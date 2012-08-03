unit KM_PlayersCollection;
{$I KaM_Remake.inc}
interface
uses
  Classes, KromUtils, Math, SysUtils,
  KM_CommonClasses, KM_Units, KM_Terrain, KM_Houses, KM_Defaults, KM_Player, KM_Utils, KM_Points;


{ Players are identified by their starting location }
type
  TKMPlayersCollection = class
  private
    fCount: Byte;
    fPlayerList: array of TKMPlayer;
    fPlayerAnimals: TKMPlayerAnimals;
    function GetPlayer(aIndex: Integer): TKMPlayer;
  public
    Selected: TObject; //Unit or House

    constructor Create;
    destructor Destroy; override;

    property Count: Byte read fCount;
    property Player[aIndex: Integer]: TKMPlayer read GetPlayer; default;
    property PlayerAnimals: TKMPlayerAnimals read fPlayerAnimals;

    procedure AddPlayers(aCount:byte); //Batch add several players

    procedure RemoveEmptyPlayers;
    procedure RemovePlayer(aIndex: TPlayerIndex);
    procedure AfterMissionInit(aFlattenRoads:boolean);
    function HousesHitTest(X,Y:Integer): TKMHouse;
    function UnitsHitTest(X, Y: Integer): TKMUnit;
    function GetClosestUnit(aLoc: TKMPoint; aIndex: TPlayerIndex; aAlliance: TAllianceType): TKMUnit;
    function GetClosestHouse(aLoc: TKMPoint; aIndex: TPlayerIndex; aAlliance: TAllianceType; aOnlyCompleted: Boolean = True): TKMHouse;
    procedure GetUnitsInRect(aRect: TKMRect; List: TList);
    function GetHouseByID(aID: Integer): TKMHouse;
    function GetUnitByID(aID: Integer): TKMUnit;
    function HitTest(X,Y: Integer; aOnlyMyPlayer: Boolean): TObject;
    procedure SelectHitTest(X,Y: Integer; aOnlyMyPlayer: Boolean);
    function GetUnitCount:integer;
    function FindPlaceForUnit(PosX,PosY:integer; aUnitType: TUnitType; out PlacePoint: TKMPoint; RequiredWalkConnect:byte):Boolean;

    ///	<summary>
    ///	  <para>
    ///	    Check how Player1 feels towards Player2.
    ///	  </para>
    ///	  <para>
    ///	    Note: this is position dependant, e.g. Player1 may be allied with
    ///	    Player2, but Player2 may be enemy to Player1
    ///	  </para>
    ///	</summary>
    function CheckAlliance(aPlay1, aPlay2: TPlayerIndex): TAllianceType;
    procedure CleanUpUnitPointer(var aUnit: TKMUnit);
    procedure CleanUpHousePointer(var aHouse: TKMHouse);
    procedure RemAnyHouse(Position: TKMPoint);
    procedure RemAnyUnit(Position: TKMPoint);
    procedure RevealForTeam(aPlayer: TPlayerIndex; Pos: TKMPoint; Radius,Amount:word);
    procedure SyncFogOfWar;
    procedure AddDefaultMPGoals(aMissionMode: TKMissionMode);

    procedure Save(SaveStream: TKMemoryStream; aMultiplayer: Boolean);
    procedure Load(LoadStream: TKMemoryStream);
    procedure SyncLoad;
    procedure IncAnimStep;
    procedure UpdateState(aTick: Cardinal);
    procedure Paint;
  end;

var
  fPlayers: TKMPlayersCollection;
  MyPlayer: TKMPlayer; //shortcut to access players player


implementation
uses KM_Game, KM_Log, KM_Resource;


{TKMAllPlayers}
constructor TKMPlayersCollection.Create;
begin
  inherited Create;

  fPlayerAnimals := TKMPlayerAnimals.Create(PLAYER_ANIMAL); //Always create Animals
end;


destructor TKMPlayersCollection.Destroy;
var I: Integer;
begin
  for I := 0 to fCount - 1 do
    FreeThenNil(fPlayerList[I]);

  PlayerAnimals.Free;

  MyPlayer := nil;
  Selected := nil;
  inherited;
end;


function TKMPlayersCollection.GetPlayer(aIndex: Integer): TKMPlayer;
begin
  Assert(InRange(aIndex, 0, fCount-1));
  Result := fPlayerList[aIndex];
end;


procedure TKMPlayersCollection.AddPlayers(aCount: Byte);
var I: Integer;
begin
  Assert(fCount+aCount <= MAX_PLAYERS);

  SetLength(fPlayerList, fCount + aCount);

  for I := fCount to fCount + aCount - 1 do
    fPlayerList[I] := TKMPlayer.Create(I);

  fCount := fCount+aCount;
