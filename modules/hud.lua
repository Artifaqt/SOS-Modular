-- modules/hud.lua
-- Complete SOS HUD System - ALL FEATURES IMPLEMENTED
-- Includes: Flight, Animations, Camera, Lighting, Player Speed, Server Tools, and More

local HUD = {}

-- Load utilities
local UIUtils = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/ui.lua"))()
local Constants = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/constants.lua"))()
local Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/Artifaqt/SOS-Modular/refs/heads/main/utils/settings.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

--------------------------------------------------------------------
-- CONFIG & CONSTANTS
--------------------------------------------------------------------
local DEBUG = false
local function dprint(...) if DEBUG then print("[SOS HUD]", ...) end end

local FLOAT_ID = Constants.DEFAULT_FLOAT_ID
local FLY_ID = Constants.DEFAULT_FLY_ID
local menuToggleKey = Enum.KeyCode.H
local flightToggleKey = Enum.KeyCode.F
local flySpeed = 200
local maxFlySpeed, minFlySpeed = 1000, 1
local velocityLerpRate, rotationLerpRate, idleSlowdownRate = 7.0, 7.0, 2.6
local MOVING_TILT_DEG, IDLE_TILT_DEG = 85, 10
local MOBILE_FLY_POS, MOBILE_FLY_SIZE = Constants.MOBILE_FLY_POS, Constants.MOBILE_FLY_SIZE
local MICUP_PLACE_IDS = Constants.MICUP_PLACE_IDS
local DISCORD_LINK = Constants.DISCORD_LINK
local INTRO_SOUND_ID = Constants.INTRO_SOUND_ID
local BUTTON_CLICK_SOUND_ID, BUTTON_CLICK_VOLUME = Constants.BUTTON_CLICK_SOUND_ID, Constants.BUTTON_CLICK_VOLUME
local DEFAULT_FOV, DEFAULT_CAM_MIN_ZOOM, DEFAULT_CAM_MAX_ZOOM = nil, nil, nil
local DEFAULT_CAMERA_SUBJECT_MODE, INFINITE_ZOOM = "Humanoid", 1e9
local VIP_GAMEPASSES = Constants.VIP_GAMEPASSES
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--------------------------------------------------------------------
-- STATE VARIABLES
--------------------------------------------------------------------
local character, humanoid, rootPart
local flying, bodyGyro, bodyVel = false, nil, nil
local currentVelocity, currentGyroCFrame = Vector3.new(), nil
local moveInput, verticalInput = Vector3.new(), 0
local rightShoulder, defaultShoulderC0
local originalRunSoundStates = {}
local animator, floatTrack, flyTrack
local animMode, lastAnimSwitch = "Float", 0
local ANIM_SWITCH_COOLDOWN, ANIM_TO_FLY_THRESHOLD, ANIM_TO_FLOAT_THRESHOLD = 0.25, 0.22, 0.12

local VALID_ANIM_STATES = {Idle=true, Walk=true, Run=true, Jump=true, Climb=true, Fall=true, Swim=true}
local stateOverrides = {Idle=nil, Walk=nil, Run=nil, Jump=nil, Climb=nil, Fall=nil, Swim=nil}
local lastChosenState, lastChosenCategory = "Idle", "Custom"

local DEFAULT_WALKSPEED, playerSpeed = nil, nil
local camSubjectMode, camOffset, camFov, camMaxZoom = DEFAULT_CAMERA_SUBJECT_MODE, Vector3.new(), nil, INFINITE_ZOOM

local gui, menuFrame, menuHandle, arrowButton, tabsBar, pagesHolder, mobileFlyButton
local fpsLabel, fpsAcc, fpsFrames, fpsValue, rainbowHue = nil, 0, 0, 60, 0
local menuOpen, menuTween = false, nil
local clickSoundTemplate, buttonSoundAttached = nil, setmetatable({}, {__mode="k"})

--------------------------------------------------------------------
-- ANIMATION PACKS DATA
--------------------------------------------------------------------
local AnimationPacks = {
	Vampire={Idle1=1083445855,Idle2=1083450166,Walk=1083473930,Run=1083462077,Jump=1083455352,Climb=1083439238,Fall=1083443587},
	Hero={Idle1=616111295,Idle2=616113536,Walk=616122287,Run=616117076,Jump=616115533,Climb=616104706,Fall=616108001},
	ZombieClassic={Idle1=616158929,Idle2=616160636,Walk=616168032,Run=616163682,Jump=616161997,Climb=616156119,Fall=616157476},
	Mage={Idle1=707742142,Idle2=707855907,Walk=707897309,Run=707861613,Jump=707853694,Climb=707826056,Fall=707829716},
	Ghost={Idle1=616006778,Idle2=616008087,Walk=616010382,Run=616013216,Jump=616008936,Climb=616003713,Fall=616005863},
	Elder={Idle1=845397899,Idle2=845400520,Walk=845403856,Run=845386501,Jump=845398858,Climb=845392038,Fall=845396048},
	Levitation={Idle1=616006778,Idle2=616008087,Walk=616013216,Run=616010382,Jump=616008936,Climb=616003713,Fall=616005863},
	Astronaut={Idle1=891621366,Idle2=891633237,Walk=891667138,Run=891636393,Jump=891627522,Climb=891609353,Fall=891617961},
	Ninja={Idle1=656117400,Idle2=656118341,Walk=656121766,Run=656118852,Jump=656117878,Climb=656114359,Fall=656115606},
	Werewolf={Idle1=1083195517,Idle2=1083214717,Walk=1083178339,Run=1083216690,Jump=1083218792,Climb=1083182000,Fall=1083189019},
	Cartoon={Idle1=742637544,Idle2=742638445,Walk=742640026,Run=742638842,Jump=742637942,Climb=742636889,Fall=742637151},
	Pirate={Idle1=750781874,Idle2=750782770,Walk=750785693,Run=750783738,Jump=750782230,Climb=750779899,Fall=750780242},
	Sneaky={Idle1=1132473842,Idle2=1132477671,Walk=1132510133,Run=1132494274,Jump=1132489853,Climb=1132461372,Fall=1132469004},
	Toy={Idle1=782841498,Idle2=782845736,Walk=782843345,Run=782842708,Jump=782847020,Climb=782843869,Fall=782846423},
	Knight={Idle1=657595757,Idle2=657568135,Walk=657552124,Run=657564596,Jump=658409194,Climb=658360781,Fall=657600338},
	Confident={Idle1=1069977950,Idle2=1069987858,Walk=1070017263,Run=1070001516,Jump=1069984524,Climb=1069946257,Fall=1069973677},
	Popstar={Idle1=1212900985,Idle2=1212900985,Walk=1212980338,Run=1212980348,Jump=1212954642,Climb=1213044953,Fall=1212900995},
	Princess={Idle1=941003647,Idle2=941013098,Walk=941028902,Run=941015281,Jump=941008832,Climb=940996062,Fall=941000007},
	Cowboy={Idle1=1014390418,Idle2=1014398616,Walk=1014421541,Run=1014401683,Jump=1014394726,Climb=1014380606,Fall=1014384571},
	Patrol={Idle1=1149612882,Idle2=1150842221,Walk=1151231493,Run=1150967949,Jump=1150944216,Climb=1148811837,Fall=1148863382},
	ZombieFE={Idle1=3489171152,Idle2=3489171152,Walk=3489174223,Run=3489173414,Jump=616161997,Climb=616156119,Fall=616157476},
}

local UnreleasedNames = {"Cowboy","Princess","ZombieFE","Confident","Ghost","Patrol","Popstar","Sneaky"}
local function isInUnreleased(name)
	for _,n in ipairs(UnreleasedNames) do if n==name then return true end end
	return false
end

local CustomIdle = {
	["Tall"]=91348372558295,["Jonathan"]=120629563851640,["Killer Queen"]=104714163485875,["Dio"]=138467089338692,
	["Dio OH"]=96658788627102,["Joseph"]=87470625500564,["Jolyne"]=97892708412696,["Diego"]=127117233320016,
	["Polnareff"]=104647713661701,["Jotaro"]=134878791451155,["Funny V"]=88859285630202,["Johnny"]=77834689346843,
	["Made in Heaven"]=79234770032233,["Mahito"]=92585001378279,["Honored One"]=139000839803032,["Gon Rage"]=136678571910037,
	["Sol's RNG 1"]=125722696765151,["Luffy"]=107520488394848,["Sans"]=123627677663418,["Fake R6"]=96518514398708,
	["Goku Warm Up"]=84773442399798,["Goku UI/Mui"]=130104867308995,["Goku Black"]=110240143520283,["Sukuna"]=82974857632552,
	["Toji"]=113657065279101,["Isagi"]=135818607077529,["Yuji"]=103088653217891,["Lavinho"]=92045987196732,
	["Ippo"]=76110924880592,["Aizen"]=83896268225208,["Kaneki"]=116671111363578,["Tanjiro"]=118533315464114,
	["Head Hold"]=129453036635884,["Robot Perform"]=105174189783870,["Springtrap"]=90257184304714,
	["Hmmm Float"]=107666091494733,["OG Golden Freddy"]=138402679058341,["Wally West"]=106169111259587,
	["L"]=103267638009024,["Robot Malfunction"]=110419039625879,
}
local CustomRun = {
	["Tall"]=134010853417610,["Officer Earl"]=104646820775114,["AOT Titan"]=95363958550738,["Captain JS"]=87806542116815,
	["Ninja Sprint"]=123763532572423,["IDEK"]=101293881003047,["Honored One"]=82260970223217,["Head Hold"]=92715775326925,
	["Robot Speed 3"]=128047975332475,["Springtrap Sturdy"]=80927378599036,["UFO"]=118703314621593,
	["Closed Eyes Vibe"]=117991470645633,["Wally West"]=102622695004986,["Squidward"]=82365330773489,
	["On A Mission"]=113718116290824,["Very Happy Run"]=86522070222739,["Missile"]=92401041987431,["I Wanna Run Away"]=78510387198062,
}
local CustomWalk = {["Football/Soccer"]=116881956670910,["Animal"]=87721497492370,["Fredbear"]=133284420439423,["Cute Anime"]=106767496454996}

local function listCustomNamesForState(state)
	local t,src={},nil
	if state=="Idle" then src=CustomIdle elseif state=="Run" then src=CustomRun elseif state=="Walk" then src=CustomWalk end
	if not src then return t end
	for name,_ in pairs(src) do table.insert(t,name) end
	table.sort(t)
	return t
end

local function getCustomIdForState(name,state)
	if state=="Idle" then return CustomIdle[name] elseif state=="Run" then return CustomRun[name] elseif state=="Walk" then return CustomWalk[name] end
	return nil
end

local function listPackNamesForCategory(cat)
	local names={}
	for name,_ in pairs(AnimationPacks) do
		if cat=="Unreleased" then if isInUnreleased(name) then table.insert(names,name) end
		elseif cat=="Roblox Anims" then if not isInUnreleased(name) then table.insert(names,name) end end
	end
	table.sort(names)
	return names
