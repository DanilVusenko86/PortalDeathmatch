#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"
#define DATA_FILE "roundtimer_data.txt"

ConVar g_cvRoundTime;
Handle g_hTimer;
int g_iTimeLeft;
bool g_bTimerRunning;
int g_iSavedTime;

public Plugin myinfo = 
{
    name = "Round Timer",
    author = "DanilVusenko",
    description = "Round timer with countdown display and map vote trigger",
    version = PLUGIN_VERSION
};

public void OnPluginStart()
{
    RegAdminCmd("sm_roundtime", Command_RoundTime, ADMFLAG_CHANGEMAP, "Set round time in minutes");
    
    g_cvRoundTime = CreateConVar("sm_roundtime_default", "10", "Default round time in minutes", FCVAR_NONE, true, 1.0);
    
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    
    // Load saved time value
    LoadSavedTime();
}

public void OnMapStart()
{
    // Start timer with saved time when map starts
    if (g_iSavedTime > 0 && !g_bTimerRunning)
    {
        StartRoundTimer(g_iSavedTime * 60);
        PrintToChatAll("[SM] Round timer set to %d minutes (saved value).", g_iSavedTime);
    }
    else if (!g_bTimerRunning)
    {
        int defaultTime = GetConVarInt(g_cvRoundTime) * 60;
        StartRoundTimer(defaultTime);
    }
}

public Action Command_RoundTime(int client, int args)
{
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: sm_roundtime <time in minutes>");
        ReplyToCommand(client, "Current time: %d minutes", g_iSavedTime);
        return Plugin_Handled;
    }
    
    char sTime[8];
    GetCmdArg(1, sTime, sizeof(sTime));
    
    int minutes = StringToInt(sTime);
    if (minutes <= 0)
    {
        ReplyToCommand(client, "Time must be greater than 0 minutes.");
        return Plugin_Handled;
    }
    
    // Save the time setting
    g_iSavedTime = minutes;
    SaveTimeSetting();
    
    // Restart the timer with new time
    StartRoundTimer(minutes * 60);
    PrintToChatAll("[SM] Round timer set to %d minutes by %N. This setting will persist across maps.", minutes, client);
    
    return Plugin_Handled;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bTimerRunning)
    {
        // Use saved time if available, otherwise use default
        int roundTime = (g_iSavedTime > 0) ? g_iSavedTime * 60 : GetConVarInt(g_cvRoundTime) * 60;
        StartRoundTimer(roundTime);
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    StopRoundTimer();
}

void StartRoundTimer(int seconds)
{
    StopRoundTimer();
    
    g_iTimeLeft = seconds;
    g_bTimerRunning = true;
    
    g_hTimer = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
    
    DisplayTimeToAll();
}

void StopRoundTimer()
{
    if (g_hTimer != INVALID_HANDLE)
    {
        KillTimer(g_hTimer);
        g_hTimer = INVALID_HANDLE;
    }
    g_bTimerRunning = false;
}

public Action Timer_Countdown(Handle timer)
{
    if (!g_bTimerRunning)
    {
        g_hTimer = INVALID_HANDLE;
        return Plugin_Stop;
    }
    
    g_iTimeLeft--;
    
    DisplayTimeToAll();
    
    if (g_iTimeLeft <= 0)
    {
        g_bTimerRunning = false;
        g_hTimer = INVALID_HANDLE;
        
        TriggerMapVote();
        return Plugin_Stop;
    }
    
    return Plugin_Continue;
}

void DisplayTimeToAll()
{
    int minutes = g_iTimeLeft / 60;
    int seconds = g_iTimeLeft % 60;
    
    char timeDisplay[16];
    Format(timeDisplay, sizeof(timeDisplay), "%02d:%02d", minutes, seconds);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            PrintHintText(i, "Time Remaining: %s", timeDisplay);
        }
    }
}

void TriggerMapVote()
{
    PrintToChatAll("[SM] Round time ended! Starting map vote...");
    
    // Get 3 random maps from mapscycle.txt
    char map1[64], map2[64], map3[64];
    if (GetRandomMaps(map1, sizeof(map1), map2, sizeof(map2), map3, sizeof(map3)))
    {
        // Execute the sm_votemap command with 3 random maps
        char command[256];
        Format(command, sizeof(command), "sm_votemap %s %s %s", map1, map2, map3);
        ServerCommand(command);
    }
    else
    {
        PrintToChatAll("[SM] Error: Could not read maps from mapscycle.txt");
    }
}

bool GetRandomMaps(char[] map1, int size1, char[] map2, int size2, char[] map3, int size3)
{
    // Build path to mapscycle.txt
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "../../cfg/mapscycle.txt");
    
    // Try alternative location if first doesn't work
    if (!FileExists(path))
    {
        BuildPath(Path_SM, path, sizeof(path), "configs/mapcycle.txt");
    }
    
    // Open the file
    File file = OpenFile(path, "r");
    if (file == null)
    {
        LogError("Could not open mapscycle.txt at: %s", path);
        return false;
    }
    
    // Read all maps into an array
    ArrayList maps = new ArrayList(ByteCountToCells(64));
    char line[128];
    
    while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
    {
        // Clean up the line
        TrimString(line);
        StripQuotes(line);
        
        // Skip empty lines and comments
        if (strlen(line) == 0 || line[0] == '/' || line[0] == ';' || line[0] == '#')
            continue;
        
        // Add to our list
        maps.PushString(line);
    }
    
    delete file;
    
    int mapCount = maps.Length;
    if (mapCount < 3)
    {
        LogError("Need at least 3 maps in mapscycle.txt, found %d", mapCount);
        delete maps;
        return false;
    }
    
    // Get 3 unique random maps
    int indices[3];
    indices[0] = GetRandomInt(0, mapCount - 1);
    
    do {
        indices[1] = GetRandomInt(0, mapCount - 1);
    } while (indices[1] == indices[0]);
    
    do {
        indices[2] = GetRandomInt(0, mapCount - 1);
    } while (indices[2] == indices[0] || indices[2] == indices[1]);
    
    // Get the map names
    maps.GetString(indices[0], map1, size1);
    maps.GetString(indices[1], map2, size2);
    maps.GetString(indices[2], map3, size3);
    
    delete maps;
    return true;
}

void LoadSavedTime()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s", DATA_FILE);
    
    if (FileExists(path))
    {
        File file = OpenFile(path, "r");
        if (file != null)
        {
            char line[16];
            if (file.ReadLine(line, sizeof(line)))
            {
                TrimString(line);
                g_iSavedTime = StringToInt(line);
            }
            delete file;
        }
    }
    
    // If no saved time or invalid, use default
    if (g_iSavedTime <= 0)
    {
        g_iSavedTime = GetConVarInt(g_cvRoundTime);
    }
}

void SaveTimeSetting()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s", DATA_FILE);
    
    // Create data directory if it doesn't exist
    char dir[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dir, sizeof(dir), "data");
    if (!DirExists(dir))
    {
        CreateDirectory(dir, 511);
    }
    
    File file = OpenFile(path, "w");
    if (file != null)
    {
        char timeStr[16];
        IntToString(g_iSavedTime, timeStr, sizeof(timeStr));
        file.WriteLine(timeStr);
        delete file;
    }
}

public void OnMapEnd()
{
    StopRoundTimer();
}