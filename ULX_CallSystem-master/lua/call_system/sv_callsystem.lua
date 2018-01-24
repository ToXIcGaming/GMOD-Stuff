
AddCSLuaFile("call_system/config/texts.lua")
AddCSLuaFile("call_system/sh_callsystem.lua")
AddCSLuaFile("call_system/config/general_config.lua")
AddCSLuaFile("call_system/cl_callsystem_gui.lua")

include("call_system/sh_callsystem.lua")
include("call_system/config/mysql.lua")

require("mysqloo")

util.AddNetworkString("CallSystem_Message")
util.AddNetworkString("CallSystem_AskAdmin")
util.AddNetworkString("CallSystem_AcceptCall")
util.AddNetworkString("CallSystem_StartDealing")
util.AddNetworkString("CallSystem_CallEnd")
util.AddNetworkString("CallSystem_Explain")

CallSystem.ActiveCalls = CallSystem.ActiveCalls or {}
CallSystem.CallsInQueue = CallSystem.CallsInQueue or {}
CallSystem.BusyAdmins = CallSystem.BusyAdmins or {}

CALLSYSTEM_INQUEUE = 1
CALLSYSTEM_SEARCHING = 2
CALLSYSTEM_DEALING = 3

if not CallSystem.database then
	local info = CallSystem.DatabaseInfo
	CallSystem.database = mysqloo.connect(info.ip, info.username, info.password, info.database)
	CallSystem.database.onConnected = function(self)
		local points_table = self:query([[CREATE TABLE IF NOT EXISTS callsystem_points (
			id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
			steamid BIGINT UNSIGNED NOT NULL,
			is_admin BOOL NOT NULL DEFAULT FALSE,
			points SMALLINT NOT NULL DEFAULT 0,
			name varchar(255) NOT NULL,
			PRIMARY KEY (id));
		]])
		points_table:start()
		local calls_table = self:query([[CREATE TABLE IF NOT EXISTS callsystem_calls (
			id INT UNSIGNED NOT NULL AUTO_INCREMENT,
			callid INT UNSIGNED NOT NULL,
			date INT UNSIGNED NOT NULL,
			calling_ply BIGINT UNSIGNED NOT NULL,
			admin BIGINT UNSIGNED NOT NULL,
			message TINYTEXT NOT NULL,
			accepted BOOL NOT NULL,
			conclusion TINYTEXT,
			refuse_reason TINYTEXT,
			PRIMARY KEY (id));
		]])
		calls_table:start()
		local get_callid = self:query("SELECT MAX(callid) AS callid FROM callsystem_calls;")
		get_callid.onSuccess = function(query)
			local data = query:getData()
			CallSystem.CallID = data[1] and data[1].callid or 0
		end
		get_callid:start()
	end
	CallSystem.database:connect()
end

function CallSystem.PlayerAuthed(ply, steamid, uniqueid)
	local steamid64 = ply:SteamID64()
	local exists = CallSystem.database:query("SELECT points FROM callsystem_points WHERE steamid = "..steamid64.." LIMIT 1;")
	exists.onSuccess = function(self)
		local data = self:getData()
		if data[1] then
			local update = CallSystem.database:query("UPDATE callsystem_points SET name = "..sql.SQLStr(ply:Nick())..", is_admin = "..(ply:IsAdmin() and "1" or "0").." WHERE steamid = "..steamid64..";")
			update:start()
		else
			local insert = CallSystem.database:query("INSERT INTO callsystem_points(`steamid`, `name`, `is_admin`) VALUES("..steamid64..", "..sql.SQLStr(ply:Nick())..", "..(ply:IsAdmin() and "1" or "0")..");")
			wq= "INSERT INTO callsystem_points(`steamid`, `name`, `is_admin`) VALUES("..steamid64..", "..sql.SQLStr(ply:Nick())..", "..(ply:IsAdmin() and "1" or "0")..");"
			insert:start()
		end
	end
	exists:start()
end
hook.Add("PlayerAuthed", "Call_System", CallSystem.PlayerAuthed)

function CallSystem.GetCallByID(id)
	for k,v in pairs(CallSystem.ActiveCalls) do
		if v.id == id then
			return v,k
		end
	end
	return false
end

