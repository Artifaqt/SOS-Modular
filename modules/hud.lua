-- modules/hud.lua
-- SOS HUD System - Main Orchestrator
-- Coordinates all sub-modules for a complete HUD experience

local HUD = {}

--------------------------------------------------------------------
-- MODULE REFERENCES (injected by main.lua)
--------------------------------------------------------------------
local Data, UIBuilder, LightingModule, AnimationsModule, FlightModule, CameraModule, PlayerModule, UIPagesModule
local Constants, Settings


-- Internal init gate to prevent RenderStepped firing before modules are injected
local __HUD_INITIALIZED = false
--------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------------------------
-- CONFIG & CONSTANTS
--------------------------------------------------------------------
local DEBUG = false
local function dprint(...) if DEBUG then print("[SOS HUD]", ...) end end

local menuToggleKey = Enum.KeyCode.H
local flightToggleKey = Enum.KeyCode.F
local flySpeed = 200
local maxFlySpeed, minFlySpeed = 1000, 1

-- These are populated from Constants during HUD.init(modules)
local MOBILE_FLY_POS, MOBILE_FLY_SIZE
local MICUP_PLACE_IDS, DISCORD_LINK
local INTRO_SOUND_ID
local BUTTON_CLICK_SOUND_ID, BUTTON_CLICK_VOLUME
local IS_MOBILE

--------------------------------------------------------------------
-- STATE VARIABLES
--------------------------------------------------------------------
local character, humanoid, rootPart
local gui, menuFrame, menuHandle, arrowButton, tabsBar, pagesHolder, mobileFlyButton
local fpsLabel, fpsAcc, fpsFrames, fpsValue, rainbowHue = nil, 0, 0, 60, 0
local menuOpen, menuTween = false, nil
local clickSoundTemplate, buttonSoundAttached = nil, setmetatable({}, {__mode="k"})

--------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------
local function notify(title, text, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "SOS HUD",
			Text = text or "",
			Duration = dur or 3
		})
	end)
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function safeDestroy(inst)
	if inst and inst.Parent then
		inst:Destroy()
	end
end

local function toAssetIdString(anyValue)
	local s = tostring(anyValue or ""):gsub("%s+", "")
	if s == "" then return nil end
	if s:find("^rbxassetid://") then return s end
	if s:match("^%d+$") then return "rbxassetid://" .. s end
	if s:find("^http") and s:lower():find("roblox.com") and s:lower():find("id=") then
		local id = s:match("id=(%d+)")
		if id then return "rbxassetid://" .. id end
	end
	return nil
end

--------------------------------------------------------------------
-- BUTTON SOUND SYSTEM
--------------------------------------------------------------------
local function ensureClickSoundTemplate()
	if clickSoundTemplate and clickSoundTemplate.Parent then
		return clickSoundTemplate
	end
	if not gui then return nil end

	local s = Instance.new("Sound")
	s.Name = "SOS_ButtonClickTemplate"
	s.SoundId = BUTTON_CLICK_SOUND_ID
	s.Volume = BUTTON_CLICK_VOLUME
	s.Looped = false
	s.Parent = gui

	clickSoundTemplate = s
	return clickSoundTemplate
end

local function playButtonClick()
	local tmpl = ensureClickSoundTemplate()
	if not tmpl then return end

	local s = tmpl:Clone()
	s.Name = "SOS_ButtonClick"
	s.Parent = gui
	pcall(function() s:Play() end)
	Debris:AddItem(s, 3)
end

local function attachSoundToButton(btn)
	if not btn or buttonSoundAttached[btn] then return end
	buttonSoundAttached[btn] = true

	local ok = pcall(function()
		btn.Activated:Connect(function() playButtonClick() end)
	end)

	if not ok then
		pcall(function()
			btn.MouseButton1Click:Connect(function() playButtonClick() end)
		end)
	end
end

local function setupGlobalButtonSounds(root)
	if not root then return end

	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextButton") or d:IsA("ImageButton") then
			attachSoundToButton(d)
		end
	end

	root.DescendantAdded:Connect(function(d)
		if d:IsA("TextButton") or d:IsA("ImageButton") then
			attachSoundToButton(d)
		end
	end)
end

local function playIntroSoundOnly()
	if not gui then return end

	local s = Instance.new("Sound")
	s.Name = "SOS_IntroSound"
	s.SoundId = INTRO_SOUND_ID
	s.Volume = 0.9
	s.Looped = false
	s.Parent = gui

	pcall(function() s:Play() end)
	Debris:AddItem(s, 8)
end

