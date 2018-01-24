AddCSLuaFile("sh_util.lua")
AddCSLuaFile("cl_damagelog.lua")
AddCSLuaFile("cl_tabs/damagetab.lua")
AddCSLuaFile("cl_tabs/settings.lua")
AddCSLuaFile("cl_tabs/shoots.lua")
AddCSLuaFile("cl_tabs/old_logs.lua")
AddCSLuaFile("cl_tabs/rdm_manager.lua")
AddCSLuaFile("cl_tabs/about.lua")
AddCSLuaFile("sh_privileges.lua")
AddCSLuaFile("sh_sync_entity.lua")
AddCSLuaFile("sh_events.lua")
AddCSLuaFile("cl_listview.lua")
AddCSLuaFile("cl_colors.lua")
AddCSLuaFile("cl_filters.lua")
AddCSLuaFile("not_my_code/orderedPairs.lua")
AddCSLuaFile("not_my_code/von.lua")
AddCSLuaFile("rdm_manager/cl_rdm_manager.lua")
AddCSLuaFile("config/config.lua")

include("sh_util.lua")
include("config/config.lua")
include("sh_sync_entity.lua")
include("sh_privileges.lua")
include("sh_events.lua")
include("not_my_code/orderedPairs.lua")
include("not_my_code/von.lua")
include("sv_damageinfos.lua")
include("sv_oldlogs.lua")
include("rdm_manager/sv_rdm_manager.lua")

resource.AddFile("sound/ui/vote_failure.wav")
resource.AddFile("sound/ui/vote_yes.wav")

util.AddNetworkString("DL_AskDamagelog")
util.AddNetworkString("DL_SendDamagelog")
util.AddNetworkString("DL_RefreshDamagelog")
util.AddNetworkString("DL_Ded")

Damagelog.DamageTable = Damagelog.DamageTable or {}
Damagelog.old_tables = Damagelog.old_tables or {}
Damagelog.ShootTables = Damagelog.ShootTables or {}
Damagelog.Roles = Damagelog.Roles or {}

Damagelog.CurrentRound = 0
Damagelog.SelectedRound = Damagelog.CurrentRound
Damagelog.Time = 0

function Damagelog:CheckDamageTable()
	if Damagelog.DamageTable[1] == "empty" then
		table.Empty(Damagelog.DamageTable)
	end
end

function Damagelog:OnGamemodeLoaded()
	
	if not timer.Exists("Damagelog_Timer") then
		timer.Create("Damagelog_Timer", 1, 0, function()
			Damagelog.Time = Damagelog.Time + 1
		end)
	end
	
	-- Prevent giant string tables...maybe?
	local cacheDelay = 25 * 60
	if not timer.Exists("Damagelog_CacheCheck") then
		timer.Create("Damagelog_CacheCheck", cacheDelay, 0, function()
			
			for k, v in pairs(Damagelog.ShootTables) do
				if (Damagelog.Time - k) >= cacheDelay then
					Damagelog.ShootTables[k] = nil
				end
			end
			
			for k, v in pairs(Damagelog.DamageTable) do
				if (Damagelog.Time - v.time) >= cacheDelay then
					Damagelog.DamageTable[k] = nil
				end
			end
			
			-- Reset the time, so it does exceed the listview width
			if Damagelog.Time >= (75 * 60)  then
				Damagelog.Time = 0
			end
			
		end)
	end
	
	Damagelog.ShootTables = Damagelog.ShootTables or {}
	Damagelog.ShootTables[Damagelog.CurrentRound] = {}
	
end
hook.Add("OnGamemodeLoaded", "OnGamemodeLoaded_Damagelog", function()
	Damagelog:OnGamemodeLoaded()
end)

-- rip from TTT
-- this one will return a string
function Damagelog:WeaponFromDmg(dmg)
	local inf = dmg:GetInflictor()
	local wep = nil
	if IsValid(inf) then
		if inf:IsWeapon() or inf.Projectile then
			wep = inf
		elseif dmg:IsDamageType(DMG_BLAST) then
			wep = "an explosion"
		elseif dmg:IsDamageType(DMG_DIRECT) or dmg:IsDamageType(DMG_BURN) then
			wep = "fire"
		elseif dmg:IsDamageType(DMG_CRUSH) then
			wep = "falling or prop damage"
		elseif inf:IsPlayer() then
			wep = inf:GetActiveWeapon()
		end
	end
	if type(wep) != "string" then
		return IsValid(wep) and wep:GetClass()
	else
		return wep
	end
end

function Damagelog:SendDamagelog(ply)
	if not ply:CanUseDamagelog() then return end
	local damage_send = self.DamageTable
	if not damage_send then 
		damage_send = { "empty" } 
	end
	local count = #damage_send
	for k,v in ipairs(damage_send) do
		net.Start("DL_SendDamagelog")
		if v == "empty" then
			net.WriteUInt(1, 1)
		elseif v == "ignore" then
			if count == 1 then
				net.WriteUInt(1, 1)
			else
				net.WriteUInt(0,1)
				net.WriteTable({"ignore"})
			end
		else
			net.WriteUInt(0, 1)
			net.WriteTable(v)
		end
		net.WriteUInt(k == count and 1 or 0, 1)
		net.Send(ply)
	end
end
net.Receive("DL_AskDamagelog", function(_, ply)
	Damagelog:SendDamagelog(ply)
end)

hook.Add("PlayerDeath", "Damagelog_PlayerDeathLastLogs", function(ply)
	local found_dmg = {}
	for k,v in ipairs(Damagelog.DamageTable) do
		if type(v) == "table" and v.time >= Damagelog.Time - 10 and v.time <= Damagelog.Time then
			table.insert(found_dmg, v)
		end
	end
	if not ply.DeathDmgLog then
		ply.DeathDmgLog = {}
	end
	ply.DeathDmgLog[Damagelog.CurrentRound] = found_dmg
end)
	
