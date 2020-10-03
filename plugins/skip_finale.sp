#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.6"

public Plugin:myinfo = {
    name = "Skip Finale",
    author = "Tripa Seca",
    version = PLUGIN_VERSION
}

static bool votingEnabled = false;
static bool matchFinished = false;
static bool mapChangeEnabled = false;
static int round = 0;
static int votes[7];

new String:nextmap[30];
new String:nextmapName[30];
new String:currentMap[128];
new Handle:g_hMenu_Vote[30] = INVALID_HANDLE;

new String:voteMaps[7][30] = {
    "c2m1_highway",             // Dark Carnival
    "c5m1_waterfront",          // The Parish
    "c10m1_caves",              // Death Toll
    "c11m1_greenhouse",         // Dead Air
    "c4m1_milltown_a",          // Hard Rain
    "c1m1_hotel",               // Dead Center
    "c3m1_plankcountry"         // Swamp Fever
}

new String:voteMapNames[7][30] = {
    "Dark Carnival",
    "The Parish",
    "Death Toll",
    "Dead Air",
    "Hard Rain",
    "Dead Center",
    "Swamp Fever"
}

new String:lastMaps[12][128] = {
    "c1m4_atrium",          // Dead Center
    "c2m4_barns",           // Dark Carnival
    "c3m4_plantation",      // Swamp Fever
    "c4m4_milltown_b",      // Hard Rain
    "c5m4_quarter",         // The Parish
    "c6m3_port",            // The Passing (3rd map)
    "c7m3_port",            // The Sacrifice (3rd map)
    "c8m4_interior",        // No Mercy
    "c10m4_mainstreet",     // Deth Toll
    "c11m4_terminal",       // Dead Air
    "c12m4_barn",           // Blood Harvest
    "c13m4_cutthroatcreek", // Cold Stream
}


// Native events
public OnPluginStart() {
    HookEvent("round_start", onRoundStart);
    HookEvent("round_end", onRoundEnd);
}


public Action:onRoundStart(Handle:event, const String:name[], bool:dontbroadcast) {
    PrintToServer("=================================");
    PrintToServer(" round start %d", round);
    PrintToServer("=================================");

    GetCurrentMap(currentMap, sizeof(currentMap));

    if (inArray(currentMap, lastMaps, sizeof(lastMaps))){
        if (round > 0){
            mapChangeEnabled = true;
        }
    }
}

public Action:onRoundEnd(Handle:event, const String:name[], bool:dontbroadcast) {

    GetCurrentMap(currentMap, sizeof(currentMap));

    PrintToServer("=================================");
    PrintToServer(" round end %d", round);
    PrintToServer("=================================");

    if (mapChangeEnabled && !matchFinished){
        votingEnabled = true;
        CreateTimer(1.0, MapVote);
        CreateTimer(11.0, MapResult);
        CreateTimer(14.0, GoToNextMap);
        matchFinished = true;
    }
    
    // last chapter
    if (inArray(currentMap, lastMaps, sizeof(lastMaps))){
        round++;
    }

    CreateTimer(5.0, ShowScore);
}


public Action:ShowScore(Handle:timer){
    new Handle:gConf = INVALID_HANDLE;
    new Handle:fGetTeamScore = INVALID_HANDLE;

    gConf = LoadGameConfigFile("left4downtown.l4d2");
    StartPrepSDKCall(SDKCall_GameRules);
    if(PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "GetTeamScore")) {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
        PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
        fGetTeamScore = EndPrepSDKCall();
    }

    bool isMapEnd = inArray(currentMap, lastMaps, sizeof(lastMaps)) && round >= 2;
    new score1 = SDKCall(fGetTeamScore, 1, 1);
    new score2 = SDKCall(fGetTeamScore, 2, 1);
    new String:verb[30];

    if (score1 > score2) {
        new String:s1[1] = "";
        if (score1 - score2 > 1){
            s1 = "s";
        }
        if (isMapEnd){
            verb = "venceu";
        } else {
            verb = "está vencendo";
        }
        PrintToChatAll("\x04Time 1 \x01%s por \x03%d\x01 ponto%s.", verb, score1 - score2, s1);
    }

    else if (score2 > score1) {
        new String:s2[1] = "";
        if (score2 - score1 > 1){
            s2 = "s";
        }
        if (isMapEnd){
            verb = "venceu";
        } else {
            verb = "está vencendo";
        }
        PrintToChatAll("\x04Time 2 \x01%s por \x03%d\x01 ponto%s.", verb, score2 - score1, s2);
    }

    else {
        if (isMapEnd){
            verb = "empatou";
        } else {
            verb = "está empatado";
        }
        PrintToChatAll("\x01O jogo \x04%s\x01! Os dois time têm \x03%d\x01 pontos!", score1);
    }
}


