--[[
    Ocean Hub // Sell Lemons Module
    Auto Sell Lemons, Buy Button, & Money Upgrade Features
    Ocean Wave Theme with Corner Lightning Effects
]]

local _tier = getgenv().Tier or "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _rs  = game:GetService("RunService")
local _http = game:GetService("HttpService")

-- ================================================
-- COLORS & CONFIGURATION - OCEAN WAVE THEME
-- ================================================
local palette = {
    bg        = Color3.fromRGB(11, 19, 43),
    panel     = Color3.fromRGB(28, 37, 65),
    card      = Color3.fromRGB(22, 32, 55),
    cardHover = Color3.fromRGB(35, 50, 75),
    accent    = Color3.fromRGB(0, 180, 216),
    accent2   = Color3.fromRGB(144, 224, 239),
    gold      = Color3.fromRGB(255, 200, 0),
    textMain  = Color3.fromRGB(224, 251, 252),
    textSub   = Color3.fromRGB(170, 215, 225),
    textMuted = Color3.fromRGB(100, 140, 160),
    red       = Color3.fromRGB(255, 80, 80),
    green     = Color3.fromRGB(0, 220, 120),
    divider   = Color3.fromRGB(30, 45, 65),
}

-- ================================================
-- GUI UTILITIES
-- ================================================
local function mkCorner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c
end
local function mkStroke(p, col, th)
    local s = Instance.new("UIStroke"); s.Color = col or palette.divider; s.Thickness = th or 1; s.Parent = p; return s
end
local function createCornerGlow(name, xScale, xOff, yScale, yOff, color1, color2)
    local g1 = Instance.new("ImageLabel")
    g1.Name = name .. "_1"
    g1.Size = UDim2.new(0, 100, 0, 100)
    g1.Position = UDim2.new(xScale, xOff, yScale, yOff)
    g1.AnchorPoint = Vector2.new(0.5, 0.5)
    g1.BackgroundTransparency = 1
    g1.Image = "rbxassetid://5028857084"
    g1.ImageColor3 = color1
    g1.ImageTransparency = 0.25
    g1.ZIndex = -1
    g1.Parent = mainFrame
    _ts:Create(g1, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    _ts:Create(g1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.5}):Play()

    local g2 = Instance.new("ImageLabel")
    g2.Name = name .. "_2"
    g2.Size = UDim2.new(0, 60, 0, 60)
    g2.Position = UDim2.new(xScale, xOff, yScale, yOff)
    g2.AnchorPoint = Vector2.new(0.5, 0.5)
    g2.BackgroundTransparency = 1
    g2.Image = "rbxassetid://5028857084"
    g2.ImageColor3 = color2
    g2.ImageTransparency = 0.35
    g2.ZIndex = -1
    g2.Parent = mainFrame
    _ts:Create(g2, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = -360}):Play()
    _ts:Create(g2, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.6}):Play()
end

-- ================================================
-- Remove old GUI
-- ================================================
local _core = game:GetService("CoreGui")
if _core:FindFirstChild("OceanHubSellLemons") then
    _core.OceanHubSellLemons:Destroy()
end

-- ================================================
-- DEVICE CONFIG (consistent with Loader)
-- ================================================
local function getDeviceConfig()
    local deviceType = "PC"
    if _uis.TouchEnabled and not _uis.KeyboardEnabled then
        deviceType = "Phone"
    elseif _uis.TouchEnabled then
        deviceType = "Tablet"
    end

    local configPaths = {
        PC = "Loader/PlayerDevice/PC.lua",
        Phone = "Loader/PlayerDevice/Phone.lua",
        Tablet = "Loader/PlayerDevice/Tablet.lua",
        Laptop = "Loader/PlayerDevice/Laptop.lua",
        Mac = "Loader/PlayerDevice/Mac.lua"
    }

    local success, config = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/" .. (configPaths[deviceType] or configPaths.PC)))()
    end)

    if success and config then
        return config
    end

    return {
        frameSize = UDim2.new(0, 460, 0, 420),
        cornerRadius = 12,
        borderThickness = 1,
        titleTextSize = 28,
        subtitleTextSize = 14,
        versionTextSize = 12,
        tierBtnTextSize = 24,
        tierDescTextSize = 13,
        keyBoxTextSize = 20,
        keySubmitTextSize = 18,
        scriptTitleSize = 22,
        scriptDescSize = 15,
        closeBtnSize = UDim2.new(0, 30, 0, 30),
        minBtnSize = UDim2.new(0, 30, 0, 30),
        keyBoxHeight = 48,
        keyButtonHeight = 42,
        scriptButtonHeight = 55,
        titleTextPosition = UDim2.new(0, 20, 0, 2),
        subtitlePosition = UDim2.new(0, 20, 0, 48),
        closeBtnPosition = UDim2.new(1, -38, 0, 6),
        minBtnPosition = UDim2.new(1, -38, 0, 38),
        versionPosition = UDim2.new(1, -70, 0, 10),
        pagesPosition = UDim2.new(0, 20, 0, 62),
        uiScale = 1,
    }
