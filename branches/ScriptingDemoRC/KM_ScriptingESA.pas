unit KM_ScriptingESA;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, SysUtils, StrUtils,
  KM_CommonTypes, KM_Defaults, KM_Points, KM_Houses, KM_ScriptingIdCache, KM_Units, KM_UnitGroups;


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
  TKMScriptStates = class
  private
    fIDCache: TKMScriptingIdCache;
    procedure LogError(aFuncName: string; const aValues: array of Integer);
  public
    constructor Create(aIDCache: TKMScriptingIdCache);
    function GameTime: Cardinal;
    function PeaceTime: Cardinal;
    function KaMRandom: Single;
    function KaMRandomI(aMax: Integer): Integer;
    function Text(aIndex: Word): AnsiString;
    function TextFormatted(aIndex: Word; const Args: array of const): AnsiString;

    function FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean;

    function GroupAt(aX, aY: Word): Integer;
    function GroupColumnCount(aGroupID: Integer): Integer;
    function GroupDead(aGroupID: Integer): Boolean;
    function GroupMember(aGroupID, aMemberIndex: Integer): Integer;
    function GroupMemberCount(aGroupID: Integer): Integer;
    function GroupOwner(aGroupID: Integer): Integer;

    function HouseAt(aX, aY: Word): Integer;
    function HouseDamage(aHouseID: Integer): Integer;
    function HouseDeliveryBlocked(aHouseID: Integer): Boolean;
    function HouseDestroyed(aHouseID: Integer): Boolean;
    function HouseHasOccupant(aHouseID: Integer): Boolean;
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

    function PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean;
    function PlayerDefeated(aPlayer: Byte): Boolean;
    function PlayerEnabled(aPlayer: Byte): Boolean;
    function PlayerGetAllUnits(aPlayer: Byte): TIntegerArray;
    function PlayerGetAllHouses(aPlayer: Byte): TIntegerArray;
    function PlayerGetAllGroups(aPlayer: Byte): TIntegerArray;
    function PlayerName(aPlayer: Byte): AnsiString;
    function PlayerColorText(aPlayer: Byte): AnsiString;
    function PlayerVictorious(aPlayer: Byte): Boolean;

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
    function ValidSoundFileName(aFileName: AnsiString): Boolean;
    function ParseTextMarkup(const aText: AnsiString): AnsiString;
    procedure LogError(aFuncName: string; const aValues: array of Integer);
  public
    SFXPath: string;  //Relative to EXE (safe to use in Save, cos it is the same for all MP players)
    constructor Create(aIDCache: TKMScriptingIdCache);

    function  GiveAnimal(aType, X,Y: Word): Integer;
    function  GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word): Integer;
    function  GiveHouse(aPlayer, aHouseType, X,Y: Integer): Integer;
    function  GiveUnit(aPlayer, aType, X,Y, aDir: Word): Integer;
    procedure GiveWares(aPlayer, aType, aCount: Word);
    procedure GiveWeapons(aPlayer, aType, aCount: Word);

    procedure FogCoverAll(aPlayer: Byte);
    procedure FogCoverCircle(aPlayer, X, Y, aRadius: Word);
    procedure FogRevealAll(aPlayer: Byte);
    procedure FogRevealCircle(aPlayer, X, Y, aRadius: Word);

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
    procedure HouseAddWaresTo(aHouseID: Integer; aType, aCount: Word);
    procedure HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean);
    function  HouseBarracksEquip(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseDestroy(aHouseID: Integer; aSilent: Boolean);
    procedure HouseDeliveryBlock(aHouseID: Integer; aDeliveryBlocked: Boolean);
    procedure HouseRepairEnable(aHouseID: Integer; aRepairEnabled: Boolean);
    function  HouseSchoolQueueAdd(aHouseID: Integer; aUnitType: Integer; aCount: Integer): Integer;
    procedure HouseSchoolQueueRemove(aHouseID, QueueIndex: Integer);
    procedure HouseUnlock(aPlayer, aHouseType: Word);
    procedure HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
    procedure HouseWareBlock(aHouseID, aWareType: Integer; aBlocked: Boolean);
    procedure HouseWeaponsOrderSet(aHouseID, aWareType, aAmount: Integer);

    function PlanAddField(aPlayer, X, Y: Word): Boolean;
    function PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean;
    function PlanAddRoad(aPlayer, X, Y: Word): Boolean;
    function PlanAddWinefield(aPlayer, X, Y: Word): Boolean;

    procedure PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean);
    procedure PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean);
    procedure PlayerDefeat(aPlayer: Word);
    procedure PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);
    
    procedure PlayWAV(aPlayer: Word; const aFileName: AnsiString; Volume: Single);
    procedure PlayWAVAtLocation(aPlayer: Word; const aFileName: AnsiString; Volume: Single; X, Y: Word);

    procedure SetOverlayText(aPlayer: Word; aText: AnsiString);
    procedure SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean);
    procedure ShowMsg(aPlayer: Word; aText: AnsiString);

    function  UnitDirectionSet(aUnitID, aDirection: Integer): Boolean;
    procedure UnitHungerSet(aUnitID, aHungerLevel: Integer);
    procedure UnitKill(aUnitID: Integer; aSilent: Boolean);
    function  UnitOrderWalk(aUnitID: Integer; X, Y: Word): Boolean;
  end;


