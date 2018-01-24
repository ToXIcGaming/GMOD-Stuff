
-- The time (seconds) needed for the admin to accept a report
CallSystem.AcceptTimer = 15

-- The minimum distance to get a point if you're an admin
CallSystem.Distance = 200

-- Antispam time (seconds)
CallSystem.AntispamTime = 120

-- Admins on these teams will be the first to be called
CallSystem.PriorityTeams = {}

-- Commands
CallSystem.Commands = {
	{
		name = "Goto",
		icon = "icon16/arrow_right.png",
		command = "goto"
	}
}