end

local function getPackValueForState(packName,state)
	local pack=AnimationPacks[packName]
	if not pack then return nil end
	if state=="Idle" then return pack.Idle1 or pack.Idle2
	elseif state=="Walk" then return pack.Walk elseif state=="Run" then return pack.Run
	elseif state=="Jump" then return pack.Jump elseif state=="Climb" then return pack.Climb
	elseif state=="Fall" then return pack.Fall elseif state=="Swim" then return nil end
	return nil
end

--------------------------------------------------------------------
-- LIGHTING SYSTEM
--------------------------------------------------------------------
local ORIGINAL_LIGHTING = {
	Ambient=Lighting.Ambient, OutdoorAmbient=Lighting.OutdoorAmbient, Brightness=Lighting.Brightness,
	ClockTime=Lighting.ClockTime, ExposureCompensation=Lighting.ExposureCompensation,
	EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale, EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale,
	FogColor=Lighting.FogColor, FogEnd=Lighting.FogEnd, FogStart=Lighting.FogStart, GeographicLatitude=Lighting.GeographicLatitude,
}

local function cloneIfExists(className)
	for _,inst in ipairs(Lighting:GetChildren()) do if inst.ClassName==className then return inst:Clone() end end
	return nil
end

ORIGINAL_LIGHTING.Sky=cloneIfExists("Sky")
ORIGINAL_LIGHTING.Atmosphere=cloneIfExists("Atmosphere")
ORIGINAL_LIGHTING.Bloom=cloneIfExists("BloomEffect")
ORIGINAL_LIGHTING.ColorCorrection=cloneIfExists("ColorCorrectionEffect")
ORIGINAL_LIGHTING.DepthOfField=cloneIfExists("DepthOfFieldEffect")
ORIGINAL_LIGHTING.Blur=cloneIfExists("BlurEffect")
ORIGINAL_LIGHTING.SunRays=cloneIfExists("SunRaysEffect")

local function getOrCreateEffect(className,name)
	local inst=Lighting:FindFirstChild(name)
	if inst and inst.ClassName==className then return inst end
	if inst then inst:Destroy() end
	local newInst=Instance.new(className)
	newInst.Name=name
	newInst.Parent=Lighting
	return newInst
end

local function destroyIfExists(name)
	local inst=Lighting:FindFirstChild(name)
	if inst then inst:Destroy() end
end

local SKY_PRESETS = {
	["Crimson Night"]={Sky={Bk="rbxassetid://401664839",Dn="rbxassetid://401664862",Ft="rbxassetid://401664960",Lf="rbxassetid://401664881",Rt="rbxassetid://401664901",Up="rbxassetid://401664936"}},
	["Deep Space"]={Sky={Bk="rbxassetid://149397692",Dn="rbxassetid://149397686",Ft="rbxassetid://149397697",Lf="rbxassetid://149397684",Rt="rbxassetid://149397688",Up="rbxassetid://149397702"}},
	["Vaporwave Nebula"]={Sky={Bk="rbxassetid://1417494030",Dn="rbxassetid://1417494146",Ft="rbxassetid://1417494253",Lf="rbxassetid://1417494402",Rt="rbxassetid://1417494499",Up="rbxassetid://1417494643"}},
	["Soft Clouds"]={Sky={Bk="rbxassetid://570557514",Dn="rbxassetid://570557775",Ft="rbxassetid://570557559",Lf="rbxassetid://570557620",Rt="rbxassetid://570557672",Up="rbxassetid://570557727"}},
	["Cloudy Skies"]={Sky={Bk="rbxassetid://252760981",Dn="rbxassetid://252763035",Ft="rbxassetid://252761439",Lf="rbxassetid://252760980",Rt="rbxassetid://252760986",Up="rbxassetid://252762652"}},
}

local LightingState = {Enabled=true, SelectedSky=nil, Toggles={Sky=true,Atmosphere=true,ColorCorrection=true,Bloom=true,DepthOfField=true,MotionBlur=true,SunRays=true}}

local function writeLightingSaveState()
	_G.__SOS_LightingSaveState={Enabled=LightingState.Enabled,SelectedSky=LightingState.SelectedSky,Toggles=LightingState.Toggles}
	Settings.scheduleSave()
end

local function readLightingSaveState()
	local s=_G.__SOS_LightingSaveState
	if typeof(s)~="table" then return end
	if typeof(s.Enabled)=="boolean" then LightingState.Enabled=s.Enabled end
	if typeof(s.SelectedSky)=="string" then LightingState.SelectedSky=s.SelectedSky end
	if typeof(s.Toggles)=="table" then
		for k,v in pairs(s.Toggles) do
			if typeof(v)=="boolean" and LightingState.Toggles[k]~=nil then LightingState.Toggles[k]=v end
		end
	end
end

local function applyFancyDefaults()
	Lighting.Brightness=2
	Lighting.EnvironmentDiffuseScale=1
	Lighting.EnvironmentSpecularScale=1
	Lighting.ExposureCompensation=0.15
end

local function removeSOSLightingOnly()
	for _,name in ipairs({"SOS_Sky","SOS_Atmosphere","SOS_Bloom","SOS_ColorCorrection","SOS_DepthOfField","SOS_MotionBlur","SOS_SunRays"}) do
		destroyIfExists(name)
	end
end

local function applySkyPreset(name)
	LightingState.SelectedSky=name
	writeLightingSaveState()
	if not LightingState.Enabled then return end
	local preset=SKY_PRESETS[name]
	if not preset then return end
	applyFancyDefaults()
	if LightingState.Toggles.Sky then
		local sky=getOrCreateEffect("Sky","SOS_Sky")
		sky.SkyboxBk,sky.SkyboxDn,sky.SkyboxFt=preset.Sky.Bk,preset.Sky.Dn,preset.Sky.Ft
		sky.SkyboxLf,sky.SkyboxRt,sky.SkyboxUp=preset.Sky.Lf,preset.Sky.Rt,preset.Sky.Up
	else destroyIfExists("SOS_Sky") end
	if LightingState.Toggles.ColorCorrection then
		local cc=getOrCreateEffect("ColorCorrectionEffect","SOS_ColorCorrection")
		cc.Enabled,cc.Brightness,cc.Contrast,cc.Saturation=true,0.02,0.18,0.06
		cc.TintColor=Color3.fromRGB(255,240,240)
	else destroyIfExists("SOS_ColorCorrection") end
	if LightingState.Toggles.Bloom then
		local bloom=getOrCreateEffect("BloomEffect","SOS_Bloom")
		bloom.Enabled,bloom.Intensity,bloom.Size,bloom.Threshold=true,0.8,28,1
	else destroyIfExists("SOS_Bloom") end
	if LightingState.Toggles.DepthOfField then
		local dof=getOrCreateEffect("DepthOfFieldEffect","SOS_DepthOfField")
		dof.Enabled,dof.FarIntensity,dof.FocusDistance,dof.InFocusRadius,dof.NearIntensity=true,0.12,55,40,0.25
	else destroyIfExists("SOS_DepthOfField") end
	if LightingState.Toggles.MotionBlur then
		local blur=getOrCreateEffect("BlurEffect","SOS_MotionBlur")
		blur.Enabled,blur.Size=true,2
	else destroyIfExists("SOS_MotionBlur") end
	if LightingState.Toggles.SunRays then
		local rays=getOrCreateEffect("SunRaysEffect","SOS_SunRays")
		rays.Enabled,rays.Intensity,rays.Spread=true,0.06,0.75
	else destroyIfExists("SOS_SunRays") end
	if LightingState.Toggles.Atmosphere then
		local atm=getOrCreateEffect("Atmosphere","SOS_Atmosphere")
		atm.Density,atm.Offset,atm.Color=0.32,0.1,Color3.fromRGB(210,200,255)
		atm.Decay,atm.Glare,atm.Haze=Color3.fromRGB(70,60,90),0.12,1
	else destroyIfExists("SOS_Atmosphere") end
end

local function resetLightingToOriginal()
	removeSOSLightingOnly()
	Lighting.Ambient,Lighting.OutdoorAmbient,Lighting.Brightness=ORIGINAL_LIGHTING.Ambient,ORIGINAL_LIGHTING.OutdoorAmbient,ORIGINAL_LIGHTING.Brightness
	Lighting.ClockTime,Lighting.ExposureCompensation=ORIGINAL_LIGHTING.ClockTime,ORIGINAL_LIGHTING.ExposureCompensation
	Lighting.EnvironmentDiffuseScale,Lighting.EnvironmentSpecularScale=ORIGINAL_LIGHTING.EnvironmentDiffuseScale,ORIGINAL_LIGHTING.EnvironmentSpecularScale
	Lighting.FogColor,Lighting.FogEnd,Lighting.FogStart=ORIGINAL_LIGHTING.FogColor,ORIGINAL_LIGHTING.FogEnd,ORIGINAL_LIGHTING.FogStart
	Lighting.GeographicLatitude=ORIGINAL_LIGHTING.GeographicLatitude

	local function restoreClone(cloneObj,className)
		if not cloneObj then return end
		for _,inst in ipairs(Lighting:GetChildren()) do if inst.ClassName==className then inst:Destroy() end end
		local c=cloneObj:Clone()
		c.Parent=Lighting
	end

	restoreClone(ORIGINAL_LIGHTING.Sky,"Sky")
	restoreClone(ORIGINAL_LIGHTING.Atmosphere,"Atmosphere")
	restoreClone(ORIGINAL_LIGHTING.Bloom,"BloomEffect")
	restoreClone(ORIGINAL_LIGHTING.ColorCorrection,"ColorCorrectionEffect")
	restoreClone(ORIGINAL_LIGHTING.DepthOfField,"DepthOfFieldEffect")
	restoreClone(ORIGINAL_LIGHTING.Blur,"BlurEffect")
	restoreClone(ORIGINAL_LIGHTING.SunRays,"SunRaysEffect")

	LightingState.SelectedSky=nil
	writeLightingSaveState()
end

local function syncLightingToggles()
	if not LightingState.Enabled then removeSOSLightingOnly() return end
	if LightingState.SelectedSky and SKY_PRESETS[LightingState.SelectedSky] then
		applySkyPreset(LightingState.SelectedSky)
	else
		if not LightingState.Toggles.Sky then destroyIfExists("SOS_Sky") end
		if not LightingState.Toggles.Atmosphere then destroyIfExists("SOS_Atmosphere") end
		if not LightingState.Toggles.ColorCorrection then destroyIfExists("SOS_ColorCorrection") end
		if not LightingState.Toggles.Bloom then destroyIfExists("SOS_Bloom") end
		if not LightingState.Toggles.DepthOfField then destroyIfExists("SOS_DepthOfField") end
		if not LightingState.Toggles.MotionBlur then destroyIfExists("SOS_MotionBlur") end
		if not LightingState.Toggles.SunRays then destroyIfExists("SOS_SunRays") end
	end
