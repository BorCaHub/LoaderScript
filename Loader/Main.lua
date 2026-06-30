--[[
    BorcaHub // Loader Module
    Custom UI Loader dengan Dark Cyber Handcrafted UI
]]

local _tier = "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _http = game:GetService("HttpService")

-- Konfigurasi Supabase
local SUPABASE_URL = "https://lvydbmdraqhyinbnwmuu.supabase.co/rest/v1/keys"
local SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2eWRibWRyYXFoeWluYm53bXV1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI3MTAyNzUsImV4cCI6MjA5ODI4NjI3NX0.B0Vh6wJ3_a3WgqQ006_hpZOKPHwuQzzUieDRtaewTLk"

-- ================================================
-- WARNA & KONFIGURASI
-- ================================================
local palette = {
    bg        = Color3.fromRGB(12, 12, 18),
    panel     = Color3.fromRGB(18, 18, 28),
    card      = Color3.fromRGB(24, 24, 38),
    cardHover = Color3.fromRGB(32, 32, 50),
    accent    = Color3.fromRGB(0, 168, 255),
    gold      = Color3.fromRGB(255, 185, 0),
    textMain  = Color3.fromRGB(235, 235, 245),
    textSub   = Color3.fromRGB(145, 145, 165),
    textMuted = Color3.fromRGB(90, 90, 110),
    red       = Color3.fromRGB(255, 60, 60),
    green     = Color3.fromRGB(0, 220, 120),
    divider   = Color3.fromRGB(38, 38, 55),
}

local function mkCorner(p, r) 
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c 
end
local function mkStroke(p, col, th) 
    local s = Instance.new("UIStroke"); s.Color = col or palette.divider; s.Thickness = th or 1; s.Parent = p; return s 
end
local function mkGradient(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = p
    return g
end

-- Hapus loader lama
local _core = game:GetService("CoreGui")
if _core:FindFirstChild("BorcaHubLoader") then
    _core.BorcaHubLoader:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BorcaHubLoader"
screenGui.ResetOnSpawn = false
local ok, _ = pcall(function() screenGui.Parent = _core end)
if not ok then screenGui.Parent = _plr:WaitForChild("PlayerGui") end

-- Frame Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Root"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.new(0, 460, 0, 340)
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
mainFrame.Parent = screenGui
mkCorner(mainFrame, 12)
mkStroke(mainFrame, palette.divider, 1)

-- ================================================
-- CORNER LIGHTS SEMUA 4 SUDUT (masing-masing 2 layer: Biru + Kuning)
-- ================================================
local function createCornerLight(name, xScale, xOff, yScale, yOff, color1, color2)
    -- Layer 1: utama (besar, rotate 360)
    local light1 = Instance.new("ImageLabel")
    light1.Name = name .. "_1"
    light1.Size = UDim2.new(0, 150, 0, 150)
    light1.Position = UDim2.new(xScale, xOff, yScale, yOff)
    light1.AnchorPoint = Vector2.new(0.5, 0.5)
    light1.BackgroundTransparency = 1
    light1.Image = "rbxassetid://5028857084"
    light1.ImageColor3 = color1
    light1.ImageTransparency = 0.05
    light1.ZIndex = 20
    light1.Parent = mainFrame
    _ts:Create(light1, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    _ts:Create(light1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.4}):Play()
    
    -- Layer 2: lebih kecil (rotasi berlawanan)
    local light2 = Instance.new("ImageLabel")
    light2.Name = name .. "_2"
    light2.Size = UDim2.new(0, 85, 0, 85)
    light2.Position = UDim2.new(xScale, xOff, yScale, yOff)
    light2.AnchorPoint = Vector2.new(0.5, 0.5)
    light2.BackgroundTransparency = 1
    light2.Image = "rbxassetid://5028857084"
    light2.ImageColor3 = color2
    light2.ImageTransparency = 0.15
    light2.ZIndex = 20
    light2.Parent = mainFrame
    _ts:Create(light2, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = -360}):Play()
    _ts:Create(light2, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.5}):Play()
