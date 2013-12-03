unit KM_ScriptingESA;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils, uPSRuntime,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_UnitGroups, KM_ResHouses;


  //Two classes exposed to scripting States and Actions

  //All functions can be split into these three categories:
  // - Event, when something has happened (e.g. House was built)
  // - State, describing the state of something (e.g. Houses.Count >= 1)
  // - Action, when we need to perform something (e.g. show a message)

  //How to add new a method exposed to the scripting? Three steps:
  //1. Add method to published section here below
  //2. Add method declaration to Compiler (TKMScripting.ScriptOnUses)
  //3. Add method name to Runtime (TKMScripting.LinkRuntime)
type
  TKMScriptEvents = class
  private
    fExec: TPSExec;
    fIDCache: TKMScriptingIdCache;
  public
    constructor Create(aExec: TPSExec; aIDCache: TKMScriptingIdCache);

    procedure ProcHouseBuilt(aHouse: TKMHouse);
    procedure ProcHousePlanPlaced(aPlayer: THandIndex; aX, aY: Word; aType: THouseType);
    procedure ProcHouseDamaged(aHouse: TKMHouse; aAttacker: TKMUnit);
    procedure ProcHouseDestroyed(aHouse: TKMHouse; aDestroyerIndex: THandIndex);
    procedure ProcMissionStart;
    procedure ProcPlanPlaced(aPlayer: THandIndex; aX, aY: Word; aPlanType: TFieldType);
    procedure ProcPlayerDefeated(aPlayer: THandIndex);
    procedure ProcPlayerVictory(aPlayer: THandIndex);
    procedure ProcTick;
    procedure ProcUnitDied(aUnit: TKMUnit; aKillerOwner: THandIndex);
    procedure ProcUnitTrained(aUnit: TKMUnit);
    procedure ProcUnitWounded(aUnit, aAttacker: TKMUnit);
    procedure ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
  end;


  TKMScriptStates = class
  private
    fIDCache: TKMScriptingIdCache;
    procedure LogError(aFuncName: string; const aValues: array of Integer);
  public
    constructor Create(aIDCache: TKMScriptingIdCache);

    function ClosestGroup(aPlayer, X, Y: Integer): Integer;
    function ClosestHouse(aPlayer, X, Y: Integer): Integer;
    function ClosestUnit(aPlayer, X, Y: Integer): Integer;

    function GameTime: Cardinal;
    function PeaceTime: Cardinal;
    function KaMRandom: Single;
    function KaMRandomI(aMax: Integer): Integer;

    function FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean;

    function GroupAt(aX, aY: Word): Integer;
    function GroupColumnCount(aGroupID: Integer): Integer;
    function GroupDead(aGroupID: Integer): Boolean;
    function GroupMember(aGroupID, aMemberIndex: Integer): Integer;
    function GroupMemberCount(aGroupID: Integer): Integer;
    function GroupOwner(aGroupID: Integer): Integer;
    function GroupType(aGroupID: Integer): Integer;

    function HouseAt(aX, aY: Word): Integer;
    function HouseCanReachResources(aHouseID: Integer): Boolean;
    function HouseDamage(aHouseID: Integer): Integer;
    function HouseDeliveryBlocked(aHouseID: Integer): Boolean;
    function HouseDestroyed(aHouseID: Integer): Boolean;
    function HouseHasOccupant(aHouseID: Integer): Boolean;
    function HouseIsComplete(aHouseID: Integer): Boolean;
    function HouseOccupant(aHouseID: Integer): Integer;
    function HouseOwner(aHouseID: Integer): Integer;
    function HousePositionX(aHouseID: Integer): Integer;
    function HousePositionY(aHouseID: Integer): Integer;
    function HouseRepair(aHouseID: Integer): Boolean;
    function HouseResourceAmount(aHouseID, aResource: Integer): Integer;
    function HouseSchoolQueue(aHouseID, QueueIndex: Integer): Integer;
    function HouseType(aHouseID: Integer): Integer;
    function HouseWareBlocked(aHouseID, aWareType: Integer): Boolean;
    function HouseWeaponsOrdered(aHouseID, aWareType: Integer): Integer;
    function HouseWoodcutterChopOnly(aHouseID: Integer): Boolean;

    function IsFieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
    function IsWinefieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
    function IsRoadAt(aPlayer: ShortInt; X, Y: Word): Boolean;

    function PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean;
    function PlayerDefeated(aPlayer: Byte): Boolean;
    function PlayerEnabled(aPlayer: Byte): Boolean;
    function PlayerGetAllUnits(aPlayer: Byte): TIntegerArray;
    function PlayerGetAllHouses(aPlayer: Byte): TIntegerArray;
    function PlayerGetAllGroups(aPlayer: Byte): TIntegerArray;
    function PlayerIsAI(aPlayer: Byte): Boolean;
    function PlayerName(aPlayer: Byte): UnicodeString;
    function PlayerColorText(aPlayer: Byte): UnicodeString;
    function PlayerVictorious(aPlayer: Byte): Boolean;
    function PlayerWareDistribution(aPlayer, aWareType, aHouseType: Byte): Byte;

    function StatArmyCount(aPlayer: Byte): Integer;
    function StatCitizenCount(aPlayer: Byte): Integer;
    function StatHouseTypeCount(aPlayer, aHouseType: Byte): Integer;
    function StatPlayerCount: Integer;
    function StatResourceProducedCount(aPlayer, aResType: Byte): Integer;
    function StatUnitCount(aPlayer: Byte): Integer;
    function StatUnitKilledCount(aPlayer, aUnitType: Byte): Integer;
    function StatUnitLostCount(aPlayer, aUnitType: Byte): Integer;
    function StatUnitTypeCount(aPlayer, aUnitType: Byte): Integer;

    function UnitAt(aX, aY: Word): Integer;
    function UnitDead(aUnitID: Integer): Boolean;
    function UnitDirection(aUnitID: Integer): Integer;
    function UnitHunger(aUnitID: Integer): Integer;
    function UnitCarrying(aUnitID: Integer): Integer;
    function UnitLowHunger: Integer;
    function UnitMaxHunger: Integer;
    function UnitOwner(aUnitID: Integer): Integer;
    function UnitPositionX(aUnitID: Integer): Integer;
    function UnitPositionY(aUnitID: Integer): Integer;
    function UnitType(aUnitID: Integer): Integer;
    function UnitsGroup(aUnitID: Integer): Integer;
  end;

  TKMScriptActions = class
  private
    fIDCache: TKMScriptingIdCache;
    procedure LogError(aFuncName: string; const aValues: array of Integer);
  public
    SFXPath: UnicodeString;  //Relative to EXE (safe to use in Save, cos it is the same for all MP players)
    constructor Create(aIDCache: TKMScriptingIdCache);

    procedure AIAutoBuild(aPlayer: Byte; aAuto: Boolean);
    procedure AIAutoDefence(aPlayer: Byte; aAuto: Boolean);
    procedure AIAutoRepair(aPlayer: Byte; aAuto: Boolean);
    procedure AIBuildersLimit(aPlayer, aLimit: Byte);
    procedure AIDefencePositionAdd(aPlayer: Byte; X, Y: Integer; aDir, aGroupType: Byte; aRadius: Word; aDefType: Byte);
    procedure AIEquipRate(aPlayer: Byte; aType: Byte; aRate: Word);
    procedure AIGroupsFormationSet(aPlayer, aType: Byte; aCount, aColumns: Word);
    procedure AIRecruitDelay(aPlayer: Byte; aDelay: Cardinal);
    procedure AIRecruitLimit(aPlayer, aLimit: Byte);
    procedure AISerfsFactor(aPlayer, aLimit: Byte);
    procedure AISoldiersLimit(aPlayer: Byte; aLimit: Integer);

    procedure CinematicStart(aPlayer: Byte);
    procedure CinematicEnd(aPlayer: Byte);
    procedure CinematicPanTo(aPlayer: Byte; X, Y, Duration: Word);

    function  GiveAnimal(aType, X,Y: Word): Integer;
    function  GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word): Integer;
    function  GiveHouse(aPlayer, aHouseType, X,Y: Integer): Integer;
    function  GiveUnit(aPlayer, aType, X,Y, aDir: Word): Integer;
    procedure GiveWares(aPlayer, aType, aCount: Word);
    procedure GiveWeapons(aPlayer, aType, aCount: Word);

    procedure FogCoverAll(aPlayer: Byte);
    procedure FogCoverCircle(aPlayer, X, Y, aRadius: Word);
    procedure FogRevealRect(aPlayer, X1, Y1, X2, Y2: Word);
    procedure FogCoverRect(aPlayer, X1, Y1, X2, Y2: Word);
    procedure FogRevealAll(aPlayer: Byte);
    procedure FogRevealCircle(aPlayer, X, Y, aRadius: Word);

    procedure GroupDisableHungryMessage(aGroupID: Integer; aDisable: Boolean);
    procedure GroupHungerSet(aGroupID, aHungerLevel: Integer);
    procedure GroupKillAll(aGroupID: Integer; aSilent: Boolean);
    procedure GroupOrderAttackHouse(aGroupID, aHouseID: Integer);
    procedure GroupOrderAttackUnit(aGroupID, aUnitID: Integer);
    procedure GroupOrderFood(aGroupID: Integer);
    procedure GroupOrderHalt(aGroupID: Integer);
    procedure GroupOrderLink(aGroupID, aDestGroupID: Integer);
    function  GroupOrderSplit(aGroupID: Integer): Integer;
    procedure GroupOrderStorm(aGroupID: Integer);
    procedure GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word);
    procedure GroupSetFormation(aGroupID: Integer; aNumColumns: Byte);

    procedure HouseAddDamage(aHouseID: Integer; aDamage: Word);
    procedure HouseAddRepair(aHouseID: Integer; aRepair: Word);
    procedure HouseAddWaresTo(aHouseID: Integer; aType, aCount: Word);
    procedure HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean);
    function  HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseDestroy(aHouseID: Integer; aSilent: Boolean);
    procedure HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
    procedure HouseDisableUnoccupiedMessage(aHouseID: Integer; aDisabled: Boolean);
    procedure HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
    function  HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer);
    procedure HouseUnlock(aPlayer, aHouseType: Word);
    procedure HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
    procedure HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean);
    procedure HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);

    procedure OverlayTextSet(aPlayer: Shortint; aText: AnsiString);
    procedure OverlayTextSetFormatted(aPlayer: Shortint; aText: AnsiString; Params: array of const);
    procedure OverlayTextAppend(aPlayer: Shortint; aText: AnsiString);
    procedure OverlayTextAppendFormatted(aPlayer: Shortint; aText: AnsiString; Params: array of const);

    function PlanAddField(aPlayer, X, Y: Word): Boolean;
    function PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean;
    function PlanAddRoad(aPlayer, X, Y: Word): Boolean;
    function PlanAddWinefield(aPlayer, X, Y: Word): Boolean;
    function PlanRemove(aPlayer, X, Y: Word): Boolean;

    procedure PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean);
    procedure PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean);
    procedure PlayerDefeat(aPlayer: Word);
    procedure PlayerShareFog(aPlayer1, aPlayer2: Word; aShare: Boolean);
    procedure PlayerWareDistribution(aPlayer, aWareType, aHouseType, aAmount: Byte);
    procedure PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);

    procedure PlayWAV(aPlayer: ShortInt; const aFileName: AnsiString; Volume: Single);
    procedure PlayWAVAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; Volume: Single; X, Y: Word);

    procedure RemoveField(X, Y: Word);
    procedure RemoveRoad(X, Y: Word);

    procedure SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean);
    procedure ShowMsg(aPlayer: Shortint; aText: AnsiString);
    procedure ShowMsgFormatted(aPlayer: Shortint; aText: AnsiString; Params: array of const);
    procedure ShowMsgGoto(aPlayer: Shortint; aX, aY: Word; aText: AnsiString);
    procedure ShowMsgGotoFormatted(aPlayer: Shortint; aX, aY: Word; aText: AnsiString; Params: array of const);

    procedure UnitBlock(aPlayer: Byte; aType: Word; aBlock: Boolean);
    function  UnitDirectionSet(aUnitID, aDirection: Integer): Boolean;
    procedure UnitHungerSet(aUnitID, aHungerLevel: Integer);
    procedure UnitKill(aUnitID: Integer; aSilent: Boolean);
    function  UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean;
  end;


