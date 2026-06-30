--[[ 
    BorcaHub // TDS Module
    rev.ULTIMATE — Cyberpunk Neon Handcrafted Interface
]]

local _tier = getgenv().Tier or "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _rs  = game:GetService("RunService")
local _http = game:GetService("HttpService")

local _activeLoops = {}

-- ================================================
-- LOAD MACRO MODULE
-- ================================================
local Macro = {}
local success, result = pcall(function()
    return loadstring(game:HttpGet('https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/Loader/Script/TowerDefensiSimulator/Macro/v1%20-%20Timed/recorder%20v1.lua'))()
end)

if success and result then
    Macro = result
    warn("[BorcaHub] Macro module loaded successfully!")
else
    warn("[BorcaHub] Failed to load macro module: " .. tostring(result))
    -- Create stub functions
    Macro = {
        StartRecording = function() warn("Macro not loaded") return false end,
        StopRecording = function() warn("Macro not loaded") return false end,
        StartPlayback = function() warn("Macro not loaded") return false end,
        StopPlayback = function() warn("Macro not loaded") return false end,
        GetMacroInfo = function() return {ActionCount = 0} end,
    }
end

-- ================================================
-- WARNA & KONFIGURASI - CYBERPUNK NEON THEME
-- ================================================
local palette = {
    bg        = Color3.fromRGB(8, 4, 12),
    panel     = Color3.fromRGB(15, 8, 22),
    sidebar   = Color3.fromRGB(12, 6, 18),
    card      = Color3.fromRGB(20, 10, 30),
    cardHover = Color3.fromRGB(28, 14, 42),
    accent    = Color3.fromRGB(255, 0, 128),
    accent2   = Color3.fromRGB(0, 255, 200),
    gold      = Color3.fromRGB(255, 200, 0),
    goldDim   = Color3.fromRGB(180, 140, 0),
    textMain  = Color3.fromRGB(255, 255, 255),
    textSub   = Color3.fromRGB(180, 180, 200),
    textMuted = Color3.fromRGB(120, 100, 140),
    red       = Color3.fromRGB(255, 50, 80),
    green     = Color3.fromRGB(0, 255, 150),
    divider   = Color3.fromRGB(40, 20, 60),
    execute   = Color3.fromRGB(255, 0, 128),
    close     = Color3.fromRGB(60, 30, 90),
    glow      = Color3.fromRGB(255, 0, 128),
}

-- ================================================
-- DAFTAR FITUR (SIMPLIFIED & CLEAN EXAMPLE)
-- ================================================
local featureList = {
    {
        id = "macro_v1_recorder",
        name = "Macro v1 - Time Based Recorder",
        desc = "Record and playback tower placements with precise timing. Record your strategy and replay it automatically.",
        tier = "premium",
        reqLevel = "Level 0+",
        towers = "Any Tower",
        map = "Any Map",
        running = false,
    },
    {
        id = "example_free",
        name = "Exemple Free Strat",
        desc = "Ini adalah contoh strat gratis yang bisa diakses oleh semua player (Free & Premium).",
        tier = "free",
        reqLevel = "Level 0+",
        towers = "Scout, Sniper, Soldier",
        map = "Grass Isle",
        running = false,
    },
    {
        id = "example_premium",
        name = "Exemple Premium Strat",
        desc = "Ini adalah contoh strat premium. Player Free TIDAK AKAN BISA menekan tombol execute untuk fitur ini.",
        tier = "premium",
        reqLevel = "Level 50+",
        towers = "Accelerator, Engineer, DJ",
        map = "Fallen Wasteland",
        running = false,
    }
}

-- ================================================
-- UTILITAS GUI
-- ================================================
local function mkCorner(p, r) 
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 12); c.Parent = p; return c 
end
local function mkStroke(p, col, th) 
    local s = Instance.new("UIStroke"); s.Color = col or palette.divider; s.Thickness = th or 2; s.Parent = p; return s 
end
local function mkPadding(p, t, b, l, r) 
    local pd = Instance.new("UIPadding"); pd.PaddingTop = UDim.new(0,t); pd.PaddingBottom = UDim.new(0,b); pd.PaddingLeft = UDim.new(0,l); pd.PaddingRight = UDim.new(0,r); pd.Parent = p; return pd 
