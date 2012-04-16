unit KM_UnitTaskBuild;
{$I KaM_Remake.inc}
interface
uses SysUtils,
  KM_CommonClasses, KM_Defaults, KM_Points,
  KM_Houses, KM_Terrain, KM_Units;

{Perform building}
type
  TTaskBuildRoad = class(TUnitTask)
    private
      fLoc: TKMPoint;
      BuildID: Integer;
      DemandSet: Boolean;
      TileLockSet: Boolean;
    public
      constructor Create(aWorker: TKMUnitWorker; aLoc: TKMPoint; aID: Integer);
      constructor Load(LoadStream: TKMemoryStream); override;
      destructor Destroy; override;
      function WalkShouldAbandon: Boolean; override;
      function Execute: TTaskResult; override;
      procedure Save(SaveStream: TKMemoryStream); override;
    end;

  TTaskBuildWine = class(TUnitTask)
    private
      fLoc: TKMPoint;
      BuildID: Integer;
      DemandSet: Boolean;
      TileLockSet, InitialFieldSet: Boolean;
    public
      constructor Create(aWorker: TKMUnitWorker; aLoc: TKMPoint; aID: Integer);
      constructor Load(LoadStream: TKMemoryStream); override;
      destructor Destroy; override;
      function WalkShouldAbandon: Boolean; override;
      function Execute: TTaskResult; override;
      procedure Save(SaveStream: TKMemoryStream); override;
    end;

  TTaskBuildField = class(TUnitTask)
    private
      fLoc: TKMPoint;
      BuildID: Integer;
      TileLockSet: Boolean;
    public
      constructor Create(aWorker: TKMUnitWorker; aLoc: TKMPoint; aID: Integer);
      constructor Load(LoadStream: TKMemoryStream); override;
      destructor Destroy; override;
      function WalkShouldAbandon: Boolean; override;
      function Execute: TTaskResult; override;
      procedure Save(SaveStream: TKMemoryStream); override;
    end;

  TTaskBuildWall = class(TUnitTask)
    private
      fLoc:TKMPoint;
      BuildID:integer;
      //not abandoned properly yet due to global unfinished conception of wall-building
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      destructor Destroy; override;
      //function WalkShouldAbandon: Boolean; override;
      function Execute:TTaskResult; override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

  TTaskBuildHouseArea = class(TUnitTask)
    private
      fHouse: TKMHouse;
      fHouseType: THouseType;
      fHouseLoc: TKMPoint;
      BuildID: Integer;
      HouseNeedsWorker: Boolean;
      HouseReadyToBuild: Boolean;
      Step: Byte;
      Cells: array[1..4*4]of TKMPoint;
      function GetHouseEntranceLoc: TKMPoint;
    public
      constructor Create(aWorker: TKMUnitWorker; aHouseType: THouseType; aLoc: TKMPoint; aID:integer);
      constructor Load(LoadStream: TKMemoryStream); override;
      procedure SyncLoad; override;
      destructor Destroy; override;
      function WalkShouldAbandon: Boolean; override;
      function Digging: Boolean;
      function Execute: TTaskResult; override;
      procedure Save(SaveStream: TKMemoryStream); override;
    end;

  TTaskBuildHouse = class(TUnitTask)
    private
      fHouse: TKMHouse;
      BuildID: Integer;
      BuildFrom: TKMPointDir; //Current WIP location
      Cells: TKMPointDirList; //List of surrounding cells and directions
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad; override;
      destructor Destroy; override;
      function WalkShouldAbandon:boolean; override;
      function Execute:TTaskResult; override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

  TTaskBuildHouseRepair = class(TUnitTask)
    private
      fHouse: TKMHouse;
      fRepairID: Integer; //Remember the house we repair to report if we died and let others take our place
      BuildFrom: TKMPointDir; //Current WIP location
      Cells: TKMPointDirList; //List of surrounding cells and directions
    public
      constructor Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aRepairID: Integer);
      constructor Load(LoadStream: TKMemoryStream); override;
      procedure SyncLoad; override;
      destructor Destroy; override;
      function WalkShouldAbandon: Boolean; override;
      function Execute: TTaskResult; override;
      procedure Save(SaveStream: TKMemoryStream); override;
    end;


implementation
uses KM_DeliverQueue, KM_PlayersCollection, KM_Resource, KM_ResourceHouse;