// Voting
public Action:MapVote(Handle:timer) {
    PrintToChatAll("\x04[votação]\x01 Iniciando votação para o próximo mapa...");

    for (new i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            VoteMenuDraw(i);
        }
    }
}

public Action:VoteMenuDraw(client) {
    if(client < 1 || IsClientInGame(client) == false || IsFakeClient(client) == true){
        return Plugin_Handled;
    }

    g_hMenu_Vote[client] = CreateMenu(VoteMenuHandler);
    SetMenuTitle(g_hMenu_Vote[client], "Vote no próximo mapa\n ");

    AddMenuItem(g_hMenu_Vote[client], "option1", voteMapNames[0]);
    AddMenuItem(g_hMenu_Vote[client], "option2", voteMapNames[1]);
    AddMenuItem(g_hMenu_Vote[client], "option3", voteMapNames[2]);
    AddMenuItem(g_hMenu_Vote[client], "option4", voteMapNames[3]);
    AddMenuItem(g_hMenu_Vote[client], "option5", voteMapNames[4]);
    AddMenuItem(g_hMenu_Vote[client], "option6", voteMapNames[5]);
    AddMenuItem(g_hMenu_Vote[client], "option7", voteMapNames[6]);

    SetMenuExitButton(g_hMenu_Vote[client], true);
    DisplayMenu(g_hMenu_Vote[client], client, MENU_TIME_FOREVER);

    //EmitSoundToClient(client, SOUND_NEW_VOTE_START);

    return Plugin_Handled;
}

public VoteMenuHandler(Handle:hMenu, MenuAction:maAction, client, itemNum){
    if (itemNum > -1){
        if (votingEnabled){
            PrintToChat(client, "\x04[votação]\x01 Você votou no mapa \x03%s\x01.", voteMapNames[itemNum]);
            votes[itemNum]++;
        } else {
            PrintToChat(client, "\x04[votação]\x01 A votação está encerrada.", voteMapNames[itemNum]);
        }
    }
}

public Action:MapResult(Handle:timer){
    int maxValue = 0;
    int maxIndex = 0;
    votingEnabled = false;

    for (int i=0; i<7; i++){
        PrintToConsoleAll("%s: %d", voteMaps[i], votes[i]);
        if (votes[i] >= maxValue){
            maxValue = votes[i];
            maxIndex = i;
        }
    }
    
    if (maxValue == 0){
        maxIndex = 0;
    }

    new String:_s[1] = "";
    if (maxValue != 1){
        _s = "s";
    }

    PrintToChatAll("\x04[votação]\x01 O mapa \x03%s\x01 foi escolhido com \x04%d\x01 voto%s.",
        voteMapNames[maxIndex], maxValue, _s);
    
    nextmap = voteMaps[maxIndex];
    nextmapName = voteMapNames[maxIndex];
}

public Action:GoToNextMap(Handle:timer){
    round = 0;
    votingEnabled = false;
    matchFinished = false;
    mapChangeEnabled = false;
    ServerCommand("changelevel %s", nextmap);
}


// misc
public bool:inArray(String:needle[128], String:haystack[][], sizeof_haystack){
    new bool:isInArray = false;
    for (new i = 0; i < sizeof_haystack; i++) {
        if (StrEqual(needle, haystack[i])) {
            isInArray = true;
            break;
        }
    }
    return isInArray;
}

stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true) {
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client))) {
        return false;
    }
    return true;
}
