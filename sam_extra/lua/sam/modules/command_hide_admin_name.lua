--
-- This hides admins names when running commands
-- eg. *Someone slapped everyone.
-- permission is see_hidden_admin_name. (by default admin+ has it)
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

		local admin = tbl["A"]
		if not admin or admin == sam.console then
			return sam.player.old_send_message(ply, msg, tbl)
		end

		msg = sam.language.get(msg) or msg

		local admins, players = {}, {}
		for _, v in ipairs(player.GetAll()) do
			table.insert((v:HasPermission("see_hidden_admin_name") or v == admin) and admins or players, v)
		end

		sam.player.old_send_message(admins, msg, tbl)

		tbl["A"] = "Someone"

		sam.player.old_send_message(players, msg:gsub("%{A%}", "*{A}", 1), tbl)
	end
end
