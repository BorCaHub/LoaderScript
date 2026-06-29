-- // TDS Macro Replay - Free Version
-- // UI: Custom Minimalist (Black & White)
-- // Author: BorcaHub

-- ══════════════════════════════════════════
-- // SERVICES
-- ══════════════════════════════════════════
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VirtualInput     = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ══════════════════════════════════════════
-- // STATE
-- ══════════════════════════════════════════
local Macro = {
    Recording        = false,
    Playing          = false,
    Looping          = false,
    Actions          = {},
    StartTime        = 0,
    Connection       = nil,
    PlayThread       = nil,
    AutoResumeRecord = false,
    AutoResumePlay   = false,
}

-- Library of saved macros (cards)
local MacroLibrary = {}
local SelectedCard = nil  -- currently selected card index

-- ══════════════════════════════════════════
-- // UI COLORS & FONTS
-- ══════════════════════════════════════════
local C = {
    BG        = Color3.fromRGB(10,  10,  10),
    Surface   = Color3.fromRGB(18,  18,  18),
    Surface2  = Color3.fromRGB(26,  26,  26),
    Border    = Color3.fromRGB(38,  38,  38),
    White     = Color3.fromRGB(255, 255, 255),
    Grey      = Color3.fromRGB(130, 130, 130),
    DimGrey   = Color3.fromRGB(55,  55,  55),
    AccentOn  = Color3.fromRGB(255, 255, 255),
    AccentOff = Color3.fromRGB(38,  38,  38),
    Red       = Color3.fromRGB(210, 55,  55),
    Green     = Color3.fromRGB(70,  190, 110),
    Yellow    = Color3.fromRGB(240, 190, 50),
    Blue      = Color3.fromRGB(90,  140, 255),
    Selected  = Color3.fromRGB(38,  38,  38),
    SelBorder = Color3.fromRGB(255, 255, 255),
}

local Font     = Enum.Font.GothamMedium
local FontBold = Enum.Font.GothamBold
local FontSemi = Enum.Font.GothamSemibold

local function tw(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad), props):Play()
end

local function makeDraggable(frame, handle)
    local drag, ds, sp = false, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

-- ══════════════════════════════════════════
-- // SCREEN GUI
-- ══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "BorcaMacro"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder   = 999
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- ══════════════════════════════════════════
-- // MAIN WINDOW  (Space Hub layout)
-- LEFT: card list  |  RIGHT: info + detail
-- ══════════════════════════════════════════
local Win = Instance.new("Frame", ScreenGui)
Win.Name             = "Win"
Win.Size             = UDim2.new(0, 520, 0, 360)
Win.Position         = UDim2.new(0.5, -260, 0.5, -180)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.ClipsDescendants = true
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 10)
local WinStroke = Instance.new("UIStroke", Win)
WinStroke.Color = C.Border; WinStroke.Thickness = 1

-- Title bar
local TBar = Instance.new("Frame", Win)
TBar.Size = UDim2.new(1,0,0,42); TBar.BackgroundColor3 = C.Surface; TBar.BorderSizePixel = 0
Instance.new("UICorner", TBar).CornerRadius = UDim.new(0,10)
local TBarFix = Instance.new("Frame", TBar)
TBarFix.Size=UDim2.new(1,0,0,10); TBarFix.Position=UDim2.new(0,0,1,-10)
TBarFix.BackgroundColor3=C.Surface; TBarFix.BorderSizePixel=0

local TitleLbl = Instance.new("TextLabel", TBar)
TitleLbl.Size=UDim2.new(1,-80,1,0); TitleLbl.Position=UDim2.new(0,14,0,0)
TitleLbl.BackgroundTransparency=1; TitleLbl.Text="TDS MACRO HUB"
TitleLbl.TextColor3=C.White; TitleLbl.Font=FontBold; TitleLbl.TextSize=14
TitleLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Close btn
local CloseBtn = Instance.new("TextButton", TBar)
CloseBtn.Size=UDim2.new(0,28,0,28); CloseBtn.Position=UDim2.new(1,-36,0.5,-14)
CloseBtn.BackgroundColor3=C.DimGrey; CloseBtn.Text="✕"; CloseBtn.TextColor3=C.White
CloseBtn.Font=FontBold; CloseBtn.TextSize=11; CloseBtn.BorderSizePixel=0
Instance.new("UICorner", CloseBtn).CornerRadius=UDim.new(0,4)
CloseBtn.MouseButton1Click:Connect(function() Win.Visible=false end)