end

-- 4 sudut dengan light keluar frame
createCornerLight("TL", 0, -35, 0, -35, palette.accent, palette.gold)
createCornerLight("TR", 1, 35, 0, -35, palette.gold, palette.accent)
createCornerLight("BL", 0, -35, 1, 35, palette.gold, palette.accent)
createCornerLight("BR", 1, 35, 1, 35, palette.accent, palette.gold)

-- ================================================
-- TOMBOL CLOSE (X) DI KANAN ATAS
-- ================================================
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 6)
closeBtn.BackgroundColor3 = palette.card
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 16
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
    task.delay(0.35, function() screenGui:Destroy() end)
end)

-- Hover close button
local function bindHover(btn, hoverColor, defaultColor)
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = defaultColor}):Play()
    end)
end
bindHover(closeBtn, Color3.fromRGB(180, 30, 30), palette.card)

-- ================================================
-- TITLE CENTER + SUBTITLE
-- ================================================
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -80, 0, 45)
titleText.Position = UDim2.new(0, 20, 0, 2)
titleText.BackgroundTransparency = 1
titleText.Text = "BORCA HUB"
titleText.TextColor3 = palette.textMain
titleText.TextSize = 28
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Center
titleText.Parent = mainFrame

local subTitleText = Instance.new("TextLabel")
subTitleText.Size = UDim2.new(1, -80, 0, 20)
subTitleText.Position = UDim2.new(0, 20, 0, 48)
subTitleText.BackgroundTransparency = 1
subTitleText.Text = "Choose Tier to Proceed"
subTitleText.TextColor3 = palette.textSub
subTitleText.TextSize = 14
subTitleText.Font = Enum.Font.GothamMedium
subTitleText.TextXAlignment = Enum.TextXAlignment.Center
subTitleText.Parent = mainFrame

-- Version label
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 0, 20)
versionLabel.Position = UDim2.new(1, -70, 0, 10)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0"
versionLabel.TextColor3 = palette.textMuted
versionLabel.TextSize = 12
versionLabel.Font = Enum.Font.Gotham
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = mainFrame

-- ================================================
-- TOMBOL MINIMIZE (DI BAWAH CLOSE X)
-- ================================================
local minBtn = Instance.new("TextButton")
minBtn.Name = "MinBtn"
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -38, 0, 38)
minBtn.BackgroundColor3 = palette.card
minBtn.Text = "−"
minBtn.TextColor3 = palette.textSub
minBtn.TextSize = 20
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = mainFrame
mkCorner(minBtn, 6)
mkStroke(minBtn, palette.divider, 1)

local isMinimized = false
local originalSize = mainFrame.Size
local originalPos = mainFrame.Position
local minimizedSize = UDim2.new(0, 460, 0, 60)

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
bindHover(minBtn, palette.cardHover, palette.card)

-- ================================================
-- CONTAINER PAGES
-- ================================================
local pages = Instance.new("Frame")
pages.Size = UDim2.new(1, -40, 1, -70)
pages.Position = UDim2.new(0, 20, 0, 62)
pages.BackgroundTransparency = 1
pages.ClipsDescendants = true
pages.Parent = mainFrame

-- ================================================
-- POPUP NOTIFIKASI
-- ================================================
local function notify(msg, col)
    local nf = Instance.new("Frame")
    nf.Size = UDim2.new(0, 260, 0, 40)
    nf.Position = UDim2.new(0.5, -130, 0, -45)
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
    nt.TextSize = 14
    nt.Font = Enum.Font.GothamBold
    nt.Parent = nf
    
    _ts:Create(nf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -130, 0, 8)
    }):Play()
    
    task.delay(2.2, function()
        _ts:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
            Position = UDim2.new(0.5, -130, 0, -50),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.3, function() nf:Destroy() end)
    end)
end

