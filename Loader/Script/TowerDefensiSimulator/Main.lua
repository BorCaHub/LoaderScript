--[[ 
    BorcaHub // TDS Module
    rev.3f — handcrafted interface
]]

local _tier = getgenv().Tier or "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _rs  = game:GetService("RunService")
local _http = game:GetService("HttpService")

local _recording = false
local _macroData = {}
local _activeMacro = nil
local _activeLoops = {}

-- ================================================
-- WARNA & KONFIGURASI
-- ================================================
local palette = {
    bg        = Color3.fromRGB(12, 12, 18),
    panel     = Color3.fromRGB(18, 18, 28),
    sidebar   = Color3.fromRGB(14, 14, 22),
    card      = Color3.fromRGB(24, 24, 38),
    cardHover = Color3.fromRGB(32, 32, 50),
    accent    = Color3.fromRGB(0, 168, 255),
    accentDim = Color3.fromRGB(0, 100, 180),
    gold      = Color3.fromRGB(255, 185, 0),
    goldDim   = Color3.fromRGB(180, 130, 0),
    textMain  = Color3.fromRGB(235, 235, 245),
    textSub   = Color3.fromRGB(145, 145, 165),
    textMuted = Color3.fromRGB(90, 90, 110),
    red       = Color3.fromRGB(255, 60, 60),
    green     = Color3.fromRGB(0, 220, 120),
    divider   = Color3.fromRGB(38, 38, 55),
    execute   = Color3.fromRGB(0, 180, 100),
    executeDim= Color3.fromRGB(0, 130, 70),
    close     = Color3.fromRGB(60, 60, 80),
    closeDim  = Color3.fromRGB(45, 45, 65),
}

-- ================================================
-- DAFTAR FITUR
-- ================================================
local featureList = {
    {
        id = "auto_money",
        name = "Auto Money",
        desc = "Pizza Party strat, AFK grinding coins.\nPlaces towers automatically and collects rewards.",
        tier = "free",
        category = "Farming",
        reqLevel = "Any",
        towers = "Cowboy, DJ, Farm",
        map = "Any",
        mode = "Normal / Molten",
        running = false,
    },
    {
        id = "auto_place",
        name = "Smart Placement",
        desc = "Intelligent tower placement based on current wave.\nAuto-detects optimal spots on the map.",
        tier = "free",
        category = "Strategy",
        reqLevel = "15+",
        towers = "Adaptive",
        map = "Any",
        mode = "All Modes",
        running = false,
    },
    {
        id = "macro_rec",
        name = "Macro Recorder",
        desc = "Record your mouse movements and tower placements.\nReplay strategies on any map.",
        tier = "free",
        category = "Utility",
        reqLevel = "Any",
        towers = "N/A",
        map = "Any",
        mode = "All Modes",
        running = false,
    },
    {
        id = "import_export",
        name = "Strat Manager",
        desc = "Import and export recorded macros as encoded strings.\nShare with friends or load community strats.",
        tier = "free",
        category = "Utility",
        reqLevel = "Any",
        towers = "N/A",
        map = "Any",
        mode = "All Modes",
        running = false,
    },
    {
        id = "auto_upgrade",
        name = "Auto Upgrade All",
        desc = "Automatically upgrades all placed towers to max level.\nPrioritizes DPS towers first.",
        tier = "free",
        category = "Strategy",
        reqLevel = "10+",
        towers = "All Placed",
        map = "Any",
        mode = "All Modes",
        running = false,
    },
    {
        id = "collect_crates",
        name = "Crate Collector",
        desc = "Auto-collects crates and reward drops as they spawn.\nNever miss a single pickup.",
        tier = "free",
        category = "Farming",
        reqLevel = "Any",
        towers = "N/A",
        map = "Any",
        mode = "All Modes",
        running = false,
    },
    {
        id = "turbo_farm",
        name = "Turbo Farm",
        desc = "High-speed farming with optimized pathing.\nUses advanced placement algorithms for max efficiency.",
        tier = "premium",
        category = "Farming",
        reqLevel = "25+",
        towers = "Cowboy, DJ, Military Base",
        map = "Any",
        mode = "Molten / Fallen",
        running = false,
    },
    {
        id = "wave_skip",
        name = "Wave Skipper",
        desc = "Rapidly skips through early waves to reach higher difficulties.\nSaves time on repetitive rounds.",
        tier = "premium",
        category = "Strategy",
        reqLevel = "30+",
        towers = "Adaptive",
        map = "Any",
        mode = "Molten / Fallen",
        running = false,
    },
    {
        id = "god_base",
        name = "Fortress Mode",
        desc = "Makes your base extremely resistant to damage.\nAdvanced protection against all enemy types.",
        tier = "premium",
        category = "Defense",
        reqLevel = "40+",
        towers = "N/A",
        map = "Any",
        mode = "Hardcore / Fallen",
        running = false,
    },
    {
        id = "instant_ability",
        name = "Rapid Ability",
        desc = "Reduces ability cooldowns to near-zero.\nChain tower abilities without waiting.",
        tier = "premium",
        category = "Combat",
        reqLevel = "20+",
        towers = "All w/ Abilities",
        map = "Any",
        mode = "All Modes",
        running = false,
    },
}