makeDraggable(Win, TBar)

-- ── LEFT PANEL: Macro Cards ───────────────
local LeftPanel = Instance.new("Frame", Win)
LeftPanel.Size=UDim2.new(0,220,1,-42); LeftPanel.Position=UDim2.new(0,0,0,42)
LeftPanel.BackgroundColor3=C.Surface; LeftPanel.BorderSizePixel=0

local LPStroke = Instance.new("UIStroke", LeftPanel)
LPStroke.Color=C.Border; LPStroke.Thickness=1
LPStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border

local LPTitle = Instance.new("TextLabel", LeftPanel)
LPTitle.Size=UDim2.new(1,0,0,30); LPTitle.BackgroundTransparency=1
LPTitle.Text="Saved Macros"; LPTitle.TextColor3=C.White
LPTitle.Font=FontSemi; LPTitle.TextSize=11
LPTitle.TextXAlignment=Enum.TextXAlignment.Left
local LPTitlePad=Instance.new("UIPadding",LPTitle)
LPTitlePad.PaddingLeft=UDim.new(0,12)

-- Divider
local LPDiv=Instance.new("Frame",LeftPanel)
LPDiv.Size=UDim2.new(1,0,0,1); LPDiv.Position=UDim2.new(0,0,0,30)
LPDiv.BackgroundColor3=C.Border; LPDiv.BorderSizePixel=0

-- Card scroll
local CardScroll = Instance.new("ScrollingFrame", LeftPanel)
CardScroll.Size=UDim2.new(1,0,1,-31); CardScroll.Position=UDim2.new(0,0,0,31)
CardScroll.BackgroundTransparency=1; CardScroll.BorderSizePixel=0
CardScroll.ScrollBarThickness=2; CardScroll.ScrollBarImageColor3=C.DimGrey
CardScroll.CanvasSize=UDim2.new(0,0,0,0); CardScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y

local CardList = Instance.new("Frame", CardScroll)
CardList.Name="CardList"; CardList.Size=UDim2.new(1,0,0,0)
CardList.AutomaticSize=Enum.AutomaticSize.Y; CardList.BackgroundTransparency=1
local CardLL=Instance.new("UIListLayout",CardList)
CardLL.Padding=UDim.new(0,1); CardLL.SortOrder=Enum.SortOrder.LayoutOrder
local CardPad=Instance.new("UIPadding",CardList)
CardPad.PaddingTop=UDim.new(0,4); CardPad.PaddingBottom=UDim.new(0,4)

-- ── RIGHT PANEL ───────────────────────────
local RightPanel = Instance.new("Frame", Win)
RightPanel.Size=UDim2.new(1,-220,1,-42); RightPanel.Position=UDim2.new(0,220,0,42)
RightPanel.BackgroundTransparency=1; RightPanel.BorderSizePixel=0

-- Top half: Info
local InfoBox = Instance.new("Frame", RightPanel)
InfoBox.Size=UDim2.new(1,-16,0,130); InfoBox.Position=UDim2.new(0,8,0,8)
InfoBox.BackgroundColor3=C.Surface2; InfoBox.BorderSizePixel=0
Instance.new("UICorner",InfoBox).CornerRadius=UDim.new(0,6)
local InfoStroke=Instance.new("UIStroke",InfoBox); InfoStroke.Color=C.Border; InfoStroke.Thickness=1

local InfoTitle=Instance.new("TextLabel",InfoBox)
InfoTitle.Size=UDim2.new(1,0,0,26); InfoTitle.BackgroundTransparency=1
InfoTitle.Text="Information"; InfoTitle.TextColor3=C.White
InfoTitle.Font=FontSemi; InfoTitle.TextSize=11
InfoTitle.TextXAlignment=Enum.TextXAlignment.Left
local ITP=Instance.new("UIPadding",InfoTitle); ITP.PaddingLeft=UDim.new(0,10)

