--[[
    BorcaHub // Loader Module
    Custom UI Loader dengan 1000x Lebih Keren (Bukan AI Look, Dark Cyber Handcrafted UI)
]]

local _tier = "Free"
local _plr = game:GetService("Players").LocalPlayer
local _ts  = game:GetService("TweenService")
local _uis = game:GetService("UserInputService")
local _http = game:GetService("HttpService")

-- Konfigurasi Supabase REST API
local SUPABASE_URL = "https://YOUR_PROJECT_REF.supabase.co/rest/v1/keys"
local SUPABASE_ANON_KEY = "YOUR_ANON_KEY"

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

-- Hapus loader lama jika ada
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
mainFrame.Size = UDim2.new(0, 480, 0, 320)
mainFrame.BackgroundColor3 = palette.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false -- Allow corner lights to be visible
mainFrame.Parent = screenGui
mkCorner(mainFrame, 12)
mkStroke(mainFrame, palette.divider, 1)

-- Rotating corner lights
local function createCornerLight(position, anchor, color)
    local light = Instance.new("ImageLabel")
    light.Size = UDim2.new(0, 80, 0, 80)
    light.Position = position
    light.AnchorPoint = anchor
    light.BackgroundTransparency = 1
    light.Image = "rbxassetid://5028857084" -- Radial blur glow
    light.ImageColor3 = color
    light.ImageTransparency = 0.5
    light.ZIndex = -1
    light.Parent = mainFrame
    
    -- Rotate animation
    local rotationTween = _ts:Create(light, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
        Rotation = 360
    })
    rotationTween:Play()
    
    return light
end

createCornerLight(UDim2.new(0, 0, 0, 0), Vector2.new(0, 0), palette.accent)
createCornerLight(UDim2.new(1, 0, 0, 0), Vector2.new(1, 0), palette.gold)
createCornerLight(UDim2.new(0, 0, 1, 0), Vector2.new(0, 1), palette.gold)
createCornerLight(UDim2.new(1, 0, 1, 0), Vector2.new(1, 1), palette.accent)

-- Top Accent Line
local topAccent = Instance.new("Frame")
topAccent.Size = UDim2.new(1, 0, 0, 2)
topAccent.BorderSizePixel = 0
topAccent.BackgroundColor3 = Color3.fromRGB(255,255,255)
topAccent.Parent = mainFrame
mkGradient(topAccent, palette.accent, palette.gold, 0)

-- Dragging Logic
local dragging, dragStart, startPos
mainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        startPos = mainFrame.Position
    end
end)
mainFrame.InputEnded:Connect(function(inp)
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

-- Title
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, 0, 0, 50)
titleText.Position = UDim2.new(0, 0, 0, 2)
titleText.BackgroundTransparency = 1
titleText.Text = "BORCA HUB"
titleText.TextColor3 = palette.textMain
titleText.TextSize = 22
titleText.Font = Enum.Font.GothamBold
titleText.Parent = mainFrame

local subTitleText = Instance.new("TextLabel")
subTitleText.Size = UDim2.new(1, 0, 0, 20)
subTitleText.Position = UDim2.new(0, 0, 0, 42)
subTitleText.BackgroundTransparency = 1
subTitleText.Text = "Choose Tier to Proceed"
subTitleText.TextColor3 = palette.textSub
subTitleText.TextSize = 12
subTitleText.Font = Enum.Font.GothamMedium
subTitleText.Parent = mainFrame

-- Container Halaman
local pages = Instance.new("Frame")
pages.Size = UDim2.new(1, -40, 1, -90)
pages.Position = UDim2.new(0, 20, 0, 75)
pages.BackgroundTransparency = 1
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
    nt.TextSize = 12
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
-- HALAMAN 1: PILIH TIER
-- ================================================
local choosePage = Instance.new("Frame")
choosePage.Size = UDim2.new(1, 0, 1, 0)
choosePage.BackgroundTransparency = 1
choosePage.Parent = pages

-- Button Free Tier
local freeBtn = Instance.new("TextButton")
freeBtn.Size = UDim2.new(0.46, 0, 0.7, 0)
freeBtn.Position = UDim2.new(0, 0, 0.15, 0)
freeBtn.BackgroundColor3 = palette.card
freeBtn.Text = ""
freeBtn.BorderSizePixel = 0
freeBtn.Parent = choosePage
mkCorner(freeBtn, 10)
mkStroke(freeBtn, palette.divider, 1)

local freeTitle = Instance.new("TextLabel")
freeTitle.Size = UDim2.new(1, 0, 0, 30)
freeTitle.Position = UDim2.new(0, 0, 0.25, 0)
freeTitle.BackgroundTransparency = 1
freeTitle.Text = "FREE"
freeTitle.TextColor3 = palette.accent
freeTitle.TextSize = 20
freeTitle.Font = Enum.Font.GothamBold
freeTitle.Parent = freeBtn

