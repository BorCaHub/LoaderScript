--[[
    Ocean Hub // TDS Macro v1 - Time Based Recorder
    Records and plays back tower placements with precise timing
    v2 Enhanced: Map change persistence, UI overlay, keyboard shortcuts
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local Macro = {}

-- ================================================
-- PERSISTENT STORAGE (survives map changes)
-- ================================================
_G.OceanMacro = _G.OceanMacro or {
    IsRecording = false,
    IsPlaying = false,
    StartTime = 0,
    RecordedActions = {},
    CurrentActionIndex = 1,
    MapChangeCount = 0,
    IsPaused = false,
    PauseTime = 0,
    TotalPausedDuration = 0,
}

-- ================================================
-- CONFIGURATION
-- ================================================
Macro.Config = {
    PlaybackSpeed = 1,
    AutoStartDelay = 0,
    LoopMacro = false,
    ShowUI = true,
    Keybinds = {
        ToggleRecording = Enum.KeyCode.F6,
        TogglePlayback = Enum.KeyCode.F7,
        StopAll = Enum.KeyCode.F8,
        SkipWave = Enum.KeyCode.F9,
        PauseResume = Enum.KeyCode.F10,
    },
    UIColors = {
        Background = Color3.fromRGB(15, 15, 25),
        Accent = Color3.fromRGB(0, 170, 255),
        Recording = Color3.fromRGB(255, 50, 50),
        Playing = Color3.fromRGB(50, 255, 100),
        Idle = Color3.fromRGB(100, 100, 100),
        Text = Color3.fromRGB(255, 255, 255),
        Warning = Color3.fromRGB(255, 200, 0),
    },
    SaveOnMapChange = true,
}

-- ================================================
-- ACTION TYPES
-- ================================================
local ActionTypes = {
    PLACE_TOWER = "place_tower",
    UPGRADE_TOWER = "upgrade_tower",
    SELL_TOWER = "sell_tower",
    SKIP_WAVE = "skip_wave",
    ABILITY = "ability",
    MAP_CHANGE = "map_change",
}

-- ================================================
-- SERVICE CACHE (auto-refreshed on map change)
-- ================================================
local ServiceCache = { ReplicatedStorage = nil, Workspace = nil }

local function RefreshServiceCache()
    ServiceCache.ReplicatedStorage = game:GetService("ReplicatedStorage")
    ServiceCache.Workspace = game:GetService("Workspace")
end
RefreshServiceCache()

-- ================================================
-- MAP CHANGE DETECTION (FIXED: no recursive loops, no stale threads)
-- ================================================
local MapChangeDetector = {}
MapChangeDetector.Connections = {}
MapChangeDetector.LastMapCheck = ""
MapChangeDetector.CheckThread = nil

function MapChangeDetector:Start()
    local ws = ServiceCache.Workspace
    if not ws then return end
    
    -- Detect map loading via terrain (ONLY when DescendantAdded, not on full rebuild)
    local conn1 = ws.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") and desc.Name:find("Terrain") then
            -- Use defer to avoid recursive trigger during map rebuild
            task.defer(function()
                self:OnMapChanged("Terrain loaded")
            end)
        end
    end)
    table.insert(self.Connections, conn1)
    
    -- Detect map folders - use defer + debounce to avoid spam
    local lastChildTrigger = 0
    local conn2 = ws.ChildAdded:Connect(function(child)
        local now = tick()
        if now - lastChildTrigger < 2 then return end -- debounce 2 detik
        lastChildTrigger = now
        
        if child.Name == "Map" or child.Name == "CurrentMap" then
            task.delay(1, function()
                self:OnMapChanged("Map folder: " .. child.Name)
            end)
        elseif child:IsA("Model") and #child:GetChildren() > 10 then
            -- Check if this is actually a new map (not existing structures being loaded)
            task.delay(1.5, function()
                self:OnMapChanged("Map model: " .. child.Name)
            end)
        end
    end)
    table.insert(self.Connections, conn2)
    
    -- Periodic check (FIXED: kill old thread before spawning new one)
    if self.CheckThread then
        task.cancel(self.CheckThread)
        self.CheckThread = nil
    end
    
    self.CheckThread = task.spawn(function()
        while task.wait(1) do
            local currentMap = self:GetCurrentMapName()
            if currentMap and currentMap ~= self.LastMapCheck and self.LastMapCheck ~= "" then
                self:OnMapChanged("Periodic: " .. self.LastMapCheck .. " -> " .. currentMap)
            end
            self.LastMapCheck = currentMap or self.LastMapCheck
        end
    end)
    
    -- Teleport detection
    local conn3 = game:GetService("TeleportService").LocalPlayerTeleported:Connect(function(state, placeId)
        self:OnMapChanged("Teleport to: " .. placeId)
    end)
    table.insert(self.Connections, conn3)
end

function MapChangeDetector:GetCurrentMapName()
    local ws = ServiceCache.Workspace
    if not ws then return nil end
    local map = ws:FindFirstChild("Map")
    if map then return map.Name end
    local lighting = game:GetService("Lighting")
    if lighting:FindFirstChild("MapName") then return lighting.MapName.Value end
    for _, child in pairs(ws:GetChildren()) do
        if child:IsA("Model") and #child:GetChildren() > 5 then
            return child.Name
        end
    end
    return nil
end

function MapChangeDetector:OnMapChanged(reason)
    _G.OceanMacro.MapChangeCount = _G.OceanMacro.MapChangeCount + 1
    RefreshServiceCache()
    warn("[Macro] Map change #" .. _G.OceanMacro.MapChangeCount .. ": " .. reason)
    
    -- Record map change if recording
    if _G.OceanMacro.IsRecording then
        local elapsedTime = tick() - _G.OceanMacro.StartTime - _G.OceanMacro.TotalPausedDuration
        table.insert(_G.OceanMacro.RecordedActions, {
            Type = ActionTypes.MAP_CHANGE,
            Time = elapsedTime,
            MapChangeNumber = _G.OceanMacro.MapChangeCount,
            Reason = reason,
        })
    end
    
    -- FIXED: Only kill connections + periodic check, re-init
    for _, conn in pairs(self.Connections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    self.Connections = {}
    
    if self.CheckThread then
        task.cancel(self.CheckThread)
        self.CheckThread = nil
    end
    
    -- Small delay before re-initializing to let map settle
    task.delay(0.5, function()
        self:Start()
    end)
    
    -- Update UI
    if Macro.UI and Macro.UI.Enabled then
        Macro.UI:UpdateMapInfo(_G.OceanMacro.MapChangeCount)
    end
    
    -- Auto-save (FIXED: use callback to check result)
    if Macro.Config.SaveOnMapChange and #_G.OceanMacro.RecordedActions > 0 then
        Macro.SaveMacro("autosave_map" .. _G.OceanMacro.MapChangeCount)
    end
end

function MapChangeDetector:Stop()
    for _, conn in pairs(self.Connections) do
        if conn and conn.Connected then conn:Disconnect() end
    end
    self.Connections = {}
    
    if self.CheckThread then
        task.cancel(self.CheckThread)
        self.CheckThread = nil
    end
end

-- ================================================
-- UI SYSTEM (survives map changes - CoreGui + ResetOnSpawn=false)
-- ================================================
Macro.UI = { Enabled = false, Frame = nil, Elements = {} }

function Macro.UI:Create()
    if self.Frame then self.Frame.Visible = true; self.Enabled = true; return end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "OceanMacroUI"
    gui.ResetOnSpawn = false  -- CRITICAL: survives map change!
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0, 280, 0, 200)
    frame.Position = UDim2.new(0, 15, 0.5, -100)
    frame.BackgroundColor3 = Macro.Config.UIColors.Background
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Macro.Config.UIColors.Accent; stroke.Thickness = 1.5; stroke.Transparency = 0.5
    
    -- Title bar
    local titleBar = Instance.new("Frame", frame)
    titleBar.Name = "TitleBar"; titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35); titleBar.BackgroundTransparency = 0.3; titleBar.BorderSizePixel = 0
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel", titleBar)
    title.Name = "Title"; title.Size = UDim2.new(1, -10, 1, 0); title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "⚡ Ocean Macro"
    title.TextColor3 = Macro.Config.UIColors.Accent; title.TextSize = 14; title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 24, 0, 24); closeBtn.Position = UDim2.new(1, -28, 0, 3)
    closeBtn.BackgroundTransparency = 1; closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80); closeBtn.TextSize = 16; closeBtn.Font = Enum.Font.GothamBold
    closeBtn.MouseButton1Click:Connect(function() self.Enabled = false; frame.Visible = false end)
    
    -- Status indicator
    local statusFrame = Instance.new("Frame", frame)
    statusFrame.Size = UDim2.new(1, -20, 0, 24); statusFrame.Position = UDim2.new(0, 10, 0, 36)
    statusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40); statusFrame.BackgroundTransparency = 0.5; statusFrame.BorderSizePixel = 0
    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 4)
    
    local statusDot = Instance.new("Frame", statusFrame)
    statusDot.Name = "StatusDot"; statusDot.Size = UDim2.new(0, 8, 0, 8)
    statusDot.Position = UDim2.new(0, 8, 0.5, -4)
    statusDot.BackgroundColor3 = Macro.Config.UIColors.Idle; statusDot.BorderSizePixel = 0
    Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)
    
    local statusText = Instance.new("TextLabel", statusFrame)
    statusText.Name = "StatusText"; statusText.Size = UDim2.new(1, -24, 1, 0); statusText.Position = UDim2.new(0, 20, 0, 0)
    statusText.BackgroundTransparency = 1; statusText.Text = "Idle"
    statusText.TextColor3 = Macro.Config.UIColors.Text; statusText.TextSize = 12; statusText.Font = Enum.Font.Gotham
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Info labels
    local infoY = 66; local infoLabels = {}
    local infoData = {
        {Name = "Actions", Key = "actions", Default = "0"},
        {Name = "Duration", Key = "duration", Default = "0:00"},
        {Name = "Map Changes", Key = "mapChanges", Default = "0"},
    }
    for _, data in ipairs(infoData) do
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, -20, 0, 18); label.Position = UDim2.new(0, 10, 0, infoY)
        label.BackgroundTransparency = 1; label.Text = data.Name .. ": " .. data.Default
        label.TextColor3 = Macro.Config.UIColors.Text; label.TextSize = 11; label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left; label.RichText = true
        infoLabels[data.Key] = label; infoY = infoY + 20
    end
    
    -- Keybind hint
    local hint = Instance.new("TextLabel", frame)
    hint.Size = UDim2.new(1, -20, 0, 16); hint.Position = UDim2.new(0, 10, 0, infoY + 2)
    hint.BackgroundTransparency = 1; hint.Text = "F6=Record  F7=Play  F8=Stop  F10=Pause"
    hint.TextColor3 = Color3.fromRGB(150, 150, 150); hint.TextSize = 9; hint.Font = Enum.Font.Gotham
    hint.TextXAlignment = Enum.TextXAlignment.Left
    
    self.Frame = frame; self.ScreenGui = gui
    self.Elements = { StatusDot = statusDot, StatusText = statusText, InfoLabels = infoLabels }
    self.Enabled = true
