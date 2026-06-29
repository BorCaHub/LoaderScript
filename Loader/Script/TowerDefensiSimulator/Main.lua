--[[ 
    BorcaHub // TDS Module
    rev.4f — Large Text & Corner Glow Handcrafted Interface
]]

local _tier = getgenv().Tier or "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _rs  = game:GetService("RunService")
local _http = game:GetService("HttpService")

local _activeLoops = {}

-- ================================================
-- WARNA & KONFIGURASI
-- ================================================
local palette = {
    bg        = Color3.fromRGB(10, 10, 15),
    panel     = Color3.fromRGB(16, 16, 26),
    sidebar   = Color3.fromRGB(12, 12, 20),
    card      = Color3.fromRGB(22, 22, 36),
    cardHover = Color3.fromRGB(30, 30, 48),
    accent    = Color3.fromRGB(0, 168, 255),
    gold      = Color3.fromRGB(255, 185, 0),
    goldDim   = Color3.fromRGB(180, 130, 0),
    textMain  = Color3.fromRGB(255, 255, 255),
    textSub   = Color3.fromRGB(165, 165, 185),
    textMuted = Color3.fromRGB(100, 100, 120),
    red       = Color3.fromRGB(255, 60, 60),
    green     = Color3.fromRGB(0, 220, 120),
    divider   = Color3.fromRGB(44, 44, 64),
    execute   = Color3.fromRGB(0, 180, 100),
    close     = Color3.fromRGB(50, 50, 70),
}

-- ================================================
-- DAFTAR FITUR (SIMPLIFIED & CLEAN EXAMPLE)
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
-- STRUKTUR GUI UTAMA (DI-PERBESAR KE 850x550 UNTUK TEXT 2X LIPAT)
-- ================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BorcaHubTDS"
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
mainFrame.ClipsDescendants = false -- Agar Glow bisa terlihat di luar frame
mainFrame.Parent = screenGui
mkCorner(mainFrame, 16)

-- 🌟 NEON GLOW BORDER EFFECT (UIStroke dengan Gradient Aksen)
local borderGlow = mkStroke(mainFrame, Color3.fromRGB(255, 255, 255), 3)
mkGradient(borderGlow, palette.accent, palette.gold, 45)

-- 🌟 CAHAYA LIGHT DI SETIAP SUDUT (CORNER GLOWS)
local function createCornerLight(name, pos, anchor)
    local light = Instance.new("ImageLabel")
    light.Name = name
    light.AnchorPoint = anchor
    light.Position = pos
    light.Size = UDim2.new(0, 120, 0, 120)
    light.BackgroundTransparency = 1
    light.Image = "rbxassetid://5028857084" -- Blur radial glow
    light.ImageColor3 = (name:find("Gold")) and palette.gold or palette.accent
    light.ImageTransparency = 0.4
    light.ZIndex = -1
    light.Parent = mainFrame
end
createCornerLight("TopLeftGlow", UDim2.new(0, 0, 0, 0), Vector2.new(0.5, 0.5))
createCornerLight("TopRightGlowGold", UDim2.new(1, 0, 0, 0), Vector2.new(0.5, 0.5))
createCornerLight("BottomLeftGlowGold", UDim2.new(0, 0, 1, 0), Vector2.new(0.5, 0.5))
createCornerLight("BottomRightGlow", UDim2.new(1, 0, 1, 0), Vector2.new(0.5, 0.5))

-- Intro Animation
mainFrame.Size = UDim2.new(0, 0, 0, 0)
mainFrame.BackgroundTransparency = 1
_ts:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 850, 0, 550),
    BackgroundTransparency = 0
}):Play()

-- ================================================
-- TITLE BAR (TEXT DI-PERBESAR 2X LIPAT)
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
titleText.Text = "BORCA HUB"
titleText.TextColor3 = palette.textMain
titleText.TextSize = 32 -- Diperbesar 2x lipat (sebelumnya 18)
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
tagLabel.TextSize = 18 -- Diperbesar 2x lipat (sebelumnya 10)
tagLabel.Font = Enum.Font.GothamBold
tagLabel.BorderSizePixel = 0
tagLabel.Parent = titleBar
mkCorner(tagLabel, 6)