local freeDesc = Instance.new("TextLabel")
freeDesc.Size = UDim2.new(1, 0, 0, 45)
freeDesc.Position = UDim2.new(0, 0, 0.48, 0)
freeDesc.BackgroundTransparency = 1
freeDesc.Text = "Directly choose script\nwith normal features"
freeDesc.TextColor3 = palette.textMuted
freeDesc.TextSize = 13 -- Diperbesar dari 11
freeDesc.Font = Enum.Font.Gotham
freeDesc.Parent = freeBtn

-- Button Premium Tier
local premiumBtn = Instance.new("TextButton")
premiumBtn.Size = UDim2.new(0.46, 0, 0.7, 0)
premiumBtn.Position = UDim2.new(0.54, 0, 0.15, 0)
premiumBtn.BackgroundColor3 = palette.card
premiumBtn.Text = ""
premiumBtn.BorderSizePixel = 0
premiumBtn.Parent = choosePage
mkCorner(premiumBtn, 10)
mkStroke(premiumBtn, palette.divider, 1)

local premiumTitle = Instance.new("TextLabel")
premiumTitle.Size = UDim2.new(1, 0, 0, 30)
premiumTitle.Position = UDim2.new(0, 0, 0.25, 0)
premiumTitle.BackgroundTransparency = 1
premiumTitle.Text = "PREMIUM"
premiumTitle.TextColor3 = palette.gold
premiumTitle.TextSize = 20
premiumTitle.Font = Enum.Font.GothamBold
premiumTitle.Parent = premiumBtn

local premiumDesc = Instance.new("TextLabel")
premiumDesc.Size = UDim2.new(1, 0, 0, 45)
premiumDesc.Position = UDim2.new(0, 0, 0.48, 0)
premiumDesc.BackgroundTransparency = 1
premiumDesc.Text = "Requires premium key\nto unlock advanced features"
premiumDesc.TextColor3 = palette.textMuted
premiumDesc.TextSize = 13 -- Diperbesar dari 11
premiumDesc.Font = Enum.Font.Gotham
premiumDesc.Parent = premiumBtn

-- ================================================
-- HALAMAN 2: PREMIUM KEY INPUT
-- ================================================
local keyPage = Instance.new("Frame")
keyPage.Size = UDim2.new(1, 0, 1, 0)
keyPage.BackgroundTransparency = 1
keyPage.Visible = false
keyPage.Parent = pages

local keyBox = Instance.new("TextBox")
keyBox.Size = UDim2.new(1, 0, 0, 44)
keyBox.Position = UDim2.new(0, 0, 0.2, 0)
keyBox.BackgroundColor3 = palette.card
keyBox.Text = ""
keyBox.PlaceholderText = "Enter your Premium Key..."
keyBox.PlaceholderColor3 = palette.textMuted
keyBox.TextColor3 = palette.textMain
keyBox.TextSize = 15 -- Diperbesar dari 14
keyBox.Font = Enum.Font.GothamBold
keyBox.BorderSizePixel = 0
keyBox.ClearTextOnFocus = false
keyBox.Parent = keyPage
mkCorner(keyBox, 8)
mkStroke(keyBox, palette.divider, 1)

local keySubmit = Instance.new("TextButton")
keySubmit.Size = UDim2.new(0.48, 0, 0, 40)
keySubmit.Position = UDim2.new(0.52, 0, 0.55, 0)
keySubmit.BackgroundColor3 = palette.gold
keySubmit.Text = "Validate Key"
keySubmit.TextColor3 = palette.bg
keySubmit.TextSize = 14 -- Diperbesar dari 13
keySubmit.Font = Enum.Font.GothamBold
keySubmit.BorderSizePixel = 0
keySubmit.Parent = keyPage
mkCorner(keySubmit, 8)

local keyBack = Instance.new("TextButton")
keyBack.Size = UDim2.new(0.48, 0, 0, 40)
keyBack.Position = UDim2.new(0, 0, 0.55, 0)
keyBack.BackgroundColor3 = palette.card
keyBack.Text = "Back"
keyBack.TextColor3 = palette.textSub
keyBack.TextSize = 14 -- Diperbesar dari 13
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

