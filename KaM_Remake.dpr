program KaM_Remake;
{$I KaM_Remake.inc}

uses
  {$IFDEF USE_MAD_EXCEPT}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListModules,
  {$ENDIF}
  {$IFDEF UNIX} cthreads, {$ENDIF} //Required for thread support on Unix/Linux
  {$IFDEF WDC} FastMM4, {$ENDIF} //Can be used only in Delphi, not Lazarus
  Forms,
  {$IFDEF FPC} Interfaces, {$ENDIF}
  KM_FormMain in 'KM_FormMain.pas' {FormMain},
  KM_FormLoading in 'KM_FormLoading.pas' {FormLoading},
  KM_AI in 'KM_AI.pas',
  KM_AIAttacks in 'KM_AIAttacks.pas',
  KM_AIDefensePos in 'KM_AIDefensePos.pas',
  KM_AIFields in 'KM_AIFields.pas',
  KM_AIGeneral in 'KM_AIGeneral.pas',
  KM_AIMayor in 'KM_AIMayor.pas',
  KM_AISetup in 'KM_AISetup.pas',
  KM_Alerts in 'KM_Alerts.pas',
  KM_ArmyEvaluation in 'KM_ArmyEvaluation.pas',
  KM_BinPacking in 'KM_BinPacking.pas',
  KM_BuildList in 'KM_BuildList.pas',
  KM_Campaigns in 'KM_Campaigns.pas',
  KM_CityPlanner in 'KM_CityPlanner.pas',
  KM_CommonClasses in 'KM_CommonClasses.pas',
  KM_CommonTypes in 'KM_CommonTypes.pas',
  KM_Controls in 'KM_Controls.pas',
  KM_DedicatedServer in 'KM_DedicatedServer.pas',
  KM_Defaults in 'KM_Defaults.pas',
  KM_DeliverQueue in 'KM_DeliverQueue.pas',
  {$IFDEF USE_MAD_EXCEPT}KM_Exceptions in 'KM_Exceptions.pas',{$ENDIF}
  KM_FogOfWar in 'KM_FogOfWar.pas',
  KM_Houses in 'KM_Houses.pas',
  KM_InterfaceDefaults in 'KM_InterfaceDefaults.pas',
  KM_InterfaceGamePlay in 'KM_InterfaceGamePlay.pas',
  KM_InterfaceMainMenu in 'KM_InterfaceMainMenu.pas',
  KM_InterfaceMapEditor in 'KM_InterfaceMapEditor.pas',
  KM_MessageStack in 'KM_MessageStack.pas',
  KM_Game in 'KM_Game.pas',
  KM_GameApp in 'KM_GameApp.pas',
  KM_GameInfo in 'KM_GameInfo.pas',
  KM_GameOptions in 'KM_GameOptions.pas',
  KM_GameInputProcess in 'KM_GameInputProcess.pas',
  KM_GameInputProcess_Multi in 'KM_GameInputProcess_Multi.pas',
  KM_GameInputProcess_Single in 'KM_GameInputProcess_Single.pas',
  KM_Goals in 'KM_Goals.pas',
  KM_HTTPClient in 'KM_HTTPClient.pas',
  KM_Hungarian in 'KM_Hungarian.pas',
  KM_Locales in 'KM_Locales.pas',
  KM_Log in 'KM_Log.pas',
  KM_Main in 'KM_Main.pas',
  KM_Maps in 'KM_Maps.pas',
  KM_MapEditor in 'KM_MapEditor.pas',
  KM_MasterServer in 'KM_MasterServer.pas',
  KM_Minimap in 'KM_Minimap.pas',
  KM_MissionScript in 'KM_MissionScript.pas',
  KM_MissionScript_Info in 'KM_MissionScript_Info.pas',
  KM_MissionScript_Preview in 'KM_MissionScript_Preview.pas',
  KM_MissionScript_Standard in 'KM_MissionScript_Standard.pas',
  KM_Music in 'KM_Music.pas',
  KM_NavMesh in 'KM_NavMesh.pas',
  KM_NetClient in 'KM_NetClient.pas',
  KM_NetServer in 'KM_NetServer.pas',
  KM_Networking in 'KM_Networking.pas',
  KM_NetworkTypes in 'KM_NetworkTypes.pas',
  KM_NetPlayersList in 'KM_NetPlayersList.pas',
  KM_Outline in 'KM_Outline.pas',
  KM_PathFinding in 'KM_PathFinding.pas',
  KM_PathFindingAStarNew in 'KM_PathFindingAStarNew.pas',
  KM_PathFindingRoad in 'KM_PathFindingRoad.pas',
  KM_PerfLog in 'KM_PerfLog.pas',
  KM_Pics in 'KM_Pics.pas',
  KM_Player in 'KM_Player.pas',
  KM_PlayersCollection in 'KM_PlayersCollection.pas',
  KM_PlayerStats in 'KM_PlayerStats.pas',
  KM_Points in 'KM_Points.pas',
  KM_PolySimplify in 'KM_PolySimplify.pas',
  KM_Projectiles in 'KM_Projectiles.pas',
  KM_Render in 'KM_Render.pas',
  KM_RenderAux in 'KM_RenderAux.pas',
  KM_RenderPool in 'KM_RenderPool.pas',
  KM_RenderTerrain in 'KM_RenderTerrain.pas',
  KM_RenderUI in 'KM_RenderUI.pas',
  KM_Resolutions in 'KM_Resolutions.pas',
  KM_Resource in 'KM_Resource.pas',
  KM_ResourceCursors in 'KM_ResourceCursors.pas',
  KM_ResourceFonts in 'KM_ResourceFonts.pas',
  KM_ResourceHouse in 'KM_ResourceHouse.pas',
  KM_ResourceMapElements in 'KM_ResourceMapElements.pas',
  KM_ResourcePalettes in 'KM_ResourcePalettes.pas',
  KM_ResourceResource in 'KM_ResourceResource.pas',
  KM_ResourceSprites in 'KM_ResourceSprites.pas',
  KM_ResourceTileset in 'KM_ResourceTileset.pas',
  KM_ResourceUnit in 'KM_ResourceUnit.pas',
  KM_Saves in 'KM_Saves.pas',
  KM_Scripting in 'KM_Scripting.pas',
  KM_ScriptingESA in 'KM_ScriptingESA.pas',
  KM_ServerQuery in 'KM_ServerQuery.pas',
  KM_Settings in 'KM_Settings.pas',
  KM_Sound in 'KM_Sound.pas',
  KM_Terrain in 'KM_Terrain.pas',
  KM_TerrainFinder in 'KM_TerrainFinder.pas',
  KM_TerrainPainter in 'KM_TerrainPainter.pas',
  KM_TextLibrary in 'KM_TextLibrary.pas',
  KM_UnitActionAbandonWalk in 'KM_UnitActionAbandonWalk.pas',
  KM_UnitActionFight in 'KM_UnitActionFight.pas',
  KM_UnitActionGoInOut in 'KM_UnitActionGoInOut.pas',
  KM_UnitActionStay in 'KM_UnitActionStay.pas',
  KM_UnitActionSteer in 'KM_UnitActionSteer.pas',
  KM_UnitActionStormAttack in 'KM_UnitActionStormAttack.pas',
  KM_UnitActionWalkTo in 'KM_UnitActionWalkTo.pas',
  KM_UnitGroups in 'KM_UnitGroups.pas',
  KM_Units in 'KM_Units.pas',
  KM_Units_Warrior in 'KM_Units_Warrior.pas',
  KM_Units_WorkPlan in 'KM_Units_WorkPlan.pas',
  KM_UnitTaskAttackHouse in 'KM_UnitTaskAttackHouse.pas',
  KM_UnitTaskBuild in 'KM_UnitTaskBuild.pas',
  KM_UnitTaskDelivery in 'KM_UnitTaskDelivery.pas',
  KM_UnitTaskDie in 'KM_UnitTaskDie.pas',
  KM_UnitTaskGoEat in 'KM_UnitTaskGoEat.pas',
  KM_UnitTaskGoHome in 'KM_UnitTaskGoHome.pas',
  KM_UnitTaskGoOutShowHungry in 'KM_UnitTaskGoOutShowHungry.pas',
  KM_UnitTaskMining in 'KM_UnitTaskMining.pas',
  KM_UnitTaskSelfTrain in 'KM_UnitTaskSelfTrain.pas',
  KM_UnitTaskThrowRock in 'KM_UnitTaskThrowRock.pas',
  KM_Utils in 'KM_Utils.pas',
  KM_Viewport in 'KM_Viewport.pas';

{$IFDEF WDC}
  {$R KaM_Remake.RES} //Keeps the Icon
  {$R KaM_Manifest.RES}
{$ENDIF}
{$IFDEF MSWindows}
  {$IFDEF FPC}
    {$R KaM_Remake_Icon.rc}
    {$R KaM_Manifest.rc}
  {$ENDIF}
{$ENDIF}

begin
  Application.Initialize;
  Application.Title := 'KaM Remake';

  fMain := TKMMain.Create;
  fMain.Start;

  Application.Run;

  fMain.Free; //Prevents memory leak of TKMMain showing up in FastMM
end.