local InfoDiv=Instance.new("Frame",InfoBox)
InfoDiv.Size=UDim2.new(1,0,0,1); InfoDiv.Position=UDim2.new(0,0,0,26)
InfoDiv.BackgroundColor3=C.Border; InfoDiv.BorderSizePixel=0

local InfoContent=Instance.new("TextLabel",InfoBox)
InfoContent.Size=UDim2.new(1,-16,1,-34); InfoContent.Position=UDim2.new(0,10,0,32)
InfoContent.BackgroundTransparency=1; InfoContent.TextColor3=C.Grey
InfoContent.Font=Font; InfoContent.TextSize=11; InfoContent.TextWrapped=true
InfoContent.TextXAlignment=Enum.TextXAlignment.Left
InfoContent.TextYAlignment=Enum.TextYAlignment.Top
InfoContent.Text="Select a macro from the list\nto view its details."

-- Bottom half: Details
local DetailBox = Instance.new("Frame", RightPanel)
DetailBox.Size=UDim2.new(1,-16,0,100); DetailBox.Position=UDim2.new(0,8,0,146)
DetailBox.BackgroundColor3=C.Surface2; DetailBox.BorderSizePixel=0
Instance.new("UICorner",DetailBox).CornerRadius=UDim.new(0,6)
local DetStroke=Instance.new("UIStroke",DetailBox); DetStroke.Color=C.Border; DetStroke.Thickness=1

local DetTitle=Instance.new("TextLabel",DetailBox)
DetTitle.Size=UDim2.new(1,0,0,26); DetTitle.BackgroundTransparency=1
DetTitle.Text="Details"; DetTitle.TextColor3=C.White
DetTitle.Font=FontSemi; DetTitle.TextSize=11
DetTitle.TextXAlignment=Enum.TextXAlignment.Left
local DTP=Instance.new("UIPadding",DetTitle); DTP.PaddingLeft=UDim.new(0,10)

local DetDiv=Instance.new("Frame",DetailBox)
DetDiv.Size=UDim2.new(1,0,0,1); DetDiv.Position=UDim2.new(0,0,0,26)
DetDiv.BackgroundColor3=C.Border; DetDiv.BorderSizePixel=0

local DetailContent=Instance.new("TextLabel",DetailBox)
DetailContent.Size=UDim2.new(1,-16,1,-34); DetailContent.Position=UDim2.new(0,10,0,32)
DetailContent.BackgroundTransparency=1; DetailContent.TextColor3=C.Grey
DetailContent.Font=Font; DetailContent.TextSize=11; DetailContent.TextWrapped=true
DetailContent.TextXAlignment=Enum.TextXAlignment.Left
DetailContent.TextYAlignment=Enum.TextYAlignment.Top
DetailContent.Text="• Actions: —\n• Status: —\n• Author: BorcaHub"

-- Bottom buttons: Close + Execute
local BtnRow = Instance.new("Frame", RightPanel)
BtnRow.Size=UDim2.new(1,-16,0,36); BtnRow.Position=UDim2.new(0,8,0,254)
BtnRow.BackgroundTransparency=1; BtnRow.BorderSizePixel=0

local ExecBtn = Instance.new("TextButton", BtnRow)
ExecBtn.Size=UDim2.new(0.48,0,1,0); ExecBtn.Position=UDim2.new(0.52,0,0,0)
ExecBtn.BackgroundColor3=C.White; ExecBtn.Text="▶  Execute"
ExecBtn.TextColor3=C.BG; ExecBtn.Font=FontBold; ExecBtn.TextSize=12
ExecBtn.BorderSizePixel=0
Instance.new("UICorner",ExecBtn).CornerRadius=UDim.new(0,6)

