--=--=
-- Permission is "reserved_slots". (By default admin+ has it.)
--=--=

if SAM_LOADED then return end

--
-- Amount of reserved slots
--
local reserved_slots = 5

--
-- Hide reserved slots?
-- Eg. your server has 32 slots, and reserved slots are 2 then the amount of slots the player
-- will see on the menu is 30 slots
--
local hide_reserved_slots = true

--
-- Kick a player with shortest session time if the server is full to free a slot for players with reserved slots access? (Won't kick players with reserved slots access.)
-- I really really really really don't recommend this option for your server.
--
local kick_if_full = true

--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=

-- Messages are appended with a "dot" by default.

--
-- What's the message that players with no access to reserved slots will get?
-- If "hide_reserved_slots" is set to true then the message will be "Server is full"
--
local reserved_message = "Left slots are reserved, sorry"

--
-- Only used when "kick_if_full" is set to "true"
-- What's the message that players will get when they kicked for freeing a slot?
--
local kick_message = "Freeing slot. Sorry, you had the shortest session time"

--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
-- DO NOT TOUCH
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=

local sam = sam

sam.permissions.add("reserved_slots", nil, "admin")

if CLIENT then return end

local max_slots = game.MaxPlayers()
if hide_reserved_slots then
	reserved_message = "Server is full"
	RunConsoleCommand("sv_visiblemaxplayers", max_slots - reserved_slots)
end

local has_reserved_access; do
	local cached_ranks; do
		local fn = hook.GetTable()["SAM.ChangedSteamIDRank"]["RemoveIfCached"]
		cached_ranks = select(2, debug.getupvalue(fn, 1))
	end

	local use_secondary_ranks = sam.player.set_secondary_rank and true or false

	local query
	if use_secondary_ranks then
		query = [[
			SELECT
				`sam_players`.`rank`,
				`sam_players_secondary`.`rank` AS `secondary_rank`
			FROM
				`sam_players`
			LEFT OUTER JOIN
				`sam_players_secondary`
			ON
				`sam_players`.`steamid` = `sam_players_secondary`.`steamid`
			WHERE
				`sam_players`.`steamid` = {1}
		]]
	else
		query = [[
			SELECT
				`rank`
			FROM
				`sam_players`
			WHERE
				`steamid` = {1}
		]]
	end

	local has_permission = sam.ranks.has_permission
	local internal_has_access = function(data, steamid, callback)
		local rank, secondary_rank = "user", "user"
		if data then
			rank, secondary_rank = data.rank, data.secondary_rank
			if rank == "NULL" then
				rank = "user"
			end
			if secondary_rank == "NULL" then
				secondary_rank = "user"
			end
		end

		cached_ranks[steamid] = data ~= nil and data or false

		return callback(has_permission(rank, "reserved_slots") or has_permission(secondary_rank, "reserved_slots"))
	end

	function has_reserved_access(steamid, callback)
		local cache = cached_ranks[steamid]
		if cache then
			return internal_has_access(cache, steamid, callback)
		elseif cache == false then
			return callback(has_permission("user", "reserved_slots"))
		end

		local has_access, msg = false, nil
		sam.SQL.FQuery(query, {steamid}, function(data)
			has_access, msg = internal_has_access(data, steamid, callback)
		end, true)

		return has_access, msg
	end
end

local math = math
local player = player

timer.Simple(0, function()
	local GM = GM or GAMEMODE

	GM.OldCheckPassword = GM.OldCheckPassword or GM.CheckPassword

	function GM:CheckPassword(steamid64, ...)
		if GM:OldCheckPassword(steamid64, ...) == false then
			return false
		end

		local use_kick = false

		local steamid = util.SteamIDFrom64(steamid64)
		local bool, msg = has_reserved_access(steamid, function(has_access)
			local left_slots = max_slots - player.GetCount()
			if left_slots == 0 then return end

			if not has_access and left_slots <= reserved_slots then
				if use_kick then
					sam.player.kick_id(steamid, reserved_message)
				end
				return false, reserved_message .. "."
			end

			if not kick_if_full then return end
			if left_slots - 1 > 0 then return end

			local chosen_player
			local shortest_time = math.huge

			local players = player.GetAll()
			for i = 1, #players do
				local ply = players[i]
				if not ply:HasPermission("reserved_slots") then
					local session_time = ply:sam_get_nwvar("is_authed") and ply:sam_get_session_time() or -1
					if session_time < shortest_time then
						chosen_player = ply
						shortest_time = session_time
					end
				end
			end

			if chosen_player then
				chosen_player:Kick(kick_message)
			end
		end)

		use_kick = true

		return bool, msg
	end
end)