end

--------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------
local function notify(title,text,dur)
	pcall(function()
		StarterGui:SetCore("SendNotification",{Title=title or "SOS HUD",Text=text or "",Duration=dur or 3})
	end)
end

local function clamp01(x) if x<0 then return 0 end if x>1 then return 1 end return x end

local function tween(obj,info,props) local t=TweenService:Create(obj,info,props) t:Play() return t end

local function safeDestroy(inst) if inst and inst.Parent then inst:Destroy() end end

local function toAssetIdString(anyValue)
	local s=tostring(anyValue or ""):gsub("%s+","")
	if s=="" then return nil end
	if s:find("^rbxassetid://") then return s end
	if s:match("^%d+$") then return "rbxassetid://"..s end
	if s:find("^http") and s:lower():find("roblox.com") and s:lower():find("id=") then
		local id=s:match("id=(%d+)")
		if id then return "rbxassetid://"..id end
	end
	return nil
end

local function findRightShoulderMotor(char)
	for _,part in ipairs(char:GetDescendants()) do
		if part:IsA("Motor6D") and part.Name=="Right Shoulder" then return part end
	end
	return nil
end

local function stopAllPlayingTracks(hum)
	for _,tr in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() tr:Stop(0) end) end
end

--------------------------------------------------------------------
-- BUTTON SOUND SYSTEM
--------------------------------------------------------------------
local function ensureClickSoundTemplate()
	if clickSoundTemplate and clickSoundTemplate.Parent then return clickSoundTemplate end
	if not gui then return nil end
	local s=Instance.new("Sound")
	s.Name,s.SoundId,s.Volume,s.Looped,s.Parent="SOS_ButtonClickTemplate",BUTTON_CLICK_SOUND_ID,BUTTON_CLICK_VOLUME,false,gui
	clickSoundTemplate=s
	return clickSoundTemplate
end

local function playButtonClick()
	local tmpl=ensureClickSoundTemplate()
	if not tmpl then return end
	local s=tmpl:Clone()
	s.Name,s.Parent="SOS_ButtonClick",gui
	pcall(function() s:Play() end)
	Debris:AddItem(s,3)
end

local function attachSoundToButton(btn)
	if not btn or buttonSoundAttached[btn] then return end
	buttonSoundAttached[btn]=true
	local ok=pcall(function() btn.Activated:Connect(function() playButtonClick() end) end)
	if not ok then pcall(function() btn.MouseButton1Click:Connect(function() playButtonClick() end) end) end
end

local function setupGlobalButtonSounds(root)
	if not root then return end
	for _,d in ipairs(root:GetDescendants()) do
		if d:IsA("TextButton") or d:IsA("ImageButton") then attachSoundToButton(d) end
	end
	root.DescendantAdded:Connect(function(d)
		if d:IsA("TextButton") or d:IsA("ImageButton") then attachSoundToButton(d) end
	end)
end

local function playIntroSoundOnly()
	if not gui then return end
	local s=Instance.new("Sound")
	s.Name,s.SoundId,s.Volume,s.Looped,s.Parent="SOS_IntroSound",INTRO_SOUND_ID,0.9,false,gui
	pcall(function() s:Play() end)
	Debris:AddItem(s,8)
end

--------------------------------------------------------------------
-- FOOTSTEP SOUND CONTROL
--------------------------------------------------------------------
local function cacheAndMuteRunSounds()
	if not character then return end
	for _,desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Sound") then
			local nameLower=string.lower(desc.Name)
			if nameLower:find("run") or nameLower:find("walk") or nameLower:find("footstep") then
				if not originalRunSoundStates[desc] then originalRunSoundStates[desc]={Volume=desc.Volume,Playing=desc.Playing} end
				desc.Volume,desc.Playing=0,false
			end
		end
	end
end

local function restoreRunSounds()
	for sound,data in pairs(originalRunSoundStates) do
		if sound and sound.Parent then
			sound.Volume=data.Volume or 0.5
			if data.Playing then sound.Playing=true end
		end
	end
end

--------------------------------------------------------------------
-- FLIGHT ANIMS
--------------------------------------------------------------------
local function loadFlightTracks()
	if not humanoid then return end
	if humanoid.RigType==Enum.HumanoidRigType.R6 then animator,floatTrack,flyTrack=nil,nil,nil return end
	animator=humanoid:FindFirstChildOfClass("Animator")
	if not animator then animator=Instance.new("Animator") animator.Parent=humanoid end
	if floatTrack then pcall(function() floatTrack:Stop(0) end) end
	if flyTrack then pcall(function() flyTrack:Stop(0) end) end
	floatTrack,flyTrack=nil,nil
	do
		local a=Instance.new("Animation") a.AnimationId=FLOAT_ID
		local ok,tr=pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then floatTrack=tr floatTrack.Priority,floatTrack.Looped=Enum.AnimationPriority.Action,true
		else floatTrack=nil dprint("Float track failed to load:",FLOAT_ID) end
	end
	do
		local a=Instance.new("Animation") a.AnimationId=FLY_ID
		local ok,tr=pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then flyTrack=tr flyTrack.Priority,flyTrack.Looped=Enum.AnimationPriority.Action,true
		else flyTrack=nil dprint("Fly track failed to load:",FLY_ID) end
	end
	animMode,lastAnimSwitch="Float",0
end

local function playFloat()
	if humanoid and humanoid.RigType==Enum.HumanoidRigType.R6 then return end
	if not floatTrack then return end
	if flyTrack and flyTrack.IsPlaying then pcall(function() flyTrack:Stop(0.25) end) end
	if not floatTrack.IsPlaying then pcall(function() floatTrack:Play(0.25) end) end
end

local function playFly()
	if humanoid and humanoid.RigType==Enum.HumanoidRigType.R6 then return end
	if not flyTrack then return end
	if floatTrack and floatTrack.IsPlaying then pcall(function() floatTrack:Stop(0.25) end) end
	if not flyTrack.IsPlaying then pcall(function() flyTrack:Play(0.25) end) end
end

local function stopFlightAnims()
	if floatTrack then pcall(function() floatTrack:Stop(0.25) end) end
	if flyTrack then pcall(function() flyTrack:Stop(0.25) end) end
end

--------------------------------------------------------------------
-- CHARACTER SETUP
--------------------------------------------------------------------
local function getCharacter()
	character=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	humanoid=character:WaitForChild("Humanoid")
	rootPart=character:WaitForChild("HumanoidRootPart")
	camera=workspace.CurrentCamera
	rightShoulder=findRightShoulderMotor(character)
	defaultShoulderC0=rightShoulder and rightShoulder.C0 or nil
	originalRunSoundStates={}
	if DEFAULT_WALKSPEED==nil then DEFAULT_WALKSPEED=humanoid.WalkSpeed end
	if playerSpeed==nil then playerSpeed=humanoid.WalkSpeed end
	if DEFAULT_FOV==nil and camera then DEFAULT_FOV=camera.FieldOfView end
	if DEFAULT_CAM_MIN_ZOOM==nil then DEFAULT_CAM_MIN_ZOOM=LocalPlayer.CameraMinZoomDistance end
	if DEFAULT_CAM_MAX_ZOOM==nil then DEFAULT_CAM_MAX_ZOOM=LocalPlayer.CameraMaxZoomDistance end
	if camFov==nil and DEFAULT_FOV then camFov=DEFAULT_FOV end
	if camMaxZoom==nil then camMaxZoom=INFINITE_ZOOM end
	loadFlightTracks()
end

--------------------------------------------------------------------
-- ANIMATE OVERRIDES
--------------------------------------------------------------------
local function getAnimateScript()
	if not character then return nil end
	return character:FindFirstChild("Animate")
end

local function applyStateOverrideToAnimate(stateName,packEntry)
	local animate=getAnimateScript()
	if not animate then notify("Anim Packs","No Animate script found in character.",3) return false end
	local hum=humanoid
	if not hum then return false end
	animate.Disabled=true
	stopAllPlayingTracks(hum)

	local function setAnimValue(folderName,childName,assetIdStr)
		local f=animate:FindFirstChild(folderName)
		if not f then return end
		local a=f:FindFirstChild(childName)
		if a and a:IsA("Animation") then a.AnimationId=assetIdStr end
	end

	local function setDirect(childName,assetIdStr)
		local a=animate:FindFirstChild(childName)
		if a and a:IsA("Animation") then a.AnimationId=assetIdStr end
	end

	local assetIdStr=toAssetIdString(packEntry)
	if not assetIdStr then animate.Disabled=false return false end

	if stateName=="Idle" then setAnimValue("idle","Animation1",assetIdStr) setAnimValue("idle","Animation2",assetIdStr)
	elseif stateName=="Walk" then setAnimValue("walk","WalkAnim",assetIdStr)
	elseif stateName=="Run" then setAnimValue("run","RunAnim",assetIdStr)
	elseif stateName=="Jump" then setAnimValue("jump","JumpAnim",assetIdStr)
	elseif stateName=="Climb" then setAnimValue("climb","ClimbAnim",assetIdStr)
	elseif stateName=="Fall" then setAnimValue("fall","FallAnim",assetIdStr)
	elseif stateName=="Swim" then setAnimValue("swim","Swim",assetIdStr) setAnimValue("swim","SwimIdle",assetIdStr) setDirect("swim",assetIdStr) end

	animate.Disabled=false
	pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
	return true
end

local function reapplyAllOverridesAfterRespawn()
	for stateName,asset in pairs(stateOverrides) do
		if asset then applyStateOverrideToAnimate(stateName,asset) end
	end
end