local StopBtn2 = Instance.new("TextButton", BtnRow)
StopBtn2.Size=UDim2.new(0.48,0,1,0); StopBtn2.Position=UDim2.new(0,0,0,0)
StopBtn2.BackgroundColor3=C.Surface; StopBtn2.Text="⏸  Stop"
StopBtn2.TextColor3=C.White; StopBtn2.Font=FontSemi; StopBtn2.TextSize=12
StopBtn2.BorderSizePixel=0
Instance.new("UICorner",StopBtn2).CornerRadius=UDim.new(0,6)
local SBStroke=Instance.new("UIStroke",StopBtn2); SBStroke.Color=C.Border; SBStroke.Thickness=1

-- Status bar at very bottom
local StatusBar = Instance.new("Frame", RightPanel)
StatusBar.Size=UDim2.new(1,-16,0,22); StatusBar.Position=UDim2.new(0,8,0,296)
StatusBar.BackgroundTransparency=1

local StatusLbl = Instance.new("TextLabel", StatusBar)
StatusLbl.Size=UDim2.new(1,0,1,0); StatusLbl.BackgroundTransparency=1
StatusLbl.Text="Status: Idle"; StatusLbl.TextColor3=C.Grey
StatusLbl.Font=Font; StatusLbl.TextSize=10
StatusLbl.TextXAlignment=Enum.TextXAlignment.Left

local function setStatus(txt, col)
    StatusLbl.Text="Status: "..txt; StatusLbl.TextColor3=col or C.Grey
end

-- ══════════════════════════════════════════
-- // RECORD MINI-PANEL (bottom overlay)
-- ══════════════════════════════════════════
local RecPanel = Instance.new("Frame", ScreenGui)
RecPanel.Name="RecPanel"
RecPanel.Size=UDim2.new(0,320,0,48)
RecPanel.Position=UDim2.new(0.5,-160,1,-60)
RecPanel.BackgroundColor3=C.Surface
RecPanel.BorderSizePixel=0
Instance.new("UICorner",RecPanel).CornerRadius=UDim.new(0,8)
local RPS=Instance.new("UIStroke",RecPanel); RPS.Color=C.Border; RPS.Thickness=1

local RecLayout=Instance.new("UIListLayout",RecPanel)
RecLayout.FillDirection=Enum.FillDirection.Horizontal
RecLayout.Padding=UDim.new(0,6)
RecLayout.VerticalAlignment=Enum.VerticalAlignment.Center
RecLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
local RecPad=Instance.new("UIPadding",RecPanel)
RecPad.PaddingLeft=UDim.new(0,10); RecPad.PaddingRight=UDim.new(0,10)

local function makeRecBtn(txt, w, col, cb)
    local b=Instance.new("TextButton",RecPanel)
    b.Size=UDim2.new(0,w,0,30); b.BackgroundColor3=col or C.Surface2
    b.Text=txt; b.TextColor3=C.White; b.Font=FontSemi; b.TextSize=11
    b.BorderSizePixel=0; b.AutoButtonColor=false
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    if col==nil then
        local s=Instance.new("UIStroke",b); s.Color=C.Border; s.Thickness=1
    end
    b.MouseButton1Click:Connect(cb)
    return b
end

local RecStatusLbl=Instance.new("TextLabel",RecPanel)
RecStatusLbl.Size=UDim2.new(0,80,0,30); RecStatusLbl.BackgroundTransparency=1
RecStatusLbl.Text="● Idle"; RecStatusLbl.TextColor3=C.Grey
RecStatusLbl.Font=FontSemi; RecStatusLbl.TextSize=11

local function setRecStatus(txt,col)
    RecStatusLbl.Text=txt; RecStatusLbl.TextColor3=col or C.Grey
end

-- ══════════════════════════════════════════
-- // SAVE DIALOG (name the macro before saving)
-- ══════════════════════════════════════════
local SaveDialog=Instance.new("Frame",ScreenGui)
SaveDialog.Name="SaveDialog"
SaveDialog.Size=UDim2.new(0,300,0,130)
SaveDialog.Position=UDim2.new(0.5,-150,0.5,-65)
SaveDialog.BackgroundColor3=C.Surface
SaveDialog.BorderSizePixel=0; SaveDialog.Visible=false
Instance.new("UICorner",SaveDialog).CornerRadius=UDim.new(0,8)
local SDStroke=Instance.new("UIStroke",SaveDialog); SDStroke.Color=C.Border; SDStroke.Thickness=1

