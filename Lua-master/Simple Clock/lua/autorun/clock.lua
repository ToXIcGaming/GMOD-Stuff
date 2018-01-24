if (SERVER) then
	AddCSLuaFile("autorun/clock.lua")
end
 
if (CLIENT) then
 
	function clockhud()

		draw.RoundedBox( 20, ScrW()*0.43, ScrH()*0.01, 128, 46, Color( 25, 25, 25, 180 ) )
		draw.SimpleText(os.date( "%a, %I:%M:%S %p" ), "Default", ScrW()*0.444, ScrH()*0.02, Color( 255, 104, 86, 255 ),0,3)
		draw.SimpleText(os.date( "%m/%d/20%y" ), "Default", ScrW()*0.454, ScrH()*0.04, Color( 255, 104, 86, 255 ),0,0)
--		draw.SimpleText( 1 / FrameTime(), "Default", ScrW()*0.024, ScrH()*0.02, Color( 255, 104, 86, 255 ),0,4)
	end
	hook.Add("HUDPaint", "clockhud", clockhud)
end