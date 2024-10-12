#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define VERSION "1.0"

bool chainmode = false; //used for spy shuffling
bool ban_primary[MAXPLAYERS+1] = false;
bool ban_secondary[MAXPLAYERS+1] = false;
bool ban_melee[MAXPLAYERS+1] = false;
bool SapTime[MAXPLAYERS+1] = false;
ConVar g_debugSpy;
ConVar g_Spy;
int MVM = 0;

public Plugin myinfo = {
	name = "Advanced Spy bots",
	author = "New edits by Lovetaste. Base by the creators/helpers of Bot Overhaul Mod",
	description = "Spy bots have been changed to be more advanced.",
	version= "1.0",
};		

public void OnPluginStart()
{
	g_debugSpy = CreateConVar("sm_ai_spy_debug", "0", "Turns on Spy console printing. WARNING: WILL CLUTTER CONSOLE. Default = 0.", _, true, 0.0, true, 1.0);
	g_Spy = CreateConVar("sm_ai_spy_enabled", "1", "Turns on Spy bot edits. Default = 1.", _, true, 0.0, true, 1.0);
}

public void OnMapStart()
{
	if (GetConVarInt(FindConVar("tf_gamemode_mvm")) == 1)
	{
		MVM = 1;
	}
	else
	{		
		MVM = 0;	
	}
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

float moveBackwards(float vel[3],float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

float moveSide(float vel[3],float MaxSpeed)
{
	vel[1] = MaxSpeed;
	return vel;
}

float moveSide2(float vel[3],float MaxSpeed)
{
	vel[1] = -MaxSpeed;
	return vel;
}

stock void TF2_SwitchtoSlot(int client, int slot)
{
 if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
 {
  char playername[32];
  GetClientName(client, playername, sizeof(playername));
  int wep = GetPlayerWeaponSlot(client, slot);
  if (wep > MaxClients && IsValidEdict(wep))
  {
	// Showin added a new way to force weapon switching!
	// We temporarily unrestrict this command to force a change and use the weapon switch blocker to force it. 
	int flags = GetCommandFlags( "cc_bot_selectweapon" );
	SetCommandFlags( "cc_bot_selectweapon", flags & ~FCVAR_CHEAT ); 
	FakeClientCommand(client, "cc_bot_selectweapon \"%s\" %i", playername, slot);
	SetCommandFlags( "cc_bot_selectweapon", flags|FCVAR_CHEAT);
  }
 }
} 

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3]) // Stock By Pelipokia
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    newmove[1] = -newmove[1];
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

stock bool TF2_IsNextToWall(int client) // Stock By Pelipokia
{
	float flPos[3];
	GetClientAbsOrigin(client, flPos);
	
	float flMaxs[3], flMins[3];
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", flMaxs);
	GetEntPropVector(client, Prop_Send, "m_vecMins", flMins);
	
	flMaxs[0] += 2.5;
	flMaxs[1] += 2.5;
	flMins[0] -= 2.5;
	flMins[1] -= 2.5;
	
	flPos[2] += 18.0;
	
	//Perform a wall check to see if we are near any obstacles we should try jump over
	Handle TraceRay = TR_TraceHullFilterEx(flPos, flPos, flMins, flMaxs, MASK_PLAYERSOLID, ExcludeFilter, client);
	
	bool bHit = TR_DidHit(TraceRay);
	
	if(bHit)
	{}
	else
	{}
	
	delete TraceRay;
	
	return bHit;
}

public bool ExcludeFilter(int entity, int contentsMask, any iExclude)
{
    return !(entity == iExclude);
}

public void OnClientPutInServer(int client) 
{
//SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);

/* if(!IsFakeClient(client))
{
	realplayercount++;
} */
}

public int GetNearestEntity(int client, char[] classnametarget)
{	
	char ClassName[32];	
	float clientOrigin[3];	
	float entityOrigin[3];	
	float distance = -1.0;	
	int nearestEntity = -1;	
	
	for(int x = 0; x <= GetMaxEntities(); x++)	
	{		
		if(IsValidEdict(x) && IsValidEntity(x))		
		{			
			GetEdictClassname(x, ClassName, 32);								
			if(StrContains(ClassName, classnametarget, false) != -1)			
			{				
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);				
				GetClientEyePosition(client, clientOrigin);								
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);				
				if((edict_distance < distance) || (distance == -1.0))				
				{					
					distance = edict_distance;					
					nearestEntity = x;				
				}			
			}		
		}	
	}	
	
	return nearestEntity;
}