var
  gScriptEvents: TKMScriptEvents;


implementation
uses KM_AI, KM_Terrain, KM_Game, KM_FogOfWar, KM_HandsCollection, KM_Units_Warrior,
  KM_HouseBarracks, KM_HouseSchool, KM_ResUnits, KM_ResWares, KM_Log, KM_Utils,
  KM_Resource, KM_UnitTaskSelfTrain, KM_Sound, KM_Hand, KM_AIDefensePos;


type
  TKMEvent = procedure of object;
  TKMEvent1I = procedure (aIndex: Integer) of object;
  TKMEvent2I = procedure (aIndex, aParam: Integer) of object;
  TKMEvent3I = procedure (aIndex, aParam1, aParam2: Integer) of object;
  TKMEvent4I = procedure (aIndex, aParam1, aParam2, aParam3: Integer) of object;


  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player


{ TKMScriptEvents }
constructor TKMScriptEvents.Create(aExec: TPSExec; aIDCache: TKMScriptingIdCache);
begin
  inherited Create;

  fExec := aExec;
  fIDCache := aIDCache;
end;


procedure TKMScriptEvents.ProcMissionStart;
var
  TestFunc: TKMEvent;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent(fExec.GetProcAsMethodN('ONMISSIONSTART'));
  if @TestFunc <> nil then
    TestFunc;
end;


procedure TKMScriptEvents.ProcTick;
var
  TestFunc: TKMEvent;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent(fExec.GetProcAsMethodN('ONTICK'));
  if @TestFunc <> nil then
    TestFunc;
end;


procedure TKMScriptEvents.ProcHouseBuilt(aHouse: TKMHouse);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  //Store house by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONHOUSEBUILT'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    TestFunc(aHouse.UID);
  end;
end;


procedure TKMScriptEvents.ProcHouseDamaged(aHouse: TKMHouse; aAttacker: TKMUnit);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store house by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONHOUSEDAMAGED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      TestFunc(aHouse.UID, aAttacker.UID);
    end
    else
      //House was damaged, but we don't know by whom (e.g. by script command)
      TestFunc(aHouse.UID, PLAYER_NONE);
  end;
end;


procedure TKMScriptEvents.ProcHouseDestroyed(aHouse: TKMHouse; aDestroyerIndex: THandIndex);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store house by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONHOUSEDESTROYED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheHouse(aHouse, aHouse.UID); //Improves cache efficiency since aHouse will probably be accessed soon
    TestFunc(aHouse.UID, aDestroyerIndex);
  end;
end;


procedure TKMScriptEvents.ProcHousePlanPlaced(aPlayer: THandIndex; aX, aY: Word; aType: THouseType);
var
  TestFunc: TKMEvent4I;
begin
  TestFunc := TKMEvent4I(fExec.GetProcAsMethodN('ONHOUSEPLANPLACED'));
  if @TestFunc <> nil then
    TestFunc(aPlayer, aX + gResource.HouseDat[aType].EntranceOffsetX, aY, HouseTypeToIndex[aType] - 1);
end;


procedure TKMScriptEvents.ProcUnitDied(aUnit: TKMUnit; aKillerOwner: THandIndex);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONUNITDIED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    TestFunc(aUnit.UID, aKillerOwner);
  end;
end;


procedure TKMScriptEvents.ProcUnitTrained(aUnit: TKMUnit);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONUNITTRAINED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    TestFunc(aUnit.UID);
  end;
end;


procedure TKMScriptEvents.ProcUnitWounded(aUnit, aAttacker: TKMUnit);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONUNITWOUNDED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    if aAttacker <> nil then
    begin
      fIDCache.CacheUnit(aAttacker, aAttacker.UID); //Improves cache efficiency since aAttacker will probably be accessed soon
      TestFunc(aUnit.UID, aAttacker.UID);
    end
    else
      TestFunc(aUnit.UID, -1);
  end;
end;


procedure TKMScriptEvents.ProcWarriorEquipped(aUnit: TKMUnit; aGroup: TKMUnitGroup);
var
  TestFunc: TKMEvent2I;
begin
  //Check if event handler (procedure) exists and run it
  //Store unit by its KaM index to keep it consistent with DAT scripts
  TestFunc := TKMEvent2I(fExec.GetProcAsMethodN('ONWARRIOREQUIPPED'));
  if @TestFunc <> nil then
  begin
    fIDCache.CacheUnit(aUnit, aUnit.UID); //Improves cache efficiency since aUnit will probably be accessed soon
    fIDCache.CacheGroup(aGroup, aGroup.UID);
    TestFunc(aUnit.UID, aGroup.UID);
  end;
end;


procedure TKMScriptEvents.ProcPlanPlaced(aPlayer: THandIndex; aX, aY: Word; aPlanType: TFieldType);
var
  TestFunc: TKMEvent3I;
begin
  case aPlanType of
    ft_Road: TestFunc := TKMEvent3I(fExec.GetProcAsMethodN('ONPLANROAD'));
    ft_Wine: TestFunc := TKMEvent3I(fExec.GetProcAsMethodN('ONPLANFIELD'));
    ft_Corn: TestFunc := TKMEvent3I(fExec.GetProcAsMethodN('ONPLANWINEFIELD'));
    else     begin
               Assert(False);
               Exit; //Make compiler happy
             end;
  end;
  if @TestFunc <> nil then
    TestFunc(aPlayer, aX, aY);
end;


procedure TKMScriptEvents.ProcPlayerDefeated(aPlayer: THandIndex);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONPLAYERDEFEATED'));
  if @TestFunc <> nil then
    TestFunc(aPlayer);
end;


procedure TKMScriptEvents.ProcPlayerVictory(aPlayer: THandIndex);
var
  TestFunc: TKMEvent1I;
begin
  //Check if event handler (procedure) exists and run it
  TestFunc := TKMEvent1I(fExec.GetProcAsMethodN('ONPLAYERVICTORY'));
  if @TestFunc <> nil then
    TestFunc(aPlayer);
end;


{ TKMScriptStates }
constructor TKMScriptStates.Create(aIDCache: TKMScriptingIdCache);
begin
  inherited Create;
  fIDCache := aIDCache;
end;


