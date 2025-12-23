-- modules/hud/data.lua
-- All data tables for HUD system (animation packs, custom animations, sky presets)

local Data = {}

--------------------------------------------------------------------
-- ANIMATION PACKS DATA
--------------------------------------------------------------------
Data.AnimationPacks = {
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

Data.UnreleasedNames = {"Cowboy","Princess","ZombieFE","Confident","Ghost","Patrol","Popstar","Sneaky"}

Data.CustomIdle = {
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

Data.CustomRun = {
	["Tall"]=134010853417610,["Officer Earl"]=104646820775114,["AOT Titan"]=95363958550738,["Captain JS"]=87806542116815,
	["Ninja Sprint"]=123763532572423,["IDEK"]=101293881003047,["Honored One"]=82260970223217,["Head Hold"]=92715775326925,
	["Robot Speed 3"]=128047975332475,["Springtrap Sturdy"]=80927378599036,["UFO"]=118703314621593,
	["Closed Eyes Vibe"]=117991470645633,["Wally West"]=102622695004986,["Squidward"]=82365330773489,
	["On A Mission"]=113718116290824,["Very Happy Run"]=86522070222739,["Missile"]=92401041987431,["I Wanna Run Away"]=78510387198062,
}

Data.CustomWalk = {
	["Football/Soccer"]=116881956670910,["Animal"]=87721497492370,["Fredbear"]=133284420439423,["Cute Anime"]=106767496454996
}

--------------------------------------------------------------------
-- SKY PRESETS DATA
--------------------------------------------------------------------
Data.SKY_PRESETS = {
	["Crimson Night"] = {
		Sky = {
			Bk = "rbxassetid://401664839", Dn = "rbxassetid://401664862",
			Ft = "rbxassetid://401664960", Lf = "rbxassetid://401665012",
			Rt = "rbxassetid://401665050", Up = "rbxassetid://401665111",
			SunAngularSize = 11, MoonAngularSize = 11, StarCount = 3000,
		},
		Lighting = {
			Ambient = Color3.fromRGB(170, 0, 0), OutdoorAmbient = Color3.fromRGB(170, 0, 0),
			Brightness = 2, ClockTime = 0, FogColor = Color3.fromRGB(80, 0, 0),
			FogEnd = 500, FogStart = 0,
		},
		Effects = {
			Bloom = { Intensity = 0.8, Size = 24, Threshold = 0.8 },
			ColorCorrection = { Brightness = 0.05, Contrast = 0.2, Saturation = 0.3, TintColor = Color3.fromRGB(255, 200, 200) },
			DepthOfField = { FarIntensity = 0.1, FocusDistance = 50, InFocusRadius = 30, NearIntensity = 0.75 },
			SunRays = { Intensity = 0.15, Spread = 0.8 },
		},
	},
	["Deep Space"] = {
		Sky = {
			Bk = "rbxassetid://149397692", Dn = "rbxassetid://149397686",
			Ft = "rbxassetid://149397697", Lf = "rbxassetid://149397684",
			Rt = "rbxassetid://149397688", Up = "rbxassetid://149397702",
			SunAngularSize = 8, MoonAngularSize = 8, StarCount = 5000,
		},
		Lighting = {
			Ambient = Color3.fromRGB(0, 0, 50), OutdoorAmbient = Color3.fromRGB(0, 0, 50),
			Brightness = 1.5, ClockTime = 0, FogColor = Color3.fromRGB(0, 0, 30),
			FogEnd = 800, FogStart = 100,
		},
		Effects = {
			Bloom = { Intensity = 1.2, Size = 32, Threshold = 0.5 },
			ColorCorrection = { Brightness = -0.1, Contrast = 0.3, Saturation = 0, TintColor = Color3.fromRGB(200, 200, 255) },
			Atmosphere = { Density = 0.4, Offset = 0.5, Color = Color3.fromRGB(100, 100, 180), Glare = 0.5, Haze = 1 },
		},
	},
	["Vaporwave Nebula"] = {
		Sky = {
			Bk = "rbxassetid://1417494030", Dn = "rbxassetid://1417494146",
			Ft = "rbxassetid://1417494253", Lf = "rbxassetid://1417494643",
			Rt = "rbxassetid://1417495187", Up = "rbxassetid://1417495827",
			SunAngularSize = 15, MoonAngularSize = 15, StarCount = 2000,
		},
		Lighting = {
			Ambient = Color3.fromRGB(255, 0, 150), OutdoorAmbient = Color3.fromRGB(255, 100, 255),
			Brightness = 2.5, ClockTime = 6, FogColor = Color3.fromRGB(255, 150, 255),
			FogEnd = 600, FogStart = 50,
		},
		Effects = {
			Bloom = { Intensity = 1.5, Size = 40, Threshold = 0.3 },
			ColorCorrection = { Brightness = 0.1, Contrast = 0.1, Saturation = 0.5, TintColor = Color3.fromRGB(255, 150, 255) },
			SunRays = { Intensity = 0.25, Spread = 1 },
		},
	},
	["Sunset Paradise"] = {
		Sky = {
			Bk = "rbxassetid://570557514", Dn = "rbxassetid://570557620",
			Ft = "rbxassetid://570557559", Lf = "rbxassetid://570557620",
			Rt = "rbxassetid://570557559", Up = "rbxassetid://570557620",
			SunAngularSize = 12, MoonAngularSize = 12, StarCount = 1000,
		},
		Lighting = {
			Ambient = Color3.fromRGB(255, 150, 100), OutdoorAmbient = Color3.fromRGB(255, 200, 150),
			Brightness = 2, ClockTime = 17, FogColor = Color3.fromRGB(255, 180, 120),
			FogEnd = 1000, FogStart = 200,
		},
		Effects = {
			Bloom = { Intensity = 1, Size = 28, Threshold = 0.6 },
			ColorCorrection = { Brightness = 0.15, Contrast = 0.15, Saturation = 0.4, TintColor = Color3.fromRGB(255, 220, 180) },
			SunRays = { Intensity = 0.35, Spread = 0.7 },
			Atmosphere = { Density = 0.3, Offset = 0.3, Color = Color3.fromRGB(255, 200, 150), Glare = 0.6, Haze = 0.8 },
		},
	},
	["Arctic Storm"] = {
		Sky = {
			Bk = "rbxassetid://5260808177", Dn = "rbxassetid://5260808177",
			Ft = "rbxassetid://5260808177", Lf = "rbxassetid://5260808177",
			Rt = "rbxassetid://5260808177", Up = "rbxassetid://5260808177",
			SunAngularSize = 5, MoonAngularSize = 5, StarCount = 500,
		},
		Lighting = {
			Ambient = Color3.fromRGB(150, 180, 200), OutdoorAmbient = Color3.fromRGB(180, 200, 220),
			Brightness = 1, ClockTime = 12, FogColor = Color3.fromRGB(200, 220, 240),
			FogEnd = 300, FogStart = 0,
		},
		Effects = {
			Bloom = { Intensity = 0.5, Size = 20, Threshold = 0.9 },
			ColorCorrection = { Brightness = 0, Contrast = 0.1, Saturation = -0.2, TintColor = Color3.fromRGB(220, 230, 255) },
			DepthOfField = { FarIntensity = 0.2, FocusDistance = 80, InFocusRadius = 40, NearIntensity = 0.5 },
			Atmosphere = { Density = 0.5, Offset = 0.2, Color = Color3.fromRGB(200, 220, 240), Glare = 0.3, Haze = 1.2 },
		},
	},
}

--------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------
function Data.isInUnreleased(name)
	for _,n in ipairs(Data.UnreleasedNames) do if n==name then return true end end
	return false
end

function Data.listCustomNamesForState(state)
	local t,src={},nil
	if state=="Idle" then src=Data.CustomIdle
	elseif state=="Run" then src=Data.CustomRun
	elseif state=="Walk" then src=Data.CustomWalk end
	if not src then return t end
	for name,_ in pairs(src) do table.insert(t,name) end
	table.sort(t)
	return t
end

function Data.getCustomIdForState(name,state)
	if state=="Idle" then return Data.CustomIdle[name]
	elseif state=="Run" then return Data.CustomRun[name]
	elseif state=="Walk" then return Data.CustomWalk[name] end
	return nil
end

function Data.listPackNamesForCategory(cat)
	local names={}
	for name,_ in pairs(Data.AnimationPacks) do
		if cat=="Unreleased" then
			if Data.isInUnreleased(name) then table.insert(names,name) end
		elseif cat=="Roblox Anims" then
			if not Data.isInUnreleased(name) then table.insert(names,name) end
		end
	end
	table.sort(names)
	return names
end

function Data.getPackValueForState(packName,state)
	local pack=Data.AnimationPacks[packName]
	if not pack then return nil end
	if state=="Idle" then return pack.Idle1 or pack.Idle2
	elseif state=="Walk" then return pack.Walk
	elseif state=="Run" then return pack.Run
	elseif state=="Jump" then return pack.Jump
	elseif state=="Climb" then return pack.Climb
	elseif state=="Fall" then return pack.Fall
	elseif state=="Swim" then return nil end
	return nil
end

return Data
