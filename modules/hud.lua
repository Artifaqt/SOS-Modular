-- modules/hud.lua
-- Main HUD System (Flight, Animations, Camera, etc.)
-- NOTE: This is a template - you'll need to refactor your main .lua file here

local HUD = {}

-- Load utilities
local UIUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/ui.lua"))()
local Constants = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/constants.lua"))()
local SettingsUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/settings.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- State
local flying = false
local character
local humanoid
local rootPart

--------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------

HUD.config = {
	menuToggleKey = Enum.KeyCode.H,
	flightToggleKey = Enum.KeyCode.F,
	flySpeed = 200,
	maxFlySpeed = 1000,
	minFlySpeed = 1,
}

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------

function HUD.init()
	print("HUD System initializing...")

	-- Setup character
	HUD.setupCharacter()

	-- Create UI
	HUD.createUI()

	-- Setup controls
	HUD.setupControls()

	-- Load settings
	local settings = SettingsUtils.loadSettings()
	if settings then
		HUD.applySettings(settings)
	end

	print("HUD System loaded!")
end

--------------------------------------------------------------------
-- CHARACTER SETUP
--------------------------------------------------------------------

function HUD.setupCharacter()
	character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	-- Handle respawns
	LocalPlayer.CharacterAdded:Connect(function(char)
		character = char
		humanoid = char:WaitForChild("Humanoid")
		rootPart = char:WaitForChild("HumanoidRootPart")
		if flying then
			HUD.stopFlying()
		end
	end)
end

--------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------

function HUD.createUI()
	-- Create your main HUD UI here
	-- This should include:
	-- - Main menu frame
	-- - Flight controls
	-- - Animation selectors
	-- - Camera controls
	-- - Speed controls
	-- etc.

	print("HUD UI created")
end

--------------------------------------------------------------------
-- CONTROLS
--------------------------------------------------------------------

function HUD.setupControls()
	-- Flight toggle
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == HUD.config.flightToggleKey then
			if flying then
				HUD.stopFlying()
			else
				HUD.startFlying()
			end
		end
	end)
end

--------------------------------------------------------------------
-- FLIGHT SYSTEM
--------------------------------------------------------------------

function HUD.startFlying()
	if flying or not humanoid or not rootPart then return end
	flying = true

	humanoid.PlatformStand = true

	-- Create BodyGyro and BodyVelocity
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.P = 1e5
	bodyGyro.Parent = rootPart

	local bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVel.Velocity = Vector3.new()
	bodyVel.Parent = rootPart

	print("Flight started")
end

function HUD.stopFlying()
	if not flying then return end
	flying = false

	-- Clean up flight objects
	for _, obj in ipairs(rootPart:GetChildren()) do
		if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then
			obj:Destroy()
		end
	end

	if humanoid then
		humanoid.PlatformStand = false
	end

	print("Flight stopped")
end

--------------------------------------------------------------------
-- SETTINGS
--------------------------------------------------------------------

function HUD.applySettings(settings)
	if settings.FlySpeed then
		HUD.config.flySpeed = settings.FlySpeed
	end
	-- Apply other settings...
end

function HUD.saveSettings()
	local settings = {
		FlySpeed = HUD.config.flySpeed,
		-- Add other settings...
	}
	SettingsUtils.saveSettingsNow(settings)
end

return HUD