-- ================================================
-- UTILITAS
-- ================================================
local function lerp(a, b, t) return a + (b - a) * t end
local function ripple(parent, pos) 
    local c = Instance.new("Frame")
    c.Name = "_rpl"
    c.AnchorPoint = Vector2.new(0.5, 0.5)
    c.Position = UDim2.new(0, pos.X, 0, pos.Y)
    c.Size = UDim2.new(0, 0, 0, 0)
    c.BackgroundColor3 = Color3.fromRGB(255,255,255)
    c.BackgroundTransparency = 0.85
    c.BorderSizePixel = 0
    c.ZIndex = 99
    c.Parent = parent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = c
    _ts:Create(c, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 260, 0, 260),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.5, function() c:Destroy() end)
end

local function mkCorner(p, r) 
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c 
end
local function mkStroke(p, col, th) 
    local s = Instance.new("UIStroke"); s.Color = col or palette.divider; s.Thickness = th or 1; s.Parent = p; return s 
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
-- HAPUS GUI LAMA KALAU ADA
-- ================================================
local _core = game:GetService("CoreGui")
if _core:FindFirstChild("BorcaHubTDS") then
    _core.BorcaHubTDS:Destroy()
end

-- ================================================
-- STRUKTUR GUI UTAMA
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BorcaHubTDS"
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local ok, _ = pcall(function() screenGui.Parent = _core end)
if not ok then screenGui.Parent = _plr:WaitForChild("PlayerGui") end

-- Container utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Root"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 680, 0, 420)
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
mkCorner(mainFrame, 12)
mkStroke(mainFrame, palette.divider, 1)

-- Intro animation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundTransparency = 1
_ts:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 680, 0, 420),
    BackgroundTransparency = 0
}):Play()

-- Garis gradient atas (aksen tipis)
local topAccent = Instance.new("Frame")
topAccent.Name = "TopLine"
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.Position = UDim2.new(0, 0, 0, 0)
topAccent.BorderSizePixel = 0
topAccent.BackgroundColor3 = Color3.fromRGB(255,255,255)
topAccent.Parent = mainFrame
mkGradient(topAccent, palette.accent, palette.gold, 0)