procedure TKMScriptStates.LogError(aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  Values: string;
begin
  for I := Low(aValues) to High(aValues) do
    Values := Values + IntToStr(aValues[I]) + IfThen(I<>High(aValues), ', ');
  gLog.AddTime('Mistake in script usage ' + aFuncName + ': ' + Values);
end;


function TKMScriptStates.ClosestGroup(aPlayer, X, Y: Integer): Integer;
var G: TKMUnitGroup;
begin
  Result := -1;
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    G := gHands[aPlayer].UnitGroups.GetClosestGroup(KMPoint(X,Y));
    if G <> nil then
      Result := G.UID;
  end
  else
    LogError('States.ClosestGroup', [aPlayer, X, Y]);
end;


function TKMScriptStates.ClosestHouse(aPlayer, X, Y: Integer): Integer;
var H: TKMHouse;
begin
  Result := -1;
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    H := gHands[aPlayer].Houses.FindHouse(ht_Any, X, Y);
    if H <> nil then
      Result := H.UID;
  end
  else
    LogError('States.ClosestHouse', [aPlayer, X, Y]);
end;


function TKMScriptStates.ClosestUnit(aPlayer, X, Y: Integer): Integer;
var U: TKMUnit;
begin
  Result := -1;
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    U := gHands[aPlayer].Units.GetClosestUnit(KMPoint(X,Y));
    if U <> nil then
      Result := U.UID;
  end
  else
    LogError('States.ClosestUnit', [aPlayer, X, Y]);
end;


function TKMScriptStates.StatArmyCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].Stats.GetArmyCount
  else
  begin
    Result := 0;
    LogError('States.StatArmyCount', [aPlayer]);
  end;
end;


function TKMScriptStates.StatCitizenCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].Stats.GetCitizensCount
  else
  begin
    Result := 0;
    LogError('States.StatCitizenCount', [aPlayer]);
  end;
end;


function TKMScriptStates.GameTime: Cardinal;
begin
  Result := gGame.GameTickCount;
end;


function TKMScriptStates.PeaceTime: Cardinal;
begin
  Result := 600 * gGame.GameOptions.Peacetime;
end;


function TKMScriptStates.PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean;
begin
  if  InRange(aPlayer1, 0, gHands.Count - 1)
  and InRange(aPlayer2, 0, gHands.Count - 1) then
    Result := gHands[aPlayer1].Alliances[aPlayer2] = at_Ally
  else
  begin
    Result := False;
    LogError('States.PlayerAllianceCheck', [aPlayer1, aPlayer2]);
  end;
end;


function TKMScriptStates.StatHouseTypeCount(aPlayer, aHouseType: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aHouseType in [Low(HouseIndexToType)..High(HouseIndexToType)])
  then
    Result := gHands[aPlayer].Stats.GetHouseQty(HouseIndexToType[aHouseType])
  else
  begin
    Result := 0;
    LogError('States.StatHouseTypeCount', [aPlayer, aHouseType]);
  end;
end;


function TKMScriptStates.StatPlayerCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to gHands.Count - 1 do
    if gHands[I].Enabled then
      Inc(Result);
end;


