--===================================================================
-- BAGIAN 1: INITIALIZATION & THEME
--===================================================================
local Players = game:GetService("Players")
local TweetService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BorcaTheme = {
	Background = Color3.fromRGB(11, 19, 36),
	SecondaryBg = Color3.fromRGB(7, 12, 24),
	GlowBorder = Color3.fromRGB(0, 162, 255),
	AccentCyan = Color3.fromRGB(0, 225, 255),
	TextMain = Color3.fromRGB(255, 255, 255),
	TextDark = Color3.fromRGB(140, 160, 190),
	ButtonRed = Color3.fromRGB(231, 76, 60),
	ButtonGreen = Color3.fromRGB(46, 204, 113)
}

local BorcaHub = {}
BorcaHub.__index = BorcaHub

function BorcaHub.Init()
	local self = setmetatable({}, BorcaHub)
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "BorcaHub_CoreEngine"
	self.ScreenGui.ResetOnSpawn = false
	self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	local success, _ = pcall(function() self.ScreenGui.Parent = CoreGui end)
	if not success then self.ScreenGui.Parent = PlayerGui end
	
	self.Tabs = {}
	self.CurrentTab = nil
	self:BuildMainDashboard()
	self:ApplyDragLogic()
	return self
end
--===================================================================
-- BAGIAN 2: DASHBOARD & TAB SYSTEM
--===================================================================
function BorcaHub:BuildMainDashboard()
	self.MainFrame = Instance.new("Frame")
	self.MainFrame.Name = "MainFrame"
	self.MainFrame.Size = UDim2.new(0, 800, 0, 500)
	self.MainFrame.Position = UDim2.new(0.5, -400, 0.5, -250)
	self.MainFrame.BackgroundColor3 = BorcaTheme.Background
	self.MainFrame.Active = true
	self.MainFrame.ClipsDescendants = true
	self.MainFrame.Parent = self.ScreenGui
	
	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0, 12)
	mainCorner.Parent = self.MainFrame
	
	self.Stroke = Instance.new("UIStroke")
	self.Stroke.Thickness = 2.5
	self.Stroke.Color = BorcaTheme.GlowBorder
	self.Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	self.Stroke.Parent = self.MainFrame
	
	self.Header = Instance.new("Frame")
	self.Header.Size = UDim2.new(1, 0, 0, 50)
	self.Header.BackgroundTransparency = 1
	self.Header.Parent = self.MainFrame
	
	self.Title = Instance.new("TextLabel")
	self.Title.Size = UDim2.new(0, 200, 1, 0)
	self.Title.Position = UDim2.new(0, 20, 0, 0)
	self.Title.BackgroundTransparency = 1
	self.Title.Text = "BORCA HUB"
	self.Title.TextColor3 = BorcaTheme.AccentCyan
	self.Title.TextSize = 24
	self.Title.Font = Enum.Font.SourceSansBold
	self.Title.TextXAlignment = Enum.TextXAlignment.Left
	self.Title.Parent = self.Header
	
	self.CloseButton = Instance.new("TextButton")
	self.CloseButton.Size = UDim2.new(0, 32, 0, 32)
	self.CloseButton.Position = UDim2.new(1, -45, 0.5, -16)
	self.CloseButton.BackgroundColor3 = BorcaTheme.SecondaryBg
	self.CloseButton.Text = "×"
	self.CloseButton.TextColor3 = BorcaTheme.TextMain
	self.CloseButton.TextSize = 24
	self.CloseButton.Font = Enum.Font.SourceSansBold
	self.CloseButton.Parent = self.Header
	
	self.CloseButton.MouseEnter:Connect(function()
		TweetService:Create(self.CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = BorcaTheme.ButtonRed}):Play()
	end)
	self.CloseButton.MouseLeave:Connect(function()
		TweetService:Create(self.CloseButton, TweenInfo.new(0.2), {BackgroundColor3 = BorcaTheme.SecondaryBg}):Play()
	end)
	self.CloseButton.MouseButton1Click:Connect(function() self:DestroyUI() end)
	
	self:BuildLeftSidebar()
	self:BuildRightContainer()
end

