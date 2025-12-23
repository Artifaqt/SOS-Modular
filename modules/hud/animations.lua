-- modules/hud/animations.lua
-- Animation system (flight anims, state overrides, Animate script manipulation)

local AnimationsModule = {}

-- Services
local Debris = game:GetService("Debris")

-- Will be injected
local Settings
local Constants
local Data
local notify

-- State
local FLOAT_ID, FLY_ID
local DEFAULT_FLOAT_ID, DEFAULT_FLY_ID
local character, humanoid, animator
local floatTrack, flyTrack
local animMode = "Float"
local lastAnimSwitch = 0
local ANIM_SWITCH_COOLDOWN = 0.25
local ANIM_TO_FLY_THRESHOLD = 0.22
local ANIM_TO_FLOAT_THRESHOLD = 0.12

local VALID_ANIM_STATES = {Idle=true, Walk=true, Run=true, Jump=true, Climb=true, Fall=true, Swim=true}
local stateOverrides = {Idle=nil, Walk=nil, Run=nil, Jump=nil, Climb=nil, Fall=nil, Swim=nil}
local lastChosenState = "Idle"
local lastChosenCategory = "Custom"

function AnimationsModule.init(settingsModule, constantsModule, dataModule, notifyFunc, floatId, flyId)
	Settings = settingsModule
	Constants = constantsModule
	Data = dataModule
	notify = notifyFunc
	FLOAT_ID = floatId or Constants.DEFAULT_FLOAT_ID
	FLY_ID = flyId or Constants.DEFAULT_FLY_ID
	DEFAULT_FLOAT_ID = Constants.DEFAULT_FLOAT_ID
	DEFAULT_FLY_ID = Constants.DEFAULT_FLY_ID
end

function AnimationsModule.updateCharacter(char, hum)
	character = char
	humanoid = hum
end

local function stopAllPlayingTracks(hum)
	for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
		pcall(function() tr:Stop(0) end)
	end
end

function AnimationsModule.loadFlightTracks()
	if not humanoid then return end
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		animator, floatTrack, flyTrack = nil, nil, nil
		return
	end

	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	if floatTrack then pcall(function() floatTrack:Stop(0) end) end
	if flyTrack then pcall(function() flyTrack:Stop(0) end) end
	floatTrack, flyTrack = nil, nil

	-- Load float track
	do
		local a = Instance.new("Animation")
		a.AnimationId = FLOAT_ID
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then
			floatTrack = tr
			floatTrack.Priority = Enum.AnimationPriority.Action
			floatTrack.Looped = true
		else
			floatTrack = nil
		end
	end

	-- Load fly track
	do
		local a = Instance.new("Animation")
		a.AnimationId = FLY_ID
		local ok, tr = pcall(function() return animator:LoadAnimation(a) end)
		if ok and tr then
			flyTrack = tr
			flyTrack.Priority = Enum.AnimationPriority.Action
			flyTrack.Looped = true
		else
			flyTrack = nil
		end
	end

	animMode = "Float"
	lastAnimSwitch = 0
end

function AnimationsModule.playFloat()
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then return end
	if not floatTrack then return end
	if flyTrack and flyTrack.IsPlaying then pcall(function() flyTrack:Stop(0.25) end) end
	if not floatTrack.IsPlaying then pcall(function() floatTrack:Play(0.25) end) end
end

function AnimationsModule.playFly()
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then return end
	if not flyTrack then return end
	if floatTrack and floatTrack.IsPlaying then pcall(function() floatTrack:Stop(0.25) end) end
	if not flyTrack.IsPlaying then pcall(function() flyTrack:Play(0.25) end) end
end

function AnimationsModule.stopFlightAnims()
	if floatTrack then pcall(function() floatTrack:Stop(0.25) end) end
	if flyTrack then pcall(function() flyTrack:Stop(0.25) end) end
end

function AnimationsModule.updateFlightAnimation(moveMagnitude)
	if not humanoid or humanoid.RigType == Enum.HumanoidRigType.R6 then return end
	local now = os.clock()
	local shouldFlyAnim = moveMagnitude > ANIM_TO_FLY_THRESHOLD
	local shouldFloatAnim = moveMagnitude < ANIM_TO_FLOAT_THRESHOLD

	if shouldFlyAnim and animMode ~= "Fly" and (now - lastAnimSwitch) >= ANIM_SWITCH_COOLDOWN then
		animMode = "Fly"
		lastAnimSwitch = now
		AnimationsModule.playFly()
	elseif shouldFloatAnim and animMode ~= "Float" and (now - lastAnimSwitch) >= ANIM_SWITCH_COOLDOWN then
		animMode = "Float"
		lastAnimSwitch = now
		AnimationsModule.playFloat()
	end
end

-- Animate script override system
local function getAnimateScript()
	if not character then return nil end
	return character:FindFirstChild("Animate")
end

function AnimationsModule.applyStateOverrideToAnimate(stateName, assetIdStr)
	local animate = getAnimateScript()
	if not animate then
		if notify then notify("Anim Packs", "No Animate script found in character.", 3) end
		return false
	end
	if not humanoid then return false end

	animate.Disabled = true
	stopAllPlayingTracks(humanoid)

	local folder = animate:FindFirstChild(stateName:lower())
	if not folder then
		animate.Disabled = false
		return false
	end

	if stateName == "Idle" then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Animation") then
				child.AnimationId = assetIdStr
			end
		end
	else
		local anim = folder:FindFirstChildOfClass("Animation")
		if anim then
			anim.AnimationId = assetIdStr
		end
	end

	animate.Disabled = false
	return true
end

function AnimationsModule.reapplyAllOverridesAfterRespawn()
	for state, override in pairs(stateOverrides) do
		if override and VALID_ANIM_STATES[state] then
			task.wait(0.05)
			AnimationsModule.applyStateOverrideToAnimate(state, override)
		end
	end
end

-- Getters/Setters
function AnimationsModule.getFLOAT_ID() return FLOAT_ID end
function AnimationsModule.setFLOAT_ID(id) FLOAT_ID = id end
function AnimationsModule.getFLY_ID() return FLY_ID end
function AnimationsModule.setFLY_ID(id) FLY_ID = id end
function AnimationsModule.getDEFAULT_FLOAT_ID() return DEFAULT_FLOAT_ID end
function AnimationsModule.getDEFAULT_FLY_ID() return DEFAULT_FLY_ID end
function AnimationsModule.getStateOverrides() return stateOverrides end
function AnimationsModule.getLastChosenState() return lastChosenState end
function AnimationsModule.setLastChosenState(state) lastChosenState = state end
function AnimationsModule.getLastChosenCategory() return lastChosenCategory end
function AnimationsModule.setLastChosenCategory(cat) lastChosenCategory = cat end

return AnimationsModule
