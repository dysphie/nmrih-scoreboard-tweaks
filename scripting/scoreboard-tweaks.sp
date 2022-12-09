#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name        = "Scoreboard Tweaks",
    author      = "Dysphie",
    description = "Remembers scores for reconnecting players and resets them on a new round",
    version     = "1.0.0",
    url         = ""
};

ConVar svKillOnDisconnect;

enum struct Score
{
	int kills;
	int deaths;
}

StringMap g_ScoreBackup;

public void OnPluginStart()
{
	svKillOnDisconnect = FindConVar("sv_kill_player_on_disconnect");

	g_ScoreBackup = new StringMap();
	HookEvent("nmrih_reset_map", OnMapReset, EventHookMode_Pre);
}

public void OnMapEnd()
{
	g_ScoreBackup.Clear();
}

public void OnMapStart()
{
	g_ScoreBackup.Clear();
}

Action OnMapReset(Event event, const char[] name, bool dontBroadcast)
{
	g_ScoreBackup.Clear();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			SetClientDeaths(client, 0);
			SetClientFrags(client, 0);
		}
	}
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if (!IsClientInGame(client))
		return;

	char steamId[MAX_AUTHID_LENGTH];
	if (GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)))
	{
		Score score;
		score.kills = GetClientFrags(client);
		score.deaths = GetClientDeaths(client);

		if (IsPlayerAlive(client) && svKillOnDisconnect.BoolValue) 
		{
			// The server will kill them, but we are early, so manually add to the death count
			score.deaths++;
		}

		g_ScoreBackup.SetArray(steamId, score, sizeof(score));
	}
}

#define STATE_ROUND_ONGOING 3

public void OnClientPostAdminCheck(int client)
{
	if (GameRules_GetProp("_roundState") != STATE_ROUND_ONGOING) {
		return;
	}

	char steamId[MAX_AUTHID_LENGTH];
	if (GetClientAuthId(client, AuthId_SteamID64, steamId, sizeof(steamId)))
	{
		Score score;
		g_ScoreBackup.GetArray(steamId, score, sizeof(score));

		SetClientFrags(client, score.kills + GetClientFrags(client));
		SetClientDeaths(client, score.deaths + GetClientDeaths(client));
	}
}

void SetClientFrags(int client, int frags)
{
	SetEntProp(client, Prop_Data, "m_iFrags", frags);
}

void SetClientDeaths(int client, int deaths)
{
	SetEntProp(client, Prop_Data, "m_iDeaths", deaths);
}