function TKMScriptStates.PlayerDefeated(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := (gHands[aPlayer].AI.WonOrLost = wol_Lost)
  else
  begin
    Result := False;
    LogError('States.PlayerDefeated', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerVictorious(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := (gHands[aPlayer].AI.WonOrLost = wol_Won)
  else
  begin
    Result := False;
    LogError('States.PlayerVictorious', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerWareDistribution(aPlayer, aWareType, aHouseType: Byte): Byte;
var
  Res: TWareType;
begin
  Res := WareIndexToType[aWareType];
  if InRange(aPlayer, 0, gHands.Count - 1) and (Res in [WARE_MIN..WARE_MAX])
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)]) then
    Result := gHands[aPlayer].Stats.Ratio[Res, HouseIndexToType[aHouseType]]
  else
  begin
    Result := 0;
    LogError('States.PlayerWareDistribution', [aPlayer, aWareType, aHouseType]);
  end;
end;


function TKMScriptStates.PlayerGetAllUnits(aPlayer: Byte): TIntegerArray;
var
  I, UnitCount: Integer;
  U: TKMUnit;
begin
  SetLength(Result, 0);

  if InRange(aPlayer, 0, gHands.Count - 1) then
  begin
    UnitCount := 0;

    //Allocate max required space
    SetLength(Result, gHands[aPlayer].Units.Count);
    for I := 0 to gHands[aPlayer].Units.Count - 1 do
    begin
      U := gHands[aPlayer].Units[I];
      //Skip units in training, they can't be disturbed until they are finished training
      if U.IsDeadOrDying or (U.UnitTask is TTaskSelfTrain) then Continue;
      Result[UnitCount] := U.UID;
      Inc(UnitCount);
    end;

    //Trim to length
    SetLength(Result, UnitCount);
  end
  else
  begin
    LogError('States.PlayerGetAllUnits', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerGetAllHouses(aPlayer: Byte): TIntegerArray;
var
  I, HouseCount: Integer;
  H: TKMHouse;
begin
  SetLength(Result, 0);

  if InRange(aPlayer, 0, gHands.Count - 1) then
  begin
    HouseCount := 0;

    //Allocate max required space
    SetLength(Result, gHands[aPlayer].Houses.Count);
    for I := 0 to gHands[aPlayer].Houses.Count - 1 do
    begin
      H := gHands[aPlayer].Houses[I];
      if H.IsDestroyed then Continue;
      Result[HouseCount] := H.UID;
      Inc(HouseCount);
    end;

    //Trim to length
    SetLength(Result, HouseCount);
  end
  else
  begin
    LogError('States.PlayerGetAllHouses', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerGetAllGroups(aPlayer: Byte): TIntegerArray;
var
  I, GroupCount: Integer;
  G: TKMUnitGroup;
begin
  SetLength(Result, 0);

  if InRange(aPlayer, 0, gHands.Count - 1) then
  begin
    GroupCount := 0;

    //Allocate max required space
    SetLength(Result, gHands[aPlayer].UnitGroups.Count);
    for I := 0 to gHands[aPlayer].UnitGroups.Count - 1 do
    begin
      G := gHands[aPlayer].UnitGroups[I];
      if G.IsDead then Continue;
      Result[GroupCount] := G.UID;
      Inc(GroupCount);
    end;

    //Trim to length
    SetLength(Result, GroupCount);
  end
  else
  begin
    LogError('States.PlayerGetAllGroups', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerIsAI(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].PlayerType = hndComputer
  else
  begin
    Result := False;
    LogError('States.PlayerIsAI', [aPlayer]);
  end;
end;


function TKMScriptStates.StatUnitCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].Stats.GetUnitQty(ut_Any)
  else
  begin
    Result := 0;
    LogError('States.StatUnitCount', [aPlayer]);
  end;
end;


function TKMScriptStates.StatUnitTypeCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := gHands[aPlayer].Stats.GetUnitQty(UnitIndexToType[aUnitType])
  else
  begin
    Result := 0;
    LogError('States.StatUnitTypeCount', [aPlayer, aUnitType]);
  end;
end;


function TKMScriptStates.StatUnitKilledCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := gHands[aPlayer].Stats.GetUnitKilledQty(UnitIndexToType[aUnitType])
  else
  begin
    Result := 0;
    LogError('States.StatUnitKilledCount', [aPlayer, aUnitType]);
  end;
end;


function TKMScriptStates.StatUnitLostCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := gHands[aPlayer].Stats.GetUnitLostQty(UnitIndexToType[aUnitType])
  else
  begin
    Result := 0;
    LogError('States.StatUnitLostCount', [aPlayer, aUnitType]);
  end;
end;


function TKMScriptStates.StatResourceProducedCount(aPlayer, aResType: Byte): Integer;
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aResType in [Low(WareIndexToType)..High(WareIndexToType)])
  then
    Result := gHands[aPlayer].Stats.GetWaresProduced(WareIndexToType[aResType])
  else
  begin
    Result := 0;
    LogError('States.StatResourceProducedCount', [aPlayer, aResType]);
  end;
end;


function TKMScriptStates.PlayerName(aPlayer: Byte): UnicodeString;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].OwnerName
  else
  begin
    Result := '';
    LogError('States.PlayerName', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerColorText(aPlayer: Byte): UnicodeString;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := Format('%.6x', [FlagColorToTextColor(gHands[aPlayer].FlagColor) and $FFFFFF])
  else
  begin
    Result := '';
    LogError('States.PlayerColorText', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerEnabled(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].Enabled
  else
  begin
    Result := False;
    LogError('States.PlayerEnabled', [aPlayer]);
  end;
end;


function TKMScriptStates.HouseCanReachResources(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := False;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := not H.ResourceDepletedMsgIssued;
  end
  else
    LogError('States.HouseCanReachResources', [aHouseID]);
end;


function TKMScriptStates.HouseAt(aX, aY: Word): Integer;
var
  H: TKMHouse;
begin
  Result := UID_NONE;
  if gTerrain.TileInMapCoords(aX,aY) then
  begin
    H := gHands.HousesHitTest(aX, aY);
    if (H <> nil) and not H.IsDestroyed then
    begin
      Result := H.UID;
      fIDCache.CacheHouse(H, H.UID); //Improves cache efficiency since H will probably be accessed soon
    end;
  end
  else
    LogError('States.HouseAt', [aX, aY]);
end;


function TKMScriptStates.HousePositionX(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := UID_NONE;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.GetEntrance.X;
  end
  else
    LogError('States.HouseX', [aHouseID]);
end;


function TKMScriptStates.HousePositionY(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := UID_NONE;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.GetEntrance.Y;
  end
  else
    LogError('States.HouseY', [aHouseID]);
end;


function TKMScriptStates.HouseDestroyed(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := True;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.IsDestroyed;
  end
  else
    LogError('States.HouseDestroyed', [aHouseID]);
end;


function TKMScriptStates.HouseOccupant(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := -1;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := UnitTypeToIndex[gResource.HouseDat[H.HouseType].OwnerType];
  end
  else
    LogError('States.HouseOccupant', [aHouseID]);
end;


function TKMScriptStates.HouseOwner(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := PLAYER_NONE;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.Owner;
  end
  else
    LogError('States.HouseOwner', [aHouseID]);
end;


//Get the house type
function TKMScriptStates.HouseType(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := -1;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := HouseTypeToIndex[H.HouseType] - 1;
  end
  else
    LogError('States.HouseType', [aHouseID]);
end;


//Get the unit type in Schools queue
function TKMScriptStates.HouseSchoolQueue(aHouseID, QueueIndex: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := -1;
  if (aHouseID > 0) and InRange(QueueIndex, 0, 5) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) and (H is TKMHouseSchool) then
      Result := UnitTypeToIndex[TKMHouseSchool(H).Queue[QueueIndex]];
  end
  else
    LogError('States.HouseSchoolQueue', [aHouseID, QueueIndex]);
end;


function TKMScriptStates.HouseWeaponsOrdered(aHouseID, aWareType: Integer): Integer;
var
  H: TKMHouse;
  Res: TWareType;
  I: Integer;
begin
  Result := 0;
  Res := WareIndexToType[aWareType];
  if (aHouseID > 0) and (Res in [WARE_MIN..WARE_MAX]) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) then
      for I := 1 to 4 do
        if gResource.HouseDat[H.HouseType].ResOutput[I] = Res then
        begin
          Result := H.ResOrder[I];
          Exit;
        end;
  end
  else
    LogError('States.HouseWeaponsOrdered', [aHouseID, aWareType]);
end;


function TKMScriptStates.HouseWoodcutterChopOnly(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := False;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H is TKMHouseWoodcutters then
      Result := TKMHouseWoodcutters(H).WoodcutterMode = wcm_Chop;
  end
  else
    LogError('States.HouseWoodcutterChopOnly', [aHouseID]);
end;


function TKMScriptStates.IsFieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
begin
  Result := False;
  //-1 stands for any player
  if InRange(aPlayer, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
    Result := gTerrain.TileIsCornField(KMPoint(X,Y))
              and ((aPlayer = -1) or (gTerrain.Land[Y, X].TileOwner = aPlayer))
  else
    LogError('States.IsFieldAt', [aPlayer, X, Y]);
end;


function TKMScriptStates.IsWinefieldAt(aPlayer: ShortInt; X, Y: Word): Boolean;
begin
  Result := False;
  //-1 stands for any player
  if InRange(aPlayer, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
    Result := gTerrain.TileIsWineField(KMPoint(X,Y))
              and ((aPlayer = -1) or (gTerrain.Land[Y, X].TileOwner = aPlayer))
  else
    LogError('States.IsWinefieldAt', [aPlayer, X, Y]);
end;


function TKMScriptStates.IsRoadAt(aPlayer: ShortInt; X, Y: Word): Boolean;
begin
  Result := False;
  //-1 stands for any player
  if InRange(aPlayer, -1, gHands.Count - 1) and gTerrain.TileInMapCoords(X, Y) then
    Result := (gTerrain.Land[Y,X].TileOverlay = to_Road)
              and ((aPlayer = -1) or (gTerrain.Land[Y, X].TileOwner = aPlayer))
  else
    LogError('States.IsRoadAt', [aPlayer, X, Y]);
end;


function TKMScriptStates.HouseWareBlocked(aHouseID, aWareType: Integer): Boolean;
var
  H: TKMHouse;
  Res: TWareType;
begin
  Result := False;
  Res := WareIndexToType[aWareType];
  if (aHouseID > 0) and (Res in [WARE_MIN..WARE_MAX]) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H is TKMHouseStore) then
      Result := TKMHouseStore(H).NotAcceptFlag[Res];
    if (H is TKMHouseBarracks) and (Res in [WARFARE_MIN..WARFARE_MAX]) then
      Result := TKMHouseBarracks(H).NotAcceptFlag[Res];
  end
  else
    LogError('States.HouseWareBlocked', [aHouseID, aWareType]);
end;


function TKMScriptStates.HouseDamage(aHouseID: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := -1; //-1 if house id is invalid
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.GetDamage;
  end
  else
    LogError('States.HouseDamage', [aHouseID]);
end;


function TKMScriptStates.HouseRepair(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := False;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.BuildingRepair;
  end
  else
    LogError('States.HouseRepair', [aHouseID]);
end;


function TKMScriptStates.HouseDeliveryBlocked(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := True;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := (not H.WareDelivery);
  end
  else
    LogError('States.HouseDeliveryBlocked', [aHouseID]);
end;


function TKMScriptStates.HouseResourceAmount(aHouseID, aResource: Integer): Integer;
var
  H: TKMHouse;
  Res: TWareType;
begin
  Result := -1; //-1 if house id is invalid
  Res := WareIndexToType[aResource];
  if (aHouseID > 0) and (Res in [WARE_MIN..WARE_MAX]) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.CheckResIn(Res) + H.CheckResOut(Res); //Count both in and out
  end
  else
    LogError('States.HouseResourceAmount', [aHouseID, aResource]);
end;


function TKMScriptStates.HouseHasOccupant(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := False;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.GetHasOwner;
  end
  else
    LogError('States.HouseHasOccupant', [aHouseID]);
end;


function TKMScriptStates.HouseIsComplete(aHouseID: Integer): Boolean;
var
  H: TKMHouse;
begin
  Result := False;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.IsComplete;
  end
  else
    LogError('States.HouseIsComplete', [aHouseID]);
end;


function TKMScriptStates.KaMRandom: Single;
begin
  Result := KM_Utils.KaMRandom;
end;


function TKMScriptStates.KaMRandomI(aMax:Integer): Integer;
begin
  //No parameters to check, any integer is fine (even negative)
  Result := KM_Utils.KaMRandom(aMax);
end;


function TKMScriptStates.FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean;
begin
  Result := False;
  if gTerrain.TileInMapCoords(aX,aY)
  and InRange(aPlayer, 0, gHands.Count - 1) then
    Result := gHands[aPlayer].FogOfWar.CheckTileRevelation(aX, aY) > 0
  else
    LogError('States.FogRevealed', [aX, aY]);
end;


function TKMScriptStates.UnitAt(aX, aY: Word): Integer;
var
  U: TKMUnit;
begin
  Result := UID_NONE;
  if gTerrain.TileInMapCoords(aX,aY) then
  begin
    U := gTerrain.UnitsHitTest(aX, aY);
    if (U <> nil) and not U.IsDeadOrDying then
    begin
      Result := U.UID;
      fIDCache.CacheUnit(U, U.UID); //Improves cache efficiency since U will probably be accessed soon
    end;
  end
  else
    LogError('States.UnitAt', [aX, aY]);
end;


function TKMScriptStates.UnitPositionX(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := -1; //-1 if unit id is invalid
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := U.GetPosition.X;
  end
  else
    LogError('States.UnitX', [aUnitID]);
end;


function TKMScriptStates.UnitPositionY(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := -1; //-1 if unit id is invalid
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := U.GetPosition.Y;
  end
  else
    LogError('States.UnitY', [aUnitID]);
end;


function TKMScriptStates.UnitDead(aUnitID: Integer): Boolean;
var
  U: TKMUnit;
begin
  Result := True;
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := U.IsDeadOrDying;
  end
  else
    LogError('States.UnitDead', [aUnitID]);
end;


function TKMScriptStates.UnitOwner(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := PLAYER_NONE;
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := U.Owner;
  end
  else
    LogError('States.UnitOwner', [aUnitID]);
end;


function TKMScriptStates.UnitDirection(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := -1;//-1 if unit id is invalid
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := Byte(U.Direction) - 1;
  end
  else
    LogError('States.UnitDirection', [aUnitID]);
end;


function TKMScriptStates.UnitType(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := -1; //-1 if unit id is invalid
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := UnitTypeToIndex[U.UnitType];
  end
  else
    LogError('States.UnitType', [aUnitID]);
end;


function TKMScriptStates.UnitHunger(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := -1; //-1 if unit id is invalid
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := Max(U.Condition, 0)*CONDITION_PACE;
  end
  else
    LogError('States.UnitHunger', [aUnitID]);
end;


function TKMScriptStates.UnitCarrying(aUnitID: Integer): Integer;
var
  U: TKMUnit;
begin
  Result := -1; //-1 if unit id is invalid
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if (U <> nil) and (U is TKMUnitSerf) and (TKMUnitSerf(U).Carry in [WARE_MIN..WARE_MAX]) then
      Result := WareTypeToIndex[TKMUnitSerf(U).Carry];
  end
  else
    LogError('States.UnitCarrying', [aUnitID]);
end;


function TKMScriptStates.UnitMaxHunger: Integer;
begin
  Result := UNIT_MAX_CONDITION*CONDITION_PACE;
end;


function TKMScriptStates.UnitLowHunger: Integer;
begin
  Result := UNIT_MIN_CONDITION*CONDITION_PACE;
end;


function TKMScriptStates.GroupAt(aX, aY: Word): Integer;
var
  G: TKMUnitGroup;
begin
  G := gHands.GroupsHitTest(aX, aY);
  if (G <> nil) and not G.IsDead then
  begin
    Result := G.UID;
    fIDCache.CacheGroup(G, G.UID); //Improves cache efficiency since G will probably be accessed soon
  end
  else
    Result := UID_NONE;
end;


function TKMScriptStates.UnitsGroup(aUnitID: Integer): Integer;
var
  U: TKMUnit;
  G: TKMUnitGroup;
begin
  Result := UID_NONE;
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if (U <> nil) and (U is TKMUnitWarrior) then
    begin
      G := gHands[U.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(U));
      if G <> nil then
      begin
        Result := G.UID;
        fIDCache.CacheGroup(G, G.UID); //Improves cache efficiency since G will probably be accessed soon
      end;
    end;
  end
  else
    LogError('States.UnitsGroup', [aUnitID]);
end;


function TKMScriptStates.GroupDead(aGroupID: Integer): Boolean;
var
  G: TKMUnitGroup;
begin
  Result := True;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      Result := G.IsDead;
  end
  else
    LogError('States.GroupDead', [aGroupID]);
end;


function TKMScriptStates.GroupOwner(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  Result := PLAYER_NONE;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      Result := G.Owner;
  end
  else
    LogError('States.GroupOwner', [aGroupID]);
end;


function TKMScriptStates.GroupType(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  Result := -1;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      Result := Byte(G.GroupType);
  end
  else
    LogError('States.GroupType', [aGroupID]);
end;


function TKMScriptStates.GroupMemberCount(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  Result := 0;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      Result := G.Count;
  end
  else
    LogError('States.GroupMemberCount', [aGroupID]);
end;


function TKMScriptStates.GroupColumnCount(aGroupID: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  Result := 0;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      Result := G.UnitsPerRow;
  end
  else
    LogError('States.GroupColumnCount', [aGroupID]);
end;


function TKMScriptStates.GroupMember(aGroupID, aMemberIndex: Integer): Integer;
var
  G: TKMUnitGroup;
begin
  Result := UID_NONE;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
    begin
      if InRange(aMemberIndex, 0, G.Count-1) then
      begin
        Result := G.Members[aMemberIndex].UID;
        //Improves cache efficiency since unit will probably be accessed soon
        fIDCache.CacheUnit(G.Members[aMemberIndex], Result);
      end
      else
        LogError('States.GroupMember', [aGroupID, aMemberIndex]);
    end;
  end
  else
    LogError('States.GroupMember', [aGroupID, aMemberIndex]);
end;


{ TKMScriptActions }
constructor TKMScriptActions.Create(aIDCache: TKMScriptingIdCache);
begin
  inherited Create;
  fIDCache := aIDCache;
end;


procedure TKMScriptActions.LogError(aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  Values: string;
begin
  for I := Low(aValues) to High(aValues) do
    Values := Values + IntToStr(aValues[I]) + IfThen(I <> High(aValues), ', ');
  gLog.AddTime('Mistake in script usage ' + aFuncName + ': ' + Values);
end;


procedure TKMScriptActions.CinematicStart(aPlayer: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
  begin
    gHands[aPlayer].InCinematic := True;
    gGame.GamePlayInterface.CinematicUpdate;
  end
  else
    LogError('Actions.CinematicStart', [aPlayer]);
end;


procedure TKMScriptActions.CinematicEnd(aPlayer: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
  begin
    gHands[aPlayer].InCinematic := False;
    gGame.GamePlayInterface.CinematicUpdate;
  end
  else
    LogError('Actions.CinematicEnd', [aPlayer]);
end;


procedure TKMScriptActions.CinematicPanTo(aPlayer: Byte; X, Y, Duration: Word);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X, Y)
  and gHands[aPlayer].InCinematic then
  begin
    if aPlayer = MySpectator.HandIndex then
      //Duration is in ticks (1/10 sec), viewport wants miliseconds (1/1000 sec)
      gGame.GamePlayInterface.Viewport.PanTo(KMPointF(X, Y), Duration*100);
  end
  else
    LogError('Actions.CinematicPanTo', [aPlayer, X, Y, Duration]);
end;


procedure TKMScriptActions.PlayerDefeat(aPlayer: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Defeat
  else
    LogError('Actions.PlayerDefeat', [aPlayer]);
end;


procedure TKMScriptActions.PlayerShareFog(aPlayer1, aPlayer2: Word; aShare: Boolean);
begin
  if  InRange(aPlayer1, 0, gHands.Count - 1)
  and InRange(aPlayer2, 0, gHands.Count - 1) then
    gHands[aPlayer1].ShareFOW[aPlayer2] := aShare
  else
    LogError('Actions.PlayerShareFog', [aPlayer1, aPlayer2, Byte(aShare)]);
end;


//Sets all player IDs in aVictors to victorious, and all their team members if aTeamVictory is true.
//All other players are set to defeated.
procedure TKMScriptActions.PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);
var
  I, K: Integer;
begin
  //Verify all input parameters
  for I := 0 to Length(aVictors) - 1 do
  if not InRange(aVictors[I], 0, gHands.Count - 1) then
  begin
    LogError('Actions.PlayerWin', [aVictors[I]]);
    Exit;
  end;

  for I := 0 to Length(aVictors) - 1 do
    if gHands[aVictors[I]].Enabled then
    begin
      gHands[aVictors[I]].AI.Victory;
      if aTeamVictory then
        for K := 0 to gHands.Count - 1 do
          if gHands[K].Enabled and (I <> K) and (gHands[aVictors[I]].Alliances[K] = at_Ally) then
            gHands[K].AI.Victory;
    end;

  //All other players get defeated
  for I := 0 to gHands.Count - 1 do
    if gHands[I].Enabled and (gHands[I].AI.WonOrLost = wol_None) then
      gHands[I].AI.Defeat;
end;


procedure TKMScriptActions.PlayerWareDistribution(aPlayer, aWareType, aHouseType, aAmount: Byte);
var
  W: TWareType;
begin
  W := WareIndexToType[aWareType];
  if InRange(aPlayer, 0, gHands.Count - 1) and (W in [wt_Steel, wt_Coal, wt_Wood, wt_Corn])
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)])
  and InRange(aAmount, 0, 5) then
  begin
    gHands[aPlayer].Stats.Ratio[W, HouseIndexToType[aHouseType]] := aAmount;
    gHands[aPlayer].Houses.UpdateResRequest;
  end
  else
    LogError('Actions.PlayerWareDistribution', [aPlayer, aWareType, aHouseType, aAmount]);
end;


procedure TKMScriptActions.PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean);
const
  ALLIED: array [Boolean] of TAllianceType = (at_Enemy, at_Ally);
begin
  //Verify all input parameters
  if InRange(aPlayer1, 0, gHands.Count - 1)
  and InRange(aPlayer2, 0, gHands.Count - 1)
  and (aPlayer1 <> aPlayer2) then
  begin
    gHands[aPlayer1].Alliances[aPlayer2] := ALLIED[aAllied];
    if aAllied then
      gHands[aPlayer2].FogOfWar.SyncFOW(gHands[aPlayer1].FogOfWar);
    if aCompliment then
    begin
      gHands[aPlayer2].Alliances[aPlayer1] := ALLIED[aAllied];
      if aAllied then
        gHands[aPlayer1].FogOfWar.SyncFOW(gHands[aPlayer2].FogOfWar);
    end;
  end
  else
    LogError('Actions.PlayerAllianceChange', [aPlayer1, aPlayer2, Byte(aCompliment), Byte(aAllied)]);
end;


procedure TKMScriptActions.PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1) then
  begin

    gHands[aPlayer].AI.AddDefaultGoals(aBuildings);
  end
  else
    LogError('Actions.PlayerAddDefaultGoals', [aPlayer, Byte(aBuildings)]);
end;


procedure TKMScriptActions.PlayWAV(aPlayer: ShortInt; const aFileName: AnsiString; Volume: Single);
var
  fullFileName: UnicodeString;
begin
  if (aPlayer <> MySpectator.HandIndex) and (aPlayer <> PLAYER_NONE) then Exit;

  fullFileName := ExeDir + Format(SFXPath, [aFileName]);
  //Silently ignore missing files (player might choose to delete annoying sounds from scripts if he likes)
  if not FileExists(fullFileName) then Exit;
  if InRange(Volume, 0, 1) then
    gSoundPlayer.PlayWAVFromScript(fullFileName, KMPoint(0,0), False, Volume)
  else
    LogError('Actions.PlayWAV: ' + UnicodeString(aFileName), []);
end;


procedure TKMScriptActions.PlayWAVAtLocation(aPlayer: ShortInt; const aFileName: AnsiString; Volume: Single; X, Y: Word);
var
  fullFileName: UnicodeString;
begin
  if (aPlayer <> MySpectator.HandIndex) and (aPlayer <> PLAYER_NONE) then Exit;

  fullFileName := ExeDir + Format(SFXPath, [aFileName]);
  //Silently ignore missing files (player might choose to delete annoying sounds from scripts if he likes)
  if not FileExists(fullFileName) then Exit;
  if InRange(Volume, 0, 1) and gTerrain.TileInMapCoords(X,Y) then
    gSoundPlayer.PlayWAVFromScript(fullFileName, KMPoint(X,Y), True, Volume)
  else
    LogError('Actions.PlayWAVAtLocation: ' + UnicodeString(aFileName), [X, Y]);
end;


procedure TKMScriptActions.RemoveField(X, Y :Word);
var
  Pos: TKMPoint;
begin
  Pos := KMPoint(X, Y);
  if gTerrain.TileInMapCoords(X, Y) and (gTerrain.TileIsCornField(Pos) or gTerrain.TileIsWineField(Pos)) then
    gTerrain.RemField(Pos)
  else
    LogError('Actions.RemoveField', [X, Y]);
end;


procedure TKMScriptActions.RemoveRoad(X, Y: Word);
var
  Pos: TKMPoint;
begin
  Pos := KMPoint(X, Y);
  if gTerrain.TileInMapCoords(X, Y) then
    gTerrain.RemRoad(Pos)
  else
    LogError('Actions.RemoveRoad', [X, Y]);
end;


function TKMScriptActions.GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word): Integer;
var
  G: TKMUnitGroup;
begin
  Result := UID_NONE;
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aType in [UnitTypeToIndex[WARRIOR_MIN]..UnitTypeToIndex[WARRIOR_MAX]])
  and gTerrain.TileInMapCoords(X,Y)
  and (TKMDirection(aDir+1) in [dir_N..dir_NW])
  and (aCount > 0)
  and (aColumns > 0) then
  begin
    G := gHands[aPlayer].AddUnitGroup(UnitIndexToType[aType],
                                        KMPoint(X,Y),
                                        TKMDirection(aDir+1),
                                        aColumns,
                                        aCount);
    if G = nil then Exit;
    Result := G.UID;
  end
  else
    LogError('Actions.GiveGroup', [aPlayer, aType, X, Y, aDir, aCount, aColumns]);
end;


function TKMScriptActions.GiveUnit(aPlayer, aType, X, Y, aDir: Word): Integer;
var
  U: TKMUnit;
begin
  Result := UID_NONE;

  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aType in [UnitTypeToIndex[CITIZEN_MIN] .. UnitTypeToIndex[CITIZEN_MAX]])
  and gTerrain.TileInMapCoords(X, Y)
  and (TKMDirection(aDir + 1) in [dir_N .. dir_NW]) then
  begin
    U := gHands[aPlayer].AddUnit(UnitIndexToType[aType], KMPoint(X,Y));
    if U = nil then Exit;
    Result := U.UID;
    U.Direction := TKMDirection(aDir + 1);
    //Make sure the unit is not locked so the script can use commands like UnitOrderWalk.
    //By default newly created units are given SetActionLockedStay
    U.SetActionStay(10, ua_Walk);
  end
  else
    LogError('Actions.GiveUnit', [aPlayer, aType, X, Y, aDir]);
end;


function TKMScriptActions.GiveHouse(aPlayer, aHouseType, X,Y: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := UID_NONE;

  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)])
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    if gTerrain.CanPlaceHouseFromScript(HouseIndexToType[aHouseType], KMPoint(X - gResource.HouseDat[HouseIndexToType[aHouseType]].EntranceOffsetX, Y)) then
    begin
      H := gHands[aPlayer].AddHouse(HouseIndexToType[aHouseType], X, Y, True);
      if H = nil then Exit;
      Result := H.UID;
    end;
  end
  else
    LogError('Actions.GiveHouse', [aPlayer, aHouseType, X, Y]);
end;


procedure TKMScriptActions.AIAutoBuild(aPlayer: Byte; aAuto: Boolean);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Setup.AutoBuild := aAuto
  else
    LogError('Actions.AIAutoBuild', [aPlayer, Byte(aAuto)]);
end;


procedure TKMScriptActions.AIAutoDefence(aPlayer: Byte; aAuto: Boolean);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Setup.AutoDefend := aAuto
  else
    LogError('Actions.AIAutoDefence', [aPlayer, Byte(aAuto)]);
end;


procedure TKMScriptActions.AIAutoRepair(aPlayer: Byte; aAuto: Boolean);
begin
   if InRange(aPlayer, 0, gHands.Count - 1) then
     gHands[aPlayer].AI.Mayor.AutoRepair := aAuto
   else
     LogError('Actions.AIAutoRepair', [aPlayer, Byte(aAuto)]);
end;


procedure TKMScriptActions.AIBuildersLimit(aPlayer, aLimit: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Setup.WorkerCount := aLimit
  else
    LogError('Actions.AIBuildersLimit', [aPlayer, aLimit]);
end;


procedure TKMScriptActions.AIDefencePositionAdd(aPlayer: Byte; X: Integer; Y: Integer; aDir: Byte; aGroupType: Byte; aRadius: Word; aDefType: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (TAIDefencePosType(aDefType) in [adt_FrontLine..adt_BackLine])
  and (TGroupType(aGroupType) in [gt_Melee..gt_Mounted])
  and (TKMDirection(aDir+1) in [dir_N..dir_NW])
  and (gTerrain.TileInMapCoords(X, Y)) then
    gHands[aPlayer].AI.General.DefencePositions.Add(KMPointDir(X, Y, TKMDirection(aDir + 1)), TGroupType(aGroupType), aRadius, TAIDefencePosType(aDefType))
  else
    LogError('Actions.AIDefencePositionAdd', [aPlayer, X, Y, aDir, aGroupType, aRadius, aDefType]);
 end;


procedure TKMScriptActions.AIEquipRate(aPlayer: Byte; aType: Byte; aRate: Word);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    case aType of
      0:    gHands[aPlayer].AI.Setup.EquipRateLeather := aRate;
      1:    gHands[aPlayer].AI.Setup.EquipRateIron := aRate;
      else  LogError('Actions.AIEquipRate, unknown type', [aPlayer, aType, aRate]);
    end
  else
    LogError('Actions.AIEquipRate', [aPlayer, aType, aRate]);
end;


procedure TKMScriptActions.AIGroupsFormationSet(aPlayer, aType: Byte; aCount, aColumns: Word);
var
  gt: TGroupType;
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and InRange(aType, 0, 3)
  and (aCount > 0) and (aColumns > 0) then
  begin
    gt := TGroupType(aType);

    gHands[aPlayer].AI.General.DefencePositions.TroopFormations[gt].NumUnits := aCount;
    gHands[aPlayer].AI.General.DefencePositions.TroopFormations[gt].UnitsPerRow := aColumns;
  end
  else
    LogError('Actions.AIGroupsFormationSet', [aPlayer, aType, aCount, aColumns]);
end;


procedure TKMScriptActions.AIRecruitDelay(aPlayer: Byte; aDelay: Cardinal);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Setup.RecruitDelay := aDelay
  else
    LogError('Actions.AIRecruitDelay', [aPlayer, aDelay]);
end;


procedure TKMScriptActions.AIRecruitLimit(aPlayer, aLimit: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Setup.RecruitCount := aLimit
  else
    LogError('Actions.AIRecruitLimit', [aPlayer, aLimit]);
end;


procedure TKMScriptActions.AISerfsFactor(aPlayer, aLimit: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].AI.Setup.SerfsPerHouse := aLimit
  else
    LogError('Actions.AISerfsFactor', [aPlayer, aLimit]);
end;


procedure TKMScriptActions.AISoldiersLimit(aPlayer: Byte; aLimit: Integer);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aLimit >= -1) then                       //-1 means unlimited; else MaxSoldiers = aLimit
    gHands[aPlayer].AI.Setup.MaxSoldiers := aLimit
  else
    LogError('Actions.AISoldiersLimit', [aPlayer, aLimit]);
end;


function TKMScriptActions.GiveAnimal(aType, X, Y: Word): Integer;
var
  U: TKMUnit;
begin
  Result := UID_NONE;

  //Verify all input parameters
  if (aType in [UnitTypeToIndex[ANIMAL_MIN] .. UnitTypeToIndex[ANIMAL_MAX]])
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    U := gHands.PlayerAnimals.AddUnit(UnitIndexToType[aType], KMPoint(X,Y));
    if U <> nil then
      Result := U.UID;
  end
  else
    LogError('Actions.GiveAnimal', [aType, X, Y]);
end;


//Wares are added to first Store
procedure TKMScriptActions.GiveWares(aPlayer, aType, aCount: Word);
var
  H: TKMHouse;
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and InRange(aCount, 0, High(Word))
  and (aType in [Low(WareIndexToType) .. High(WareIndexToType)]) then
  begin
    H := gHands[aPlayer].FindHouse(ht_Store, 1);
    if H <> nil then
    begin
      H.ResAddToIn(WareIndexToType[aType], aCount);
      gHands[aPlayer].Stats.WareProduced(WareIndexToType[aType], aCount);
    end;
  end
  else
    LogError('Actions.GiveWares', [aPlayer, aType, aCount]);
end;


//Weapons are added to first Barracks
procedure TKMScriptActions.GiveWeapons(aPlayer, aType, aCount: Word);
var
  H: TKMHouse;
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and InRange(aCount, 0, High(Word))
  and (WareIndexToType[aType] in [WARFARE_MIN .. WARFARE_MAX]) then
  begin
    H := gHands[aPlayer].FindHouse(ht_Barracks, 1);
    if H <> nil then
    begin
      H.ResAddToIn(WareIndexToType[aType], aCount);
      gHands[aPlayer].Stats.WareProduced(WareIndexToType[aType], aCount);
    end;
  end
  else
    LogError('Actions.GiveWeapons', [aPlayer, aType, aCount]);
end;


procedure TKMScriptActions.FogRevealCircle(aPlayer, X, Y, aRadius: Word);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X,Y)
  and InRange(aRadius, 0, 255) then
    gHands[aPlayer].FogOfWar.RevealCircle(KMPoint(X, Y), aRadius, FOG_OF_WAR_MAX)
  else
    LogError('Actions.FogRevealCircle', [aPlayer, X, Y, aRadius]);
end;


procedure TKMScriptActions.FogCoverCircle(aPlayer, X, Y, aRadius: Word);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X,Y)
  and InRange(aRadius, 0, 255) then
    gHands[aPlayer].FogOfWar.CoverCircle(KMPoint(X, Y), aRadius)
  else
    LogError('Actions.FogCoverCircle', [aPlayer, X, Y, aRadius]);
end;


procedure TKMScriptActions.FogRevealRect(aPlayer, X1, Y1, X2, Y2: Word);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X1,Y1)
  and gTerrain.TileInMapCoords(X2,Y2) then
    gHands[aPlayer].FogOfWar.RevealRect(KMPoint(X1, Y1), KMPoint(X2, Y2), FOG_OF_WAR_MAX)
  else
    LogError('Actions.FogRevealRect', [aPlayer, X1, Y1, X2, Y2]);
end;


procedure TKMScriptActions.FogCoverRect(aPlayer, X1, Y1, X2, Y2: Word);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X1,Y1)
  and gTerrain.TileInMapCoords(X2,Y2) then
    gHands[aPlayer].FogOfWar.CoverRect(KMPoint(X1, Y1), KMPoint(X2, Y2))
  else
    LogError('Actions.FogCoverRect', [aPlayer, X1, Y1, X2, Y2]);
end;


procedure TKMScriptActions.FogRevealAll(aPlayer: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].FogOfWar.RevealEverything
  else
    LogError('Actions.FogRevealAll', [aPlayer]);
end;


procedure TKMScriptActions.FogCoverAll(aPlayer: Byte);
begin
  if InRange(aPlayer, 0, gHands.Count - 1) then
    gHands[aPlayer].FogOfWar.CoverEverything
  else
    LogError('Actions.FogCoverAll', [aPlayer]);
end;


//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsg(aPlayer: Shortint; aText: AnsiString);
begin
  if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
    gGame.ShowMessage(mkText, UnicodeString(aText), KMPoint(0,0));
end;


//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsgFormatted(aPlayer: Shortint; aText: AnsiString; Params: array of const);
begin
  if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
    gGame.ShowMessageFormatted(mkText, UnicodeString(aText), KMPoint(0,0), Params);
end;


//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsgGoto(aPlayer: Shortint; aX, aY: Word; aText: AnsiString);
begin
  if gTerrain.TileInMapCoords(aX, aY) then
  begin
    if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
      gGame.ShowMessage(mkText, UnicodeString(aText), KMPoint(aX,aY));
  end
  else
    LogError('Actions.ShowMsgGoto', [aPlayer, aX, aY]);
end;


//Input text is ANSI with libx codes to substitute
procedure TKMScriptActions.ShowMsgGotoFormatted(aPlayer: Shortint; aX, aY: Word; aText: AnsiString; Params: array of const);
begin
  if gTerrain.TileInMapCoords(aX, aY) then
  begin
    if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
      gGame.ShowMessageFormatted(mkText, UnicodeString(aText), KMPoint(aX,aY), Params);
  end
  else
    LogError('Actions.ShowMsgGotoFormatted', [aPlayer, aX, aY]);
end;


procedure TKMScriptActions.HouseUnlock(aPlayer, aHouseType: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)]) then
    gHands[aPlayer].Stats.HouseGranted[HouseIndexToType[aHouseType]] := True
  else
    LogError('Actions.HouseUnlock', [aPlayer, aHouseType]);
end;


procedure TKMScriptActions.HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)]) then
    gHands[aPlayer].Stats.HouseBlocked[HouseIndexToType[aHouseType]] := not aAllowed
  else
    LogError('Actions.HouseAllow', [aPlayer, aHouseType, Byte(aAllowed)]);
end;


procedure TKMScriptActions.SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aResType in [Low(WareIndexToType)..High(WareIndexToType)]) then
    gHands[aPlayer].Stats.AllowToTrade[WareIndexToType[aResType]] := aAllowed
  else
    LogError('Actions.SetTradeAllowed', [aPlayer, aResType, Byte(aAllowed)]);
end;


procedure TKMScriptActions.HouseAddDamage(aHouseID: Integer; aDamage: Word);
var
  H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      H.AddDamage(aDamage, nil); //We don't know who did the damage
  end
  else
    LogError('Actions.HouseAddDamage', [aHouseID, aDamage]);
end;


procedure TKMScriptActions.HouseAddRepair(aHouseID: Integer; aRepair: Word);
var
  H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      H.AddRepair(aRepair);
  end
  else
    LogError('Actions.HouseAddRepair', [aHouseID, aRepair]);
end;


procedure TKMScriptActions.HouseDestroy(aHouseID: Integer; aSilent: Boolean);
var
  H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      H.DemolishHouse(PLAYER_NONE, aSilent);
  end
  else
    LogError('Actions.HouseDestroy', [aHouseID]);
end;


procedure TKMScriptActions.HouseAddWaresTo(aHouseID: Integer; aType, aCount: Word);
var
  H: TKMHouse;
  Res: TWareType;
begin
  Res := WareIndexToType[aType];
  if (aHouseID > 0) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      if H.ResCanAddToIn(Res) then
      begin
        H.ResAddToIn(Res, aCount, True);
        gHands[H.Owner].Stats.WareProduced(Res, aCount);
      end
      else
        LogError('Actions.HouseAddWaresTo wrong ware type', [aHouseID, aType, aCount]);
    //Silently ignore if house doesn't exist
  end
  else
    LogError('Actions.HouseAddWaresTo', [aHouseID, aType, aCount]);
end;


procedure TKMScriptActions.HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
var H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) then
      H.BuildingRepair := aRepairEnabled;
  end
  else
    LogError('Actions.HouseRepairEnable', [aHouseID, Byte(aRepairEnabled)]);
end;


procedure TKMScriptActions.HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
var H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) then
      H.WareDelivery := not aDeliveryBlocked;
  end
  else
    LogError('Actions.HouseDeliveryBlock', [aHouseID, Byte(aDeliveryBlocked)]);
end;


procedure TKMScriptActions.HouseDisableUnoccupiedMessage(aHouseID: Integer; aDisabled: Boolean);
var
  H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) then
      H.DisableUnoccupiedMessage := aDisabled;
  end
  else
    LogError('Actions.HouseDisableUnoccupiedMessage', [aHouseID, Byte(aDisabled)]);
end;


procedure TKMScriptActions.HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
const
  CHOP_ONLY: array [Boolean] of TWoodcutterMode = (wcm_ChopAndPlant, wcm_Chop);
var
  H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H is TKMHouseWoodcutters then
      TKMHouseWoodcutters(H).WoodcutterMode := CHOP_ONLY[aChopOnly];
  end
  else
    LogError('Actions.HouseWoodcutterChopOnly', [aHouseID, Byte(aChopOnly)]);
end;


procedure TKMScriptActions.HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean);
var
  H: TKMHouse;
  Res: TWareType;
begin
  Res := WareIndexToType[aWareType];
  if (aHouseID > 0) and (Res in [WARE_MIN..WARE_MAX]) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H is TKMHouseStore then
      TKMHouseStore(H).NotAcceptFlag[Res] := aBlocked;
    if (H is TKMHouseBarracks) and (Res in [WARFARE_MIN..WARFARE_MAX]) then
      TKMHouseBarracks(H).NotAcceptFlag[Res] := aBlocked;
  end
  else
    LogError('Actions.HouseWareBlock', [aHouseID, aWareType, Byte(aBlocked)]);
end;


procedure TKMScriptActions.HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);
var
  H: TKMHouse;
  Res: TWareType;
  I: Integer;
begin
  Res := WareIndexToType[aWareType];
  if (aHouseID > 0) and (Res in [WARE_MIN..WARE_MAX]) and InRange(aAmount, 0, MAX_WARES_ORDER) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) then
      for I := 1 to 4 do
        if gResource.HouseDat[H.HouseType].ResOutput[I] = Res then
        begin
          H.ResOrder[I] := aAmount;
          Exit;
        end;
  end
  else
    LogError('Actions.HouseWeaponsOrderSet', [aHouseID, aWareType, aAmount]);
end;


procedure TKMScriptActions.HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer);
var
  H: TKMHouse;
begin
  if (aHouseID > 0) and InRange(QueueIndex, 0, 5) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) and (H is TKMHouseSchool) then
      TKMHouseSchool(H).RemUnitFromQueue(QueueIndex);
  end
  else
    LogError('Actions.HouseSchoolQueueRemove', [aHouseID, QueueIndex]);
end;


function TKMScriptActions.HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := 0;
  if (aHouseID > 0)
  and (aUnitType in [UnitTypeToIndex[CITIZEN_MIN]..UnitTypeToIndex[CITIZEN_MAX]]) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) and (H is TKMHouseSchool) then
      Result := TKMHouseSchool(H).AddUnitToQueue(UnitIndexToType[aUnitType], aCount);
  end
  else
    LogError('Actions.HouseSchoolQueueAdd', [aHouseID, aUnitType]);
