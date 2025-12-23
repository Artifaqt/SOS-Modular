-- loader_executor.lua
-- Entry point for executor - loads main.lua from GitHub

-- ============================================
-- CONFIGURATION
-- ============================================
-- UPDATE THIS WITH YOUR GITHUB RAW URL
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/Og%20Files/main.lua"

-- ============================================
-- VERSION INFO
-- ============================================
local VERSION = "1.0.0"
local SCRIPT_NAME = "SOS Modular Script"

-- ============================================
-- LOADING SCREEN
-- ============================================
print("===========================================")
print(string.format("  %s v%s", SCRIPT_NAME, VERSION))
print("===========================================")
print("\nLoading from GitHub...")
print("URL:", GITHUB_RAW_URL)
print("")

-- ============================================
-- LOAD MAIN SCRIPT
-- ============================================
local success, result = pcall(function()
	return game:HttpGet(GITHUB_RAW_URL)
end)

if not success then
	warn("[SOS] Failed to fetch main.lua from GitHub!")
	warn("[SOS] Error:", result)
	warn("[SOS] Please check:")
	warn("  1. Your GitHub URL is correct")
	warn("  2. The repository is public or you have access")
	warn("  3. The file path is correct")
	return
end

-- ============================================
-- EXECUTE MAIN SCRIPT
-- ============================================
print("[SOS] Downloaded main.lua successfully!")
print("[SOS] Executing main script...\n")

local executeSuccess, executeError = pcall(function()
	loadstring(result)()
end)

if not executeSuccess then
	warn("[SOS] Failed to execute main.lua!")
	warn("[SOS] Error:", executeError)
else
	print("\n[SOS] Script execution completed!")
end

-- ============================================
-- USAGE INSTRUCTIONS (printed to console)
-- ============================================
print("\n===========================================")
print("           USAGE INSTRUCTIONS")
print("===========================================")
print("\nHotkeys:")
print("  H - Toggle HUD Menu")
print("  F - Toggle Flight")
print("  Tab - Toggle Leaderboard")
print("\nFor updates, reload the script from executor!")
print("===========================================\n")
