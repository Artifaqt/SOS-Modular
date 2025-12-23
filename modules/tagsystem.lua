-- modules/tagsystem.lua
-- SOS Tags System

local TagSystem = {}

-- Load utilities
local UIUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/ui.lua"))()
local Constants = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/constants.lua"))()
local ChatUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/chat.lua"))()
local PlayerUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/player.lua"))()

local Players = game:GetService("Players")
local TextChatService = game:FindService("TextChatService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- State
local SosUsers = {}
local AkUsers = {}
local SeenFirstActivation = false
local RepliedToActivationUserId = {}
local ownerPresenceAnnounced = false
local TrailsConnByUserId = {}

local gui
local statsPopup
local statsPopupLabel
local broadcastPanel
local broadcastSOS
local broadcastAK

local INIT_DELAY = 0.9

--------------------------------------------------------------------
-- UI HELPERS
--------------------------------------------------------------------

local function ensureGui()
	if gui and gui.Parent then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "SOS_Tags_UI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

local function ensureBroadcastPanel()
	ensureGui()

	if not PlayerUtils.canSeeBroadcastButtons(LocalPlayer) then
		if broadcastPanel and broadcastPanel.Parent then
			broadcastPanel:Destroy()
		end
		broadcastPanel = nil
		broadcastSOS = nil
		broadcastAK = nil
		return
	end

	if broadcastPanel and broadcastPanel.Parent then return end

	broadcastPanel = Instance.new("Frame")
	broadcastPanel.Name = "BroadcastPanel"
	broadcastPanel.AnchorPoint = Vector2.new(0, 1)
	broadcastPanel.Position = UDim2.new(0, 10, 1, -10)
	broadcastPanel.Size = UDim2.new(0, 220, 0, 48)
	broadcastPanel.BorderSizePixel = 0
	broadcastPanel.Parent = gui
	UIUtils.makeCorner(broadcastPanel, 14)
	UIUtils.makeGlass(broadcastPanel)
	UIUtils.makeStroke(broadcastPanel, 2, Constants.THEME.Red, 0.1)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = broadcastPanel

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = broadcastPanel

	broadcastSOS = UIUtils.makeButton(broadcastPanel, "Broadcast SOS")
	broadcastSOS.Size = UDim2.new(0, 100, 0, 32)

	broadcastAK = UIUtils.makeButton(broadcastPanel, "Broadcast AK")
	broadcastAK.Size = UDim2.new(0, 100, 0, 32)
end

--------------------------------------------------------------------
-- TAGS CREATION
--------------------------------------------------------------------

local function destroyTagGui(char, name)
	if not char then return end
	local old = char:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local function createSosRoleTag(plr)
	if not plr then return end
	local char = plr.Character
	if not char then return end

	local role = PlayerUtils.getSosRole(plr, SosUsers)

	if not role then
		destroyTagGui(char, "SOS_RoleTag")
		return
	end

	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local adornee = (head and head:IsA("BasePart")) and head or ((hrp and hrp:IsA("BasePart")) and hrp or nil)
	if not adornee then return end

	destroyTagGui(char, "SOS_RoleTag")

	local color = PlayerUtils.getRoleColor(plr, role)

	local bb = Instance.new("BillboardGui")
	bb.Name = "SOS_RoleTag"
	bb.Adornee = adornee
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, Constants.TAG_W, 0, Constants.TAG_H)
	bb.StudsOffset = Vector3.new(0, Constants.TAG_OFFSET_Y, 0)
	bb.Parent = char

	local btn = Instance.new("TextButton")
	btn.Name = "ClickArea"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BorderSizePixel = 0
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.Parent = bb
	UIUtils.makeCorner(btn, 10)

	btn.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	btn.BackgroundTransparency = 0.22

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 12)),
	})
	grad.Parent = btn

	local stroke = UIUtils.makeStroke(btn, 2, color, 0.05)

	local top = Instance.new("TextLabel")
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, -10, 0, 18)
	top.Position = UDim2.new(0, 5, 0, 3)
	top.Font = Enum.Font.GothamBold
	top.TextSize = 13
	top.TextXAlignment = Enum.TextXAlignment.Center
	top.TextYAlignment = Enum.TextYAlignment.Center
	top.Text = PlayerUtils.getTopLine(plr, role)
	top.ZIndex = 3
	top.Parent = btn
	top.TextColor3 = color

	local bottom = Instance.new("TextLabel")
	bottom.BackgroundTransparency = 1
	bottom.Size = UDim2.new(1, -10, 0, 16)
	bottom.Position = UDim2.new(0, 5, 0, 19)
	bottom.Font = Enum.Font.Gotham
	bottom.TextSize = 12
	bottom.TextColor3 = Color3.fromRGB(230, 230, 230)
	bottom.TextXAlignment = Enum.TextXAlignment.Center
	bottom.TextYAlignment = Enum.TextYAlignment.Center
	bottom.Text = plr.Name
	bottom.ZIndex = 3
	bottom.Parent = btn

	-- Click to teleport
	btn.MouseButton1Click:Connect(function()
		local holdingCtrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		if not holdingCtrl then
			PlayerUtils.teleportBehind(LocalPlayer, plr, 5)
		end
	end)
end

