-- main.lua
-- Main orchestrator - loads and initializes all modules

local Main = {}

-- GitHub base URL (UPDATE THIS WITH YOUR GITHUB RAW URL)
local GITHUB_BASE_URL = "https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main"

-- Module URLs
local MODULES = {
	-- Utils
	constants = GITHUB_BASE_URL .. "/utils/constants.lua",
	ui = GITHUB_BASE_URL .. "/utils/ui.lua",
	settings = GITHUB_BASE_URL .. "/utils/settings.lua",
	chat = GITHUB_BASE_URL .. "/utils/chat.lua",
	player = GITHUB_BASE_URL .. "/utils/player.lua",

	-- Modules
	hud = GITHUB_BASE_URL .. "/modules/hud.lua",
	leaderboard = GITHUB_BASE_URL .. "/modules/leaderboard.lua",
	tagsystem = GITHUB_BASE_URL .. "/modules/tagsystem.lua",
}

--------------------------------------------------------------------
-- MODULE LOADING
--------------------------------------------------------------------

function Main.loadModule(name, url)
	local success, result = pcall(function()
		return loadstring(game:HttpGet(url))()
	end)

	if success then
		print("[SOS] Loaded module:", name)
		return result
	else
		warn("[SOS] Failed to load module:", name, "-", result)
		return nil
	end
end

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------

function Main.init()
	print("===========================================")
	print("       SOS Script Loading System")
	print("===========================================")

	-- Load utilities first
	print("\n[SOS] Loading utilities...")
	local Constants = Main.loadModule("constants", MODULES.constants)
	local UIUtils = Main.loadModule("ui", MODULES.ui)
	local SettingsUtils = Main.loadModule("settings", MODULES.settings)
	local ChatUtils = Main.loadModule("chat", MODULES.chat)
	local PlayerUtils = Main.loadModule("player", MODULES.player)

	if not Constants or not UIUtils then
		warn("[SOS] Critical utilities failed to load. Aborting.")
		return
	end

	-- Load modules
	print("\n[SOS] Loading modules...")
	local HUD = Main.loadModule("hud", MODULES.hud)
	local Leaderboard = Main.loadModule("leaderboard", MODULES.leaderboard)
	local TagSystem = Main.loadModule("tagsystem", MODULES.tagsystem)

	-- Initialize modules
	print("\n[SOS] Initializing modules...")

	if HUD and HUD.init then
		local success, err = pcall(function()
			HUD.init()
		end)
		if not success then
			warn("[SOS] HUD.init() failed:", err)
		end
	else
		warn("[SOS] HUD module or HUD.init() not found!")
	end

	if Leaderboard and Leaderboard.init then
		pcall(function()
			Leaderboard.init()
		end)
	end

	if TagSystem and TagSystem.init then
		pcall(function()
			TagSystem.init()
		end)
	end

	print("\n===========================================")
	print("   SOS Script Loaded Successfully!")
	print("===========================================")
end

-- Auto-initialize
Main.init()

return Main
