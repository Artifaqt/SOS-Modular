# SOS Modular Script System

A modular, GitHub-hosted Roblox executor script with clean dependency injection architecture, automatic cleanup on re-execution, and easy maintenance.

## ✨ Features

- ✅ **Centralized Loading** - All external links in one place ([main.lua](main.lua))
- ✅ **Dependency Injection** - Modules don't self-load, cleaner architecture
- ✅ **Re-execution Cleanup** - Run the script multiple times without conflicts or performance degradation
- ✅ **Modular Design** - Easy to maintain and extend
- ✅ **GitHub Hosted** - Update once, users auto-reload
- ✅ **Full Featured** - HUD, Flight, Custom Leaderboard, Tag System

---

## 📁 Project Structure

```
SOS-Modular/
├── .gitignore                   # Git ignore rules
├── README.md                    # This file
├── loader_executor.lua          # Entry point - run this in your executor
├── main.lua                     # Central orchestrator - loads & wires all modules
│
├── modules/                     # Feature modules (no internal links)
│   ├── hud.lua                 # Main HUD system orchestrator
│   ├── hud/                    # HUD sub-modules
│   │   ├── data.lua           # Data structures
│   │   ├── ui_builder.lua     # UI components
│   │   ├── lighting.lua       # Lighting effects
│   │   ├── animations.lua     # Animation system
│   │   ├── flight.lua         # Flight physics
│   │   ├── camera.lua         # Camera controls
│   │   ├── player.lua         # Player modifications
│   │   └── ui_pages.lua       # Menu pages
│   ├── leaderboard.lua         # Custom player leaderboard
│   └── tagsystem.lua           # SOS tags activation system
│
└── utils/                       # Shared utilities (no internal links)
    ├── constants.lua            # Shared constants, themes, configs
    ├── ui.lua                   # UI helper functions
    ├── settings.lua             # Settings save/load system
    ├── chat.lua                 # Chat utilities
    └── player.lua               # Player utilities
```

---

## 🏗️ Architecture

### Dependency Injection Pattern

**All external links live in [main.lua](main.lua) only.**

Modules expose `init(deps)` functions and receive their dependencies:

```lua
-- ❌ OLD WAY (self-loading, creates conflicts on re-execution)
local Constants = loadstring(game:HttpGet("https://..."))()

-- ✅ NEW WAY (dependency injection)
function Module.init(deps)
    Constants = deps.Constants  -- Injected by main.lua
end
```

### Re-execution Cleanup

When the script is re-executed, it automatically:
1. Finds previous runtime in `_G.__SOS_RUNTIME`
2. Calls `cleanup()` on all modules
3. Disconnects all connections
4. Destroys all GUIs
5. Stops all background loops
6. Clears registry and starts fresh

**Result**: You can re-run the script as many times as you want without relaunching Roblox. Perfect for development and updates!

---

## 🚀 Setup Instructions

### Step 1: Upload to GitHub

1. Create a new GitHub repository (or use an existing one)
2. Make sure your repository is **PUBLIC**
3. Upload the entire `SOS-Modular` folder structure to your repository
4. Note your repository URL

### Step 2: Update URLs

**You only need to update ONE file: [main.lua](main.lua)**

Open `main.lua` and replace the base URL (line 47):

```lua
-- BEFORE
local GITHUB_BASE_URL = "https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main"

-- AFTER
local GITHUB_BASE_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/refs/heads/main"
```

**That's it!** All modules are loaded from this one URL.

### Step 3: Update Loader (Optional)

If you want to use a different loader URL, update `loader_executor.lua` (line ~5):

```lua
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/refs/heads/main/main.lua"
```

### Step 4: Test the URL

Before running in executor, test your URL in a browser:
```
https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/refs/heads/main/main.lua
```

If you see the Lua code, your URL is correct! ✅

### Step 5: Run in Executor

1. Copy the entire contents of `loader_executor.lua`
2. Paste it into your Roblox executor
3. Execute!

---

## 🎮 Usage

