
CallSystem.Colors = {

	-- chat
	chat_blue = Color(98, 176, 255),
	chat_red = Color(255,62,62),
	chat_tag = Color(228, 156, 77),
	
	-- GUI
	background_white = Color(213, 216, 220),
	background_red =  Color(212, 122, 122),
	background_blue = Color(111, 142, 203),
	background_quote = Color(255, 253, 236),
	background_lightblue = Color(176, 197, 229),
	
	button_outline = Color(60, 60, 60),
	green_button_hovered = Color(107, 166, 111),
	green_button_not_hovered = Color(146, 213, 150),
	red_button_hovered = Color(166, 107, 111),
	red_button_not_hovered = Color(213, 146, 150),
	
	text_green = Color(41, 120, 46),
	text_yellow = Color(206, 191, 17),
	text_red = Color(206, 43, 17)

}

CallSystem.Texts = {

	-- chat
	command_description = "Call an admin using the admin assignment system",
	admins_busy = "All admins are dealing with situations, you are next in line.",
	admins_offline = "Could not find any admin.",
	admins_notified = " has been notified. Please wait.",
	admins_refused = "Sorry, your call has not been accepted by any admin.",
	admin_accepted = " has accepted your call.",
	admin_left = "The call has ended because the admin has left the server.",
	player_left = "The call has ended because the calling player has left the server.",
	chat_tag = "[Call System]",
	call_end = "The call has ended with the conclusion : ",
	antispam_part1 = "Please wait ",
	antispam_part2 = " seconds before doing another call.",
	
	-- Admin receiving a call
	receivecall_title = "You have received a call !",
	receivecall_text_part1 = " has called the admins at ",
	receivecall_text_part2 = " with the reason :",
	receivecall_button = "Accept",
	refused_why_title = "Refusal reason",
	refused_why_message = "Please explain why you refused to take this call",
	
	-- Admin dealing with a call
	call_ui_title = "You are currently dealing with a call",
	admin_commands = "Admin commands",
	end_call_button = "End call",
	not_close = "Go to the victim or you won't get a point.",
	close_enough = "You will be awarded a point by ending this call.",
	
	-- Ending a call
	end_call_title = "Ending a call",
	end_call_message = "Please write a small conclusion."
}
