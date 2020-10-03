#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

static TEAM_SPEC = 1;
//static TEAM_SURVIVOR = 2;
//static TEAM_INFECTED = 3;

public Plugin:myinfo = {
    name = "Simple Spec",
    author = "Tripa Seca",
    version = PLUGIN_VERSION
}

// Native events
public OnPluginStart() {
    RegConsoleCmd("spec", GoSpec);
}

public Action:GoSpec(client, args) {
    if (IsClientInGame(client)) {
        ChangeClientTeam(client, TEAM_SPEC);
    }
    return Plugin_Handled;
}

