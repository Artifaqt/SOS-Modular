-- modules/hud/flight.lua
-- Flight physics and movement system

local FlightModule = {}

-- Services
local UserInputService = game:GetService("UserInputService")

-- Key tracking (more reliable than IsKeyDown in some environments)
local keyDown = {}
local inputConnectionsBound = false

local function setKey(input, isDown)
	if input and input.KeyCode then
		keyDown[input.KeyCode] = isDown and true or nil
	end
end

local function isDown(keyCode)
	return keyDown[keyCode] == true
end

local function bindInputConnections()
	if inputConnectionsBound then return end
	inputConnectionsBound = true

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		setKey(input, true)
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		setKey(input, false)
	end)

	-- Safety: clear stuck keys when window focus is lost
	if UserInputService.WindowFocusReleased then
		UserInputService.WindowFocusReleased:Connect(function()
			keyDown = {}
		end)
	end
end


-- Will be injected
local AnimationsModule

-- State
local flying = false
local bodyGyro, bodyVel
local currentVelocity = Vector3.new()
local currentGyroCFrame = nil
local moveInput = Vector3.new()
local verticalInput = 0
local rightShoulder, defaultShoulderC0
local originalRunSoundStates = {}

-- Config
local velocityLerpRate = 7.0
local rotationLerpRate = 7.0
local idleSlowdownRate = 2.6
local MOVING_TILT_DEG = 85
local IDLE_TILT_DEG = 10

local character, humanoid, rootPart, camera
local IS_MOBILE

function FlightModule.init(animModule, isMobile)
	AnimationsModule = animModule
	IS_MOBILE = isMobile
	if UserInputService.KeyboardEnabled then
		bindInputConnections()
	end
end

function FlightModule.updateCharacter(char, hum, root, cam, shoulder, shoulderC0)
	character = char
	humanoid = hum
	rootPart = root
	camera = cam
	if not camera then camera = workspace.CurrentCamera end
	rightShoulder = shoulder
	defaultShoulderC0 = shoulderC0
	originalRunSoundStates = {}
end

local function cacheAndMuteRunSounds()
	if not character then return end
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Sound") then
			local nameLower = string.lower(desc.Name)
			if nameLower:find("run") or nameLower:find("walk") or nameLower:find("footstep") then
				if not originalRunSoundStates[desc] then
					originalRunSoundStates[desc] = {Volume = desc.Volume, Playing = desc.Playing}
				end
				desc.Volume = 0
				desc.Playing = false
			end
		end
	end
end

local function restoreRunSounds()
	for sound, data in pairs(originalRunSoundStates) do
		if sound and sound.Parent then
			sound.Volume = data.Volume or 0.5
			if data.Playing then sound.Playing = true end
		end
	end
end

function FlightModule.startFlying()
	if flying then return end
	if not humanoid or not rootPart then return end

	flying = true
	humanoid.PlatformStand = true

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.P = 1e5
	bodyGyro.D = 1000
	bodyGyro.Parent = rootPart

	bodyVel = Instance.new("BodyVelocity")
	bodyVel.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVel.P = 1250
	bodyVel.Velocity = Vector3.new()
	bodyVel.Parent = rootPart

	cacheAndMuteRunSounds()
	if AnimationsModule then AnimationsModule.playFloat() end
end

function FlightModule.stopFlying()
	if not flying then return end
	flying = false

	if AnimationsModule then AnimationsModule.stopFlightAnims() end

	if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
	if bodyVel then bodyVel:Destroy() bodyVel = nil end
	if humanoid then humanoid.PlatformStand = false end
	if rightShoulder and defaultShoulderC0 then
		rightShoulder.C0 = defaultShoulderC0
	end

	restoreRunSounds()
end