end;


function TKMScriptActions.HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
var
  H: TKMHouse;
begin
  Result := 0;
  if (aHouseID > 0)
  and (aUnitType in [UnitTypeToIndex[WARRIOR_EQUIPABLE_MIN]..UnitTypeToIndex[WARRIOR_EQUIPABLE_MAX]]) then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if (H <> nil) and (H is TKMHouseBarracks) then
      Result := TKMHouseBarracks(H).Equip(UnitIndexToType[aUnitType], aCount);
  end
  else
    LogError('Actions.HouseBarracksEquip', [aHouseID, aUnitType]);
end;


procedure TKMScriptActions.OverlayTextSet(aPlayer: Shortint; aText: AnsiString);
begin
  //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
  if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
    gGame.ShowOverlay(UnicodeString(aText));
end;


procedure TKMScriptActions.OverlayTextSetFormatted(aPlayer: Shortint; aText: AnsiString; Params: array of const);
begin
  //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
  if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
    gGame.ShowOverlayFormatted(UnicodeString(aText), Params);
end;


procedure TKMScriptActions.OverlayTextAppend(aPlayer: Shortint; aText: AnsiString);
begin
  //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
  if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
    gGame.OverlayAppend(UnicodeString(aText));
end;


procedure TKMScriptActions.OverlayTextAppendFormatted(aPlayer: Shortint; aText: AnsiString; Params: array of const);
begin
  //Text from script should be only ANSI Latin, but UI is Unicode, so we switch it
  if (aPlayer = MySpectator.HandIndex) or (aPlayer = PLAYER_NONE) then
    gGame.OverlayAppendFormatted(UnicodeString(aText), Params);
