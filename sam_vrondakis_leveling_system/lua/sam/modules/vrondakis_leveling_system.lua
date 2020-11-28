if SAM_LOADED then return end

local sam, command = sam, sam.command

command.set_category("Levels")

command.new("addxp")
	:SetPermission("addxp", "superadmin")

	:AddArg("player", {single_target = true})
	:AddArg("number", {hint = "xp", default = 1, min = 1})

	:Help("Add XP to a player.")

	:OnExecute(function(ply, targets, xp)
		local target = targets[1]
		if target.DarkRPUnInitialized then return end

		target:addXP(xp, true)
		DarkRP.notify(target, 0, 4, ply:Nick() .. " gave you " .. xp .. "XP")

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} gave {T} {V} XP.", {
			A = ply, T = targets, V = xp
		})
	end)
:End()

command.new("setlevel")
	:SetPermission("setlevel", "superadmin")

	:AddArg("player", {single_target = true})
	:AddArg("number", {hint = "level", default = 1, min = 1})

	:Help("Set player's level.")

	:OnExecute(function(ply, targets, level)
		local target = targets[1]
		if target.DarkRPUnInitialized then return end

		DarkRP.storeXPData(target, level, 0)
		target:setDarkRPVar("level", level)
		target:setDarkRPVar("xp", 0)
		DarkRP.notify(target, 0, 4, ply:Nick() .. " set your level to " .. level)

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} set the level for {T} to {V}.", {
			A = ply, T = targets, V = level
		})
	end)
:End()