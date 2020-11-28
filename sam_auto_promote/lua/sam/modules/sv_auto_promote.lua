if SAM_LOADED then return end

--
-- All credits to https://github.com/RoniJames/GPromote/blob/master/lua/autorun/server/autopromote.lua
--

--
-- Rank to start promoting from
--
local starting_rank = "user"

--
-- {A} will be replaced with the player who got promoted
-- {V} will be replaced with the player's new rank
-- {V_2} will be replaced with the player's old rank
--
local promote_message = "{A} got promoted to {V} from {V_2}."

--
-- Ranks to promote to
-- Add ranks by order, eg.
	-- trusted
	-- trusted+
	-- trusted++
	-- trusted++++++++
-- times:
	-- 1y -> 1 year
	-- 1mo -> 1 month
	-- 1w -> 1 week
	-- 1d -> 1 day
	-- 1h -> 1 hour
	-- 1m -> 1 minute
--
local promote_ranks = {
	"regular"; "12h",
	"trusted"; "4d 6h",
	"trusted++"; "4d 7h",
}

--
--
-- DO NOT TOUCH ANY THING PAST THIS
-- DO NOT TOUCH ANY THING PAST THIS
-- DO NOT TOUCH ANY THING PAST THIS
--
--

local ranks_count = #promote_ranks

for i = 2, ranks_count, 2 do
	promote_ranks[i] = sam.parse_length(promote_ranks[i]) * 60
end

local can_promote = function(ply_rank)
	if ply_rank == starting_rank then
		return true
	end

	for i = 1, ranks_count - 2, 2 do
		if ply_rank == promote_ranks[i] then
			return true
		end
	end

	return false
end

local math = math
local get_promote_rank = function(ply)
	local ply_rank = ply:GetUserGroup()
	local play_time = math.floor(ply:sam_get_play_time())

	if not can_promote(ply_rank) then return false end

	local promote_rank = false

	for i = 1, ranks_count, 2 do
		local rank = promote_ranks[i]
		local time_needed = promote_ranks[i + 1]
		if play_time >= time_needed or ply_rank == rank --[[make sure that he doesn't lose his rank if he doesn't have enough time but got manually assigned]] then
			promote_rank = rank
		end
	end

	-- he is already promoted to this rank
	if ply_rank == promote_rank then
		return false
	end

	return promote_rank
end

local player = player
hook.Add("SAM.UpdatedPlayTimes", "AutoPromote", function()
	local players = player.GetHumans()
	for i = 1, #players do
		local ply = players[i]
		local promote_rank = get_promote_rank(ply)
		if not promote_rank then continue end

		if sam.ranks.is_rank(promote_rank) then
			local old_rank = ply:GetUserGroup()
			ply:sam_set_rank(promote_rank)
			sam.player.send_message(nil, promote_message, {
				A = ply, V = promote_rank, V_2 = old_rank
			})
		else
			sam.player.send_message(nil, "Could not promote {A} to {V} because rank does not exist.", {
				A = ply, V = promote_rank
			})
		end
	end
end)
