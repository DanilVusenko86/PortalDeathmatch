#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <clientprefs>


public Plugin myinfo = 
{
    name = "Map Vote",
    author = "Danil Vusenko",
    description = "Map vote system",
    version = "0.1"
};

Handle g_hVoteMenu = INVALID_HANDLE;
Handle g_hVoteTimer = INVALID_HANDLE;
int g_iVoteCount[3];
int g_iTotalVotes = 0;
char g_sMapList[3][64];

// Cookie for remembering if client has voted
Handle g_hVotedCookie = INVALID_HANDLE;

public void OnPluginStart()
{
    RegAdminCmd("sm_votemap", Command_VoteMap, ADMFLAG_CHANGEMAP, "Starts a map vote");
    RegConsoleCmd("sm_vote", Command_Vote, "Vote for a map");
    
    g_hVotedCookie = RegClientCookie("votemap_voted", "Has client voted", CookieAccess_Protected);
    
    LoadTranslations("common.phrases");
}

public Action Command_VoteMap(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "Usage: sm_votemap <map1> <map2> [map3]");
        return Plugin_Handled;
    }
    
    // Clear previous vote data
    g_hVoteMenu = INVALID_HANDLE;
    g_iTotalVotes = 0;
    for (int i = 0; i < 3; i++) g_iVoteCount[i] = 0;
    
    // Get maps from command
    GetCmdArg(1, g_sMapList[0], sizeof(g_sMapList[]));
    GetCmdArg(2, g_sMapList[1], sizeof(g_sMapList[]));
    
    if (args >= 3)
    {
        GetCmdArg(3, g_sMapList[2], sizeof(g_sMapList[]));
    }
    else
    {
        g_sMapList[2][0] = '\0';
    }
    
    // Reset all clients' voted status
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            SetClientCookie(i, g_hVotedCookie, "0");
        }
    }
    
    // Create VGUI panel for all clients
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            ShowVotePanel(i);
        }
    }
    
    // Start vote timer
    g_hVoteTimer = CreateTimer(20.0, Timer_EndVote, _, TIMER_FLAG_NO_MAPCHANGE);
    
    PrintToChatAll("\x04[MapVote] \x01A map vote has started! Type \x03!vote <1-3>\x01 in chat or use the VGUI menu.");
    
    return Plugin_Handled;
}

void ShowVotePanel(int client)
{
    Panel panel = new Panel();
    panel.SetTitle("Vote for next map:");
    
    char buffer[128];
    
    // Add map options
    Format(buffer, sizeof(buffer), "1. %s", g_sMapList[0]);
    panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
    
    Format(buffer, sizeof(buffer), "2. %s", g_sMapList[1]);
    panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
    
    if (g_sMapList[2][0] != '\0')
    {
        Format(buffer, sizeof(buffer), "3. %s", g_sMapList[2]);
        panel.DrawItem(buffer, ITEMDRAW_DEFAULT);
    }
    
    panel.DrawItem(" ", ITEMDRAW_SPACER);
    panel.DrawItem("0. Cancel", ITEMDRAW_DEFAULT);
    
    panel.Send(client, PanelHandler_Vote, 20);
    delete panel;
}

public int PanelHandler_Vote(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_Select)
    {
        char sCookieValue[8];
        GetClientCookie(client, g_hVotedCookie, sCookieValue, sizeof(sCookieValue));
        
        if (StrEqual(sCookieValue, "1"))
        {
            PrintToChat(client, "\x04[MapVote] \x01You have already voted.");
            return 0;
        }
        
        if (param2 >= 1 && param2 <= 3 && g_sMapList[param2-1][0] != '\0')
        {
            g_iVoteCount[param2-1]++;
            g_iTotalVotes++;
            SetClientCookie(client, g_hVotedCookie, "1");
            PrintToChatAll("\x04[MapVote] \x03%N \x01voted for \x04%s", client, g_sMapList[param2-1]);
        }
    }
    return 0;
}

public Action Command_Vote(int client, int args)
{
    if (g_hVoteMenu == INVALID_HANDLE)
    {
        ReplyToCommand(client, "There is no vote in progress.");
        return Plugin_Handled;
    }
    
    if (args < 1)
    {
        ReplyToCommand(client, "Usage: !vote <1-3>");
        ShowVotePanel(client);
        return Plugin_Handled;
    }
    
    char sArg[8];
    GetCmdArg(1, sArg, sizeof(sArg));
    
    char sCookieValue[8];
    GetClientCookie(client, g_hVotedCookie, sCookieValue, sizeof(sCookieValue));
    
    if (StrEqual(sCookieValue, "1"))
    {
        ReplyToCommand(client, "You have already voted.");
        return Plugin_Handled;
    }
    
    int vote = StringToInt(sArg);
    if (vote >= 1 && vote <= 3 && g_sMapList[vote-1][0] != '\0')
    {
        g_iVoteCount[vote-1]++;
        g_iTotalVotes++;
        SetClientCookie(client, g_hVotedCookie, "1");
        PrintToChatAll("\x04[MapVote] \x03%N \x01voted for \x04%s", client, g_sMapList[vote-1]);
    }
    else
    {
        ReplyToCommand(client, "Invalid vote option. Please choose between 1-3.");
    }
    
    return Plugin_Handled;
}

public Action Timer_EndVote(Handle timer)
{
    g_hVoteTimer = INVALID_HANDLE;
    
    if (g_iTotalVotes == 0)
    {
        PrintToChatAll("\x04[MapVote] \x01Vote ended with no votes.");
        return Plugin_Stop;
    }
    
    // Find winning map
    int winningIndex = 0;
    for (int i = 1; i < 3; i++)
    {
        if (g_iVoteCount[i] > g_iVoteCount[winningIndex] && g_sMapList[i][0] != '\0')
        {
            winningIndex = i;
        }
    }
    
    PrintToChatAll("\x04[MapVote] \x01Vote ended. Next map will be \x04%s \x01with \x03%d/%d \x01votes.", 
        g_sMapList[winningIndex], g_iVoteCount[winningIndex], g_iTotalVotes);
    
    // Change level after delay
    CreateTimer(5.0, Timer_ChangeLevel, winningIndex);
    
    return Plugin_Stop;
}

public Action Timer_ChangeLevel(Handle timer, any winningIndex)
{
    ServerCommand("changelevel %s", g_sMapList[winningIndex]);
    return Plugin_Stop;
}

public void OnMapStart()
{
    // Reset vote when map starts
    g_hVoteMenu = INVALID_HANDLE;
    if (g_hVoteTimer != INVALID_HANDLE)
    {
        KillTimer(g_hVoteTimer);
        g_hVoteTimer = INVALID_HANDLE;
    }
}