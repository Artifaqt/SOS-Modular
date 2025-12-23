-- utils/settings.lua
-- Settings save/load system (per UserId)

local SettingsUtils = {}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local SETTINGS_FILE_PREFIX = "SOS_HUD_Settings_"
local SETTINGS_ATTR_NAME = "SOS_HUD_SETTINGS_JSON"

local pendingSave = false

--------------------------------------------------------------------
-- FILE I/O HELPERS
--------------------------------------------------------------------

function SettingsUtils.canFileIO()
	return (typeof(readfile) == "function") and (typeof(writefile) == "function") and (typeof(isfile) == "function")
end

function SettingsUtils.getSettingsFileName()
	return SETTINGS_FILE_PREFIX .. tostring(LocalPlayer.UserId) .. ".json"
end

--------------------------------------------------------------------
-- ENCODE/DECODE
--------------------------------------------------------------------

function SettingsUtils.encodeSettings(tbl)
	local ok, res = pcall(function()
		return HttpService:JSONEncode(tbl)
	end)
	if ok then return res end
	return nil
end

function SettingsUtils.decodeSettings(str)
	local ok, res = pcall(function()
		return HttpService:JSONDecode(str)
	end)
	if ok and typeof(res) == "table" then
		return res
	end
	return nil
end

--------------------------------------------------------------------
-- LOAD SETTINGS
--------------------------------------------------------------------

function SettingsUtils.loadSettings()
	local raw = nil

	-- Try file first
	if SettingsUtils.canFileIO() then
		local file = SettingsUtils.getSettingsFileName()
		if isfile(file) then
			local ok, data = pcall(function()
				return readfile(file)
			end)
			if ok and type(data) == "string" and #data > 0 then
				raw = data
			end
		end
	end

	-- Fallback to attribute
	if not raw then
		local attr = LocalPlayer:GetAttribute(SETTINGS_ATTR_NAME)
		if type(attr) == "string" and #attr > 0 then
			raw = attr
		end
	end

	if raw then
		return SettingsUtils.decodeSettings(raw)
	end

	return nil
end

--------------------------------------------------------------------
-- SAVE SETTINGS
--------------------------------------------------------------------

function SettingsUtils.saveSettingsNow(tbl)
	local json = SettingsUtils.encodeSettings(tbl)
	if not json then return end

	-- Save to file
	if SettingsUtils.canFileIO() then
		pcall(function()
			writefile(SettingsUtils.getSettingsFileName(), json)
		end)
	end

	-- Save to attribute
	pcall(function()
		LocalPlayer:SetAttribute(SETTINGS_ATTR_NAME, json)
	end)
end

function SettingsUtils.scheduleSave(tbl)
	if pendingSave then return end
	pendingSave = true
	task.delay(0.35, function()
		pendingSave = false
		SettingsUtils.saveSettingsNow(tbl)
	end)
end

return SettingsUtils