end

local config = getDeviceConfig()

-- ================================================
-- MAIN GUI STRUCTURE
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OceanHubSellLemons"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local ok, _ = pcall(function() screenGui.Parent = _core end)
if not ok then screenGui.Parent = _plr:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Root"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = config.frameSize
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui
mkCorner(mainFrame, config.cornerRadius)
mkStroke(mainFrame, palette.divider, config.borderThickness)

createCornerGlow("TL", 0, -20, 0, -20, palette.accent, palette.accent2)
createCornerGlow("TR", 1, 20, 0, -20, palette.accent2, palette.accent)
createCornerGlow("BL", 0, -20, 1, 20, palette.accent2, palette.accent)
createCornerGlow("BR", 1, 20, 1, 20, palette.accent, palette.accent2)

-- Intro Animation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundTransparency = 1
_ts:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = config.frameSize,
    BackgroundTransparency = 0
}):Play()

-- ================================================
-- TITLE BAR
-- ================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 58)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -100, 0, 28)
titleText.Position = UDim2.new(0, 20, 0, 4)
titleText.BackgroundTransparency = 1
titleText.Text = "SELL LEMONS"
titleText.TextColor3 = palette.textMain
titleText.TextSize = config.titleTextSize or 22
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local subTitleText = Instance.new("TextLabel")
subTitleText.Size = UDim2.new(1, -100, 0, 16)
subTitleText.Position = UDim2.new(0, 20, 0, 34)
subTitleText.BackgroundTransparency = 1
subTitleText.Text = "Lemon Tycoon Automation"
subTitleText.TextColor3 = palette.textSub
subTitleText.TextSize = config.subtitleTextSize or 11
subTitleText.Font = Enum.Font.GothamMedium
subTitleText.TextXAlignment = Enum.TextXAlignment.Left
subTitleText.Parent = titleBar

-- Tier badge (right side of title bar)
local tierLabel = Instance.new("TextLabel")
tierLabel.Size = UDim2.new(0, 60, 0, 20)
tierLabel.Position = UDim2.new(1, -70, 0, 4)
tierLabel.BackgroundColor3 = (_tier == "Premium") and palette.gold or palette.accent
tierLabel.BackgroundTransparency = 0.2
tierLabel.Text = _tier:upper()
tierLabel.TextColor3 = palette.textMain
tierLabel.TextSize = 9
tierLabel.Font = Enum.Font.GothamBold
tierLabel.TextXAlignment = Enum.TextXAlignment.Center
tierLabel.Parent = titleBar
mkCorner(tierLabel, 4)

-- Version label (top right corner, below close button area)
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 45, 0, 14)
versionLabel.Position = UDim2.new(1, -70, 0, 30)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v2.0"
versionLabel.TextColor3 = palette.textMuted
versionLabel.TextSize = 10
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = mainFrame

-- Dragging
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = mainFrame.Position
    end
end)
titleBar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
_uis.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ================================================
-- Close & Minimize buttons
-- ================================================
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = config.closeBtnSize
closeBtn.Position = config.closeBtnPosition or UDim2.new(1, -38, 0, 6)
closeBtn.BackgroundColor3 = palette.card
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame
mkCorner(closeBtn, 6)
mkStroke(closeBtn, palette.red, 1.5)

