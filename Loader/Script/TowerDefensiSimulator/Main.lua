--[[ 
    Ocean Hub // TDS Module
    rev.ULTIMATE — Cyberpunk Neon Handcrafted Interface with Integrated Timed Macro V1
]]

local _tier = getgenv().Tier or "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _rs  = game:GetService("RunService")
local _http = game:GetService("HttpService")

-- Macro system state (local for Main.lua hook-based recording)
-- This is SEPARATE from _G.OceanMacro used by recorder v1.lua
local _recording = false
local _replaying = false
local _startTick = 0
local _macroData = {}
local _activeLoops = {}

-- ================================================
-- COLORS & CONFIGURATION - OCEAN WAVE THEME
-- ================================================
local palette = {
    bg        = Color3.fromRGB(11, 19, 43),
    panel     = Color3.fromRGB(28, 37, 65),
    sidebar   = Color3.fromRGB(20, 28, 50),
    card      = Color3.fromRGB(22, 32, 55),
    cardHover = Color3.fromRGB(35, 50, 75),
    accent    = Color3.fromRGB(0, 180, 216),
    accent2   = Color3.fromRGB(144, 224, 239),
    gold      = Color3.fromRGB(255, 200, 0),
    goldDim   = Color3.fromRGB(200, 160, 0),
    textMain  = Color3.fromRGB(224, 251, 252),
    textSub   = Color3.fromRGB(170, 215, 225),
    textMuted = Color3.fromRGB(100, 140, 160),
    red       = Color3.fromRGB(255, 80, 80),
    green     = Color3.fromRGB(0, 220, 120),
    divider   = Color3.fromRGB(30, 45, 65),
    execute   = Color3.fromRGB(0, 180, 216),
    close     = Color3.fromRGB(60, 30, 90),
    glow      = Color3.fromRGB(0, 180, 216),
}

-- ================================================
-- FEATURE LIST
-- ================================================
local featureList = {
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
    },
    {
        id = "macro_v1_recorder",
        name = "Macro v1 - Time Based Recorder",
        desc = "Merekam dan memutar kembali penempatan tower dengan waktu yang presisi secara otomatis.",
        tier = "premium",
        reqLevel = "Level 15+",
        towers = "Semua Tower",
        map = "Semua Map",
        running = false,
    }
}

-- ================================================
-- GUI UTILITIES
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
-- Remove old GUI
-- ================================================
local _core = game:GetService("CoreGui")
if _core:FindFirstChild("OceanHubTDS") then
    _core.OceanHubTDS:Destroy()
end

-- ================================================
-- MAIN GUI STRUCTURE - OCEAN WAVE DESIGN
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "OceanHubTDS"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local ok, _ = pcall(function() screenGui.Parent = _core end)
if not ok then screenGui.Parent = _plr:WaitForChild("PlayerGui") end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Root"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 850, 0, 550)
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui
mkCorner(mainFrame, 16)

-- Corner light effects at 4 corners (Cyan + Aqua, extending outward)
local function createCornerGlow(name, xScale, xOff, yScale, yOff, color1, color2)
    -- Layer 1 (besar)
    local g1 = Instance.new("ImageLabel")
    g1.Name = name .. "_1"
    g1.Size = UDim2.new(0, 140, 0, 140)
    g1.Position = UDim2.new(xScale, xOff, yScale, yOff)
    g1.AnchorPoint = Vector2.new(0.5, 0.5)
    g1.BackgroundTransparency = 1
    g1.Image = "rbxassetid://5028857084"
    g1.ImageColor3 = color1
    g1.ImageTransparency = 0.2
    g1.ZIndex = -1
    g1.Parent = mainFrame
    _ts:Create(g1, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    _ts:Create(g1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.5}):Play()
    
    -- Layer 2 (lebih kecil, warna berbeda, rotasi berlawanan)
    local g2 = Instance.new("ImageLabel")
    g2.Name = name .. "_2"
    g2.Size = UDim2.new(0, 80, 0, 80)
    g2.Position = UDim2.new(xScale, xOff, yScale, yOff)
    g2.AnchorPoint = Vector2.new(0.5, 0.5)
    g2.BackgroundTransparency = 1
    g2.Image = "rbxassetid://5028857084"
    g2.ImageColor3 = color2
    g2.ImageTransparency = 0.3
    g2.ZIndex = -1
    g2.Parent = mainFrame
    _ts:Create(g2, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = -360}):Play()
    _ts:Create(g2, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.6}):Play()
