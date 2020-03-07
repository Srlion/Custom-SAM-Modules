--
-- Language stuff
--

local setrank = "{A} set the secondary rank for {T} to {V} for {V_2}."
local setrank_help = "Set a player's secondary rank."
local setrankid_help = "Set a player's secondary rank by his steamid/steamid64."


--
--
-- DO NOT TOUCH ANY THING PAST THIS
-- DO NOT TOUCH ANY THING PAST THIS
-- DO NOT TOUCH ANY THING PAST THIS
--
--


if SAM_LOADED then return end

local sam, command = sam, sam.command
local SQL = sam.SQL

--
local PLAYER = FindMetaTable("Player")

function PLAYER:GetSecondaryUserGroup()
	return self:GetNWString("SecondaryUserGroup", "user")
end

local inherits_from = sam.ranks.inherits_from
function PLAYER:CheckGroup(name)
	return inherits_from(self:GetUserGroup(), name) or inherits_from(self:GetSecondaryUserGroup(), name)
end

function PLAYER:IsUserGroup(name)
	if not self:IsValid() then return false end
	return self:GetNWString("UserGroup") == name or self:GetNWString("SecondaryUserGroup") == name
end

local has_permission = sam.ranks.has_permission
function PLAYER:HasPermission(perm)
	return has_permission(self:GetUserGroup(), perm) or has_permission(self:GetSecondaryUserGroup(), perm)
end

local can_target = sam.ranks.can_target
function PLAYER:CanTarget(ply)
	local rank, secondary_rank = self:GetUserGroup(), self:GetSecondaryUserGroup()
	local target_rank, target_secondary_rank = ply:GetUserGroup(), ply:GetSecondaryUserGroup()
	return
		(can_target(rank, target_rank) or can_target(secondary_rank, target_rank)) and
		(can_target(rank, target_secondary_rank) or can_target(secondary_rank, target_secondary_rank))
end

function PLAYER:CanTargetRank(rank)
	return can_target(self:GetUserGroup(), rank) or can_target(self:GetSecondaryUserGroup(), rank)
end

do
	local has_ban_permission = function(rank)
		return has_permission(rank, "ban") or has_permission(rank, "banid")
	end

	local get_ban_limit = sam.ranks.get_ban_limit
	function PLAYER:GetBanLimit(ply)
		local rank = self:GetUserGroup()
		local limit = get_ban_limit(rank)
		if limit == 0 and has_ban_permission(rank) then
			return 0
		end

		local secondary_rank = self:GetSecondaryUserGroup()
		local secondary_limit = get_ban_limit(secondary_rank)
		if secondary_limit == 0 and has_ban_permission(secondary_rank) then
			return 0
		end

		return math.max(limit, secondary_limit)
	end
end

function sam.console.GetSecondaryUserGroup()
	return "superadmin"
end

if SERVER then
	function PLAYER:SetSecondaryUserGroup(name)
		self:SetNWString("SecondaryUserGroup", name)
	end

	function sam.console.SetSecondaryUserGroup()
	end
end

hook.Add("SAM.LoadedRestrictions", "SecondaryRank", function()
	local get_limit = sam.ranks.get_limit
	function PLAYER:GetLimit(limit_type)
		local main_limit = get_limit(self:GetUserGroup(), limit_type)
		if main_limit == -1 then
			return -1
		end

		local secondary_limit = get_limit(self:GetSecondaryUserGroup(), limit_type)
		if secondary_limit == -1 then
			return -1
		end

		return math.max(main_limit, secondary_limit)
	end
end)
--

--
command.set_category("User Management")

command.new("setsecondaryrank")
	:Aliases("changesecondaryrank")

	:SetPermission("setsecondaryrank")

	:AddArg("player", {single_target = true})
	:AddArg("rank", {check = function(rank, ply)
		return ply:CanTargetRank(rank)
	end})
	:AddArg("length", {optional = true, default = 0})

	:Help(setrank_help)

	:OnExecute(function(ply, targets, rank, length)
		targets[1]:sam_set_secondary_rank(rank, length)

		if sam.is_command_silent then return end
		sam.player.send_message(nil, setrank, {
			A = ply, T = targets, V = rank, V_2 = sam.format_length(length)
		})
	end)
:End()

command.new("setsecondaryrankid")
	:Aliases("changesecondaryrankid")

	:SetPermission("setsecondaryrankid")

	:AddArg("steamid")
	:AddArg("rank", {check = function(rank, ply)
		return ply:CanTargetRank(rank)
	end})
	:AddArg("length", {optional = true, default = 0})

	:Help(setrankid_help)

	:OnExecute(function(ply, promise, rank, length)
		local a_name = ply:Name()
		local silent = sam.is_command_silent

		promise:done(function(data)
			local steamid, target = data[1], data[2]
			if target then
				target:sam_set_secondary_rank(rank, length)

				if silent then return end
				sam.player.send_message(nil, setrank, {
					A = ply, T = {target, admin = ply}, V = rank, V_2 = sam.format_length(length)
				})
			else
				sam.player.set_secondary_rank_id(steamid, rank, length)

				if silent then return end
				sam.player.send_message(nil, setrank, {
					A = a_name, T = steamid, V = rank, V_2 = sam.format_length(length)
				})
			end
		end)
	end)