-- ================================================
-- HALAMAN 1: PILIH TIER (FREE / PREMIUM)
-- ================================================
local choosePage = Instance.new("Frame")
choosePage.Size = UDim2.new(1, 0, 1, 0)
choosePage.BackgroundTransparency = 1
choosePage.Parent = pages

-- Helper function untuk button tier dengan glow
local function createTierBtn(pos, title, desc, color, glowCol)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.46, 0, 0.65, 0)
    btn.Position = pos
    btn.BackgroundColor3 = palette.card
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = choosePage
    mkCorner(btn, 10)
    mkStroke(btn, palette.divider, 1)
    
    -- Glow di 2 sudut
    local g1 = Instance.new("ImageLabel")
    g1.Size = UDim2.new(0, 70, 0, 70)
    g1.Position = UDim2.new(0, -18, 0, -18)
    g1.AnchorPoint = Vector2.new(0.5, 0.5)
    g1.BackgroundTransparency = 1
    g1.Image = "rbxassetid://5028857084"
    g1.ImageColor3 = glowCol
    g1.ImageTransparency = 0.2
    g1.ZIndex = -1
    g1.Parent = btn
    _ts:Create(g1, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
    _ts:Create(g1, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.5}):Play()
    
    local g2 = Instance.new("ImageLabel")
    g2.Size = UDim2.new(0, 45, 0, 45)
    g2.Position = UDim2.new(1, 15, 1, 15)
    g2.AnchorPoint = Vector2.new(0.5, 0.5)
    g2.BackgroundTransparency = 1
    g2.Image = "rbxassetid://5028857084"
    g2.ImageColor3 = palette.accent
    g2.ImageTransparency = 0.3
    g2.ZIndex = -1
    g2.Parent = btn
    _ts:Create(g2, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = -360}):Play()
    _ts:Create(g2, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.6}):Play()
    
    -- Title
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 30)
    t.Position = UDim2.new(0, 0, 0.2, 0)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = color
    t.TextSize = 24 -- lebih kecil
    t.Font = Enum.Font.GothamBold
    t.Parent = btn
    
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(0.9, 0, 0, 45)
    d.Position = UDim2.new(0.05, 0, 0.55, 0)
    d.BackgroundTransparency = 1
    d.Text = desc
    d.TextColor3 = palette.textMuted
    d.TextSize = 13 -- lebih kecil
    d.Font = Enum.Font.Gotham
    d.TextWrapped = true
    d.Parent = btn
    
    -- Hover effect
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = palette.cardHover}):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = palette.card}):Play()
    end)
    
    return btn
end

local freeBtn = createTierBtn(
    UDim2.new(0, 0, 0.18, 0),
    "FREE",
    "Directly choose script with normal features",
    palette.accent,
    palette.accent
)

local premiumBtn = createTierBtn(
    UDim2.new(0.54, 0, 0.18, 0),
    "PREMIUM",
    "Requires premium key to unlock advanced features",
    palette.gold,
    palette.gold
)

-- ================================================
-- HALAMAN 2: PREMIUM KEY INPUT
-- ================================================
local keyPage = Instance.new("Frame")
keyPage.Size = UDim2.new(1, 0, 1, 0)
keyPage.BackgroundTransparency = 1
keyPage.Visible = false
keyPage.Parent = pages

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, 0, 0, 48)
keyBox.Position = UDim2.new(0, 0, 0.2, 0)
keyBox.BackgroundColor3 = palette.card
keyBox.Text = ""
keyBox.PlaceholderText = "Enter Premium Key..."
keyBox.PlaceholderColor3 = palette.textMuted
keyBox.TextColor3 = palette.textMain
keyBox.TextSize = 20
keyBox.Font = Enum.Font.GothamBold
keyBox.BorderSizePixel = 0
keyBox.ClearTextOnFocus = false
keyBox.Parent = keyPage
mkCorner(keyBox, 8)
mkStroke(keyBox, palette.divider, 1)