end
local function mkGradient(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = p
    return g
end

-- ================================================
-- HAPUS GUI LAMA
-- ================================================
local _core = game:GetService("CoreGui")
if _core:FindFirstChild("BorcaHubTDS") then
    _core.BorcaHubTDS:Destroy()
end

-- ================================================
-- STRUKTUR GUI UTAMA - CYBERPUNK DESIGN
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BorcaHubTDS"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local ok, _ = pcall(function() screenGui.Parent = _core end)
if not ok then screenGui.Parent = _plr:WaitForChild("PlayerGui") end

-- Background blur effect
local blur = Instance.new("Blur")
blur.Size = 24
blur.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Root"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 900, 0, 600)
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
mkCorner(mainFrame, 24)

-- Animated gradient background
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 4, 12)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 8, 25)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 4, 12))
})
bgGradient.Rotation = 45
bgGradient.Parent = mainFrame

-- Neon border with animated glow
local borderFrame = Instance.new("Frame")
borderFrame.Name = "NeonBorder"
borderFrame.Size = UDim2.new(1, 4, 1, 4)
borderFrame.Position = UDim2.new(0, -2, 0, -2)
borderFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
borderFrame.BackgroundTransparency = 1
borderFrame.BorderSizePixel = 0
borderFrame.ZIndex = 0
borderFrame.Parent = mainFrame

local borderStroke = Instance.new("UIStroke")
borderStroke.Color = palette.accent
borderStroke.Thickness = 3
borderStroke.Transparency = 0.3
borderStroke.Parent = borderFrame

local borderGlow = Instance.new("UIStroke")
borderGlow.Color = palette.accent2
borderGlow.Thickness = 6
borderGlow.Transparency = 0.7
borderGlow.Parent = borderFrame

-- Animated scanline effect
local scanline = Instance.new("Frame")
scanline.Name = "Scanline"
scanline.Size = UDim2.new(1, 0, 0, 2)
scanline.Position = UDim2.new(0, 0, 0, 0)
scanline.BackgroundColor3 = palette.accent2
scanline.BackgroundTransparency = 0.8
scanline.BorderSizePixel = 0
scanline.ZIndex = 1
scanline.Parent = mainFrame

local scanlineTween = _ts:Create(scanline, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
    Position = UDim2.new(0, 0, 1, 0)
})
scanlineTween:Play()

-- Intro animation with scale and rotation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.Rotation = 180
_ts:Create(mainFrame, TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 900, 0, 600),
    Rotation = 0
}):Play()

-- ================================================
-- TITLE BAR - CYBERPUNK STYLE
-- ================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 85)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

-- Glowing title background
local titleBg = Instance.new("Frame")
titleBg.Name = "TitleBg"
titleBg.Size = UDim2.new(1, -40, 0, 65)
titleBg.Position = UDim2.new(0, 20, 0, 10)
titleBg.BackgroundColor3 = palette.card
titleBg.BackgroundTransparency = 0.5
titleBg.BorderSizePixel = 0
titleBg.Parent = titleBar
mkCorner(titleBg, 16)

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, palette.card),
    ColorSequenceKeypoint.new(0.5, palette.cardHover),
    ColorSequenceKeypoint.new(1, palette.card)
})
titleGradient.Rotation = 90
titleGradient.Parent = titleBg

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = palette.accent
titleStroke.Thickness = 2
titleStroke.Transparency = 0.5
titleStroke.Parent = titleBg

