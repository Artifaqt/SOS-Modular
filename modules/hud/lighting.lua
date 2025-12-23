-- modules/hud/lighting.lua
-- Lighting system for HUD (sky presets, effects, toggles)

local LightingModule = {}

-- Services
local Lighting = game:GetService("Lighting")

-- Will be injected by main HUD
local Settings
local Data

--------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------
local ORIGINAL_LIGHTING = {}
local LightingState = {
	Enabled = true,
	SelectedSky = nil,
	Toggles = {
		Sky = true,
		Atmosphere = true,
		ColorCorrection = true,
		Bloom = true,
		DepthOfField = true,
		MotionBlur = true,
		SunRays = true
	}
}

--------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------
function LightingModule.init(settingsModule, dataModule)
	Settings = settingsModule
	Data = dataModule

	-- Capture original lighting
	ORIGINAL_LIGHTING = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		ExposureCompensation = Lighting.ExposureCompensation,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		FogColor = Lighting.FogColor,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		GeographicLatitude = Lighting.GeographicLatitude,
	}

	-- Clone existing effects
	local function cloneIfExists(className)
		for _, inst in ipairs(Lighting:GetChildren()) do
			if inst.ClassName == className then
				return inst:Clone()
			end
		end
		return nil
	end

	ORIGINAL_LIGHTING.Sky = cloneIfExists("Sky")
	ORIGINAL_LIGHTING.Atmosphere = cloneIfExists("Atmosphere")
	ORIGINAL_LIGHTING.Bloom = cloneIfExists("BloomEffect")
	ORIGINAL_LIGHTING.ColorCorrection = cloneIfExists("ColorCorrectionEffect")
	ORIGINAL_LIGHTING.DepthOfField = cloneIfExists("DepthOfFieldEffect")
	ORIGINAL_LIGHTING.Blur = cloneIfExists("BlurEffect")
	ORIGINAL_LIGHTING.SunRays = cloneIfExists("SunRaysEffect")
end

--------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------
local function getOrCreateEffect(className, name)
	local inst = Lighting:FindFirstChild(name)
	if inst and inst.ClassName == className then
		return inst
	end
	if inst then
		inst:Destroy()
	end
	local newInst = Instance.new(className)
	newInst.Name = name
	newInst.Parent = Lighting
	return newInst
end

local function destroyIfExists(name)
	local inst = Lighting:FindFirstChild(name)
	if inst then
		inst:Destroy()
	end
end

local function applyFancyDefaults()
	Lighting.Brightness = 2
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.ExposureCompensation = 0.15
end

local function removeSOSLightingOnly()
	for _, name in ipairs({"SOS_Sky", "SOS_Atmosphere", "SOS_Bloom", "SOS_ColorCorrection", "SOS_DepthOfField", "SOS_MotionBlur", "SOS_SunRays"}) do
		destroyIfExists(name)
	end
end

--------------------------------------------------------------------
-- SAVE/LOAD STATE
--------------------------------------------------------------------
function LightingModule.writeLightingSaveState()
	_G.__SOS_LightingSaveState = {
		Enabled = LightingState.Enabled,
		SelectedSky = LightingState.SelectedSky,
		Toggles = LightingState.Toggles
	}
	if Settings then
		Settings.scheduleSave()
	end
end

function LightingModule.readLightingSaveState()
	local s = _G.__SOS_LightingSaveState
	if typeof(s) ~= "table" then
		return
	end
	if typeof(s.Enabled) == "boolean" then
		LightingState.Enabled = s.Enabled
	end
	if typeof(s.SelectedSky) == "string" then
		LightingState.SelectedSky = s.SelectedSky
	end
	if typeof(s.Toggles) == "table" then
		for k, v in pairs(s.Toggles) do
			if typeof(v) == "boolean" and LightingState.Toggles[k] ~= nil then
				LightingState.Toggles[k] = v
			end
		end
	end
end

