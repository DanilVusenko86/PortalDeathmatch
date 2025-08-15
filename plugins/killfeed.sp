#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "Killfeed",
    author = "DanilVusenko",
    description = "Displays a killfeed in chat and HUD for player deaths",
    version = "1.0.0"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    bool headshot = event.GetBool("headshot");

    // Validate victim
    if (victim < 1 || victim > MaxClients || !IsClientInGame(victim))
        return;

    char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH], message[128];
    
    // Get victim name from client info (like 'name' command)
    if (!GetClientInfo(victim, "name", victimName, sizeof(victimName)) || !victimName[0])
    {
        strcopy(victimName, sizeof(victimName), "Unknown");
    }

    // Handle different kill scenarios
    if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker))
    {
        if (attacker == victim)
        {
            Format(message, sizeof(message), "%s committed suicide", victimName);
        }
        else
        {
            // Get attacker name from client info
            if (!GetClientInfo(attacker, "name", attackerName, sizeof(attackerName)) || !attackerName[0])
            {
                strcopy(attackerName, sizeof(attackerName), "Unknown");
            }
            
            Format(message, sizeof(message), "%s killed %s", 
                attackerName, victimName);
        }
    }
    else
    {
        Format(message, sizeof(message), "%s died", victimName);
    }

    // Broadcast to chat
    PrintToChatAll("[Killfeed] %s", message);

    // Display on HUD for all players
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            ShowHudText(i, -1, message);
        }
    }
}