-- Title text with glow effect
local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(0, 300, 1, 0)
titleText.Position = UDim2.new(0, 30, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BORCA"
titleText.TextColor3 = palette.textMain
titleText.TextSize = 36
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBg

local titleGlow = Instance.new("TextStroke")
titleGlow.Color = palette.accent
titleGlow.Thickness = 2
titleGlow.Transparency = 0.5
titleText.TextStroke = titleGlow

local subtitleText = Instance.new("TextLabel")
subtitleText.Name = "Subtitle"
subtitleText.Size = UDim2.new(0, 300, 0, 20)
subtitleText.Position = UDim2.new(0, 30, 1, -25)
subtitleText.BackgroundTransparency = 1
subtitleText.Text = "TOWER DEFENSE"
subtitleText.TextColor3 = palette.accent2
subtitleText.TextSize = 14
subtitleText.Font = Enum.Font.GothamBold
subtitleText.TextXAlignment = Enum.TextXAlignment.Left
subtitleText.Parent = titleBg

-- Animated tier badge
local tagLabel = Instance.new("TextLabel")
tagLabel.Name = "Tag"
tagLabel.Size = UDim2.new(0, 100, 0, 32)
tagLabel.Position = UDim2.new(1, -130, 0.5, -16)
tagLabel.BackgroundColor3 = (_tier == "Premium") and palette.gold or palette.accent
tagLabel.BackgroundTransparency = 0.2
tagLabel.Text = _tier:upper()
tagLabel.TextColor3 = palette.textMain
tagLabel.TextSize = 14
tagLabel.Font = Enum.Font.GothamBold
tagLabel.BorderSizePixel = 0
tagLabel.Parent = titleBg
mkCorner(tagLabel, 8)

local tagStroke = Instance.new("UIStroke")
tagStroke.Color = (_tier == "Premium") and palette.gold or palette.accent
tagStroke.Thickness = 2
tagStroke.Parent = tagLabel

-- Version with cyber style
local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "Ver"
versionLabel.Size = UDim2.new(0, 80, 0, 24)
versionLabel.Position = UDim2.new(1, -200, 1, -32)
versionLabel.BackgroundColor3 = palette.sidebar
versionLabel.BackgroundTransparency = 0.5
versionLabel.Text = "v2.0"
versionLabel.TextColor3 = palette.textMuted
versionLabel.TextSize = 12
versionLabel.Font = Enum.Font.Code
versionLabel.BorderSizePixel = 0
versionLabel.Parent = titleBg
mkCorner(versionLabel, 4)

-- Close button with cyber design
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -48, 0.5, -18)
closeBtn.BackgroundColor3 = palette.red
closeBtn.BackgroundTransparency = 0.3
closeBtn.Text = "✕"
closeBtn.TextColor3 = palette.textMain
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBg
mkCorner(closeBtn, 8)

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = palette.red
closeStroke.Thickness = 2
closeStroke.Parent = closeBtn

-- Dragging Logic
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

-- Body Frame
local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "Body"
bodyFrame.Size = UDim2.new(1, -40, 1, -110)
bodyFrame.Position = UDim2.new(0, 20, 0, 95)
bodyFrame.BackgroundTransparency = 1
bodyFrame.BorderSizePixel = 0
bodyFrame.Parent = mainFrame

-- ================================================
-- PANEL KIRI - CYBERPUNK LIST DESIGN
-- ================================================
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 400, 1, -30)
leftPanel.Position = UDim2.new(0, 20, 0, 15)
leftPanel.BackgroundColor3 = palette.sidebar
leftPanel.BackgroundTransparency = 0.3
leftPanel.BorderSizePixel = 0
leftPanel.Parent = bodyFrame
mkCorner(leftPanel, 20)

local leftStroke = Instance.new("UIStroke")
leftStroke.Color = palette.divider
leftStroke.Thickness = 1
leftStroke.Transparency = 0.5
leftStroke.Parent = leftPanel

local leftGradient = Instance.new("UIGradient")
leftGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, palette.sidebar),
    ColorSequenceKeypoint.new(1, palette.panel)
})
leftGradient.Rotation = 90
leftGradient.Parent = leftPanel

local leftHeader = Instance.new("Frame")
leftHeader.Name = "Header"
leftHeader.Size = UDim2.new(1, -20, 0, 55)
leftHeader.Position = UDim2.new(0, 10, 0, 10)
leftHeader.BackgroundColor3 = palette.card
leftHeader.BackgroundTransparency = 0.5
leftHeader.BorderSizePixel = 0
leftHeader.Parent = leftPanel
mkCorner(leftHeader, 12)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, palette.accent),
    ColorSequenceKeypoint.new(1, palette.accent2)
})
headerGradient.Rotation = 45
headerGradient.Parent = leftHeader

local headerText = Instance.new("TextLabel")
headerText.Size = UDim2.new(1, 0, 1, 0)
headerText.BackgroundTransparency = 1
headerText.Text = "⚡ MODULES"
headerText.TextColor3 = palette.textMain
headerText.TextSize = 18
headerText.Font = Enum.Font.GothamBold
headerText.TextXAlignment = Enum.TextXAlignment.Center
headerText.Parent = leftHeader

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "List"
scrollFrame.Size = UDim2.new(1, -20, 1, -80)
scrollFrame.Position = UDim2.new(0, 10, 0, 70)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 0
scrollFrame.ScrollBarImageColor3 = palette.accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = leftPanel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