local keySubmit = Instance.new("TextButton")
keySubmit.Size = UDim2.new(0.48, 0, 0, 42)
keySubmit.Position = UDim2.new(0.52, 0, 0.55, 0)
keySubmit.BackgroundColor3 = palette.gold
keySubmit.Text = "Validate Key"
keySubmit.TextColor3 = palette.bg
keySubmit.TextSize = 18
keySubmit.Font = Enum.Font.GothamBold
keySubmit.BorderSizePixel = 0
keySubmit.Parent = keyPage
mkCorner(keySubmit, 8)

local keyBack = Instance.new("TextButton")
keyBack.Size = UDim2.new(0.48, 0, 0, 42)
keyBack.Position = UDim2.new(0, 0, 0.55, 0)
keyBack.BackgroundColor3 = palette.card
keyBack.Text = "Back"
keyBack.TextColor3 = palette.textSub
keyBack.TextSize = 18
keyBack.Font = Enum.Font.GothamBold
keyBack.BorderSizePixel = 0
keyBack.Parent = keyPage
mkCorner(keyBack, 8)
mkStroke(keyBack, palette.divider, 1)

-- ================================================
-- HALAMAN 3: SCRIPT CATEGORY (SCROLLABLE)
-- ================================================
local categoryPage = Instance.new("Frame")
categoryPage.Size = UDim2.new(1, 0, 1, 0)
categoryPage.BackgroundTransparency = 1
categoryPage.Visible = false
categoryPage.Parent = pages

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.Position = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = palette.accent
scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
scrollFrame.Parent = categoryPage

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 10)
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 8)
listPadding.PaddingLeft = UDim.new(0, 0)
listPadding.PaddingRight = UDim.new(0, 0)
listPadding.PaddingBottom = UDim.new(0, 8)
listPadding.Parent = scrollFrame

-- TDS Button
local scriptBtn = Instance.new("TextButton")
scriptBtn.Size = UDim2.new(1, 0, 0, 55)
scriptBtn.BackgroundColor3 = palette.card
scriptBtn.Text = ""
scriptBtn.BorderSizePixel = 0
scriptBtn.LayoutOrder = 1
scriptBtn.Parent = scrollFrame
mkCorner(scriptBtn, 8)
mkStroke(scriptBtn, palette.divider, 1)

local scriptTitle = Instance.new("TextLabel")
scriptTitle.Size = UDim2.new(1, -18, 0, 28)
scriptTitle.Position = UDim2.new(0, 14, 0, 5)
scriptTitle.BackgroundTransparency = 1
scriptTitle.Text = "Tower Defense Simulator"
scriptTitle.TextColor3 = palette.textMain
scriptTitle.TextSize = 22 -- lebih kecil
scriptTitle.Font = Enum.Font.GothamBold
scriptTitle.TextXAlignment = Enum.TextXAlignment.Left
scriptTitle.Parent = scriptBtn

local scriptDesc = Instance.new("TextLabel")
scriptDesc.Size = UDim2.new(1, -18, 0, 22)
scriptDesc.Position = UDim2.new(0, 14, 0, 30)
scriptDesc.BackgroundTransparency = 1
scriptDesc.Text = "Auto Farm, Macros & Premium Scripts"
scriptDesc.TextColor3 = palette.textMuted
scriptDesc.TextSize = 15 -- lebih kecil
scriptDesc.Font = Enum.Font.Gotham
scriptDesc.TextXAlignment = Enum.TextXAlignment.Left
scriptDesc.Parent = scriptBtn

-- Merge Nuke Button
local mergeNukeBtn = Instance.new("TextButton")
mergeNukeBtn.Size = UDim2.new(1, 0, 0, 55)
mergeNukeBtn.BackgroundColor3 = palette.card
mergeNukeBtn.Text = ""
mergeNukeBtn.BorderSizePixel = 0
mergeNukeBtn.LayoutOrder = 2
mergeNukeBtn.Parent = scrollFrame
mkCorner(mergeNukeBtn, 8)
mkStroke(mergeNukeBtn, palette.divider, 1)