local function createAkOrbTag(plr)
	if not plr then return end
	local char = plr.Character
	if not char then return end

	if PlayerUtils.isOwner(plr) then
		destroyTagGui(char, "SOS_AKTag")
		return
	end

	if not SosUsers[plr.UserId] then
		destroyTagGui(char, "SOS_AKTag")
		return
	end

	if not AkUsers[plr.UserId] then
		destroyTagGui(char, "SOS_AKTag")
		return
	end

	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local adornee = (head and head:IsA("BasePart")) and head or ((hrp and hrp:IsA("BasePart")) and hrp or nil)
	if not adornee then return end

	destroyTagGui(char, "SOS_AKTag")

	local bb = Instance.new("BillboardGui")
	bb.Name = "SOS_AKTag"
	bb.Adornee = adornee
	bb.AlwaysOnTop = true
	bb.Size = UDim2.new(0, Constants.ORB_SIZE, 0, Constants.ORB_SIZE)
	bb.StudsOffset = Vector3.new(0, Constants.ORB_OFFSET_Y, 0)
	bb.Parent = char

	local btn = Instance.new("TextButton")
	btn.Name = "ClickArea"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BorderSizePixel = 0
	btn.Text = "AK"
	btn.AutoButtonColor = true
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 10
	btn.TextXAlignment = Enum.TextXAlignment.Center
	btn.TextYAlignment = Enum.TextYAlignment.Center
	btn.TextColor3 = Color3.fromRGB(255, 60, 60)
	btn.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
	btn.BackgroundTransparency = 0.12
	btn.Parent = bb
	UIUtils.makeCorner(btn, 999)
	UIUtils.makeStroke(btn, 1, Color3.fromRGB(0, 0, 0), 0.25)
end

local function refreshAllTagsForPlayer(plr)
	if not plr or not plr.Character then return end
	createSosRoleTag(plr)
	createAkOrbTag(plr)
end

local function hookPlayer(plr)
	if not plr then return end
	plr.CharacterAdded:Connect(function()
		task.wait(0.12)
		refreshAllTagsForPlayer(plr)
	end)
	if plr.Character then
		task.defer(function()
			refreshAllTagsForPlayer(plr)
		end)
	end
end

--------------------------------------------------------------------
-- SOS/AK ACTIVATION
--------------------------------------------------------------------

local function onSosActivated(userId)
	if typeof(userId) ~= "number" then return end
	SosUsers[userId] = true
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		refreshAllTagsForPlayer(plr)
	end
end

local function onAkSeen(userId)
	if typeof(userId) ~= "number" then return end
	AkUsers[userId] = true
	local plr = Players:GetPlayerByUserId(userId)
	if plr then
		refreshAllTagsForPlayer(plr)
	end
end

local function textHasAk(text)
	if type(text) ~= "string" then return false end
	if text == Constants.AK_MARKER_1 or text == Constants.AK_MARKER_2 then return true end
	if text:find(Constants.AK_MARKER_1, 1, true) then return true end
	if text:find(Constants.AK_MARKER_2, 1, true) then return true end
	return false
end

local function maybeReplyToActivation(uid)
	if typeof(uid) ~= "number" then return end
	if uid == LocalPlayer.UserId then return end

	if not SeenFirstActivation then
		SeenFirstActivation = true
		return
	end

	if RepliedToActivationUserId[uid] then
		return
	end

	RepliedToActivationUserId[uid] = true
	ChatUtils.trySendChat(Constants.SOS_REPLY_MARKER)
end

--------------------------------------------------------------------
-- CHAT LISTENERS
--------------------------------------------------------------------

local function hookChatListeners()
	if TextChatService and TextChatService.MessageReceived then
		TextChatService.MessageReceived:Connect(function(msg)
			if not msg then return end
			local text = msg.Text or ""
			local src = msg.TextSource
			if not src or not src.UserId then return end
			local uid = src.UserId

			if text == Constants.SOS_ACTIVATE_MARKER then
				onSosActivated(uid)
				maybeReplyToActivation(uid)
				return
			end

			if text == Constants.SOS_REPLY_MARKER then
				onSosActivated(uid)
				return
			end

			if textHasAk(text) then
				onAkSeen(uid)
				return
			end
		end)
	end

	local function hookChatted(plr)
		pcall(function()
			plr.Chatted:Connect(function(message)
				if message == Constants.SOS_ACTIVATE_MARKER then
					onSosActivated(plr.UserId)
					maybeReplyToActivation(plr.UserId)
				elseif message == Constants.SOS_REPLY_MARKER then
					onSosActivated(plr.UserId)
				elseif textHasAk(message) then
					onAkSeen(plr.UserId)
				end
			end)
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		hookChatted(plr)
	end
	Players.PlayerAdded:Connect(hookChatted)
end

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------

function TagSystem.init()
	ensureBroadcastPanel()

	if broadcastSOS then
		broadcastSOS.MouseButton1Click:Connect(function()
			onSosActivated(LocalPlayer.UserId)
			ChatUtils.trySendChat(Constants.SOS_ACTIVATE_MARKER)
		end)
	end

	if broadcastAK then
		broadcastAK.MouseButton1Click:Connect(function()
			onAkSeen(LocalPlayer.UserId)
			ChatUtils.trySendChat(Constants.AK_MARKER_1)
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		hookPlayer(plr)
	end

	Players.PlayerAdded:Connect(function(plr)
		hookPlayer(plr)
		RepliedToActivationUserId[plr.UserId] = nil
	end)

	Players.PlayerRemoving:Connect(function(plr)
		if plr then
			RepliedToActivationUserId[plr.UserId] = nil
		end
	end)

	hookChatListeners()

	onSosActivated(LocalPlayer.UserId)
	ChatUtils.trySendChat(Constants.SOS_ACTIVATE_MARKER)

	print("SOS Tags loaded. Activation 𖺗. Reply ¬ once per person per join.")
end

-- Delayed initialization
task.delay(INIT_DELAY, function()
	TagSystem.init()
end)

return TagSystem