{ TTaskBuildRoad }
constructor TTaskBuildRoad.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  inherited Create(aWorker);
  fTaskName := utn_BuildRoad;
  fLoc      := aLoc;
  BuildID   := aID;
  DemandSet := False;
  TileLockSet := False;
end;


constructor TTaskBuildRoad.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(DemandSet);
  LoadStream.Read(TileLockSet);
end;


destructor TTaskBuildRoad.Destroy;
begin
  //Yet unstarted
  if BuildID <> -1 then
    if fTerrain.CanAddField(fLoc, ft_Road) then
      //Allow other workers to take this task
      fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.ReOpenField(BuildID)
    else
      //This plan is not valid anymore
      fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.CloseField(BuildID);

  if DemandSet   then fPlayers.Player[fUnit.GetOwner].Deliveries.Queue.RemDemand(fUnit);
  if TileLockSet then fTerrain.UnlockTile(fLoc);
  inherited;
end;


function TTaskBuildRoad.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not fTerrain.CanAddField(fLoc, ft_Road);
end;


function TTaskBuildRoad.Execute: TTaskResult;
begin
  Result := TaskContinues;

  if WalkShouldAbandon then
  begin
    Result := TaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0: begin
         SetActionWalkToSpot(fLoc);
         Thought := th_Build;
       end;
    1: begin
         Thought := th_None;
         fTerrain.SetTileLock(fLoc, tlRoadWork);
         TileLockSet := True;
         fPlayers.Player[GetOwner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
         BuildID := -1;
         SetActionLockedStay(11,ua_Work1,false);
       end;
    2: begin
         fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house) after first dig
         fTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,ua_Work1,false);
       end;
    3: begin
         fTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,ua_Work1,false);
         fPlayers.Player[GetOwner].Deliveries.Queue.AddDemand(nil, fUnit, rt_Stone, 1, dt_Once, di_High);
         DemandSet := true;
       end;
    4: begin //This step is repeated until Serf brings us some stone
         SetActionLockedStay(30,ua_Work1);
         Thought := th_Stone;
       end;
    5: begin
         SetActionLockedStay(11,ua_Work2,false);
         DemandSet := false;
         Thought := th_None;
       end;
    6: begin
         fTerrain.IncDigState(fLoc);
         SetActionLockedStay(11,ua_Work2,false);
       end;
    7: begin
         fTerrain.IncDigState(fLoc);
         fTerrain.FlattenTerrain(fLoc); //Flatten the terrain slightly on and around the road
         //Remove fields and other quads as they won't fit with road
         if MapElem[fTerrain.Land[fLoc.Y,fLoc.X].Obj+1].WineOrCorn then
           fTerrain.Land[fLoc.Y,fLoc.X].Obj := 255;
         SetActionLockedStay(11,ua_Work2,false);
       end;
    8: begin
         //Remove the object again, in case it grew while we were building (I saw this in-game)
         if MapElem[fTerrain.Land[fLoc.Y,fLoc.X].Obj+1].WineOrCorn then
           fTerrain.Land[fLoc.Y,fLoc.X].Obj := 255;
         fTerrain.SetField(fLoc, GetOwner, ft_Road);
         SetActionStay(5, ua_Walk);
         fTerrain.UnlockTile(fLoc);
         TileLockSet := False;
       end;
    else Result := TaskDone;
  end;
  if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rt_Stone
end;


procedure TTaskBuildRoad.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(DemandSet);
  SaveStream.Write(TileLockSet);
end;


{ TTaskBuildWine }
constructor TTaskBuildWine.Create(aWorker: TKMUnitWorker; aLoc: TKMPoint; aID: Integer);
begin
  inherited Create(aWorker);
  fTaskName := utn_BuildWine;
  fLoc      := aLoc;
  BuildID   := aID;
  DemandSet := False;
  TileLockSet := False;
  InitialFieldSet := False;
end;


constructor TTaskBuildWine.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(DemandSet);
  LoadStream.Read(TileLockSet);
  LoadStream.Read(InitialFieldSet);
end;


destructor TTaskBuildWine.Destroy;
begin
  //Yet unstarted
  if BuildID <> -1 then
    if fTerrain.CanAddField(fLoc, ft_Wine) then
      //Allow other workers to take this task
      fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.ReOpenField(BuildID)
    else
      //This plan is not valid anymore
      fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.CloseField(BuildID);

  if DemandSet   then fPlayers.Player[fUnit.GetOwner].Deliveries.Queue.RemDemand(fUnit);
  if TileLockSet then fTerrain.UnlockTile(fLoc);
  if InitialFieldSet then fTerrain.RemField(fLoc);
  inherited;