local SDTitle=Instance.new("TextLabel",SaveDialog)
SDTitle.Size=UDim2.new(1,0,0,34); SDTitle.BackgroundColor3=C.Surface2
SDTitle.BorderSizePixel=0; SDTitle.Text="Save Macro As..."
SDTitle.TextColor3=C.White; SDTitle.Font=FontBold; SDTitle.TextSize=12
Instance.new("UICorner",SDTitle).CornerRadius=UDim.new(0,8)
local SDTFix=Instance.new("Frame",SDTitle)
SDTFix.Size=UDim2.new(1,0,0,8); SDTFix.Position=UDim2.new(0,0,1,-8)
SDTFix.BackgroundColor3=C.Surface2; SDTFix.BorderSizePixel=0

local SDInput=Instance.new("TextBox",SaveDialog)
SDInput.Size=UDim2.new(1,-24,0,30); SDInput.Position=UDim2.new(0,12,0,44)
SDInput.BackgroundColor3=C.BG; SDInput.Text=""; SDInput.PlaceholderText="Macro name..."
SDInput.PlaceholderColor3=C.DimGrey; SDInput.TextColor3=C.White
SDInput.Font=Font; SDInput.TextSize=12; SDInput.BorderSizePixel=0
Instance.new("UICorner",SDInput).CornerRadius=UDim.new(0,6)
local SDIStroke=Instance.new("UIStroke",SDInput); SDIStroke.Color=C.Border; SDIStroke.Thickness=1
local SDIPad=Instance.new("UIPadding",SDInput); SDIPad.PaddingLeft=UDim.new(0,8)

local SDCancel=Instance.new("TextButton",SaveDialog)
SDCancel.Size=UDim2.new(0.44,0,0,30); SDCancel.Position=UDim2.new(0,12,0,84)
SDCancel.BackgroundColor3=C.Surface2; SDCancel.Text="Cancel"
SDCancel.TextColor3=C.Grey; SDCancel.Font=FontSemi; SDCancel.TextSize=11
SDCancel.BorderSizePixel=0
Instance.new("UICorner",SDCancel).CornerRadius=UDim.new(0,6)
SDCancel.MouseButton1Click:Connect(function() SaveDialog.Visible=false end)

local SDSave=Instance.new("TextButton",SaveDialog)
SDSave.Size=UDim2.new(0.44,0,0,30); SDSave.Position=UDim2.new(0.56,-12,0,84)
SDSave.BackgroundColor3=C.White; SDSave.Text="Save"
SDSave.TextColor3=C.BG; SDSave.Font=FontBold; SDSave.TextSize=11
SDSave.BorderSizePixel=0
Instance.new("UICorner",SDSave).CornerRadius=UDim.new(0,6)

-- ══════════════════════════════════════════
-- // CARD SYSTEM
-- ══════════════════════════════════════════
local function refreshRightPanel()
    if not SelectedCard then
        InfoContent.Text="Select a macro from the list\nto view its details."
        DetailContent.Text="• Actions: —\n• Status: —\n• Author: BorcaHub"
        return
    end
    local card=MacroLibrary[SelectedCard]
    if not card then return end
    InfoContent.Text=card.name.."\n\n"..card.description
    DetailContent.Text="• Actions: "..#card.actions.."\n• Loop: "..(Macro.Looping and "On" or "Off").."\n• Author: BorcaHub"
end

local function deselectAll()
    for _, child in ipairs(CardList:GetChildren()) do
        if child:IsA("Frame") and child:FindFirstChild("CardBtn") then
            tw(child, {BackgroundColor3=C.Surface})
            local s=child:FindFirstChildOfClass("UIStroke")
            if s then tw(s,{Color=C.Border}) end
        end
    end
end

