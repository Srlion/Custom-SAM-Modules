--
-- Make command notifying only for ranks you select.
-- permission is command_notify. (by default admin+ has it)
-- You can NOT use this with 'command_hide_admin_name.lua'
--
if SAM_LOADED then return end

sam.permissions.add("command_notify", nil, "admin")

if SERVER then
	local get_players = function()
		local players = {}
		for _, v in ipairs(player.GetAll()) do
			if v:HasPermission("command_notify") then
				table.insert(players, v)
			end
		end
		return players
	end

	sam.player.old_send_message = sam.player.old_send_message or sam.player.send_message
	function sam.player.send_message(ply, msg, tbl)
		if ply == nil and debug.traceback():find("lua/sam/command/", 1, true) then
			sam.player.old_send_message(get_players(), msg, tbl)
		else
			sam.player.old_send_message(ply, msg, tbl)
		end
	end
end