end;


function TTaskBuildWine.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not fTerrain.CanAddField(fLoc, ft_Wine);
end;


function TTaskBuildWine.Execute: TTaskResult;
begin
  Result := TaskContinues;

  if WalkShouldAbandon then
  begin
    Result := TaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
   0: begin
        SetActionWalkToSpot(fLoc);
        Thought := th_Build;
      end;
   1: begin
        Thought := th_None;
        fTerrain.SetTileLock(fLoc, tlRoadWork);
        fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
        fPlayers.Player[GetOwner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
        BuildID := -1; //it can't be cancelled now
        TileLockSet := True;
        SetActionLockedStay(12*4,ua_Work1,false);
      end;
   2: begin
        fTerrain.IncDigState(fLoc);
        SetActionLockedStay(24,ua_Work1,false);
      end;
   3: begin
        fTerrain.IncDigState(fLoc);
        SetActionLockedStay(24,ua_Work1,false);
        fPlayers.Player[GetOwner].Deliveries.Queue.AddDemand(nil,fUnit,rt_Wood, 1, dt_Once, di_High);
        DemandSet := true;
      end;
   4: begin
        fTerrain.ResetDigState(fLoc);
        fTerrain.SetField(fLoc, GetOwner, ft_InitWine); //Replace the terrain, but don't seed grapes yet
        InitialFieldSet := True;
        SetActionLockedStay(30, ua_Work1);
        Thought := th_Wood;
      end;
   5: begin //This step is repeated until Serf brings us some wood
        SetActionLockedStay(30, ua_Work1);
        Thought := th_Wood;
      end;
   6: begin
        DemandSet := false;
        SetActionLockedStay(11*8, ua_Work2, False);
        Thought := th_None;
      end;
   7: begin
        fTerrain.SetField(fLoc, GetOwner, ft_Wine);
        InitialFieldSet := False;
        SetActionStay(5, ua_Walk);
        fTerrain.UnlockTile(fLoc);
        TileLockSet := False;
      end;
   else Result := TaskDone;
  end;
  if fPhase<>5 then inc(fPhase); //Phase=5 is when worker waits for rt_Wood
end;


procedure TTaskBuildWine.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(DemandSet);
  SaveStream.Write(TileLockSet);
  SaveStream.Write(InitialFieldSet);
end;


{ TTaskBuildField }
constructor TTaskBuildField.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  inherited Create(aWorker);
  fTaskName := utn_BuildField;
  fLoc      := aLoc;
  BuildID   := aID;
  TileLockSet := False;
end;


constructor TTaskBuildField.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(TileLockSet);
end;


destructor TTaskBuildField.Destroy;
begin
  //Yet unstarted
  if BuildID <> -1 then
    if fTerrain.CanAddField(fLoc, ft_Corn) then
      //Allow other workers to take this task
      fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.ReOpenField(BuildID)
    else
      //This plan is not valid anymore
      fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.CloseField(BuildID);

  if TileLockSet then fTerrain.UnlockTile(fLoc);
  inherited;
end;


function TTaskBuildField.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not fTerrain.CanAddField(fLoc, ft_Corn);
end;


function TTaskBuildField.Execute:TTaskResult;
begin
  Result := TaskContinues;

  if WalkShouldAbandon then
  begin
    Result := TaskDone;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0: begin
         SetActionWalkToSpot(fLoc);
         Thought := th_Build;
       end;
    1: begin
        fTerrain.SetTileLock(fLoc, tlRoadWork);
        TileLockSet := True;
        fPlayers.Player[GetOwner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
        BuildID := -1;
        SetActionLockedStay(0,ua_Walk);
       end;
    2: begin
        SetActionLockedStay(11,ua_Work1,false);
        inc(fPhase2);
        if fPhase2 = 2 then fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
        if (fPhase2 = 6) and MapElem[fTerrain.Land[fLoc.Y,fLoc.X].Obj+1].WineOrCorn then
          fTerrain.Land[fLoc.Y,fLoc.X].Obj:=255; //Remove fields/grasses/other quads as they won't fit with the new field
        if fPhase2 in [6,8] then fTerrain.IncDigState(fLoc);
       end;
    3: begin
        Thought := th_None; //Keep thinking build until it's done
        fTerrain.SetField(fLoc,GetOwner,ft_Corn);
        SetActionStay(5,ua_Walk);
        fTerrain.UnlockTile(fLoc);
        TileLockSet := False;
       end;
    else Result := TaskDone;
  end;
  if fPhase2 in [0,10] then inc(fPhase);
end;


procedure TTaskBuildField.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(TileLockSet);
end;


{ TTaskBuildWall }
constructor TTaskBuildWall.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  inherited Create(aWorker);
  fTaskName := utn_BuildWall;
  fLoc      := aLoc;
  BuildID   := aID;
end;


constructor TTaskBuildWall.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(BuildID);
end;


destructor TTaskBuildWall.Destroy;
begin
  fPlayers.Player[fUnit.GetOwner].Deliveries.Queue.RemDemand(fUnit);
  if fPhase > 1 then
    fTerrain.UnlockTile(fLoc)
  else
    fPlayers.Player[fUnit.GetOwner].BuildList.FieldworksList.ReOpenField(BuildID); //Allow other workers to take this task
  inherited;
end;


//Need an idea how to make it work
function TTaskBuildWall.Execute:TTaskResult;
begin
  Result := TaskContinues;
  with fUnit do
  case fPhase of
    0: begin
         SetActionWalkToSpot(fLoc);
         Thought := th_Build;
       end;
    1: begin
        fTerrain.SetTileLock(fLoc, tlRoadWork);
        fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
        fPlayers.Player[GetOwner].BuildList.FieldworksList.CloseField(BuildID); //Close the job now because it can no longer be cancelled
        BuildID := -1;
        SetActionLockedStay(0,ua_Walk);
       end;
    2: begin
        fTerrain.IncDigState(fLoc);
        SetActionLockedStay(22,ua_Work1,false);
      end;
    3: begin
        fTerrain.IncDigState(fLoc);
        SetActionLockedStay(22,ua_Work1,false);
        fPlayers.Player[GetOwner].Deliveries.Queue.AddDemand(nil, fUnit, rt_Wood, 1, dt_Once, di_High);
      end;
    4: begin
        SetActionLockedStay(30,ua_Work1);
        Thought:=th_Wood;
      end;
    5: begin
        Thought := th_None;
        SetActionLockedStay(22,ua_Work2,false);
      end;
    6: begin
        fTerrain.ResetDigState(fLoc);
        fTerrain.IncDigState(fLoc);
        SetActionLockedStay(22,ua_Work2,false);
      end;
      //Ask for 2 more wood now
    7: begin
        //Walk away from tile and continue building from the side
        SetActionLockedStay(11,ua_Work,false);
      end;
    8: begin
        //fTerrain.IncWallState(fLoc);
        SetActionLockedStay(11,ua_Work,false);
      end;
    9: begin
        fTerrain.SetWall(fLoc,GetOwner);
        SetActionStay(1,ua_Work);
        fTerrain.UnlockTile(fLoc);
       end;
    else Result := TaskDone;
  end;
  if (fPhase<>4)and(fPhase<>8) then inc(fPhase); //Phase=4 is when worker waits for rt_Wood
  if fPhase=8 then inc(fPhase2);
  if fPhase2=5 then inc(fPhase); //wait 5 cycles
end;


procedure TTaskBuildWall.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(BuildID);
end;


{ TTaskBuildHouseArea }
constructor TTaskBuildHouseArea.Create(aWorker: TKMUnitWorker; aHouseType: THouseType; aLoc: TKMPoint; aID:integer);
var
  i,k:integer;
  HA: THouseArea;
begin
  inherited Create(aWorker);
  fTaskName  := utn_BuildHouseArea;
  fHouseType := aHouseType;
  fHouseLoc  := aLoc;
  BuildID    := aID;
  HouseNeedsWorker  := False; //House needs this worker to complete
  HouseReadyToBuild := False; //House is ready to be built
  Step       := 0;

  HA := fResource.HouseDat[fHouseType].BuildArea;
  //Fill Cells left->right, top->bottom. Worker will start flattening from the end (reversed)
  for i := 1 to 4 do for k := 1 to 4 do
  if HA[i,k] <> 0 then
  begin
    inc(Step);
    Cells[Step] := KMPoint(fHouseLoc.X + k - 3, fHouseLoc.Y + i - 4);
  end;
end;


constructor TTaskBuildHouseArea.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fHouseType, SizeOf(fHouseType));
  LoadStream.Read(fHouseLoc);
  LoadStream.Read(BuildID);
  LoadStream.Read(HouseNeedsWorker);
  LoadStream.Read(HouseReadyToBuild);
  LoadStream.Read(Step);
  for i:=1 to length(Cells) do
  LoadStream.Read(Cells[i]);
end;


procedure TTaskBuildHouseArea.SyncLoad;
begin
  inherited;
  fHouse := fPlayers.GetHouseByID(cardinal(fHouse));
end;


{ We need to revert all changes made }
destructor TTaskBuildHouseArea.Destroy;
begin
  //Yet unstarted
  if (BuildID <> -1) then
    if fTerrain.CanPlaceHouse(GetHouseEntranceLoc,fHouseType) then
      //Allow other workers to take this task
      fPlayers.Player[fUnit.GetOwner].BuildList.HousePlanList.ReOpenPlan(BuildID)
    else
    begin
      //This plan is not valid anymore
      fPlayers.Player[fUnit.GetOwner].BuildList.HousePlanList.ClosePlan(BuildID);
      fPlayers.Player[fUnit.GetOwner].Stats.HousePlanRemoved(fHouseType);
    end;

  //Destroy the house if worker was killed (e.g. by archer or hunger)
  //as we don't have mechanics to resume the building process yet
  if HouseNeedsWorker and (fHouse <> nil) and not fHouse.IsDestroyed then
    fPlayers.Player[fUnit.GetOwner].RemHouse(fHouseLoc, True);

  //Complete the task in the end (Worker could have died while trying to exit building area)
  if HouseReadyToBuild and not HouseNeedsWorker and (fHouse <> nil) and not fHouse.IsDestroyed then
  begin
    fHouse.BuildingState := hbs_Wood;
    fPlayers.Player[fUnit.GetOwner].BuildList.HouseList.AddHouse(fHouse); //Add the house to JobList, so then all workers could take it
    fPlayers.Player[fUnit.GetOwner].Deliveries.Queue.AddDemand(fHouse, nil, rt_Wood, fResource.HouseDat[fHouse.HouseType].WoodCost, dt_Once, di_High);
    fPlayers.Player[fUnit.GetOwner].Deliveries.Queue.AddDemand(fHouse, nil, rt_Stone, fResource.HouseDat[fHouse.HouseType].StoneCost, dt_Once, di_High);
  end;

  fPlayers.CleanUpHousePointer(fHouse);
  inherited;
end;


function TTaskBuildHouseArea.WalkShouldAbandon: Boolean;
begin
  //Walk should abandon if other player has built something there before we arrived
  Result := (BuildID <> -1) and not fTerrain.CanPlaceHouse(GetHouseEntranceLoc, fHouseType);
end;


function TTaskBuildHouseArea.GetHouseEntranceLoc: TKMPoint;
begin
  Result.X := fHouseLoc.X + fResource.HouseDat[fHouseType].EntranceOffsetX;
  Result.Y := fHouseLoc.Y;
end;


//Tell if we are in Digging phase where we can walk on tlDigged tiles
//(incl. phase when we walk out)
function TTaskBuildHouseArea.Digging: Boolean;
begin
  Result := fPhase >= 2;
end;


{Prepare building site - flatten terrain}
function TTaskBuildHouseArea.Execute: TTaskResult;
var OutOfWay: TKMPoint;
begin
  Result := TaskContinues;

  if WalkShouldAbandon then
  begin
    Result := TaskDone;
    Exit;
  end;

  if (fHouse <> nil) and fHouse.IsDestroyed then
  begin
    Result := TaskDone;
    fUnit.Thought := th_None;
    Exit;
  end;

  with fUnit do
  case fPhase of
    0:  begin
          SetActionWalkToSpot(GetHouseEntranceLoc);
          Thought := th_Build;
        end;
    1:  begin
          fPlayers.Player[GetOwner].BuildList.HousePlanList.ClosePlan(BuildID);
          fPlayers.Player[GetOwner].Stats.HousePlanRemoved(fHouseType);
          BuildID := -1; //Other workers can't take this task from now on
          Assert(fHouse = nil);
          fPlayers.Player[GetOwner].AddHouseWIP(fHouseType, fHouseLoc, fHouse);
          fHouse := fHouse.GetHousePointer; //We need to register a pointer to the house
          Assert(fHouse <> nil);
          HouseNeedsWorker := True; //The house placed on the map, if something happens with Worker the house will be removed
          SetActionLockedStay(2, ua_Walk);
          Thought := th_None;
        end;
    2:  SetActionWalkToSpot(Cells[Step]);
    3:  begin
          SetActionLockedStay(11,ua_Work1,false); //Don't flatten terrain here as we haven't started digging yet
        end;
    4:  begin
          SetActionLockedStay(11,ua_Work1,false);
          fTerrain.FlattenTerrain(Cells[Step]);
        end;
    5:  begin
          SetActionLockedStay(11,ua_Work1,false);
          fTerrain.FlattenTerrain(Cells[Step]);
        end;
    6:  begin
          SetActionLockedStay(11,ua_Work1,false);
          fTerrain.FlattenTerrain(Cells[Step]);
          fTerrain.FlattenTerrain(Cells[Step]); //Flatten the terrain twice now to ensure it really is flat
          if KMSamePoint(fHouse.GetEntrance, Cells[Step]) then
            fTerrain.SetField(fHouse.GetEntrance, GetOwner, ft_Road);
          fTerrain.Land[Cells[Step].Y,Cells[Step].X].Obj := 255; //All objects are removed
          fTerrain.SetTileLock(Cells[Step], tlDigged); //Block passability on tile
          dec(Step);
        end;
    7:  begin
          //Walk away from building site, before we get trapped when house becomes stoned
          OutOfWay := fTerrain.GetOutOfTheWay(GetPosition, KMPoint(0,0), CanWalk);
          if KMSamePoint(OutOfWay, KMPoint(0,0)) then
            OutOfWay := KMPointBelow(fHouse.GetEntrance); //Don't get stuck in corners
          SetActionWalkToSpot(OutOfWay);
          HouseNeedsWorker := False; //House construction no longer needs the worker to continue
          HouseReadyToBuild := True; //If worker gets killed while walking house will be finished without him
        end;
    else
        Result := TaskDone;
  end;

  inc(fPhase);

  if (fPhase = 7) and (Step > 0) then
    fPhase := 2; //Repeat with next cell
end;


procedure TTaskBuildHouseArea.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fHouseType, SizeOf(fHouseType));
  SaveStream.Write(fHouseLoc);
  SaveStream.Write(BuildID);
  SaveStream.Write(HouseNeedsWorker);
  SaveStream.Write(HouseReadyToBuild);
  SaveStream.Write(Step);
  for i:=1 to length(Cells) do
  SaveStream.Write(Cells[i]);
