#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"

static int givenPills = 0;

public Plugin:myinfo = {
    name = "T1 and Pills",
    author = "Tripa Seca",
    version = PLUGIN_VERSION
}


// Native events
public OnPluginStart() {

    // Listeners
    HookEvent("round_start", onRoundStart);

    // Commands
    RegConsoleCmd("pills", PillsCommand);

}


// Hooked events
public onRoundStart(Handle:ev, const String:name[], bool:dontBroadcast) {
    givenPills = 0;

    // Timers
    CreateTimer(1.0, ReplaceWeapons);
    CreateTimer(15.0, GivePills);
    CreateTimer(30.0, GivePills);
    CreateTimer(60.0, GivePills);

}

public Action:PillsCommand(client, args){
    //if (GetUserAdmin(client) != INVALID_ADMIN_ID) {
        CreateTimer(1.0, GivePills);
    //}
    return Plugin_Handled;
}


// Timers
public Action:GivePills(Handle timer){
    new maxplayers = MaxClients;
    for (new i = 1; i <= maxplayers; i++) {
        if (IsClientInGame(i)) {
            SetEntityRenderColor(i, 255, 255, 255, 255);
            if (GetClientTeam(i) == 2 && IsPlayerAlive(i)) {
                if (givenPills < 4){
                    new flags = GetCommandFlags("give");
                    SetCommandFlags("give", flags & ~FCVAR_CHEAT);
                    FakeClientCommand(i, "give weapon_pain_pills");
                    SetCommandFlags("give", flags|FCVAR_CHEAT);
                    givenPills++;
                }
            }
        }
    }
    return Plugin_Continue;
}


// Weapon replacement
new String:t1_shotguns[][32] = { "weapon_shotgun_chrome_spawn", "weapon_pumpshotgun_spawn" }
new String:t1_smgs[][32] = { "weapon_smg_spawn", "weapon_smg_silenced_spawn" }

public Action:ReplaceWeapons(Handle:timer) {

    new String:allowedWeapons[22][128] = {
        "weapon_ammo_spawn",
        "weapon_melee_spawn",
        "weapon_pistol",
        "weapon_pistol_spawn",
        "weapon_pistol_magnum",

        "weapon_pistol_magnum_spawn",
        "weapon_smg_spawn",
        "weapon_smg_silenced_spawn",
        "weapon_pumpshotgun_spawn",
        "weapon_shotgun_chrome_spawn",

        "weapon_ammo",
        "weapon_pain_pills_spawn",
        //"weapon_adrenaline_spawn",
        //"weapon_pipe_bomb_spawn",
        //"weapon_molotov_spawn",

        //"weapon_vomitjar_spawn",
        //"weapon_upgradepack_incendiary_spawn",
        //"weapon_upgradepack_explosive_spawn",
        "weapon_gascan",
        "weapon_gascan_spawn",

        "weapon_scavenge_item_spawn",
        "weapon_charger_claw",
        "weapon_boomer_claw",
        "weapon_smoker_claw",
        "weapon_spitter_claw",

        "weapon_hunter_claw",
        "weapon_jockey_claw",
        "weapon_tank_claw",
    };

    new String:T2[17][128] = {
        "weapon_rifle_ak47_spawn",
        "weapon_rifle_desert_spawn",
        "weapon_rifle_m60_spawn",
        "weapon_rifle_spawn",
        "weapon_hunting_rifle_spawn",
        "weapon_sniper_military_spawn",
        "weapon_grenade_launcher_spawn",
        "weapon_chainsaw_spawn",
        "weapon_rifle_ak47",
        "weapon_rifle_desert",
        "weapon_rifle_m60",
        "weapon_rifle",
        "weapon_hunting_rifle",
        "weapon_sniper_military",
        "weapon_grenade_launcher",
        "weapon_chainsaw",
        "weapon_spawn",
    }

    new String:specialWeapons[4][128] = {
        "weapon_grenade_launcher_spawn",
        "weapon_chainsaw_spawn",
        "weapon_grenade_launcher",
        "weapon_chainsaw",
    }
    
    int gunType = 1;

    for (new i = 0; i <= GetEntityCount(); i++) {
        decl String:EdictName[128];

        if(IsValidEntity(i)) {
            GetEdictClassname(i, EdictName, sizeof(EdictName));

            // if entity is a weapon
            if (StrContains(EdictName, "weapon_spawn", false) != -1 ||
                StrContains(EdictName, "weapon", false) != -1) {

                // if weapon is not allowed
                if (!inArray(EdictName, allowedWeapons, sizeof(allowedWeapons))){
                    PrintToServer("Removing weapon %s", EdictName);

                    decl Float:location[3], Float:angle[3];
                    GetEntPropVector(i, Prop_Send, "m_vecOrigin", location);
                    GetEntPropVector(i, Prop_Data, "m_angRotation", angle);
                    
                    bool isT2 = inArray(EdictName, T2, sizeof(T2));
                    bool isSpecial = inArray(EdictName, specialWeapons, sizeof(specialWeapons));

                    RemoveEdict(i);
                    
                    // if weapon is a T2 and is not special, spawn a T1
                    if (isT2 && !isSpecial){
                        new index;
                        if (gunType == 1){
                            index = CreateEntityByName(t1_shotguns[
                                GetRandomInt(0, sizeof(t1_shotguns) - 1)]);
                            gunType = 2;
                        } else {
                            index = CreateEntityByName(t1_smgs[
                                GetRandomInt(0, sizeof(t1_smgs) - 1)]);
                            gunType = 1;
                        }
                        TeleportEntity(index, location, angle, NULL_VECTOR);
                        DispatchKeyValue(index, "count", "4");
                        DispatchSpawn(index);
                        ActivateEntity(index);
                    }
                }
            }
        }
    }
    
    return Plugin_Handled;
}



// misc
public bool:inArray(String:needle[128], String:haystack[][], size){
    new bool:isInArray = false;
    for (new i = 0; i < size; i++) {
        if (StrEqual(needle, haystack[i])) {
            isInArray = true;
            break;
        }
    }
    return isInArray;
}