function BorcaHub:BuildLeftSidebar()
	self.LeftSidebar = Instance.new("Frame")
	self.LeftSidebar.Size = UDim2.new(0, 260, 0, 430)
	self.LeftSidebar.Position = UDim2.new(0, 15, 0, 55)
	self.LeftSidebar.BackgroundColor3 = BorcaTheme.SecondaryBg
	self.LeftSidebar.Parent = self.MainFrame
	
	local sideCorner = Instance.new("UICorner")
	sideCorner.CornerRadius = UDim.new(0, 8)
	sideCorner.Parent = self.LeftSidebar
	
	local infoPanel = Instance.new("Frame")
	infoPanel.Size = UDim2.new(1, -20, 0, 130)
	infoPanel.Position = UDim2.new(0, 10, 0, 10)
	infoPanel.BackgroundTransparency = 1
	infoPanel.Parent = self.LeftSidebar
	
	local infoDetails = Instance.new("TextLabel")
	infoDetails.Size = UDim2.new(1, 0, 1, 0)
	infoDetails.BackgroundTransparency = 1
	infoDetails.Text = string.format("• User: %s\n• Rank: Premium\n• Ping: Calc...", LocalPlayer.Name)
	infoDetails.TextColor3 = BorcaTheme.TextDark
	infoDetails.TextSize = 14
	infoDetails.Font = Enum.Font.Code
	infoDetails.TextXAlignment = Enum.TextXAlignment.Left
	infoDetails.Parent = infoPanel
	
	task.spawn(function()
		while task.wait(2) and self.ScreenGui do
			local ping = tonumber(string.format("%.0f", LocalPlayer:GetNetworkPing() * 1000))
			infoDetails.Text = string.format("• User: %s\n• Rank: Premium\n• Ping: %d ms", LocalPlayer.Name, ping)
		end
	end)

	self.TabScroll = Instance.new("ScrollingFrame")
	self.TabScroll.Size = UDim2.new(1, -20, 0, 260)
	self.TabScroll.Position = UDim2.new(0, 10, 0, 150)
	self.TabScroll.BackgroundTransparency = 1
	self.TabScroll.ScrollBarThickness = 2
	self.TabScroll.Parent = self.LeftSidebar
	
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.Parent = self.TabScroll
end

function BorcaHub:BuildRightContainer()
	self.RightContainer = Instance.new("Frame")
	self.RightContainer.Size = UDim2.new(0, 500, 0, 430)
	self.RightContainer.Position = UDim2.new(0, 285, 0, 55)
	self.RightContainer.BackgroundColor3 = BorcaTheme.SecondaryBg
	self.RightContainer.Parent = self.MainFrame
	
	local rightCorner = Instance.new("UICorner")
	rightCorner.CornerRadius = UDim.new(0, 8)
	rightCorner.Parent = self.RightContainer
