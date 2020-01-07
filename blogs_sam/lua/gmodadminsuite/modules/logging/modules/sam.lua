local MODULE = GAS.Logging:MODULE()

MODULE.Category = "SAM"
MODULE.Name     = "Commands"
MODULE.Colour   = Color(255,90,0)

local sam_blacklist = {
    ["noclip"] = true,
    ["menu"] = true
}

MODULE:Setup(function()
    MODULE:Hook("SAM.RanCommand", "command", function(ply, cmd_name, args, cmd)
        if sam_blacklist[cmd_name] then return end

        local cmd_args = cmd.args
        local cmd_args_n = #cmd_args

        local args2 = {}
        for i = 1, cmd_args_n do
            local arg = args[i]

            if arg == nil or arg == "" then
                arg = cmd_args[i].default
            end

            if arg == nil then
                local v = args[i + 1]
                if (v ~= nil and v ~= "") or (cmd_args[i + 1] and cmd_args[i + 1].default ~= nil) then
                    table.insert(args2, "")
                end
            else
                table.insert(args2, tostring(arg))
            end
        end

        MODULE:LogPhrase("command_used", GAS.Logging:FormatPlayer(sam.isconsole(ply) and "Console" or ply), GAS.Logging:Highlight("sam " .. cmd_name .. " \"" .. table.concat(args2, "\" \"") .. "\""))
    end)
end)

GAS.Logging:AddModule(MODULE)