--------------------------------------------------------------------
-- SKY PRESET APPLICATION
--------------------------------------------------------------------
function LightingModule.applySkyPreset(name)
	LightingState.SelectedSky = name
	LightingModule.writeLightingSaveState()

	if not LightingState.Enabled then
		return
	end

	local preset = Data.SKY_PRESETS[name]
	if not preset then
		return
	end

	applyFancyDefaults()

	-- Apply Sky
	if LightingState.Toggles.Sky then
		local sky = getOrCreateEffect("Sky", "SOS_Sky")
		sky.SkyboxBk = preset.Sky.Bk
		sky.SkyboxDn = preset.Sky.Dn
		sky.SkyboxFt = preset.Sky.Ft
		sky.SkyboxLf = preset.Sky.Lf
		sky.SkyboxRt = preset.Sky.Rt
		sky.SkyboxUp = preset.Sky.Up
	else
		destroyIfExists("SOS_Sky")
	end

	-- Apply Color Correction
	if LightingState.Toggles.ColorCorrection then
		local cc = getOrCreateEffect("ColorCorrectionEffect", "SOS_ColorCorrection")
		cc.Enabled = true
		cc.Brightness = 0.02
		cc.Contrast = 0.18
		cc.Saturation = 0.06
		cc.TintColor = Color3.fromRGB(255, 240, 240)
	else
		destroyIfExists("SOS_ColorCorrection")
	end

	-- Apply Bloom
	if LightingState.Toggles.Bloom then
		local bloom = getOrCreateEffect("BloomEffect", "SOS_Bloom")
		bloom.Enabled = true
		bloom.Intensity = 0.8
		bloom.Size = 28
		bloom.Threshold = 1
	else
		destroyIfExists("SOS_Bloom")
	end

	-- Apply Depth of Field
	if LightingState.Toggles.DepthOfField then
		local dof = getOrCreateEffect("DepthOfFieldEffect", "SOS_DepthOfField")
		dof.Enabled = true
		dof.FarIntensity = 0.12
		dof.FocusDistance = 55
		dof.InFocusRadius = 40
		dof.NearIntensity = 0.25
	else
		destroyIfExists("SOS_DepthOfField")
	end

	-- Apply Motion Blur
	if LightingState.Toggles.MotionBlur then
		local blur = getOrCreateEffect("BlurEffect", "SOS_MotionBlur")
		blur.Enabled = true
		blur.Size = 2
	else
		destroyIfExists("SOS_MotionBlur")
	end

	-- Apply Sun Rays
	if LightingState.Toggles.SunRays then
		local rays = getOrCreateEffect("SunRaysEffect", "SOS_SunRays")
		rays.Enabled = true
		rays.Intensity = 0.06
		rays.Spread = 0.75
	else
		destroyIfExists("SOS_SunRays")
	end

	-- Apply Atmosphere
	if LightingState.Toggles.Atmosphere then
		local atm = getOrCreateEffect("Atmosphere", "SOS_Atmosphere")
		atm.Density = 0.32
		atm.Offset = 0.1
		atm.Color = Color3.fromRGB(210, 200, 255)
		atm.Decay = Color3.fromRGB(70, 60, 90)
		atm.Glare = 0.12
		atm.Haze = 1
	else
		destroyIfExists("SOS_Atmosphere")
	end
end

--------------------------------------------------------------------
-- RESET LIGHTING
--------------------------------------------------------------------
function LightingModule.resetLightingToOriginal()
	removeSOSLightingOnly()

	Lighting.Ambient = ORIGINAL_LIGHTING.Ambient
	Lighting.OutdoorAmbient = ORIGINAL_LIGHTING.OutdoorAmbient
	Lighting.Brightness = ORIGINAL_LIGHTING.Brightness
	Lighting.ClockTime = ORIGINAL_LIGHTING.ClockTime
	Lighting.ExposureCompensation = ORIGINAL_LIGHTING.ExposureCompensation
	Lighting.EnvironmentDiffuseScale = ORIGINAL_LIGHTING.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = ORIGINAL_LIGHTING.EnvironmentSpecularScale
	Lighting.FogColor = ORIGINAL_LIGHTING.FogColor
	Lighting.FogEnd = ORIGINAL_LIGHTING.FogEnd
	Lighting.FogStart = ORIGINAL_LIGHTING.FogStart
	Lighting.GeographicLatitude = ORIGINAL_LIGHTING.GeographicLatitude

	local function restoreClone(cloneObj, className)
		if not cloneObj then
			return
		end
		for _, inst in ipairs(Lighting:GetChildren()) do
			if inst.ClassName == className then
				inst:Destroy()
			end
		end
		local c = cloneObj:Clone()
		c.Parent = Lighting
	end

	restoreClone(ORIGINAL_LIGHTING.Sky, "Sky")
	restoreClone(ORIGINAL_LIGHTING.Atmosphere, "Atmosphere")
	restoreClone(ORIGINAL_LIGHTING.Bloom, "BloomEffect")
	restoreClone(ORIGINAL_LIGHTING.ColorCorrection, "ColorCorrectionEffect")
	restoreClone(ORIGINAL_LIGHTING.DepthOfField, "DepthOfFieldEffect")
	restoreClone(ORIGINAL_LIGHTING.Blur, "BlurEffect")
	restoreClone(ORIGINAL_LIGHTING.SunRays, "SunRaysEffect")

	LightingState.SelectedSky = nil
	LightingModule.writeLightingSaveState()
end

--------------------------------------------------------------------
-- SYNC TOGGLES
--------------------------------------------------------------------
function LightingModule.syncLightingToggles()
	if not LightingState.Enabled then
		removeSOSLightingOnly()
		return
	end

	if LightingState.SelectedSky and Data.SKY_PRESETS[LightingState.SelectedSky] then
		LightingModule.applySkyPreset(LightingState.SelectedSky)
	end
end

--------------------------------------------------------------------
-- GETTERS
--------------------------------------------------------------------
function LightingModule.getLightingState()
	return LightingState
end

return LightingModule
