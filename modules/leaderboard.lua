-- modules/leaderboard.lua
-- Custom Leaderboard System - COMPLETE VERSION

local Leaderboard = {}
Leaderboard.__initialized = false


-- Utilities (injected by main.lua)
local UIUtils
local Constants
local CoreModule
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local THEME

-- State
local screenGui
local mainFrame
local title
local scrollFrame
local playerEntries = {}
local mutedPlayers = {}
local currentlyExpandedPanel = nil
local currentExpandedCloseCallback = nil
-- CoreModule is injected by main.lua via Leaderboard.init({CoreModule=...})

local isLeaderboardVisible = true
local usingCustom = true
local isSwitching = false
local originalPosition

-- Teleport sound (created after Constants is injected)
local teleportSound

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------

function Leaderboard.init(deps)
	-- Ignore accidental auto-calls (we require dependency injection from main.lua)
	if deps == nil then return end
	if Leaderboard.__initialized then return end

	deps = deps or {}
	UIUtils = deps.UIUtils or UIUtils
	Constants = deps.Constants or Constants
	CoreModule = deps.CoreModule or CoreModule

	if not UIUtils or not Constants then
		warn("[SOS Leaderboard] Missing dependencies. Expected {UIUtils=..., Constants=...}.")
		return
	end

	Leaderboard.__initialized = true
THEME = Constants.THEME

	-- Create / refresh teleport sound now that Constants is available
	pcall(function()
		if teleportSound and teleportSound.Parent then
			teleportSound:Destroy()
		end
	end)
	teleportSound = Instance.new("Sound")
	teleportSound.Name = "TeleportSound"
	teleportSound.SoundId = Constants.TELEPORT_SOUND_ID
	teleportSound.Volume = 100
	teleportSound.Parent = SoundService
	-- CoreModule injected by main.lua (optional)
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
-- PLAYER ENTRY CREATION (COMPLETE)
--------------------------------------------------------------------