--------------------------------------------------------------------
-- HELPER FUNCTIONS (Character)
--------------------------------------------------------------------
local function findRightShoulderMotor(char)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("Motor6D") and part.Name == "Right Shoulder" then
			return part
		end
	end
	return nil
end

--------------------------------------------------------------------
-- CHARACTER SETUP
--------------------------------------------------------------------
local function getCharacter()
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	camera = workspace.CurrentCamera

	local rightShoulder = findRightShoulderMotor(character)
	local defaultShoulderC0 = rightShoulder and rightShoulder.C0 or nil

	-- Update all modules with new character
	AnimationsModule.updateCharacter(character, humanoid)
	FlightModule.updateCharacter(character, humanoid, rootPart, camera, rightShoulder, defaultShoulderC0)
	CameraModule.updateCharacter(character, humanoid)
	PlayerModule.updateCharacter(character, humanoid)

	-- Load flight animation tracks
	AnimationsModule.loadFlightTracks()
end

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------
function HUD.init(modules)
modules = modules or {}
-- Support both old keys and current keys
Data = modules.Data or Data
UIBuilder = modules.UIBuilder or UIBuilder
LightingModule = modules.LightingModule or modules.Lighting or LightingModule
AnimationsModule = modules.AnimationsModule or modules.Animations or AnimationsModule
FlightModule = modules.FlightModule or modules.Flight or FlightModule
CameraModule = modules.CameraModule or modules.Camera or CameraModule
PlayerModule = modules.PlayerModule or modules.Player or PlayerModule
UIPagesModule = modules.UIPagesModule or modules.UIPages or UIPagesModule
Constants = modules.Constants or Constants
Settings = modules.Settings or Settings


	-- Bind constant values now that Constants has been injected
	MOBILE_FLY_POS = Constants.MOBILE_FLY_POS
	MOBILE_FLY_SIZE = Constants.MOBILE_FLY_SIZE
	MICUP_PLACE_IDS = Constants.MICUP_PLACE_IDS
	DISCORD_LINK = Constants.DISCORD_LINK
	INTRO_SOUND_ID = Constants.INTRO_SOUND_ID
	BUTTON_CLICK_SOUND_ID = Constants.BUTTON_CLICK_SOUND_ID
	BUTTON_CLICK_VOLUME = Constants.BUTTON_CLICK_VOLUME

	-- Compute IS_MOBILE at init-time (module may be loaded before input flags settle)
	IS_MOBILE = UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled or UserInputService.MouseEnabled)
if not (Data and UIBuilder and LightingModule and AnimationsModule and FlightModule and CameraModule and PlayerModule and UIPagesModule and Constants and Settings) then
	warn("[SOS HUD] Missing injected modules. Ensure main.lua loads and passes HUD sub-modules into HUD.init().")
end

	Settings.loadSettings()

	-- Initialize all modules in dependency order
	print("[SOS HUD] Initializing modules...")

	-- 1. Data module (no dependencies)
	-- Data is stateless, no init needed

	-- 2. UI Builder (no dependencies)
	-- UIBuilder is stateless, no init needed

	-- 3. Initialize core modules BEFORE getting character
	LightingModule.init(Settings, Data)
	AnimationsModule.init(Settings, Constants, Data, notify, Constants.DEFAULT_FLOAT_ID, Constants.DEFAULT_FLY_ID)
	FlightModule.init(AnimationsModule, IS_MOBILE)

	-- 4. Get character (this will call loadFlightTracks, so AnimationsModule must be initialized first!)
	getCharacter()

	-- 5. Initialize modules that need character
	CameraModule.init(Settings, Constants, character, humanoid)
	PlayerModule.init(Settings, Constants, notify, character, humanoid)

	-- 6. Create UI
	HUD.createUI()

	-- 7. Apply initial states
	PlayerModule.applyPlayerSpeed()
	CameraModule.applyCameraSettings()
	AnimationsModule.reapplyAllOverridesAfterRespawn()
	LightingModule.syncLightingToggles()

	-- 8. Set up character respawn handling
	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.15)
		getCharacter()
		PlayerModule.applyPlayerSpeed()
		CameraModule.applyCameraSettings()
		AnimationsModule.reapplyAllOverridesAfterRespawn()
		LightingModule.syncLightingToggles()
		if FlightModule.isFlying() then
			FlightModule.stopFlying()
		end
	end)

	print("[SOS HUD] Initialization complete!")
	notify("SOS HUD", "Loaded.", 2)
end

-- Expose lighting sync function
HUD.syncLightingToggles = function()
	LightingModule.syncLightingToggles()
end

