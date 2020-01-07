--
-- Make command notifying only for ranks you select.
-- permission is command_notify. (by default admin+ has it)
--
if SAM_LOADED then return end

sam.permissions.add("command_notify", nil, "superadmin")

local get_players = function()
    local players = {}
    for _, v in ipairs(player.GetAll()) do
        if v:HasPermission("command_notify") then
            table.insert(players, v)
        end
    end
    return players
end

local old_send = sam.player.send_message
function sam.player.send_message(ply, msg, tbl)
    if ply == nil and debug.traceback():find("lua/sam/command/", 1, true) then
        old_send(get_players(), msg, tbl)
    else
        old_send(ply, msg, tbl)
    end
end