end;


{ TTaskBuildHouse }
constructor TTaskBuildHouse.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
begin
  inherited Create(aWorker);
  fTaskName := utn_BuildHouse;
  fHouse    := aHouse.GetHousePointer;
  BuildID   := aID;

  Cells := TKMPointDirList.Create;
  fHouse.GetListOfCellsAround(Cells, aWorker.GetDesiredPassability);
end;


constructor TTaskBuildHouse.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(BuildID);
  LoadStream.Read(BuildFrom);
  Cells := TKMPointDirList.Create;
  Cells.LoadFromStream(LoadStream);
end;


procedure TTaskBuildHouse.SyncLoad;
begin
  inherited;
  fHouse := fPlayers.GetHouseByID(cardinal(fHouse));
end;


destructor TTaskBuildHouse.Destroy;
begin
  //We are no longer connected to the House (it's either done or we died)
  fPlayers.Player[fUnit.GetOwner].BuildList.HouseList.RemWorker(BuildID);
  fPlayers.CleanUpHousePointer(fHouse);
  FreeAndNil(Cells);
  inherited;
end;


{ If we are walking to the house but the house is destroyed/canceled we should abandon immediately
  If house has not enough resource to be built, consider building task is done and look for a new
  task that has enough resouces. Once this house has building resources delivered it will be
  available from build queue again
  If house is already built by other workers}
