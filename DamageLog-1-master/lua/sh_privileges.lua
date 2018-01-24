-- edit the privileges on config/config.lua

local meta = FindMetaTable("Player")

function meta:CanUseDamagelog()
	for k,v in pairs(Damagelog.User_rights) do
		if self:IsUserGroup(k) then
			return true
		end
	end
	return false
end

function meta:GetRole()
	return self:Team()
end

function meta:IsActive()
	return self:Alive()
end

if SERVER then
	-- Needs to be called in Initialize hook, because damagelog addon is loaded before ULib, thus causing errors
	hook.Add("Initialize", "DamagelogsAddULXAccessString", function()
		if ulx then
			ULib.ucl.registerAccess( "ulx seerdmmanager", ULib.ACCESS_ADMIN, "Allows the user to manage RDMs", "Other" )
		end
	end)
end

function meta:CanUseRDMManager()
	if ulx then
		return self:query("ulx seerdmmanager")
	end
	return self:IsAdmin()
end