closeBtn.MouseButton1Click:Connect(function()
    _ts:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.35, function()
        _activeLoops = {}
        screenGui:Destroy()
    end)
end)

local minBtn = Instance.new("TextButton")
minBtn.Name = "MinBtn"
minBtn.Size = config.minBtnSize
minBtn.Position = config.minBtnPosition or UDim2.new(1, -38, 0, 38)
minBtn.BackgroundColor3 = palette.card
minBtn.Text = "−"
minBtn.TextColor3 = palette.textSub
minBtn.TextSize = 16
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = mainFrame
mkCorner(minBtn, 6)
mkStroke(minBtn, palette.divider, 1)

local isMinimized = false
local originalSize = mainFrame.Size
local minimizedSize = UDim2.new(0, config.frameSize.X.Offset, 0, 60)

minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        _ts:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
            Size = minimizedSize
        }):Play()
        minBtn.Text = "+"
    else
        _ts:Create(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {
            Size = originalSize
        }):Play()
        minBtn.Text = "−"
    end
end)

-- Hover effects
local function bindHover(btn, hoverColor, defaultColor)
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = defaultColor}):Play()
    end)
end
bindHover(closeBtn, Color3.fromRGB(180, 30, 30), palette.card)
bindHover(minBtn, palette.cardHover, palette.card)

-- ================================================
-- Divider
-- ================================================
local titleDiv = Instance.new("Frame")
titleDiv.Size = UDim2.new(1, -40, 0, 2)
titleDiv.Position = UDim2.new(0, 20, 0, 60)
titleDiv.BackgroundColor3 = palette.divider
titleDiv.BorderSizePixel = 0
titleDiv.Parent = mainFrame

-- ================================================
-- STATUS PANEL (money, lemons, stats)
-- ================================================
local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(1, -40, 0, 70)
statsPanel.Position = UDim2.new(0, 20, 0, 68)
statsPanel.BackgroundColor3 = palette.card
statsPanel.BackgroundTransparency = 0.5
statsPanel.BorderSizePixel = 0
statsPanel.Parent = mainFrame
mkCorner(statsPanel, 8)
mkStroke(statsPanel, palette.divider, 1)

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Size = UDim2.new(0.5, -10, 1, 0)
moneyLabel.Position = UDim2.new(0, 10, 0, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "💰 Money: Loading..."
moneyLabel.TextColor3 = palette.gold
moneyLabel.TextSize = 13
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = statsPanel

local lemonLabel = Instance.new("TextLabel")
lemonLabel.Size = UDim2.new(0.5, -10, 1, 0)
lemonLabel.Position = UDim2.new(0.5, 0, 0, 0)
lemonLabel.BackgroundTransparency = 1
lemonLabel.Text = "🍋 Lemons: Loading..."
lemonLabel.TextColor3 = palette.accent
lemonLabel.TextSize = 13
lemonLabel.Font = Enum.Font.GothamBold
lemonLabel.TextXAlignment = Enum.TextXAlignment.Right
lemonLabel.Parent = statsPanel

local soldLabel = Instance.new("TextLabel")
soldLabel.Size = UDim2.new(1, -20, 0, 16)
soldLabel.Position = UDim2.new(0, 10, 0, 42)
soldLabel.BackgroundTransparency = 1
soldLabel.Text = "Total Sold: 0"
soldLabel.TextColor3 = palette.textMuted
soldLabel.TextSize = 11
soldLabel.Font = Enum.Font.Gotham
soldLabel.TextXAlignment = Enum.TextXAlignment.Left
soldLabel.Parent = statsPanel

-- ================================================
-- CONTENT PAGES
-- ================================================
local pages = Instance.new("Frame")
pages.Size = UDim2.new(1, -40, 1, -170)
pages.Position = UDim2.new(0, 20, 0, 145)
pages.BackgroundTransparency = 1
pages.ClipsDescendants = true
pages.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = palette.accent
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = pages

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 4)
listPadding.Parent = scrollFrame

-- ================================================
-- FEATURE STATES
-- ================================================
local features = {
    autoSellLemons = false,
    autoBuyButton = false,
    moneyUpgrade = false,
}

