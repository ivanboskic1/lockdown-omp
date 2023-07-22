#pragma option -d3
/**
TODO
 */
/*
	- Gamemode name: lockdown by DinoWETT
    - Version: v1.0
    - Switched to open.mp version by Ivan
*/
#define YSI_YES_HEAP_MALLOC
#define YSI_NO_OBNOXIOUS_HEADER
#define YSI_NO_OPTIMISATION_MESSAGE

#pragma warning disable 234

//#define CGEN_MEMORY 60000
//
#include <open.mp>
#include <a_mysql>
#include <crashdetect>
#include <distance>
#include <easyDialog>
#include <formatex>
#include <mapfix>
#include <sscanf2>
#include <streamer>
#include <ysilib\YSI_Coding\y_hooks>
#include <ysilib\YSI_Core\y_utils.inc>
#include <ysilib\YSI_Coding\y_timers>
#include <ysilib\YSI_Visual\y_commands> 
#include <ysilib\YSI_Data\y_foreach>
#include <ysilib\YSI_Data\y_iterate>
//
#define col_white      0xFFFFFFFF
#define col_yellow     0xFFFF00FF
#define col_red        0xFF0000FF
#define col_server     0x0099FFAA
//
#define c_white    "{FFFFFF}"
#define c_yellow   "{FFFF00}"
#define c_red      "{FF0000}"
#define c_server   "{0099FF}"

//================== [DATABASE] =======================//
#define DB_DATABASE 		"lockdown_omp"
#define DB_HOST 			"localhost"
#define DB_USER 			"root"
#define DB_PASSWORD 		""
//================== [REG/LOG SYSTEM] ==================//
new MySQL:_Database;

const MAX_PASSWORD_LENGTH = 65;
const MIN_PASSWORD_LENGTH = 6;
const MAX_LOGIN_ATTEMPTS = 	3;

static  
	player_sqlID[MAX_PLAYERS],
	player_Username[MAX_PLAYERS][MAX_PLAYER_NAME],
	player_realPassword[MAX_PLAYERS],
    player_Password[MAX_PLAYERS][MAX_PASSWORD_LENGTH],
    player_Score[MAX_PLAYERS],
	player_Skin[MAX_PLAYERS],
    player_Money[MAX_PLAYERS],
    player_LoginAttempts[MAX_PLAYERS];

