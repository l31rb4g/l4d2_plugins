#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"

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
        ChangeClientTeam(client, 1);
    }
    return Plugin_Handled;
}