### Hotkeys
- **H** - Toggle HUD Menu
- **F** - Toggle Flight
- **Tab** - Toggle Leaderboard
- **CapsLock** - Switch between custom/default leaderboard

### HUD Features
- Flight system with mobile support
- Custom animations (float, fly, custom IDs)
- Camera controls (FOV, shift lock)
- Speed controls
- Lighting effects
- FPS counter

### Tag System
- Broadcast SOS: Bottom-left panel (owners/special users only)
- Activation marker: 𖺗
- Reply marker: ¬
- Auto-tags for SOS users, owners, testers, sins, OGs, custom roles
- Click tags to teleport behind player

### Leaderboard Features
- Click player entry to see options
- Teleport to player
- Send friend request (requires CoreModule)
- View avatar
- Mute/unmute voice chat
- Friend icons
- Draggable, resizable
- Special styling for owners

---

## 🔧 Customization

### Adding Custom Roles

Edit [utils/constants.lua](utils/constants.lua):

```lua
-- Add owner
Constants.OwnerUserIds = {
    [YOUR_USER_ID] = true,
}

-- Add custom tags
Constants.CustomTags = {
    [USER_ID] = { TagText = "VIP", Color = Color3.fromRGB(255, 215, 0) },
}

-- Add Sin profiles
Constants.SinProfiles = {
    [USER_ID] = { SinName = "Custom", Color = Color3.fromRGB(255, 0, 0) },
}

-- Add OG profiles
Constants.OgProfiles = {
    [USER_ID] = { OgName = "OG Player", Color = Color3.fromRGB(100, 200, 255) },
}
```

### Modifying Theme

Edit [utils/constants.lua](utils/constants.lua) to change colors:

```lua
Constants.THEME = {
    GlassTop = Color3.fromRGB(18, 18, 22),
    Red = Color3.fromRGB(200, 40, 40),
    Text = Color3.fromRGB(245, 245, 245),
    -- etc...
}
```

### Adding Flight Animation IDs

Edit [utils/constants.lua](utils/constants.lua):

```lua
Constants.DEFAULT_FLOAT_ID = "rbxassetid://YOUR_ANIMATION_ID"
Constants.DEFAULT_FLY_ID = "rbxassetid://YOUR_ANIMATION_ID"
```

---

## 🔄 Updating the Script

### For Developers (You)

1. Edit files in your GitHub repository
2. Commit and push changes
3. Changes are live immediately!

### For Users

**Option 1: Re-execute** (Recommended)
- Just run the script again in your executor
- Cleanup system handles everything automatically
- No need to rejoin game!

**Option 2: Rejoin Game**
- Works too, but re-execution is faster

---

## 🛠️ Adding New Modules

### 1. Create Module File

Create `modules/your_module.lua`:

```lua
local YourModule = {}

-- Connection tracking for cleanup
YourModule.__connections = {}

-- Dependencies (injected by main.lua)
local Constants, UIUtils

-- Init function
function YourModule.init(deps)
    deps = deps or {}
    Constants = deps.Constants
    UIUtils = deps.UIUtils

    -- Your initialization code
    local conn = game:GetService("Players").PlayerAdded:Connect(function(player)
        -- ...
    end)
    table.insert(YourModule.__connections, conn)
end

-- Cleanup function
function YourModule.cleanup()
    for _, c in ipairs(YourModule.__connections) do
        pcall(function() c:Disconnect() end)
    end
    YourModule.__connections = {}

    -- Destroy your GUIs, etc.
end

return YourModule
```

### 2. Add to main.lua

Add your module URL to `MODULES` table:
```lua
local MODULES = {
    -- ... existing modules ...
    your_module = GITHUB_BASE_URL .. "/modules/your_module.lua",
}
```

Load and initialize:
```lua
local YourModule = Main.loadModule("your_module", MODULES.your_module)
RUNTIME.modules["your_module"] = YourModule

if YourModule and YourModule.init then
    YourModule.init({
        Constants = Constants,
        UIUtils = UIUtils,
        -- ... other dependencies
    })
end
```

