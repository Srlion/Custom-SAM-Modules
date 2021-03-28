--
-- This is a temp fix for the brainD author who doesn't wanna add
-- support other admin mods
-- https://github.com/MalboroDEV/PermaProps/pull/27/commits/4e83e371b6400c258affccde156248023594293c
--
if SAM_LOADED then return end

local perma_file = "permaprops/sv_menu.lua"
if not file.Exists(perma_file, "LUA") then return end

local load = function()
	include(perma_file)
end

if PermaProps and PermaProps.Permissions then
	load()
end

hook.Add("Initialize", "BrainD_PermaProps", load)
hook.Add("CAMI.OnUsergroupRegistered", "BrainD_PermaProps", load)