end
--===================================================================
-- BAGIAN 3: CREATION MODULES & EXECUTIONS
--===================================================================
function BorcaHub:CreateTab(tabName)
	local tabObj = {}
	tabObj.Button = Instance.new("TextButton")
	tabObj.Button.Size = UDim2.new(1, 0, 0, 38)
	tabObj.Button.BackgroundColor3 = BorcaTheme.Background
	tabObj.Button.Text = "  " .. tabName
	tabObj.Button.TextColor3 = BorcaTheme.TextDark
	tabObj.Button.TextSize = 14
	tabObj.Button.Font = Enum.Font.SourceSansBold
	tabObj.Button.TextXAlignment = Enum.TextXAlignment.Left
	tabObj.Button.Parent = self.TabScroll
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = tabObj.Button
	
	tabObj.Page = Instance.new("ScrollingFrame")
	tabObj.Page.Size = UDim2.new(1, -20, 1, -20)
	tabObj.Page.Position = UDim2.new(0, 10, 0, 10)
	tabObj.Page.BackgroundTransparency = 1
	tabObj.Page.Visible = false
	tabObj.Page.ScrollBarThickness = 4
	tabObj.Page.Parent = self.RightContainer
	
	local pageLayout = Instance.new("UIListLayout")
	pageLayout.Padding = UDim.new(0, 10)
	pageLayout.Parent = tabObj.Page
	
	tabObj.Button.MouseButton1Click:Connect(function()
		for _, otherTab in pairs(self.Tabs) do
			otherTab.Page.Visible = false
			otherTab.Button.TextColor3 = BorcaTheme.TextDark
			TweetService:Create(otherTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = BorcaTheme.Background}):Play()
		end
		tabObj.Page.Visible = true
		tabObj.Button.TextColor3 = BorcaTheme.AccentCyan
		TweetService:Create(tabObj.Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(16, 32, 64)}):Play()
	end)
	
	table.insert(self.Tabs, tabObj)
	if #self.Tabs == 1 then
		tabObj.Page.Visible = true
		tabObj.Button.TextColor3 = BorcaTheme.AccentCyan
		tabObj.Button.BackgroundColor3 = Color3.fromRGB(16, 32, 64)
	end
	
	local elements = {}
	function elements:AddButton(title, description, callback)
		local btnFrame = Instance.new("Frame")
		btnFrame.Size = UDim2.new(1, -5, 0, 65)
		btnFrame.BackgroundColor3 = BorcaTheme.Background
		btnFrame.Parent = tabObj.Page
		
		local frameCorner = Instance.new("UICorner")
		frameCorner.CornerRadius = UDim.new(0, 6)
		frameCorner.Parent = btnFrame
		
		local textTitle = Instance.new("TextLabel")
		textTitle.Size = UDim2.new(0.6, 0, 0, 25)
		textTitle.Position = UDim2.new(0, 15, 0, 10)
		textTitle.BackgroundTransparency = 1
		textTitle.Text = title
		textTitle.TextColor3 = BorcaTheme.TextMain
		textTitle.TextSize = 16
		textTitle.Font = Enum.Font.SourceSansBold
		textTitle.TextXAlignment = Enum.TextXAlignment.Left
		textTitle.Parent = btnFrame
		
		local textDesc = Instance.new("TextLabel")
		textDesc.Size = UDim2.new(0.6, 0, 0, 20)
		textDesc.Position = UDim2.new(0, 15, 0, 32)
		textDesc.BackgroundTransparency = 1
		textDesc.Text = description
		textDesc.TextColor3 = BorcaTheme.TextDark
		textDesc.TextXAlignment = Enum.TextXAlignment.Left
		textDesc.Parent = btnFrame
		
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0, 110, 0, 36)
		actionBtn.Position = UDim2.new(1, -125, 0.5, -18)
		actionBtn.BackgroundColor3 = Color3.fromRGB(20, 40, 80)
		actionBtn.Text = "Execute"
		actionBtn.TextColor3 = BorcaTheme.AccentCyan
		actionBtn.Font = Enum.Font.SourceSansBold
		actionBtn.Parent = btnFrame
		
		local actCorner = Instance.new("UICorner")
		actCorner.CornerRadius = UDim.new(0, 6)
		actCorner.Parent = actionBtn
		
		actionBtn.MouseEnter:Connect(function()
			TweetService:Create(actionBtn, TweenInfo.new(0.2), {BackgroundColor3 = BorcaTheme.ButtonGreen, TextColor3 = Color3.fromRGB(255,255,255)}):Play()
		end)
		actionBtn.MouseLeave:Connect(function()
			TweetService:Create(actionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 40, 80), TextColor3 = BorcaTheme.AccentCyan}):Play()
		end)
		actionBtn.MouseButton1Click:Connect(function() pcall(callback) end)
	end
	return elements
end

function BorcaHub:ApplyDragLogic()
	local dragging, dragInput, dragStart, startPos
	self.Header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.MainFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	self.Header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			TweetService:Create(self.MainFrame, TweenInfo.new(0.08), {Position = targetPos}):Play()
		end
	end)
end

function BorcaHub:DestroyUI()
	if self.ScreenGui then self.ScreenGui:Destroy() end
end

-- ==================================================================
-- MENJALANKAN BORCA HUB & MEMBUAT TOMBOL CONTOH
-- ==================================================================
local MyBorcaHub = BorcaHub.Init()
local MainTab = MyBorcaHub:CreateTab("Main Cheats")
local PlayerTab = MyBorcaHub:CreateTab("Player Settings")

MainTab:AddButton("Auto Farm Money", "Otomatis mengumpulkan koin terdekat", function()
	print("Auto Farm Aktif!")
end)

PlayerTab:AddButton("Super Speed", "Mengubah kecepatan lari menjadi 150", function()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("Humanoid") then char.Humanoid.WalkSpeed = 150 end
end)
