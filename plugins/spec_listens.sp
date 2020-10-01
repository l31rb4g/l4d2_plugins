#include <sourcemod>
#include <sdktools>

#define VOICE_NORMAL        0   // Allow the client to listen and speak normally.
#define VOICE_MUTED         1   // Mutes the client from speaking to everyone.
#define VOICE_SPEAKALL      2   // Allow the client to speak to everyone.
#define VOICE_LISTENALL     4   // Allow the client to listen to everyone.
#define VOICE_TEAM          8   // Allow the client to always speak to team, even when dead.
#define VOICE_LISTENTEAM    16  // Allow the client to always hear teammates, including dead ones.

#define TEAM_SPEC 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name = "Spec Listens",
    author = "Tripa Seca",
    description = "Allows spectators to listen to all teams",
    version = PLUGIN_VERSION,
}

public OnPluginStart(){
    HookEvent("player_team", onPlayerChangeTeam);
}

public onPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new team = GetEventInt(event, "team");
    if (IsValidClient(client)){
        if (team == TEAM_SPEC) {
            SetClientListeningFlags(client, VOICE_LISTENALL);
        }
        else {
            SetClientListeningFlags(client, VOICE_NORMAL);
        }
    }
}


stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true) {
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client))) {
        return false;
    }
    return true;
}
