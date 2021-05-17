--
-- This shows commands ran silently
-- eg. ~hp ^ 100
-- permission is silent_notify. (by default superadmin has it)
--
if SAM_LOADED then return end

local table = table

local sam = sam

sam.permissions.add("silent_notify", nil, "superadmin")

if SERVER then
	local get_players = function()
		local players = {}
		for _, v in ipairs(player.GetHumans()) do
			if v:HasPermission("silent_notify") then
				table.insert(players, v)
			end
		end
		return players
	end
	hook.Add("SAM.RanCommand", "SAM.ShowSlientCommands", function(ply, cmd_name, args, cmd)
		if sam.is_command_silent then			
			if #args > 0 then
				sam.player.send_message(get_players(), "{A} has ran {V} with Args: {#00E640 \"}{V_1}{#00E640 \"}", {
					A = ply, V = cmd_name, V_1 = table.concat(args, "\", \"")
				})
			else
				sam.player.send_message(get_players(), "{A} has ran {V}", {
					A = ply, V = cmd_name
				})
			end
		end
	end)
end