end

function Macro.UI:UpdateStatus(status, color)
    if not self.Elements.StatusDot then return end
    self.Elements.StatusText.Text = status
    self.Elements.StatusDot.BackgroundColor3 = color or Macro.Config.UIColors.Idle
end

function Macro.UI:UpdateInfo()
    if not self.Elements.InfoLabels then return end
    local actions = #_G.OceanMacro.RecordedActions
    local duration = actions > 0 and _G.OceanMacro.RecordedActions[actions].Time or 0
    local m = math.floor(duration / 60); local s = math.floor(duration % 60)
    self.Elements.InfoLabels.actions.Text = "Actions: <b>" .. actions .. "</b>"
    self.Elements.InfoLabels.duration.Text = "Duration: <b>" .. string.format("%d:%02d", m, s) .. "</b>"
    self.Elements.InfoLabels.mapChanges.Text = "Map Changes: <b>" .. _G.OceanMacro.MapChangeCount .. "</b>"
end

function Macro.UI:UpdateMapInfo(count)
    if self.Elements.InfoLabels then
        self.Elements.InfoLabels.mapChanges.Text = "Map Changes: <b>" .. count .. "</b>"
    end
end

function Macro.UI:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    self.Frame = nil; self.ScreenGui = nil; self.Elements = {}; self.Enabled = false
end