-- ================================================
-- PANEL KANAN - CYBERPUNK INFO PANEL
-- ================================================
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(1, -450, 1, -30)
rightPanel.Position = UDim2.new(0, 430, 0, 15)
rightPanel.BackgroundColor3 = palette.panel
rightPanel.BackgroundTransparency = 0.2
rightPanel.BorderSizePixel = 0
rightPanel.Parent = bodyFrame
mkCorner(rightPanel, 20)

local rightGradient = Instance.new("UIGradient")
rightGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, palette.panel),
    ColorSequenceKeypoint.new(1, palette.sidebar)
})
rightGradient.Rotation = 90
rightGradient.Parent = rightPanel

local rightStroke = Instance.new("UIStroke")
rightStroke.Color = palette.divider
rightStroke.Thickness = 1
rightStroke.Transparency = 0.5
rightStroke.Parent = rightPanel

local infoHeader = Instance.new("Frame")
infoHeader.Name = "Header"
infoHeader.Size = UDim2.new(1, -20, 0, 55)
infoHeader.Position = UDim2.new(0, 10, 0, 10)
infoHeader.BackgroundColor3 = palette.card
infoHeader.BackgroundTransparency = 0.5
infoHeader.BorderSizePixel = 0
infoHeader.Parent = rightPanel
mkCorner(infoHeader, 12)

local infoHeaderGradient = Instance.new("UIGradient")
infoHeaderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, palette.accent2),
    ColorSequenceKeypoint.new(1, palette.accent)
})
infoHeaderGradient.Rotation = 45
infoHeaderGradient.Parent = infoHeader

local infoHeaderText = Instance.new("TextLabel")
infoHeaderText.Size = UDim2.new(1, 0, 1, 0)
infoHeaderText.BackgroundTransparency = 1
infoHeaderText.Text = "📊 DETAILS"
infoHeaderText.TextColor3 = palette.textMain
infoHeaderText.TextSize = 18
infoHeaderText.Font = Enum.Font.GothamBold
infoHeaderText.TextXAlignment = Enum.TextXAlignment.Center
infoHeaderText.Parent = infoHeader

local infoContent = Instance.new("TextLabel")
infoContent.Name = "InfoText"
infoContent.Size = UDim2.new(1, -40, 1, -160)
infoContent.Position = UDim2.new(0, 20, 0, 75)
infoContent.BackgroundTransparency = 1
infoContent.Text = "Select a module from the list\nto view details."
infoContent.TextColor3 = palette.textSub
infoContent.TextSize = 16
infoContent.Font = Enum.Font.GothamMedium
infoContent.TextXAlignment = Enum.TextXAlignment.Left
infoContent.TextYAlignment = Enum.TextYAlignment.Top
infoContent.TextWrapped = true
infoContent.RichText = true
infoContent.Parent = rightPanel

-- ================================================
-- BOTTOM BUTTONS - CYBERPUNK STYLE
-- ================================================
local btnRow = Instance.new("Frame")
btnRow.Name = "Buttons"
btnRow.Size = UDim2.new(1, -40, 0, 70)
btnRow.Position = UDim2.new(0, 20, 1, -90)
btnRow.BackgroundTransparency = 1
btnRow.BorderSizePixel = 0
btnRow.Parent = rightPanel

local executeBtn = Instance.new("TextButton")
executeBtn.Name = "ExecBtn"
executeBtn.Size = UDim2.new(1, 0, 1, 0)
executeBtn.Position = UDim2.new(0, 0, 0, 0)
executeBtn.BackgroundColor3 = palette.execute
executeBtn.BackgroundTransparency = 0.3
executeBtn.Text = "▶ EXECUTE"
executeBtn.TextColor3 = palette.textMain
executeBtn.TextSize = 18
executeBtn.Font = Enum.Font.GothamBold
executeBtn.BorderSizePixel = 0
executeBtn.AutoButtonColor = false
executeBtn.Parent = btnRow
mkCorner(executeBtn, 14)

local execGradient = Instance.new("UIGradient")
execGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, palette.execute),
    ColorSequenceKeypoint.new(0.5, palette.accent),
    ColorSequenceKeypoint.new(1, palette.execute)
})
execGradient.Rotation = 45
execGradient.Parent = executeBtn