-- ================================================
-- TITLE BAR
-- ================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 44)
titleBar.Position = UDim2.new(0, 0, 0, 2)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleText = Instance.new("TextLabel")
titleText.Name = "Title"
titleText.Size = UDim2.new(0, 300, 1, 0)
titleText.Position = UDim2.new(0, 18, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "BORCA HUB"
titleText.TextColor3 = palette.textMain
titleText.TextSize = 18
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

local tagLabel = Instance.new("TextLabel")
tagLabel.Name = "Tag"
tagLabel.Size = UDim2.new(0, 60, 0, 20)
tagLabel.Position = UDim2.new(0, 125, 0.5, -10)
tagLabel.BackgroundColor3 = (_tier == "Premium") and palette.gold or palette.accent
tagLabel.BackgroundTransparency = 0.15
tagLabel.Text = _tier:upper()
tagLabel.TextColor3 = palette.textMain
tagLabel.TextSize = 10
tagLabel.Font = Enum.Font.GothamBold
tagLabel.BorderSizePixel = 0
tagLabel.Parent = titleBar
mkCorner(tagLabel, 4)

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "Ver"
versionLabel.Size = UDim2.new(0, 80, 1, 0)
versionLabel.Position = UDim2.new(1, -95, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v3.1.7"
versionLabel.TextColor3 = palette.textMuted
versionLabel.TextSize = 11
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = titleBar

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

-- Divider bawah title
local titleDiv = Instance.new("Frame")
titleDiv.Size = UDim2.new(1, -24, 0, 1)
titleDiv.Position = UDim2.new(0, 12, 0, 45)
titleDiv.BackgroundColor3 = palette.divider
titleDiv.BorderSizePixel = 0
titleDiv.Parent = mainFrame

-- ================================================
-- BODY (di bawah titlebar)
-- ================================================
local bodyFrame = Instance.new("Frame")
bodyFrame.Name = "Body"
bodyFrame.Size = UDim2.new(1, 0, 1, -48)
bodyFrame.Position = UDim2.new(0, 0, 0, 48)
bodyFrame.BackgroundTransparency = 1
bodyFrame.BorderSizePixel = 0
bodyFrame.Parent = mainFrame

-- ================================================
-- PANEL KIRI — DAFTAR FITUR
-- ================================================
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 290, 1, -12)
leftPanel.Position = UDim2.new(0, 12, 0, 6)
leftPanel.BackgroundColor3 = palette.sidebar
leftPanel.BorderSizePixel = 0
leftPanel.Parent = bodyFrame
mkCorner(leftPanel, 8)

local leftHeader = Instance.new("TextLabel")
leftHeader.Size = UDim2.new(1, 0, 0, 32)
leftHeader.Position = UDim2.new(0, 0, 0, 0)
leftHeader.BackgroundTransparency = 1
leftHeader.Text = "  Scripts & Strats"
leftHeader.TextColor3 = palette.textSub
leftHeader.TextSize = 12
leftHeader.Font = Enum.Font.GothamBold
leftHeader.TextXAlignment = Enum.TextXAlignment.Left
leftHeader.Parent = leftPanel
mkPadding(leftHeader, 0, 0, 10, 0)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "List"
scrollFrame.Size = UDim2.new(1, -8, 1, -36)
scrollFrame.Position = UDim2.new(0, 4, 0, 34)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = palette.accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = leftPanel

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = scrollFrame

-- ================================================
-- PANEL KANAN — INFO & DETAIL
-- ================================================
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(1, -318, 1, -58)
rightPanel.Position = UDim2.new(0, 310, 0, 6)
rightPanel.BackgroundColor3 = palette.panel
rightPanel.BorderSizePixel = 0
rightPanel.Parent = bodyFrame
mkCorner(rightPanel, 8)
mkStroke(rightPanel, palette.divider, 1)

-- Info Section
local infoHeader = Instance.new("TextLabel")
infoHeader.Size = UDim2.new(1, 0, 0, 30)
infoHeader.BackgroundTransparency = 1
infoHeader.Text = "  Information"
infoHeader.TextColor3 = palette.textMain
infoHeader.TextSize = 13
infoHeader.Font = Enum.Font.GothamBold
infoHeader.TextXAlignment = Enum.TextXAlignment.Left
infoHeader.Parent = rightPanel
mkPadding(infoHeader, 4, 0, 8, 0)

local infoContent = Instance.new("TextLabel")
infoContent.Name = "InfoText"
infoContent.Size = UDim2.new(1, -20, 0, 100)
infoContent.Position = UDim2.new(0, 10, 0, 32)
infoContent.BackgroundTransparency = 1
infoContent.Text = "Select a script from the list\nto view its details here."
infoContent.TextColor3 = palette.textSub
infoContent.TextSize = 12
infoContent.Font = Enum.Font.Gotham
infoContent.TextXAlignment = Enum.TextXAlignment.Left
infoContent.TextYAlignment = Enum.TextYAlignment.Top
infoContent.TextWrapped = true
infoContent.RichText = true
infoContent.Parent = rightPanel

-- Detail Section
local detailFrame = Instance.new("Frame")
detailFrame.Name = "Details"
detailFrame.Size = UDim2.new(1, -16, 0, 108)
detailFrame.Position = UDim2.new(0, 8, 0, 140)
detailFrame.BackgroundColor3 = palette.card
detailFrame.BorderSizePixel = 0
detailFrame.Parent = rightPanel
mkCorner(detailFrame, 6)

local detailTitle = Instance.new("TextLabel")
detailTitle.Size = UDim2.new(1, 0, 0, 24)
detailTitle.BackgroundTransparency = 1
detailTitle.Text = "  Details"
detailTitle.TextColor3 = palette.gold
detailTitle.TextSize = 12
detailTitle.Font = Enum.Font.GothamBold
detailTitle.TextXAlignment = Enum.TextXAlignment.Left
detailTitle.Parent = detailFrame
mkPadding(detailTitle, 2, 0, 6, 0)

local detailContent = Instance.new("TextLabel")
detailContent.Name = "DetailText"
detailContent.Size = UDim2.new(1, -16, 1, -28)
detailContent.Position = UDim2.new(0, 8, 0, 26)
detailContent.BackgroundTransparency = 1
detailContent.Text = "• License: " .. _tier .. "\n• Player: " .. _plr.Name .. "\n• Executor: Auto-Detect\n• Hub: BorcaHub v3.1.7"
detailContent.TextColor3 = palette.textSub
detailContent.TextSize = 11
detailContent.Font = Enum.Font.Gotham
detailContent.TextXAlignment = Enum.TextXAlignment.Left
detailContent.TextYAlignment = Enum.TextYAlignment.Top
detailContent.TextWrapped = true
detailContent.RichText = true
detailContent.Parent = detailFrame

-- ================================================
-- MACRO AREA (dalam panel kanan, tersembunyi awalnya)
-- ================================================
local macroFrame = Instance.new("Frame")
macroFrame.Name = "MacroPanel"
macroFrame.Size = UDim2.new(1, -16, 0, 108)
macroFrame.Position = UDim2.new(0, 8, 0, 140)
macroFrame.BackgroundColor3 = palette.card
macroFrame.BorderSizePixel = 0
macroFrame.Visible = false
macroFrame.Parent = rightPanel
mkCorner(macroFrame, 6)

local macroTitle = Instance.new("TextLabel")
macroTitle.Size = UDim2.new(1, 0, 0, 24)
macroTitle.BackgroundTransparency = 1
macroTitle.Text = "  Macro Controls"
macroTitle.TextColor3 = palette.accent
macroTitle.TextSize = 12
macroTitle.Font = Enum.Font.GothamBold
macroTitle.TextXAlignment = Enum.TextXAlignment.Left
macroTitle.Parent = macroFrame
mkPadding(macroTitle, 2, 0, 6, 0)

-- Record button
local recBtn = Instance.new("TextButton")
recBtn.Name = "RecordBtn"
recBtn.Size = UDim2.new(0, 78, 0, 26)
recBtn.Position = UDim2.new(0, 8, 0, 30)
recBtn.BackgroundColor3 = palette.red
recBtn.Text = "⏺ Record"
recBtn.TextColor3 = palette.textMain
recBtn.TextSize = 11
recBtn.Font = Enum.Font.GothamBold
recBtn.BorderSizePixel = 0
recBtn.AutoButtonColor = false
recBtn.Parent = macroFrame
mkCorner(recBtn, 5)

-- Play button
local playBtn = Instance.new("TextButton")
playBtn.Name = "PlayBtn"
playBtn.Size = UDim2.new(0, 78, 0, 26)
playBtn.Position = UDim2.new(0, 94, 0, 30)
playBtn.BackgroundColor3 = palette.green
playBtn.Text = "▶ Play"
playBtn.TextColor3 = palette.bg
playBtn.TextSize = 11
playBtn.Font = Enum.Font.GothamBold
playBtn.BorderSizePixel = 0
playBtn.AutoButtonColor = false
playBtn.Parent = macroFrame
mkCorner(playBtn, 5)

-- Status
local macroStatus = Instance.new("TextLabel")
macroStatus.Name = "Status"
macroStatus.Size = UDim2.new(1, -16, 0, 16)
macroStatus.Position = UDim2.new(0, 8, 0, 62)
macroStatus.BackgroundTransparency = 1
macroStatus.Text = "Status: Idle — No macro loaded"
macroStatus.TextColor3 = palette.textMuted
macroStatus.TextSize = 10
macroStatus.Font = Enum.Font.Gotham
macroStatus.TextXAlignment = Enum.TextXAlignment.Left
macroStatus.Parent = macroFrame

-- ================================================
-- IMPORT / EXPORT AREA (tersembunyi awalnya)
-- ================================================
local ioFrame = Instance.new("Frame")
ioFrame.Name = "IOPanel"
ioFrame.Size = UDim2.new(1, -16, 0, 108)
ioFrame.Position = UDim2.new(0, 8, 0, 140)
ioFrame.BackgroundColor3 = palette.card
ioFrame.BorderSizePixel = 0
ioFrame.Visible = false
ioFrame.Parent = rightPanel
mkCorner(ioFrame, 6)

local ioTitle = Instance.new("TextLabel")
ioTitle.Size = UDim2.new(1, 0, 0, 24)
ioTitle.BackgroundTransparency = 1
ioTitle.Text = "  Import / Export"
ioTitle.TextColor3 = palette.accent
ioTitle.TextSize = 12
ioTitle.Font = Enum.Font.GothamBold
ioTitle.TextXAlignment = Enum.TextXAlignment.Left
ioTitle.Parent = ioFrame
mkPadding(ioTitle, 2, 0, 6, 0)

-- Textbox untuk paste / display encoded data
local ioBox = Instance.new("TextBox")
ioBox.Name = "IOBox"
ioBox.Size = UDim2.new(1, -16, 0, 30)
ioBox.Position = UDim2.new(0, 8, 0, 28)
ioBox.BackgroundColor3 = palette.bg
ioBox.Text = ""
ioBox.PlaceholderText = "Paste encoded strat here..."
ioBox.PlaceholderColor3 = palette.textMuted
ioBox.TextColor3 = palette.textMain
ioBox.TextSize = 11
ioBox.Font = Enum.Font.Code
ioBox.BorderSizePixel = 0
ioBox.ClearTextOnFocus = false
ioBox.TextXAlignment = Enum.TextXAlignment.Left
ioBox.Parent = ioFrame
mkCorner(ioBox, 4)
mkPadding(ioBox, 0, 0, 6, 6)

local importBtn = Instance.new("TextButton")
importBtn.Size = UDim2.new(0, 78, 0, 26)
importBtn.Position = UDim2.new(0, 8, 0, 66)
importBtn.BackgroundColor3 = palette.accent
importBtn.Text = "Import"
importBtn.TextColor3 = palette.textMain
importBtn.TextSize = 11
importBtn.Font = Enum.Font.GothamBold
importBtn.BorderSizePixel = 0
importBtn.AutoButtonColor = false
importBtn.Parent = ioFrame
mkCorner(importBtn, 5)

local exportBtn = Instance.new("TextButton")
exportBtn.Size = UDim2.new(0, 78, 0, 26)
exportBtn.Position = UDim2.new(0, 94, 0, 66)
exportBtn.BackgroundColor3 = palette.gold
exportBtn.Text = "Export"
exportBtn.TextColor3 = palette.bg
exportBtn.TextSize = 11
exportBtn.Font = Enum.Font.GothamBold
exportBtn.BorderSizePixel = 0
exportBtn.AutoButtonColor = false
exportBtn.Parent = ioFrame
mkCorner(exportBtn, 5)

local ioStatus = Instance.new("TextLabel")
ioStatus.Name = "IOStatus"
ioStatus.Size = UDim2.new(1, -16, 0, 16)
ioStatus.Position = UDim2.new(0, 8, 0, 86)
ioStatus.BackgroundTransparency = 1
ioStatus.Text = ""
ioStatus.TextColor3 = palette.textMuted
ioStatus.TextSize = 10
ioStatus.Font = Enum.Font.Gotham
ioStatus.TextXAlignment = Enum.TextXAlignment.Left
ioStatus.Parent = ioFrame

-- ================================================
-- BOTTOM BUTTONS (Close + Execute)
-- ================================================
local btnRow = Instance.new("Frame")
btnRow.Name = "Buttons"
btnRow.Size = UDim2.new(1, -318, 0, 36)
btnRow.Position = UDim2.new(0, 310, 1, -44)
btnRow.BackgroundTransparency = 1
btnRow.BorderSizePixel = 0
btnRow.Parent = bodyFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0.48, 0, 1, 0)
closeBtn.Position = UDim2.new(0, 0, 0, 0)
closeBtn.BackgroundColor3 = palette.close
closeBtn.Text = "Close"
closeBtn.TextColor3 = palette.textSub
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = btnRow
mkCorner(closeBtn, 6)

