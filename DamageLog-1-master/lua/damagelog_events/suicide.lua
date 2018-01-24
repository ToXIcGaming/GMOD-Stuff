if SERVER then
	Damagelog:EventHook("DoPlayerDeath")
else
	Damagelog:AddFilter("Show suicides", DAMAGELOG_FILTER_BOOL, true)
	Damagelog:AddColor("Suicides", Color(25, 25, 220, 255))
end

local event = {}

event.Type = "KILL"

function event:DoPlayerDeath(ply, attacker, dmginfo)
	if (IsValid(attacker) and (attacker:IsPlayer() and attacker == ply) or not attacker:IsPlayer()) or not IsValid(attacker) then
		local tbl = { 
			[1] = ply:Nick(), 
			[2] = ply:GetRole(), 
			[3] = ply:SteamID()
		} 
		self.CallEvent(tbl)
	end
end

function event:ToString(v)
	return string.format("<something/world> has killed %s [%s]", v[1], team.GetName(v[2]), v[3])
end

function event:IsAllowed(tbl)
	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then
		if tbl[3] != pfilter then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show suicides"]
	if not dfilter then return false end
	return true
end

function event:GetColor(tbl)
	return Damagelog:GetColor("Suicides")
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[3] })
end

Damagelog:AddEvent(event)
