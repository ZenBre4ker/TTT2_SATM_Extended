--make sure that the convarutil.lua exists that adds all convars
if SERVER then
	AddCSLuaFile()
	if file.Exists("terrortown/scripts/sh_convarutil_local.lua", "LUA") then
		AddCSLuaFile("terrortown/scripts/sh_convarutil_local.lua")
	end
end

if file.Exists("terrortown/scripts/sh_convarutil_local.lua", "LUA") then
	include("terrortown/scripts/sh_convarutil_local.lua")
-- Must run before hook.Add
	local shortNameOfAddon = "SATM"
	local longNameOfAddon = "Space-Time Manipulator"

	local cg = ConvarGroup(shortNameOfAddon, longNameOfAddon)

	--Convar(ConvarGroup cg , Bool TTT2-Only, String ttt_Addon_Modifier, Bool/Int/Float DefaultValue, Table{} FCVAR_Flags, String Modifier Description, String Datatype ("bool","int","float"), Bool/Int/Float MinValue, Bool/Int/Float MaxValue, Int Decimalpoints)
	--Example:
	--Convar(cg, false, "ttt_asm_shift_speed_modifier", 2, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Movement speed multiplier during the aiming sequence", "float", 0.01, 8, 2)
	
	Convar(cg, false, "ttt_satm_detective", 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Should Detectives be able to buy the SATM?", "bool", 0, 1, 0)
	Convar(cg, false, "ttt_satm_traitor", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Should Traitors be able to buy the SATM?", "bool", 0, 1, 0)
	Convar(cg, false, "ttt_satm_duration", 10, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How long the duration of the SATM should be?", "int", 1, 20, 0)
	Convar(cg, false, "ttt_satm_use_charges", 4, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How many charges should the SATM overall have?", "int", 1, 10, 0)
	Convar(cg, false, "ttt_satm_teleport_charges", 2, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "How many charges should the teleport function have?", "int", 1, 10, 0)
--

print(shortNameOfAddon .. " Convars are created.")

end