local mergeNukeTitle = Instance.new("TextLabel")
mergeNukeTitle.Size = UDim2.new(1, -18, 0, 28)
mergeNukeTitle.Position = UDim2.new(0, 14, 0, 5)
mergeNukeTitle.BackgroundTransparency = 1
mergeNukeTitle.Text = "Merge Nuke"
mergeNukeTitle.TextColor3 = palette.textMain
mergeNukeTitle.TextSize = 22 -- lebih kecil
mergeNukeTitle.Font = Enum.Font.GothamBold
mergeNukeTitle.TextXAlignment = Enum.TextXAlignment.Left
mergeNukeTitle.Parent = mergeNukeBtn

local mergeNukeDesc = Instance.new("TextLabel")
mergeNukeDesc.Size = UDim2.new(1, -18, 0, 22)
mergeNukeDesc.Position = UDim2.new(0, 14, 0, 30)
mergeNukeDesc.BackgroundTransparency = 1
mergeNukeDesc.Text = "Auto Merge & More"
mergeNukeDesc.TextColor3 = palette.textMuted
mergeNukeDesc.TextSize = 15 -- lebih kecil
mergeNukeDesc.Font = Enum.Font.Gotham
mergeNukeDesc.TextXAlignment = Enum.TextXAlignment.Left
mergeNukeDesc.Parent = mergeNukeBtn

-- Sell Lemons Button (BARU!)
local sellLemonsBtn = Instance.new("TextButton")
sellLemonsBtn.Size = UDim2.new(1, 0, 0, 55)
sellLemonsBtn.BackgroundColor3 = palette.card
sellLemonsBtn.Text = ""
sellLemonsBtn.BorderSizePixel = 0
sellLemonsBtn.LayoutOrder = 3
sellLemonsBtn.Parent = scrollFrame
mkCorner(sellLemonsBtn, 8)
mkStroke(sellLemonsBtn, palette.divider, 1)

local sellLemonsTitle = Instance.new("TextLabel")
sellLemonsTitle.Size = UDim2.new(1, -18, 0, 28)
sellLemonsTitle.Position = UDim2.new(0, 14, 0, 5)
sellLemonsTitle.BackgroundTransparency = 1
sellLemonsTitle.Text = "Sell Lemons"
sellLemonsTitle.TextColor3 = palette.textMain
sellLemonsTitle.TextSize = 22 -- lebih kecil
sellLemonsTitle.Font = Enum.Font.GothamBold
sellLemonsTitle.TextXAlignment = Enum.TextXAlignment.Left
sellLemonsTitle.Parent = sellLemonsBtn

local sellLemonsDesc = Instance.new("TextLabel")
sellLemonsDesc.Size = UDim2.new(1, -18, 0, 22)
sellLemonsDesc.Position = UDim2.new(0, 14, 0, 30)
sellLemonsDesc.BackgroundTransparency = 1
sellLemonsDesc.Text = "Auto Buy Button & Upgrade Money"
sellLemonsDesc.TextColor3 = palette.textMuted
sellLemonsDesc.TextSize = 15 -- lebih kecil
sellLemonsDesc.Font = Enum.Font.Gotham
sellLemonsDesc.TextXAlignment = Enum.TextXAlignment.Left
sellLemonsDesc.Parent = sellLemonsBtn

-- Coming Soon
local comingSoon = Instance.new("Frame")
comingSoon.Size = UDim2.new(1, 0, 0, 55)
comingSoon.BackgroundColor3 = palette.card
comingSoon.BackgroundTransparency = 0.6
comingSoon.BorderSizePixel = 0
comingSoon.LayoutOrder = 4
comingSoon.Parent = scrollFrame
mkCorner(comingSoon, 8)
mkStroke(comingSoon, palette.divider, 1)

local comingTitle = Instance.new("TextLabel")
comingTitle.Size = UDim2.new(1, -18, 1, 0)
comingTitle.Position = UDim2.new(0, 14, 0, 0)
comingTitle.BackgroundTransparency = 1
comingTitle.Text = "More Games Coming Soon..."
comingTitle.TextColor3 = palette.textMuted
comingTitle.TextSize = 20 -- lebih kecil
comingTitle.Font = Enum.Font.GothamBold
comingTitle.TextXAlignment = Enum.TextXAlignment.Left
comingTitle.Parent = comingSoon

