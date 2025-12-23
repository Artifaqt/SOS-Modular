# SOS Modular Script System

A modular, GitHub-hosted Roblox executor script with clean architecture and easy maintenance.

## 📁 Project Structure

```
SOS-Modular/
├── loader_executor.lua     # Entry point - run this in your executor
├── main.lua               # Orchestrator - loads all modules
├── modules/               # Feature modules
│   ├── hud.lua           # Main HUD system (flight, animations, camera)
│   ├── leaderboard.lua   # Custom player leaderboard
│   └── tagsystem.lua     # SOS tags activation system
└── utils/                # Shared utilities
    ├── constants.lua     # Shared constants, themes, configs
    ├── ui.lua            # UI helper functions
    ├── settings.lua      # Settings save/load system
    ├── chat.lua          # Chat utilities
    └── player.lua        # Player utilities
```

## 🚀 Setup Instructions

### Step 1: Upload to GitHub

1. Create a new GitHub repository (or use an existing one)
2. Make sure your repository is **PUBLIC**
3. Upload the entire `SOS-Modular` folder structure to your repository
4. Note your repository URL

### Step 2: Update URLs

You need to update the GitHub URLs in several files:

#### 1. **loader_executor.lua**
Replace `YOUR_USERNAME/YOUR_REPO` with your actual GitHub info:
```lua
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/SOS-Modular/main.lua"
```

#### 2. **main.lua**
Replace the base URL:
```lua
local GITHUB_BASE_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/SOS-Modular"
```

#### 3. **All utility files** (utils/*.lua)
Replace `YOUR_GITHUB_RAW_URL` in:
- utils/ui.lua
- utils/player.lua

#### 4. **All module files** (modules/*.lua)
Replace `YOUR_GITHUB_RAW_URL` in:
- modules/leaderboard.lua
- modules/tagsystem.lua
- modules/hud.lua

### Step 3: Test the URL

Before running in executor, test your URL in a browser:
```
https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/SOS-Modular/main.lua
```

If you see the Lua code, your URL is correct! ✅

### Step 4: Run in Executor

1. Copy the entire contents of `loader_executor.lua`
2. Paste it into your Roblox executor
3. Execute!

## 🎮 Usage

### Hotkeys
- **H** - Toggle HUD Menu
- **F** - Toggle Flight
- **Tab** - Toggle Leaderboard
- **CapsLock** - Switch between custom/default leaderboard

### Tag System
- Broadcast SOS: Bottom-left panel (owners/special users only)
- Activation marker: 𖺗
- Reply marker: ¬

### Leaderboard Features
- Click player entry to see options
- Teleport to player
- Send friend request
- View avatar
- Mute voice chat

## 🔧 Customization

### Adding Custom Roles

Edit `utils/constants.lua`:

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
```

### Modifying Theme

Edit `utils/constants.lua` to change colors:

```lua
Constants.THEME = {
    GlassTop = Color3.fromRGB(18, 18, 22),
    Red = Color3.fromRGB(200, 40, 40),
    Text = Color3.fromRGB(245, 245, 245),
    -- etc...
}
```

## 📝 Development Notes

### HUD Module (modules/hud.lua)

The current `hud.lua` is a **template**. You need to:
1. Take your existing `.lua` file (main HUD script)
2. Refactor it into the `hud.lua` module structure
3. Use the utilities we've created (UIUtils, Constants, etc.)
4. Follow the same pattern as the leaderboard and tagsystem modules

### Adding New Modules

1. Create a new file in `modules/` folder
2. Load utilities at the top:
```lua
local UIUtils = loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL/utils/ui.lua"))()
local Constants = loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL/utils/constants.lua"))()
```
3. Create a table for your module:
```lua
local MyModule = {}
```
4. Add an init function:
```lua
function MyModule.init()
    -- Your initialization code
end
```
5. Return the module:
```lua
return MyModule
```
6. Add it to `main.lua` in the MODULES table

### Benefits of This Structure

✅ **Easy Updates** - Change one file, push to GitHub, users reload
✅ **Modular** - Each feature is separate and maintainable
✅ **Reusable** - Utilities can be shared across modules
✅ **Organized** - Clear separation of concerns
✅ **Scalable** - Easy to add new features

## 🐛 Troubleshooting

### "Failed to fetch main.lua from GitHub"
- Check your GitHub URL is correct
- Ensure repository is PUBLIC
- Verify the file path matches your repo structure

### "Module failed to load"
- Check all URLs are updated with your GitHub info
- Verify all files are uploaded to GitHub
- Check for typos in file names (case-sensitive!)

### "YOUR_GITHUB_RAW_URL" appearing in errors
- You forgot to update the URLs in utility/module files
- Replace ALL instances of `YOUR_GITHUB_RAW_URL` with your actual URL

## 📦 Original Files

Your original files are preserved:
- `.lua` - Original main HUD script
- `BR05.lua` - Original leaderboard script
- `BR05TagSystem.lua` - Original tag system script

You can reference these when refactoring `modules/hud.lua`.

## 🔄 Updating the Script

1. Edit files in your GitHub repository
2. Commit changes
3. Users just need to re-run `loader_executor.lua` in their executor
4. No need to distribute new files!

## 📞 Support

If you encounter issues:
1. Check all URLs are updated correctly
2. Verify files are uploaded to GitHub
3. Test URLs in browser before using in executor
4. Check executor console for error messages

---

**Made with ❤️ for the SOS community**