end

-- Corner glow at all 4 corners (Electric Cyan + Neon Aqua, extending outward)
createCornerGlow("TL", 0, -25, 0, -25, palette.accent, palette.accent2)
createCornerGlow("TR", 1, 25, 0, -25, palette.accent2, palette.accent)
createCornerGlow("BL", 0, -25, 1, 25, palette.accent2, palette.accent)
createCornerGlow("BR", 1, 25, 1, 25, palette.accent, palette.accent2)

-- Intro Animation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundTransparency = 1
_ts:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 460, 0, 340),
    BackgroundTransparency = 0
}):Play()

-- ================================================
-- TITLE BAR - OCEAN WAVE STYLE
-- ================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 70)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(0, 400, 1, 0)
titleText.Position = UDim2.new(0, 24, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "OCEAN HUB"
titleText.TextColor3 = palette.textMain
titleText.TextSize = 32
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local tagLabel = Instance.new("TextLabel")
tagLabel.Name = "Tag"
tagLabel.Size = UDim2.new(0, 110, 0, 34)
tagLabel.Position = UDim2.new(0, 220, 0.5, -17)
tagLabel.BackgroundColor3 = (_tier == "Premium") and palette.gold or palette.accent
tagLabel.BackgroundTransparency = 0.15
tagLabel.Text = _tier:upper()
tagLabel.TextColor3 = palette.textMain
tagLabel.TextSize = 18
tagLabel.Font = Enum.Font.GothamBold
tagLabel.BorderSizePixel = 0
tagLabel.Parent = titleBar
mkCorner(tagLabel, 6)

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "Ver"
versionLabel.Size = UDim2.new(0, 120, 1, 0)
versionLabel.Position = UDim2.new(1, -195, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0"
versionLabel.TextColor3 = palette.textMuted
versionLabel.TextSize = 20
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = titleBar

-- Close button (X) top right
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -54, 0.5, -20)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
mkCorner(closeBtn, 8)

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

-- Title bar divider
local titleDiv = Instance.new("Frame")
titleDiv.Size = UDim2.new(1, -40, 0, 2)
titleDiv.Position = UDim2.new(0, 20, 0, 70)
titleDiv.BackgroundColor3 = palette.divider
titleDiv.BorderSizePixel = 0
titleDiv.Parent = mainFrame

-- Body Frame
local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "Body"
bodyFrame.Size = UDim2.new(1, 0, 1, -80)
bodyFrame.Position = UDim2.new(0, 0, 0, 80)
bodyFrame.BackgroundTransparency = 1
bodyFrame.BorderSizePixel = 0
bodyFrame.Parent = mainFrame

-- ================================================
-- LEFT PANEL: FEATURES LIST
-- ================================================
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 380, 1, -20)
leftPanel.Position = UDim2.new(0, 20, 0, 6)
leftPanel.BackgroundColor3 = palette.sidebar
leftPanel.BorderSizePixel = 0
leftPanel.Parent = bodyFrame
mkCorner(leftPanel, 12)
mkStroke(leftPanel, palette.divider, 1)

local leftHeader = Instance.new("TextLabel")
leftHeader.Size = UDim2.new(1, 0, 0, 50)
leftHeader.Position = UDim2.new(0, 0, 0, 0)
leftHeader.BackgroundTransparency = 1
leftHeader.Text = "Features"
leftHeader.TextColor3 = palette.textSub
leftHeader.TextSize = 22
leftHeader.Font = Enum.Font.GothamBold
leftHeader.TextXAlignment = Enum.TextXAlignment.Left
leftHeader.Parent = leftPanel
mkPadding(leftHeader, 0, 0, 20, 0)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "List"
scrollFrame.Size = UDim2.new(1, -16, 1, -60)
scrollFrame.Position = UDim2.new(0, 8, 0, 50)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = palette.accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = leftPanel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

