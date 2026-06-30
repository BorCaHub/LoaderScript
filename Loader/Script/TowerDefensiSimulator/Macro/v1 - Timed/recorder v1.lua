--[[
    BorcaHub // TDS Macro v1 - Time Based Recorder
    Records and plays back tower placements with precise timing
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Macro = {}

-- ================================================
-- CONFIGURATION
-- ================================================
Macro.Config = {
    PlaybackSpeed = 1, -- 1 = normal, 2 = 2x speed, etc.
    AutoStartDelay = 0, -- Delay before auto-starting playback
    LoopMacro = false, -- Loop the macro after completion
}

-- ================================================
-- STATE
-- ================================================
Macro.State = {
    IsRecording = false,
    IsPlaying = false,
    StartTime = 0,
    RecordedActions = {},
    CurrentActionIndex = 1,
    PlaybackLoop = nil,
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
}

-- ================================================
-- UTILITY FUNCTIONS
-- ================================================
local function getTowerPlacementPosition()
    -- Get mouse position on the map for tower placement
    local Mouse = Player:GetMouse()
    local Ray = Workspace.CurrentCamera:ViewportPointToRay(Mouse.X, Mouse.Y)
    local RaycastParams = RaycastParams.new()
    RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    RaycastParams.FilterDescendantsInstances = {Player.Character}
    
    local Result = Workspace:Raycast(Ray.Origin, Ray.Direction * 1000, RaycastParams)
    
    if Result then
        return Result.Position, Result.Instance
    end
    return nil, nil
end

local function getTowerFromInventory(towerName)
    -- Get tower from player's inventory
    local Inventory = Player:FindFirstChild("Inventory")
    if Inventory then
        for _, item in pairs(Inventory:GetChildren()) do
            if item.Name == towerName or item.Name:lower():find(towerName:lower()) then
                return item
            end
        end
    end
    return nil
end

-- ================================================
-- RECORDING FUNCTIONS
-- ================================================
function Macro.StartRecording()
    if Macro.State.IsRecording then
        warn("Already recording!")
        return false
    end
    
    Macro.State.IsRecording = true
    Macro.State.StartTime = tick()
    Macro.State.RecordedActions = {}
    
    warn("[Macro v1] Recording started at " .. Macro.State.StartTime)
    return true
end

function Macro.StopRecording()
    if not Macro.State.IsRecording then
        warn("Not recording!")
        return false
    end
    
    Macro.State.IsRecording = false
    warn("[Macro v1] Recording stopped. Total actions: " .. #Macro.State.RecordedActions)
    return true
end

function Macro.RecordPlaceTower(towerName, position)
    if not Macro.State.IsRecording then
        return false
    end
    
    local elapsedTime = tick() - Macro.State.StartTime
    
    table.insert(Macro.State.RecordedActions, {
        Type = ActionTypes.PLACE_TOWER,
        Time = elapsedTime,
        TowerName = towerName,
        Position = position,
    })
    
    warn("[Macro v1] Recorded: Place " .. towerName .. " at " .. tostring(position) .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordUpgradeTower(towerIndex, upgradeLevel)
    if not Macro.State.IsRecording then
        return false
    end
    
    local elapsedTime = tick() - Macro.State.StartTime
    
    table.insert(Macro.State.RecordedActions, {
        Type = ActionTypes.UPGRADE_TOWER,
        Time = elapsedTime,
        TowerIndex = towerIndex,
        UpgradeLevel = upgradeLevel,
    })
    
    warn("[Macro v1] Recorded: Upgrade tower " .. towerIndex .. " to level " .. upgradeLevel .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordSkipWave()
    if not Macro.State.IsRecording then
        return false
    end
    
    local elapsedTime = tick() - Macro.State.StartTime
    
    table.insert(Macro.State.RecordedActions, {
        Type = ActionTypes.SKIP_WAVE,
        Time = elapsedTime,
    })
    
    warn("[Macro v1] Recorded: Skip wave (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

function Macro.RecordAbility(towerIndex, abilityIndex)
    if not Macro.State.IsRecording then
        return false
    end
    
    local elapsedTime = tick() - Macro.State.StartTime
    
    table.insert(Macro.State.RecordedActions, {
        Type = ActionTypes.ABILITY,
        Time = elapsedTime,
        TowerIndex = towerIndex,
        AbilityIndex = abilityIndex,
    })
    
    warn("[Macro v1] Recorded: Ability " .. abilityIndex .. " on tower " .. towerIndex .. " (t=" .. string.format("%.2f", elapsedTime) .. "s)")
    return true
end

-- ================================================
-- PLAYBACK FUNCTIONS
-- ================================================
function Macro.StartPlayback()
    if Macro.State.IsPlaying then
        warn("Already playing!")
        return false
    end
    
    if #Macro.State.RecordedActions == 0 then
        warn("No recorded actions to play!")
        return false
    end
    
    Macro.State.IsPlaying = true
    Macro.State.CurrentActionIndex = 1
    Macro.State.StartTime = tick()
    
    warn("[Macro v1] Playback started. Total actions: " .. #Macro.State.RecordedActions)
    
    -- Start playback loop
    Macro.State.PlaybackLoop = task.spawn(Macro.PlaybackLoop)
    
    return true
end

function Macro.StopPlayback()
    if not Macro.State.IsPlaying then
        return false
    end
    
    Macro.State.IsPlaying = false
    
    if Macro.State.PlaybackLoop then
        Macro.State.PlaybackLoop = nil
    end
    
    warn("[Macro v1] Playback stopped")
    return true
end

function Macro.PlaybackLoop()
    while Macro.State.IsPlaying do
        local currentTime = (tick() - Macro.State.StartTime) * Macro.Config.PlaybackSpeed
        
        -- Execute all actions that should have happened by now
        while Macro.State.CurrentActionIndex <= #Macro.State.RecordedActions do
            local action = Macro.State.RecordedActions[Macro.State.CurrentActionIndex]
            
            if action.Time <= currentTime then
                Macro.ExecuteAction(action)
                Macro.State.CurrentActionIndex = Macro.State.CurrentActionIndex + 1
            else
                break
            end
        end
        
        -- Check if playback is complete
        if Macro.State.CurrentActionIndex > #Macro.State.RecordedActions then
            warn("[Macro v1] Playback completed")
            
            if Macro.Config.LoopMacro then
                -- Restart playback
                Macro.State.CurrentActionIndex = 1
                Macro.State.StartTime = tick()
                warn("[Macro v1] Looping macro...")
            else
                Macro.StopPlayback()
                break
            end
        end
        
        task.wait(0.016) -- ~60 FPS check rate
    end
end

function Macro.ExecuteAction(action)
    local success, err = pcall(function()
        if action.Type == ActionTypes.PLACE_TOWER then
            Macro.PlaceTower(action.TowerName, action.Position)
        elseif action.Type == ActionTypes.UPGRADE_TOWER then
            Macro.UpgradeTower(action.TowerIndex, action.UpgradeLevel)
        elseif action.Type == ActionTypes.SKIP_WAVE then
            Macro.SkipWave()
        elseif action.Type == ActionTypes.ABILITY then
            Macro.UseAbility(action.TowerIndex, action.AbilityIndex)
        end
    end)
    
    if not success then
        warn("[Macro v1] Failed to execute action: " .. tostring(err))
    end
end

-- ================================================
-- ACTION EXECUTION
-- ================================================
function Macro.PlaceTower(towerName, position)
    -- Find tower in inventory
    local tower = getTowerFromInventory(towerName)
    if not tower then
        warn("[Macro v1] Tower not found in inventory: " .. towerName)
        return false
    end
    
    -- Attempt to place tower (this depends on the game's specific API)
    -- This is a generic implementation - adjust based on actual game mechanics
    local TowersFolder = Workspace:FindFirstChild("Towers")
    if not TowersFolder then
        warn("[Macro v1] Towers folder not found")
        return false
    end
    
    -- Fire remote event to place tower (adjust based on game)
    local PlaceEvent = ReplicatedStorage:FindFirstChild("PlaceTower")
    if PlaceEvent then
        PlaceEvent:FireServer(towerName, position)
    else
        -- Alternative method using game-specific remotes
        warn("[Macro v1] PlaceTower remote not found - using fallback")
        -- Fallback implementation would go here
    end
    
    return true
end

function Macro.UpgradeTower(towerIndex, upgradeLevel)
    -- Fire upgrade remote
    local UpgradeEvent = ReplicatedStorage:FindFirstChild("UpgradeTower")
    if UpgradeEvent then
        UpgradeEvent:FireServer(towerIndex, upgradeLevel)
    else
        warn("[Macro v1] UpgradeTower remote not found")
    end
end

function Macro.SkipWave()
    -- Fire skip wave remote
    local SkipEvent = ReplicatedStorage:FindFirstChild("SkipWave")
    if SkipEvent then
        SkipEvent:FireServer()
    else
        warn("[Macro v1] SkipWave remote not found")
    end
end

function Macro.UseAbility(towerIndex, abilityIndex)
    -- Fire ability remote
    local AbilityEvent = ReplicatedStorage:FindFirstChild("UseAbility")
    if AbilityEvent then
        AbilityEvent:FireServer(towerIndex, abilityIndex)
    else
        warn("[Macro v1] UseAbility remote not found")
    end
end

-- ================================================
-- MACRO MANAGEMENT
-- ================================================
function Macro.SaveMacro(name)
    local macroData = {
        Actions = Macro.State.RecordedActions,
        Config = Macro.Config,
    }
    
    -- Save to game-specific storage or file
    -- This would depend on executor capabilities
    local success, err = pcall(function()
        if writefile then
            writefile("borcahub_tds_macro_" .. name .. ".json", game:GetService("HttpService"):JSONEncode(macroData))
            return true
        end
        return false
    end)
    
    if success then
        warn("[Macro v1] Macro saved: " .. name)
    else
        warn("[Macro v1] Failed to save macro: " .. tostring(err))
    end
    
    return success
end

function Macro.LoadMacro(name)
    local success, data = pcall(function()
        if readfile then
            local content = readfile("borcahub_tds_macro_" .. name .. ".json")
            return game:GetService("HttpService"):JSONDecode(content)
        end
        return nil
    end)
    
    if success and data then
        Macro.State.RecordedActions = data.Actions or {}
        Macro.Config = data.Config or Macro.Config
        warn("[Macro v1] Macro loaded: " .. name .. " (" .. #Macro.State.RecordedActions .. " actions)")
        return true
    else
        warn("[Macro v1] Failed to load macro: " .. name)
        return false
    end
end

function Macro.ClearMacro()
    Macro.State.RecordedActions = {}
    warn("[Macro v1] Macro cleared")
end

function Macro.GetMacroInfo()
    return {
        IsRecording = Macro.State.IsRecording,
        IsPlaying = Macro.State.IsPlaying,
        ActionCount = #Macro.State.RecordedActions,
        Duration = Macro.State.RecordedActions[#Macro.State.RecordedActions] and Macro.State.RecordedActions[#Macro.State.RecordedActions].Time or 0,
    }
end

-- ================================================
-- EXPORT
-- ================================================
return Macro