end;


procedure TKMPlayersCollection.AfterMissionInit(aFlattenRoads:boolean);
var i:integer;
begin
  for i:=0 to fCount-1 do
    fPlayerList[i].AfterMissionInit(aFlattenRoads);
end;


//We assume that if player has no assets it is unused and can be removed, so that remaining players
//will be tightly packed and mission info will display correct player count
//Accessed only by MapEditor when it needs to remove empty players before saving a map
procedure TKMPlayersCollection.RemoveEmptyPlayers;
var I: Integer;
begin
  for I := Count - 1 downto 0 do
    if fPlayerList[I].GetFieldsCount + fPlayerList[I].Houses.Count + fPlayerList[I].Units.Count = 0 then
      RemovePlayer(I);
end;


//Remove player 'aIndex'
//Accessed only by MapEditor when it needs to remove empty players before saving a map
procedure TKMPlayersCollection.RemovePlayer(aIndex: TPlayerIndex);
var i,k:integer;
begin
  if MyPlayer = fPlayerList[aIndex] then
    MyPlayer := nil;

  //Remove other players goals using this player
  for i:=0 to fCount-1 do
    fPlayerList[i].Goals.RemoveReference(aIndex);

  FreeThenNil(fPlayerList[aIndex]);

  for i:=aIndex to fCount-2 do
  begin
    fPlayerList[i] := fPlayerList[i+1];
    fPlayerList[i].SetPlayerID(i);
  end;

  dec(fCount);
  SetLength(fPlayerList, fCount);

  for i:=0 to fCount-1 do
    for k:=aIndex to fCount-1 do
      fPlayerList[i].Alliances[k] := fPlayerList[i].Alliances[k+1];

  fTerrain.RemovePlayer(aIndex);
end;


function TKMPlayersCollection.HousesHitTest(X, Y: Integer): TKMHouse;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to fCount - 1 do
  begin
    Result := fPlayerList[I].HousesHitTest(X, Y);
    if Result <> nil then
      Exit; //There can't be 2 houses on one tile
  end;
end;


function TKMPlayersCollection.UnitsHitTest(X, Y: Integer): TKMUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to fCount - 1 do
  begin
    Result := fPlayerList[I].UnitsHitTest(X, Y);
    if Result <> nil then
      Exit; //There can't be 2 units on one tile
  end;
end;


function TKMPlayersCollection.GetClosestUnit(aLoc: TKMPoint; aIndex: TPlayerIndex; aAlliance: TAllianceType): TKMUnit;
var i:integer; U: TKMUnit;
begin
  Result := nil;

  for i:=0 to fCount-1 do
  if (aIndex<>i) and (CheckAlliance(aIndex,i) = aAlliance) then
  begin
    U := fPlayerList[i].Units.GetClosestUnit(aLoc);
    if (U<>nil) and ((Result=nil) or (GetLength(U.PositionF, KMPointF(aLoc)) < GetLength(Result.PositionF, KMPointF(aLoc)))) then
      Result := U;
  end;
end;


//Get closest house. Note: we check by house cells, not by entrance
function TKMPlayersCollection.GetClosestHouse(aLoc: TKMPoint; aIndex: TPlayerIndex; aAlliance: TAllianceType; aOnlyCompleted: Boolean = True): TKMHouse;
var
  I: Integer;
  H: TKMHouse;
begin
  Result := nil;

  //Check all players
  for I := 0 to fCount - 1 do
  if (aIndex <> I) and (CheckAlliance(aIndex, I) = aAlliance) then
  begin
    H := fPlayerList[I].Houses.FindHouse(ht_Any, aLoc.X, aLoc.Y, 1, aOnlyCompleted);
    if (H <> nil) and ((Result = nil) or (H.GetDistance(aLoc) < Result.GetDistance(aLoc))) then
      Result := H;
  end;
end;


function TKMPlayersCollection.GetHouseByID(aID: Integer): TKMHouse;
var i:integer;
begin
  Result := nil;
  if aID = 0 then exit;

  for i:=0 to fCount-1 do
  begin
    Result := fPlayerList[i].Houses.GetHouseByID(aID);
    if Result<>nil then exit; //else keep on testing
  end;
end;


function TKMPlayersCollection.GetUnitByID(aID: Integer): TKMUnit;
var i:integer;
begin
  Result := nil;
  if aID = 0 then exit;

  for i:=0 to fCount-1 do
  begin
    Result := fPlayerList[i].Units.GetUnitByID(aID);
    if Result<>nil then exit; //else keep on testing
  end;
  if Result = nil then Result := PlayerAnimals.Units.GetUnitByID(aID);