implementation
uses KM_AI, KM_Terrain, KM_Game, KM_FogOfWar, KM_PlayersCollection, KM_Units_Warrior,
  KM_HouseBarracks, KM_TextLibrary, KM_ResourceUnit, KM_ResourceWares, KM_ResourceHouse,
  KM_Log, KM_Utils, KM_Resource, KM_UnitTaskSelfTrain, KM_Sound;


  //We need to check all input parameters as could be wildly off range due to
  //mistakes in scripts. In that case we have two options:
  // - skip silently and log
  // - report to player

{ TKMScriptStates }
constructor TKMScriptStates.Create(aIDCache: TKMScriptingIdCache);
begin
  Inherited Create;
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


function TKMScriptStates.StatArmyCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Stats.GetArmyCount
  else
  begin
    Result := 0;
    LogError('States.StatArmyCount', [aPlayer]);
  end;
end;


function TKMScriptStates.StatCitizenCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Stats.GetCitizensCount
  else
  begin
    Result := 0;
    LogError('States.StatCitizenCount', [aPlayer]);
  end;
end;


function TKMScriptStates.GameTime: Cardinal;
begin
  Result := fGame.GameTickCount;
end;


function TKMScriptStates.PeaceTime: Cardinal;
begin
  Result := 600*fGame.GameOptions.Peacetime;
end;


function TKMScriptStates.PlayerAllianceCheck(aPlayer1, aPlayer2: Byte): Boolean;
begin
  if  InRange(aPlayer1, 0, fPlayers.Count - 1)
  and InRange(aPlayer2, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer1].Alliances[aPlayer2] = at_Ally
  else
  begin
    Result := False;
    LogError('States.PlayerAllianceCheck', [aPlayer1, aPlayer2]);
  end;
end;


function TKMScriptStates.StatHouseTypeCount(aPlayer, aHouseType: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aHouseType in [Low(HouseIndexToType)..High(HouseIndexToType)])
  then
    Result := fPlayers[aPlayer].Stats.GetHouseQty(HouseIndexToType[aHouseType])
  else
  begin
    Result := 0;
    LogError('States.StatHouseTypeCount', [aPlayer, aHouseType]);
  end;
end;


function TKMScriptStates.StatPlayerCount: Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to fPlayers.Count - 1 do
    if fPlayers[I].Enabled then
      Inc(Result);
end;