function Leaderboard.createPlayerEntry(player)
	local playerFrame = Instance.new("Frame")
	playerFrame.Name = player.Name
	playerFrame.Size = UDim2.new(1, -5, 0, 30)
	playerFrame.BackgroundColor3 = THEME.Entry
	playerFrame.BackgroundTransparency = THEME.EntryTrans
	playerFrame.BorderSizePixel = 0

	UIUtils.makeCorner(playerFrame, 10)
	UIUtils.makeStroke(playerFrame, 1, THEME.Red, 0.35)

	-- Create clickable button for the main entry
	local clickButton = Instance.new("TextButton")
	clickButton.Size = UDim2.new(1, 0, 0, 30)
	clickButton.Position = UDim2.new(0, 0, 0, 0)
	clickButton.BackgroundTransparency = 1
	clickButton.Text = ""
	clickButton.ZIndex = 2
	clickButton.Parent = playerFrame

	-- Friend icon (left of name)
	local friendIcon = Instance.new("ImageLabel")
	friendIcon.Name = "FriendIcon"
	friendIcon.Size = UDim2.new(0, 16, 0, 16)
	friendIcon.Position = UDim2.new(0, 5, 0.5, -8)
	friendIcon.BackgroundTransparency = 1
	friendIcon.Image = "rbxasset://textures/ui/PlayerList/FriendIcon.png"
	friendIcon.ImageColor3 = Color3.fromRGB(100, 200, 255)
	friendIcon.ScaleType = Enum.ScaleType.Fit
	friendIcon.ZIndex = 3
	friendIcon.Visible = false
	friendIcon.Parent = playerFrame

	if player ~= LocalPlayer then
		pcall(function()
			local isFriend = LocalPlayer:IsFriendsWith(player.UserId)
			friendIcon.Visible = isFriend
		end)
	end

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

	player:GetPropertyChangedSignal("DisplayName"):Connect(function()
		local newDisplayText = player.DisplayName
		if player.DisplayName ~= player.Name then
			newDisplayText = player.DisplayName .. " (@" .. player.Name .. ")"
		end
		nameLabel.Text = newDisplayText
		Leaderboard.updateSortOrder()
	end)

	-- Special styling for specific user IDs
	local isSpecialUser = (player.UserId == 118170824 or player.UserId == 7870252435)

	if isSpecialUser then
		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 150)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
		})
		gradient.Rotation = 45
		gradient.Parent = nameLabel

		local glow = Instance.new("UIStroke")
		glow.Color = Color3.fromRGB(255, 215, 0)
		glow.Thickness = 1.5
		glow.Transparency = 0.3
		glow.Parent = nameLabel

		nameLabel.Font = Enum.Font.GothamBold

		spawn(function()
			while nameLabel.Parent do
				for i = 0, 360, 2 do
					if not nameLabel.Parent then break end
					gradient.Rotation = i
					wait(0.03)
				end
			end
		end)
	elseif player == LocalPlayer then
		nameLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
		nameLabel.Font = Enum.Font.GothamBold
	end

	-- Mute indicator (red dot)
	local muteIndicator = Instance.new("Frame")
	muteIndicator.Name = "MuteIndicator"
	muteIndicator.Size = UDim2.new(0, 8, 0, 8)
	muteIndicator.Position = UDim2.new(1, -15, 0.5, -4)
	muteIndicator.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	muteIndicator.BorderSizePixel = 0
	muteIndicator.ZIndex = 4
	muteIndicator.Visible = mutedPlayers[player.UserId] or false
	muteIndicator.Parent = playerFrame

	UIUtils.makeCorner(muteIndicator, 999)

	-- Options panel
	local optionsPanel = Instance.new("Frame")
	optionsPanel.Name = "OptionsPanel"
	optionsPanel.Size = UDim2.new(0, 0, 0, 116)
	optionsPanel.BackgroundColor3 = THEME.Panel
	optionsPanel.BackgroundTransparency = THEME.PanelTrans
	optionsPanel.BorderSizePixel = 0
	optionsPanel.ClipsDescendants = true
	optionsPanel.ZIndex = 10
	optionsPanel.Parent = screenGui

	UIUtils.makeCorner(optionsPanel, 12)
	UIUtils.makeStroke(optionsPanel, 2, THEME.Red, 0.10)
	UIUtils.makeGlass(optionsPanel)

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Padding = UDim.new(0, 3)
	buttonLayout.FillDirection = Enum.FillDirection.Vertical
	buttonLayout.Parent = optionsPanel

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.Parent = optionsPanel

	-- Mute/Unmute button
	local muteButton = Instance.new("TextButton")
	muteButton.Name = "MuteButton"
	muteButton.Size = UDim2.new(1, 0, 0, 24)
	muteButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	muteButton.BackgroundTransparency = 0
	muteButton.BorderSizePixel = 0
	muteButton.Text = mutedPlayers[player.UserId] and "Unmute Voice" or "Mute Voice"
	muteButton.TextColor3 = THEME.Text
	muteButton.TextSize = 14
	muteButton.Font = Enum.Font.GothamMedium
	muteButton.ZIndex = 11
	muteButton.LayoutOrder = 1
	muteButton.Parent = optionsPanel
	UIUtils.themeButton(muteButton)

	-- Friend Request button
	local friendButton = Instance.new("TextButton")
	friendButton.Name = "FriendButton"
	friendButton.Size = UDim2.new(1, 0, 0, 24)
	friendButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	friendButton.BackgroundTransparency = 0
	friendButton.BorderSizePixel = 0
	friendButton.Text = "Add Friend"
	friendButton.TextColor3 = THEME.Text
	friendButton.TextSize = 14
	friendButton.Font = Enum.Font.GothamMedium
	friendButton.ZIndex = 11
	friendButton.LayoutOrder = 2
	friendButton.Parent = optionsPanel
	UIUtils.themeButton(friendButton)

	-- View Avatar button
	local avatarButton = Instance.new("TextButton")
	avatarButton.Name = "AvatarButton"
	avatarButton.Size = UDim2.new(1, 0, 0, 24)
	avatarButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	avatarButton.BackgroundTransparency = 0
	avatarButton.BorderSizePixel = 0
	avatarButton.Text = "View Avatar"
	avatarButton.TextColor3 = THEME.Text
	avatarButton.TextSize = 14
	avatarButton.Font = Enum.Font.GothamMedium
	avatarButton.ZIndex = 11
	avatarButton.LayoutOrder = 3
	avatarButton.Parent = optionsPanel
	UIUtils.themeButton(avatarButton)

	-- Teleport button
	local teleportButton = Instance.new("TextButton")
	teleportButton.Name = "TeleportButton"
	teleportButton.Size = UDim2.new(1, 0, 0, 24)
	teleportButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	teleportButton.BackgroundTransparency = 0
	teleportButton.BorderSizePixel = 0
	teleportButton.Text = "Teleport"
	teleportButton.TextColor3 = THEME.Text
	teleportButton.TextSize = 14
	teleportButton.Font = Enum.Font.GothamMedium
	teleportButton.ZIndex = 11
	teleportButton.LayoutOrder = 4
	teleportButton.Parent = optionsPanel
	UIUtils.themeButton(teleportButton)

	-- Avatar button functionality
	avatarButton.MouseButton1Click:Connect(function()
		pcall(function()
			game:GetService("GuiService"):InspectPlayerFromUserId(player.UserId)
			print("Opened avatar for " .. player.DisplayName)
		end)
	end)

	-- Teleport button functionality
	teleportButton.MouseButton1Click:Connect(function()
		pcall(function()
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local targetCFrame = player.Character.HumanoidRootPart.CFrame

				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					teleportSound:Play()
					LocalPlayer.Character.HumanoidRootPart.CFrame = targetCFrame
				else
					warn("Your character is not available")
				end
			else
				warn(player.DisplayName .. "'s character is not available")
			end
		end)
	end)

	-- Friend button functionality
	friendButton.MouseButton1Click:Connect(function()
		local success, result = pcall(function()
			local userid = player.UserId

			local alreadyFriends = false
			pcall(function()
				alreadyFriends = LocalPlayer:IsFriendsWith(userid)
			end)

			if alreadyFriends then
				return "Already friends with " .. player.DisplayName
			end

			if CoreModule and CoreModule.replicatesignal then
				CoreModule.replicatesignal(LocalPlayer.RemoteFriendRequestSignal, userid, Enum.FriendRequestEvent.Issue)
				friendButton.Text = "Request Sent"
				return "Sent friend request to " .. player.DisplayName .. " (replicatesignal)"
			elseif LocalPlayer.RequestFriendship then
				warn("replicatesignal not available - using RequestFriendship fallback")
				LocalPlayer:RequestFriendship(player)
				friendButton.Text = "Request Sent"
				return "Sent friend request to " .. player.DisplayName .. " (fallback)"
			else
				error("Your executor doesn't support friend requests")
			end
		end)

		if success then
			print(result)
		else
			warn("Failed to send friend request: " .. tostring(result))
		end
	end)

	-- Update friend icon and button periodically
	spawn(function()
		while playerFrame.Parent do
			wait(5)
			pcall(function()
				if player ~= LocalPlayer and player.Parent then
					local isFriend = LocalPlayer:IsFriendsWith(player.UserId)
					friendIcon.Visible = isFriend
					if isFriend then
						friendButton.Text = "Already Friends"
					else
						friendButton.Text = "Add Friend"
					end
				end
			end)
		end
	end)

	-- Function to check actual mute state from VoiceChat
	local function updateMuteState()
		pcall(function()
			local VoiceChatInternal = game:GetService("VoiceChatInternal")
			local isMuted = false

			pcall(function()
				if VoiceChatInternal.GetParticipants then
					local participants = VoiceChatInternal:GetParticipants()
					for _, participant in pairs(participants) do
						if participant.UserId == player.UserId then
							isMuted = participant.IsMuted or false
							return
						end
					end
				end
			end)

			if not isMuted then
				pcall(function()
					local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
					if playerGui then
						local voiceChatUI = playerGui:FindFirstChild("BubbleChat") or playerGui:FindFirstChild("VoiceChat")
						if voiceChatUI then
							local muteIcon = voiceChatUI:FindFirstChild("MuteIcon_" .. player.UserId, true)
							if muteIcon and muteIcon.Visible then
								isMuted = true
							end
						end
					end
				end)
			end

			if isMuted then
				mutedPlayers[player.UserId] = true
			end

			local uiMuted = mutedPlayers[player.UserId] == true
			muteIndicator.Visible = uiMuted
			if uiMuted then
				muteButton.Text = "Unmute Voice"
			else
				muteButton.Text = "Mute Voice"
			end
		end)
	end

	-- Mute button functionality
	muteButton.MouseButton1Click:Connect(function()
		local VoiceChatInternal = game:GetService("VoiceChatInternal")

		if mutedPlayers[player.UserId] then
			pcall(function()
				VoiceChatInternal:SubscribePause(player.UserId, false)
			end)
			mutedPlayers[player.UserId] = false
			muteButton.Text = "Mute Voice"
			muteIndicator.Visible = false
			print("Unmuted " .. player.DisplayName)
		else
			pcall(function()
				VoiceChatInternal:SubscribePause(player.UserId, true)
			end)
			mutedPlayers[player.UserId] = true
			muteButton.Text = "Unmute Voice"
			muteIndicator.Visible = true
			print("Muted " .. player.DisplayName)
		end

		wait(0.1)
		updateMuteState()
	end)

	-- Continuously monitor mute state
	spawn(function()
		while playerFrame.Parent do
			updateMuteState()
			wait(2)
		end
	end)

	-- Track expanded state
	local expanded = false
	local updateConnection = nil

	-- Close panel function
	local function closeThisPanel()
		expanded = false
		optionsPanel.Visible = false

		playerFrame.BackgroundColor3 = THEME.Entry

		if updateConnection then
			updateConnection:Disconnect()
			updateConnection = nil
		end

		if currentlyExpandedPanel == optionsPanel then
			currentlyExpandedPanel = nil
			currentExpandedCloseCallback = nil
		end
	end

	-- Update options panel position
	local function updateOptionsPosition()
		if expanded and mainFrame.Visible then
			local frameAbsPos = playerFrame.AbsolutePosition
			local leaderboardAbsPos = mainFrame.AbsolutePosition
			local leaderboardSize = mainFrame.AbsoluteSize
			local screenSize = workspace.CurrentCamera.ViewportSize

			local entryTopY = frameAbsPos.Y
			local entryBottomY = frameAbsPos.Y + playerFrame.AbsoluteSize.Y
			local leaderboardTopY = leaderboardAbsPos.Y + 40
			local leaderboardBottomY = leaderboardAbsPos.Y + leaderboardSize.Y

			if entryBottomY < leaderboardTopY or entryTopY > leaderboardBottomY then
				closeThisPanel()
				return
			end

			local leaderboardOnRight = leaderboardAbsPos.X > screenSize.X / 2

			local submenuHeight = optionsPanel.AbsoluteSize.Y
			local centeredOffset = (playerFrame.AbsoluteSize.Y - submenuHeight) / 2
			local desiredY = frameAbsPos.Y + centeredOffset

			local minY = leaderboardTopY
			local maxY = leaderboardBottomY - submenuHeight
			local clampedY = math.clamp(desiredY, minY, maxY)

			if leaderboardOnRight then
				optionsPanel.Position = UDim2.new(0, frameAbsPos.X - 140, 0, clampedY)
			else
				optionsPanel.Position = UDim2.new(0, frameAbsPos.X + playerFrame.AbsoluteSize.X + 10, 0, clampedY)
			end
		end
	end

	-- Click to expand/collapse
	clickButton.MouseButton1Click:Connect(function()
		if currentlyExpandedPanel and currentlyExpandedPanel ~= optionsPanel then
			if currentExpandedCloseCallback then
				currentExpandedCloseCallback()
			end
		end

		expanded = not expanded

		if expanded then
			local frameAbsPos = playerFrame.AbsolutePosition
			local leaderboardAbsPos = mainFrame.AbsolutePosition
			local leaderboardSize = mainFrame.AbsoluteSize

			local leaderboardTopY = leaderboardAbsPos.Y + 40
			local leaderboardBottomY = leaderboardAbsPos.Y + leaderboardSize.Y

			local entryTopY = frameAbsPos.Y
			local entryBottomY = frameAbsPos.Y + playerFrame.AbsoluteSize.Y

			if entryBottomY < leaderboardTopY or entryTopY > leaderboardBottomY then
				expanded = false
				return
			end

			currentlyExpandedPanel = optionsPanel
			currentExpandedCloseCallback = closeThisPanel

			playerFrame.BackgroundColor3 = THEME.EntryHover

			local screenSize = workspace.CurrentCamera.ViewportSize
			local leaderboardOnRight = leaderboardAbsPos.X > screenSize.X / 2

			optionsPanel.Size = UDim2.new(0, 130, 0, 116)
			optionsPanel.Visible = true

			local submenuHeight = 116
			local centeredOffset = (playerFrame.AbsoluteSize.Y - submenuHeight) / 2
			local desiredY = frameAbsPos.Y + centeredOffset

			local minY = leaderboardTopY
			local maxY = leaderboardBottomY - submenuHeight
			local clampedY = math.clamp(desiredY, minY, maxY)

			if leaderboardOnRight then
				local targetX = frameAbsPos.X - 140
				local startX = frameAbsPos.X
				optionsPanel.Position = UDim2.new(0, startX, 0, clampedY)
				optionsPanel:TweenPosition(UDim2.new(0, targetX, 0, clampedY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
			else
				local targetX = frameAbsPos.X + playerFrame.AbsoluteSize.X + 10
				local startX = frameAbsPos.X + playerFrame.AbsoluteSize.X
				optionsPanel.Position = UDim2.new(0, startX, 0, clampedY)
				optionsPanel:TweenPosition(UDim2.new(0, targetX, 0, clampedY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
			end

			if updateConnection then
				updateConnection:Disconnect()
			end
			updateConnection = RunService.RenderStepped:Connect(updateOptionsPosition)
		else
			closeThisPanel()
		end
	end)

	-- Hide panel when main frame slides off screen or when collapsed
	local lastLeaderboardPos = mainFrame.AbsolutePosition
	RunService.RenderStepped:Connect(function()
		local currentPos = mainFrame.AbsolutePosition
		local screenSize = workspace.CurrentCamera.ViewportSize

		local isOffScreen = currentPos.X < -mainFrame.AbsoluteSize.X or currentPos.X > screenSize.X

		if isOffScreen or not expanded then
			optionsPanel.Visible = false
		else
			optionsPanel.Visible = true
		end

		lastLeaderboardPos = currentPos
	end)

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

	-- TAB: show/hide only the currently active leaderboard
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

	-- CAPS LOCK: switch which leaderboard is active (never allow both visible)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode ~= Enum.KeyCode.CapsLock then return end
		if isSwitching then return end

		isSwitching = true
		usingCustom = not usingCustom

		if usingCustom then
			pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)

			if isLeaderboardVisible then
				Leaderboard.showCustom(true)
			else
				Leaderboard.hideCustom(false)
			end

			isSwitching = false
			print("Switched to Custom Leaderboard")
		else
			local function finishToOfficial()
				pcall(function()
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, isLeaderboardVisible)
				end)
				isSwitching = false
				print("Switched to Official Roblox Leaderboard")
			end

			if isLeaderboardVisible then
				local tween = Leaderboard.hideCustom(true)
				if tween then
					tween.Completed:Connect(function()
						finishToOfficial()
					end)
				else
					finishToOfficial()
				end
			else
				Leaderboard.hideCustom(false)
				pcall(function()
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
				end)
				isSwitching = false
				print("Switched to Official Roblox Leaderboard")
			end
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

			if (newWidth < 200 or newHeight < 200) and currentExpandedCloseCallback then
				currentExpandedCloseCallback()
			end
		end
	end)
end


--------------------------------------------------------------------
-- CLEANUP (for re-execution)
--------------------------------------------------------------------
function Leaderboard.cleanup()
    pcall(function()
        local cg = game:GetService("CoreGui")
        local gui = cg:FindFirstChild("CustomLeaderboard")
        if gui then gui:Destroy() end
    end)
end

return Leaderboard