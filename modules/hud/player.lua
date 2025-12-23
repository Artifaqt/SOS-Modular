-- modules/hud/player.lua
-- Player controls (speed, VIP tools)

local PlayerModule = {}

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

-- Will be injected
local Settings
local Constants
local notify

-- State
local DEFAULT_WALKSPEED = nil
local playerSpeed = nil
local character, humanoid

function PlayerModule.init(settingsModule, constantsModule, notifyFunc, char, hum)
	Settings = settingsModule
	Constants = constantsModule
	notify = notifyFunc
	character = char
	humanoid = hum
end

function PlayerModule.updateCharacter(char, hum)
	character = char
	humanoid = hum
end

function PlayerModule.applyPlayerSpeed()
	if humanoid and playerSpeed then
		humanoid.WalkSpeed = playerSpeed
	end
end

function PlayerModule.resetPlayerSpeedToDefault()
	if humanoid then
		if DEFAULT_WALKSPEED == nil then
			DEFAULT_WALKSPEED = humanoid.WalkSpeed
		end
		playerSpeed = DEFAULT_WALKSPEED
		humanoid.WalkSpeed = DEFAULT_WALKSPEED
	end
	if Settings then Settings.scheduleSave() end
end

function PlayerModule.ownsAnyVipPass()
	for _, id in ipairs(Constants.VIP_GAMEPASSES) do
		local ok, owned = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, id)
		end)
		if ok and owned then return true end
	end
	return false
end

function PlayerModule.giveBetterSpeedCoil()
	if not character or not humanoid then
		if notify then notify("Better Speed Coil", "Character not ready.", 2) end
		return
	end
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then
		if notify then notify("Better Speed Coil", "Backpack not found.", 2) end
		return
	end
	if backpack:FindFirstChild("Better Speed Coil") or character:FindFirstChild("Better Speed Coil") then
		if notify then notify("Better Speed Coil", "You already have it.", 2) end
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = "Better Speed Coil"
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ManualActivationOnly = true

	local last = nil
	tool.Equipped:Connect(function()
		if humanoid then
			last = humanoid.WalkSpeed
			humanoid.WalkSpeed = 111
		end
	end)
	tool.Unequipped:Connect(function()
		if humanoid then
			humanoid.WalkSpeed = last or humanoid.WalkSpeed
		end
	end)

	tool.Parent = backpack
	if notify then notify("Better Speed Coil", "Added to your inventory.", 2) end
end

-- Getters/Setters
function PlayerModule.getPlayerSpeed() return playerSpeed end
function PlayerModule.setPlayerSpeed(speed) playerSpeed = speed end

return PlayerModule