function TKMScriptStates.PlayerDefeated(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := (fPlayers[aPlayer].AI.WonOrLost = wol_Lost)
  else
  begin
    Result := False;
    LogError('States.PlayerDefeated', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerVictorious(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := (fPlayers[aPlayer].AI.WonOrLost = wol_Won)
  else
  begin
    Result := False;
    LogError('States.PlayerVictorious', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerGetAllUnits(aPlayer: Byte): TIntegerArray;
var
  I, UnitCount: Integer;
  U: TKMUnit;
begin
  SetLength(Result, 0);

  if InRange(aPlayer, 0, fPlayers.Count - 1) then
  begin
    UnitCount := 0;

    //Allocate max required space
    SetLength(Result, fPlayers[aPlayer].Units.Count);
    for I := 0 to fPlayers[aPlayer].Units.Count - 1 do
    begin
      U := fPlayers[aPlayer].Units[I];
      //Skip units in training, they can't be disturbed until they are finished training
      if U.IsDead or (U.UnitTask is TTaskSelfTrain) then Continue;
      Result[UnitCount] := U.ID;
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

  if InRange(aPlayer, 0, fPlayers.Count - 1) then
  begin
    HouseCount := 0;

    //Allocate max required space
    SetLength(Result, fPlayers[aPlayer].Houses.Count);
    for I := 0 to fPlayers[aPlayer].Houses.Count - 1 do
    begin
      H := fPlayers[aPlayer].Houses[I];
      if H.IsDestroyed then Continue;
      Result[HouseCount] := H.ID;
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

  if InRange(aPlayer, 0, fPlayers.Count - 1) then
  begin
    GroupCount := 0;

    //Allocate max required space
    SetLength(Result, fPlayers[aPlayer].UnitGroups.Count);
    for I := 0 to fPlayers[aPlayer].UnitGroups.Count - 1 do
    begin
      G := fPlayers[aPlayer].UnitGroups[I];
      if G.IsDead then Continue;
      Result[GroupCount] := G.ID;
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


function TKMScriptStates.StatUnitCount(aPlayer: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Stats.GetUnitQty(ut_Any)
  else
  begin
    Result := 0;
    LogError('States.StatUnitCount', [aPlayer]);
  end;
end;


function TKMScriptStates.StatUnitTypeCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := fPlayers[aPlayer].Stats.GetUnitQty(UnitIndexToType[aUnitType])
  else
  begin
    Result := 0;
    LogError('States.StatUnitTypeCount', [aPlayer, aUnitType]);
  end;
end;


function TKMScriptStates.StatUnitKilledCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := fPlayers[aPlayer].Stats.GetUnitKilledQty(UnitIndexToType[aUnitType])
  else
  begin
    Result := 0;
    LogError('States.StatUnitKilledCount', [aPlayer, aUnitType]);
  end;
end;


function TKMScriptStates.StatUnitLostCount(aPlayer, aUnitType: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aUnitType in [Low(UnitIndexToType)..High(UnitIndexToType)])
  then
    Result := fPlayers[aPlayer].Stats.GetUnitLostQty(UnitIndexToType[aUnitType])
  else
  begin
    Result := 0;
    LogError('States.StatUnitLostCount', [aPlayer, aUnitType]);
  end;
end;


function TKMScriptStates.StatResourceProducedCount(aPlayer, aResType: Byte): Integer;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aResType in [Low(WareIndexToType)..High(WareIndexToType)])
  then
    Result := fPlayers[aPlayer].Stats.GetWaresProduced(WareIndexToType[aResType])
  else
  begin
    Result := 0;
    LogError('States.StatResourceProducedCount', [aPlayer, aResType]);
  end;
end;


function TKMScriptStates.PlayerName(aPlayer: Byte): AnsiString;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].PlayerName
  else
  begin
    Result := '';
    LogError('States.PlayerName', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerColorText(aPlayer: Byte): AnsiString;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := Format('%.6x', [FlagColorToTextColor(fPlayers[aPlayer].FlagColor) and $FFFFFF])
  else
  begin
    Result := '';
    LogError('States.PlayerColorText', [aPlayer]);
  end;
end;


function TKMScriptStates.PlayerEnabled(aPlayer: Byte): Boolean;
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].Enabled
  else
  begin
    Result := False;
    LogError('States.PlayerEnabled', [aPlayer]);
  end;
end;


function TKMScriptStates.HouseAt(aX, aY: Word): Integer;
var H: TKMHouse;
begin
  Result := -1;
  if gTerrain.TileInMapCoords(aX,aY) then
  begin
    H := fPlayers.HousesHitTest(aX, aY);
    if (H <> nil) and not H.IsDestroyed then
    begin
      Result := H.ID;
      fIDCache.CacheHouse(H, H.ID); //Improves cache efficiency since H will probably be accessed soon
    end;
  end
  else
    LogError('States.HouseAt', [aX, aY]);
end;


function TKMScriptStates.HousePositionX(aHouseID: Integer): Integer;
var H: TKMHouse;
begin
  Result := -1;
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
var H: TKMHouse;
begin
  Result := -1;
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
var H: TKMHouse;
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


function TKMScriptStates.HouseOwner(aHouseID: Integer): Integer;
var H: TKMHouse;
begin
  Result := -1;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.Owner;
  end
  else
    LogError('States.HouseOwner', [aHouseID]);
end;


function TKMScriptStates.HouseType(aHouseID: Integer): Integer;
var H: TKMHouse;
begin
  Result := -1;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := HouseTypeToIndex[H.HouseType]-1;
  end
  else
    LogError('States.HouseType', [aHouseID]);
end;


function TKMScriptStates.HouseSchoolQueue(aHouseID, QueueIndex: Integer): Integer;
var H: TKMHouse;
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
        if fResource.HouseDat[H.HouseType].ResOutput[I] = Res then
        begin
          Result := H.ResOrder[I];
          Exit;
        end;
  end
  else
    LogError('States.HouseWeaponsOrdered', [aHouseID, aWareType]);
end;


function TKMScriptStates.HouseWoodcutterChopOnly(aHouseID: Integer): Boolean;
var H: TKMHouse;
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
var H: TKMHouse;
begin
  Result := -1;
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
var H: TKMHouse;
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
var H: TKMHouse;
begin
  Result := True;
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      Result := H.WareDelivery;
  end
  else
    LogError('States.HouseDeliveryBlocked', [aHouseID]);
end;


function TKMScriptStates.HouseResourceAmount(aHouseID, aResource: Integer): Integer;
var
  H: TKMHouse;
  Res: TWareType;
begin
  Result := -1;
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
var H: TKMHouse;
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


function TKMScriptStates.KaMRandom: Single;
begin
  Result := KM_Utils.KaMRandom;
end;


function TKMScriptStates.KaMRandomI(aMax:Integer): Integer;
begin
  //No parameters to check, any integer is fine (even negative)
  Result := KM_Utils.KaMRandom(aMax);
end;


function TKMScriptStates.Text(aIndex: Word): AnsiString;
begin
  Result := fTextLibrary.GetMissionString(aIndex);
end;


function TKMScriptStates.TextFormatted(aIndex: Word; const Args: array of const): AnsiString;
begin
  Result := Format(fTextLibrary.GetMissionString(aIndex), Args);
end;


function TKMScriptStates.FogRevealed(aPlayer: Byte; aX, aY: Word): Boolean;
begin
  Result := False;
  if gTerrain.TileInMapCoords(aX,aY)
  and InRange(aPlayer, 0, fPlayers.Count - 1) then
    Result := fPlayers[aPlayer].FogOfWar.CheckTileRevelation(aX, aY) > 0
  else
    LogError('States.FogRevealed', [aX, aY]);
end;


function TKMScriptStates.UnitAt(aX, aY: Word): Integer;
var U: TKMUnit;
begin
  Result := -1;
  if gTerrain.TileInMapCoords(aX,aY) then
  begin
    U := gTerrain.UnitsHitTest(aX, aY);
    if (U <> nil) and not U.IsDead then
    begin
      Result := U.ID;
      fIDCache.CacheUnit(U, U.ID); //Improves cache efficiency since U will probably be accessed soon
    end;
  end
  else
    LogError('States.UnitAt', [aX, aY]);
end;


function TKMScriptStates.UnitPositionX(aUnitID: Integer): Integer;
var U: TKMUnit;
begin
  Result := -1;
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
var U: TKMUnit;
begin
  Result := -1;
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
var U: TKMUnit;
begin
  Result := True;
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := U.IsDead;
  end
  else
    LogError('States.UnitDead', [aUnitID]);
end;


function TKMScriptStates.UnitOwner(aUnitID: Integer): Integer;
var U: TKMUnit;
begin
  Result := -1;
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
var U: TKMUnit;
begin
  Result := -1;
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      Result := Byte(U.Direction)-1;
  end
  else
    LogError('States.UnitDirection', [aUnitID]);
end;


function TKMScriptStates.UnitType(aUnitID: Integer): Integer;
var U: TKMUnit;
begin
  Result := -1;
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
var U: TKMUnit;
begin
  Result := -1;
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
var U: TKMUnit;
begin
  Result := -1;
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
var G: TKMUnitGroup;
begin
  G := fPlayers.GroupsHitTest(aX, aY);
  if (G <> nil) and not G.IsDead then
  begin
    Result := G.ID;
    fIDCache.CacheGroup(G, G.ID); //Improves cache efficiency since G will probably be accessed soon
  end
  else
    Result := -1;
end;


function TKMScriptStates.UnitsGroup(aUnitID: Integer): Integer;
var U: TKMUnit; G: TKMUnitGroup;
begin
  Result := -1;
  if aUnitID > 0 then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if (U <> nil) and (U is TKMUnitWarrior) then
    begin
      G := fPlayers[U.Owner].UnitGroups.GetGroupByMember(TKMUnitWarrior(U));
      if G <> nil then
      begin
        Result := G.ID;
        fIDCache.CacheGroup(G, G.ID); //Improves cache efficiency since G will probably be accessed soon
      end;
    end;
  end
  else
    LogError('States.UnitsGroup', [aUnitID]);
end;


function TKMScriptStates.GroupDead(aGroupID: Integer): Boolean;
var G: TKMUnitGroup;
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
var G: TKMUnitGroup;
begin
  Result := -1;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
      Result := G.Owner;
  end
  else
    LogError('States.GroupOwner', [aGroupID]);
end;


function TKMScriptStates.GroupMemberCount(aGroupID: Integer): Integer;
var G: TKMUnitGroup;
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
var G: TKMUnitGroup;
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
var G: TKMUnitGroup;
begin
  Result := 0;
  if aGroupID > 0 then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if G <> nil then
    begin
      if InRange(aMemberIndex, 0, G.Count-1) then
      begin
        Result := G.Members[aMemberIndex].ID;
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
  Inherited Create;
  fIDCache := aIDCache;
end;


function TKMScriptActions.ValidSoundFileName(aFileName: AnsiString): Boolean;
var I: Integer;
begin
  for I:=1 to Length(aFileName) do
    if not (aFileName[I] in ['a'..'z', '1'..'9', '0']) then
    begin
      Result := False;
      Exit;
    end;
  Result := Length(aFileName) > 0;
end;


//@Lewin: What is this function intended to do and why is it unused?
//Judging from current implementation it just removes $ symbols
//(which is equivalent to StringReplace(aText, '$', '', [rfReplaceAll]);
function TKMScriptActions.ParseTextMarkup(const aText: AnsiString): AnsiString;
var I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(aText) do
  begin
    if aText[I] = '$' then
    begin
      inc(I);
    end
    else
    begin
      Result := Result + aText[I];
      inc(I);
    end;
  end;
end;


procedure TKMScriptActions.LogError(aFuncName: string; const aValues: array of Integer);
var
  I: Integer;
  Values: string;
begin
  for I := Low(aValues) to High(aValues) do
    Values := Values + IntToStr(aValues[I]) + IfThen(I<>High(aValues), ', ');
  gLog.AddTime('Mistake in script usage ' + aFuncName + ': ' + Values);
end;


procedure TKMScriptActions.PlayerDefeat(aPlayer: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    fPlayers[aPlayer].AI.Defeat
  else
    LogError('Actions.PlayerDefeat', [aPlayer]);
end;


//Sets all player IDs in aVictors to victorious, and all their team members if aTeamVictory is true.
//All other players are set to defeated.
procedure TKMScriptActions.PlayerWin(const aVictors: array of Integer; aTeamVictory: Boolean);
var I,K: Integer;
begin
  //Verify all input parameters
  for I := 0 to Length(aVictors) - 1 do
  if not InRange(aVictors[I], 0, fPlayers.Count - 1) then
  begin
    LogError('Actions.PlayerWin', [aVictors[I]]);
    Exit;
  end;

  for I := 0 to Length(aVictors) - 1 do
    if fPlayers[aVictors[I]].Enabled then
    begin
      fPlayers[aVictors[I]].AI.Victory;
      if aTeamVictory then
        for K := 0 to fPlayers.Count - 1 do
          if fPlayers[K].Enabled and (fPlayers[aVictors[I]].Alliances[K] = at_Ally) then
            fPlayers[K].AI.Victory;
    end;

  //All other players get defeated
  for I := 0 to fPlayers.Count - 1 do
    if fPlayers[I].Enabled and (fPlayers[I].AI.WonOrLost = wol_None) then
      fPlayers[I].AI.Defeat;
end;


procedure TKMScriptActions.PlayerAllianceChange(aPlayer1, aPlayer2: Byte; aCompliment, aAllied: Boolean);
const ALLIED: array[Boolean] of TAllianceType = (at_Enemy, at_Ally);
begin
  //Verify all input parameters
  if InRange(aPlayer1, 0, fPlayers.Count - 1)
  and InRange(aPlayer2, 0, fPlayers.Count - 1) then
  begin
    fPlayers[aPlayer1].Alliances[aPlayer2] := ALLIED[aAllied];
    if aAllied then
      fPlayers[aPlayer2].FogOfWar.SyncFOW(fPlayers[aPlayer1].FogOfWar);
    if aCompliment then
    begin
      fPlayers[aPlayer2].Alliances[aPlayer1] := ALLIED[aAllied];
      if aAllied then
        fPlayers[aPlayer1].FogOfWar.SyncFOW(fPlayers[aPlayer2].FogOfWar);
    end;
  end
  else
    LogError('Actions.PlayerAllianceChange', [aPlayer1, aPlayer2, Byte(aCompliment), Byte(aAllied)]);
end;


procedure TKMScriptActions.PlayerAddDefaultGoals(aPlayer: Byte; aBuildings: Boolean);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
  begin
    fPlayers[aPlayer].AddDefaultGoals(aBuildings);
  end
  else
    LogError('Actions.PlayerAddDefaultGoals', [aPlayer, Byte(aBuildings)]);
end;


procedure TKMScriptActions.PlayWAV(aPlayer: Word; const aFileName: AnsiString; Volume: Single);
var FullFileName: string;
begin
  if aPlayer <> MySpectator.PlayerIndex then Exit;

  FullFileName := ExeDir + Format(SFXPath, [aFileName]);
  //Silently ignore missing files (player might choose to delete annoying sounds from scripts if he likes)
  if not FileExists(FullFileName) then Exit;
  if ValidSoundFileName(aFileName) and InRange(Volume, 0, 1) then
    fSoundLib.PlayWAVFromScript(FullFileName, KMPoint(0,0), False, Volume)
  else
    LogError('Actions.PlayWAV: '+aFileName, []);
end;


procedure TKMScriptActions.PlayWAVAtLocation(aPlayer: Word; const aFileName: AnsiString; Volume: Single; X, Y: Word);
var FullFileName: string;
begin
  if aPlayer <> MySpectator.PlayerIndex then Exit;

  FullFileName := ExeDir + Format(SFXPath, [aFileName]);
  //Silently ignore missing files (player might choose to delete annoying sounds from scripts if he likes)
  if not FileExists(FullFileName) then Exit;
  if ValidSoundFileName(aFileName) and InRange(Volume, 0, 1) and gTerrain.TileInMapCoords(X,Y) then
    fSoundLib.PlayWAVFromScript(FullFileName, KMPoint(X,Y), True, Volume)
  else
    LogError('Actions.PlayWAVAtLocation: '+aFileName, [X, Y]);
end;


function TKMScriptActions.GiveGroup(aPlayer, aType, X,Y, aDir, aCount, aColumns: Word): Integer;
var G: TKMUnitGroup;
begin
  Result := -1;
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aType in [UnitTypeToIndex[WARRIOR_MIN]..UnitTypeToIndex[WARRIOR_MAX]])
  and gTerrain.TileInMapCoords(X,Y)
  and (TKMDirection(aDir+1) in [dir_N..dir_NW]) then
  begin
    G := fPlayers[aPlayer].AddUnitGroup(UnitIndexToType[aType],
                                        KMPoint(X,Y),
                                        TKMDirection(aDir+1),
                                        aColumns,
                                        aCount);
    if G = nil then Exit;
    Result := G.ID;
  end
  else
    LogError('Actions.GiveGroup', [aPlayer, aType, X, Y, aDir, aCount, aColumns]);
end;


function TKMScriptActions.GiveUnit(aPlayer, aType, X, Y, aDir: Word): Integer;
var
  U: TKMUnit;
begin
  Result := -1;

  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aType in [UnitTypeToIndex[CITIZEN_MIN] .. UnitTypeToIndex[CITIZEN_MAX]])
  and gTerrain.TileInMapCoords(X, Y)
  and (TKMDirection(aDir + 1) in [dir_N .. dir_NW]) then
  begin
    U := fPlayers[aPlayer].AddUnit(UnitIndexToType[aType], KMPoint(X,Y));
    if U = nil then Exit;
    Result := U.ID;
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
  Result := -1;

  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)])
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    if gTerrain.CanPlaceHouseFromScript(HouseIndexToType[aHouseType], KMPoint(X - fResource.HouseDat[HouseIndexToType[aHouseType]].EntranceOffsetX, Y)) then
    begin
      H := fPlayers[aPlayer].AddHouse(HouseIndexToType[aHouseType], X, Y, True);
      if H = nil then Exit;
      Result := H.ID;
    end;
  end
  else
    LogError('Actions.GiveHouse', [aPlayer, aHouseType, X, Y]);