end;


//Houses have priority over units, so you can't select an occupant
//Selection priority is as follows:
//BuiltHouses > Units > IncompleteHouses
function TKMPlayersCollection.HitTest(X,Y: Integer; aOnlyMyPlayer: Boolean): TObject;
var
  H: TKMHouse;
  U: TKMUnit;
begin
  if aOnlyMyPlayer then
  begin
    H := MyPlayer.HousesHitTest(X,Y);
    if (H <> nil) and (H.BuildingState in [hbs_Stone, hbs_Done]) then
      Result := H
    else begin
      U := MyPlayer.UnitsHitTest(X,Y);
      if (U <> nil) and (not U.IsDeadOrDying) then
        Result := U
      else
        Result := H;
    end
  end
  else
  begin
    H := HousesHitTest(X,Y);
    if (H <> nil) and (H.BuildingState in [hbs_Stone, hbs_Done]) then
      Result := H
    else begin
      U := UnitsHitTest(X,Y);
      if (U <> nil) and (not U.IsDeadOrDying) then
        Result := U
      else
        Result := H;
    end;
  end;
end;


procedure TKMPlayersCollection.SelectHitTest(X,Y: Integer; aOnlyMyPlayer: Boolean);
var
  Obj: TObject;
begin
  Obj := HitTest(X, Y, aOnlyMyPlayer);

  if Obj <> nil then
    Selected := Obj;
end;


//Get total unit count for statistics display
function TKMPlayersCollection.GetUnitCount:integer;
var i:integer;
begin
  Result := 0;
  for i:=0 to fCount-1 do
    inc(Result, fPlayerList[i].Units.Count);
end;


procedure TKMPlayersCollection.GetUnitsInRect(aRect: TKMRect; List: TList);
var I: Integer;
begin
  Assert(List.Count = 0);

  for I := 0 to fCount - 1 do
    fPlayerList[I].Units.GetUnitsInRect(aRect, List);
end;


{Should return closest position where unit can be placed}
function TKMPlayersCollection.FindPlaceForUnit(PosX,PosY:integer; aUnitType: TUnitType; out PlacePoint: TKMPoint; RequiredWalkConnect:byte):Boolean;
var
  i:integer;
  P: TKMPointI;
  T: TKMPoint;
  Pass: TPassability; //temp for required passability
begin
  Result := False; // if function fails to find valid position
  Pass := fResource.UnitDat[aUnitType].AllowedPassability;

  for i:=0 to 255 do begin
    P := GetPositionFromIndex(KMPoint(PosX,PosY), i);
    if fTerrain.TileInMapCoords(P.X,P.Y) then begin
      T := KMPoint(P);
      if fTerrain.CheckPassability(T, Pass) and (fTerrain.GetWalkConnectID(T) = RequiredWalkConnect)
      and not fTerrain.HasUnit(T) then begin
        PlacePoint := T; // Assign if all test are passed
        Result := True;
        exit;
      end;
    end;
  end;
end;


{ Check how Player1 feels towards Player2. Note: this is position dependant,
e.g. Play1 may be allied with Play2, but Play2 may be enemy to Play1}
function TKMPlayersCollection.CheckAlliance(aPlay1,aPlay2: TPlayerIndex): TAllianceType;
begin
  Result := at_Ally;

  if (aPlay1 = PLAYER_ANIMAL) or (aPlay2 = PLAYER_ANIMAL) or (aPlay1 = aPlay2) then
    Exit;

  Result := fPlayerList[aPlay1].Alliances[aPlay2];
end;


procedure TKMPlayersCollection.CleanUpUnitPointer(var aUnit: TKMUnit);
begin
  if (aUnit <> nil) and not fGame.IsExiting then
    aUnit.ReleaseUnitPointer;
  aUnit := nil;
end;


procedure TKMPlayersCollection.CleanUpHousePointer(var aHouse: TKMHouse);
begin
  if (aHouse <> nil) and (fGame <> nil) and not fGame.IsExiting then
    aHouse.ReleaseHousePointer;
  aHouse := nil;
end;


//MapEd procedure to remove any house below
procedure TKMPlayersCollection.RemAnyHouse(Position: TKMPoint);
var I: Integer;
begin
  for I := 0 to fCount - 1 do
    fPlayerList[I].RemHouse(Position, true, true);
end;


//MapEd procedure to remove any unit below
procedure TKMPlayersCollection.RemAnyUnit(Position: TKMPoint);
var I: Integer;
begin
  for I := 0 to fCount - 1 do
    fPlayerList[i].RemUnit(Position);
  fPlayerAnimals.RemUnit(Position);