-- ================================================
-- RIGHT PANEL: DETAILS & INFO
-- ================================================
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(1, -430, 1, -20)
rightPanel.Position = UDim2.new(0, 410, 0, 6)
rightPanel.BackgroundColor3 = palette.panel
rightPanel.BorderSizePixel = 0
rightPanel.Parent = bodyFrame
mkCorner(rightPanel, 12)
mkStroke(rightPanel, palette.divider, 1)

local infoHeader = Instance.new("TextLabel")
infoHeader.Size = UDim2.new(1, 0, 0, 50)
infoHeader.BackgroundTransparency = 1
infoHeader.Text = "Information"
infoHeader.TextColor3 = palette.textMain
infoHeader.TextSize = 22
infoHeader.Font = Enum.Font.GothamBold
infoHeader.TextXAlignment = Enum.TextXAlignment.Left
infoHeader.Parent = rightPanel
mkPadding(infoHeader, 0, 0, 20, 0)

local infoContent = Instance.new("TextLabel")
infoContent.Name = "InfoText"
infoContent.Size = UDim2.new(1, -40, 0, 190)
infoContent.Position = UDim2.new(0, 20, 0, 60)
infoContent.BackgroundTransparency = 1
infoContent.Text = "Select a script from the list\nto view details."
infoContent.TextColor3 = palette.textSub
infoContent.TextSize = 18
infoContent.Font = Enum.Font.GothamMedium
infoContent.TextXAlignment = Enum.TextXAlignment.Left
infoContent.TextYAlignment = Enum.TextYAlignment.Top
infoContent.TextWrapped = true
infoContent.RichText = true
infoContent.Parent = rightPanel

-- ================================================
-- DYNAMIC WORKSPACE: TIMED MACRO V1 PANEL
-- ================================================
local macroArea = Instance.new("Frame")
macroArea.Name = "MacroArea"
macroArea.Size = UDim2.new(1, -40, 0, 160)
macroArea.Position = UDim2.new(0, 20, 0, 260)
macroArea.BackgroundTransparency = 1
macroArea.Visible = false
macroArea.Parent = rightPanel

local mRecBtn = Instance.new("TextButton")
mRecBtn.Size = UDim2.new(0.48, 0, 0, 40)
mRecBtn.BackgroundColor3 = palette.red
mRecBtn.Text = "⏺ Record"
mRecBtn.TextColor3 = palette.textMain
mRecBtn.TextSize = 16
mRecBtn.Font = Enum.Font.GothamBold
mRecBtn.BorderSizePixel = 0
mRecBtn.Parent = macroArea
mkCorner(mRecBtn, 8)

local mPlayBtn = Instance.new("TextButton")
mPlayBtn.Size = UDim2.new(0.48, 0, 0, 40)
mPlayBtn.Position = UDim2.new(0.52, 0, 0, 0)
mPlayBtn.BackgroundColor3 = palette.green
mPlayBtn.Text = "▶ Play"
mPlayBtn.TextColor3 = palette.bg
mPlayBtn.TextSize = 16
mPlayBtn.Font = Enum.Font.GothamBold
mPlayBtn.BorderSizePixel = 0
mPlayBtn.Parent = macroArea
mkCorner(mPlayBtn, 8)

local ioBox = Instance.new("TextBox")
ioBox.Size = UDim2.new(1, 0, 0, 40)
ioBox.Position = UDim2.new(0, 0, 0, 50)
ioBox.BackgroundColor3 = palette.card
ioBox.Text = ""
ioBox.PlaceholderText = "Paste macro encoded string here..."
ioBox.PlaceholderColor3 = palette.textMuted
ioBox.TextColor3 = palette.textMain
ioBox.TextSize = 12
ioBox.Font = Enum.Font.Code
ioBox.BorderSizePixel = 0
ioBox.ClearTextOnFocus = false
ioBox.Parent = macroArea
mkCorner(ioBox, 6)
mkStroke(ioBox, palette.divider, 1)
mkPadding(ioBox, 0, 0, 10, 10)