end;


function TKMScriptActions.GiveAnimal(aType, X, Y: Word): Integer;
var
  U: TKMUnit;
begin
  Result := -1;

  //Verify all input parameters
  if (aType in [UnitTypeToIndex[ANIMAL_MIN] .. UnitTypeToIndex[ANIMAL_MAX]])
  and gTerrain.TileInMapCoords(X, Y) then
  begin
    U := fPlayers.PlayerAnimals.AddUnit(UnitIndexToType[aType], KMPoint(X,Y));
    if U <> nil then
      Result := U.ID;
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
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and InRange(aCount, 0, High(Word))
  and (aType in [Low(WareIndexToType) .. High(WareIndexToType)]) then
  begin
    H := fPlayers[aPlayer].FindHouse(ht_Store, 1);
    if H <> nil then
    begin
      H.ResAddToIn(WareIndexToType[aType], aCount);
      fPlayers[aPlayer].Stats.WareProduced(WareIndexToType[aType], aCount);
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
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and InRange(aCount, 0, High(Word))
  and (WareIndexToType[aType] in [WARFARE_MIN .. WARFARE_MAX]) then
  begin
    H := fPlayers[aPlayer].FindHouse(ht_Barracks, 1);
    if H <> nil then
    begin
      H.ResAddToIn(WareIndexToType[aType], aCount);
      fPlayers[aPlayer].Stats.WareProduced(WareIndexToType[aType], aCount);
    end;
  end
  else
    LogError('Actions.GiveWeapons', [aPlayer, aType, aCount]);