local gameState = {
    totalSold = 0,
    lastSellTime = 0,
    lastBuyTime = 0,
    lastUpgradeTime = 0,
    sellCooldown = 1.5,
    buyCooldown = 2.0,
    upgradeCooldown = 3.0,
    knownBuyButtons = {},
    sellRemote = nil,
    upgradeRemotes = {},
}

-- ================================================
-- HELPER: CREATE FEATURE BUTTON
-- ================================================
local layoutCounter = 0
local function createFeatureBtn(name, desc, featureKey, requiredTier, customToggle)
    layoutCounter = layoutCounter + 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 70)
    btn.BackgroundColor3 = palette.card
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.LayoutOrder = layoutCounter
    btn.AutoButtonColor = false
    btn.Parent = scrollFrame
    mkCorner(btn, 8)
    mkStroke(btn, palette.divider, 1)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -90, 0, 24)
    title.Position = UDim2.new(0, 12, 0, 6)
    title.BackgroundTransparency = 1
    title.Text = name .. (requiredTier == "premium" and " 🔒" or "")
    title.TextColor3 = (requiredTier == "premium" and _tier ~= "Premium") and palette.textMuted or palette.textMain
    title.TextSize = config.scriptTitleSize or 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = btn

    local descLbl = Instance.new("TextLabel")
    descLbl.Size = UDim2.new(1, -90, 0, 18)
    descLbl.Position = UDim2.new(0, 12, 0, 32)
    descLbl.BackgroundTransparency = 1
    descLbl.Text = desc
    descLbl.TextColor3 = palette.textMuted
    descLbl.TextSize = config.scriptDescSize or 12
    descLbl.Font = Enum.Font.Gotham
    descLbl.TextXAlignment = Enum.TextXAlignment.Left
    descLbl.Parent = btn

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 56, 0, 26)
    toggle.Position = UDim2.new(1, -68, 0, 18)
    toggle.BackgroundColor3 = palette.divider
    toggle.Text = "OFF"
    toggle.TextColor3 = palette.textMuted
    toggle.TextSize = 12
    toggle.Font = Enum.Font.GothamBold
    toggle.BorderSizePixel = 0
    toggle.Name = "Toggle"
    toggle.Parent = btn
    mkCorner(toggle, 6)

    local statusDot = Instance.new("Frame")
    statusDot.Size = UDim2.new(0, 6, 0, 6)
    statusDot.Position = UDim2.new(1, -18, 0, 28)
    statusDot.BackgroundColor3 = palette.textMuted
    statusDot.BorderSizePixel = 0
    statusDot.Parent = btn
    mkCorner(statusDot, 3)

    btn.MouseButton1Click:Connect(function()
        if requiredTier == "premium" and _tier ~= "Premium" then
            return
        end

        features[featureKey] = not features[featureKey]
        local isOn = features[featureKey]

        toggle.BackgroundColor3 = isOn and palette.green or palette.divider
        toggle.Text = isOn and "ON" or "OFF"
        statusDot.BackgroundColor3 = isOn and palette.green or palette.textMuted

        if customToggle then
            customToggle(isOn, btn, toggle, statusDot)
        end
    end)

    return btn, toggle, statusDot
end

local function bindHover(btn, hoverColor, defaultColor)
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = defaultColor}):Play()
    end)
end

-- ================================================
-- FEATURE 1: AUTO SELL LEMONS
-- ================================================
local sellBtn, sellToggle, sellDot = createFeatureBtn(
    "Auto Sell Lemons",
    "Automatically sells lemons when available (Free)",
    "autoSellLemons",
    "free"
)
bindHover(sellBtn, palette.cardHover, palette.card)

-- ================================================
-- FEATURE 2: AUTO BUY BUTTON
-- ================================================
local buyBtn, buyToggle, buyDot = createFeatureBtn(
    "Auto Buy Button",
    "Auto purchases available upgrade buttons (Free)",
    "autoBuyButton",
    "free"
)
bindHover(buyBtn, palette.cardHover, palette.card)

-- ================================================
-- FEATURE 3: MONEY UPGRADE
-- ================================================
local upgradeBtn, upgradeToggle, upgradeDot = createFeatureBtn(
    "Money Upgrade",
    "Automatically upgrades lemon generators (Premium)",
    "moneyUpgrade",
    "premium"
)
bindHover(upgradeBtn, palette.cardHover, palette.card)

