sam.command.set_category("Vfire")

sam.command.new("extinguish")
    :SetPermission("extinguish", "admin")

	:DisallowConsole()

	:Help("Extinguish the fire you look at!")

    :OnExecute(function(ply)
        local looked_at = ents.FindInCone(ply:EyePos(), ply:EyeAngles():Forward(), 30000, 0.9)
        local remove_count = 0

        for k, v in ipairs(looked_at) do
            local class = v:GetClass()

            if class == "vfire" or class == "vfire_ball" then
                v:Remove()
                remove_count = remove_count + 1
            end
        end

        sam.player.send_message(nil, "{A} extinguished {V} fire!", {
            A = ply, V = remove_count
        })
    end)
:End()

sam.command.new("extinguishall")
	:SetPermission("extinguishall", "admin")

	:Help("Extinguishes all vfires on the map")

	:OnExecute(function(ply)
		for k, v in ipairs(ents.FindByClass("vfire*")) do
			v:Remove()
		end

		sam.player.send_message(nil, "{A} extinguished all fire!", {
			A = ply
		})
	end)
:End()