end;


procedure TKMScriptActions.FogRevealCircle(aPlayer, X, Y, aRadius: Word);
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and gTerrain.TileInMapCoords(X,Y)
  and InRange(aRadius, 0, 255) then
    fPlayers[aPlayer].FogOfWar.RevealCircle(KMPoint(X, Y), aRadius, FOG_OF_WAR_MAX)
  else
    LogError('Actions.FogRevealCircle', [aPlayer, X, Y, aRadius]);
end;


procedure TKMScriptActions.FogCoverCircle(aPlayer, X, Y, aRadius: Word);
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and gTerrain.TileInMapCoords(X,Y)
  and InRange(aRadius, 0, 255) then
    fPlayers[aPlayer].FogOfWar.CoverCircle(KMPoint(X, Y), aRadius)
  else
    LogError('Actions.FogCoverCircle', [aPlayer, X, Y, aRadius]);
end;


procedure TKMScriptActions.FogRevealAll(aPlayer: Byte);
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    fPlayers[aPlayer].FogOfWar.RevealEverything
  else
    LogError('Actions.FogRevealAll', [aPlayer]);
end;


procedure TKMScriptActions.FogCoverAll(aPlayer: Byte);
begin
  if InRange(aPlayer, 0, fPlayers.Count - 1) then
    fPlayers[aPlayer].FogOfWar.CoverEverything
  else
    LogError('Actions.FogCoverAll', [aPlayer]);
