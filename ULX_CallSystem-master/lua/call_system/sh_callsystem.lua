
include("call_system/config/general_config.lua")
include("call_system/config/texts.lua")

function CallSystem.GetText(id)
	local text = CallSystem.Texts[id] or false
	return text or "<string not found>", text and true
end

function CallSystem.GetColor(id)
	return CallSystem.Colors[id] or color_white
end