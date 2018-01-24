if SERVER then
	Damagelog:EventHook("DoPlayerDeath")
else
	Damagelog:AddFilter("Show kills", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Teamkills", Color(255, 40, 40))
	Damagelog:AddColor("Kills", Color(255, 128, 0, 255))
end

local event = {}

event.Type = "KILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
	if IsValid(attacker) and attacker:IsPlayer() and attacker != ply then
		local tbl = { 
			[1] = attacker:Nick(), 
			[2] = attacker:GetRole(), 
			[3] = ply:Nick(), 
			[4] = ply:GetRole(), 
			[5] = Damagelog:WeaponFromDmg(dmginfo),
			[6] = ply:SteamID(),
			[7] = attacker:SteamID()
		} 
		self.CallEvent(tbl)
		net.Start("DL_Ded")
			net.WriteUInt(1,1)
			net.WriteString(tbl[1])
		net.Send(ply)
		ply:SetNWEntity("DL_Killer", attacker)
		ply.rdmInfo = {
			time = Damagelog.Time,
			round = Damagelog.CurrentRound,
		}
		ply.rdmSend = true
	end
end

function event:ToString(v)

	local weapon = v[5]
	text = string.format("%s [%s] has killed %s [%s] with an unknown weapon", v[1], team.GetName(v[2]), v[3], team.GetName(v[4])) 
	if weapon then
		text = string.format("%s [%s] has killed %s [%s] with %s", v[1], team.GetName(v[2]), v[3], team.GetName(v[4]), weapon)
	end
	return text
	
end

function event:IsAllowed(tbl)

	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then
		if not (tbl[6] == pfilter or tbl[7] == pfilter) then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show kills"]
	if not dfilter then return false end
	return true
	
end

function event:GetColor(tbl)
	
	if Damagelog:IsTeamkill(tbl[2], tbl[4]) then
		return Damagelog:GetColor("Teamkills")
	else
		return Damagelog:GetColor("Kills")
	end
	
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[7] }, { tbl[3], tbl[6] })
	line:ShowDamageInfos(tbl[3], tbl[1])
end

Damagelog:AddEvent(event)