--------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------
function HUD.createUI()
	safeDestroy(gui)

	-- Create main ScreenGui
	gui = Instance.new("ScreenGui")
	gui.Name = "SOS_HUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	ensureClickSoundTemplate()
	setupGlobalButtonSounds(gui)
	playIntroSoundOnly()

	-- FPS Counter
	fpsLabel = Instance.new("TextLabel")
	fpsLabel.Name = "FPS"
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.AnchorPoint = Vector2.new(1, 1)
	fpsLabel.Position = UDim2.new(1, -6, 1, -6)
	fpsLabel.Size = UDim2.new(0, 140, 0, 18)
	fpsLabel.Font = Enum.Font.GothamBold
	fpsLabel.TextSize = 12
	fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
	fpsLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	fpsLabel.Text = "fps"
	fpsLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
	fpsLabel.Parent = gui

	-- Menu Handle (top bar)
	menuHandle = Instance.new("Frame")
	menuHandle.Name = "MenuHandle"
	menuHandle.AnchorPoint = Vector2.new(0.5, 0)
	menuHandle.Position = UDim2.new(0.5, 0, 0, 6)
	menuHandle.Size = UDim2.new(0, 560, 0, 42)
	menuHandle.BorderSizePixel = 0
	menuHandle.Parent = gui
	UIBuilder.makeCorner(menuHandle, 16)
	UIBuilder.makeGlass(menuHandle)
	UIBuilder.makeStroke(menuHandle, 2)

	-- Arrow Button (toggle menu)
	arrowButton = Instance.new("TextButton")
	arrowButton.Name = "Arrow"
	arrowButton.BackgroundTransparency = 1
	arrowButton.Size = UDim2.new(0, 40, 0, 40)
	arrowButton.Position = UDim2.new(0, 8, 0, 1)
	arrowButton.Text = "˄"
	arrowButton.Font = Enum.Font.GothamBold
	arrowButton.TextSize = 22
	arrowButton.TextColor3 = Color3.fromRGB(240, 240, 240)
	arrowButton.Parent = menuHandle

	-- Title Label
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -90, 1, 0)
	title.Position = UDim2.new(0, 70, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.Text = "SOS HUD"
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = menuHandle

	-- Menu Frame (main menu container)
	menuFrame = Instance.new("Frame")
	menuFrame.Name = "Menu"
	menuFrame.AnchorPoint = Vector2.new(0.5, 0)
	menuFrame.Position = UDim2.new(0.5, 0, 0, 52)
	menuFrame.Size = UDim2.new(0, 560, 0, 390)
	menuFrame.BorderSizePixel = 0
	menuFrame.Parent = gui
	UIBuilder.makeCorner(menuFrame, 16)
	UIBuilder.makeGlass(menuFrame)
	UIBuilder.makeStroke(menuFrame, 2)

	-- Tabs Bar (horizontal scrolling tab buttons)
	tabsBar = Instance.new("ScrollingFrame")
	tabsBar.Name = "TabsBar"
	tabsBar.BackgroundTransparency = 1
	tabsBar.BorderSizePixel = 0
	tabsBar.Position = UDim2.new(0, 14, 0, 10)
	tabsBar.Size = UDim2.new(1, -28, 0, 46)
	tabsBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabsBar.ScrollBarThickness = 2
	tabsBar.ScrollingDirection = Enum.ScrollingDirection.X
	tabsBar.AutomaticCanvasSize = Enum.AutomaticSize.X
	tabsBar.Parent = menuFrame

	local tabsLayout = Instance.new("UIListLayout")
	tabsLayout.FillDirection = Enum.FillDirection.Horizontal
	tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabsLayout.Padding = UDim.new(0, 10)
	tabsLayout.Parent = tabsBar

	-- Pages Holder (container for all tab pages)
	pagesHolder = Instance.new("Frame")
	pagesHolder.Name = "PagesHolder"
	pagesHolder.BackgroundTransparency = 1
	pagesHolder.Position = UDim2.new(0, 14, 0, 66)
	pagesHolder.Size = UDim2.new(1, -28, 1, -80)
	pagesHolder.ClipsDescendants = true
	pagesHolder.Parent = menuFrame

	-- Initialize UI Pages Module and build all pages
	UIPagesModule.init({
		Settings = Settings,
		Data = Data,
		Constants = Constants,
		LightingModule = LightingModule,
		AnimationsModule = AnimationsModule,
		FlightModule = FlightModule,
		CameraModule = CameraModule,
		PlayerModule = PlayerModule,
		UIBuilder = UIBuilder,
		notify = notify,
		toAssetIdString = toAssetIdString,
		UserInputService = UserInputService,
		TeleportService = TeleportService,
		HttpService = HttpService,
		GuiService = GuiService,
		LocalPlayer = LocalPlayer,
		pagesHolder = pagesHolder,
		tabsBar = tabsBar,
		flightToggleKey = flightToggleKey,
		MICUP_PLACE_IDS = MICUP_PLACE_IDS,
		DISCORD_LINK = DISCORD_LINK
	})

	-- Sync fly speed between modules
	UIPagesModule.setFlySpeed(flySpeed)
	UIPagesModule.setMinFlySpeed(minFlySpeed)
	UIPagesModule.setMaxFlySpeed(maxFlySpeed)
	FlightModule.setFlySpeed(flySpeed)

	-- Build all pages
	UIPagesModule.buildAllPages()

	-- Set up menu toggle animation
	menuOpen = false
	menuFrame.Visible = false
	arrowButton.Text = "˄"

	local openPos = menuFrame.Position
	local closedPos = UDim2.new(
		menuFrame.Position.X.Scale,
		menuFrame.Position.X.Offset,
		menuFrame.Position.Y.Scale,
		menuFrame.Position.Y.Offset - (menuFrame.Size.Y.Offset + 10)
	)

	local function setMenu(open, instant)
		menuOpen = open
		arrowButton.Text = open and "˅" or "˄"

		if menuTween then
			pcall(function() menuTween:Cancel() end)
			menuTween = nil
		end

		if instant then
			menuFrame.Visible = open
			menuFrame.Position = open and openPos or closedPos
			menuFrame.BackgroundTransparency = open and 0.18 or 1
			return
		end

		if open then
			menuFrame.Visible = true
			menuFrame.Position = closedPos
			menuFrame.BackgroundTransparency = 1
			menuTween = tween(
				menuFrame,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = openPos, BackgroundTransparency = 0.18}
			)
		else
			menuTween = tween(
				menuFrame,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = closedPos, BackgroundTransparency = 1}
			)
			menuTween.Completed:Connect(function()
				if not menuOpen then
					menuFrame.Visible = false
				end
			end)
		end
	end

	arrowButton.MouseButton1Click:Connect(function()
		setMenu(not menuOpen, false)
	end)

	setMenu(false, true)

	-- Mobile Fly Button
	if IS_MOBILE then
		mobileFlyButton = UIBuilder.makeButton(gui, "Fly")
		mobileFlyButton.Name = "MobileFly"
		mobileFlyButton.AnchorPoint = Vector2.new(1, 1)
		mobileFlyButton.Position = MOBILE_FLY_POS
		mobileFlyButton.Size = MOBILE_FLY_SIZE
		mobileFlyButton.TextSize = 18

		mobileFlyButton.MouseButton1Click:Connect(function()
			if FlightModule.isFlying() then
				FlightModule.stopFlying()
			else
				FlightModule.startFlying()
			end
		end)
	end
