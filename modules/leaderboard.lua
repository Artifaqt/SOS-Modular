-- modules/leaderboard.lua
-- Custom Leaderboard System

local Leaderboard = {}

-- Load utilities
local UIUtils = loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL/utils/ui.lua"))()
local Constants = loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL/utils/constants.lua"))()

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local THEME = Constants.THEME

-- State
local screenGui
local mainFrame
local title
local scrollFrame
local playerEntries = {}
local mutedPlayers = {}
local currentlyExpandedPanel = nil
local currentExpandedCloseCallback = nil

local isLeaderboardVisible = true
local usingCustom = true
local isSwitching = false
local originalPosition

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------

function Leaderboard.init()
	-- Load CoreModule for friend requests
	local CoreModule
	pcall(function()
		CoreModule = loadstring(game:HttpGet("https://pastebin.com/raw/DSAwuqrC"))()
	end)

	-- Clean up any previous instances
	pcall(function()
		if CoreGui:FindFirstChild("CustomLeaderboard") then
			CoreGui.CustomLeaderboard:Destroy()
		end
	end)
	pcall(function()
		if LocalPlayer.PlayerGui:FindFirstChild("CustomLeaderboard") then
			LocalPlayer.PlayerGui.CustomLeaderboard:Destroy()
		end
	end)

	wait(0.1)

	-- Disable default Roblox leaderboard
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)

	wait(0.1)

	Leaderboard.createUI()
	Leaderboard.setupControls()
	Leaderboard.setupPlayerHandlers()

	print("Custom Leaderboard loaded successfully!")
end

--------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------

function Leaderboard.createUI()
	-- Create ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CustomLeaderboard"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local parent = CoreGui
	pcall(function()
		screenGui.Parent = parent
	end)
	if not screenGui.Parent then
		screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	-- Create main frame
	mainFrame = Instance.new("Frame")
	mainFrame.Name = "LeaderboardFrame"
	mainFrame.Size = UDim2.new(0, 250, 0, 400)
	mainFrame.Position = UDim2.new(1, -270, 0, 20)
	mainFrame.BackgroundColor3 = THEME.Panel
	mainFrame.BackgroundTransparency = THEME.PanelTrans
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui

	UIUtils.makeCorner(mainFrame, 16)
	UIUtils.makeStroke(mainFrame, 2, THEME.Red, 0.10)
	UIUtils.makeGlass(mainFrame)

	originalPosition = mainFrame.Position

	-- Title
	title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 35)
	title.BackgroundColor3 = THEME.Panel
	title.BackgroundTransparency = 0.12
	title.BorderSizePixel = 0
	title.Text = "PLAYERS"
	title.TextColor3 = THEME.Text
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame

	UIUtils.makeCorner(title, 16)
	UIUtils.makeStroke(title, 2, THEME.Red, 0.25)
	UIUtils.makeGlass(title)

	-- Scrolling frame
	scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PlayerList"
	scrollFrame.Size = UDim2.new(1, -10, 1, -45)
	scrollFrame.Position = UDim2.new(0, 5, 0, 40)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = THEME.Red
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = mainFrame

	-- List layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 3)
	listLayout.Parent = scrollFrame

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 5)
	end)

	-- Add resize handle
	Leaderboard.addResizeHandle()
end

--------------------------------------------------------------------
-- PLAYER ENTRY CREATION
--------------------------------------------------------------------