end;


function TKMScriptActions.PlanAddRoad(aPlayer, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ft_Road) then
    begin
      Result := True;
      gHands[aPlayer].BuildList.FieldworksList.AddField(KMPoint(X, Y), ft_Road);
    end;
  end
  else
    LogError('Actions.PlanAddRoad', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanAddField(aPlayer, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ft_Corn) then
    begin
      Result := True;
      gHands[aPlayer].BuildList.FieldworksList.AddField(KMPoint(X, Y), ft_Corn);
    end;
  end
  else
    LogError('Actions.PlanAddField', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanAddWinefield(aPlayer, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if gHands[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ft_Wine) then
    begin
      Result := True;
      gHands[aPlayer].BuildList.FieldworksList.AddField(KMPoint(X, Y), ft_Wine);
    end;
  end
  else
    LogError('Actions.PlanAddWinefield', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanRemove(aPlayer, X, Y: Word): Boolean;
var
  HT: THouseType;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    HT := gHands[aPlayer].BuildList.HousePlanList.GetPlan(KMPoint(X, Y));
    if HT <> ht_None then
    begin
      gHands[aPlayer].BuildList.HousePlanList.RemPlan(KMPoint(X, Y));
      gHands[aPlayer].Stats.HousePlanRemoved(HT);
      Result := True;
    end;
    if gHands[aPlayer].BuildList.FieldworksList.HasField(KMPoint(X, Y)) <> ft_None then
    begin
      gHands[aPlayer].BuildList.FieldworksList.RemFieldPlan(KMPoint(X, Y));
      Result := True;
    end;
  end
  else
    LogError('Actions.PlanRemove', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aHouseType in [Low(HouseIndexToType)..High(HouseIndexToType)])
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if gHands[aPlayer].CanAddHousePlan(KMPoint(X, Y), HouseIndexToType[aHouseType]) then
    begin
      Result := True;
      gHands[aPlayer].AddHousePlan(HouseIndexToType[aHouseType], KMPoint(X, Y));
    end;
  end
  else
    LogError('Actions.PlanAddHouse', [aPlayer, aHouseType, X, Y]);
end;


procedure TKMScriptActions.UnitBlock(aPlayer: Byte; aType: Word; aBlock: Boolean);
begin
  if InRange(aPlayer, 0, gHands.Count - 1)
  and (aType in [Low(UnitIndexToType) .. High(UnitIndexToType)]) then
    gHands[aPlayer].Stats.UnitBlocked[UnitIndexToType[aType]] := aBlock
  else
    LogError('Actions.UnitBlock', [aPlayer, aType, Byte(aBlock)]);
end;


procedure TKMScriptActions.UnitHungerSet(aUnitID, aHungerLevel: Integer);
var
  U: TKMUnit;
begin
  aHungerLevel := Round(aHungerLevel / CONDITION_PACE);
  if (aUnitID > 0) and InRange(aHungerLevel, 0, UNIT_MAX_CONDITION) then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      U.Condition := aHungerLevel;
  end
  else
    LogError('Actions.UnitHungerSet', [aUnitID, aHungerLevel]);
end;


function TKMScriptActions.UnitDirectionSet(aUnitID, aDirection: Integer): Boolean;
var
  U: TKMUnit;
begin
  Result := False;
  if (aUnitID > 0) and (TKMDirection(aDirection+1) in [dir_N..dir_NW]) then
  begin
    U := fIDCache.GetUnit(aUnitID);
    //Can only make idle units outside houses change direction so we don't mess up tasks and cause crashes
    if (U <> nil) and U.IsIdle and U.Visible then
    begin
      Result := True;
      U.Direction := TKMDirection(aDirection+1);
    end;
  end
  else
    LogError('Actions.UnitDirectionSet', [aUnitID, aDirection]);
end;


function TKMScriptActions.UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean;
var
  U: TKMUnit;
begin
  Result := False;

  if (aUnitID > 0) and gTerrain.TileInMapCoords(X, Y) then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U = nil then Exit; //Unit could have long died, or never existed

    //Animals cant be ordered to walk, they use Steering instead
    if (U.UnitType in [ANIMAL_MIN..ANIMAL_MAX]) then
      LogError('Actions.UnitOrderWalk is not supported for animals', [aUnitID, X, Y])
    else
      //Can only make idle or units in houses walk so we don't mess up tasks and cause crashes
      if U.IsIdle and U.Visible then
      begin
        Result := True;
        U.SetActionWalk(KMPoint(X,Y), ua_Walk, 0, nil, nil);
      end;
  end
  else
    LogError('Actions.UnitOrderWalk', [aUnitID, X, Y]);
end;


procedure TKMScriptActions.UnitKill(aUnitID: Integer; aSilent: Boolean);
var
  U: TKMUnit;
begin
  if (aUnitID > 0) then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      //Force delay to let the unit choose when to die, because this could be called in the middle of an event
      U.KillUnit(PLAYER_NONE, not aSilent, True);
  end
  else
    LogError('Actions.UnitKill', [aUnitID]);
end;


procedure TKMScriptActions.GroupDisableHungryMessage(aGroupID: Integer; aDisable: Boolean);
var
  G: TKMUnitGroup;
begin
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      G.DisableHungerMessage := aDisable;
  end
  else
    LogError('Actions.GroupDisableHungryMessage', [aGroupID, Byte(aDisable)]);
end;


procedure TKMScriptActions.GroupHungerSet(aGroupID, aHungerLevel: Integer);
var
  G: TKMUnitGroup;
  I: Integer;
begin
  aHungerLevel := Round(aHungerLevel / CONDITION_PACE);
  if (aGroupID > 0) and InRange(aHungerLevel, 0, UNIT_MAX_CONDITION) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      for I := 0 to G.Count - 1 do
        if (G.Members[I] <> nil) and (not G.Members[I].IsDeadOrDying) then
          G.Members[I].Condition := aHungerLevel;
  end
  else
    LogError('Actions.GroupHungerSet', [aGroupID, aHungerLevel]);
end;


procedure TKMScriptActions.GroupKillAll(aGroupID: Integer; aSilent: Boolean);
var
  G: TKMUnitGroup;
  I: Integer;
begin
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      for I := G.Count - 1 downto 0 do
        G.Members[I].KillUnit(PLAYER_NONE, not aSilent, True);
  end
  else
    LogError('Actions.GroupKillAll', [aGroupID]);
end;


procedure TKMScriptActions.GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word);
var
  G: TKMUnitGroup;
begin
  if (aGroupID > 0)
  and gTerrain.TileInMapCoords(X, Y)
  and (TKMDirection(aDirection + 1) in [dir_N..dir_NW]) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if (G <> nil) and G.CanWalkTo(KMPoint(X,Y), 0) then
      G.OrderWalk(KMPoint(X,Y), True, TKMDirection(aDirection+1));
  end
  else
    LogError('Actions.GroupOrderWalk', [aGroupID, X, Y, aDirection]);
end;


procedure TKMScriptActions.GroupOrderAttackHouse(aGroupID, aHouseID: Integer);
var
  G: TKMUnitGroup;
  H: TKMHouse;
begin
  if (aGroupID > 0) and (aHouseID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    H := fIDCache.GetHouse(aHouseID);
    if (G <> nil) and (H <> nil) then
      G.OrderAttackHouse(H, True);
  end
  else
    LogError('Actions.GroupOrderAttackHouse', [aGroupID, aHouseID]);
end;


procedure TKMScriptActions.GroupOrderAttackUnit(aGroupID, aUnitID: Integer);
var
  G: TKMUnitGroup;
  U: TKMUnit;
begin
  if (aGroupID > 0) and (aUnitID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    U := fIDCache.GetUnit(aUnitID);

    //Player can not attack animals
    if (G <> nil) and (U <> nil) and (U.Owner <> PLAYER_ANIMAL) then
      G.OrderAttackUnit(U, True);
  end
  else
    LogError('Actions.GroupOrderAttackUnit', [aGroupID, aUnitID]);
end;


procedure TKMScriptActions.GroupOrderFood(aGroupID: Integer);
var
  G: TKMUnitGroup;
begin
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if (G <> nil) then
      G.OrderFood(True);
  end
  else
    LogError('Actions.GroupOrderFood', [aGroupID]);
end;


procedure TKMScriptActions.GroupOrderStorm(aGroupID: Integer);
var
  G: TKMUnitGroup;
begin
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if (G <> nil) and (G.GroupType = gt_Melee) then
      G.OrderStorm(True);
  end
  else
    LogError('Actions.GroupOrderStorm', [aGroupID]);
end;


procedure TKMScriptActions.GroupOrderHalt(aGroupID: Integer);
var
  G: TKMUnitGroup;
begin
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if (G <> nil) then
      G.OrderHalt(True);
  end
  else
    LogError('Actions.GroupOrderHalt', [aGroupID]);
end;


procedure TKMScriptActions.GroupOrderLink(aGroupID, aDestGroupID: Integer);
var
  G, G2: TKMUnitGroup;
begin
  if (aGroupID > 0) and (aDestGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    G2 := fIDCache.GetGroup(aDestGroupID);
    if (G <> nil) and (G2 <> nil) and (G.Owner = G2.Owner) then  //Check group owners to prevent "DNA Modifications" ;D
      G.OrderLinkTo(G2, True);
  end
  else
    LogError('Actions.GroupOrderLink', [aGroupID, aDestGroupID]);
end;


function TKMScriptActions.GroupOrderSplit(aGroupID: Integer): Integer;
var
  G, G2: TKMUnitGroup;
begin
  Result := UID_NONE;
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if (G <> nil) then
    begin
      G2 := G.OrderSplit(True);
      if G2 <> nil then
        Result := G2.UID;
    end;
  end
  else
    LogError('Actions.GroupOrderSplit', [aGroupID]);
end;


procedure TKMScriptActions.GroupSetFormation(aGroupID: Integer; aNumColumns: Byte);
var
  G: TKMUnitGroup;
begin
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      G.UnitsPerRow := aNumColumns;
  end
  else
    LogError('Actions.GroupSetFormation', [aGroupID, aNumColumns]);
end;


end.