### 3. Connection Tracking Rules

**Always track connections:**
```lua
local conn = something:Connect(function() ... end)
table.insert(ModuleName.__connections, conn)
```

**For spawn() loops:**
```lua
spawn(function()
    while condition and not ModuleName.__cleanupRequested do
        -- work
        if ModuleName.__cleanupRequested then break end
    end
end)
```

---

## 🐛 Troubleshooting

### "Failed to fetch main.lua from GitHub"
- Check your GitHub URL is correct
- Ensure repository is PUBLIC
- Verify the file path matches your repo structure
- Try accessing URL directly in browser

### "Module failed to load"
- Check console output for specific module name
- Verify all files are uploaded to GitHub
- Check for typos in file names (case-sensitive!)
- Make sure main.lua GITHUB_BASE_URL is correct

### Performance Degradation After Multiple Runs
- **This should not happen anymore!** Re-execution cleanup prevents this.
- If you still experience issues, check console for cleanup errors

### Script Conflicts When Re-executing
- **This should not happen anymore!** Cleanup disconnects all old connections.
- If you experience duplicate inputs or tags, report as a bug

---

## 📚 Architecture Benefits

✅ **Single Source of Truth** - All URLs in main.lua
✅ **No Circular Dependencies** - Clean dependency flow
✅ **Easy Testing** - Modules can be tested in isolation
✅ **Re-execution Safe** - Cleanup prevents conflicts
✅ **Performance Stable** - No connection/loop leaks
✅ **Maintainable** - Clear module boundaries
✅ **Scalable** - Easy to add features

---

## 📊 File Checklist

Before uploading to GitHub, make sure these files exist:

**Required Files:**
- ✅ `loader_executor.lua` - Script entry point
- ✅ `main.lua` - Central orchestrator
- ✅ `README.md` - Documentation

**Utils Folder:**
- ✅ `utils/constants.lua`
- ✅ `utils/ui.lua`
- ✅ `utils/settings.lua`
- ✅ `utils/chat.lua`
- ✅ `utils/player.lua`

**Modules Folder:**
- ✅ `modules/hud.lua`
- ✅ `modules/leaderboard.lua`
- ✅ `modules/tagsystem.lua`

**HUD Sub-modules:**
- ✅ `modules/hud/data.lua`
- ✅ `modules/hud/ui_builder.lua`
- ✅ `modules/hud/lighting.lua`
- ✅ `modules/hud/animations.lua`
- ✅ `modules/hud/flight.lua`
- ✅ `modules/hud/camera.lua`
- ✅ `modules/hud/player.lua`
- ✅ `modules/hud/ui_pages.lua`

**Optional (can ignore):**
- `.gitignore` - Keeps local files private
- `SOS-non-Modular/` - Original reference files (ignored by git)

---

## 📊 System Requirements

- **Executor**: Any modern Roblox executor with HttpGet support
- **Optional**: CoreModule for friend requests (leaderboard feature)
- **Internet**: Required for loading from GitHub

---

## 🔐 Security Notes

- All scripts are visible in this public repository
- No obfuscation, fully readable code
- Review code before executing (as you should with any script)
- GitHub URLs use HTTPS

---

## 🎯 Current Version

**v5.5** - Re-execution cleanup fully implemented

### Recent Changes
- ✅ Centralized all external links in main.lua
- ✅ Implemented dependency injection architecture
- ✅ Added re-execution cleanup system
- ✅ Fixed GUI location bugs
- ✅ Added connection tracking to all modules
- ✅ Added spawn() loop cleanup flags
- ✅ Performance stable across multiple re-executions

---

## 📞 Support

If you encounter issues:
1. Check all URLs are updated correctly in main.lua
2. Verify files are uploaded to GitHub and public
3. Test main.lua URL in browser before using in executor
4. Check executor console for error messages
5. Review technical documentation in this repo

---

**Made with ❤️ for the SOS community**

*Powered by dependency injection and clean architecture*
