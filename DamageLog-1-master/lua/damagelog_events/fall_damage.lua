
if SERVER then
	Damagelog:EventHook("EntityTakeDamage")
else
	Damagelog:AddFilter("Show fall damage", DAMAGELOG_FILTER_BOOL, false)
	Damagelog:AddColor("Team Damage", Color(255, 40, 40))
	Damagelog:AddColor("Fall Damage", Color(0, 0, 0))
end

local event = {}

event.Type = "FD"

function event:EntityTakeDamage(ent, dmginfo)
	local att = dmginfo:GetAttacker()
	if ent:IsPlayer() and att == game.GetWorld() and dmginfo:GetDamageType() == DMG_FALL then
		local damages = dmginfo:GetDamage()
		if math.floor(damages) > 0 then
			local tbl = { 
				[1] = ent:Nick(), 
				[2] = ent:GetRole(), 
				[3] = math.Round(damages), 
				[4] = ent:SteamID()
			}
			self.CallEvent(tbl)
		end
	end
end

function event:ToString(tbl)
	return string.format("%s [%s] fell and lost %s HP", tbl[1], team.GetName(tbl[2]), tbl[3]) 
end

function event:IsAllowed(tbl)

	local pfilter = Damagelog.filter_settings["Filter by player"]
	if pfilter then 
		if not tbl[5] and tbl[4] != pfilter then
			return false
		elseif tbl[5] and not (tbl[4] == pfilter or tbl[7] == pfilter) then
			return false
		end
	end
	local dfilter = Damagelog.filter_settings["Show fall damage"]
	if not dfilter then return false end
	return true
	
end

function event:GetColor(tbl)
	if tbl[5] and Damagelog:IsTeamkill(tbl[2], tbl[7]) then
		return Damagelog:GetColor("Team Damage")
	else
		return Damagelog:GetColor("Fall Damage")
	end
end

function event:RightClick(line, tbl, text)
	line:ShowTooLong(true)
	line:ShowCopy(true, { tbl[1], tbl[4] }, tbl[5] and { tbl[6], tbl[8] })
end

Damagelog:AddEvent(event)