-- ================================================
-- LOG PANEL (shows recent actions)
-- ================================================
local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, 0, 0, 60)
logLabel.Position = UDim2.new(0, 0, 1, -55)
logLabel.BackgroundTransparency = 1
logLabel.Text = "Ready. Features idle."
logLabel.TextColor3 = palette.textMuted
logLabel.TextSize = 11
logLabel.Font = Enum.Font.Gotham
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.TextWrapped = true
logLabel.Parent = pages

local logHistory = {}
local function addLog(msg)
    table.insert(logHistory, 1, msg)
    if #logHistory > 3 then
        table.remove(logHistory)
    end
    logLabel.Text = table.concat(logHistory, "\n")
end

-- ================================================
-- TOGGLE KEYBIND
-- ================================================
local _visible = true
_uis.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        _visible = not _visible
        mainFrame.Visible = _visible
    end
end)

-- ================================================
-- GAME DATA FETCHING
-- ================================================
local function getPlayerData()
    local data = _plr:FindFirstChild("Data") or _plr:FindFirstChild("leaderstats") or _plr:FindFirstChild("Stats")
    if not data then return nil end

    local money = data:FindFirstChild("Money") or data:FindFirstChild("Cash") or data:FindFirstChild("Coins") or data:FindFirstChild("Currency")
    local lemons = data:FindFirstChild("Lemons") or data:FindFirstChild("Lemon") or data:FindFirstChild("Fruits")

    return {
        money = money and tostring(money.Value) or "Unknown",
        lemons = lemons and tostring(lemons.Value) or "Unknown",
        moneyObj = money,
        lemonObj = lemons,
        folder = data
    }
end

local function updateStats()
    local data = getPlayerData()
    if data then
        moneyLabel.Text = "💰 Money: " .. data.money
        lemonLabel.Text = "🍋 Lemons: " .. data.lemons
    else
        moneyLabel.Text = "💰 Money: N/A"
        lemonLabel.Text = "🍋 Lemons: N/A"
    end
    soldLabel.Text = "Total Sold: " .. tostring(gameState.totalSold)
end

-- Initial stat update
task.spawn(function()
    task.wait(1)
    updateStats()
end)

