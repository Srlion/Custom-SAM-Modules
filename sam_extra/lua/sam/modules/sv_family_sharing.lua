--
-- This checks if a player joined your server using a lent account that is banned
-- eg. player got banned so he decided to make an alt account and used https://store.steampowered.com/promotion/familysharing
--

--
-- Get yours from https://steamcommunity.com/dev/apikey
--
local SteamAPI_Key = "YOUR_STEAMAPI_KEY"

local BanMessage = "Bypassing a ban using an alt. (alt: %s)"

--
-- Do you want to kick players using family shared accounts?
--
local BlockFamilySharing = false
local BlockFamilySharingMessage = "This server blocked using shared accounts."

--
--
-- DO NOT TOUCH --
--
--

hook.Add("SAM.AuthedPlayer", "CheckSteamFamily", function(ply)
    local ply_steamid = ply:SteamID()
	http.Fetch(string.format("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=%s&format=json&steamid=%s&appid_playing=4000", SteamAPI_Key, ply:SteamID64()), function(body)
        body = util.JSONToTable(body)

        if not body or not body.response or not body.response.lender_steamid then
            sam.print(Color(255, 0, 0), "Invalid Steam API Key to check for steam family sharing check.")
            debug.Trace()
            return
        end

        local lender = body.response.lender_steamid
        if lender == "0" then return end

        if BlockFamilySharing then
            ply:Kick(BlockFamilySharingMessage)
        else
            lender = util.SteamIDFrom64(lender)
            sam.player.is_banned(lender, function(banned)
                if banned then
					RunConsoleCommand("sam", "banid", ply_steamid, "0", BanMessage:format(lender))
                end
            end)
        end
    end)
end)