function FlightModule.updateMovementInput()
	local forward, backward, left, right, up, down = 0, 0, 0, 0, 0, 0

	-- WASD only when not mobile. Use event-tracked keys first, then fall back to IsKeyDown.
	if not IS_MOBILE then
		local W = (isDown and isDown(Enum.KeyCode.W)) or UserInputService:IsKeyDown(Enum.KeyCode.W)
		local S = (isDown and isDown(Enum.KeyCode.S)) or UserInputService:IsKeyDown(Enum.KeyCode.S)
		local A = (isDown and isDown(Enum.KeyCode.A)) or UserInputService:IsKeyDown(Enum.KeyCode.A)
		local D = (isDown and isDown(Enum.KeyCode.D)) or UserInputService:IsKeyDown(Enum.KeyCode.D)
		local E = (isDown and isDown(Enum.KeyCode.E)) or UserInputService:IsKeyDown(Enum.KeyCode.E)
		local Space = (isDown and isDown(Enum.KeyCode.Space)) or UserInputService:IsKeyDown(Enum.KeyCode.Space)
		local Q = (isDown and isDown(Enum.KeyCode.Q)) or UserInputService:IsKeyDown(Enum.KeyCode.Q)
		local Ctrl = (isDown and isDown(Enum.KeyCode.LeftControl)) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)

		if W then forward = 1 end
		if S then backward = 1 end
		if A then left = 1 end
		if D then right = 1 end
		if E or Space then up = 1 end
		if Q or Ctrl then down = 1 end
	end

	moveInput = Vector3.new(right - left, 0, backward - forward)
	verticalInput = up - down
end


function FlightModule.renderStep(dt, flySpeed)
	if not flying or not rootPart or not bodyGyro or not bodyVel then return end

	-- CurrentCamera can be nil early during load or can change; refresh defensively
	camera = camera or workspace.CurrentCamera
	if not camera then return end

	FlightModule.updateMovementInput()

	local camCF = camera.CFrame
	local camLook = camera.CFrame.LookVector
	local camRight = camera.CFrame.RightVector
	local moveDir = Vector3.new() + camLook * (-moveInput.Z) + camRight * (moveInput.X) + Vector3.new(0, verticalInput, 0)
	local moveMagnitude = moveDir.Magnitude
	local hasHorizontal = Vector3.new(moveInput.X, 0, moveInput.Z).Magnitude > 0.01

	if moveMagnitude > 0 then
		local unit = moveDir.Unit
		local targetVel = unit * flySpeed
		local alphaVel = clamp01(dt * velocityLerpRate)
		currentVelocity = currentVelocity:Lerp(targetVel, alphaVel)
	else
		currentVelocity = currentVelocity:Lerp(Vector3.new(), clamp01(dt * idleSlowdownRate))
	end
	bodyVel.Velocity = currentVelocity

	local lookDir = moveMagnitude > 0.05 and moveDir.Unit or camLook.Unit
	if lookDir.Magnitude < 0.01 then lookDir = Vector3.new(0, 0, -1) end
	local baseCF = CFrame.lookAt(rootPart.Position, rootPart.Position + lookDir)
	local tiltDeg = moveMagnitude > 0.1 and MOVING_TILT_DEG or IDLE_TILT_DEG
	if not hasHorizontal and verticalInput < 0 then tiltDeg = 90
	elseif not hasHorizontal and verticalInput > 0 then tiltDeg = 0 end
	local targetCF = baseCF * CFrame.Angles(-math.rad(tiltDeg), 0, 0)
	if not currentGyroCFrame then currentGyroCFrame = targetCF end
	currentGyroCFrame = currentGyroCFrame:Lerp(targetCF, clamp01(dt * rotationLerpRate))
	bodyGyro.CFrame = currentGyroCFrame

	-- Update flight animation based on movement
	if AnimationsModule then
		AnimationsModule.updateFlightAnimation(moveMagnitude)
	end

	-- Right arm tracking
	if rightShoulder and defaultShoulderC0 and character then
		local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
		if torso then
			local relDir = torso.CFrame:VectorToObjectSpace(camLook)
			local yaw = math.atan2(-relDir.Z, relDir.X)
			local pitch = math.asin(relDir.Y)
			local armCF = CFrame.new() * CFrame.Angles(0, -math.pi / 2, 0) * CFrame.Angles(-pitch * 0.9, 0, -yaw * 0.25)
			rightShoulder.C0 = defaultShoulderC0 * armCF
		end
	end

	return moveMagnitude
end

-- Getters/Setters
function FlightModule.isFlying() return flying end
function FlightModule.getBodyGyro() return bodyGyro end
function FlightModule.getBodyVel() return bodyVel end
function FlightModule.setFlySpeed(speed)
	-- This is just for state synchronization
	-- The actual flySpeed is passed to renderStep
end

return FlightModule