timer Spawn_Player[100](playerid, type)
{
	if(type == 1)
    {
		SendClientMessage(playerid, -1, ""c_server"Lockdown // "c_white"You have successfully registered!");
		SetSpawnInfo(playerid, 0, player_Skin[playerid], -2193.9375, -2256.1196, 30.6873, 151.0796, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
	    SpawnPlayer(playerid);
		SetPlayerScore(playerid, player_Score[playerid]);
		GivePlayerMoney(playerid, player_Money[playerid]);
		SetPlayerSkin(playerid, player_Skin[playerid]);
	}
    else if(type == 2)
	{
		SendClientMessage(playerid, col_server,"Lockdown // "c_white"You have successfully applied!");
		SetSpawnInfo(playerid, 0, player_Skin[playerid], -2193.9375, -2256.1196, 30.6873, 151.0796, WEAPON_FIST, 0, WEAPON_FIST, 0, WEAPON_FIST, 0);
		SpawnPlayer(playerid);
		SetPlayerScore(playerid, player_Score[playerid]);
		GivePlayerMoney(playerid, player_Money[playerid]);
		SetPlayerSkin(playerid, player_Skin[playerid]);
	}
	return 1;
}

forward Account_CheckData(playerid);
public Account_CheckData(playerid) {
    new rows = cache_num_rows();
    if(!rows) {
        Dialog_Show(playerid, "dialog_regpassword", DIALOG_STYLE_INPUT, "Register", "Please enter the desired password", "Register", "Quit");
    } else {
        cache_get_value_name(0, "password", player_Password[playerid], MAX_PASSWORD_LENGTH);
        Dialog_Show(playerid, "dialog_login", DIALOG_STYLE_INPUT, "Login", "Please enter your password", "Login", "Quit");
    }
    return 1;
}

forward Account_LoadData(playerid);
public Account_LoadData(playerid) {
    new rows = cache_num_rows();
    if(!rows) return 0;
    else {
        cache_get_value_name_int(0, "id", player_sqlID[playerid]);
		cache_get_value_name(0, "password", player_Password[playerid], MAX_PASSWORD_LENGTH);
		cache_get_value_name_int(0, "score", player_Score[playerid]);
		cache_get_value_name_int(0, "skin", player_Skin[playerid]);
		cache_get_value_name_int(0, "money", player_Money[playerid]);
        defer Spawn_Player(playerid, 2);
    }
    return 1;
}

forward Account_Registered(playerid);
public Account_Registered(playerid) {
    player_Username[playerid] = ReturnPlayerName(playerid);
    player_Money[playerid] = 1000;
    player_Skin[playerid] = 240;
    player_Score[playerid] = 0;
    defer Spawn_Player(playerid, 1);
    return 1;
}

stock Account_SaveData(playerid) {
    new query[512];
	mysql_format(_Database, query, sizeof query, "UPDATE `users` SET `username` = '%e', `score` = '%d', `skin` = '%d', `money` = '%d' WHERE `id` = '%d'", 
	ReturnPlayerName(playerid), player_Score[playerid], player_Skin[playerid], player_Money[playerid], player_sqlID[playerid]);
	mysql_tquery(_Database, query);
    return 1;
}

stock IsVehicleBicycle(m) {
    if (m == 481 || m == 509 || m == 510) return 1;
    return 0;
}

stock GetVehicleSpeed(vehicleid) {
	new Float:xPos[3];
	GetVehicleVelocity(vehicleid, xPos[0], xPos[1], xPos[2]);
	return floatround(floatsqroot(xPos[0] * xPos[0] + xPos[1] * xPos[1] + xPos[2] * xPos[2]) * 170.00);
}

main() {
    print("-                                     -");
	print(" Founder : realnaith");
	print(" Version : 1.0 - Lockdown              ");
	print(" Credits : realnaith, nodi, ivan       ");
	print("-                                     -");
	print("> Gamemode Starting...");
	print(">> Lockdown - Gamemode Started");
    print("-                                     -");
}

public OnGameModeInit() {
	SetGameModeText("lockdown-omp");
    DisableInteriorEnterExits();
	ManualVehicleEngineAndLights();
	ShowPlayerMarkers(PLAYER_MARKERS_MODE_OFF);
	SetNameTagDrawDistance(20.0);
	LimitGlobalChatRadius(20.0);
	AllowInteriorWeapons(true);
	EnableVehicleFriendlyFire();
	EnableStuntBonusForAll(false);
    _Database = mysql_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_DATABASE);
	if(_Database == MYSQL_INVALID_HANDLE || mysql_errno(_Database) != 0) {
		SendRconCommand("exit");
	}
	print(">> Lockdown : Connection has been established");
    return 1;
}

