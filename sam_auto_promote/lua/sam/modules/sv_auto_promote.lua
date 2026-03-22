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
	{ rank = "regular",   time = "12h" },
	{ rank = "trusted",   time = "4d 6h" },
	{ rank = "trusted++", time = "4d 7h" },
}

--
--
-- DO NOT TOUCH ANY THING PAST THIS
-- DO NOT TOUCH ANY THING PAST THIS
-- DO NOT TOUCH ANY THING PAST THIS
--
--

local ranks_count = #promote_ranks
for i = 1, ranks_count do
	promote_ranks[i].time = sam.parse_length(promote_ranks[i].time) * 60
end

local function can_promote(ply_rank)
	if ply_rank == starting_rank then
		return true
	end

	for i = 1, ranks_count - 1 do
		if ply_rank == promote_ranks[i].rank then
			return true
		end
	end

	return false
end

local math = math
local function get_promote_rank(ply)
	local ply_rank = ply:GetUserGroup()
	local play_time = math.floor(ply:sam_get_play_time())

	if not can_promote(ply_rank) then return false end

	local promote_rank = false
	for i = 1, ranks_count do
		local rank = promote_ranks[i].rank
		local time_needed = promote_ranks[i].time
		if play_time >= time_needed or ply_rank == rank then
			promote_rank = rank
		end
	end

	if ply_rank == promote_rank then
		return false
	end

	return promote_rank
end

local player = player
hook.Add("SAM.UpdatedPlayTimes", "AutoPromote", function()
	for _, ply in player.Iterators() do
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