-- ================================================
-- NAVIGASI & LOGIKA TRANSISI
-- ================================================
local function showPage(page)
    choosePage.Visible = (page == choosePage)
    keyPage.Visible = (page == keyPage)
    categoryPage.Visible = (page == categoryPage)

    if page == choosePage then
        subTitleText.Text = "Choose Tier to Proceed"
    elseif page == keyPage then
        subTitleText.Text = "Verify Premium Credentials"
    elseif page == categoryPage then
        subTitleText.Text = "Select Script (" .. _tier .. " Mode)"
    end
end

-- Klik Free
freeBtn.MouseButton1Click:Connect(function()
    _tier = "Free"
    getgenv().Tier = "Free"
    showPage(categoryPage)
end)

-- Klik Premium
premiumBtn.MouseButton1Click:Connect(function()
    showPage(keyPage)
end)

-- Klik Back
keyBack.MouseButton1Click:Connect(function()
    showPage(choosePage)
end)

-- Validasi Key Premium
keySubmit.MouseButton1Click:Connect(function()
    local text = keyBox.Text
    if text == "" then
        notify("Please enter a key!", palette.red)
        return
    end

    notify("Validating credentials...", palette.accent)

    local requestFunc = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or request
    if not requestFunc then
        notify("Executor lacks http request capability!", palette.red)
        return
    end

    local success, response = pcall(function()
        return requestFunc({
            Url = SUPABASE_URL .. "?select=*&key=eq." .. text,
            Method = "GET",
            Headers = {
                ["apikey"] = SUPABASE_ANON_KEY,
                ["Authorization"] = "Bearer " .. SUPABASE_ANON_KEY,
                ["Content-Type"] = "application/json"
            }
        })
    end)

    if success and response and response.StatusCode == 200 then
        local data = _http:JSONDecode(response.Body)
        if #data > 0 then
            _tier = "Premium"
            getgenv().Tier = "Premium"
            notify("Premium verification successful!", palette.green)
            task.wait(1)
            showPage(categoryPage)
        else
            notify("Invalid or expired premium key!", palette.red)
        end
    else
        notify("Network error during key verification.", palette.red)
    end
end)

-- Jalankan TDS Script
scriptBtn.MouseButton1Click:Connect(function()
    notify("Loading TDS module...", palette.green)
    task.wait(1.2)
    screenGui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/Loader/Script/TowerDefensiSimulator/Main.lua"))()
end)

-- Jalankan Merge Nuke Script
mergeNukeBtn.MouseButton1Click:Connect(function()
    notify("Loading Merge Nuke module...", palette.green)
    task.wait(1.2)
    screenGui:Destroy()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/Loader/Script/Merge%20Nuke/Main.lua"))()
end)

-- Jalankan Sell Lemons Script (BARU!)
sellLemonsBtn.MouseButton1Click:Connect(function()
    notify("Loading Sell Lemons module...", palette.green)
    task.wait(1.2)
    screenGui:Destroy()
    -- TODO: Load Sell Lemons script
    -- loadstring(game:HttpGet("URL_SELL_LEMONS"))()
end)

-- Minimize hover
local function bindHover(btn, hoverColor, defaultColor)
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = defaultColor}):Play()
    end)
end

bindHover(freeBtn, palette.cardHover, palette.card)
bindHover(premiumBtn, palette.cardHover, palette.card)
bindHover(keyBack, palette.cardHover, palette.card)
bindHover(keySubmit, Color3.fromRGB(200, 150, 0), palette.gold)
bindHover(scriptBtn, palette.cardHover, palette.card)
bindHover(mergeNukeBtn, palette.cardHover, palette.card)
bindHover(sellLemonsBtn, palette.cardHover, palette.card)