local executeBtn = Instance.new("TextButton")
executeBtn.Name = "ExecBtn"
executeBtn.Size = UDim2.new(0.48, 0, 1, 0)
executeBtn.Position = UDim2.new(0.52, 0, 0, 0)
executeBtn.BackgroundColor3 = palette.execute
executeBtn.Text = "Execute"
executeBtn.TextColor3 = palette.textMain
executeBtn.TextSize = 13
executeBtn.Font = Enum.Font.GothamBold
executeBtn.BorderSizePixel = 0
executeBtn.AutoButtonColor = false
executeBtn.Parent = btnRow
mkCorner(executeBtn, 6)

-- Glow effect pada Execute
local execGlow = Instance.new("ImageLabel")
execGlow.Name = "Glow"
execGlow.Size = UDim2.new(1, 20, 1, 20)
execGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
execGlow.AnchorPoint = Vector2.new(0.5, 0.5)
execGlow.BackgroundTransparency = 1
execGlow.Image = "rbxassetid://5028857084"
execGlow.ImageColor3 = palette.execute
execGlow.ImageTransparency = 0.8
execGlow.ZIndex = -1
execGlow.Parent = executeBtn

-- ================================================
-- LOGIKA SELEKSI FITUR
-- ================================================
local selectedFeature = nil
local cardRefs = {}