local mImportBtn = Instance.new("TextButton")
mImportBtn.Size = UDim2.new(0.48, 0, 0, 36)
mImportBtn.Position = UDim2.new(0, 0, 0, 100)
mImportBtn.BackgroundColor3 = palette.accent
mImportBtn.Text = "Import"
mImportBtn.TextColor3 = palette.textMain
mImportBtn.TextSize = 14
mImportBtn.Font = Enum.Font.GothamBold
mImportBtn.BorderSizePixel = 0
mImportBtn.Parent = macroArea
mkCorner(mImportBtn, 6)

local mExportBtn = Instance.new("TextButton")
mExportBtn.Size = UDim2.new(0.48, 0, 0, 36)
mExportBtn.Position = UDim2.new(0.52, 0, 0, 100)
mExportBtn.BackgroundColor3 = palette.gold
mExportBtn.Text = "Export"
mExportBtn.TextColor3 = palette.bg
mExportBtn.TextSize = 14
mExportBtn.Font = Enum.Font.GothamBold
mExportBtn.BorderSizePixel = 0
mExportBtn.Parent = macroArea
mkCorner(mExportBtn, 6)

local macroStatus = Instance.new("TextLabel")
macroStatus.Size = UDim2.new(1, 0, 0, 20)
macroStatus.Position = UDim2.new(0, 0, 0, 140)
macroStatus.BackgroundTransparency = 1
macroStatus.Text = "Status: Idle — No macro data"
macroStatus.TextColor3 = palette.textMuted
macroStatus.TextSize = 12
macroStatus.Font = Enum.Font.Gotham
macroStatus.TextXAlignment = Enum.TextXAlignment.Left
macroStatus.Parent = macroArea

-- ================================================
-- BOTTOM BUTTONS (EXECUTE)
-- ================================================
local btnRow = Instance.new("Frame")
btnRow.Name = "Buttons"
btnRow.Size = UDim2.new(1, -40, 0, 60)
btnRow.Position = UDim2.new(0, 20, 1, -80)
btnRow.BackgroundTransparency = 1
btnRow.BorderSizePixel = 0
btnRow.Parent = rightPanel

local executeBtn = Instance.new("TextButton")
executeBtn.Name = "ExecBtn"
executeBtn.Size = UDim2.new(1, 0, 1, 0)
executeBtn.Position = UDim2.new(0, 0, 0, 0)
executeBtn.BackgroundColor3 = palette.execute
executeBtn.Text = "Execute"
executeBtn.TextColor3 = palette.textMain
executeBtn.TextSize = 20
executeBtn.Font = Enum.Font.GothamBold
executeBtn.BorderSizePixel = 0
executeBtn.AutoButtonColor = false
executeBtn.Parent = btnRow
mkCorner(executeBtn, 10)

-- ================================================
-- ACCESS DENIED POPUP
-- ================================================
local function showAccessDenied()
    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 450, 0, 160)
    popup.Position = UDim2.new(0.5, -225, 0.5, -80)
    popup.BackgroundColor3 = palette.bg
    popup.BorderSizePixel = 0
    popup.ZIndex = 500
    popup.Parent = mainFrame
    mkCorner(popup, 12)
    
    local stroke = mkStroke(popup, palette.red, 3)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "🔒 ACCESS DENIED"
    title.TextColor3 = palette.red
    title.TextSize = 26
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 501
    title.Parent = popup

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -40, 0, 60)
    msg.Position = UDim2.new(0, 20, 0, 50)
    msg.BackgroundTransparency = 1
    msg.Text = "Fitur ini hanya untuk pengguna Premium!\nUpgrade key Anda untuk mengakses fitur ini."
    msg.TextColor3 = palette.textSub
    msg.TextSize = 16
    msg.Font = Enum.Font.GothamMedium
    msg.ZIndex = 501
    msg.Parent = popup

    local okBtn = Instance.new("TextButton")
    okBtn.Size = UDim2.new(0, 120, 0, 36)
    okBtn.Position = UDim2.new(0.5, -60, 0, 110)
    okBtn.BackgroundColor3 = palette.close
    okBtn.Text = "OK"
    okBtn.TextColor3 = palette.textMain
    okBtn.TextSize = 16
    okBtn.Font = Enum.Font.GothamBold
    okBtn.BorderSizePixel = 0
    okBtn.ZIndex = 501
    okBtn.Parent = popup
    mkCorner(okBtn, 6)

    okBtn.MouseButton1Click:Connect(function()
        popup:Destroy()
    end)