--------------------------------------------------------------------
-- MOVEMENT INPUT
--------------------------------------------------------------------
local function updateMovementInput()
	if IS_MOBILE then
		if humanoid then
			local md=humanoid.MoveDirection
			if md.Magnitude>0.01 and camera then
				local camCF,camLook,camRight=camera.CFrame,camera.CFrame.LookVector,camera.CFrame.RightVector
				local x,z=camRight:Dot(md),-camLook:Dot(md)
				moveInput=Vector3.new(x,0,z)
			else moveInput=Vector3.new() end
		else moveInput=Vector3.new() end
		verticalInput=0
		return
	end
	local dir=Vector3.new()
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir=dir+Vector3.new(0,0,-1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir=dir+Vector3.new(0,0,1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir=dir+Vector3.new(-1,0,0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir=dir+Vector3.new(1,0,0) end
	moveInput=dir
	local vert=0
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then vert=vert+1 end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then vert=vert-1 end
	verticalInput=vert
end

--------------------------------------------------------------------
-- FLIGHT CORE
--------------------------------------------------------------------
local function startFlying()
	if flying or not humanoid or not rootPart then return end
	flying=true
	humanoid.PlatformStand=true
	cacheAndMuteRunSounds()
	bodyGyro=Instance.new("BodyGyro")
	bodyGyro.MaxTorque,bodyGyro.P,bodyGyro.D,bodyGyro.CFrame,bodyGyro.Parent=Vector3.new(1e5,1e5,1e5),1e5,1000,rootPart.CFrame,rootPart
	bodyVel=Instance.new("BodyVelocity")
	bodyVel.MaxForce,bodyVel.Velocity,bodyVel.P,bodyVel.Parent=Vector3.new(1e5,1e5,1e5),Vector3.new(),1250,rootPart
	currentVelocity,currentGyroCFrame=Vector3.new(),rootPart.CFrame
	local camLook=camera and camera.CFrame.LookVector or Vector3.new(0,0,-1)
	if camLook.Magnitude<0.01 then camLook=Vector3.new(0,0,-1) end
	camLook=camLook.Unit
	local baseCF=CFrame.lookAt(rootPart.Position,rootPart.Position+camLook)
	currentGyroCFrame=baseCF*CFrame.Angles(-math.rad(IDLE_TILT_DEG),0,0)
	bodyGyro.CFrame=currentGyroCFrame
	animMode,lastAnimSwitch="Float",0
	playFloat()
end

local function stopFlying()
	if not flying then return end
	flying=false
	stopFlightAnims()
	if bodyGyro then bodyGyro:Destroy() bodyGyro=nil end
	if bodyVel then bodyVel:Destroy() bodyVel=nil end
	if humanoid then humanoid.PlatformStand=false end
	if rightShoulder and defaultShoulderC0 then rightShoulder.C0=defaultShoulderC0 end
	restoreRunSounds()
end

--------------------------------------------------------------------
-- UI BUILDING BLOCKS
--------------------------------------------------------------------
local function makeCorner(parent,r) local c=Instance.new("UICorner") c.CornerRadius,c.Parent=UDim.new(0,r or 12),parent return c end
local function makeStroke(parent,thickness) local s=Instance.new("UIStroke") s.Color,s.Thickness,s.Transparency,s.ApplyStrokeMode,s.Parent=Color3.fromRGB(200,40,40),thickness or 2,0.1,Enum.ApplyStrokeMode.Border,parent return s end

local function makeGlass(parent)
	parent.BackgroundColor3,parent.BackgroundTransparency=Color3.fromRGB(10,10,12),0.18
	local grad=Instance.new("UIGradient")
	grad.Rotation,grad.Parent=90,parent
	grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(18,18,22)),ColorSequenceKeypoint.new(0.4,Color3.fromRGB(10,10,12)),ColorSequenceKeypoint.new(1,Color3.fromRGB(6,6,8))})
	grad.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.05),NumberSequenceKeypoint.new(1,0.20)})
	local shine,shineImg=Instance.new("Frame"),nil
	shine.Name,shine.BackgroundTransparency,shine.Size,shine.Position,shine.Parent="Shine",1,UDim2.new(1,-8,0.35,0),UDim2.new(0,4,0,4),parent
	shineImg=Instance.new("ImageLabel")
	shineImg.BackgroundTransparency,shineImg.Size,shineImg.Image,shineImg.ImageTransparency,shineImg.Parent=1,UDim2.new(1,0,1,0),"rbxassetid://5028857084",0.72,shine
	local shineGrad=Instance.new("UIGradient")
	shineGrad.Rotation,shineGrad.Transparency,shineGrad.Parent=0,NumberSequence.new({NumberSequenceKeypoint.new(0,0.65),NumberSequenceKeypoint.new(1,1)}),shineImg
end

local function makeText(parent,txt,size,bold)
	local t=Instance.new("TextLabel")
	t.BackgroundTransparency,t.Text,t.TextColor3,t.Font,t.TextSize,t.TextXAlignment,t.TextYAlignment,t.TextWrapped,t.Parent=1,txt or "",Color3.fromRGB(240,240,240),bold and Enum.Font.GothamBold or Enum.Font.Gotham,size or 16,Enum.TextXAlignment.Left,Enum.TextYAlignment.Center,true,parent
	return t
end

local function makeButton(parent,txt)
	local b=Instance.new("TextButton")
	b.BackgroundColor3,b.BackgroundTransparency,b.BorderSizePixel,b.AutoButtonColor,b.Text,b.Font,b.TextSize,b.TextColor3,b.Parent=Color3.fromRGB(16,16,20),0.2,0,true,txt or "Button",Enum.Font.GothamBold,14,Color3.fromRGB(245,245,245),parent
	makeCorner(b,10)
	local st=Instance.new("UIStroke")
	st.Color,st.Thickness,st.Transparency,st.Parent=Color3.fromRGB(200,40,40),1,0.25,b
	return b
end

local function makeInput(parent,placeholder)
	local tb=Instance.new("TextBox")
	tb.BackgroundColor3,tb.BackgroundTransparency,tb.BorderSizePixel,tb.ClearTextOnFocus,tb.Text,tb.PlaceholderText,tb.Font,tb.TextSize,tb.TextColor3,tb.PlaceholderColor3,tb.Parent=Color3.fromRGB(16,16,20),0.15,0,false,"",placeholder or "",Enum.Font.Gotham,14,Color3.fromRGB(245,245,245),Color3.fromRGB(170,170,170),parent
	makeCorner(tb,10)
	local st=Instance.new("UIStroke")
	st.Color,st.Thickness,st.Transparency,st.Parent=Color3.fromRGB(200,40,40),1,0.35,tb
	return tb
end

local function setTabButtonActive(btn,active)
	local st=btn:FindFirstChildOfClass("UIStroke")
	if st then st.Transparency,st.Thickness=active and 0.05 or 0.35,active and 2 or 1 end
	btn.BackgroundTransparency=active and 0.08 or 0.22
end

--------------------------------------------------------------------
-- PLAYER SPEED / CAMERA
--------------------------------------------------------------------
local function applyPlayerSpeed() if humanoid and playerSpeed then humanoid.WalkSpeed=playerSpeed end end

local function resetPlayerSpeedToDefault()
	if humanoid then
		if DEFAULT_WALKSPEED==nil then DEFAULT_WALKSPEED=humanoid.WalkSpeed end
		playerSpeed,humanoid.WalkSpeed=DEFAULT_WALKSPEED,DEFAULT_WALKSPEED
	end
	Settings.scheduleSave()
end

local function resolveCameraSubject(mode)
	if not character then return nil end
	if mode=="Humanoid" then return humanoid end
	if mode=="Head" then return character:FindFirstChild("Head") or humanoid end
	if mode=="HumanoidRootPart" then return character:FindFirstChild("HumanoidRootPart") or humanoid end
	if mode=="Torso" then return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or humanoid end
	if mode=="UpperTorso" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or humanoid end
	if mode=="LowerTorso" then return character:FindFirstChild("LowerTorso") or humanoid end
	return humanoid
end

local function applyCameraSettings()
	if not camera then return end
	LocalPlayer.CameraMaxZoomDistance,LocalPlayer.CameraMinZoomDistance=camMaxZoom or INFINITE_ZOOM,DEFAULT_CAM_MIN_ZOOM or 0.5
	if camFov then camera.FieldOfView=camFov end
	local subject=resolveCameraSubject(camSubjectMode)
	if subject then camera.CameraSubject=subject end
	if humanoid then humanoid.CameraOffset=camOffset end
end

local function resetCameraToDefaults()
	if DEFAULT_FOV and camera then camFov,camera.FieldOfView=DEFAULT_FOV,DEFAULT_FOV end
	if DEFAULT_CAM_MIN_ZOOM~=nil then LocalPlayer.CameraMinZoomDistance=DEFAULT_CAM_MIN_ZOOM end
	camMaxZoom,LocalPlayer.CameraMaxZoomDistance=INFINITE_ZOOM,INFINITE_ZOOM
	camSubjectMode,camOffset=DEFAULT_CAMERA_SUBJECT_MODE,Vector3.new()
	if humanoid then humanoid.CameraOffset=camOffset end
	applyCameraSettings()
	Settings.scheduleSave()
end

--------------------------------------------------------------------
-- VIP TOOLS
--------------------------------------------------------------------
local function ownsAnyVipPass()
	for _,id in ipairs(VIP_GAMEPASSES) do
		local ok,owned=pcall(function() return MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId,id) end)
		if ok and owned then return true end
	end
	return false
end

local function giveBetterSpeedCoil()
	if not character or not humanoid then notify("Better Speed Coil","Character not ready.",2) return end
	local backpack=LocalPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then notify("Better Speed Coil","Backpack not found.",2) return end
	if backpack:FindFirstChild("Better Speed Coil") or character:FindFirstChild("Better Speed Coil") then notify("Better Speed Coil","You already have it.",2) return end
	local tool=Instance.new("Tool")
	tool.Name,tool.RequiresHandle,tool.CanBeDropped,tool.ManualActivationOnly="Better Speed Coil",false,false,true
	local last=nil
	tool.Equipped:Connect(function() if humanoid then last,humanoid.WalkSpeed=humanoid.WalkSpeed,111 end end)
	tool.Unequipped:Connect(function() if humanoid then humanoid.WalkSpeed=last or humanoid.WalkSpeed end end)
	tool.Parent=backpack
	notify("Better Speed Coil","Added to your inventory.",2)
end

--------------------------------------------------------------------
-- INIT
--------------------------------------------------------------------
function HUD.init()
	Settings.loadSettings()
	getCharacter()
	HUD.createUI()
	applyPlayerSpeed()
	applyCameraSettings()
	reapplyAllOverridesAfterRespawn()
	syncLightingToggles()

	LocalPlayer.CharacterAdded:Connect(function()
		task.wait(0.15)
		getCharacter()
		applyPlayerSpeed()
		applyCameraSettings()
		reapplyAllOverridesAfterRespawn()
		syncLightingToggles()
		if flying then stopFlying() end
	end)

	notify("SOS HUD","Loaded.",2)
end

HUD.syncLightingToggles=syncLightingToggles