local execStroke = Instance.new("UIStroke")
execStroke.Color = palette.accent
execStroke.Thickness = 2
execStroke.Parent = executeBtn

local execGlow = Instance.new("Frame")
execGlow.Name = "Glow"
execGlow.Size = UDim2.new(1, 10, 1, 10)
execGlow.Position = UDim2.new(0, -5, 0, -5)
execGlow.BackgroundColor3 = palette.execute
execGlow.BackgroundTransparency = 0.8
execGlow.BorderSizePixel = 0
execGlow.ZIndex = -1
execGlow.Parent = executeBtn
mkCorner(execGlow, 16)

-- ================================================
-- LOGIKA SELEKSI FITUR
-- ================================================
local selectedFeature = nil
local cardRefs = {}

local function selectFeature(feat)
    selectedFeature = feat
    
    -- Format Info hanya berisi (Required Level, Tower, Map, Description) sesuai request
    infoContent.Text = string.format(
        "<b>• Required Level:</b> %s\n\n" ..
        "<b>• Tower:</b> %s\n\n" ..
        "<b>• Map:</b> %s\n\n" ..
        "<b>• Description:</b> %s",
        feat.reqLevel,
        feat.towers,
        feat.map,
        feat.desc
    )
    
    -- Update highlights
    for id, card in pairs(cardRefs) do
        if id == feat.id then
            _ts:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = palette.cardHover}):Play()
            if card:FindFirstChild("SelectBar") then
                _ts:Create(card.SelectBar, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
            end
        else
            _ts:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = palette.card}):Play()
            if card:FindFirstChild("SelectBar") then
                _ts:Create(card.SelectBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            end
        end
    end
end

-- ================================================
-- POPUP NOTIFIKASI - CYBERPUNK STYLE
-- ================================================
local function showAccessDenied()
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 480, 0, 180)
    popup.Position = UDim2.new(0.5, -240, 0.5, -90)
    popup.BackgroundColor3 = palette.bg
    popup.BackgroundTransparency = 0.95
    popup.BorderSizePixel = 0
    popup.ZIndex = 500
    popup.Parent = mainFrame
    mkCorner(popup, 20)
    
    local popupGradient = Instance.new("UIGradient")
    popupGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette.bg),
        ColorSequenceKeypoint.new(1, palette.panel)
    })
    popupGradient.Rotation = 45
    popupGradient.Parent = popup
    
    local popupStroke = Instance.new("UIStroke")
    popupStroke.Color = palette.red
    popupStroke.Thickness = 3
    popupStroke.Parent = popup
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.Text = "🔒 ACCESS DENIED"
    title.TextColor3 = palette.red
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 501
    title.Parent = popup
    
    local titleStroke = Instance.new("TextStroke")
    titleStroke.Color = palette.red
    titleStroke.Thickness = 2
    title.TextStroke = titleStroke

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -50, 0, 70)
    msg.Position = UDim2.new(0, 25, 0, 65)
    msg.BackgroundTransparency = 1
    msg.Text = "This feature is exclusive to Premium users!\nUpgrade your key to access this module."
    msg.TextColor3 = palette.textSub
    msg.TextSize = 16
    msg.Font = Enum.Font.GothamMedium
    msg.TextWrapped = true
    msg.ZIndex = 501
    msg.Parent = popup

    local okBtn = Instance.new("TextButton")
    okBtn.Size = UDim2.new(0, 140, 0, 42)
    okBtn.Position = UDim2.new(0.5, -70, 0, 125)
    okBtn.BackgroundColor3 = palette.red
    okBtn.BackgroundTransparency = 0.3
    okBtn.Text = "UNDERSTOOD"
    okBtn.TextColor3 = palette.textMain
    okBtn.TextSize = 16
    okBtn.Font = Enum.Font.GothamBold
    okBtn.BorderSizePixel = 0
    okBtn.ZIndex = 501
    okBtn.Parent = popup
    mkCorner(okBtn, 10)
    
    local okStroke = Instance.new("UIStroke")
    okStroke.Color = palette.red
    okStroke.Thickness = 2
    okStroke.Parent = okBtn

    okBtn.MouseButton1Click:Connect(function()
        _ts:Create(popup, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.35, function() popup:Destroy() end)
    end)
