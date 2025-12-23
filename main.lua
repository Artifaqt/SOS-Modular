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
	coremodule = "https://pastebin.com/raw/DSAwuqrC",

	-- Main Modules
	hud = GITHUB_BASE_URL .. "/modules/hud.lua",
	leaderboard = GITHUB_BASE_URL .. "/modules/leaderboard.lua",
	tagsystem = GITHUB_BASE_URL .. "/modules/tagsystem.lua",

	-- HUD Sub-Modules
	hud_data = GITHUB_BASE_URL .. "/modules/hud/data.lua",
	hud_ui_builder = GITHUB_BASE_URL .. "/modules/hud/ui_builder.lua",
	hud_lighting = GITHUB_BASE_URL .. "/modules/hud/lighting.lua",
	hud_animations = GITHUB_BASE_URL .. "/modules/hud/animations.lua",
	hud_flight = GITHUB_BASE_URL .. "/modules/hud/flight.lua",
	hud_camera = GITHUB_BASE_URL .. "/modules/hud/camera.lua",
	hud_player = GITHUB_BASE_URL .. "/modules/hud/player.lua",
	hud_ui_pages = GITHUB_BASE_URL .. "/modules/hud/ui_pages.lua",
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
	print("       SOS Script Loading System v4.6")
	print("===========================================")

	-- Load utilities first
	print("\n[SOS] Loading utilities...")
	local Constants = Main.loadModule("constants", MODULES.constants)
	local UIUtils = Main.loadModule("ui", MODULES.ui)
	local SettingsUtils = Main.loadModule("settings", MODULES.settings)
	local ChatUtils = Main.loadModule("chat", MODULES.chat)
	local PlayerUtils = Main.loadModule("player", MODULES.player)
	local CoreModule = Main.loadModule("coremodule", MODULES.coremodule)

	
	-- Initialize utils that require dependencies
	if UIUtils and UIUtils.init then
		local ok, err = pcall(function() UIUtils.init({Constants = Constants}) end)
		if not ok then
			warn("[SOS] UIUtils.init() failed:", err)
		end
	end
	if PlayerUtils and PlayerUtils.init then
		local ok, err = pcall(function() PlayerUtils.init({Constants = Constants}) end)
		if not ok then
			warn("[SOS] PlayerUtils.init() failed:", err)
		end
	end

if not Constants or not UIUtils then
		warn("[SOS] Critical utilities failed to load. Aborting.")
		return
	end

	-- Load HUD sub-modules
	print("\n[SOS] Loading HUD sub-modules...")
	local HUD_Data = Main.loadModule("hud_data", MODULES.hud_data)
	local HUD_UIBuilder = Main.loadModule("hud_ui_builder", MODULES.hud_ui_builder)
	local HUD_Lighting = Main.loadModule("hud_lighting", MODULES.hud_lighting)
	local HUD_Animations = Main.loadModule("hud_animations", MODULES.hud_animations)
	local HUD_Flight = Main.loadModule("hud_flight", MODULES.hud_flight)
	local HUD_Camera = Main.loadModule("hud_camera", MODULES.hud_camera)
	local HUD_Player = Main.loadModule("hud_player", MODULES.hud_player)
	local HUD_UIPages = Main.loadModule("hud_ui_pages", MODULES.hud_ui_pages)

	-- Load main modules
	print("\n[SOS] Loading main modules...")
	local HUD = Main.loadModule("hud", MODULES.hud)
	local Leaderboard = Main.loadModule("leaderboard", MODULES.leaderboard)
	local TagSystem = Main.loadModule("tagsystem", MODULES.tagsystem)

	-- Initialize modules
	print("\n[SOS] Initializing modules...")

	if HUD and HUD.init then
		local success, err = pcall(function()
			-- Pass sub-modules to HUD
			HUD.init({
				Data = HUD_Data,
				UIBuilder = HUD_UIBuilder,
				LightingModule = HUD_Lighting,
				AnimationsModule = HUD_Animations,
				FlightModule = HUD_Flight,
				CameraModule = HUD_Camera,
				PlayerModule = HUD_Player,
				UIPagesModule = HUD_UIPages,
				Constants = Constants,
				Settings = SettingsUtils,
			})
		end)
		if not success then
			warn("[SOS] HUD.init() failed:", err)
		end
	else
		warn("[SOS] HUD module or HUD.init() not found!")
	end

	if Leaderboard and Leaderboard.init then
		local ok, err = pcall(function()
			Leaderboard.init({UIUtils = UIUtils, Constants = Constants, CoreModule = CoreModule})
		end)
		if not ok then
			warn("[SOS] Leaderboard.init() failed:", err)
		end
	end

	if TagSystem and TagSystem.init then
		local ok, err = pcall(function()
			TagSystem.init({UIUtils = UIUtils, Constants = Constants, ChatUtils = ChatUtils, PlayerUtils = PlayerUtils})
		end)
		if not ok then
			warn("[SOS] TagSystem.init() failed:", err)
		end
	end

	print("\n===========================================")
	print("   SOS Script Loaded Successfully!")
	print("===========================================")
end

-- Auto-initialize
Main.init()

return Main