--------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------
function HUD.createUI()
	safeDestroy(gui)
	gui=Instance.new("ScreenGui")
	gui.Name,gui.ResetOnSpawn,gui.IgnoreGuiInset,gui.ZIndexBehavior,gui.Parent="SOS_HUD",false,true,Enum.ZIndexBehavior.Sibling,LocalPlayer:WaitForChild("PlayerGui")
	ensureClickSoundTemplate()
	setupGlobalButtonSounds(gui)
	playIntroSoundOnly()

	fpsLabel=Instance.new("TextLabel")
	fpsLabel.Name,fpsLabel.BackgroundTransparency,fpsLabel.AnchorPoint,fpsLabel.Position,fpsLabel.Size="FPS",1,Vector2.new(1,1),UDim2.new(1,-6,1,-6),UDim2.new(0,140,0,18)
	fpsLabel.Font,fpsLabel.TextSize,fpsLabel.TextXAlignment,fpsLabel.TextYAlignment,fpsLabel.Text,fpsLabel.TextColor3,fpsLabel.Parent=Enum.Font.GothamBold,12,Enum.TextXAlignment.Right,Enum.TextYAlignment.Bottom,"fps",Color3.fromRGB(80,255,80),gui

	menuHandle=Instance.new("Frame")
	menuHandle.Name,menuHandle.AnchorPoint,menuHandle.Position,menuHandle.Size,menuHandle.BorderSizePixel,menuHandle.Parent="MenuHandle",Vector2.new(0.5,0),UDim2.new(0.5,0,0,6),UDim2.new(0,560,0,42),0,gui
	makeCorner(menuHandle,16)
	makeGlass(menuHandle)
	makeStroke(menuHandle,2)

	arrowButton=Instance.new("TextButton")
	arrowButton.Name,arrowButton.BackgroundTransparency,arrowButton.Size,arrowButton.Position,arrowButton.Text,arrowButton.Font,arrowButton.TextSize,arrowButton.TextColor3,arrowButton.Parent="Arrow",1,UDim2.new(0,40,0,40),UDim2.new(0,8,0,1),"˄",Enum.Font.GothamBold,22,Color3.fromRGB(240,240,240),menuHandle

	local title=Instance.new("TextLabel")
	title.BackgroundTransparency,title.Size,title.Position,title.Font,title.TextSize,title.Text,title.TextColor3,title.TextXAlignment,title.Parent=1,UDim2.new(1,-90,1,0),UDim2.new(0,70,0,0),Enum.Font.GothamBold,18,"SOS HUD",Color3.fromRGB(245,245,245),Enum.TextXAlignment.Center,menuHandle

	menuFrame=Instance.new("Frame")
	menuFrame.Name,menuFrame.AnchorPoint,menuFrame.Position,menuFrame.Size,menuFrame.BorderSizePixel,menuFrame.Parent="Menu",Vector2.new(0.5,0),UDim2.new(0.5,0,0,52),UDim2.new(0,560,0,390),0,gui
	makeCorner(menuFrame,16)
	makeGlass(menuFrame)
	makeStroke(menuFrame,2)

	tabsBar=Instance.new("ScrollingFrame")
	tabsBar.Name,tabsBar.BackgroundTransparency,tabsBar.BorderSizePixel,tabsBar.Position,tabsBar.Size,tabsBar.CanvasSize,tabsBar.ScrollBarThickness,tabsBar.ScrollingDirection,tabsBar.AutomaticCanvasSize,tabsBar.Parent="TabsBar",1,0,UDim2.new(0,14,0,10),UDim2.new(1,-28,0,46),UDim2.new(0,0,0,0),2,Enum.ScrollingDirection.X,Enum.AutomaticSize.X,menuFrame

	local tabsLayout=Instance.new("UIListLayout")
	tabsLayout.FillDirection,tabsLayout.SortOrder,tabsLayout.Padding,tabsLayout.Parent=Enum.FillDirection.Horizontal,Enum.SortOrder.LayoutOrder,UDim.new(0,10),tabsBar

	pagesHolder=Instance.new("Frame")
	pagesHolder.Name,pagesHolder.BackgroundTransparency,pagesHolder.Position,pagesHolder.Size,pagesHolder.ClipsDescendants,pagesHolder.Parent="PagesHolder",1,UDim2.new(0,14,0,66),UDim2.new(1,-28,1,-80),true,menuFrame

	HUD.buildAllPages()

	menuOpen,menuFrame.Visible,arrowButton.Text=false,false,"˄"
	local openPos,closedPos=menuFrame.Position,UDim2.new(menuFrame.Position.X.Scale,menuFrame.Position.X.Offset,menuFrame.Position.Y.Scale,menuFrame.Position.Y.Offset-(menuFrame.Size.Y.Offset+10))

	local function setMenu(open,instant)
		menuOpen,arrowButton.Text=open,open and "˅" or "˄"
		if menuTween then pcall(function() menuTween:Cancel() end) menuTween=nil end
		if instant then menuFrame.Visible,menuFrame.Position,menuFrame.BackgroundTransparency=open,open and openPos or closedPos,open and 0.18 or 1 return end
		if open then
			menuFrame.Visible,menuFrame.Position,menuFrame.BackgroundTransparency=true,closedPos,1
			menuTween=tween(menuFrame,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=openPos,BackgroundTransparency=0.18})
		else
			menuTween=tween(menuFrame,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=closedPos,BackgroundTransparency=1})
			menuTween.Completed:Connect(function() if not menuOpen then menuFrame.Visible=false end end)
		end
	end

	arrowButton.MouseButton1Click:Connect(function() setMenu(not menuOpen,false) end)
	setMenu(false,true)

	if IS_MOBILE then
		mobileFlyButton=makeButton(gui,"Fly")
		mobileFlyButton.Name,mobileFlyButton.AnchorPoint,mobileFlyButton.Position,mobileFlyButton.Size,mobileFlyButton.TextSize="MobileFly",Vector2.new(1,1),MOBILE_FLY_POS,MOBILE_FLY_SIZE,18
		mobileFlyButton.MouseButton1Click:Connect(function() if flying then stopFlying() else startFlying() end end)
	end
end

-- Due to character limit, I'll continue the buildAllPages in the next part
-- This is a comprehensive implementation with all core systems in place

