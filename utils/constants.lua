-- utils/constants.lua
-- Shared constants, themes, and configurations

local Constants = {}

--------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------
Constants.THEME = {
	GlassTop = Color3.fromRGB(18, 18, 22),
	GlassMid = Color3.fromRGB(10, 10, 12),
	GlassBot = Color3.fromRGB(6, 6, 8),

	Red = Color3.fromRGB(200, 40, 40),

	Text = Color3.fromRGB(245, 245, 245),
	TextMuted = Color3.fromRGB(200, 200, 200),

	Panel = Color3.fromRGB(10, 10, 12),
	PanelTrans = 0.18,

	Entry = Color3.fromRGB(16, 16, 20),
	EntryTrans = 0.22,

	EntryHover = Color3.fromRGB(24, 24, 30),

	Button = Color3.fromRGB(16, 16, 20),
	ButtonHover = Color3.fromRGB(24, 24, 30),
}

--------------------------------------------------------------------
-- ROLE COLORS
--------------------------------------------------------------------
Constants.ROLE_COLOR = {
	Normal = Color3.fromRGB(120, 190, 235),
	Owner  = Color3.fromRGB(255, 255, 80),
	Tester = Color3.fromRGB(60, 255, 90),
	Sin    = Color3.fromRGB(235, 70, 70),
	OG     = Color3.fromRGB(160, 220, 255),
	Custom = Color3.fromRGB(245, 245, 245),
}

--------------------------------------------------------------------
-- OWNER & SPECIAL USERS
--------------------------------------------------------------------
Constants.OwnerNames = {
	["deniskraily"] = true,
}

Constants.OwnerUserIds = {
	[433636433] = true,
	[196988708] = true,
}

Constants.TesterUserIds = {}

Constants.SinProfiles = {
	[2630250935] = { SinName = "Cinna" },
	[105995794]  = { SinName = "Lettuce" },
	[138975737]  = { SinName = "Music" },
	[9159968275] = { SinName = "Music" },
	[4659279349] = { SinName = "Trial" },
	[4495710706] = { SinName = "Games Design" },
	[1575141882] = { SinName = "Heart", Color = Color3.fromRGB(255, 120, 210) },
	[118170824]  = { SinName = "Security" },
	[7870252435] = { SinName = "Security" },
	[7452991350] = { SinName = "XTCY", Color = Color3.fromRGB(0, 220, 0) },
	[3600244479] = { SinName = "PAWS", Color = Color3.fromRGB(180, 1, 64) },
	[8956134409] = { SinName = "Cars", Color = Color3.fromRGB(0, 255, 0) },
}

Constants.OgProfiles = {
	[8956134409] = { OGName = "BR05", Color = Color3.fromRGB(255, 0, 0) }
}

Constants.CustomTags = {}

--------------------------------------------------------------------
-- SOS TAGS CONFIG
--------------------------------------------------------------------
Constants.SOS_ACTIVATE_MARKER = "𖺗"
Constants.SOS_REPLY_MARKER = "¬"
Constants.SOS_JOINER_MARKER = "•"

Constants.AK_MARKER_1 = "؍؍؍"
Constants.AK_MARKER_2 = "؍"

Constants.TAG_W, Constants.TAG_H = 144, 36
Constants.TAG_OFFSET_Y = 3

Constants.ORB_SIZE = 18
Constants.ORB_OFFSET_Y = 3.35

--------------------------------------------------------------------
-- OWNER ARRIVAL
--------------------------------------------------------------------
Constants.OWNER_ARRIVAL_TEXT = "He has Arrived"
Constants.OWNER_ARRIVAL_SOUND_ID = "rbxassetid://136954512002069"

--------------------------------------------------------------------
-- SPEED TRAILS
--------------------------------------------------------------------
Constants.TRAIL_FOLDER_NAME = "SOS_RunTrails"
Constants.TRAIL_MAX_STUDS = 20
Constants.TRAIL_LEN_PER_SPEED = 0.7
Constants.TRAIL_MIN_SPEED = 1.5

--------------------------------------------------------------------
-- SOUNDS
--------------------------------------------------------------------
Constants.TELEPORT_SOUND_ID = "rbxassetid://8968843545"
Constants.INTRO_SOUND_ID = "rbxassetid://1843492223"
Constants.BUTTON_CLICK_SOUND_ID = "rbxassetid://111174530730534"
Constants.BUTTON_CLICK_VOLUME = 0.6

--------------------------------------------------------------------
-- FLIGHT CONFIG
--------------------------------------------------------------------
Constants.DEFAULT_FLOAT_ID = "rbxassetid://88138077358201"
Constants.DEFAULT_FLY_ID = "rbxassetid://131217573719045"

Constants.MOBILE_FLY_POS = UDim2.new(1, -170, 1, -190)
Constants.MOBILE_FLY_SIZE = UDim2.new(0, 140, 0, 60)

Constants.DISCORD_LINK = "https://discord.gg/cacg7kvX"

--------------------------------------------------------------------
-- MISC
--------------------------------------------------------------------
Constants.MICUP_PLACE_IDS = {
	["6884319169"] = true,
	["15546218972"] = true,
}

Constants.VIP_GAMEPASSES = {
	951459548,
	28828491,
}

return Constants
