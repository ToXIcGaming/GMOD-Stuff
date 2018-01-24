
include("call_system/sh_callsystem.lua")
include("call_system/cl_callsystem_gui.lua")

CallSystem.CurrentNotif = nil

function CallSystem.ClientMessage()
	local result = {}
	local count = net.ReadUInt(8)
	for i=1, count do
		local is_color = net.ReadUInt(1) == 1
		local str = nil
		if not is_color then
			str = net.ReadString()
		end
		local text,found = CallSystem.GetText(str)
		table.insert(result, is_color and net.ReadColor() or (found and text or str))
	end
	chat.AddText(CallSystem.GetColor("chat_tag"), CallSystem.GetText("chat_tag").." ", unpack(result))
end
net.Receive("CallSystem_Message", CallSystem.ClientMessage)

function CallSystem.AdminNotification()
	local id = net.ReadUInt(32)
	CallSystem.CurrentNotif = {
		id = id,
		ply = net.ReadEntity(),
		message = net.ReadString(),
		t = net.ReadUInt(32),
		ask_admin = true,
		remainingtime = CallSystem.AcceptTimer,
		Stop = function()
			timer.Destroy("TimerNotif")
			CallSystem.Avatar:SetVisible(false)
			CallSystem.CurrentNotif.animended = false
			CallSystem.CurrentNotif.animpos = nil
			CallSystem.CurrentNotif.End = true
		end
	}
	if timer.Exists("TimerNotif") then
		timer.Destroy("TimerNotif")
	end
	timer.Create("TimerNotif", 1, CallSystem.AcceptTimer + 1, function()
		CallSystem.CurrentNotif.remainingtime = CallSystem.CurrentNotif.remainingtime - 1
		if CallSystem.CurrentNotif.remainingtime <= -1 then
			CallSystem.CurrentNotif.Stop()
			Derma_StringRequest(CallSystem.GetText("refused_why_title"), CallSystem.GetText("refused_why_message"), nil, function(str)
				net.Start("CallSystem_Explain")
				net.WriteUInt(id, 32)
				net.WriteString(str)
				net.SendToServer()
			end)
		end
	end)
end
net.Receive("CallSystem_AskAdmin", CallSystem.AdminNotification)

function CallSystem.StartDealing()
	local only_update = net.ReadUInt(1) == 1
	if only_update then
		if CallSystem.DealingWith then
			CallSystem.DealingWith.close_enough = true
		end
	else
		local tbl = net.ReadTable()
		tbl.Stop = function()
			CallSystem.Avatar:SetVisible(false)
			tbl.animended = false
			tbl.animpos = nil
			tbl.End = true
		end
		CallSystem.DealingWith = tbl
		CallSystem.Avatar:SetVisible(true)
	end
end
net.Receive("CallSystem_StartDealing", CallSystem.StartDealing)

function CallSystem.DrawNotifs()
	local notif = CallSystem.CurrentNotif
	if notif and notif.ask_admin then
		CallSystem.AskAdmin(notif)
	elseif CallSystem.DealingWith then
		CallSystem.DrawMainGUI(CallSystem.DealingWith)
	end
end
hook.Add("HUDPaint", "CallSystem", CallSystem.DrawNotifs)