end

-- Expose buildAllPages for backwards compatibility
function HUD.buildAllPages()
	if UIPagesModule and UIPagesModule.buildAllPages then
		UIPagesModule.buildAllPages()
	end
end

--------------------------------------------------------------------
-- INPUT & RENDER LOOPS
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == flightToggleKey then
		if FlightModule.isFlying() then
			FlightModule.stopFlying()
		else
			FlightModule.startFlying()
		end
	elseif input.KeyCode == menuToggleKey then
		if arrowButton then
			arrowButton:Activate()
		end
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not __HUD_INITIALIZED then return end
	-- FPS Counter
	fpsAcc = fpsAcc + dt
	fpsFrames = fpsFrames + 1

	if fpsAcc >= 0.25 then
		fpsValue = math.floor((fpsFrames / fpsAcc) + 0.5)
		fpsAcc = 0
		fpsFrames = 0
	end

	if fpsLabel then
		fpsLabel.Text = tostring(fpsValue) .. " fps"

		if fpsValue < 40 then
			fpsLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
		elseif fpsValue < 60 then
			fpsLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		elseif fpsValue < 76 then
			fpsLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
		elseif fpsValue < 121 then
			fpsLabel.TextColor3 = Color3.fromRGB(80, 255, 220)
		else
			rainbowHue = (rainbowHue + dt * 0.5) % 1
			fpsLabel.TextColor3 = Color3.fromHSV(rainbowHue, 0.85, 1)
		end
	end

	-- Flight Physics Update
	FlightModule.renderStep(dt, flySpeed)

	-- Sync fly speed if changed by UI
	local uiFlySpeed = UIPagesModule.getFlySpeed()
	if uiFlySpeed and uiFlySpeed ~= flySpeed then
		flySpeed = uiFlySpeed
		FlightModule.setFlySpeed(flySpeed)
	end
end)

return HUD
