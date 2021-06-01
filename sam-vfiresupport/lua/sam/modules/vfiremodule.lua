sam.command.set_category("MK") -- any new command will be in that category unless the command uses :SetCategory function

sam.command.new("extinguish"):SetPermission("extinguish", "admin"):DisallowConsole():Help("Extinguish the fire you look at!"):MenuHide(false):DisableNotify(true):OnExecute(function(calling_ply)
    local lookedAt = ents.FindInCone(calling_ply:EyePos(), calling_ply:EyeAngles():Forward(), 30000, 0.9)
    local removeCount = 0

    for k, v in pairs(lookedAt) do
        local class = v:GetClass()

        if class == "vfire" or class == "vfire_ball" then
            v:Remove()
            removeCount = removeCount + 1
        end
    end

    sam.player.send_message(calling_ply, "{A} fire extinguished!", {
        A = removeCount
    })
end):End()

sam.command.new("extinguishall"):SetPermission("extinguishall", "admin"):Help("Löscht alle Feuer!"):MenuHide(false):DisableNotify(true):OnExecute(function(calling_ply)
    local removeCount = 0

    for k, v in pairs(ents.FindByClass("vfire" or class == "vfire_ball")) do
        v:Remove()
        removeCount = removeCount + 1
    end

    sam.player.send_message(calling_ply, "All fire ( {A} ) extinguished!", {
        A = removeCount
    })
end):End()