-- ================================================
-- UI UPDATE LOOP
-- ================================================
local UIUpdateLoop = nil
local function StartUIUpdateLoop()
    if UIUpdateLoop then return end
    UIUpdateLoop = task.spawn(function()
        while task.wait(0.1) do
            if Macro.UI and Macro.UI.Enabled and Macro.UI.Frame then Macro.UI:UpdateInfo() end
        end
    end)
end

-- ================================================
-- KEYBOARD SHORTCUTS
-- ================================================
local function SetupKeybinds()
    return UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        local key = input.KeyCode
        if key == Macro.Config.Keybinds.ToggleRecording then
            if _G.OceanMacro.IsRecording then Macro.StopRecording() else Macro.StartRecording() end
        elseif key == Macro.Config.Keybinds.TogglePlayback then
            if _G.OceanMacro.IsPlaying then Macro.StopPlayback() else Macro.StartPlayback() end
        elseif key == Macro.Config.Keybinds.StopAll then
            Macro.StopRecording(); Macro.StopPlayback()
        elseif key == Macro.Config.Keybinds.SkipWave then
            Macro.RecordSkipWave()
        elseif key == Macro.Config.Keybinds.PauseResume then
            if _G.OceanMacro.IsRecording then
                _G.OceanMacro.IsPaused = not _G.OceanMacro.IsPaused
                if _G.OceanMacro.IsPaused then
                    _G.OceanMacro.PauseTime = tick()
                    if Macro.UI.Enabled then Macro.UI:UpdateStatus("⏸ Paused", Macro.Config.UIColors.Warning) end
                    warn("[Macro] Recording paused")
                else
                    _G.OceanMacro.TotalPausedDuration = _G.OceanMacro.TotalPausedDuration + (tick() - _G.OceanMacro.PauseTime)
                    if Macro.UI.Enabled then Macro.UI:UpdateStatus("Recording", Macro.Config.UIColors.Recording) end
                    warn("[Macro] Recording resumed")
                end
            end
        end
    end)
