#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Weapon Setup",
    author = "DanilVusenko",
    description = "Gives players weapons when they connect and respawn",
    version = "1.1"
};

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnClientPutInServer(int client)
{
    if (IsValidClient(client))
    {
        CreateTimer(1.0, Timer_GiveWeapons, GetClientUserId(client));
    }
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client))
    {
        CreateTimer(0.1, Timer_GiveWeapons, GetClientUserId(client));
    }
    
    return Plugin_Continue;
}

public Action Timer_GiveWeapons(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    
    if (IsValidClient(client))
    {
        // Execute weapon give commands as the client
        ClientCommand(client, "give weapon_portalgun");
        ClientCommand(client, "give weapon_physcannon");
        ClientCommand(client, "give weapon_crowbar");
        ClientCommand(client, "give weapon_pistol");
        ClientCommand(client, "give weapon_smg1");
        ClientCommand(client, "give item_suit");
        ClientCommand(client, "upgrade_portalgun");
    }
    
    return Plugin_Stop;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}