function TTaskBuildHouse.WalkShouldAbandon: Boolean;
begin
  Result := fHouse.IsDestroyed or (not fHouse.CheckResToBuild) or fHouse.IsComplete;
end;


{Build the house}
function TTaskBuildHouse.Execute: TTaskResult;
begin
  Result := TaskContinues;

  if WalkShouldAbandon then
  begin
    fUnit.Thought := th_None;
    Result := TaskDone;
    Exit;
  end;

  with fUnit do
    case fPhase of
      0: if PickRandomSpot(Cells, BuildFrom) then
         begin
           Thought := th_Build;
           SetActionWalkToSpot(BuildFrom.Loc);
         end
         else
           Result := TaskDone;
      1: begin
           Direction := BuildFrom.Dir;
           SetActionLockedStay(0, ua_Walk);
         end;
      2: begin
           SetActionLockedStay(5,ua_Work,false,0,0); //Start animation
           Direction := BuildFrom.Dir;
           //Remove house plan when we start the stone phase (it is still required for wood)
           //But don't do it every time we hit if it's already done!
           if fHouse.IsStone and (fTerrain.Land[fHouse.GetPosition.Y, fHouse.GetPosition.X].TileLock <> tlHouse) then
             fTerrain.SetHouse(fHouse.GetPosition, fHouse.HouseType, hsBuilt, GetOwner);
         end;
      3: begin
           fHouse.IncBuildingProgress;
           SetActionLockedStay(6,ua_Work,false,0,5); //Do building and end animation
           inc(fPhase2);
         end;
      4: begin
           SetActionStay(1,ua_Walk);
           Thought := th_None;
         end;
      else Result := TaskDone;
    end;
  inc(fPhase);

  {Worker does 5 hits from any spot around the house and then goes to new spot,
   but if the house is done worker should stop activity immediately}
  if (fPhase=4) and (not fHouse.IsComplete) then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase:=0 //Then goto new spot
    else
      fPhase:=2; //else do more hits