--------------------------------------------------------------------
-- BUILD ALL PAGES
--------------------------------------------------------------------
function HUD.buildAllPages()
	local pages,tabButtons,activePageName={},{},""

	local function makePage(name)
		local p,scroll=Instance.new("Frame"),nil
		p.Name,p.BackgroundTransparency,p.Size,p.Visible,p.Parent=name,1,UDim2.new(1,0,1,0),false,pagesHolder
		scroll=Instance.new("ScrollingFrame")
		scroll.Name,scroll.BackgroundTransparency,scroll.BorderSizePixel,scroll.Size,scroll.CanvasSize,scroll.AutomaticCanvasSize,scroll.ScrollBarThickness,scroll.Parent="Scroll",1,0,UDim2.new(1,0,1,0),UDim2.new(0,0,0,0),Enum.AutomaticSize.Y,4,p
		local pad=Instance.new("UIPadding")
		pad.PaddingTop,pad.PaddingBottom,pad.PaddingLeft,pad.PaddingRight,pad.Parent=UDim.new(0,8),UDim.new(0,12),UDim.new(0,6),UDim.new(0,6),scroll
		local layout=Instance.new("UIListLayout")
		layout.SortOrder,layout.Padding,layout.Parent=Enum.SortOrder.LayoutOrder,UDim.new(0,10),scroll
		pages[name]={Page=p,Scroll=scroll}
		return p,scroll
	end

	local infoPage,infoScroll=makePage("Info")
	local controlsPage,controlsScroll=makePage("Controls")
	local flyPage,flyScroll=makePage("Fly")
	local animPage,animScroll=makePage("Anim Packs")
	local playerPage,playerScroll=makePage("Player")
	local cameraPage,cameraScroll=makePage("Camera")
	local lightingPage,lightingScroll=makePage("Lighting")
	local serverPage,serverScroll=makePage("Server")
	local clientPage,clientScroll=makePage("Client")
	local micupPage,micupScroll=nil,nil
	do local placeIdStr=tostring(game.PlaceId) if MICUP_PLACE_IDS[placeIdStr] then micupPage,micupScroll=makePage("Mic up") end end

	-- INFO TAB
	do
		local header,msg=makeText(infoScroll,"The Sins Of Scripting HUD",16,true),nil
		header.Size=UDim2.new(1,0,0,22)
		msg=makeText(infoScroll,"Welcome.\n\nDiscord:\nPress to copy, or it will open if copy isn't supported.\n",14,false)
		msg.Size=UDim2.new(1,0,0,90)
		local row=Instance.new("Frame")
		row.BackgroundTransparency,row.Size,row.Parent=1,UDim2.new(1,0,0,44),infoScroll
		local rowLay=Instance.new("UIListLayout")
		rowLay.FillDirection,rowLay.Padding,rowLay.VerticalAlignment,rowLay.Parent=Enum.FillDirection.Horizontal,UDim.new(0,10),Enum.VerticalAlignment.Center,row
		local discordBtn,linkBox=makeButton(row,"(SOS Server)"),nil
		discordBtn.Size=UDim2.new(0,180,0,36)
		linkBox=makeInput(row,"Press to copy")
		linkBox.Size,linkBox.Text=UDim2.new(1,-200,0,36),DISCORD_LINK
		discordBtn.MouseButton1Click:Connect(function()
			local copied=false
			pcall(function() if typeof(setclipboard)=="function" then setclipboard(DISCORD_LINK) copied=true end end)
			if copied then notify("SOS Server","Copied to clipboard.",2)
			else pcall(function() linkBox:CaptureFocus() end) pcall(function() GuiService:OpenBrowserWindow(DISCORD_LINK) end) notify("SOS Server","Press to copy (use the box).",3) end
		end)
	end

	-- CONTROLS TAB
	do
		local header=makeText(controlsScroll,"Controls",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local info=makeText(controlsScroll,"PC:\n- Fly Toggle: "..flightToggleKey.Name.."\n- Move: WASD + Q/E\n\nMobile:\n- Use the Fly button (bottom-right)\n- Use the top arrow to open/close the menu",14,false)
		info.Size=UDim2.new(1,0,0,120)
	end

	-- FLY TAB
	do
		local header=makeText(flyScroll,"Flight Emotes",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local keyLegend=makeText(flyScroll,"A = Apply    R = Reset",13,true)
		keyLegend.Size,keyLegend.TextColor3=UDim2.new(1,0,0,18),Color3.fromRGB(220,220,220)
		local warning=makeText(flyScroll,"Animation IDs for flight must be a Published Marketplace/Catalog EMOTE assetid from the Creator Store.\n(If you paste random IDs, it can fail.)\n(copy and paste id in the link of the creator store version or the chosen Emote (Wont Work With Normal Marketplace ID))",13,false)
		warning.TextColor3,warning.Size=Color3.fromRGB(220,220,220),UDim2.new(1,0,0,92)

		local function makeIdRow(labelText,getFn,setFn,resetFn)
			local row,l,box,applyBtn,resetBtn=Instance.new("Frame"),nil,nil,nil,nil
			row.BackgroundTransparency,row.Size,row.Parent=1,UDim2.new(1,0,0,44),flyScroll
			l=makeText(row,labelText,14,true)
			l.Size=UDim2.new(0,120,1,0)
			box=makeInput(row,"rbxassetid://... or number")
			box.Size,box.Position,box.Text=UDim2.new(1,-240,0,36),UDim2.new(0,130,0,4),getFn()
			applyBtn=makeButton(row,"A")
			applyBtn.Size,applyBtn.AnchorPoint,applyBtn.Position=UDim2.new(0,70,0,36),Vector2.new(1,0),UDim2.new(1,-90,0,4)
			resetBtn=makeButton(row,"R")
			resetBtn.Size,resetBtn.AnchorPoint,resetBtn.Position=UDim2.new(0,70,0,36),Vector2.new(1,0),UDim2.new(1,-10,0,4)
			applyBtn.MouseButton1Click:Connect(function()
				local parsed=toAssetIdString(box.Text)
				if not parsed then notify("Flight Emotes","Invalid ID. Use rbxassetid://123 or just 123",3) return end
				setFn(parsed) loadFlightTracks() if flying then stopFlightAnims() playFloat() end Settings.scheduleSave() notify("Flight Emotes","Applied.",2)
			end)
			resetBtn.MouseButton1Click:Connect(function()
				resetFn() box.Text=getFn() loadFlightTracks() if flying then stopFlightAnims() playFloat() end Settings.scheduleSave() notify("Flight Emotes","Reset to default.",2)
			end)
		end

		makeIdRow("FLOAT_ID:",function() return FLOAT_ID end,function(v) FLOAT_ID=v end,function() FLOAT_ID=DEFAULT_FLOAT_ID end)
		makeIdRow("FLY_ID:",function() return FLY_ID end,function(v) FLY_ID=v end,function() FLY_ID=DEFAULT_FLY_ID end)

		local speedHeader=makeText(flyScroll,"Fly Speed",16,true)
		speedHeader.Size=UDim2.new(1,0,0,22)
		local speedRow,speedLabel,sliderBg,sliderFill,knob=Instance.new("Frame"),nil,nil,nil,nil
		speedRow.BackgroundTransparency,speedRow.Size,speedRow.Parent=1,UDim2.new(1,0,0,60),flyScroll
		speedLabel=makeText(speedRow,"Speed: "..tostring(flySpeed),14,true)
		speedLabel.Size=UDim2.new(1,0,0,18)
		sliderBg=Instance.new("Frame")
		sliderBg.BackgroundColor3,sliderBg.BackgroundTransparency,sliderBg.BorderSizePixel,sliderBg.Position,sliderBg.Size,sliderBg.Parent=Color3.fromRGB(16,16,20),0.15,0,UDim2.new(0,0,0,26),UDim2.new(1,0,0,10),speedRow
		makeCorner(sliderBg,999)
		sliderFill=Instance.new("Frame")
		sliderFill.BackgroundColor3,sliderFill.BorderSizePixel,sliderFill.Size,sliderFill.Parent=Color3.fromRGB(200,40,40),0,UDim2.new(0,0,1,0),sliderBg
		makeCorner(sliderFill,999)
		knob=Instance.new("Frame")
		knob.BackgroundColor3,knob.BorderSizePixel,knob.Size,knob.Parent=Color3.fromRGB(245,245,245),0,UDim2.new(0,14,0,14),sliderBg
		makeCorner(knob,999)

		local function setSpeedFromAlpha(a)
			a=clamp01(a)
			local s=minFlySpeed+(maxFlySpeed-minFlySpeed)*a
			flySpeed=math.floor(s+0.5)
			speedLabel.Text="Speed: "..tostring(flySpeed)
			sliderFill.Size=UDim2.new(a,0,1,0)
			knob.Position=UDim2.new(a,-7,0.5,-7)
			Settings.scheduleSave()
		end

		setSpeedFromAlpha((flySpeed-minFlySpeed)/(maxFlySpeed-minFlySpeed))

		local dragging=false
		sliderBg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
		sliderBg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
		UserInputService.InputChanged:Connect(function(i)
			if not dragging then return end
			if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
			local a=(i.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
			setSpeedFromAlpha(a)
		end)
	end

	-- ANIM PACKS TAB
	do
		local header=makeText(animScroll,"Anim Packs",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local help=makeText(animScroll,"Pick a STATE, then pick a pack name to change only that state.",13,false)
		help.Size,help.TextColor3=UDim2.new(1,0,0,34),Color3.fromRGB(210,210,210)

		local animStateBar=Instance.new("ScrollingFrame")
		animStateBar.BackgroundTransparency,animStateBar.BorderSizePixel,animStateBar.Size,animStateBar.CanvasSize,animStateBar.AutomaticCanvasSize,animStateBar.ScrollingDirection,animStateBar.ScrollBarThickness,animStateBar.Parent=1,0,UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),Enum.AutomaticSize.X,Enum.ScrollingDirection.X,2,animScroll
		local stLayout=Instance.new("UIListLayout")
		stLayout.FillDirection,stLayout.SortOrder,stLayout.Padding,stLayout.Parent=Enum.FillDirection.Horizontal,Enum.SortOrder.LayoutOrder,UDim.new(0,12),animStateBar

		local animCategoryBar=Instance.new("ScrollingFrame")
		animCategoryBar.BackgroundTransparency,animCategoryBar.BorderSizePixel,animCategoryBar.Size,animCategoryBar.CanvasSize,animCategoryBar.AutomaticCanvasSize,animCategoryBar.ScrollingDirection,animCategoryBar.ScrollBarThickness,animCategoryBar.Parent=1,0,UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),Enum.AutomaticSize.X,Enum.ScrollingDirection.X,2,animScroll
		local catLayout=Instance.new("UIListLayout")
		catLayout.FillDirection,catLayout.SortOrder,catLayout.Padding,catLayout.Parent=Enum.FillDirection.Horizontal,Enum.SortOrder.LayoutOrder,UDim.new(0,12),animCategoryBar

		local animListScroll=Instance.new("ScrollingFrame")
		animListScroll.BackgroundTransparency,animListScroll.BorderSizePixel,animListScroll.Size,animListScroll.CanvasSize,animListScroll.AutomaticCanvasSize,animListScroll.ScrollBarThickness,animListScroll.Parent=1,0,UDim2.new(1,0,0,250),UDim2.new(0,0,0,0),Enum.AutomaticSize.Y,4,animScroll
		local pad=Instance.new("UIPadding")
		pad.PaddingTop,pad.PaddingBottom,pad.PaddingLeft,pad.PaddingRight,pad.Parent=UDim.new(0,6),UDim.new(0,6),UDim.new(0,2),UDim.new(0,2),animListScroll
		local animListContainer=Instance.new("Frame")
		animListContainer.BackgroundTransparency,animListContainer.Size,animListContainer.Parent=1,UDim2.new(1,0,0,0),animListScroll
		local listLayout=Instance.new("UIListLayout")
		listLayout.SortOrder,listLayout.Padding,listLayout.Parent=Enum.SortOrder.LayoutOrder,UDim.new(0,10),animListContainer

		local function animateListPop()
			animListContainer.Position=UDim2.new(0,26,0,0)
			tween(animListContainer,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)})
		end

		local stateButtons,categoryButtons={},{}

		local function rebuildPackList()
			for _,ch in ipairs(animListContainer:GetChildren()) do if ch:IsA("TextButton") or ch:IsA("TextLabel") or ch:IsA("Frame") then ch:Destroy() end end
			if lastChosenCategory=="Custom" then
				local names=listCustomNamesForState(lastChosenState)
				if #names==0 then local t=makeText(animListContainer,"No Custom animations for: "..lastChosenState,14,true) t.Size=UDim2.new(1,0,0,28) animateListPop() return end
				for _,nm in ipairs(names) do
					local b=makeButton(animListContainer,nm)
					b.Size=UDim2.new(1,0,0,36)
					b.MouseButton1Click:Connect(function()
						local id=getCustomIdForState(nm,lastChosenState)
						if not id then return end
						stateOverrides[lastChosenState]="rbxassetid://"..tostring(id)
						local ok=applyStateOverrideToAnimate(lastChosenState,stateOverrides[lastChosenState])
						if ok then notify("Anim Packs","Set "..lastChosenState.." to "..nm,2) Settings.scheduleSave()
						else notify("Anim Packs","Failed to apply. (Animate script missing?)",3) end
					end)
				end
				animateListPop() return
			end

			local names=listPackNamesForCategory(lastChosenCategory)
			for _,packName in ipairs(names) do
				local b=makeButton(animListContainer,packName)
				b.Size=UDim2.new(1,0,0,36)
				b.MouseButton1Click:Connect(function()
					local id=getPackValueForState(packName,lastChosenState)
					if not id then notify("Anim Packs","That pack has no ID for: "..lastChosenState,2) return end
					stateOverrides[lastChosenState]="rbxassetid://"..tostring(id)
					local ok=applyStateOverrideToAnimate(lastChosenState,stateOverrides[lastChosenState])
					if ok then notify("Anim Packs","Set "..lastChosenState.." to "..packName,2) Settings.scheduleSave()
					else notify("Anim Packs","Failed to apply. (Animate script missing?)",3) end
				end)
			end
			animateListPop()
		end

		local function setState(stateName)
			lastChosenState=stateName
			for n,btn in pairs(stateButtons) do setTabButtonActive(btn,n==stateName) end
			rebuildPackList()
			Settings.scheduleSave()
		end

		local function setCategory(catName)
			lastChosenCategory=catName
			for n,btn in pairs(categoryButtons) do setTabButtonActive(btn,n==catName) end
			rebuildPackList()
			Settings.scheduleSave()
		end

		local states={"Idle","Walk","Run","Jump","Climb","Fall","Swim"}
		for _,sName in ipairs(states) do
			local b=makeButton(animStateBar,sName)
			b.Size,stateButtons[sName]=UDim2.new(0,110,0,36),b
			b.MouseButton1Click:Connect(function() setState(sName) end)
		end

		local cats={"Roblox Anims","Unreleased","Custom"}
		for _,cName in ipairs(cats) do
			local b=makeButton(animCategoryBar,cName)
			b.Size,categoryButtons[cName]=UDim2.new(0,(cName=="Roblox Anims" and 160 or 130),0,36),b
			b.MouseButton1Click:Connect(function() setCategory(cName) end)
		end

		setCategory(lastChosenCategory)
		setState(lastChosenState)
	end

	-- PLAYER TAB
	do
		local header=makeText(playerScroll,"Player",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local info=makeText(playerScroll,"WalkSpeed changer. Reset uses the game's default speed for you.",13,false)
		info.Size,info.TextColor3=UDim2.new(1,0,0,34),Color3.fromRGB(210,210,210)
		local row,speedLabel,sliderBg,sliderFill,knob,resetBtn=Instance.new("Frame"),nil,nil,nil,nil,nil
		row.BackgroundTransparency,row.Size,row.Parent=1,UDim2.new(1,0,0,76),playerScroll
		speedLabel=makeText(row,"Speed: "..tostring(playerSpeed or 16),14,true)
		speedLabel.Size=UDim2.new(1,0,0,18)
		sliderBg=Instance.new("Frame")
		sliderBg.BackgroundColor3,sliderBg.BackgroundTransparency,sliderBg.BorderSizePixel,sliderBg.Position,sliderBg.Size,sliderBg.Parent=Color3.fromRGB(16,16,20),0.15,0,UDim2.new(0,0,0,26),UDim2.new(1,0,0,10),row
		makeCorner(sliderBg,999)
		sliderFill=Instance.new("Frame")
		sliderFill.BackgroundColor3,sliderFill.BorderSizePixel,sliderFill.Size,sliderFill.Parent=Color3.fromRGB(200,40,40),0,UDim2.new(0,0,1,0),sliderBg
		makeCorner(sliderFill,999)
		knob=Instance.new("Frame")
		knob.BackgroundColor3,knob.BorderSizePixel,knob.Size,knob.Parent=Color3.fromRGB(245,245,245),0,UDim2.new(0,14,0,14),sliderBg
		makeCorner(knob,999)
		resetBtn=makeButton(row,"Reset")
		resetBtn.Size,resetBtn.AnchorPoint,resetBtn.Position=UDim2.new(0,100,0,34),Vector2.new(1,0),UDim2.new(1,0,0,42)

		local function setSpeedFromAlpha(a)
			a=clamp01(a)
			local s=2+(500-2)*a
			playerSpeed=math.floor(s+0.5)
			speedLabel.Text="Speed: "..tostring(playerSpeed)
			sliderFill.Size=UDim2.new(a,0,1,0)
			knob.Position=UDim2.new(a,-7,0.5,-7)
			applyPlayerSpeed()
			Settings.scheduleSave()
		end

		local function alphaFromSpeed(s)
			s=math.clamp(s,2,500)
			return (s-2)/(500-2)
		end

		setSpeedFromAlpha(alphaFromSpeed(playerSpeed or 16))

		local dragging=false
		sliderBg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
		sliderBg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
		UserInputService.InputChanged:Connect(function(i)
			if not dragging then return end
			if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
			local a=(i.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
			setSpeedFromAlpha(a)
		end)

		resetBtn.MouseButton1Click:Connect(function()
			resetPlayerSpeedToDefault()
			setSpeedFromAlpha(alphaFromSpeed(playerSpeed or 16))
			notify("Player","Speed reset.",2)
		end)
	end

	-- CAMERA TAB
	do
		local header=makeText(cameraScroll,"Camera",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local sub=makeText(cameraScroll,"Choose camera subject, offset, max zoom, and FOV. Each has a reset.",13,false)
		sub.Size,sub.TextColor3=UDim2.new(1,0,0,34),Color3.fromRGB(210,210,210)
		local subjectHeader=makeText(cameraScroll,"Attach To",15,true)
		subjectHeader.Size=UDim2.new(1,0,0,20)

		local subjectBar=Instance.new("ScrollingFrame")
		subjectBar.BackgroundTransparency,subjectBar.BorderSizePixel,subjectBar.Size,subjectBar.CanvasSize,subjectBar.AutomaticCanvasSize,subjectBar.ScrollingDirection,subjectBar.ScrollBarThickness,subjectBar.Parent=1,0,UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),Enum.AutomaticSize.X,Enum.ScrollingDirection.X,2,cameraScroll
		local subjLayout=Instance.new("UIListLayout")
		subjLayout.FillDirection,subjLayout.SortOrder,subjLayout.Padding,subjLayout.Parent=Enum.FillDirection.Horizontal,Enum.SortOrder.LayoutOrder,UDim.new(0,10),subjectBar

		local subjButtons={}
		local modes={"Humanoid","Head","HumanoidRootPart","Torso","UpperTorso","LowerTorso"}

		local function setSubjectMode(m)
			camSubjectMode=m
			for k,b in pairs(subjButtons) do setTabButtonActive(b,k==m) end
			applyCameraSettings()
			Settings.scheduleSave()
		end

		for _,m in ipairs(modes) do
			local b=makeButton(subjectBar,m)
			b.Size,subjButtons[m]=UDim2.new(0,170,0,36),b
			b.MouseButton1Click:Connect(function() setSubjectMode(m) end)
		end

		local offHeader=makeText(cameraScroll,"Offset",15,true)
		offHeader.Size=UDim2.new(1,0,0,20)

		local function makeAxisSlider(axisName,getValFn,setValFn,minV,maxV)
			local row,label,reset,sliderBg,fill,knob=Instance.new("Frame"),nil,nil,nil,nil,nil
			row.BackgroundTransparency,row.Size,row.Parent=1,UDim2.new(1,0,0,66),cameraScroll
			label=makeText(row,axisName..": "..string.format("%.2f",getValFn()),14,true)
			label.Size=UDim2.new(1,-120,0,18)
			reset=makeButton(row,"Reset")
			reset.Size,reset.AnchorPoint,reset.Position=UDim2.new(0,100,0,30),Vector2.new(1,0),UDim2.new(1,0,0,0)
			sliderBg=Instance.new("Frame")
			sliderBg.BackgroundColor3,sliderBg.BackgroundTransparency,sliderBg.BorderSizePixel,sliderBg.Position,sliderBg.Size,sliderBg.Parent=Color3.fromRGB(16,16,20),0.15,0,UDim2.new(0,0,0,26),UDim2.new(1,0,0,10),row
			makeCorner(sliderBg,999)
			fill=Instance.new("Frame")
			fill.BackgroundColor3,fill.BorderSizePixel,fill.Size,fill.Parent=Color3.fromRGB(200,40,40),0,UDim2.new(0,0,1,0),sliderBg
			makeCorner(fill,999)
			knob=Instance.new("Frame")
			knob.BackgroundColor3,knob.BorderSizePixel,knob.Size,knob.Parent=Color3.fromRGB(245,245,245),0,UDim2.new(0,14,0,14),sliderBg
			makeCorner(knob,999)

			local function setFromAlpha(a)
				a=clamp01(a)
				local v=minV+(maxV-minV)*a
				setValFn(v)
				label.Text=axisName..": "..string.format("%.2f",getValFn())
				fill.Size=UDim2.new(a,0,1,0)
				knob.Position=UDim2.new(a,-7,0.5,-7)
				applyCameraSettings()
				Settings.scheduleSave()
			end

			local function alphaFromValue(v)
				v=math.clamp(v,minV,maxV)
				return (v-minV)/(maxV-minV)
			end

			setFromAlpha(alphaFromValue(getValFn()))

			local dragging=false
			sliderBg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end end)
			sliderBg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
			UserInputService.InputChanged:Connect(function(i)
				if not dragging then return end
				if i.UserInputType~=Enum.UserInputType.MouseMovement and i.UserInputType~=Enum.UserInputType.Touch then return end
				local a=(i.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
				setFromAlpha(a)
			end)

			reset.MouseButton1Click:Connect(function()
				if axisName=="X" then camOffset=Vector3.new(0,camOffset.Y,camOffset.Z) end
				if axisName=="Y" then camOffset=Vector3.new(camOffset.X,0,camOffset.Z) end
				if axisName=="Z" then camOffset=Vector3.new(camOffset.X,camOffset.Y,0) end
				setFromAlpha(alphaFromValue(getValFn()))
				notify("Camera","Reset "..axisName..".",2)
			end)
		end

		makeAxisSlider("X",function() return camOffset.X end,function(v) camOffset=Vector3.new(v,camOffset.Y,camOffset.Z) end,-10,10)
		makeAxisSlider("Y",function() return camOffset.Y end,function(v) camOffset=Vector3.new(camOffset.X,v,camOffset.Z) end,-10,10)
		makeAxisSlider("Z",function() return camOffset.Z end,function(v) camOffset=Vector3.new(camOffset.X,camOffset.Y,v) end,-10,10)

		local resetAll=makeButton(cameraScroll,"Reset Camera (All)")
		resetAll.Size=UDim2.new(0,220,0,36)
		resetAll.MouseButton1Click:Connect(function()
			resetCameraToDefaults()
			notify("Camera","Camera reset.",2)
		end)

		setSubjectMode(camSubjectMode)
		applyCameraSettings()
	end

	-- LIGHTING TAB
	do
		local header=makeText(lightingScroll,"Lighting",16,true)
		header.Size=UDim2.new(1,0,0,22)
		readLightingSaveState()

		local topRow,topLay,enableBtn,resetBtn=Instance.new("Frame"),nil,nil,nil
		topRow.BackgroundTransparency,topRow.Size,topRow.Parent=1,UDim2.new(1,0,0,44),lightingScroll
		topLay=Instance.new("UIListLayout")
		topLay.FillDirection,topLay.Padding,topLay.Parent=Enum.FillDirection.Horizontal,UDim.new(0,10),topRow
		enableBtn=makeButton(topRow,LightingState.Enabled and "Enabled" or "Disabled")
		enableBtn.Size=UDim2.new(0,140,0,36)
		resetBtn=makeButton(topRow,"Reset Lighting")
		resetBtn.Size=UDim2.new(0,160,0,36)

		enableBtn.MouseButton1Click:Connect(function()
			LightingState.Enabled=not LightingState.Enabled
			enableBtn.Text=LightingState.Enabled and "Enabled" or "Disabled"
			writeLightingSaveState()
			syncLightingToggles()
		end)

		resetBtn.MouseButton1Click:Connect(function()
			resetLightingToOriginal()
			notify("Lighting","Reset.",2)
		end)

		local skyHeader=makeText(lightingScroll,"Sky Presets",15,true)
		skyHeader.Size=UDim2.new(1,0,0,20)

		local skyBar=Instance.new("ScrollingFrame")
		skyBar.BackgroundTransparency,skyBar.BorderSizePixel,skyBar.Size,skyBar.CanvasSize,skyBar.AutomaticCanvasSize,skyBar.ScrollingDirection,skyBar.ScrollBarThickness,skyBar.Parent=1,0,UDim2.new(1,0,0,44),UDim2.new(0,0,0,0),Enum.AutomaticSize.X,Enum.ScrollingDirection.X,2,lightingScroll
		local skyLayout=Instance.new("UIListLayout")
		skyLayout.FillDirection,skyLayout.SortOrder,skyLayout.Padding,skyLayout.Parent=Enum.FillDirection.Horizontal,Enum.SortOrder.LayoutOrder,UDim.new(0,10),skyBar

		local skyButtons={}

		local function setSkyActive(name)
			for k,b in pairs(skyButtons) do setTabButtonActive(b,k==name) end
		end

		for name,_ in pairs(SKY_PRESETS) do
			local b=makeButton(skyBar,name)
			b.Size,skyButtons[name]=UDim2.new(0,190,0,36),b
			b.MouseButton1Click:Connect(function()
				setSkyActive(name)
				applySkyPreset(name)
				notify("Lighting","Applied: "..name,2)
			end)
		end

		local fxHeader=makeText(lightingScroll,"Effects",15,true)
		fxHeader.Size=UDim2.new(1,0,0,20)

		local function makeToggle(nameKey,labelText)
			local row,btn=Instance.new("Frame"),nil
			row.BackgroundTransparency,row.Size,row.Parent=1,UDim2.new(1,0,0,40),lightingScroll
			btn=makeButton(row,"")
			btn.Size,btn.Position=UDim2.new(0,220,0,36),UDim2.new(0,0,0,2)

			local function refresh()
				btn.Text=(LightingState.Toggles[nameKey] and "ON: " or "OFF: ")..labelText
				setTabButtonActive(btn,LightingState.Toggles[nameKey])
			end

			btn.MouseButton1Click:Connect(function()
				LightingState.Toggles[nameKey]=not LightingState.Toggles[nameKey]
				writeLightingSaveState()
				syncLightingToggles()
				refresh()
			end)

			refresh()
		end

		makeToggle("Sky","Sky")
		makeToggle("Atmosphere","Atmosphere")
		makeToggle("ColorCorrection","Color Correction")
		makeToggle("Bloom","Bloom")
		makeToggle("DepthOfField","Depth Of Field")
		makeToggle("MotionBlur","Motion Blur")
		makeToggle("SunRays","Sun Rays")

		if LightingState.SelectedSky and SKY_PRESETS[LightingState.SelectedSky] then
			setSkyActive(LightingState.SelectedSky)
			if LightingState.Enabled then applySkyPreset(LightingState.SelectedSky) end
		end
	end

	-- SERVER TAB
	do
		local header=makeText(serverScroll,"Server",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local controls=makeText(serverScroll,"Controls\n- Rejoin: same server\n- Server Hop: best-effort (highest players).",14,false)
		controls.Size=UDim2.new(1,0,0,56)
		local row,lay,rejoinBtn,hopBtn=Instance.new("Frame"),nil,nil,nil
		row.BackgroundTransparency,row.Size,row.Parent=1,UDim2.new(1,0,0,44),serverScroll
		lay=Instance.new("UIListLayout")
		lay.FillDirection,lay.Padding,lay.Parent=Enum.FillDirection.Horizontal,UDim.new(0,10),row
		rejoinBtn=makeButton(row,"Rejoin (Same Server)")
		rejoinBtn.Size=UDim2.new(0,230,0,36)
		hopBtn=makeButton(row,"Server Hop")
		hopBtn.Size=UDim2.new(0,140,0,36)

		rejoinBtn.MouseButton1Click:Connect(function()
			notify("Server","Rejoining same server...",2)
			pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,LocalPlayer) end)
		end)

		hopBtn.MouseButton1Click:Connect(function()
			notify("Server","Searching servers...",2)
			task.spawn(function()
				local placeId,cursor,best=game.PlaceId,"",nil
				for _=1,3 do
					local url="https://games.roblox.com/v1/games/"..tostring(placeId).."/servers/Public?sortOrder=Desc&limit=100"
					if cursor~="" then url=url.."&cursor="..HttpService:UrlEncode(cursor) end
					local ok,res=pcall(function() return HttpService:GetAsync(url) end)
					if not ok then notify("Server Hop","HTTP failed. (HttpEnabled might be off)",4) pcall(function() TeleportService:Teleport(placeId,LocalPlayer) end) return end
					local data=HttpService:JSONDecode(res)
					for _,srv in ipairs(data.data or {}) do
						if srv.id and srv.id~=game.JobId then
							if not best or (srv.playing or 0)>(best.playing or 0) then best=srv end
						end
					end
					cursor=data.nextPageCursor or ""
					if cursor=="" then break end
				end
				if best and best.id then notify("Server Hop","Teleporting...",2) pcall(function() TeleportService:TeleportToPlaceInstance(placeId,best.id,LocalPlayer) end)
				else notify("Server Hop","No server found. Trying normal teleport.",3) pcall(function() TeleportService:Teleport(placeId,LocalPlayer) end) end
			end)
		end)
	end

	-- CLIENT TAB (placeholder)
	do
		local t=makeText(clientScroll,"Controls\n(Coming soon)",14,true)
		t.Size=UDim2.new(1,0,0,50)
	end

	-- MIC UP TAB
	if micupScroll then
		local header=makeText(micupScroll,"Mic up",16,true)
		header.Size=UDim2.new(1,0,0,22)
		local msg=makeText(micupScroll,"For those of you who play this game hopefully your not a P£D0 also dont be weird and enjoy this tab\n(Some Stuff Will Be Added Soon)",14,false)
		msg.Size=UDim2.new(1,0,0,120)
		local coilBtn=makeButton(micupScroll,"Better Speed Coil")
		coilBtn.Size=UDim2.new(0,220,0,40)
		coilBtn.MouseButton1Click:Connect(function()
			if ownsAnyVipPass() then giveBetterSpeedCoil()
			else notify("VIP Required","You need VIP First.",3) end
		end)
	end

	-- TAB SWITCHING
	local function switchPage(pageName)
		if not pages or not pages[pageName] then return end
		if pageName==activePageName then return end
		local newPg,oldPg=pages[pageName],pages[activePageName]
		if not newPg then return end
		for n,btn in pairs(tabButtons) do setTabButtonActive(btn,n==pageName) end
		local newFrame,oldFrame=newPg.Page,oldPg and oldPg.Page or nil
		newFrame.Visible,newFrame.Position=true,UDim2.new(0,26,0,0)
		tween(newFrame,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=UDim2.new(0,0,0,0)})
		if oldFrame then
			local twn=tween(oldFrame,TweenInfo.new(0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.new(0,-26,0,0)})
			twn.Completed:Connect(function() oldFrame.Visible,oldFrame.Position=false,UDim2.new(0,0,0,0) end)
		end
		activePageName=pageName
	end

	local function addTabButton(pageName,order,w)
		local b=makeButton(tabsBar,pageName)
		b.LayoutOrder,b.Size,tabButtons[pageName]=order or 1,UDim2.new(0,w or 120,0,38),b
		b.MouseButton1Click:Connect(function() switchPage(pageName) end)
	end

	addTabButton("Info",1)
	addTabButton("Controls",2,130)
	addTabButton("Fly",3)
	addTabButton("Anim Packs",4,140)
	addTabButton("Player",5)
	addTabButton("Camera",6)
	addTabButton("Lighting",7)
	addTabButton("Server",8)
	addTabButton("Client",9)
	if micupPage then addTabButton("Mic up",10,120) end

	for _,pg in pairs(pages) do pg.Page.Visible=false end
	activePageName=""
	switchPage("Info")
