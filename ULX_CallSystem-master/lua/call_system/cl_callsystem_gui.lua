
local warning_icon = Material("icon16/exclamation.png")
local clock_icon = Material("icon16/clock.png")
local information_icon = Material("icon16/information.png")
local buttons = {}

surface.CreateFont("CallSystem_Title", {
	font = "Arial",
	size = 16,
	weight = 800
})

surface.CreateFont("CallSystem_Quote", {
	font = "Arial",
	size = 16,
	weight = 800,
	italic = true
})

if IsValid(CallSystem.Avatar) then CallSystem.Avatar:Remove() end
CallSystem.Avatar = vgui.Create("AvatarImage")
CallSystem.Avatar:SetVisible(false)
CallSystem.Avatar:SetSize(32, 32)

local function AdjustText(str, font, w)
	surface.SetFont(font)
	local size = surface.GetTextSize(str)
	if size <= w then
		return str
	else
		local last_space
		local i = 0
		for k,v in pairs(string.ToTable(str)) do
			local _w,h = surface.GetTextSize(v)
			i = i + _w
			if i > w then
				local sep = last_space or k
				return string.Left(str, sep), string.Right(str, #str - sep)
			end	
			if v == " " then
				last_space = k
			end
		end
	end
end

local function GetPopPos(notif, w, normal_x, pop_out)
	local animspeed = 0.5
	if not notif.animended then
		if not notif.animpos then
			notif.animpos = -normal_x - w
			if notif.End then
				notif.animpos = normal_x + w
			end
			notif.animstart = CurTime()
			notif.animend = CurTime() + animspeed
			return notif.animpos
		else
			local diff = animspeed - (notif.animend - CurTime())
			if diff >= animspeed then
				notif.animended = true
				if pop_out then
					return normal_x
				else
					CallSystem.CurrentNotif = nil
					return false
				end
			end
			local animpos = normal_x*diff / animspeed
			local scale = math.sin((math.pi/2) * diff/animspeed)
			if pop_out then
				return ((normal_x+w)*scale)-w
			else
				return (normal_x) - ((normal_x+w)*scale)
			end
		end
	else
		return normal_x
	end
end

local is_in = false
local function IsButtonHovered(tbl)
	local mx, my = gui.MousePos()
	return (mx >= tbl.x and mx <= (tbl.x + tbl.w)) and (my >= tbl.y and my <= (tbl.y + tbl.h))
end

local function button(title, hoveredc, not_hovered, x, y, w, h, callback)
	local tbl = { x = x, y = y, w = w, h = h, callback = callback }
	table.insert(buttons, tbl)
	local hovered = IsButtonHovered(tbl)
	local color = hovered and hoveredc or not_hovered
	local pnl = vgui.GetWorldPanel()
	if hovered and not is_in then
		local pnl = vgui.GetWorldPanel()
		if pnl and pnl:IsValid() then
			pnl:SetCursor("hand")
		end
		is_in = true
	elseif not hovered and is_in then
		is_in = false
		if pnl and pnl:IsValid() then
			pnl:SetCursor("arrow")
		end		
	end
	draw.RoundedBox(2, x, y, w, h, CallSystem.GetColor("button_outline"))
	draw.RoundedBox(2, x+1, y+1, w-2, h-2, color)
	draw.SimpleText(title, "CallSystem_Title", x + w/2, y + h/2, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local pressed_key = false
function CallSystem.Think()
	if input.IsMouseDown(MOUSE_LEFT) and not pressed_key then
		pressed_key = true
		for k,v in pairs(buttons) do
			if IsButtonHovered(v) then
				v.callback(v)
				break
			end
		end
	elseif pressed_key and not input.IsMouseDown(MOUSE_LEFT) then
		pressed_key = false
	end	
end
hook.Add("Think", "CallSystem", CallSystem.Think)

function CallSystem.DrawReason(tbl, x, y, w, reason1, reason2, reason3, reason2_1)
	CallSystem.Avatar:SetVisible(true)
	CallSystem.Avatar:SetPos(x+10, y+32)
	local text = tbl.ply:Nick()..CallSystem.GetText("receivecall_text_part1")..os.date("%H:%M:%S", tbl.t)..CallSystem.GetText("receivecall_text_part2")
	local text1, text2 = AdjustText(text, "CallSystem_Title", w - 52)
	draw.SimpleText(text1, "CallSystem_Title", x + 48, y + 30, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	draw.SimpleText(text2, "CallSystem_Title", x + 48, y + 50, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	local box_h = reason2 and (not reason3 and 45 or 65) or 25
	surface.SetDrawColor(CallSystem.GetColor("background_quote"))
	surface.DrawRect(x+10, y + 70, w - 20, box_h)
	draw.SimpleText(reason1, "CallSystem_Quote", x + 15, y + 75, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	if reason2 then
		draw.SimpleText(reason3 and reason2_1 or reason2, "CallSystem_Quote", x + 15, y + 95, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		if reason3 then
			draw.SimpleText(reason3, "CallSystem_Quote", x + 15, y + 115, color_black, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
		end
	end
	
end

function CallSystem.AskAdmin(notif)
	table.Empty(buttons)
	if not IsValid(notif.ply) then
		table.Empty(notif)
		return
	end
	local w = 350
	local reason1, reason2 = AdjustText(notif.message, "CallSystem_Quote", w-40)
	local reason2_1, reason3
	if reason2 then
		reason2_1, reason3 = AdjustText(reason2, "CallSystem_Quote", w-40)
	end
	local h = reason2 and (not reason3 and 145 or 165) or 125
	local y = ScrH()/2 - w/2
	local normal_x = 10
	local x = GetPopPos(notif, w, normal_x, not notif.End)
	if not x then return end
	if x > normal_x then x = normal_x end
	draw.RoundedBox(2, x, y, w, h, color_black)
	draw.RoundedBox(2, x+1, y+1, w-2, h-2, CallSystem.GetColor("background_white"))
	draw.RoundedBox(2, x+1, y+1, w-2, 7, CallSystem.GetColor("background_red"))
	surface.SetDrawColor( CallSystem.GetColor("background_red"))
	surface.DrawRect(x+1, y+8, w-2, 16)
	surface.SetDrawColor(color_black)
	surface.DrawLine(x, y+24, x+w, y+24)
	surface.SetDrawColor(color_white)
	surface.SetMaterial(warning_icon)
	surface.DrawTexturedRect(x+6, y+5, 16, 16)
	surface.SetMaterial(clock_icon)
	surface.DrawTexturedRect(x + w - 37, y + 7, 12, 12)
	draw.SimpleText(CallSystem.GetText("receivecall_title"), "CallSystem_Title", x + 26, y + 5, Color(41, 46, 54), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	local remainingtime = tostring(notif.remainingtime)
	local scale = remainingtime/15
	local color
	if scale > 0.66 then
		color = CallSystem.GetColor("text_green")
	elseif scale <= 0.66 and scale > 0.33 then
		color = CallSystem.GetColor("text_yellow")
	else
		color = CallSystem.GetColor("text_red")
	end
	draw.SimpleText(remainingtime, "CallSystem_Title", x + w -20, y + 5, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	CallSystem.DrawReason(notif, x, y, w, reason1, reason2, reason3, reason2_1) 
	local y_button = reason2 and (not reason3 and 120 or 140) or 100
	button(CallSystem.GetText("receivecall_button"), CallSystem.GetColor("green_button_hovered"), CallSystem.GetColor("green_button_not_hovered"), x + 10, y + y_button, 75, 20, function() 
		CallSystem.CurrentNotif.Stop()
		net.Start("CallSystem_AcceptCall")
		net.WriteUInt(notif.id, 32)
		net.SendToServer()
	end)
end

function CallSystem.DrawMainGUI(tbl)
	table.Empty(buttons)
	if not IsValid(tbl.ply) then return end
	local w = 350
	local x = GetPopPos(tbl, w, 10, not tbl.End)
	if not x then
		CallSystem.DealingWith = nil
		return
	end
	local reason1, reason2 = AdjustText(tbl.message, "CallSystem_Quote", w-40)
	local reason2_1, reason3
	if reason2 then
		reason2_1, reason3 = AdjustText(reason2, "CallSystem_Quote", w-40)
	end
	local h = reason2 and (not reason3 and 173 or 193) or 153
	local y =  100
	draw.RoundedBox(2, x, y, w, h, color_black)
	draw.RoundedBox(2, x+1, y+1, w-2, h-2, CallSystem.GetColor("background_white"))
	draw.RoundedBox(2, x+1, y+1, w-2, 7, CallSystem.GetColor("background_blue"))
	surface.SetDrawColor( CallSystem.GetColor("background_blue"))
	surface.DrawRect(x+1, y+8, w-2, 16)
	surface.SetDrawColor(color_black)
	surface.DrawLine(x, y+24, x+w, y+24)
	surface.SetDrawColor(color_white)
	surface.SetMaterial(information_icon)
	surface.DrawTexturedRect(x+6, y+5, 16, 16)
	draw.SimpleText(CallSystem.GetText("call_ui_title"), "CallSystem_Title", x + 26, y + 5, Color(41, 46, 54), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	surface.SetDrawColor(CallSystem.GetColor("background_lightblue"))
	local backgroundw = reason2 and (not reason3 and 95 or 115) or 75
	surface.DrawRect(x+1, y+25, w-2, backgroundw)
	CallSystem.DrawReason(tbl, x, y, w, reason1, reason2, reason3, reason2_1, 5)
	if not tbl.close_enough then
		draw.SimpleText(CallSystem.GetText("not_close"), "CallSystem_Title", x + 11, y + backgroundw + 28, CallSystem.GetColor("text_red"), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	else
		draw.SimpleText(CallSystem.GetText("close_enough"), "CallSystem_Title", x + 11, y + backgroundw + 28, CallSystem.GetColor("text_green"), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
	end
	local y_buttons = 49 + backgroundw
	button(CallSystem.GetText("admin_commands"), CallSystem.GetColor("green_button_hovered"), CallSystem.GetColor("green_button_not_hovered"), x + 10, y + y_buttons, 130, 20, function()
		local options = DermaMenu()
		for k,v in ipairs(CallSystem.Commands) do
			options:AddOption(v.name, function() 
				RunConsoleCommand("ulx", v.command, tbl.ply:Nick()) 
				surface.PlaySound("buttons/button9.wav") 
			end):SetImage(v.icon)
		end
		options:Open()
	end)
	button(CallSystem.GetText("end_call_button"), CallSystem.GetColor("red_button_hovered"), CallSystem.GetColor("red_button_not_hovered"), x + 150, y + y_buttons, 70, 20, function()
		Derma_StringRequest(CallSystem.GetText("end_call_title"), CallSystem.GetText("end_call_message"), nil, function(str)
			tbl.Stop()
			net.Start("CallSystem_CallEnd")
			net.WriteUInt(tbl.id, 32)
			net.WriteString(str)
			net.SendToServer()
		end)
	end)
end