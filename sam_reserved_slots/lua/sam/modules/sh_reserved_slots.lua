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

--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=

-- Messages are appended with a "dot" by default.

--
-- What's the message that players with no access to reserved slots will get?
-- If "hide_reserved_slots" is set to true then the message will be "Server is full"
--
local reserved_message = "Left slots are reserved, sorry"

--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
-- DO NOT TOUCH
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=
--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=

local sam = sam
local SQL = sam.SQL

sam.permissions.add("reserved_slots", nil, "admin")

if CLIENT then return end

local max_slots = game.MaxPlayers()
if hide_reserved_slots then
	reserved_message = "Server is full"
	RunConsoleCommand("sv_visiblemaxplayers", max_slots - reserved_slots)
end

local has_permission = sam.ranks.has_permission
local player = player

-- Rank cache: steamid -> rank string
local rank_cache = {}

local function get_rank_from_data(data)
	if data and data.rank and data.rank ~= "NULL" then
		return data.rank
	end
	return "user"
end

-- Cache invalidation via SAM hooks

local function invalidate_cache()
	rank_cache = {}
end

hook.Add("SAM.ChangedPlayerRank", "SAM.ReservedSlots.Cache", invalidate_cache)
hook.Add("SAM.ChangedSteamIDRank", "SAM.ReservedSlots.Cache", invalidate_cache)
hook.Add("SAM.OnRankRemove", "SAM.ReservedSlots.Cache", invalidate_cache)
hook.Add("SAM.RankNameChanged", "SAM.ReservedSlots.Cache", invalidate_cache)
timer.Create("SAM.ReservedSlots.CacheClear", 300, 0, invalidate_cache) -- Clear cache every 5 minutes just in case

local query = [[
	SELECT
		`rank`
	FROM
		`sam_players`
	WHERE
		`steamid` = {1}
]]

local function has_reserved_access(steamid, callback)
	local cached = rank_cache[steamid]
	if cached then
		callback(has_permission(cached, "reserved_slots"))
		return
	end

	SQL.FQuery(query, { steamid }, function(data)
		local rank = get_rank_from_data(data)
		rank_cache[steamid] = rank
		callback(has_permission(rank, "reserved_slots"))
	end, true)
end

timer.Simple(0, function()
	local GM = GM or GAMEMODE

	sam.hook_last("CheckPassword", "SAM.ReservedSlots", function(steamid64, ...)
		local OldCheckPassword = GM and GM.CheckPassword
		if OldCheckPassword then
			local allowed, msg = OldCheckPassword(GM, steamid64, ...)
			if allowed == false then
				return false, msg
			end
		end

		local steamid = util.SteamIDFrom64(steamid64)
		local left_slots = max_slots - player.GetCount()

		if left_slots <= 0 then
			return false, reserved_message .. "."
		end

		if left_slots <= reserved_slots then
			if SQL.IsMySQL() then
				has_reserved_access(steamid, function(allowed)
					if not allowed then
						sam.player.kick_id(steamid, reserved_message)
					end
				end)
			else
				local has_access = false
				has_reserved_access(steamid, function(allowed)
					has_access = allowed
				end)

				if not has_access then
					return false, reserved_message .. "."
				end
			end
		end

		return true
	end)
end)