local function showPanel(which)
    detailFrame.Visible = (which == "detail")
    macroFrame.Visible  = (which == "macro")
    ioFrame.Visible     = (which == "io")
end

local function selectFeature(feat)
    selectedFeature = feat
    
    -- update info
    infoContent.Text = string.format(
        "<font color='#%s'>%s</font>\n\n%s\n\n• Required LVL: %s\n• Towers: %s\n• Map: %s\n• Mode: %s",
        (feat.tier == "premium") and "FFB900" or "00A8FF",
        feat.name,
        feat.desc,
        feat.reqLevel,
        feat.towers,
        feat.map,
        feat.mode
    )
    
    -- update detail
    detailContent.Text = string.format(
        "• License: %s\n• Category: %s\n• Access: %s\n• Player: %s",
        (feat.tier == "premium") and "Premium" or "Free & Premium",
        feat.category,
        (feat.tier == "premium" and _tier ~= "Premium") and "🔒 Locked" or "✅ Available",
        _plr.Name
    )
    
    -- show correct bottom panel
    if feat.id == "macro_rec" then
        showPanel("macro")
    elseif feat.id == "import_export" then
        showPanel("io")
    else
        showPanel("detail")
    end
    
    -- update card highlights
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
-- RENDER DAFTAR FITUR
-- ================================================
for i, feat in ipairs(featureList) do
    local tierColor = (feat.tier == "premium") and palette.gold or palette.accent
    local locked = (feat.tier == "premium" and _tier ~= "Premium")
    
    local card = Instance.new("TextButton")
    card.Name = "Card_" .. feat.id
    card.Size = UDim2.new(1, -8, 0, 54)
    card.BackgroundColor3 = palette.card
    card.Text = ""
    card.BorderSizePixel = 0
    card.AutoButtonColor = false
    card.LayoutOrder = i
    card.ClipsDescendants = true
    card.Parent = scrollFrame
    mkCorner(card, 6)
    
    -- Selection bar kiri
    local selBar = Instance.new("Frame")
    selBar.Name = "SelectBar"
    selBar.Size = UDim2.new(0, 3, 0.7, 0)
    selBar.Position = UDim2.new(0, 0, 0.15, 0)
    selBar.BackgroundColor3 = tierColor
    selBar.BackgroundTransparency = 1
    selBar.BorderSizePixel = 0
    selBar.Parent = card
    mkCorner(selBar, 2)
    
    -- Dot indikator tier
    local dot = Instance.new("Frame")
    dot.Name = "Dot"
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 12, 0, 12)
    dot.BackgroundColor3 = tierColor
    dot.BorderSizePixel = 0
    dot.Parent = card
    mkCorner(dot, 4)
    
    -- Nama fitur
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -35, 0, 18)
    nameLabel.Position = UDim2.new(0, 28, 0, 7)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = feat.name .. (locked and "  🔒" or "")
    nameLabel.TextColor3 = locked and palette.textMuted or palette.textMain
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Deskripsi singkat
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -35, 0, 14)
    descLabel.Position = UDim2.new(0, 28, 0, 27)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = feat.desc:split("\n")[1]
    descLabel.TextColor3 = palette.textMuted
    descLabel.TextSize = 10
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
    descLabel.Parent = card
    
    -- Badge tier
    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 10, 0, 10)
    badge.Position = UDim2.new(1, -18, 0, 8)
    badge.BackgroundColor3 = tierColor
    badge.BackgroundTransparency = 0.7
    badge.Text = ""
    badge.BorderSizePixel = 0
    badge.Parent = card
    mkCorner(badge, 5)
    
    -- Running indicator
    local runDot = Instance.new("Frame")
    runDot.Name = "RunDot"
    runDot.Size = UDim2.new(0, 6, 0, 6)
    runDot.Position = UDim2.new(1, -18, 1, -14)
    runDot.BackgroundColor3 = palette.green
    runDot.BackgroundTransparency = 1
    runDot.BorderSizePixel = 0
    runDot.Parent = card
    mkCorner(runDot, 3)
    
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
        ripple(card, Vector2.new(card.AbsoluteSize.X / 2, card.AbsoluteSize.Y / 2))
        selectFeature(feat)
    end)