local versionLabel = Instance.new("TextLabel")
versionLabel.Name = "Ver"
versionLabel.Size = UDim2.new(0, 120, 1, 0)
versionLabel.Position = UDim2.new(1, -195, 0, 0) -- Digeser ke kiri agar tidak menabrak tombol X
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.0" -- Diganti dari v3.1.7
versionLabel.TextColor3 = palette.textMuted
versionLabel.TextSize = 20
versionLabel.Font = Enum.Font.GothamMedium
versionLabel.TextXAlignment = Enum.TextXAlignment.Right
versionLabel.Parent = titleBar

-- Tombol Close (X) di Atas Kanan
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

-- Divider bawah title
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
-- PANEL KIRI: LIST STRAT (TEXT DI-PERBESAR)
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
leftHeader.Text = "Features" -- Diganti dari Scripts & Strats
leftHeader.TextColor3 = palette.textSub
leftHeader.TextSize = 22 -- Diperbesar 2x lipat (sebelumnya 12)
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
-- PANEL KANAN: DETAIL & INFO (Hanya 4 Fields & Text Gede)
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
infoHeader.TextSize = 22 -- Diperbesar 2x lipat (sebelumnya 13)
infoHeader.Font = Enum.Font.GothamBold
infoHeader.TextXAlignment = Enum.TextXAlignment.Left
infoHeader.Parent = rightPanel
mkPadding(infoHeader, 0, 0, 20, 0)

local infoContent = Instance.new("TextLabel")
infoContent.Name = "InfoText"
infoContent.Size = UDim2.new(1, -40, 1, -140)
infoContent.Position = UDim2.new(0, 20, 0, 60)
infoContent.BackgroundTransparency = 1
infoContent.Text = "Select a script from the list\nto view details."
infoContent.TextColor3 = palette.textSub
infoContent.TextSize = 18 -- Diperbesar 2x lipat (sebelumnya 12)
infoContent.Font = Enum.Font.GothamMedium
infoContent.TextXAlignment = Enum.TextXAlignment.Left
infoContent.TextYAlignment = Enum.TextYAlignment.Top
infoContent.TextWrapped = true
infoContent.RichText = true
infoContent.Parent = rightPanel

-- ================================================
-- BOTTOM BUTTONS (TEXT DI-PERBESAR 2X LIPAT)
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
executeBtn.Size = UDim2.new(1, 0, 1, 0) -- Diubah menjadi ukuran penuh karena Close pindah ke atas
executeBtn.Position = UDim2.new(0, 0, 0, 0)
executeBtn.BackgroundColor3 = palette.execute
executeBtn.Text = "Execute"
executeBtn.TextColor3 = palette.textMain
executeBtn.TextSize = 20 -- Diperbesar 2x lipat (sebelumnya 13)
executeBtn.Font = Enum.Font.GothamBold
executeBtn.BorderSizePixel = 0
executeBtn.AutoButtonColor = false
executeBtn.Parent = btnRow
mkCorner(executeBtn, 10)

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
-- POPUP NOTIFIKASI BESAR JIKA AKSES DITOLAK
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
-- RENDER DAFTAR FITUR (TEXT DI-PERBESAR)
-- ================================================
for i, feat in ipairs(featureList) do
    local tierColor = (feat.tier == "premium") and palette.gold or palette.accent
    local locked = (feat.tier == "premium" and _tier ~= "Premium")
    
    local card = Instance.new("TextButton")
    card.Name = "Card_" .. feat.id
    card.Size = UDim2.new(1, -8, 0, 80) -- Dipertinggi dari 54
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
    dot.Size = UDim2.new(0, 14, 0, 14) -- Diperbesar dari 8
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
    nameLabel.TextSize = 22 -- Diperbesar 2x lipat (sebelumnya 13)
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
    descLabel.TextSize = 15 -- Diperbesar 2x lipat (sebelumnya 10)
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
-- PROSES EKSEKUSI
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
    nt.TextSize = 18 -- Diperbesar
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
    
    if feat.running then
        notifyPopup("▶ " .. feat.name .. " activated", palette.execute)
    else
        notifyPopup("⏹ " .. feat.name .. " stopped", palette.close)
    end
end)

-- Hover effects untuk tombol bawah & Close X
for _, btn in pairs({closeBtn, executeBtn}) do
    btn.MouseEnter:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (btn == executeBtn) and palette.execute:Lerp(Color3.fromRGB(0,0,0), 0.2) or Color3.fromRGB(200, 40, 40)
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        _ts:Create(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = (btn == executeBtn) and palette.execute or Color3.fromRGB(255, 60, 60)
        }):Play()
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