end

-- ================================================
-- FEATURE SELECTION LOGIC
-- ================================================
local selectedFeature = nil
local cardRefs = {}

local function selectFeature(feat)
    selectedFeature = feat
    
    -- Format Info
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
    
    -- Tampilkan atau Sembunyikan Area UI Macro Controls
    if feat.id == "macro_v1_recorder" then
        macroArea.Visible = true
    else
        macroArea.Visible = false
    end
    
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
-- RENDER FEATURE LIST
-- ================================================
for i, feat in ipairs(featureList) do
    local tierColor = (feat.tier == "premium") and palette.gold or palette.accent
    local locked = (feat.tier == "premium" and _tier ~= "Premium")
    
    local card = Instance.new("TextButton")
    card.Name = "Card_" .. feat.id
    card.Size = UDim2.new(1, -8, 0, 80)
    card.BackgroundColor3 = palette.card
    card.Text = ""
    card.BorderSizePixel = 0
    card.AutoButtonColor = false
    card.LayoutOrder = i
    card.ClipsDescendants = true
    card.Parent = scrollFrame
    mkCorner(card, 8)
    
    -- Selection bar kiri
    local selBar = Instance.new("Frame")
    selBar.Name = "SelectBar"
    selBar.Size = UDim2.new(0, 5, 0.7, 0)
    selBar.Position = UDim2.new(0, 0, 0.15, 0)
    selBar.BackgroundColor3 = tierColor
    selBar.BackgroundTransparency = 1
    selBar.BorderSizePixel = 0
    selBar.Parent = card
    mkCorner(selBar, 3)
    
    -- Dot indikator tier
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = UDim2.new(0, 16, 0, 16)
    dot.BackgroundColor3 = tierColor
    dot.BorderSizePixel = 0
    dot.Parent = card
    mkCorner(dot, 7)
    
    -- Nama fitur
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -55, 0, 26)
    nameLabel.Position = UDim2.new(0, 40, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = feat.name .. (locked and "  🔒" or "")
    nameLabel.TextColor3 = locked and palette.textMuted or palette.textMain
    nameLabel.TextSize = 22
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Deskripsi singkat
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -55, 0, 22)
    descLabel.Position = UDim2.new(0, 40, 0, 40)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = feat.desc:split("\n")[1]
    descLabel.TextColor3 = palette.textMuted
    descLabel.TextSize = 15
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
    descLabel.Parent = card
    
    -- Running indicator
    local runDot = Instance.new("Frame")
    runDot.Name = "RunDot"
    runDot.Size = UDim2.new(0, 10, 0, 10)
    runDot.Position = UDim2.new(1, -26, 0.5, -5)
    runDot.BackgroundColor3 = palette.green
    runDot.BackgroundTransparency = 1
    runDot.BorderSizePixel = 0
    runDot.Parent = card
    mkCorner(runDot, 5)
    
    cardRefs[feat.id] = card
    
    -- Hover effects
    card.MouseEnter:Connect(function()
        if selectedFeature ~= feat then
            _ts:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = palette.cardHover}):Play()
        end
    end)
    card.MouseLeave:Connect(function()
        if selectedFeature ~= feat then
            _ts:Create(card, TweenInfo.new(0.15), {BackgroundColor3 = palette.card}):Play()
        end
    end)
    
    card.MouseButton1Click:Connect(function()
        selectFeature(feat)
    end)