end

-- ================================================
-- RENDER DAFTAR FITUR - CYBERPUNK CARDS
-- ================================================
for i, feat in ipairs(featureList) do
    local tierColor = (feat.tier == "premium") and palette.gold or palette.accent
    local locked = (feat.tier == "premium" and _tier ~= "Premium")
    
    local card = Instance.new("TextButton")
    card.Name = "Card_" .. feat.id
    card.Size = UDim2.new(1, -10, 0, 95)
    card.BackgroundColor3 = palette.card
    card.BackgroundTransparency = 0.3
    card.Text = ""
    card.BorderSizePixel = 0
    card.AutoButtonColor = false
    card.LayoutOrder = i
    card.ClipsDescendants = true
    card.Parent = scrollFrame
    mkCorner(card, 14)
    
    local cardGradient = Instance.new("UIGradient")
    cardGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, palette.card),
        ColorSequenceKeypoint.new(1, palette.cardHover)
    })
    cardGradient.Rotation = 90
    cardGradient.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = tierColor
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.7
    cardStroke.Parent = card
    
    -- Cyber selection indicator
    local selBar = Instance.new("Frame")
    selBar.Name = "SelectBar"
    selBar.Size = UDim2.new(0, 6, 0.8, 0)
    selBar.Position = UDim2.new(0, 0, 0.1, 0)
    selBar.BackgroundColor3 = tierColor
    selBar.BackgroundTransparency = 1
    selBar.BorderSizePixel = 0
    selBar.Parent = card
    mkCorner(selBar, 4)
    
    -- Glowing tier indicator
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(0, 18, 0, 18)
    dot.BackgroundColor3 = tierColor
    dot.BackgroundTransparency = 0.3
    dot.BorderSizePixel = 0
    dot.Parent = card
    mkCorner(dot, 9)
    
    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = tierColor
    dotStroke.Thickness = 2
    dotStroke.Parent = dot
    
    -- Feature name with glow
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -65, 0, 30)
    nameLabel.Position = UDim2.new(0, 45, 0, 12)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = feat.name .. (locked and " 🔒" or "")
    nameLabel.TextColor3 = locked and palette.textMuted or palette.textMain
    nameLabel.TextSize = 18
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    if not locked then
        local nameStroke = Instance.new("TextStroke")
        nameStroke.Color = tierColor
        nameStroke.Thickness = 1
        nameStroke.Transparency = 0.7
        nameLabel.TextStroke = nameStroke
    end
    
    -- Description with cyber style
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -65, 0, 24)
    descLabel.Position = UDim2.new(0, 45, 0, 45)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = feat.desc:split("\n")[1]
    descLabel.TextColor3 = palette.textMuted
    descLabel.TextSize = 13
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
    descLabel.Parent = card
    
    -- Running indicator with pulse effect
    local runDot = Instance.new("Frame")
    runDot.Name = "RunDot"
    runDot.Size = UDim2.new(0, 12, 0, 12)
    runDot.Position = UDim2.new(1, -28, 0.5, -6)
    runDot.BackgroundColor3 = palette.green
    runDot.BackgroundTransparency = 1
    runDot.BorderSizePixel = 0
    runDot.Parent = card
    mkCorner(runDot, 6)
    
    local runStroke = Instance.new("UIStroke")
    runStroke.Color = palette.green
    runStroke.Thickness = 2
    runStroke.Parent = runDot
    
    cardRefs[feat.id] = card
    
    -- Enhanced hover effects with scale
    card.MouseEnter:Connect(function()
        if selectedFeature ~= feat then
            _ts:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = palette.cardHover,
                Size = UDim2.new(1, -5, 0, 98)
            }):Play()
            cardStroke.Transparency = 0.3
        end
    end)
    card.MouseLeave:Connect(function()
        if selectedFeature ~= feat then
            _ts:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = palette.card,
                Size = UDim2.new(1, -10, 0, 95)
            }):Play()
            cardStroke.Transparency = 0.7
        end
    end)
    
    card.MouseButton1Click:Connect(function()
        selectFeature(feat)
    end)
end