public int FindNearestHealth(int client)
{	
	char ClassName[32];	
	float clientOrigin[3];	
	float entityOrigin[3];	
	float distance = -1.0;	
	int nearestEntity = -1;	
	
	for(int x = 0; x <= GetMaxEntities(); x++)	
	{		
		if(IsValidEdict(x) && IsValidEntity(x))		
		{			
			GetEdictClassname(x, ClassName, 32);						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && !HasEntProp(x, Prop_Send, "m_fEffects"))				
				continue;						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && GetEntProp(x, Prop_Send, "m_fEffects") != 0)				
				continue;						
			if(StrContains(ClassName, "item_health", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1 || StrContains(ClassName, "rd_robot_dispenser", false) != -1 || StrContains(ClassName, "pd_dispenser", false) != -1)			
			{				
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);				
				GetClientEyePosition(client, clientOrigin);								
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);				
				if((edict_distance < distance) || (distance == -1.0))				
				{					
					distance = edict_distance;					
					nearestEntity = x;				
				}			
			}		
		}	
	}	
	
	return nearestEntity;
}

public int FindNearestAmmo(int client)
{	
	char ClassName[32];	
	float clientOrigin[3];	
	float entityOrigin[3];	
	float distance = -1.0;	
	int nearestEntity = -1;	
	
	for(int x = 0; x <= GetMaxEntities(); x++)	
	{		
		if(IsValidEdict(x) && IsValidEntity(x))		
		{			
			GetEdictClassname(x, ClassName, 32);						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && !HasEntProp(x, Prop_Send, "m_fEffects"))				
				continue;						
			if(StrContains(ClassName, "prop_dynamic", false) == -1 && GetEntProp(x, Prop_Send, "m_fEffects") != 0)				
				continue;						
			if(StrContains(ClassName, "item_ammopack", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1 || StrContains(ClassName, "rd_robot_dispenser", false) != -1 || StrContains(ClassName, "pd_dispenser", false) != -1)			
			{				
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);				
				GetClientEyePosition(client, clientOrigin);								
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);				
				if((edict_distance < distance) || (distance == -1.0))				
				{					
					distance = edict_distance;					
					nearestEntity = x;				
				}			
			}		
		}	
	}	
	
	return nearestEntity;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{	
	TR_TraceRayFilterEx(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() == 1.0;
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(IsValidClient(client) && IsFakeClient(client))
	{
		TFClassType class = TF2_GetPlayerClass(client);
		/* if (g_Spy.IntValue > 0)
		{
			//IDK If this actually does anything important
			for(int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || (i == client) || IsFakeClient(i) || !IsFakeClient(client))
				{
					continue;
				}
			}
		} */
		if(class == TFClass_Spy)
		{
			if(g_Spy.IntValue > 0 && IsFakeClient(client) && IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_CritOnWin) && GetEntProp(client, Prop_Send, "m_iStunFlags") != TF_STUNFLAGS_LOSERSTATE)
			{
				// Force Bots to auto ready in MVM!
				//if(MVM == 1 && GetClientTeam(client) == 2)
				//{
				//	FakeClientCommand(client, "tournament_player_readystate 1");
				//}
			
				// Make bots work better in water.
				int WaterDepth = GetEntProp(client, Prop_Data, "m_nWaterLevel");
				if(WaterDepth >= 2)
				{
					buttons |= IN_JUMP;
				}
				
				// Make bots crouch jump.
				if(GetClientButtons(client) & IN_JUMP)
				{
					if(!(GetEntityFlags(client) & FL_ONGROUND))
					{
						//PrintToConsoleAll("DUCK!");
						buttons |= IN_DUCK;
					}
				}
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				int d = GetPlayerWeaponSlot(client, 2);
				if(GetHealth(client) < (MaxHealth / 1.25) && !(356 == GetEntProp(d, Prop_Send, "m_iItemDefinitionIndex") && GetHealth(client) > 65))
				{
					//int healthkit = GetNearestEntity(client, "item_healthkit_*"); 
					int healthkit = FindNearestHealth(client);
					
					if(healthkit != -1)
					{
						if(IsValidEntity(healthkit))
						{
							if (GetEntProp(healthkit, Prop_Send, "m_fEffects") != 0)
							{
								return Plugin_Continue;
							}
							
							float clientOrigin[3];
							float healthkitorigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(healthkit, Prop_Send, "m_vecOrigin", healthkitorigin);
							
							clientOrigin[2] += 5.0;
							healthkitorigin[2] += 5.0;
							
							float chainDistance;
							chainDistance = GetVectorDistance(clientOrigin, healthkitorigin);
							
							if(chainDistance < 350 && IsPointVisible(clientOrigin, healthkitorigin) && healthkitorigin[2] < clientOrigin[2] + 50)
							{
								TF2_MoveTo(client, healthkitorigin, vel, angles);
							}

						}
					}
				}
				int ammoOffset = FindSendPropInfo("CTFPlayer", "m_iAmmo");
				int size = GetEntData(client, ammoOffset + 4, 4);
				if(size < 13)
				{
					//int ammokit = GetNearestEntity(client, "item_ammopack_*"); 		
					int ammokit = FindNearestAmmo(client);
						
					if(ammokit != -1)
					{
						if(IsValidEntity(ammokit))
						{
							if (GetEntProp(ammokit, Prop_Send, "m_fEffects") != 0)
							{
								return Plugin_Continue;
							}
				
							float clientOrigin[3];
							float ammokitorigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(ammokit, Prop_Send, "m_vecOrigin", ammokitorigin);
							
							clientOrigin[2] += 5.0;
							ammokitorigin[2] += 5.0;
							
							float chainDistance;
							chainDistance = GetVectorDistance(clientOrigin, ammokitorigin);
							
							if(chainDistance < 350 && IsPointVisible(clientOrigin, ammokitorigin) && ammokitorigin[2] < clientOrigin[2] + 50)
							{
								TF2_MoveTo(client, ammokitorigin, vel, angles);
							}
						}
					}
				}
				float clientEyes[3];
				GetClientEyePosition(client, clientEyes);
				int Ent = Client_GetClosest(clientEyes, client);
				if(IsValidEntity(Ent))
				{
				TFClassType otherclass = TF2_GetPlayerClass(Ent);
				}
				int nearbyRocket = FindEntityByClassname(-1, "tf_projectile_rocket"); //this makes the bot jump when a rocket is near.
				if(nearbyRocket != -1)
				{
					float clientOrigin[3];
					float rocketOrigin[3];
					GetClientAbsOrigin(client, clientOrigin);
					GetEntPropVector(nearbyRocket, Prop_Send, "m_vecOrigin", rocketOrigin);
					//clientOrigin[2] += 5.0;
					//rocketOrigin[2] += 5.0;
							
					float surfDistance;
					surfDistance = GetVectorDistance(clientOrigin, rocketOrigin);
					if(surfDistance < 75 && (GetHealth(client) > 70))
					{
						if(TF2_IsPlayerInCondition(client, TFCond_Disguised)) //this will make the spy undisguise, allowing the spy to take knockback
						{
						TF2_RemoveCondition(client,TFCond_Disguised);
						}
						
						//PrintToConsoleAll("ATTEMPTING TO SURF ROCKET!");
						buttons |= IN_JUMP;
					}
				}
				
				
				
				
				
				
				
				if(!(GetEntityFlags(client) & FL_ONGROUND))
				{
					if(buttons & IN_FORWARD)
					{
						buttons &= ~IN_FORWARD;
					}
					if(buttons & IN_BACK)
					{
						buttons &= ~IN_BACK;
					}
				} 
				/* 
				this SHOULD remove the forward and back buttons when the bot is midair to make sure the bot's velocity isn't limited midair. The only real problem with this is that the bot does not know how to airstrafe properly. That means that when going for things like a jumpstab, if the target moves to the side it will fail a large amount of the time, even if the target moves a small amount. This COULD be prevented if the bot knew how to airstrafe onto the target's head, but as for now this has not been implemented due to my LACK OF KNOWLEDGE!!!!
				
				
				IDEAS ON HOW TO IMPLEMENT BOT AIRSTRAFING TO DESTINATION CORRECTLY:
				The equation for the minimum angle required to gain as much speed as possible while airstrafing is:
				L - |t*a| >= |v|cos(θ)
				θ >= acos((L - |t*a|)/|v|)
				
				An idea on how to implement this is for the bot to find an available target when midair (THIS PART WOULD BE OUTSIDE OF PLAYERCMD FUNCTION SO THAT THE BOT KEEPS THE SAME TARGET THROUGHOUT IT'S TIME MIDAIR), find the origin location, and determine whether or not it needs to airstrafe to the left or the right by using the array and comparing it to its own.
				
				I'd assume that it wouldn't be THAT hard, just use the X and Y coords of the target and compare it to its own.
				
				Then, afterwards, it would change its view angles based on the equation, and use it's velocity to see the range in which it will fly. If it will hit a target, it will strafe to them.
				
				
				
				This was what the equation IN CODE looked like in the Bunnyhopping From A Programmer's Perspective article.
				private Vector3 Accelerate(Vector3 accelDir, Vector3 prevVelocity, float accelerate, float max_velocity)
				{
					float projVel = Vector3.Dot(prevVelocity, accelDir); // Vector projection of Current velocity onto accelDir.
					float accelVel = accelerate * Time.fixedDeltaTime; // Accelerated velocity in direction of movment

					// If necessary, truncate the accelerated velocity so the vector projection does not exceed max_velocity
					if(projVel + accelVel > max_velocity)
						accelVel = max_velocity - projVel;

					return prevVelocity + accelDir * accelVel;
				}
				
				I'm not sure if this could just be copy and pasted into sourcemod, but as for now I plan on using this as a basis for airstrafing logic.
				
				
				
				
				|v|cos(180) = -v < L is the equation for stopping, and may be used for surf logic. The idea is if the bot realizes that it is going to overshoot it's target, then it will apply this logic to itself in order to stab their target. However, I'm not sure if i even NEED this logic, due to the bot's perfect aim. The bot can't overshoot if it just stabs the player when it gets there! Plus, the TF2_MoveTo function should force the bot to press forward in the opposite direction the moment it gets past the target, allowing for a quick slowdown and stab.
				The TF2_MoveTo is a confusing function, because I am not sure if it actually makes the bot airstrafe to their target or if it just manipulates their velocity to the left/right as if they are moving forward. I guess it doesnt matter, as long as the velocity is going to the side.
				I could probably just use the moveSide and moveSide2 function.
				
				
				
				*/
				






















			
				
				
				
				
				
				
				
				if(g_Spy.IntValue == 1)
				{
					// Get watch and knife type.
					int watch = GetPlayerWeaponSlot(client, 4);
					int knife = GetPlayerWeaponSlot(client, 2); 
					
					int nearbyPipe = FindEntityByClassname(-1, "tf_projectile_pipe"); //If the spy is above 100 hp, it will try to surf. Otherwise, it won't. If it has the Dead Ringer, it will take it out if it can.
					if(nearbyPipe != -1)
					{
						float clientOrigin[3];
						float pipeOrigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						GetEntPropVector(nearbyPipe, Prop_Send, "m_vecOrigin", pipeOrigin);
			
						float pipeDistance;
						pipeDistance = GetVectorDistance(clientOrigin, pipeOrigin);
						if(pipeDistance < 110)
						{
							if(GetHealth(client) >= 100)
							{
								if(TF2_IsPlayerInCondition(client, TFCond_Disguised)) //this will make the spy undisguise, allowing the spy to take knockback
								{
								TF2_RemoveCondition(client,TFCond_Disguised);
								}
								
								//PrintToConsoleAll("ATTEMPTING TO SURF ROCKET!");
								buttons |= IN_JUMP;
							}
							else
							{
								// Make dead ringer spies take their dead ringer out.
								if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 0)
								{
									buttons |= IN_ATTACK2;
								}
							}
						
						}
					}
					
					
					
					
					
					
					
					
					
					// Make spys always backstab if they can!
					if(IsWeaponSlotActive(client, 2) && GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab"))
					{
						buttons |= IN_ATTACK;
					}
					
					if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) //this should make the spy decloak only when the target isnt looking, to make the bot more proactive
					{
						if (IsTargetInSightRange(Ent, client))		
						{
							if(buttons & IN_ATTACK2)
							{
								buttons &= ~IN_ATTACK2;
							}
						}
						else
						{
						buttons |= IN_ATTACK2;
						}
					}
					
					

					// Make spy bots always sap enemy buildings!
					int EnemyBuilding = GetNearestEntity(client, "obj_sentrygun");
					if(EnemyBuilding != -1)
					{
						if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
						{
							float clientOrigin[3];
							float enemysentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
					
							clientOrigin[2] += 50.0;

							float camangle[3];
							float fEntityLocation[3];
							float vec[3];
							float angle[3];
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 35.0;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);
						
							int iBuildingIsSapped = GetEntProp(EnemyBuilding, Prop_Send, "m_bHasSapper");
							//int iBuildingHealth = GetEntProp(EnemyBuilding, Prop_Send, "m_iHealth");
							int IBuildingBuilded = GetEntProp(EnemyBuilding, Prop_Send, "m_iState");
							//PrintToConsoleAll("Building Mode : %i", IBuildingBuilded);
							if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 250.0 && IBuildingBuilded != 0 && iBuildingIsSapped == 0 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && enemysentryOrigin[2] < clientOrigin[2] + 50)
							{
								SapTime[client] = true;
								ban_secondary[client] = true;
								TF2_SwitchtoSlot(client, TFWeaponSlot_Secondary); 
								FakeClientCommand(client, "build 3 0");
								
								TF2_LookAtPos(client, enemysentryOrigin, 0.08);
								TF2_MoveTo(client, enemysentryOrigin, vel, angles);
								//	PrintToConsoleAll("SAP TIME!");
								if(IsWeaponSlotActive(client, 1))
								{
									buttons |= IN_ATTACK;
								//	PrintToConsoleAll("SAP SPAM!");
								}
								// If the spy is near it but still has yet to sap (due to bugs) then sap it automatically.
								if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 250.0 && iBuildingIsSapped == 0)
								{
									iBuildingIsSapped = 1;
								//	PrintToConsoleAll("FORCE SAP!");
								}
								
								// Make dead ringer spies put it away for the sap!
								if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
								{
									buttons |= IN_ATTACK2;
								}
								
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToConsoleAll("JUMP!");
									buttons |= IN_JUMP;
								}
							}
							else if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 1000.0 && IBuildingBuilded != 0 && iBuildingIsSapped == 0)
							{
								SapTime[client] = true;
								ban_secondary[client] = false;
							}
							else
							{
								SapTime[client] = false;
								ban_secondary[client] = false;
							}
						}
						else
						{
							SapTime[client] = false;
							ban_secondary[client] = false;
						}
					}
					else
					{
						SapTime[client] = false;
						ban_secondary[client] = false;
					}
					if(TF2_IsPlayerInCondition(client, TFCond_OnFire) && 649 == GetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex") && IsValidEntity(knife)) //this makes the spy take out the Spycicle if the bot is on fire
					{
						ban_melee[client] = true;
						TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
					}
					else
					{
						ban_melee[client] = false;
					}

					// Make spys always go for the stab!
					if(IsValidClient(Ent) && !SapTime[client] && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{	
						float EntVel[3];
						GetEntPropVector(Ent, Prop_Data, "m_vecVelocity", EntVel);
						float clientVel[3];
						GetEntPropVector(client, Prop_Data, "m_vecVelocity", clientVel);
						float clientCurrentVel = clientVel[0]; //for shuffling
						
						TFClassType otherclass = TF2_GetPlayerClass(Ent);
						float clientOrigin[3];
						float searchOrigin[3];
						float searchOriginView[3];
						float searchOriginVel[3];
						float searchOriginVelView[3];
						float clientOriginVel[3];
						GetClientAbsOrigin(Ent, searchOrigin);
						GetClientAbsOrigin(Ent, searchOriginVel);
						GetClientAbsOrigin(Ent, searchOriginView);
						GetClientAbsOrigin(Ent, searchOriginVelView);
						GetClientAbsOrigin(client, clientOrigin);
						GetClientAbsOrigin(client, clientOriginVel);
						
						//the searchOriginView and searchOriginVelView are not QoL changes for spectators of Spy bots. They raise the Y value so that the bots target near the center of the back, instead of the bottom of the model
						searchOriginView[2] += 55;
						searchOriginVel[0] += EntVel[0];
						searchOriginVel[1] += EntVel[1];
						searchOriginVel[2] += EntVel[2];	
						searchOriginVelView[0] += EntVel[0];
						searchOriginVelView[1] += EntVel[1];
						searchOriginVelView[2] += 55;
						searchOriginVelView[2] += EntVel[2];	
						clientOriginVel[0] += clientVel[0];
						clientOriginVel[1] += clientVel[1];
						clientOriginVel[2] += clientVel[2];
						
					//	float clientAngles[3];
					//	float searchAngles[3];
					//	GetClientAbsAngles(Ent, searchAngles);
					//	GetClientAbsAngles(client, clientAngles);
					//	float chainAngles;
					//	chainAngles = GetVectorAngles(clientAngles, searchAngles);
					//	PrintToConsoleAll("angles", chainAngles);
						
						
						float chainDistance;
						float chainDistanceVel;
						chainDistance = GetVectorDistance(clientOrigin, searchOrigin);
						chainDistanceVel = GetVectorDistance(clientOrigin, searchOriginVel);
						float flBotAng[3], flTargetAng[3];
						GetClientEyeAngles(client, flBotAng);
						GetClientEyeAngles(Ent, flTargetAng);
						int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);
						
						
						// float camangle[3], float clientEyes[3], float fEntityLocation[3];
						GetClientEyePosition(Ent, clientEyes);
						
						
						
						// Make them fire their weapon if this is a panic situation!
						// Otherwise keep it on the down low.
						//if (IsTargetInSightRange(client, Ent) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsWeaponSlotActive(client, 0) && otherclass != TFClass_Spy)
						//{
							//if the spy is looking at the target and undisguised, while having his gun out
						//	TF2_LookAtPos(client, searchOrigin, 0.08);
						//	buttons |= IN_ATTACK;
						//}
						//else 
						//if (IsTargetInSightRange(Ent, client) && IsTargetInSightRange(client, Ent) && TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetHealth(client) < (MaxHealth / 1.25) && IsWeaponSlotActive(client, 0) && otherclass != TFClass_Spy)
						//{
							//if the spy and the target are looking at each other, the spy is disguised and low health, and the spy has his gun out
						//	TF2_LookAtPos(client, searchOrigin, 0.08);
						//	buttons |= IN_ATTACK;
						//}
						//else if (IsWeaponSlotActive(client, 0)) //&& otherclass != TFClass_Spy)
						//{
						//	buttons &= ~IN_ATTACK;
						//}
						
						//IsPointVisible(clientOrigin, searchOrigin)
						 //&& chainDistance < 1000
						 // && 
						if (IsTargetInSightRange(client, Ent)) //otherclass != TFClass_Pyro (disabled so the spy would actually try and kill enemy Pyros instead of being a pussy). I readded the distance check to prevent Spies from bumping into walls due to locking onto far away targets through walls. I DONT KNOW WHY THE WALL DETECTION ISNT WORKING WELL :(((( if anyone can fix plz tell meeeeee
						{
							if(IsTargetInSightRange(client, Ent))
							{
								//if(g_debugSpy.IntValue == 1)
								//{
								//PrintToConsoleAll("Targeting.");
								//}
							} 
							if(!IsTargetInSightRange(Ent, client) && IsTargetInSightRange(client, Ent) && (searchOriginVel[2] < clientOrigin[2] + 115 || searchOriginVel[2] < clientOriginVel[2] + 115 || searchOrigin[2] < clientOrigin[2] + 115)) //not in enemy crosshair view & enemy either will be or is already on equal ground or the spy
							{
								//if(g_debugSpy.IntValue == 1)
								//{
								//PrintToConsoleAll("Not in view of target!");
								//}
								TF2_LookAtPos(client, searchOriginView, 0.64);
								ban_melee[client] = true;
								ban_primary[client] = false;
								TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
								if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
								{
									buttons |= IN_ATTACK2;
								}
								else
								{
									// Spy bots should stay dedicated to the fight at this point.
								// Normally they would shoot once and instantly cloak.
									if(buttons & IN_ATTACK2)
									{
										buttons &= ~IN_ATTACK2;
									}
								}
								if(chainDistance < 150.0)
								{
									moveForward(vel,320.0);
									//if(g_debugSpy.IntValue == 1)
									//{
									//PrintToConsoleAll("Aligning for a backstab!");
								//	}
									if(iAngleDiff > 0)
									{
										//Move right
										moveSide(vel,400.0);
									}
									else if(iAngleDiff < 0)
									{
										//Move left
										moveSide2(vel,400.0);
									}
								}
								else
								{
									TF2_MoveTo(client, searchOrigin, vel, angles);
								}
								/* // Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToConsoleAll("JUMP!");
									buttons |= IN_JUMP;
								} */
							}
							else if(IsTargetInSightRange(Ent, client) && IsTargetInSightRange(client, Ent)) //in enemy view
							{
								//if(g_debugSpy.IntValue == 1)
								//{
								//PrintToConsoleAll("In view of target!");
								//}
								if((searchOrigin[2] <= clientOrigin[2] - 95) || (searchOriginVel[2] <= clientOrigin[2] - 95)) // if the spy is or will be above the enemy for a jumpstab
								{ 
									if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
									{
										buttons |= IN_ATTACK2;
									}
									else
									{
									// Spy bots should stay dedicated to the fight at this point.
									// Normally they would shoot once and instantly cloak.
										if(buttons & IN_ATTACK2)
										{
											buttons &= ~IN_ATTACK2;
										}
									}
									if(chainDistanceVel <= 500.0 || chainDistance <= 440.0) // if the enemy is or will be in range for a jumpstab

									{
										ban_melee[client] = true;
										ban_primary[client] = false;
										TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
										//if(g_debugSpy.IntValue == 1)
										//{
										//PrintToConsoleAll("Attempting to jumpstab!");
										//}
										if(GetEntityFlags(client) & FL_ONGROUND)
										{
											buttons |= IN_JUMP;
											TF2_LookAtPos(client, searchOriginView, 0.05);
										}
										TF2_LookAtPos(client, searchOriginView, 0.15);
										TF2_MoveTo(client, searchOrigin, vel, angles);
									}
									else
									{
										//if(g_debugSpy.IntValue == 1)
										//{
										//PrintToConsoleAll("High enough for jumpstab but enemy vel won't connect!");
										//}
										//moveForward(vel,320.0);
									}
								}
								else
								{
									if(IsValidEntity(knife) && ((GetHealth(client) > 45 && otherclass == TFClass_Spy) || (GetHealth(client) > 65 && otherclass != TFClass_Spy) || 356 == GetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex") || 461 == GetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex")))// IF the bot has a knife AND it is either above 45hp against a Spy, above 65hp against a non-Spy, has a kunai, or has a big earner, THEN it will proceed.
									{
										/* if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && chainDistance <= 100.0) //this prevents the spy from disguising while trying to chain. if this is removed, the spy bot will constantly try to redisguise, which is incredibly annoying. This shouldn't make the bot die to sentries a lot, due to the stabbing requiring SapTime to be false.
										{
										TF2_RemoveCondition(client,TFCond_Disguising);
										TF2_RemoveCondition(client,TFCond_Disguised);
										TF2_RemovePlayerDisguise(client);
										} */
										
										ban_melee[client] = true;
										ban_primary[client] = false;
										TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);

										//if(chainDistance > 50.0)
										//{
										////	moveForward(vel,320.0); (simple movement, i removed this in favor of the random shuffling so that the spy looks like its actually trying to trickstab you instead of just running at you)
										//}
										if(chainDistance > 50.0) 
										{
											TF2_LookAtPos(client, searchOriginVelView,0.06);
											moveForward(vel,320.0);
											if(GetRandomInt(0,100) <= 20 || clientCurrentVel >= 319)
											{
												if(chainmode)
												{
													chainmode = false;
												}
												else
												{
													chainmode = true;
												}
												
											}	//it changes the spy shuffle direction when the current X velocity reaches 319, or with a 20% chance to ignore that and switch anyway. The random chance is added so the spy doesn't move perfectly, allowing for more confusion on the enemy and more tricking
											if(chainmode)
											{
												moveSide(vel, 400);
											}
											else
											{												
												moveSide2(vel, 400);
											}
										
										}
										else
										{
											TF2_LookAtPos(client, searchOriginView, 0.5);
										// Thanks to Pelipoika for this part.
										//float flBotAng[3], flTargetAng[3];
										//GetClientEyeAngles(client, flBotAng);
										//GetClientEyeAngles(Ent, flTargetAng);
										//int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);
											//PrintToConsoleAll("Circlestrafing");
											if(iAngleDiff > 0)
											{
												//Move right
												moveSide(vel,320.0);
											}
											else if(iAngleDiff < 0)
											{
												//Move left
												moveSide2(vel,320.0);
											}
										}

										//buttons |= IN_ATTACK;
									
										
										//PrintToConsoleAll("DEADRING: %i", GetEntProp(client, Prop_Send, "m_bFeignDeathReady"));
										
										// Make dead ringer spies put it away for the stab!
										if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
										{
											buttons |= IN_ATTACK2;
										}
										else
										{
											// Spy bots should stay dedicated to the fight at this point.
											// Normally they would shoot once and instantly cloak.
											if(buttons & IN_ATTACK2)
											{
												buttons &= ~IN_ATTACK2;
											}
										}
									}		
									else
									{
										if(chainDistance < 150)
										{
										moveBackwards(vel, 320);
										}
										//TF2_MoveTo(client, searchOrigin, vel, angles);	
										ban_melee[client] = false;
										ban_primary[client] = true;
										TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
											
										//PrintToConsoleAll("DEADRING: %i", GetEntProp(client, Prop_Send, "m_bFeignDeathReady"));
										
										// Make dead ringer spies take their dead ringer out.
										if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 0)
										{
											buttons |= IN_ATTACK2;
										}		
										
										/* // Make sure bot doesn't get stuck when trying to run.
										if(TF2_IsNextToWall(client))
										{
											//PrintToConsoleAll("JUMP!");
											buttons |= IN_JUMP;
										} */
									}
								}
							
							}
							else if(IsTargetInSightRange(client, Ent))//enemy is not on equal ground but spy can still see them
							{
								TF2_LookAtPos(client, searchOrigin, 0.08);
								ban_melee[client] = false;
								ban_primary[client] = true;
								TF2_SwitchtoSlot(client, TFWeaponSlot_Primary);
								if(IsWeaponSlotActive(client, 1))
								{
								buttons |= IN_ATTACK;
								}
								else
								{
									if(buttons & IN_ATTACK)
									{
										buttons &= ~IN_ATTACK;
									}
								}
								
								
								
								// Make dead ringer spies put their ringer away to shoot.
								if (IsValidEntity(watch) && 59 == GetEntProp(watch, Prop_Send, "m_iItemDefinitionIndex") && GetEntProp(client, Prop_Send, "m_bFeignDeathReady") == 1)
								{
									buttons |= IN_ATTACK2;
								}		
								// Make sure bot doesn't get stuck when trying to attack.
								if(TF2_IsNextToWall(client))
								{
									//PrintToConsoleAll("JUMP!");
									buttons |= IN_JUMP;
								}
								if(GetRandomInt(0,100) <= 10 || clientCurrentVel >= 319 || (TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly) && clientCurrentVel >= 430)) //it changes the spy shuffle direction when the current X velocity reaches 319, or with a 20% chance to ignore that and switch anyway. The random chance is added so the spy doesn't move perfectly, allowing for more confusion on the enemy and more tricking
								{
									if(chainmode)
									{
										chainmode = false;
									}
									else
									{
										chainmode = true;
									}
								}
								if(chainmode)
								{
									moveSide(vel, 400);
								}
								else
								{												
									moveSide2(vel, 400);
								}
								TF2_MoveTo(client, searchOrigin, vel, angles);
							}
						}
						else
						{
							//PrintToConsoleAll("Not targeting.");
							ban_melee[client] = false;
							ban_primary[client] = false;
						}
						
					}
					else
					{
						ban_melee[client] = false;
						ban_primary[client] = false;
					}
				}
			}
		}
	}
}


