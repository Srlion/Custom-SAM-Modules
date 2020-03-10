if SAM_LOADED then return end

local table = table

local sam, command = sam, sam.command

command.set_category("SimpleWeather")

local cant_use_command = function()
	return table.HasValue(SW.MapBlacklist, game.GetMap():lower())
end

command.new("weather")
	:SetPermission("weather", "superadmin")

	:AddArg("text", {hint = "type", check = function(type)
		return type == "" or type == "none" or SW.Weathers[type]
	end})

	:GetRestArgs()

	:Help("Change the weather.")

	:OnExecute(function(ply, type)
		if cant_use_command() then return end

		if type == "none" then
			SW.SetWeather("")
		else
			SW.SetWeather(type)
		end

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} set weather to {V}.", {
			A = ply, V = type
		})
	end)
:End()

command.new("stopweather")
	:SetPermission("stopweather", "superadmin")

	:Help("Stop the weather.")

	:OnExecute(function(ply)
		if cant_use_command() then return end

		SW.SetWeather("")

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} turned off weather.", {
			A = ply
		})
	end)
:End()

command.new("autoweather")
	:SetPermission("autoweather", "superadmin")

	:Help("Set auto-weather to ON.")

	:OnExecute(function(ply)
		if cant_use_command() then return end

		SW.AutoWeatherEnabled = true

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} set auto-weather to ON.", {
			A = ply
		})
	end)
:End()

command.new("offautoweather")
	:SetPermission("offautoweather", "superadmin")

	:Help("Set auto-weather to OFF.")

	:OnExecute(function(ply)
		if cant_use_command() then return end

		SW.AutoWeatherEnabled = false

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} set auto-weather to OFF.", {
			A = ply
		})
	end)
:End()

command.new("settime")
	:SetPermission("settime", "superadmin")

	:AddArg("number", {hint = "time", optional = true, min = 0, max = 24, default = 0})

	:Help("Change the time.")

	:OnExecute(function(ply, time)
		if cant_use_command() then return end

		SW.SetTime(time)

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} set time to {V}.", {
			A = ply, V = time
		})
	end)
:End()

command.new("enabletime")
	:SetPermission("enabletime", "superadmin")

	:Help("Enable the passage of time.")

	:OnExecute(function(ply)
		if cant_use_command() then return end

		SW.PauseTime(false)

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} enabled the passage of time.", {
			A = ply
		})
	end)
:End()

command.new("disabletime")
	:SetPermission("disabletime", "superadmin")

	:Help("Enable the passage of time.")

	:OnExecute(function(ply)
		if cant_use_command() then return end

		SW.PauseTime(true)

		if sam.is_command_silent then return end
		sam.player.send_message(nil, "{A} disabled the passage of time.", {
			A = ply
		})
	end)
:End()