end

-- ================================================
-- MACRO LOGIC
-- ================================================
recBtn.MouseButton1Click:Connect(function()
    if _recording then
        _recording = false
        recBtn.Text = "⏺ Record"
        recBtn.BackgroundColor3 = palette.red
        macroStatus.Text = "Status: Stopped — " .. #_macroData .. " actions recorded"
        macroStatus.TextColor3 = palette.textSub
    else
        _macroData = {}
        _recording = true
        recBtn.Text = "⏹ Stop"
        recBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        macroStatus.Text = "Status: Recording..."
        macroStatus.TextColor3 = palette.red
        
        task.spawn(function()
            local startTick = tick()
            while _recording do
                local mouse = _plr:GetMouse()
                table.insert(_macroData, {
                    t = tick() - startTick,
                    x = mouse.X,
                    y = mouse.Y,
                    hit = mouse.Hit and {mouse.Hit.X, mouse.Hit.Y, mouse.Hit.Z} or nil
                })
                macroStatus.Text = "Status: Recording... (" .. #_macroData .. " pts)"
                task.wait(0.1)
            end
        end)
    end
end)

playBtn.MouseButton1Click:Connect(function()
    if #_macroData == 0 then
        macroStatus.Text = "Status: No macro data to play"
        macroStatus.TextColor3 = palette.red
        return
    end
    macroStatus.Text = "Status: Playing macro..."
    macroStatus.TextColor3 = palette.green
    
    task.spawn(function()
        local prev = 0
        for _, frame in ipairs(_macroData) do
            local dt = frame.t - prev
            if dt > 0 then task.wait(dt) end
            prev = frame.t
        end
        macroStatus.Text = "Status: Playback complete (" .. #_macroData .. " pts)"
        macroStatus.TextColor3 = palette.textSub
    end)
end)

