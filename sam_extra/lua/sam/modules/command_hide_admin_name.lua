--
-- This hides admins names when running commands
-- eg. *Someone slapped everyone.
-- You can NOT use this with 'command_notify_for_ranks.lua'
--
if SAM_LOADED then return end

sam.permissions.add("see_hidden_admin_name", nil, "admin")

if SERVER then
	sam.player.old_send_message = sam.player.old_send_message or sam.player.send_message
	function sam.player.send_message(ply, msg, tbl)
		if ply or not debug.traceback():find("lua/sam/command/", 1, true) or not tbl or not msg then
			return sam.player.old_send_message(ply, msg, tbl)
		end

		msg = sam.language.get(msg) or msg

		local admins, players = {}, {}
		for _, v in ipairs(player.GetAll()) do
			table.insert(v:HasPermission("see_hidden_admin_name") and admins or players, v)
		end

		sam.player.old_send_message(admins, msg, tbl)

		msg = msg:gsub("%{A%}", function()
			local admin = tbl["A"]
			if admin == sam.console then
				return "{A}"
			end
			tbl["A"] = "Someone"
			return "*{A}"
		end, 1)

		sam.player.old_send_message(players, msg, tbl)
	end
end