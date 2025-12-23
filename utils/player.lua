-- utils/player.lua
-- Player utility functions

local PlayerUtils = {}

local Constants = loadstring(game:HttpGet("YOUR_GITHUB_RAW_URL/utils/constants.lua"))()

--------------------------------------------------------------------
-- OWNER/ROLE CHECKS
--------------------------------------------------------------------

function PlayerUtils.isOwner(plr)
	if not plr then return false end
	return (Constants.OwnerNames[plr.Name] == true) or (Constants.OwnerUserIds[plr.UserId] == true)
end

function PlayerUtils.canSeeBroadcastButtons(plr)
	if PlayerUtils.isOwner(plr) then
		return true
	end
	return plr.UserId == 2630250935
end

--------------------------------------------------------------------
-- ROLE RESOLUTION
--------------------------------------------------------------------

function PlayerUtils.getSosRole(plr, sosUsers)
	if not plr then return nil end

	if PlayerUtils.isOwner(plr) then
		return "Owner"
	end

	if Constants.CustomTags[plr.UserId] then
		return "Custom"
	end

	if Constants.OgProfiles[plr.UserId] then
		return "OG"
	end

	if not sosUsers[plr.UserId] then
		return nil
	end

	if Constants.TesterUserIds[plr.UserId] then
		return "Tester"
	end

	if Constants.SinProfiles[plr.UserId] then
		return "Sin"
	end

	return "Normal"
end

function PlayerUtils.getRoleColor(plr, role)
	if role == "Sin" then
		local prof = Constants.SinProfiles[plr.UserId]
		if prof and prof.Color then return prof.Color end
	end
	if role == "OG" then
		local prof = Constants.OgProfiles[plr.UserId]
		if prof and prof.Color then return prof.Color end
	end
	if role == "Custom" then
		local prof = Constants.CustomTags[plr.UserId]
		if prof and prof.Color then return prof.Color end
	end
	return Constants.ROLE_COLOR[role] or Color3.fromRGB(240, 240, 240)
end

function PlayerUtils.getTopLine(plr, role)
	if role == "Owner" then return "SOS Owner" end
	if role == "Tester" then return "SOS Tester" end

	if role == "Sin" then
		local prof = Constants.SinProfiles[plr.UserId]
		if prof and prof.SinName and #prof.SinName > 0 then
			return "The Sin of " .. prof.SinName
		end
		return "The Sin of ???"
	end

	if role == "OG" then
		local prof = Constants.OgProfiles[plr.UserId]
		if prof and prof.OgName and #prof.OgName > 0 then
			return prof.OgName
		end
		return "OG"
	end

	if role == "Custom" then
		local prof = Constants.CustomTags[plr.UserId]
		if prof and prof.TagText and #prof.TagText > 0 then
			return prof.TagText
		end
		return "Custom"
	end

	return "SOS User"
end

--------------------------------------------------------------------
-- TELEPORT UTILITY
--------------------------------------------------------------------

function PlayerUtils.teleportBehind(localPlayer, targetPlayer, studsBack)
	if not targetPlayer or targetPlayer == localPlayer then return end

	local myChar = localPlayer.Character
	local theirChar = targetPlayer.Character
	if not myChar or not theirChar then return end

	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	local theirHRP = theirChar:FindFirstChild("HumanoidRootPart")
	if not myHRP or not theirHRP then return end

	local back = studsBack or 5
	local targetCf = theirHRP.CFrame * CFrame.new(0, 0, back)

	pcall(function()
		if myChar.PivotTo then
			myChar:PivotTo(targetCf)
		else
			myHRP.CFrame = targetCf
		end
	end)
end

return PlayerUtils