end;


procedure TKMScriptActions.ShowMsg(aPlayer: Word; aText: AnsiString);
begin
  if aPlayer = MySpectator.PlayerIndex then
    fGame.ShowMessage(mkText, aText, KMPoint(0,0))
end;


procedure TKMScriptActions.HouseUnlock(aPlayer, aHouseType: Word);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)]) then
    fPlayers[aPlayer].Stats.HouseGranted[HouseIndexToType[aHouseType]] := True
  else
    LogError('Actions.HouseUnlock', [aPlayer, aHouseType]);
end;


procedure TKMScriptActions.HouseAllow(aPlayer, aHouseType: Word; aAllowed: Boolean);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aHouseType in [Low(HouseIndexToType) .. High(HouseIndexToType)]) then
    fPlayers[aPlayer].Stats.HouseBlocked[HouseIndexToType[aHouseType]] := not aAllowed
  else
    LogError('Actions.HouseAllow', [aPlayer, aHouseType, Byte(aAllowed)]);
end;


procedure TKMScriptActions.SetTradeAllowed(aPlayer, aResType: Word; aAllowed: Boolean);
begin
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aResType in [Low(WareIndexToType)..High(WareIndexToType)]) then
    fPlayers[aPlayer].Stats.AllowToTrade[WareIndexToType[aResType]] := aAllowed
  else
    LogError('Actions.SetTradeAllowed', [aPlayer, aResType, Byte(aAllowed)]);
