#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name = "Chat Name Fix",
    author = "DanilVusenko",
    description = "Fixes player names not showing in Portal 1 chat",
    version = "1.0"
};

public void OnPluginStart() {
    HookUserMessage(GetUserMessageId("SayText"), Hook_SayText, true);
    HookUserMessage(GetUserMessageId("SayText2"), Hook_SayText2, true);
}

public Action Hook_SayText(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
    int client = msg.ReadByte();
    char message[256];
    msg.ReadString(message, sizeof(message), true);

    if (client <= 0 || client > MaxClients || !IsClientInGame(client)) {
        return Plugin_Continue; 
    }

    char clientName[MAX_NAME_LENGTH];
    if (!GetClientInfo(client, "name", clientName, sizeof(clientName)) || !clientName[0]) {
        GetClientName(client, clientName, sizeof(clientName));
    }

    char formattedMessage[256];
    Format(formattedMessage, sizeof(formattedMessage), "\x01%s \x01%s", clientName, message);

    DataPack pack = new DataPack();
    pack.WriteCell(playersNum);
    for (int i = 0; i < playersNum; i++) {
        pack.WriteCell(players[i]);
    }
    pack.WriteString(formattedMessage);
    RequestFrame(Frame_SendSayText, pack);

    return Plugin_Handled; 
}

public Action Hook_SayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init) {
    int client = msg.ReadByte();
    msg.ReadByte(); 
    char format[256], message[256];
    msg.ReadString(format, sizeof(format), true);
    msg.ReadString(message, sizeof(message), true);

    if (client <= 0 || client > MaxClients || !IsClientInGame(client)) {
        return Plugin_Continue; 
    }

    char clientName[MAX_NAME_LENGTH];
    if (!GetClientInfo(client, "name", clientName, sizeof(clientName)) || !clientName[0]) {
        GetClientName(client, clientName, sizeof(clientName));
    }

    if (StrContains(format, "{1}") != -1) {
        ReplaceString(format, sizeof(format), "{1}", clientName);
    } else if (StrContains(format, "%s1") != -1) {
        ReplaceString(format, sizeof(format), "%s1", clientName);
    }

    char formattedMessage[256];
    Format(formattedMessage, sizeof(formattedMessage), "\x01%s \x01%s", format, message);

    DataPack pack = new DataPack();
    pack.WriteCell(playersNum);
    for (int i = 0; i < playersNum; i++) {
        pack.WriteCell(players[i]);
    }
    pack.WriteString(formattedMessage);
    RequestFrame(Frame_SendSayText, pack);

    return Plugin_Handled; 
}

public void Frame_SendSayText(DataPack pack) {
    pack.Reset();
    int playersNum = pack.ReadCell();
    int[] players = new int[playersNum];
    for (int i = 0; i < playersNum; i++) {
        players[i] = pack.ReadCell();
    }

    char message[256];
    pack.ReadString(message, sizeof(message));
    delete pack;

    for (int i = 0; i < playersNum; i++) {
        int target = players[i];
        if (target > 0 && target <= MaxClients && IsClientInGame(target) && !IsFakeClient(target)) {
            PrintToChat(target, message);
        }
    }
}