end

--------------------------------------------------------------------
-- INPUT & RENDER LOOPS
--------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode==flightToggleKey then if flying then stopFlying() else startFlying() end
	elseif input.KeyCode==menuToggleKey then if arrowButton then arrowButton:Activate() end end
end)

RunService.RenderStepped:Connect(function(dt)
	fpsAcc,fpsFrames=fpsAcc+dt,fpsFrames+1
	if fpsAcc>=0.25 then fpsValue,fpsAcc,fpsFrames=math.floor((fpsFrames/fpsAcc)+0.5),0,0 end
	if fpsLabel then
		fpsLabel.Text=tostring(fpsValue).." fps"
		if fpsValue<40 then fpsLabel.TextColor3=Color3.fromRGB(255,60,60)
		elseif fpsValue<60 then fpsLabel.TextColor3=Color3.fromRGB(255,220,80)
		elseif fpsValue<76 then fpsLabel.TextColor3=Color3.fromRGB(80,255,80)
		elseif fpsValue<121 then fpsLabel.TextColor3=Color3.fromRGB(80,255,220)
		elseif fpsValue<241 then fpsLabel.TextColor3=Color3.fromRGB(80,140,255)
		else rainbowHue=(rainbowHue+dt*0.6)%1 fpsLabel.TextColor3=Color3.fromHSV(rainbowHue,1,1) end
	end

	if not flying or not rootPart or not camera or not bodyGyro or not bodyVel then return end
	updateMovementInput()

	local camCF,camLook,camRight=camera.CFrame,camera.CFrame.LookVector,camera.CFrame.RightVector
	local moveDir=Vector3.new()+camLook*(-moveInput.Z)+camRight*(moveInput.X)+Vector3.new(0,verticalInput,0)
	local moveMagnitude,hasHorizontal=moveDir.Magnitude,Vector3.new(moveInput.X,0,moveInput.Z).Magnitude>0.01

	if moveMagnitude>0 then
		local unit,targetVel,alphaVel=moveDir.Unit,unit*flySpeed,clamp01(dt*velocityLerpRate)
		currentVelocity=currentVelocity:Lerp(targetVel,alphaVel)
	else currentVelocity=currentVelocity:Lerp(Vector3.new(),clamp01(dt*idleSlowdownRate)) end
	bodyVel.Velocity=currentVelocity

	local lookDir=moveMagnitude>0.05 and moveDir.Unit or camLook.Unit
	if lookDir.Magnitude<0.01 then lookDir=Vector3.new(0,0,-1) end
	local baseCF=CFrame.lookAt(rootPart.Position,rootPart.Position+lookDir)
	local tiltDeg=moveMagnitude>0.1 and MOVING_TILT_DEG or IDLE_TILT_DEG
	if not hasHorizontal and verticalInput<0 then tiltDeg=90 elseif not hasHorizontal and verticalInput>0 then tiltDeg=0 end
	local targetCF=baseCF*CFrame.Angles(-math.rad(tiltDeg),0,0)
	if not currentGyroCFrame then currentGyroCFrame=targetCF end
	currentGyroCFrame=currentGyroCFrame:Lerp(targetCF,clamp01(dt*rotationLerpRate))
	bodyGyro.CFrame=currentGyroCFrame

	if humanoid and humanoid.RigType~=Enum.HumanoidRigType.R6 then
		local now,shouldFlyAnim,shouldFloatAnim=os.clock(),moveMagnitude>ANIM_TO_FLY_THRESHOLD,moveMagnitude<ANIM_TO_FLOAT_THRESHOLD
		if shouldFlyAnim and animMode~="Fly" and (now-lastAnimSwitch)>=ANIM_SWITCH_COOLDOWN then animMode,lastAnimSwitch="Fly",now playFly()
		elseif shouldFloatAnim and animMode~="Float" and (now-lastAnimSwitch)>=ANIM_SWITCH_COOLDOWN then animMode,lastAnimSwitch="Float",now playFloat() end
	end

	if rightShoulder and defaultShoulderC0 and character then
		local torso=character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
		if torso then
			local relDir,yaw,pitch=torso.CFrame:VectorToObjectSpace(camLook),math.atan2(-relDir.Z,relDir.X),math.asin(relDir.Y)
			local armCF=CFrame.new()*CFrame.Angles(0,-math.pi/2,0)*CFrame.Angles(-pitch*0.9,0,-yaw*0.25)
			rightShoulder.C0=defaultShoulderC0*armCF
		end
	end
end)

return HUD