end;


procedure TKMScriptActions.HouseAddDamage(aHouseID: Integer; aDamage: Word);
var H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      H.AddDamage(-1, aDamage);
  end
  else
    LogError('Actions.HouseAddDamage', [aHouseID, aDamage]);
end;


procedure TKMScriptActions.HouseDestroy(aHouseID: Integer; aSilent: Boolean);
var H: TKMHouse;
begin
  if aHouseID > 0 then
  begin
    H := fIDCache.GetHouse(aHouseID);
    if H <> nil then
      H.DemolishHouse(-1, aSilent);
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
        fPlayers[H.Owner].Stats.WareProduced(Res, aCount);
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


procedure TKMScriptActions.HouseWoodcutterChopOnly(aHouseID: Integer; aChopOnly: Boolean);
var H: TKMHouse;
const CHOP_ONLY: array[Boolean] of TWoodcutterMode = (wcm_ChopAndPlant, wcm_Chop);
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
        if fResource.HouseDat[H.HouseType].ResOutput[I] = Res then
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
var H: TKMHouse;
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
var H: TKMHouse;
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


procedure TKMScriptActions.SetOverlayText(aPlayer: Word; aText: AnsiString);
begin
  if aPlayer = MySpectator.PlayerIndex then
    fGame.GamePlayInterface.SetScriptedOverlay(aText);