stock float AngleNormalize(float angle)
{
    angle = fmodf(angle, 360.0);
    if (angle > 180) 
    {
        angle -= 360;
    }
    if (angle < -180)
    {
        angle += 360;
    }
    
    return angle;
}

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}

public bool Filter(int entity, int mask)
{
	return !(IsValidClient(entity));
}

public bool TraceRayDontHitPlayers(int entity, int mask)
{
	if(entity <= MaxClients)
	{
		return false;
	}
	return true;
}

bool IsClientMoving(int client, float wantedVel=0.0)
{
	float buffer[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
	if(wantedVel > 0.0)
	{
		return (GetVectorLength(buffer) >= wantedVel);
	}
	else
	{
		return (GetVectorLength(buffer) > 0.0);
	}
}  


stock int GetHealth(int client)
{
return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock int TF_IsUberCharge(int client)
{
	int index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntProp(index, Prop_Send, "m_bChargeRelease", 1);
	else
		return 0;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

stock int Client_GetClosest(float vecOrigin_center[3], const int client)
{    
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			// We always check this anyways later on.
			// Getitng rid of this makes stuff like gru heavy tweaks work.
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock int Client_GetClosest_Team(float vecOrigin_center[3], const int client)
{    
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) == GetClientTeam(client))
		{
			TFClassType class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock int Client_GetClosest_Both(float vecOrigin_center[3], const int client)
{    
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) == GetClientTeam(client))
		{
			TFClassType class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
		else if(GetClientTeam(i) != GetClientTeam(client))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || TF2_IsPlayerInCondition(i, TFCond_Disguised))
				continue;
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock int Client_GetClosest_SPY(float vecOrigin_center[3], const int client)
{    
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client))
				continue;
			// We always check this anyways later on.
			// Getitng rid of this makes stuff like gru heavy tweaks work.
			//if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			//{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
			//}
		}
	}
	return closestEdict;
}