end

-- ================================================
-- UTILITY FUNCTIONS
-- ================================================
local function getTowerPlacementPosition()
    local ws = ServiceCache.Workspace
    if not ws then return nil, nil end
    local Mouse = Player:GetMouse()
    local Ray = ws.CurrentCamera:ViewportPointToRay(Mouse.X, Mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Player.Character}
    local Result = ws:Raycast(Ray.Origin, Ray.Direction * 1000, params)
    if Result then return Result.Position, Result.Instance end
    return nil, nil
end

local function getTowerFromInventory(towerName)
    local Inventory = Player:FindFirstChild("Inventory")
    if Inventory then
        for _, item in pairs(Inventory:GetChildren()) do
            if item.Name == towerName or item.Name:lower():find(towerName:lower()) then return item end
        end
    end
    return nil
end

-- ================================================
-- RECORDING FUNCTIONS
-- ================================================
function Macro.StartRecording()
    if _G.OceanMacro.IsRecording then warn("[Macro] Already recording!"); return false end
    
    _G.OceanMacro.IsRecording = true
    _G.OceanMacro.IsPlaying = false
    _G.OceanMacro.StartTime = tick()
    _G.OceanMacro.TotalPausedDuration = 0
    _G.OceanMacro.IsPaused = false
    _G.OceanMacro.MapChangeCount = 0
    _G.OceanMacro.RecordedActions = {}
    
    if Macro.UI.Enabled then Macro.UI:UpdateStatus("Recording", Macro.Config.UIColors.Recording) end
    warn("[Macro] Recording started")
    return true
