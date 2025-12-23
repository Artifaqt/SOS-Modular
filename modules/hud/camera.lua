-- modules/hud/camera.lua
-- Camera control system

local CameraModule = {}

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Will be injected
local Settings
local Constants

-- State
local DEFAULT_FOV, DEFAULT_CAM_MIN_ZOOM, DEFAULT_CAM_MAX_ZOOM
local DEFAULT_CAMERA_SUBJECT_MODE = "Humanoid"
local INFINITE_ZOOM = 1e9

local camSubjectMode = DEFAULT_CAMERA_SUBJECT_MODE
local camOffset = Vector3.new()
local camFov = nil
local camMaxZoom = INFINITE_ZOOM

local character, humanoid

function CameraModule.init(settingsModule, constantsModule, char, hum)
	Settings = settingsModule
	Constants = constantsModule
	character = char
	humanoid = hum

	-- Capture defaults
	if not DEFAULT_FOV then DEFAULT_FOV = camera.FieldOfView end
	if not DEFAULT_CAM_MIN_ZOOM then DEFAULT_CAM_MIN_ZOOM = LocalPlayer.CameraMinZoomDistance end
	if not DEFAULT_CAM_MAX_ZOOM then DEFAULT_CAM_MAX_ZOOM = LocalPlayer.CameraMaxZoomDistance end
end

function CameraModule.updateCharacter(char, hum)
	character = char
	humanoid = hum
end

function CameraModule.resolveCameraSubject(mode)
	if not character then return nil end
	if mode == "Humanoid" then return humanoid end
	if mode == "Head" then return character:FindFirstChild("Head") or humanoid end
	if mode == "HumanoidRootPart" then return character:FindFirstChild("HumanoidRootPart") or humanoid end
	if mode == "Torso" then return character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") or humanoid end
	if mode == "UpperTorso" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or humanoid end
	if mode == "LowerTorso" then return character:FindFirstChild("LowerTorso") or humanoid end
	return humanoid
end

function CameraModule.applyCameraSettings()
	if not camera then return end
	LocalPlayer.CameraMaxZoomDistance = camMaxZoom or INFINITE_ZOOM
	LocalPlayer.CameraMinZoomDistance = DEFAULT_CAM_MIN_ZOOM or 0.5
	if camFov then camera.FieldOfView = camFov end
	local subject = CameraModule.resolveCameraSubject(camSubjectMode)
	if subject then camera.CameraSubject = subject end
	if humanoid then humanoid.CameraOffset = camOffset end
end

function CameraModule.resetCameraToDefaults()
	if DEFAULT_FOV and camera then
		camFov = DEFAULT_FOV
		camera.FieldOfView = DEFAULT_FOV
	end
	if DEFAULT_CAM_MIN_ZOOM ~= nil then
		LocalPlayer.CameraMinZoomDistance = DEFAULT_CAM_MIN_ZOOM
	end
	camMaxZoom = INFINITE_ZOOM
	LocalPlayer.CameraMaxZoomDistance = INFINITE_ZOOM
	camSubjectMode = DEFAULT_CAMERA_SUBJECT_MODE
	camOffset = Vector3.new()
	if humanoid then humanoid.CameraOffset = camOffset end
	CameraModule.applyCameraSettings()
	if Settings then Settings.scheduleSave() end
end

-- Getters/Setters
function CameraModule.getCamSubjectMode() return camSubjectMode end
function CameraModule.setCamSubjectMode(mode) camSubjectMode = mode end
function CameraModule.getCamOffset() return camOffset end
function CameraModule.setCamOffset(offset) camOffset = offset end
function CameraModule.getCamFov() return camFov end
function CameraModule.setCamFov(fov) camFov = fov end
function CameraModule.getCamMaxZoom() return camMaxZoom end
function CameraModule.setCamMaxZoom(zoom) camMaxZoom = zoom end

return CameraModule