:End()
--

if CLIENT then return end

do
	local cached_ranks = {}
	local targeting_offline = {}

	local check_steamid = function(steamid)
		if not sam.is_steamid(steamid) then
			if sam.is_steamid64(steamid) then
				return util.SteamIDFrom64(steamid)
			else
				return nil
			end
		end

		return steamid
	end

	local can_target_steamid_callback = function(data, promise)
		local ply, steamid = promise.ply, promise.steamid
		local rank, secondary_rank = promise.rank, promise.secondary_rank
		local target_rank, target_secondary_rank
		if data then
			target_rank, target_secondary_rank = data.rank, data.secondary_rank
			if target_rank == "NULL" then
				target_rank = "user"
			end
			if target_secondary_rank == "NULL" then
				target_secondary_rank = "user"
			end
		end

		if not data or
			((can_target(rank, target_rank) or can_target(secondary_rank, target_rank)) and
			(can_target(rank, target_secondary_rank) or can_target(secondary_rank, target_secondary_rank))) then
			promise:resolve({steamid})
		elseif IsValid(ply) then
			ply:sam_send_message("cant_target_player", {
				S = steamid
			})
		end

		targeting_offline[ply] = nil
		cached_ranks[steamid] = data ~= nil and data or false
	end

	local arguments = command.get_arguments()
	arguments["steamid"] = function(argument, input, ply, _, result)
		local steamid = check_steamid(input)
		if not steamid then
			ply:sam_send_message("invalid", {
				S = "steamid/steamid64", S_2 = input
			})
			return false
		end

		if argument.allow_higher_target then
			table.insert(result, steamid)
			return
		end

		local promise = sam.Promise.new()
		promise.ply = ply
		promise.rank = ply:GetUserGroup()
		promise.secondary_rank = ply:GetSecondaryUserGroup()
		promise.steamid = steamid

		local target = player.GetBySteamID(steamid)
		if sam.isconsole(ply) then
			promise:resolve({steamid})
		elseif target then
			if ply:CanTarget(target) then
				promise:resolve({steamid, target})
			else
				ply:sam_send_message("cant_target_player", {
					S = steamid
				})
			end
		elseif cached_ranks[steamid] ~= nil then
			can_target_steamid_callback(cached_ranks[steamid], promise)
		else
			targeting_offline[ply] = true

			sam.SQL.FQuery([[
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
			]], {steamid}, can_target_steamid_callback, true, promise)
		end

		table.insert(result, promise)
	end

	timer.Create("SAM.ClearCachedRanks", 60 * 2.5, 0, function()
		table.Empty(cached_ranks)
	end)

	for k, v in ipairs({"SAM.ChangedSteamIDRank", "SAM.ChangedSteamIDSecondaryRank"}) do
		hook.Add(v, "RemoveIfCached", function(steamid)
			cached_ranks[steamid] = nil
		end)
	end

	hook.Add("SAM.CanRunCommand", "StopIfTargetingOffline", function(ply)
		if targeting_offline[ply] then
			return false
		end
	end)
end

--
function sam.player.set_secondary_rank(ply, rank, length)
	if sam.type(ply) ~= "Player" or not ply:IsValid() then
		error("invalid player")
	elseif not sam.ranks.is_rank(rank) then
		error("invalid rank")
	end

	if not sam.isnumber(length) or length < 0 then
		length = 0
	end

	local expiry_date = 0
	if length ~= 0 then
		if rank == "user" then
			expiry_date = 0
		else
			expiry_date = (math.min(length, 31536000) * 60) + os.time()
		end
	end

	ply:sam_start_secondary_rank_timer(expiry_date)

	SQL.FQuery([[
		UPDATE
			`sam_players_secondary`
		SET
			`rank` = {1},
			`expiry_date` = {2}
		WHERE
			`steamid` = {3}
	]], {rank, expiry_date, ply:SteamID()})

	local old_rank = ply:GetSecondaryUserGroup()
	ply:SetSecondaryUserGroup(rank)
	sam.hook_call("SAM.ChangedPlayerSecondaryRank", ply, rank, old_rank, expiry_date)
end