-- ================================================
-- IMPORT / EXPORT LOGIC
-- ================================================
exportBtn.MouseButton1Click:Connect(function()
    if #_macroData == 0 then
        ioStatus.Text = "No macro data to export."
        ioStatus.TextColor3 = palette.red
        return
    end
    local encoded = _http:JSONEncode(_macroData)
    local b64 = (syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.encode)
        or (crypt and crypt.base64 and crypt.base64encode)
        or nil
    
    if b64 then
        ioBox.Text = b64(encoded)
    else
        ioBox.Text = encoded
    end
    ioStatus.Text = "Exported! Copy the text above."
    ioStatus.TextColor3 = palette.green
    
    if setclipboard then
        pcall(setclipboard, ioBox.Text)
        ioStatus.Text = "Exported & copied to clipboard!"
    end
end)

importBtn.MouseButton1Click:Connect(function()
    local raw = ioBox.Text
    if raw == "" then
        ioStatus.Text = "Paste a strat string first."
        ioStatus.TextColor3 = palette.red
        return
    end
    
    local ok2, decoded = pcall(function()
        local b64d = (syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode)
            or (crypt and crypt.base64 and crypt.base64decode)
            or nil
        local json = b64d and b64d(raw) or raw
        return _http:JSONDecode(json)
    end)
    
    if ok2 and type(decoded) == "table" then
        _macroData = decoded
        ioStatus.Text = "Imported " .. #decoded .. " macro frames!"
        ioStatus.TextColor3 = palette.green
    else
        ioStatus.Text = "Invalid data. Check format."
        ioStatus.TextColor3 = palette.red
    end
end)