public OnPlayerConnect(playerid) {
	TogglePlayerSpectating(playerid, false);
	SetPlayerColor(playerid, col_white);
	player_LoginAttempts[playerid] = 0;
	new query[512];
	mysql_format(_Database, query, sizeof query, "SELECT * FROM `users` WHERE `username` = '%e'", ReturnPlayerName(playerid));
	mysql_tquery(_Database, query, "Account_CheckData", "i", playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason) {
	Account_SaveData(playerid);
	return 1;
}

public OnPlayerSpawn(playerid) {
	SetPlayerTeam(playerid, NO_TEAM);
	return 1;
}

public OnVehicleSpawn(vehicleid) {
	new bool:engine, bool:lights, bool:alarm = false, bool:doors, bool:bonnet, bool:boot, bool:objective;
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
    if(IsVehicleBicycle(GetVehicleModel(vehicleid)))
        SetVehicleParamsEx(vehicleid, engine = true, lights = false, alarm = false, doors, bonnet, boot, objective);
    else 
        SetVehicleParamsEx(vehicleid, false, false, false, doors, bonnet, boot, objective);
	return 1;
}

public OnPlayerStateChange(playerid, PLAYER_STATE:newstate, PLAYER_STATE:oldstate) {
	new vehicle = GetPlayerVehicleID(playerid), bool:engine, bool:lights, bool:alarm, bool:doors, bool:bonnet, bool:boot, bool:objective;
    GetVehicleParamsEx(vehicle, engine, lights, alarm, doors, bonnet, boot, objective);
	if(newstate == PLAYER_STATE_DRIVER) 
        if(engine == VEHICLE_PARAMS_OFF)
            SendClientMessage(playerid, -1, ""c_server"Lockdown // "c_white"To start the engine use the 'N' key");
	return 1;
}

public OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys) {
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER) {
        if(newkeys & KEY_NO) {
            new vehicle = GetPlayerVehicleID(playerid), bool:engine, bool:lights, bool:alarm, bool:doors, bool:bonnet, bool:boot, bool:objective;
            if(IsVehicleBicycle(GetVehicleModel(vehicle)))
                return 1;
            GetVehicleParamsEx(vehicle, engine, lights, alarm, doors, bonnet, boot, objective);
            if(engine == VEHICLE_PARAMS_OFF)
                SetVehicleParamsEx(vehicle, VEHICLE_PARAMS_ON, lights, alarm, doors, bonnet, boot, objective);
            else
                SetVehicleParamsEx(vehicle, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective);
            new str[60];
            format(str, sizeof(str),""c_server"Lockdown // "c_white"%s si motor.", (engine == VEHICLE_PARAMS_OFF) ? "Upalio" : "Ugasio");
            SendClientMessage(playerid, -1, str);
            return 1;
		}
        if(newkeys & KEY_YES) {
            new vehicle = GetPlayerVehicleID(playerid), bool:engine, bool:lights, bool:alarm, bool:doors, bool:bonnet, bool:boot, bool:objective;
            if(IsVehicleBicycle(GetVehicleModel(vehicle)))
                return 1;
            GetVehicleParamsEx(vehicle, engine, lights, alarm, doors, bonnet, boot, objective);
            if(lights == VEHICLE_PARAMS_OFF)
                SetVehicleParamsEx(vehicle, engine, VEHICLE_PARAMS_ON, alarm, doors, bonnet, boot, objective);
            else
                SetVehicleParamsEx(vehicle, engine, VEHICLE_PARAMS_OFF, alarm, doors, bonnet, boot, objective);
            new str[60];
            format(str, sizeof(str),""c_server"Lockdown // "c_white"%s si svetla.", (lights == VEHICLE_PARAMS_OFF) ? "Upalio" : "Ugasio");
            SendClientMessage(playerid, -1, str);
            return 1;
        }
	}
	return 1;
}

Dialog:dialog_regpassword(playerid, response, listitem, string:inputtext[]) {
	if(!response) return Kick(playerid);
	if(!(MIN_PASSWORD_LENGTH <= strlen(inputtext) <= MAX_PASSWORD_LENGTH)) return Dialog_Show(playerid, "dialog_regpassword", DIALOG_STYLE_INPUT, "Register", "Please enter the desired password", "Register", "Quit");
	SHA256_PassHash(inputtext, ReturnPlayerName(playerid), player_Password[playerid], 65);
	strmid(player_realPassword[playerid], inputtext, 0, strlen(inputtext), 65);
	new query[512];
	mysql_format(_Database, query, sizeof query, "INSERT INTO `users` (`username`, `password`, `score`, `skin`, `money`) \
	VALUES ('%e', '%e', 0, 240, 1000)", ReturnPlayerName(playerid), player_Password[playerid]);
	mysql_tquery(_Database, query, "Account_Registered", "i", playerid);
	return 1;
}

Dialog:dialog_login(playerid, response, listitem, string:inputtext[]) {
	if(!response) return Kick(playerid);
	new pass[65];
	SHA256_PassHash(inputtext, ReturnPlayerName(playerid), pass, 65);
	if(strcmp(pass, player_Password[playerid]) == 0) {
		strmid(player_realPassword[playerid], inputtext, 0, strlen(inputtext), 65);
		new query[512];
		mysql_format(_Database, query, sizeof query, "SELECT * FROM `users` WHERE `username` = '%e' LIMIT 1", ReturnPlayerName(playerid));
		mysql_tquery(_Database, query, "Account_LoadData", "i", playerid);
	} else {
		++player_LoginAttempts[playerid];
		if(player_LoginAttempts[playerid] == MAX_LOGIN_ATTEMPTS)
			SendClientMessage(playerid, col_red, "Wrong password");
		Dialog_Show(playerid, "dialog_login", DIALOG_STYLE_INPUT, "Login", "Please enter your password", "Login", "Quit");
	}
	return 1;
}