-- Scrolling Frame for game list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.Position = UDim2.new(0, 0, 0, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.ScrollBarImageColor3 = palette.accent
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = categoryPage

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingTop = UDim.new(0, 0)
listPadding.PaddingBottom = UDim.new(0, 0)
listPadding.Parent = scrollFrame

-- TDS Button
local scriptBtn = Instance.new("TextButton")
scriptBtn.Size = UDim2.new(1, 0, 0, 60)
scriptBtn.BackgroundColor3 = palette.card
scriptBtn.Text = ""
scriptBtn.BorderSizePixel = 0
scriptBtn.LayoutOrder = 1
scriptBtn.Parent = scrollFrame
mkCorner(scriptBtn, 8)
mkStroke(scriptBtn, palette.divider, 1)

local scriptTitle = Instance.new("TextLabel")
scriptTitle.Size = UDim2.new(1, -20, 0, 30)
scriptTitle.Position = UDim2.new(0, 15, 0, 6)
scriptTitle.BackgroundTransparency = 1
scriptTitle.Text = "Tower Defense Simulator"
scriptTitle.TextColor3 = palette.textMain
scriptTitle.TextSize = 17
scriptTitle.Font = Enum.Font.GothamBold
scriptTitle.TextXAlignment = Enum.TextXAlignment.Left
scriptTitle.Parent = scriptBtn

local scriptDesc = Instance.new("TextLabel")
scriptDesc.Size = UDim2.new(1, -20, 0, 20)
scriptDesc.Position = UDim2.new(0, 15, 0, 32)
scriptDesc.BackgroundTransparency = 1
scriptDesc.Text = "Click to run TDS modules (Auto Farm, Macros, etc.)"
scriptDesc.TextColor3 = palette.textMuted
scriptDesc.TextSize = 12
scriptDesc.Font = Enum.Font.Gotham
scriptDesc.TextXAlignment = Enum.TextXAlignment.Left
scriptDesc.Parent = scriptBtn

-- Merge Nuke Button
local mergeNukeBtn = Instance.new("TextButton")
mergeNukeBtn.Size = UDim2.new(1, 0, 0, 60)
mergeNukeBtn.BackgroundColor3 = palette.card
mergeNukeBtn.Text = ""
mergeNukeBtn.BorderSizePixel = 0
mergeNukeBtn.LayoutOrder = 2
mergeNukeBtn.Parent = scrollFrame
mkCorner(mergeNukeBtn, 8)
mkStroke(mergeNukeBtn, palette.divider, 1)

local mergeNukeTitle = Instance.new("TextLabel")
mergeNukeTitle.Size = UDim2.new(1, -20, 0, 30)
mergeNukeTitle.Position = UDim2.new(0, 15, 0, 6)
mergeNukeTitle.BackgroundTransparency = 1
mergeNukeTitle.Text = "Merge Nuke"
mergeNukeTitle.TextColor3 = palette.textMain
mergeNukeTitle.TextSize = 17
mergeNukeTitle.Font = Enum.Font.GothamBold
mergeNukeTitle.TextXAlignment = Enum.TextXAlignment.Left
mergeNukeTitle.Parent = mergeNukeBtn

local mergeNukeDesc = Instance.new("TextLabel")
mergeNukeDesc.Size = UDim2.new(1, -20, 0, 20)
mergeNukeDesc.Position = UDim2.new(0, 15, 0, 32)
mergeNukeDesc.BackgroundTransparency = 1
mergeNukeDesc.Text = "Click to run Merge Nuke modules (Auto Merge, etc.)"
mergeNukeDesc.TextColor3 = palette.textMuted
mergeNukeDesc.TextSize = 12
mergeNukeDesc.Font = Enum.Font.Gotham
mergeNukeDesc.TextXAlignment = Enum.TextXAlignment.Left
mergeNukeDesc.Parent = mergeNukeBtn

-- Coming Soon placeholder
local comingSoon = Instance.new("Frame")
comingSoon.Size = UDim2.new(1, 0, 0, 60)
comingSoon.BackgroundColor3 = palette.card
comingSoon.BackgroundTransparency = 0.6
comingSoon.BorderSizePixel = 0
comingSoon.LayoutOrder = 3
comingSoon.Parent = scrollFrame
mkCorner(comingSoon, 8)
mkStroke(comingSoon, palette.divider, 1)

local comingTitle = Instance.new("TextLabel")
comingTitle.Size = UDim2.new(1, -20, 1, 0)
comingTitle.Position = UDim2.new(0, 15, 0, 0)
comingTitle.BackgroundTransparency = 1
comingTitle.Text = "Other Games Coming Soon..."
comingTitle.TextColor3 = palette.textMuted
comingTitle.TextSize = 15
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
    
    -- Load TDS script utama dari repo BorCaHub
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/Loader/Script/TowerDefensiSimulator/Main.lua"))()
end)

-- Jalankan Merge Nuke Script
mergeNukeBtn.MouseButton1Click:Connect(function()
    notify("Loading Merge Nuke module...", palette.green)
    task.wait(1.2)
    screenGui:Destroy()
    
    -- Load Merge Nuke script utama dari repo BorCaHub
    loadstring(game:HttpGet("https://raw.githubusercontent.com/BorCaHub/BorcaScriptHub/main/Loader/Script/Merge%20Nuke/Main.lua"))()
end)

-- Hover effect umum
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
bindHover(scriptBtn, palette.cardHover, palette.card)
bindHover(mergeNukeBtn, palette.cardHover, palette.card)