end

-- ================================================
-- EXECUTION & NOTIFICATION LOGIC
-- ================================================
local function notifyPopup(msg, col)
    local nf = Instance.new("Frame")
    nf.Size = UDim2.new(0, 320, 0, 50)
    nf.Position = UDim2.new(0.5, -160, 0, -55)
    nf.BackgroundColor3 = col or palette.accent
    nf.BorderSizePixel = 0
    nf.ZIndex = 100
    nf.Parent = mainFrame
    mkCorner(nf, 10)
    
    local nt = Instance.new("TextLabel")
    nt.Size = UDim2.new(1, 0, 1, 0)
    nt.BackgroundTransparency = 1
    nt.Text = msg
    nt.TextColor3 = palette.textMain
    nt.TextSize = 18
    nt.Font = Enum.Font.GothamBold
    nt.Parent = nf
    
    _ts:Create(nf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -160, 0, 12)
    }):Play()
    
    task.delay(2.2, function()
        _ts:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0.5, -160, 0, -60),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.3, function() nf:Destroy() end)
    end)
end

-- ================================================
-- TIMED MACRO V1 RECORDER LOGIC (TIME BASED)
-- ================================================
local function startMacroRecord()
    _recording = true
    _startTick = tick()
    _macroData = {}
    mRecBtn.Text = "⏹ Stop Rec"
    mRecBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    macroStatus.Text = "Status: Recording... (Time-based)"
    macroStatus.TextColor3 = palette.red

    -- Setup Metatable Hook untuk merekam remote calls (TDS game remotes)
    local rawMT = getrawmetatable and getrawmetatable(game)
    if rawMT and setreadonly then
        local oldNC = rawMT.__namecall
        setreadonly(rawMT, false)
        rawMT.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if _recording and method == "InvokeServer" and (self.Name == "RemoteFunction" or self.Name == "RF") then
                table.insert(_macroData, {
                    time = tick() - _startTick,
                    type = "RF",
                    remote = self.Name,
                    args = args
                })
                macroStatus.Text = "Status: Recorded " .. #_macroData .. " actions"
            elseif _recording and method == "FireServer" and (self.Name == "RemoteEvent" or self.Name == "RE") then
                table.insert(_macroData, {
                    time = tick() - _startTick,
                    type = "RE",
                    remote = self.Name,
                    args = args
                })
                macroStatus.Text = "Status: Recorded " .. #_macroData .. " actions"
            end
            return oldNC(self, ...)
        end)
        setreadonly(rawMT, true)
    else
        -- Fallback if executor doesn't support metatable hook (simulate click)
        task.spawn(function()
            while _recording do
                local mouse = _plr:GetMouse()
                if _uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    table.insert(_macroData, {
                        time = tick() - _startTick,
                        type = "Click",
                        pos = {mouse.X, mouse.Y},
                        hit = mouse.Hit and {mouse.Hit.X, mouse.Hit.Y, mouse.Hit.Z} or nil
                    })
                    macroStatus.Text = "Status: Recorded " .. #_macroData .. " actions"
                    task.wait(0.2)
                end
                task.wait(0.05)
            end
        end)
    end
end

local function stopMacroRecord()
    _recording = false
    mRecBtn.Text = "⏺ Record"
    mRecBtn.BackgroundColor3 = palette.red
    macroStatus.Text = "Status: Saved " .. #_macroData .. " timed actions."
    macroStatus.TextColor3 = palette.textSub
end