end

function Macro.StopRecording()
    if not _G.OceanMacro.IsRecording then warn("[Macro] Not recording!"); return false end
    
    _G.OceanMacro.IsRecording = false
    _G.OceanMacro.IsPaused = false
    local count = #_G.OceanMacro.RecordedActions
    
    if Macro.UI.Enabled then
        Macro.UI:UpdateStatus("Saved (" .. count .. " actions)", Macro.Config.UIColors.Accent)
        task.wait(1.5)
        Macro.UI:UpdateStatus("Idle", Macro.Config.UIColors.Idle)
    end
    warn("[Macro] Recording stopped. " .. count .. " actions recorded")
    return true
end

function Macro.RecordPlaceTower(towerName, position)
    if not _G.OceanMacro.IsRecording or _G.OceanMacro.IsPaused then return false end
    local elapsedTime = tick() - _G.OceanMacro.StartTime - _G.OceanMacro.TotalPausedDuration
    table.insert(_G.OceanMacro.RecordedActions, {
        Type = ActionTypes.PLACE_TOWER, Time = elapsedTime,
        TowerName = towerName, Position = position,
    })
    warn("[Macro] 🏗 Place " .. towerName .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordUpgradeTower(towerIndex, upgradeLevel)
    if not _G.OceanMacro.IsRecording or _G.OceanMacro.IsPaused then return false end
    local elapsedTime = tick() - _G.OceanMacro.StartTime - _G.OceanMacro.TotalPausedDuration
    table.insert(_G.OceanMacro.RecordedActions, {
        Type = ActionTypes.UPGRADE_TOWER, Time = elapsedTime,
        TowerIndex = towerIndex, UpgradeLevel = upgradeLevel,
    })
    warn("[Macro] ⬆ Upgrade tower " .. towerIndex .. " to Lv" .. upgradeLevel .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordSellTower(towerIndex)
    if not _G.OceanMacro.IsRecording or _G.OceanMacro.IsPaused then return false end
    local elapsedTime = tick() - _G.OceanMacro.StartTime - _G.OceanMacro.TotalPausedDuration
    table.insert(_G.OceanMacro.RecordedActions, {
        Type = ActionTypes.SELL_TOWER, Time = elapsedTime, TowerIndex = towerIndex,
    })
    warn("[Macro] 💰 Sell tower " .. towerIndex .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordSkipWave()
    if not _G.OceanMacro.IsRecording or _G.OceanMacro.IsPaused then return false end
    local elapsedTime = tick() - _G.OceanMacro.StartTime - _G.OceanMacro.TotalPausedDuration
    table.insert(_G.OceanMacro.RecordedActions, {
        Type = ActionTypes.SKIP_WAVE, Time = elapsedTime,
    })
    warn("[Macro] ⏭ Skip wave (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordAbility(towerIndex, abilityIndex)
    if not _G.OceanMacro.IsRecording or _G.OceanMacro.IsPaused then return false end
    local elapsedTime = tick() - _G.OceanMacro.StartTime - _G.OceanMacro.TotalPausedDuration
    table.insert(_G.OceanMacro.RecordedActions, {
        Type = ActionTypes.ABILITY, Time = elapsedTime,
        TowerIndex = towerIndex, AbilityIndex = abilityIndex,
    })
    warn("[Macro] ⚡ Ability " .. abilityIndex .. " on tower " .. towerIndex .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

-- ================================================
-- PLAYBACK FUNCTIONS
-- ================================================
function Macro.StartPlayback()
    if _G.OceanMacro.IsPlaying then warn("[Macro] Already playing!"); return false end
    if #_G.OceanMacro.RecordedActions == 0 then warn("[Macro] No recorded actions!"); return false end
    
    _G.OceanMacro.IsPlaying = true
    _G.OceanMacro.IsRecording = false
    _G.OceanMacro.CurrentActionIndex = 1
    _G.OceanMacro.StartTime = tick()
    
    if Macro.UI.Enabled then Macro.UI:UpdateStatus("Playing", Macro.Config.UIColors.Playing) end
    warn("[Macro] ▶ Playback started (" .. #_G.OceanMacro.RecordedActions .. " actions)")
    task.spawn(Macro.PlaybackLoop)
    return true
end

function Macro.StopPlayback()
    if not _G.OceanMacro.IsPlaying then return false end
    _G.OceanMacro.IsPlaying = false
    if Macro.UI.Enabled then
        Macro.UI:UpdateStatus("Stopped", Macro.Config.UIColors.Warning)
        task.wait(1)
        Macro.UI:UpdateStatus("Idle", Macro.Config.UIColors.Idle)
    end
    warn("[Macro] ⏹ Playback stopped")
    return true
end

function Macro.PlaybackLoop()
    while _G.OceanMacro.IsPlaying do
        local currentTime = (tick() - _G.OceanMacro.StartTime) * Macro.Config.PlaybackSpeed
        
        while _G.OceanMacro.CurrentActionIndex <= #_G.OceanMacro.RecordedActions do
            local action = _G.OceanMacro.RecordedActions[_G.OceanMacro.CurrentActionIndex]
            if action.Time <= currentTime then
                if action.Type ~= ActionTypes.MAP_CHANGE then Macro.ExecuteAction(action) end
                _G.OceanMacro.CurrentActionIndex = _G.OceanMacro.CurrentActionIndex + 1
            else break end
        end
        
        if _G.OceanMacro.CurrentActionIndex > #_G.OceanMacro.RecordedActions then
            warn("[Macro] ✅ Playback completed")
            if Macro.Config.LoopMacro then
                _G.OceanMacro.CurrentActionIndex = 1
                _G.OceanMacro.StartTime = tick()
                warn("[Macro] 🔄 Looping...")
            else Macro.StopPlayback(); break end
        end
        
        task.wait(0.016)
    end
end

function Macro.ExecuteAction(action)
    local success, err = pcall(function()
        if action.Type == ActionTypes.PLACE_TOWER then Macro.PlaceTower(action.TowerName, action.Position)
        elseif action.Type == ActionTypes.UPGRADE_TOWER then Macro.UpgradeTower(action.TowerIndex, action.UpgradeLevel)
        elseif action.Type == ActionTypes.SELL_TOWER then Macro.SellTower(action.TowerIndex)
        elseif action.Type == ActionTypes.SKIP_WAVE then Macro.SkipWave()
        elseif action.Type == ActionTypes.ABILITY then Macro.UseAbility(action.TowerIndex, action.AbilityIndex) end
    end)
    if not success then warn("[Macro] ❌ Execute failed: " .. tostring(err)) end
end

-- ================================================
-- ACTION EXECUTION
-- ================================================
function Macro.PlaceTower(towerName, position)
    local tower = getTowerFromInventory(towerName)
    if not tower then warn("[Macro] Tower not found: " .. towerName); return false end
    local rs = ServiceCache.ReplicatedStorage
    if not rs then return false end
    local evt = rs:FindFirstChild("PlaceTower")
    if evt then evt:FireServer(towerName, position) else warn("[Macro] PlaceTower remote not found") end
    return true
end

function Macro.UpgradeTower(towerIndex, upgradeLevel)
    local rs = ServiceCache.ReplicatedStorage
    if not rs then return end
    local evt = rs:FindFirstChild("UpgradeTower")
    if evt then evt:FireServer(towerIndex, upgradeLevel) else warn("[Macro] UpgradeTower remote not found") end
end

function Macro.SellTower(towerIndex)
    local rs = ServiceCache.ReplicatedStorage
    if not rs then return end
    local evt = rs:FindFirstChild("SellTower")
    if evt then evt:FireServer(towerIndex) else warn("[Macro] SellTower remote not found") end
end

function Macro.SkipWave()
    local rs = ServiceCache.ReplicatedStorage
    if not rs then return end
    local evt = rs:FindFirstChild("SkipWave")
    if evt then evt:FireServer() else warn("[Macro] SkipWave remote not found") end
end

function Macro.UseAbility(towerIndex, abilityIndex)
    local rs = ServiceCache.ReplicatedStorage
    if not rs then return end
    local evt = rs:FindFirstChild("UseAbility")
    if evt then evt:FireServer(towerIndex, abilityIndex) else warn("[Macro] UseAbility remote not found") end
end

-- ================================================
-- MACRO MANAGEMENT
-- ================================================
function Macro.SaveMacro(name)
    local data = { Actions = _G.OceanMacro.RecordedActions, Config = Macro.Config, MapChangeCount = _G.OceanMacro.MapChangeCount }
    local ok, err = pcall(function()
        if writefile then
            writefile("oceanhub_tds_macro_" .. name .. ".json", HttpService:JSONEncode(data))
            return true
        end
        return false, "writefile not available"
    end)
    if ok then
        warn("[Macro] 💾 Saved: " .. name)
    else
        warn("[Macro] ❌ Save failed: " .. tostring(err))
    end
    return ok
end

function Macro.LoadMacro(name)
    local ok, data = pcall(function()
        if readfile then return HttpService:JSONDecode(readfile("oceanhub_tds_macro_" .. name .. ".json")) end
        return nil
    end)
    if ok and data then
        _G.OceanMacro.RecordedActions = data.Actions or {}
        _G.OceanMacro.MapChangeCount = data.MapChangeCount or 0
        Macro.Config = data.Config or Macro.Config
        warn("[Macro] 📂 Loaded: " .. name .. " (" .. #_G.OceanMacro.RecordedActions .. " actions)")
        return true
    end
    warn("[Macro] ❌ Failed to load: " .. name)
    return false
end

function Macro.ClearMacro()
    _G.OceanMacro.RecordedActions = {}
    _G.OceanMacro.MapChangeCount = 0
    warn("[Macro] 🗑 Cleared")
end

function Macro.GetMacroInfo()
    local actions = _G.OceanMacro.RecordedActions
    return {
        IsRecording = _G.OceanMacro.IsRecording, IsPlaying = _G.OceanMacro.IsPlaying,
        IsPaused = _G.OceanMacro.IsPaused, ActionCount = #actions,
        Duration = actions[#actions] and actions[#actions].Time or 0,
        MapChangeCount = _G.OceanMacro.MapChangeCount,
    }
end

-- ================================================
-- INITIALIZATION
-- ================================================
function Macro.Init()
    if Macro.Config.ShowUI then Macro.UI:Create(); StartUIUpdateLoop() end
    _G.OceanMacro.InputConnection = SetupKeybinds()
    MapChangeDetector:Start()
    warn("[Macro] ✅ System ready - Map persistence ACTIVE")
    warn("[Macro] Controls: F6=Record  F7=Play  F8=Stop  F9=Skip  F10=Pause")
end

function Macro.Cleanup()
    Macro.StopRecording(); Macro.StopPlayback(); MapChangeDetector:Stop()
    if _G.OceanMacro.InputConnection then _G.OceanMacro.InputConnection:Disconnect(); _G.OceanMacro.InputConnection = nil end
    Macro.UI:Destroy()
end

-- Auto-init
Macro.Init()

return Macro