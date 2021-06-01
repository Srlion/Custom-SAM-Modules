sam.command.set_category("Vfire")

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

    sam.player.send_message(calling_ply, "{A} fires extinguished!", {
        A = removeCount
    })
end):End()

sam.command.new("extinguishall"):SetPermission("extinguishall", "admin"):Help("Extinguishes all vfires on the map"):MenuHide(false):DisableNotify(true):OnExecute(function(calling_ply)
    local removeCount = 0

    for k, v in pairs(ents.FindByClass("vfire" or class == "vfire_ball")) do
        v:Remove()
        removeCount = removeCount + 1
    end

    sam.player.send_message(calling_ply, "All {A} fires  extinguished!", {
        A = removeCount
    })
end):End()