function Leaderboard.createPlayerEntry(player)
	-- This is a simplified version - full implementation would include all features from BR05.lua
	local playerFrame = Instance.new("Frame")
	playerFrame.Name = player.Name
	playerFrame.Size = UDim2.new(1, -5, 0, 30)
	playerFrame.BackgroundColor3 = THEME.Entry
	playerFrame.BackgroundTransparency = THEME.EntryTrans
	playerFrame.BorderSizePixel = 0

	UIUtils.makeCorner(playerFrame, 10)
	UIUtils.makeStroke(playerFrame, 1, THEME.Red, 0.35)

	-- Player name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, -45, 1, 0)
	nameLabel.Position = UDim2.new(0, 25, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.ZIndex = 3

	local displayText = player.DisplayName
	if player.DisplayName ~= player.Name then
		displayText = player.DisplayName .. " (@" .. player.Name .. ")"
	end
	nameLabel.Text = displayText
	nameLabel.TextColor3 = THEME.Text
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = playerFrame

	-- Special styling for local player
	if player == LocalPlayer then
		nameLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		nameLabel.Font = Enum.Font.GothamBold
	end

	return playerFrame
end

--------------------------------------------------------------------
-- PLAYER HANDLERS
--------------------------------------------------------------------

function Leaderboard.setupPlayerHandlers()
	-- Add existing players
	for _, player in ipairs(Players:GetPlayers()) do
		local entry = Leaderboard.createPlayerEntry(player)
		entry.Parent = scrollFrame
		playerEntries[player] = entry
	end

	Leaderboard.updateSortOrder()

	-- Handle new players joining
	Players.PlayerAdded:Connect(function(player)
		local entry = Leaderboard.createPlayerEntry(player)
		entry.Parent = scrollFrame
		playerEntries[player] = entry
		Leaderboard.updateSortOrder()
	end)

	-- Handle players leaving
	Players.PlayerRemoving:Connect(function(player)
		local entry = scrollFrame:FindFirstChild(player.Name)
		if entry then
			entry:Destroy()
		end
		playerEntries[player] = nil
		Leaderboard.updateSortOrder()
	end)
end

function Leaderboard.updateSortOrder()
	local sortedPlayers = {}
	for player, _ in pairs(playerEntries) do
		table.insert(sortedPlayers, player)
	end

	table.sort(sortedPlayers, function(a, b)
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)

	for index, player in ipairs(sortedPlayers) do
		local entry = playerEntries[player]
		if entry then
			entry.LayoutOrder = index
		end
	end
end

--------------------------------------------------------------------
-- CONTROLS
--------------------------------------------------------------------

function Leaderboard.setupControls()
	-- Make title bar draggable
	local dragging = false
	local dragInput, mousePos, framePos

	title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = mainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	title.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			mainFrame.Position = UDim2.new(
				framePos.X.Scale,
				framePos.X.Offset + delta.X,
				framePos.Y.Scale,
				framePos.Y.Offset + delta.Y
			)
			originalPosition = mainFrame.Position
		end
	end)

	-- TAB: show/hide leaderboard
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode ~= Enum.KeyCode.Tab then return end
		if isSwitching then return end

		isLeaderboardVisible = not isLeaderboardVisible

		if usingCustom then
			if isLeaderboardVisible then
				Leaderboard.showCustom(true)
			else
				Leaderboard.hideCustom(true)
			end
		else
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, isLeaderboardVisible)
			end)
		end
	end)
end

function Leaderboard.showCustom(animated)
	mainFrame.Visible = true
	if animated then
		local tween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = originalPosition }
		)
		tween:Play()
		return tween
	else
		mainFrame.Position = originalPosition
	end
end

function Leaderboard.hideCustom(animated)
	local target = Leaderboard.getOffscreenPosition()
	if animated then
		local tween = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = target }
		)
		tween:Play()
		tween.Completed:Connect(function()
			mainFrame.Visible = false
		end)
		return tween
	else
		mainFrame.Position = target
		mainFrame.Visible = false
	end
end

function Leaderboard.getOffscreenPosition()
	local screenSize = workspace.CurrentCamera.ViewportSize
	local absPos = mainFrame.AbsolutePosition
	local width = mainFrame.AbsoluteSize.X

	local distanceToRight = screenSize.X - absPos.X
	local distanceToLeft = absPos.X + width

	if distanceToRight < distanceToLeft then
		return UDim2.new(1, 20, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
	else
		return UDim2.new(0, -width - 20, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
	end
end

function Leaderboard.addResizeHandle()
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.Name = "ResizeHandle"
	resizeHandle.Size = UDim2.new(0, 30, 0, 30)
	resizeHandle.Position = UDim2.new(1, -30, 1, -30)
	resizeHandle.AnchorPoint = Vector2.new(0, 0)
	resizeHandle.BackgroundTransparency = 1
	resizeHandle.BorderSizePixel = 0
	resizeHandle.Text = ""
	resizeHandle.ZIndex = 5
	resizeHandle.AutoButtonColor = false
	resizeHandle.Parent = mainFrame

	local resizing = false
	local resizeStart, startSize

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true
			resizeStart = input.Position
			startSize = mainFrame.Size
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - resizeStart
			local newWidth = math.max(200, startSize.X.Offset + delta.X)
			local newHeight = math.max(150, startSize.Y.Offset + delta.Y)
			mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
		end
	end)
end

return Leaderboard
