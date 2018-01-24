ROUND_ACTIVE = 1
ROLE_TRAITOR = -1337
ROLE_DETECTIVE  = -1337
ROLE_INNOCENT = -1337

function GetRoundState()
	return ROUND_ACTIVE
end

function util.SimpleTime(seconds, fmt)
	if not seconds then seconds = 0 end

    local ms = (seconds - math.floor(seconds)) * 100
    seconds = math.floor(seconds)
    local s = seconds % 60
    seconds = (seconds - s) / 60
    local m = seconds % 60

    return string.format(fmt, m, s, ms)
end