end;


//Reveal portion of terrain for said player and his allies
//@Lewin: I don't see a reason against revealing a map for allies always
//@Krom: Well in singleplayer KaM you couldn't see what your allies could. It could mess up some campaign/fanmade missions,
//       possibly where you "discover" allies that you couldn't see at the start. (I made one such mission, you had to defend
//       your allies village, but you couldn't see it at the start, you had to walk there)
//       I think it would be bad to change it. Maybe it could be a script option eventually.
procedure TKMPlayersCollection.RevealForTeam(aPlayer: TPlayerIndex; Pos: TKMPoint; Radius, Amount: Word);
var I: Integer;
begin
  fPlayerList[aPlayer].FogOfWar.RevealCircle(Pos,Radius,Amount);
  //if fGame.MultiplayerMode then
    for I := 0 to fCount - 1 do
      if (I <> aPlayer) and (fPlayerList[aPlayer].Alliances[I] = at_Ally) then
        fPlayerList[I].FogOfWar.RevealCircle(Pos, Radius, Amount);
end;


procedure TKMPlayersCollection.SyncFogOfWar;
var i,k: integer;
begin
  for i:=0 to fCount-1 do
    for k:=0 to fCount-1 do
      if (i<>k) and (fPlayerList[i].Alliances[k] = at_Ally) then
        fPlayerList[k].FogOfWar.SyncFOW(fPlayerList[i].FogOfWar);
end;


procedure TKMPlayersCollection.AddDefaultMPGoals(aMissionMode: TKMissionMode);
var
  i,k: integer;
  Enemies:array[TPlayerIndex] of array of TPlayerIndex;
begin
  for i:=0 to fCount-1 do
  begin
    SetLength(Enemies[i],0);
    for k:=0 to fCount-1 do
      if (i<>k) and (fPlayerList[i].Alliances[k] = at_Enemy) then
      begin
        SetLength(Enemies[i],Length(Enemies[i])+1);
        Enemies[i,Length(Enemies[i])-1] := k;
      end;
    fPlayerList[i].Goals.AddDefaultMPGoals(aMissionMode <> mm_Tactic, i, Enemies[i]);
  end;
end;


// aMultiplayer - savegames should be identical when in MP mode
procedure TKMPlayersCollection.Save(SaveStream: TKMemoryStream; aMultiplayer: Boolean);
var I: Integer;
begin
  SaveStream.Write('Players');
  SaveStream.Write(fCount);
  for I := 0 to fCount - 1 do
    fPlayerList[I].Save(SaveStream);
  PlayerAnimals.Save(SaveStream);

  //Multiplayer saves must be identical
  if aMultiplayer then
    SaveStream.Write(Player[0].PlayerIndex)
  else
    SaveStream.Write(MyPlayer.PlayerIndex);
end;


procedure TKMPlayersCollection.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
  PlayerIndex: TPlayerIndex;
begin
  LoadStream.ReadAssert('Players');
  LoadStream.Read(fCount);
  fLog.AssertToLog(fCount <= MAX_PLAYERS,'Player count in savegame exceeds MAX_PLAYERS allowed by Remake');

  SetLength(fPlayerList, fCount);

  for I := 0 to fCount - 1 do
  begin
    fPlayerList[I] := TKMPlayer.Create(0);
    fPlayerList[I].Load(LoadStream);
  end;
  PlayerAnimals.Load(LoadStream);

  LoadStream.Read(PlayerIndex);
  MyPlayer := fPlayerList[PlayerIndex];
  Selected := nil;
end;


procedure TKMPlayersCollection.SyncLoad;
var i:byte;
begin
  for i:=0 to fCount-1 do
    fPlayerList[i].SyncLoad;
  PlayerAnimals.SyncLoad;
end;


procedure TKMPlayersCollection.IncAnimStep;
var I: Integer;
begin
  for I := 0 to fCount - 1 do
    fPlayerList[I].IncAnimStep;
end;


procedure TKMPlayersCollection.UpdateState(aTick: Cardinal);
var
  I: Integer;
begin
  //Update AI every 2sec for different player to even the CPU load
  for I := 0 to fCount - 1 do
    if not fGame.IsPaused and not fGame.IsExiting then
      fPlayerList[I].UpdateState(aTick)
    else
      //PlayerAI can stop the game and clear everything
      Exit;

  PlayerAnimals.UpdateState(aTick); //Animals don't have any AI yet
end;


procedure TKMPlayersCollection.Paint;
var I: Integer;
begin
  for I := 0 to fCount - 1 do
    fPlayerList[I].Paint;

  PlayerAnimals.Paint;
end;


end.