function CallSystem.ClientMessage(ply, ...)
	net.Start("CallSystem_Message")
	local tbl = {...}
	local count = #tbl
	net.WriteUInt(count, 8)
	for k,v in ipairs(tbl) do
		local is_color = type(v) == "table"
		net.WriteUInt(is_color and 1 or 0, 1)
		if is_color then
			net.WriteColor(v)
		else
			net.WriteString(tostring(v))
		end
	end
	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

function CallSystem.DeleteCall(id, reason)
	local call, index = CallSystem.GetCallByID(id)
	if call then
		local filter = {}
		if IsValid(call.ply) then
			table.insert(filter, call.ply)
		end
		if IsValid(call.admin) then
			table.insert(filter, call.admin)
		end
		CallSystem.ClientMessage(filter, color_white, reason)
		table.remove(CallSystem.ActiveCalls, index)
		if call.admin then
			table.RemoveByValue(CallSystem.BusyAdmins, call.admin)
		end
	end
	if #CallSystem.ActiveCalls == 0 then
		local call = CallSystem.CallsInQueue[1]
		if call then
			call.state = CALLSYSTEM_SEARCHING
			CallSystem.SearchForAdmins(CallSystem.CallID)
		end
	end
end

function CallSystem.ManageCall(id, call, admin)
	call.admin = admin
	table.insert(call.ignored_admins, admin)
	table.insert(CallSystem.BusyAdmins, admin)
	net.Start("CallSystem_AskAdmin")
		net.WriteUInt(call.id, 32)
		net.WriteEntity(call.ply)
		net.WriteString(call.message)
		net.WriteUInt(call.t, 32)
	net.Send(admin)
	timer.Simple(CallSystem.AcceptTimer + 1, function()
		local _call = CallSystem.GetCallByID(id)
		if _call and _call.state == CALLSYSTEM_SEARCHING and _call.admin == admin then
			CallSystem.SearchForAdmins(_call.id)
			local query = CallSystem.database:query(string.format([[INSERT INTO callsystem_calls (`callid`, `date`, `calling_ply`, `admin`, `message`, `accepted`)
				VALUES(%s, %s, %s, %s, %s, FALSE);]],
				_call.id,
				_call.t,
				_call.ply:SteamID64(),
				_call.admin:SteamID64(),
				sql.SQLStr(_call.message)))
			query:start()
			local remove_points = CallSystem.database:query("UPDATE callsystem_points SET points = points - 1 WHERE steamid = ".._call.admin:SteamID64()..";")
			remove_points:start()
		end
	end)
end

net.Receive("CallSystem_Explain", function(_, admin)
	local id = net.ReadUInt(32)
	local reason = net.ReadString()
	local call = CallSystem.GetCallByID(id)
	local query = CallSystem.database:query("UPDATE callsystem_calls SET refuse_reason = "..sql.SQLStr(reason).." WHERE id = "..id)
	query:start()
	table.RemoveByValue(CallSystem.BusyAdmins, admin)
end)

function CallSystem.SearchForAdmins(id)
	local call = CallSystem.GetCallByID(id)
	if not call then return end
	local first_tbl, second_tbl = {}, {}
	for k,v in RandomPairs(player.GetAll()) do
		table.insert(table.HasValue(CallSystem.PriorityTeams, v:Team()) and first_tbl or second_tbl, v)
	end
	local found_admin = false
	local tbl = second_tbl
	table.Add(tbl, first_tbl)
	for k,v in RandomPairs(tbl) do
		if ULib.ucl.query(v, "ulx seeasay") then
			if not found_admin then
				found_admin = true
			end
			if not table.HasValue(CallSystem.BusyAdmins, v) and not table.HasValue(call.ignored_admins, v) then
				CallSystem.ClientMessage(call.ply, CallSystem.GetColor("chat_blue"), v:Nick(), color_white, "admins_notified")
				CallSystem.ManageCall(id, call, v)
				return
			end
		end
	end
	if found_admin then
		call.state = CALLSYSTEM_INQUEUE
		table.insert(CallSystem.CallsInQueue, call)
		if #call.ignored_admins > 0 then
			CallSystem.ClientMessage(call.ply, color_white, "admins_refused")
		else
			CallSystem.ClientMessage(call.ply, color_white, "admins_busy")
		end
	else
		CallSystem.DeleteCall(id, "admins_offline")
	end
end