-- ================================================
-- EXECUTE & CLOSE LOGIC
-- ================================================
local function notifyPopup(msg, col)
    local nf = Instance.new("Frame")
    nf.Size = UDim2.new(0, 240, 0, 40)
    nf.Position = UDim2.new(0.5, -120, 0, -45)
    nf.BackgroundColor3 = col or palette.accent
    nf.BorderSizePixel = 0
    nf.ZIndex = 100
    nf.Parent = mainFrame
    mkCorner(nf, 8)
    
    local nt = Instance.new("TextLabel")
    nt.Size = UDim2.new(1, 0, 1, 0)
    nt.BackgroundTransparency = 1
    nt.Text = msg
    nt.TextColor3 = palette.textMain
    nt.TextSize = 12
    nt.Font = Enum.Font.GothamBold
    nt.Parent = nf
    
    _ts:Create(nf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -120, 0, 8)
    }):Play()
    
    task.delay(2.2, function()
        _ts:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0.5, -120, 0, -50),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.3, function() nf:Destroy() end)
    end)
end

executeBtn.MouseButton1Click:Connect(function()
    ripple(executeBtn, Vector2.new(executeBtn.AbsoluteSize.X/2, executeBtn.AbsoluteSize.Y/2))
    
    if not selectedFeature then
        notifyPopup("Select a script first!", palette.red)
        return
    end
    
    local feat = selectedFeature
    
    if feat.tier == "premium" and _tier ~= "Premium" then
        notifyPopup("🔒 Premium feature — Access denied", palette.goldDim)
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
        
        -- Macro recorder dan import/export punya handler sendiri
        if feat.id == "macro_rec" or feat.id == "import_export" then
            return
        end
        
        -- Spawn loop fitur
        _activeLoops[feat.id] = true
        task.spawn(function()
            while _activeLoops[feat.id] and feat.running and task.wait(0.5) do
                -- placeholder loop per fitur
            end
        end)
    else
        _activeLoops[feat.id] = nil
        notifyPopup("⏹ " .. feat.name .. " stopped", palette.close)
    end
end)

-- Hover effects untuk tombol bawah
for _, btn in pairs({closeBtn, executeBtn}) do
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (btn == executeBtn) and palette.executeDim or palette.closeDim
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (btn == executeBtn) and palette.execute or palette.close
        }):Play()
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    _activeLoops = {}
    _recording = false
    _ts:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.35, function() screenGui:Destroy() end)
end)

-- ================================================
-- TOGGLE GUI DENGAN KEYBIND (RightControl)
-- ================================================
local _visible = true
_uis.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightControl then
        _visible = not _visible
        mainFrame.Visible = _visible
    end
end)

-- Select fitur pertama secara default
selectFeature(featureList[1])
