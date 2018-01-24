
AddCSLuaFile()

CallSystem = {}

if SERVER then
	AddCSLuaFile("call_system/cl_callsystem.lua")
	include("call_system/sv_callsystem.lua")
end

if CLIENT then
	include("call_system/cl_callsystem.lua")
end