end;


function TKMScriptActions.PlanAddRoad(aPlayer, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if fPlayers[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ft_Road) then
    begin
      Result := True;
      fPlayers[aPlayer].BuildList.FieldworksList.AddField(KMPoint(X, Y), ft_Road);
    end;
  end
  else
    LogError('Actions.PlanAddRoad', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanAddField(aPlayer, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if fPlayers[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ft_Corn) then
    begin
      Result := True;
      fPlayers[aPlayer].BuildList.FieldworksList.AddField(KMPoint(X, Y), ft_Corn);
    end;
  end
  else
    LogError('Actions.PlanAddField', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanAddWinefield(aPlayer, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if fPlayers[aPlayer].CanAddFieldPlan(KMPoint(X, Y), ft_Wine) then
    begin
      Result := True;
      fPlayers[aPlayer].BuildList.FieldworksList.AddField(KMPoint(X, Y), ft_Wine);
    end;
  end
  else
    LogError('Actions.PlanAddWinefield', [aPlayer, X, Y]);
end;


function TKMScriptActions.PlanAddHouse(aPlayer, aHouseType, X, Y: Word): Boolean;
begin
  Result := False;
  //Verify all input parameters
  if InRange(aPlayer, 0, fPlayers.Count - 1)
  and (aHouseType in [Low(HouseIndexToType)..High(HouseIndexToType)])
  and gTerrain.TileInMapCoords(X,Y) then
  begin
    if fPlayers[aPlayer].CanAddHousePlan(KMPoint(X, Y), HouseIndexToType[aHouseType]) then
    begin
      Result := True;
      fPlayers[aPlayer].AddHousePlan(HouseIndexToType[aHouseType], KMPoint(X, Y));
    end;
  end
  else
    LogError('Actions.PlanAddHouse', [aPlayer, aHouseType, X, Y]);
end;


procedure TKMScriptActions.UnitHungerSet(aUnitID, aHungerLevel: Integer);
var U: TKMUnit;
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
var U: TKMUnit;
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
var U: TKMUnit;
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
var U: TKMUnit;
begin
  if (aUnitID > 0) then
  begin
    U := fIDCache.GetUnit(aUnitID);
    if U <> nil then
      U.KillUnit(-1, not aSilent);
  end
  else
    LogError('Actions.UnitKill', [aUnitID]);
end;


procedure TKMScriptActions.GroupOrderWalk(aGroupID: Integer; X, Y, aDirection: Word);
var G: TKMUnitGroup;
begin
  if (aGroupID > 0)
  and gTerrain.TileInMapCoords(X,Y)
  and (TKMDirection(aDirection+1) in [dir_N..dir_NW]) then
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
    if (G <> nil) and (U <> nil) then
      G.OrderAttackUnit(U, True);
  end
  else
    LogError('Actions.GroupOrderAttackHouse', [aGroupID, aUnitID]);
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
    if (G <> nil) and (G2 <> nil) then
      G.OrderLinkTo(G2, True);
  end
  else
    LogError('Actions.GroupOrderLink', [aGroupID, aDestGroupID]);
end;


function TKMScriptActions.GroupOrderSplit(aGroupID: Integer): Integer;
var
  G, G2: TKMUnitGroup;
begin
  Result := -1;
  if (aGroupID > 0) then
  begin
    G := fIDCache.GetGroup(aGroupID);
    if (G <> nil) then
    begin
      G2 := G.OrderSplit(True);
      if G2 <> nil then
        Result := G.ID;
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