end;


procedure TTaskBuildHouse.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(BuildID);
  SaveStream.Write(BuildFrom);
  Cells.SaveToStream(SaveStream);
end;


{ TTaskBuildHouseRepair }
constructor TTaskBuildHouseRepair.Create(aWorker: TKMUnitWorker; aHouse: TKMHouse; aRepairID: Integer);
begin
  inherited Create(aWorker);
  fTaskName := utn_BuildHouseRepair;
  fHouse    := aHouse.GetHousePointer;
  fRepairID := aRepairID;

  Cells := TKMPointDirList.Create;
  fHouse.GetListOfCellsAround(Cells, aWorker.GetDesiredPassability);
end;


constructor TTaskBuildHouseRepair.Load(LoadStream: TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(fRepairID);
  LoadStream.Read(BuildFrom);
  Cells := TKMPointDirList.Create;
  Cells.LoadFromStream(LoadStream);
end;


procedure TTaskBuildHouseRepair.SyncLoad;
begin
  inherited;
  fHouse := fPlayers.GetHouseByID(Cardinal(fHouse));
end;


destructor TTaskBuildHouseRepair.Destroy;
begin
  fPlayers[fUnit.GetOwner].BuildList.RepairList.RemWorker(fRepairID);
  fPlayers.CleanUpHousePointer(fHouse);
  FreeAndNil(Cells);
  inherited;
end;


function TTaskBuildHouseRepair.WalkShouldAbandon: Boolean;
begin
  Result := fHouse.IsDestroyed
            or not fHouse.IsDamaged
            or not fHouse.BuildingRepair;
end;


{Repair the house}
function TTaskBuildHouseRepair.Execute: TTaskResult;
begin
  Result := TaskContinues;

  if WalkShouldAbandon then
  begin
    Result := TaskDone;
    Exit;
  end;

  with fUnit do
    case fPhase of
      0:  if PickRandomSpot(Cells, BuildFrom) then
          begin
            Thought := th_Build;
            SetActionWalkToSpot(BuildFrom.Loc);
          end
          else
            Result := TaskDone;
      1:  begin
            Direction := BuildFrom.Dir;
            SetActionLockedStay(0, ua_Walk);
          end;
      2:  begin
            SetActionLockedStay(5, ua_Work, false, 0, 0); //Start animation
            Direction := BuildFrom.Dir;
          end;
      3:  begin
            fHouse.AddRepair;
            SetActionLockedStay(6, ua_Work,false, 0, 5); //Do building and end animation
            inc(fPhase2);
          end;
      4:  begin
            Thought := th_None;
            SetActionStay(1, ua_Walk);
          end;
      else
          Result := TaskDone;
    end;
  inc(fPhase);

  if fPhase = 4 then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase := 0 //Then goto new spot
    else
      fPhase := 2; //else do more hits
end;


procedure TTaskBuildHouseRepair.Save(SaveStream: TKMemoryStream);
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fRepairID);
  SaveStream.Write(BuildFrom);
  Cells.SaveToStream(SaveStream);
end;


end.