-- ================================================
-- REMOTE DISCOVERY
-- ================================================
local function findSellRemote()
    if gameState.sellRemote then return gameState.sellRemote end

    local remotes = game:GetService("ReplicatedStorage")
    for _, remote in pairs(remotes:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name:lower()
            if name:find("sell") and (name:find("lemon") or name:find("fruit")) then
                gameState.sellRemote = remote
                addLog("Found sell remote: " .. remote.Name)
                return remote
            end
        end
    end

    -- Fallback: search by common naming patterns
    for _, remote in pairs(remotes:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name:lower()
            if name:find("sell") then
                gameState.sellRemote = remote
                addLog("Found fallback sell remote: " .. remote.Name)
                return remote
            end
        end
    end

    return nil
end

local function findUpgradeRemotes()
    if #gameState.upgradeRemotes > 0 then return gameState.upgradeRemotes end

    local remotes = game:GetService("ReplicatedStorage")
    local found = {}

    for _, remote in pairs(remotes:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            local name = remote.Name:lower()
            if name:find("upgrade") or name:find("buy") or name:find("purchase") then
                table.insert(found, remote)
            end
        end
    end

    gameState.upgradeRemotes = found
    if #found > 0 then
        addLog("Found " .. #found .. " upgrade/buy remotes")
    end
    return found
end

local function findBuyButtons()
    local found = {}
    local gui = _plr:FindFirstChild("PlayerGui")
    if not gui then return found end

    for _, obj in pairs(gui:GetDescendants()) do
        if obj:IsA("TextButton") then
            local name = obj.Name:lower()
            if name:find("buy") or name:find("purchase") or name:find("upgrade") then
                -- Avoid clicking hidden or disabled buttons
                if obj.Visible and obj:IsDescendantOf(_plr.PlayerGui) then
                    table.insert(found, obj)
                end
            end
        end
    end

    return found
end

-- ================================================
-- CORE LOGIC LOOPS
-- ================================================
local function attemptSellLemons()
    if not features.autoSellLemons then return end
    local now = tick()
    if now - gameState.lastSellTime < gameState.sellCooldown then return end

    local data = getPlayerData()
    if not data or not data.lemonObj or data.lemonObj.Value <= 0 then
        return -- No lemons to sell
    end

    local remote = findSellRemote()
    if not remote then
        addLog("No sell remote found")
        return
    end

    local success = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer()
        elseif remote:IsA("RemoteFunction") then
            remote:InvokeServer()
        end
    end)

    if success then
        gameState.lastSellTime = now
        gameState.totalSold = gameState.totalSold + 1
        updateStats()
        addLog("Sold lemons! (Total: " .. gameState.totalSold .. ")")
    else
        addLog("Sell failed - remote error")
    end
end

local function attemptBuyButton()
    if not features.autoBuyButton then return end
    local now = tick()
    if now - gameState.lastBuyTime < gameState.buyCooldown then return end

    local buttons = findBuyButtons()
    if #buttons == 0 then
        return
    end

    -- Pick first available button safely
    for _, btn in ipairs(buttons) do
        if btn.Visible and btn:IsDescendantOf(_plr.PlayerGui) then
            local success = pcall(function()
                btn:Activate()
            end)

            if success then
                gameState.lastBuyTime = now
                addLog("Clicked buy: " .. btn.Name)
                task.wait(0.3) -- Small delay between clicks
            end
            break -- Only click one per cycle
        end
    end
end

local function attemptMoneyUpgrade()
    if not features.moneyUpgrade then return end
    if _tier ~= "Premium" then return end
    local now = tick()
    if now - gameState.lastUpgradeTime < gameState.upgradeCooldown then return end

    local data = getPlayerData()
    if not data or not data.moneyObj then return end

    local remotes = findUpgradeRemotes()
    if #remotes == 0 then
        addLog("No upgrade remotes found")
        return
    end

    -- Try first available upgrade remote
    for _, remote in ipairs(remotes) do
        local success = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer()
            end
        end)

        if success then
            gameState.lastUpgradeTime = now
            addLog("Upgraded via: " .. remote.Name)
            task.wait(0.5)
            break
        end
    end
end

-- ================================================
-- MAIN EXECUTION LOOP
-- ================================================
_activeLoops = {}

local mainLoop = task.spawn(function()
    while true do
        task.wait(0.5)

        -- Refresh stats periodically
        updateStats()

        attemptSellLemons()
        attemptBuyButton()
        attemptMoneyUpgrade()

        -- Update status text
        if features.autoSellLemons then
            subTitleText.Text = "Auto Selling Active"
            subTitleText.TextColor3 = palette.green
        elseif features.autoBuyButton then
            subTitleText.Text = "Auto Buying Active"
            subTitleText.TextColor3 = palette.accent
        elseif features.moneyUpgrade then
            subTitleText.Text = "Upgrading Money (Premium)"
            subTitleText.TextColor3 = palette.gold
        else
            subTitleText.Text = "Lemon Tycoon Automation"
            subTitleText.TextColor3 = palette.textSub
        end
    end
end)

table.insert(_activeLoops, mainLoop)

-- ================================================
-- INITIALIZATION LOG
-- ================================================
addLog("Sell Lemons module loaded")
addLog("Tier: " .. _tier)
addLog("Features ready")

-- Expose for external control
getgenv().BorcaSellLemons = {
    GetState = function()
        return {
            features = features,
            totalSold = gameState.totalSold,
            tier = _tier,
        }
    end,
    StopAll = function()
        features.autoSellLemons = false
        features.autoBuyButton = false
        features.moneyUpgrade = false

        sellToggle.BackgroundColor3 = palette.divider
        sellToggle.Text = "OFF"
        sellDot.BackgroundColor3 = palette.textMuted

        buyToggle.BackgroundColor3 = palette.divider
        buyToggle.Text = "OFF"
        buyDot.BackgroundColor3 = palette.textMuted

        upgradeToggle.BackgroundColor3 = palette.divider
        upgradeToggle.Text = "OFF"
        upgradeDot.BackgroundColor3 = palette.textMuted

        addLog("All features stopped")
    end,
}