local function rebuildCards()
    for _, c in ipairs(CardList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    for i, entry in ipairs(MacroLibrary) do
        local Card=Instance.new("Frame",CardList)
        Card.Name="Card"..i; Card.Size=UDim2.new(1,0,0,62)
        Card.BackgroundColor3=C.Surface; Card.BorderSizePixel=0
        Card.LayoutOrder=i
        local CStroke=Instance.new("UIStroke",Card); CStroke.Color=C.Border; CStroke.Thickness=1

        local CName=Instance.new("TextLabel",Card)
        CName.Size=UDim2.new(1,-12,0,20); CName.Position=UDim2.new(0,10,0,10)
        CName.BackgroundTransparency=1; CName.Text=entry.name
        CName.TextColor3=C.White; CName.Font=FontSemi; CName.TextSize=12
        CName.TextXAlignment=Enum.TextXAlignment.Left

        local CDesc=Instance.new("TextLabel",Card)
        CDesc.Size=UDim2.new(1,-12,0,26); CDesc.Position=UDim2.new(0,10,0,28)
        CDesc.BackgroundTransparency=1; CDesc.Text=entry.description
        CDesc.TextColor3=C.Grey; CDesc.Font=Font; CDesc.TextSize=10
        CDesc.TextXAlignment=Enum.TextXAlignment.Left; CDesc.TextWrapped=true

        -- Delete btn
        local DelBtn=Instance.new("TextButton",Card)
        DelBtn.Size=UDim2.new(0,18,0,18); DelBtn.Position=UDim2.new(1,-24,0,6)
        DelBtn.BackgroundColor3=C.DimGrey; DelBtn.Text="✕"
        DelBtn.TextColor3=C.Grey; DelBtn.Font=FontBold; DelBtn.TextSize=9
        DelBtn.BorderSizePixel=0
        Instance.new("UICorner",DelBtn).CornerRadius=UDim.new(0,4)
        DelBtn.MouseButton1Click:Connect(function()
            table.remove(MacroLibrary,i)
            if SelectedCard==i then SelectedCard=nil end
            rebuildCards(); refreshRightPanel()
        end)

        -- Click to select
        local CardBtn=Instance.new("TextButton",Card)
        CardBtn.Name="CardBtn"; CardBtn.Size=UDim2.new(1,0,1,0)
        CardBtn.BackgroundTransparency=1; CardBtn.Text=""; CardBtn.ZIndex=2
        CardBtn.MouseButton1Click:Connect(function()
            deselectAll()
            SelectedCard=i
            tw(Card,{BackgroundColor3=C.Selected})
            tw(CStroke,{Color=C.SelBorder})
            refreshRightPanel()
        end)

        -- Highlight if selected
        if SelectedCard==i then
            Card.BackgroundColor3=C.Selected
            CStroke.Color=C.SelBorder
        end
    end
end

-- ══════════════════════════════════════════
-- // CORE MACRO FUNCTIONS
-- ══════════════════════════════════════════
local function startRecording()
    if Macro.Recording then return end
    Macro.Actions={}; Macro.Recording=true; Macro.StartTime=tick()
    if Macro.Connection then Macro.Connection:Disconnect() end
    Macro.Connection=UserInputService.InputBegan:Connect(function(input)
        if not Macro.Recording then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            table.insert(Macro.Actions,{type="click",time=tick()-Macro.StartTime,x=Mouse.X,y=Mouse.Y})
        elseif input.UserInputType==Enum.UserInputType.MouseButton2 then
            table.insert(Macro.Actions,{type="rclick",time=tick()-Macro.StartTime,x=Mouse.X,y=Mouse.Y})
        elseif input.KeyCode~=Enum.KeyCode.Unknown then
            table.insert(Macro.Actions,{type="key",time=tick()-Macro.StartTime,keyCode=input.KeyCode})
        end
    end)
    setRecStatus("● REC", C.Red)
    setStatus("Recording...", C.Red)
end

local function stopRecording()
    if not Macro.Recording then return end
    Macro.Recording=false
    if Macro.Connection then Macro.Connection:Disconnect(); Macro.Connection=nil end
    setRecStatus("● Idle", C.Grey)
    setStatus("Stopped — "..#Macro.Actions.." actions", C.Grey)
    -- Auto prompt save dialog
    if #Macro.Actions > 0 then
        SDInput.Text=""
        SaveDialog.Visible=true
    end
end

local function playActions(actions)
    local startT=tick()
    for _,action in ipairs(actions) do
        if not Macro.Playing then break end
        local waitT=action.time-(tick()-startT)
        if waitT>0 then task.wait(waitT) end
        if not Macro.Playing then break end
        if action.type=="click" then
            pcall(function()
                VirtualInput:SendMouseButtonEvent(action.x,action.y,0,true,game,1)
                task.wait(0.05)
                VirtualInput:SendMouseButtonEvent(action.x,action.y,0,false,game,1)
            end)
        elseif action.type=="rclick" then
            pcall(function()
                VirtualInput:SendMouseButtonEvent(action.x,action.y,1,true,game,1)
                task.wait(0.05)
                VirtualInput:SendMouseButtonEvent(action.x,action.y,1,false,game,1)
            end)
        elseif action.type=="key" then
            pcall(function()
                VirtualInput:SendKeyEvent(true,action.keyCode,false,game)
                task.wait(0.05)
                VirtualInput:SendKeyEvent(false,action.keyCode,false,game)
            end)
        end
    end
end

local function stopMacro()
    Macro.Playing=false
    if Macro.PlayThread then task.cancel(Macro.PlayThread); Macro.PlayThread=nil end
    setStatus("Stopped", C.Grey)
end

-- ══════════════════════════════════════════
-- // BUTTON CALLBACKS
-- ══════════════════════════════════════════

-- Execute selected card
ExecBtn.MouseButton1Click:Connect(function()
    if not SelectedCard then setStatus("No macro selected!", C.Red); return end
    local card=MacroLibrary[SelectedCard]
    if not card then setStatus("Macro not found!", C.Red); return end
    if Macro.Playing then stopMacro(); task.wait(0.1) end
    Macro.Playing=true
    setStatus("▶ Playing: "..card.name, C.Green)
    Macro.PlayThread=task.spawn(function()
        repeat
            playActions(card.actions)
            if Macro.Looping and Macro.Playing then task.wait(0.5) end
        until not Macro.Looping or not Macro.Playing
        Macro.Playing=false
        setStatus("Done ✓", C.Grey)
    end)
end)

-- Stop
StopBtn2.MouseButton1Click:Connect(function() stopMacro() end)

-- Save dialog confirm
SDSave.MouseButton1Click:Connect(function()
    local name=SDInput.Text
    if name=="" then name="Macro #"..tostring(#MacroLibrary+1) end
    local actionsCopy={}
    for _,a in ipairs(Macro.Actions) do table.insert(actionsCopy,a) end
    table.insert(MacroLibrary,{
        name=name,
        description=#actionsCopy.." actions recorded",
        actions=actionsCopy,
    })
    SaveDialog.Visible=false
    rebuildCards()
    SelectedCard=#MacroLibrary
    refreshRightPanel()
    setStatus("Saved: "..name, C.Green)
end)

-- ══════════════════════════════════════════
-- // TOOLBAR BUTTONS (bottom of left panel)
-- ══════════════════════════════════════════
local ToolBar=Instance.new("Frame",LeftPanel)
ToolBar.Size=UDim2.new(1,0,0,32); ToolBar.Position=UDim2.new(0,0,1,-32)
ToolBar.BackgroundColor3=C.Surface2; ToolBar.BorderSizePixel=0

local TBDiv=Instance.new("Frame",LeftPanel)
TBDiv.Size=UDim2.new(1,0,0,1); TBDiv.Position=UDim2.new(0,0,1,-33)
TBDiv.BackgroundColor3=C.Border; TBDiv.BorderSizePixel=0

local TBLayout=Instance.new("UIListLayout",ToolBar)
TBLayout.FillDirection=Enum.FillDirection.Horizontal
TBLayout.VerticalAlignment=Enum.VerticalAlignment.Center
TBLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center
TBLayout.Padding=UDim.new(0,4)

local function makeTB(txt, cb)
    local b=Instance.new("TextButton",ToolBar)
    b.Size=UDim2.new(0,54,0,22); b.BackgroundColor3=C.DimGrey
    b.Text=txt; b.TextColor3=C.White; b.Font=Font; b.TextSize=9
    b.BorderSizePixel=0; b.AutoButtonColor=false
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
    b.MouseEnter:Connect(function() tw(b,{BackgroundColor3=Color3.fromRGB(75,75,75)}) end)
    b.MouseLeave:Connect(function() tw(b,{BackgroundColor3=C.DimGrey}) end)
    b.MouseButton1Click:Connect(cb)
    return b
end

makeTB("⏺ Record", function()
    Win.Visible=false
    startRecording()
end)
makeTB("📥 Import", function()
    IDNameInput.Text=""; IDCodeInput.Text=""
    ImportDialog.Visible=true
end)

-- Resize card scroll to fit above toolbar
CardScroll.Size=UDim2.new(1,0,1,-63)

-- ══════════════════════════════════════════
-- // REC PANEL BUTTONS
-- ══════════════════════════════════════════
makeRecBtn("⏹ Stop & Save", 110, nil, function()
    stopRecording()
end)
makeRecBtn("🗑 Discard", 80, nil, function()
    if Macro.Connection then Macro.Connection:Disconnect(); Macro.Connection=nil end
    Macro.Recording=false; Macro.Actions={}
    setRecStatus("● Idle", C.Grey)
    setStatus("Discarded", C.Grey)
end)

-- ══════════════════════════════════════════
-- // MAP CHANGE AUTO RESUME
-- ══════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(char)
    local wasPlay=Macro.Playing
    if Macro.Recording then
        if Macro.Connection then Macro.Connection:Disconnect(); Macro.Connection=nil end
        Macro.Recording=false; setRecStatus("● Idle",C.Grey)
    end
    if wasPlay then stopMacro() end
    char:WaitForChild("HumanoidRootPart",10)
    task.wait(2)
    if Macro.AutoResumePlay and wasPlay and SelectedCard then
        local card=MacroLibrary[SelectedCard]
        if card then
            Macro.Playing=true
            setStatus("▶ Auto-resumed: "..card.name, C.Green)
            Macro.PlayThread=task.spawn(function()
                repeat
                    playActions(card.actions)
                    if Macro.Looping and Macro.Playing then task.wait(0.5) end
                until not Macro.Looping or not Macro.Playing
                Macro.Playing=false; setStatus("Done ✓",C.Grey)
            end)
        end
    else
        setStatus("Map changed — stopped",C.Grey)
    end
end)

-- ══════════════════════════════════════════
-- // LOOP TOGGLE (right click Execute = toggle loop)
-- ══════════════════════════════════════════
ExecBtn.MouseButton2Click:Connect(function()
    Macro.Looping=not Macro.Looping
    ExecBtn.Text=Macro.Looping and "🔁 Execute" or "▶  Execute"
    setStatus("Loop: "..(Macro.Looping and "ON" or "OFF"), C.Grey)
    refreshRightPanel()
end)

-- ══════════════════════════════════════════
-- // AUTO RESUME TOGGLE (right click Stop)
-- ══════════════════════════════════════════
StopBtn2.MouseButton2Click:Connect(function()
    Macro.AutoResumePlay=not Macro.AutoResumePlay
    StopBtn2.Text=Macro.AutoResumePlay and "🔄 Auto" or "⏸  Stop"
    setStatus("Auto Resume: "..(Macro.AutoResumePlay and "ON" or "OFF"), C.Grey)
end)

-- ══════════════════════════════════════════
-- // INSERT = toggle main window
-- ══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode==Enum.KeyCode.Insert then
        Win.Visible=not Win.Visible
    end
end)

-- ══════════════════════════════════════════
-- // INIT
-- ══════════════════════════════════════════
rebuildCards()
refreshRightPanel()
setStatus("Idle", C.Grey)
print("[BorcaHub] TDS Macro Hub loaded!")
print("[BorcaHub] INSERT = open/close | Right-click Execute = toggle loop | Right-click Stop = toggle auto-resume")