function CallSystem.Initialize()

	if not ulx then return end
	
	local old_asay = ulx.asay
	
	function ulx.asay(calling_ply, message)
		if ULib.ucl.query(calling_ply, "ulx seeasay") or not CallSystem.CallID then 
			return old_asay(calling_ply, message)
		end
		if calling_ply.LastCall and CallSystem.AntispamTime > CurTime() - calling_ply.LastCall then 
			CallSystem.ClientMessage(calling_ply, color_white, "antispam_part1", tostring(CallSystem.AntispamTime - math.Round(CurTime() - calling_ply.LastCall)), "antispam_part2")
			return 
		end
		calling_ply.LastCall = CurTime()
		CallSystem.CallID = CallSystem.CallID + 1
		local call = {
			id = CallSystem.CallID,
			ply = calling_ply,
			message = message,
			state = CALLSYSTEM_SEARCHING,
			t = os.time(),
			ignored_admins = {},
			close_enough = false
		}
		table.insert(CallSystem.ActiveCalls, call)
		CallSystem.SearchForAdmins(CallSystem.CallID)
	end
	local asay = ulx.command("Chat", "ulx asay", ulx.asay, "@", true, true)
	asay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
	asay:defaultAccess(ULib.ACCESS_ALL)
	asay:help(CallSystem.GetText("command_description"))
	
end
hook.Add("Initialize", "Call_System", CallSystem.Initialize)

function CallSystem.PlayerDisconnected(ply)
	for k,v in pairs(CallSystem.ActiveCalls) do
		if v.admin == ply then
			if v.state == CALLSYSTEM_SEARCHING then
				v.admin = nil
				table.RemoveByValue(CallSystem.BusyAdmins, ply)
				CallSystem.SearchForAdmins(v.id)
			else
				CallSystem.DeleteCall(v.id, "admin_left")
			end
			break
		elseif v.ply == ply then
			CallSystem.DeleteCall(v.id, "player_left")
			break
		end
	end
end
hook.Add("PlayerDisconnected", "Call_System", CallSystem.PlayerDisconnected)

function CallSystem.UpdateToAdmin(call, admin, only_update)
	net.Start("CallSystem_StartDealing")
	if only_update then
		net.WriteUInt(1,1)
	else
		net.WriteUInt(0,1)
		net.WriteTable(call)
	end
	net.Send(admin)
end

net.Receive("CallSystem_AcceptCall", function(_, admin)
	local id = net.ReadUInt(32)
	local call = CallSystem.GetCallByID(id)
	if not IsValid(call.ply) then
		CallSystem.DeleteCall(id, "player_left")
		return
	end
	CallSystem.ClientMessage(call.ply, CallSystem.GetColor("chat_blue"), admin:Nick(), color_white, "admin_accepted")
	call.state = CALLSYSTEM_DEALING
	CallSystem.UpdateToAdmin(call, admin)
end)

net.Receive("CallSystem_CallEnd", function(_, admin)
	local id = net.ReadUInt(32)
	local conclusion = net.ReadString()
	local call = CallSystem.GetCallByID(id)
	local query = string.format([[INSERT INTO callsystem_calls (`callid`, `date`, `calling_ply`, `admin`, `message`, `conclusion`, `accepted`)
		VALUES(%s, %s, %s, %s, %s, %s, TRUE);]],
		call.id,
		call.t,
		call.ply:SteamID64(),
		call.admin:SteamID64(),
		sql.SQLStr(call.message),
		sql.SQLStr(conclusion))
	qy = query
	local insert = CallSystem.database:query(query)
	insert:start()
	if call.close_enough then
		local give_point = CallSystem.database:query("UPDATE callsystem_points SET points = points + 1 WHERE steamid = "..call.admin:SteamID64()..";")
		give_point:start()
	end
	CallSystem.DeleteCall(id, CallSystem.GetText("call_end")..conclusion)
end)

timer.Create("CallSystem_Distance", 0.5, 0, function()
	for k,v in pairs(CallSystem.ActiveCalls) do
		if v.state == CALLSYSTEM_DEALING and not v.close_enough then
			local admin = v.admin
			local ply = v.ply
			if not IsValid(admin) or not IsValid(ply) then continue end
			local distance = ply:GetPos():Distance(admin:GetPos())
			if distance <= CallSystem.Distance then
				v.close_enough = true
				CallSystem.UpdateToAdmin(v, admin)
			end
		end
	end
end)