do
	local set_rank_id = function(player_data, arguments)
		local old_rank = player_data and player_data.rank or false
		local promise, steamid, rank, length = unpack(arguments, 1, 4)

		local expiry_date = 0
		if length ~= 0 then
			if rank == "user" then
				expiry_date = 0
			else
				expiry_date = (math.min(length, 31536000) * 60) + os.time()
			end
		end

		local exists = true
		if old_rank == false then
			exists, old_rank = false, "user"

			local time = os.time()
			SQL.FQuery([[
				INSERT INTO
					`sam_players_secondary`(
						`steamid`,
						`rank`
					)
				VALUES
					({1}, {2})
			]], {steamid, rank, 0, time, time, 0})
		else
			SQL.FQuery([[
				UPDATE
					`sam_players_secondary`
				SET
					`rank` = {1},
					`expiry_date` = {2}
				WHERE
					`steamid` = {3}
			]], {rank, expiry_date, steamid})
		end

		promise:resolve()
		sam.hook_call("SAM.ChangedSteamIDSecondaryRank", steamid, rank, old_rank, expiry_date, exists)
	end

	function sam.player.set_secondary_rank_id(steamid, rank, length)
		sam.is_steamid(steamid, true)

		if not sam.ranks.is_rank(rank) then
			error("invalid rank")
		end

		local promise = Promise.new()

		do
			local ply = player.GetBySteamID(steamid)
			if ply then
				promise:resolve(ply:sam_set_secondary_rank(rank, length))
				return promise
			end
		end

		if not sam.isnumber(length) or length < 0  then
			length = 0
		end

		SQL.FQuery([[
			SELECT
				`rank`
			FROM
				`sam_players_secondary`
			WHERE
				`steamid` = {1}
		]], {steamid}, set_rank_id, true, {promise, steamid, rank, length})

		return promise
	end
end

hook.Add("SAM.OnRankRemove", "ResetPlayerSecondaryRank", function(name)
	for _, ply in ipairs(player.GetAll()) do
		if ply:GetSecondaryUserGroup() == name then
			ply:sam_set_secondary_rank("user")
		end
	end

	SQL.FQuery([[
		UPDATE
			`sam_players_secondary`
		SET
			`rank` = 'user',
			`expiry_date` = 0
		WHERE
			`rank` = {1}
	]], {name})
end)

hook.Add("SAM.RankNameChanged", "ChangePlayerSecondaryRankName", function(old, new)
	for _, ply in ipairs(player.GetAll()) do
		if ply:GetSecondaryUserGroup() == old then
			ply:sam_set_secondary_rank(new)
		end
	end

	SQL.FQuery([[
		UPDATE
			`sam_players_secondary`
		SET
			`rank` = {1}
		WHERE
			`rank` = {2}
	]], {new, old})
end)
--

--
hook.Add("SAM.DatabaseLoaded", "SecondaryRankTable", function()
	SQL.Query([[
		CREATE TABLE IF NOT EXISTS `sam_players_secondary`(
			`steamid` VARCHAR(32),
			`rank` VARCHAR(30),
			`expiry_date` INT UNSIGNED DEFAULT 0
		)
	]])
end)

do
	local auth_player = function(data, ply)
		if not ply:IsValid() then return end

		local rank, expiry_date
		if data and data.secondary_rank ~= "" then
			rank, expiry_date = data.secondary_rank, tonumber(data.secondary_expiry_date)
		else
			rank, expiry_date = "user", 0

			SQL.FQuery([[
				INSERT INTO
					`sam_players_secondary`(
						`steamid`,
						`rank`
					)
				VALUES
					({1}, {2})
			]], {ply:SteamID(), rank})
		end

		if data then
			data.secondary_rank, data.secondary_expiry_date = nil, nil
		end

		if data and data.rank == "" then
			data = nil
		end

		ply:SetSecondaryUserGroup(rank)
		ply:sam_start_secondary_rank_timer(expiry_date)
		sam.player.auth(data, ply)
	end

	hook.Add("PlayerInitialSpawn", "SAM.AuthPlayer", function(ply)
		SQL.FQuery([[
			SELECT
				IFNULL(`sam_players`.`rank`, '') AS `rank`,
				IFNULL(`sam_players`.`expiry_date`, '') AS `expiry_date`,
				IFNULL(`sam_players`.`play_time`, '') AS `play_time`,
				IFNULL(`sam_players_secondary`.`rank`, '') AS `secondary_rank`,
				IFNULL(`sam_players_secondary`.`expiry_date`, '') AS `secondary_expiry_date`
			FROM
				`sam_players`
			LEFT OUTER JOIN
				`sam_players_secondary`
			ON
				`sam_players`.`steamid` = `sam_players_secondary`.`steamid`
			WHERE
				`sam_players`.`steamid` = {1}
		]], {ply:SteamID()}, auth_player, true, ply)
	end)
end
--

do
	local remove_rank_timer = function(ply)
		timer.Remove("SAM.SecondaryRankTimer." .. ply:SteamID())
	end

	function sam.player.start_secondary_rank_timer(ply, expiry_date)
		ply.sam_secondary_rank_expirydate = expiry_date
		if expiry_date == 0 then -- permanent rank
			return remove_rank_timer(ply)
		end
		expiry_date = expiry_date - os.time()
		timer.Create("SAM.SecondaryRankTimer." .. ply:SteamID(), expiry_date, 1, function()
			ply:sam_set_secondary_rank("user")
		end)
	end

	hook.Add("PlayerDisconnected", "SAM.RemoveSecondaryRankTimer", remove_rank_timer)
end