-- ================================================
-- PROSES EKSEKUSI - CYBERPUNK NOTIFICATIONS
-- ================================================
local function notifyPopup(msg, col)
    local nf = Instance.new("Frame")
    nf.Size = UDim2.new(0, 350, 0, 55)
    nf.Position = UDim2.new(0.5, -175, 0, -60)
    nf.BackgroundColor3 = col or palette.accent
    nf.BackgroundTransparency = 0.3
    nf.BorderSizePixel = 0
    nf.ZIndex = 100
    nf.Parent = mainFrame
    mkCorner(nf, 12)
    
    local nfGradient = Instance.new("UIGradient")
    nfGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, col or palette.accent),
        ColorSequenceKeypoint.new(1, palette.accent2)
    })
    nfGradient.Rotation = 45
    nfGradient.Parent = nf
    
    local nfStroke = Instance.new("UIStroke")
    nfStroke.Color = col or palette.accent
    nfStroke.Thickness = 2
    nfStroke.Parent = nf
    
    local nt = Instance.new("TextLabel")
    nt.Size = UDim2.new(1, 0, 1, 0)
    nt.BackgroundTransparency = 1
    nt.Text = msg
    nt.TextColor3 = palette.textMain
    nt.TextSize = 16
    nt.Font = Enum.Font.GothamBold
    nt.Parent = nf
    
    _ts:Create(nf, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -175, 0, 15)
    }):Play()
    
    task.delay(2.5, function()
        _ts:Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0.5, -175, 0, -65),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.35, function() nf:Destroy() end)
    end)
end

executeBtn.MouseButton1Click:Connect(function()
    if not selectedFeature then
        notifyPopup("Select a script first!", palette.red)
        return
    end
    
    local feat = selectedFeature
    
    -- JIKA PLAYER ADALAH FREE DAN MENCOBA MENGGUNAKAN FITUR PREMIUM
    if feat.tier == "premium" and _tier ~= "Premium" then
        showAccessDenied()
        return
    end
    
    -- Toggle running state
    feat.running = not feat.running
    local card = cardRefs[feat.id]
    if card and card:FindFirstChild("RunDot") then
        _ts:Create(card.RunDot, TweenInfo.new(0.2), {
            BackgroundTransparency = feat.running and 0 or 1
        }):Play()
    end
    
    -- Execute macro logic
    if feat.id == "macro_v1_recorder" then
        if feat.running then
            -- Start recording
            if Macro.StartRecording then
                local success = Macro.StartRecording()
                if success then
                    notifyPopup("🔴 Recording started!", palette.execute)
                    
                    -- Auto-stop recording after 5 minutes or add manual stop
                    task.spawn(function()
                        while feat.running do
                            task.wait(0.1)
                            -- Check if user wants to stop (could add keybind)
                        end
                        if Macro.StopRecording then
                            Macro.StopRecording()
                        end
                    end)
                else
                    notifyPopup("Failed to start recording", palette.red)
                    feat.running = false
                    if card and card:FindFirstChild("RunDot") then
                        _ts:Create(card.RunDot, TweenInfo.new(0.2), {
                            BackgroundTransparency = 1
                        }):Play()
                    end
                end
            else
                notifyPopup("Macro module not loaded", palette.red)
                feat.running = false
            end
        else
            -- Stop recording and show info
            if Macro.StopRecording then
                Macro.StopRecording()
                local info = Macro.GetMacroInfo and Macro.GetMacroInfo() or {}
                notifyPopup("⏹ Recording stopped! Actions: " .. (info.ActionCount or 0), palette.close)
            end
        end
    else
        -- Other features
        if feat.running then
            notifyPopup("▶ " .. feat.name .. " activated", palette.execute)
        else
            notifyPopup("⏹ " .. feat.name .. " stopped", palette.close)
        end
    end
end)

-- Enhanced hover effects for buttons
for _, btn in pairs({closeBtn, executeBtn}) do
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.1,
            Size = (btn == executeBtn) and UDim2.new(1, 5, 1, 5) or UDim2.new(0, 38, 0, 38)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.3,
            Size = (btn == executeBtn) and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 36, 0, 36)
        }):Play()
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    _activeLoops = {}
    scanlineTween:Cancel()
    _ts:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        Rotation = -180,
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.55, function() screenGui:Destroy() end)
end)

-- Toggle keybind RightControl
local _visible = true
_uis.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        _visible = not _visible
        mainFrame.Visible = _visible
    end
end)

-- Default selection
selectFeature(featureList[1])