stock bool IsValidClient(int client) 
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || client < 0) 
		return false; 
	return true; 
}

stock void TF2_LookAtPos(int client, float flGoal[3], float flAimSpeed = 0.05)
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);
	
	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);
	
	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;

	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

public bool TraceEntityFilterStuffTank(int entity, int mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

stock int GetMetal(int client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}

stock int GetTeamNumber(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock bool IsTargetInSightRange(int client, int target, float angle=90.0, float distance=0.0, bool heightcheck=true, bool negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
		
	float clientpos[3];
	float targetpos[3];
	float anglevector[3];
	float targetvector[3];
	float resultangle;
	float resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	// Showin added wall detection here
	// Might be useless cuz it doesn't really prevent them from getting stuck.
	Handle Wall;
	Wall = TR_TraceRayFilterEx(clientpos,targetpos,MASK_SOLID,RayType_EndPoint,Filter);
	if(TR_DidHit(Wall))
	{
		TR_GetEndPosition(targetpos, Wall);
		if(GetVectorDistance(clientpos, targetpos) < 50.0)
		{
			//PrintToConsoleAll("WALL!");
			return false;
		}
	}					
	CloseHandle(Wall);
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

stock int TF2_GetObject(int client, TFObjectType type, TFObjectMode mode)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		TFObjectMode iObjMode = TF2_GetObjectMode(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type && iObjMode == mode 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
}

stock int AngleDifference(float angle1, float angle2)
{
	int diff = RoundToNearest((angle2 - angle1 + 180)) % 360 - 180;
	return diff < -180 ? diff + 360 : diff;
}
















