local function playMacro()
    if #_macroData == 0 then
        macroStatus.Text = "Status: No macro data to play"
        macroStatus.TextColor3 = palette.red
        return
    end

    _replaying = true
    mPlayBtn.Text = "⏹ Stop Play"
    mPlayBtn.BackgroundColor3 = palette.red
    macroStatus.Text = "Status: Replaying timed actions..."
    macroStatus.TextColor3 = palette.green

    task.spawn(function()
        local startTime = tick()
        local index = 1

        while _replaying and index <= #_macroData do
            local currentElapsed = tick() - startTime
            local action = _macroData[index]

            if currentElapsed >= action.time then
                -- Replay action ke game server
                pcall(function()
                    if action.type == "RF" then
                        local rf = game:GetService("ReplicatedStorage"):FindFirstChild(action.remote)
                        if rf then rf:InvokeServer(unpack(action.args)) end
                    elseif action.type == "RE" then
                        local re = game:GetService("ReplicatedStorage"):FindFirstChild(action.remote)
                        if re then re:FireServer(unpack(action.args)) end
                    end
                end)
                index = index + 1
            end
            task.wait(0.01)
        end

        _replaying = false
        mPlayBtn.Text = "▶ Play"
        mPlayBtn.BackgroundColor3 = palette.green
        macroStatus.Text = "Status: Replay finished."
        macroStatus.TextColor3 = palette.textSub
    end)
end

local function stopPlayMacro()
    _replaying = false
    mPlayBtn.Text = "▶ Play"
    mPlayBtn.BackgroundColor3 = palette.green
    macroStatus.Text = "Status: Replay stopped."
    macroStatus.TextColor3 = palette.textSub
end

-- Macro button listeners
mRecBtn.MouseButton1Click:Connect(function()
    if _recording then stopMacroRecord() else startMacroRecord() end
end)

mPlayBtn.MouseButton1Click:Connect(function()
    if _replaying then stopPlayMacro() else playMacro() end
end)

mExportBtn.MouseButton1Click:Connect(function()
    if #_macroData == 0 then
        macroStatus.Text = "Status: No data to export!"
        macroStatus.TextColor3 = palette.red
        return
    end
    local ok2, encoded = pcall(function()
        local json = _http:JSONEncode(_macroData)
        local b64 = (syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.encode)
            or (crypt and crypt.base64 and crypt.base64encode)
            or nil
        return b64 and b64(json) or json
    end)
    if ok2 then
        ioBox.Text = encoded
        macroStatus.Text = "Status: Exported!"
        macroStatus.TextColor3 = palette.green
        if setclipboard then pcall(setclipboard, encoded) end
    end
end)

mImportBtn.MouseButton1Click:Connect(function()
    local text = ioBox.Text
    if text == "" then return end
    local ok2, decoded = pcall(function()
        local b64d = (syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode)
            or (crypt and crypt.base64 and crypt.base64decode)
            or nil
        local raw = b64d and b64d(text) or text
        return _http:JSONDecode(raw)
    end)
    if ok2 and type(decoded) == "table" then
        _macroData = decoded
        macroStatus.Text = "Status: Imported " .. #_macroData .. " actions!"
        macroStatus.TextColor3 = palette.green
    else
        macroStatus.Text = "Status: Import failed!"
        macroStatus.TextColor3 = palette.red
    end
end)

-- Execute click
executeBtn.MouseButton1Click:Connect(function()
    if not selectedFeature then
        notifyPopup("Select a script first!", palette.red)
        return
    end
    
    local feat = selectedFeature
    
    -- IF PLAYER IS FREE AND TRIES TO USE PREMIUM FEATURE
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
    
    if feat.running then
        notifyPopup("▶ " .. feat.name .. " activated", palette.execute)
    else
        notifyPopup("⏹ " .. feat.name .. " stopped", palette.close)
    end
end)

-- Hover effects
for _, btn in pairs({closeBtn, executeBtn, mRecBtn, mPlayBtn, mImportBtn, mExportBtn}) do
    btn.MouseEnter:Connect(function()
        local hoverCol = btn.BackgroundColor3:Lerp(Color3.fromRGB(0,0,0), 0.2)
        if btn == closeBtn then hoverCol = Color3.fromRGB(200, 40, 40) end
        _ts:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = hoverCol }):Play()
    end)
    btn.MouseLeave:Connect(function()
        local defaultCol = btn.BackgroundColor3
        if btn == closeBtn then defaultCol = Color3.fromRGB(255, 60, 60) end
        _ts:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = defaultCol }):Play()
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    _activeLoops = {}
    _ts:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.35, function() screenGui:Destroy() end)
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
