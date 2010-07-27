unit KM_GameInputProcess;
{$I KaM_Remake.inc}
interface
uses SysUtils, Math, Controls, KromUtils,
    KM_CommonTypes, KM_Defaults, KM_Utils,
    KM_Houses, KM_Units, KM_Units_Warrior
    ;

{ YET UNUSED, JUST AN IDEA}

{ A. This unit takes and adjoins players input from TGame and TGamePlayInterfaces clicks and keys
  Then passes it on to game events.
  E.g. there are 2 ways player can place an order to selected Warrior:
  1. Click on map
  2. Click on minimap

  B. And most important, it accumulates and feeds player input to the game.
  Thus making possible to:
   - record gameplay
   - playback replays
   - send input through LAN to make multiplayer games

  Player commands are:
 +I.   Unit commands, only warriors (TKMUnitWarrior, OrderInfo)
  II.  House production orders (TKMHouse, PlaceOrder(warfare, troops, citizens))
  III. House repair/delivery options (TKMHouse, Toggle(repair, delivery, storehouse))
 +IV.  Building/road plans (build what, Location)
  V.   Delivery ratios
  VI.  Cheatcodes affecting gameplay (goods, props)
  VII. Viewport settings for replay (place, zoom)
  IIX. Message queue handling in gameplay interface

  }
 const MAX_PARAMS = 8;

type TBuildOrder = (bo_RoadPlan, bo_FieldPlan, bo_WinePlan, bo_WallPlan, bo_RemovePlan, bo_RemoveHouse);

type TGIPState = (gipRecording, gipReplaying);

type TGameInputCommand = (
  gic_ArmyFeed,
  gic_ArmySplit,
  gic_ArmyLink,
  gic_ArmyAttackUnit,
  gic_ArmyAttackHouse,
  gic_ArmyHalt,         //Formation commands
  gic_ArmyWalk,          //Walking

  gic_BuildRoadPlan,
  gic_BuildFieldPlan,
  gic_BuildWinePlan,
  gic_BuildWallPlan,
  gic_BuildRemovePlan,  //Removal of a plan
  gic_BuildRemoveHouse, //Removal of house
  gic_BuildHousePlan   //Build HouseType

  //gic_House
  //gic_Settings
  );

type
TGameInputProcess = class
  private
    fCount:integer;
    fCursor:integer;
    fQueue: array of packed record
      Tick:cardinal;
      Command:TGameInputCommand;
      params:array[1..MAX_PARAMS]of integer;
    end;
    fState:TGIPState;
    procedure SaveCommand(aGIC:TGameInputCommand; aParam1:integer=maxint; aParam2:integer=maxint; aParam3:integer=maxint; aParam4:integer=maxint);
    procedure ExecCommand(aIndex:integer);
  public
    constructor Create(aState:TGIPState);
    destructor Destroy; override;
    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
    procedure SaveToFile();
    procedure LoadFromFile();
    procedure BuildCommand(aOrder:TBuildOrder; aLoc:TKMPoint); overload;
    procedure BuildCommand(aHouse:THouseType; aLoc:TKMPoint); overload;
    procedure WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand); overload;
    procedure WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aUnit:TKMUnit); overload;
    procedure WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aHouse:TKMHouse); overload;
    procedure WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aTurnAmount:shortint; aLineAmount:shortint); overload;
    procedure WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aLoc:TKMPoint; aDirection:TKMDirection=dir_NA); overload;
    procedure Tick(aTick:cardinal);

    property Count:integer read fCount;
    property State:TGIPState read fState;
end;



implementation
uses KM_Terrain, KM_Unit1, KM_Sound, KM_Game, KM_PlayersCollection;


constructor TGameInputProcess.Create(aState:TGIPState);
begin
  Inherited Create;
  setlength(fQueue, 1024);
  fCount := 0;
  fCursor := 1;
  fState := aState;
end;


destructor TGameInputProcess.Destroy;
begin
  Inherited;
end;


procedure TGameInputProcess.Save(SaveStream:TKMemoryStream);
var i,k:integer;
begin
  SaveStream.Write('Game input process data');
  SaveStream.Write(fCount);
  for i:=1 to fCount do begin
    SaveStream.Write(fQueue[i].Tick);
    SaveStream.Write(fQueue[i].Command, SizeOf(fQueue[i].Command));
    for k:=1 to MAX_PARAMS do
      SaveStream.Write(fQueue[i].params[k]);
  end;
end;


procedure TGameInputProcess.Load(LoadStream:TKMemoryStream);
var i,k:integer; s:string;
begin
  LoadStream.Read(s);
  Assert(s='Game input process data');
  LoadStream.Read(fCount);
  setlength(fQueue, fCount+1);
  for i:=1 to fCount do begin
    LoadStream.Read(fQueue[i].Tick);
    LoadStream.Read(fQueue[i].Command, SizeOf(fQueue[i].Command));
    for k:=1 to MAX_PARAMS do
      LoadStream.Read(fQueue[i].params[k]);
  end;
end;


procedure TGameInputProcess.SaveToFile();
var f:file; i:integer;
begin
  AssignFile(f, ExeDir+'Saves\save99.gil');
  Rewrite(f, 1);
  BlockWrite(f, fCount, 4);
  for i:=1 to fCount do
    BlockWrite(f, fQueue[i].Tick, SizeOf(fQueue[i]));
  CloseFile(f);
end;


procedure TGameInputProcess.LoadFromFile();
var f:file; i,NumRead:integer;
begin
  if not FileExists(ExeDir+'Saves\save99.gil') then exit;
  AssignFile(f, ExeDir+'Saves\save99.gil');
  Reset(f, 1);
  BlockRead(f, fCount, 4, NumRead);
  if NumRead=0 then begin
    CloseFile(f);
    exit;
  end;
  for i:=1 to fCount do
    BlockRead(f, fQueue[i].Tick, SizeOf(fQueue[i]));
  CloseFile(f);
end;


procedure TGameInputProcess.SaveCommand(aGIC:TGameInputCommand; aParam1:integer=maxint; aParam2:integer=maxint; aParam3:integer=maxint; aParam4:integer=maxint);
begin
  Assert(fState=gipRecording);
  inc(fCount);
  if length(fQueue) <= fCount then setlength(fQueue, fCount+128);

  with fQueue[fCount] do begin
    Tick    := fGame.GetTickCount;
    Command := aGIC;
    Params[1] := aParam1;
    Params[2] := aParam2;
    Params[3] := aParam3;
    Params[4] := aParam4;
  end;
end;


procedure TGameInputProcess.ExecCommand(aIndex:integer);
begin
  Assert(fState=gipReplaying);
  with fQueue[aIndex] do
  case Command of
    gic_ArmyFeed:         TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).Split;
    gic_ArmySplit:        TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).OrderFood;
    gic_ArmyLink:         TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).LinkTo(TKMUnitWarrior(fPlayers.GetUnitByID(Params[2])));
    gic_ArmyAttackUnit:   TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).GetCommander.PlaceOrder(wo_Attack, fPlayers.GetUnitByID(Params[2]));
    gic_ArmyAttackHouse:  TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).GetCommander.PlaceOrder(wo_Attack, fPlayers.GetHouseByID(Params[2]));
    gic_ArmyHalt:         TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).Halt(Params[2],Params[3]);
    gic_ArmyWalk:         TKMUnitWarrior(MyPlayer.GetUnitByID(Params[1])).GetCommander.PlaceOrder(wo_Walk, KMPoint(Params[2],Params[3]), TKMDirection(Params[4]));

    gic_BuildRoadPlan:    MyPlayer.AddRoadPlan(KMPoint(Params[1],Params[2]), mu_RoadPlan,  false, MyPlayer.PlayerID);
    gic_BuildFieldPlan:   MyPlayer.AddRoadPlan(KMPoint(Params[1],Params[2]), mu_FieldPlan,  false, MyPlayer.PlayerID);
    gic_BuildWinePlan:    MyPlayer.AddRoadPlan(KMPoint(Params[1],Params[2]), mu_WinePlan,  false, MyPlayer.PlayerID);
    gic_BuildWallPlan:    MyPlayer.AddRoadPlan(KMPoint(Params[1],Params[2]), mu_WallPlan,  false, MyPlayer.PlayerID);
    gic_BuildRemovePlan:  MyPlayer.RemPlan(KMPoint(Params[1],Params[2]));
    gic_BuildRemoveHouse: MyPlayer.RemHouse(KMPoint(Params[1],Params[2]), false);
    gic_BuildHousePlan:   MyPlayer.AddHousePlan(THouseType(Params[1]), KMPoint(Params[2],Params[3]), MyPlayer.PlayerID);

    else Assert(false);
  end;
end;


procedure TGameInputProcess.BuildCommand(aOrder:TBuildOrder; aLoc:TKMPoint);
begin
  case aOrder of
    bo_RoadPlan:    MyPlayer.AddRoadPlan(aLoc, mu_RoadPlan,  false, MyPlayer.PlayerID);
    bo_FieldPlan:   MyPlayer.AddRoadPlan(aLoc, mu_FieldPlan, false, MyPlayer.PlayerID);
    bo_WinePlan:    MyPlayer.AddRoadPlan(aLoc, mu_WinePlan,  false, MyPlayer.PlayerID);
    bo_WallPlan:    MyPlayer.AddRoadPlan(aLoc, mu_WallPlan,  false, MyPlayer.PlayerID);
    bo_RemovePlan:  MyPlayer.RemPlan(aLoc);
    bo_RemoveHouse: MyPlayer.RemHouse(aLoc, false);
    else Assert(false, 'Unknown BuildCommand');
  end;

  case aOrder of
    bo_RoadPlan:    SaveCommand(gic_BuildRoadPlan, aLoc.X, aLoc.Y);
    bo_FieldPlan:   SaveCommand(gic_BuildFieldPlan, aLoc.X, aLoc.Y);
    bo_WinePlan:    SaveCommand(gic_BuildWinePlan, aLoc.X, aLoc.Y);
    bo_WallPlan:    SaveCommand(gic_BuildWallPlan, aLoc.X, aLoc.Y);
    bo_RemovePlan:  SaveCommand(gic_BuildRemovePlan, aLoc.X, aLoc.Y);
    bo_RemoveHouse: SaveCommand(gic_BuildRemoveHouse, aLoc.X, aLoc.Y);
    else Assert(false, 'Unknown BuildCommand');
  end;
end;


procedure TGameInputProcess.BuildCommand(aHouse:THouseType; aLoc:TKMPoint);
begin
  MyPlayer.AddHousePlan(aHouse, aLoc, MyPlayer.PlayerID);
  SaveCommand(gic_BuildHousePlan, integer(aHouse), aLoc.X, aLoc.Y);
end;


procedure TGameInputProcess.WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand);
begin
  Assert(aCommand in [gic_ArmyFeed, gic_ArmySplit]);
  case aCommand of
    gic_ArmyFeed:  aWarrior.OrderFood;
    gic_ArmySplit: aWarrior.Split;
  end;

  SaveCommand(aCommand, aWarrior.ID);
end;


procedure TGameInputProcess.WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aUnit:TKMUnit);
begin
  Assert(aCommand in [gic_ArmyLink, gic_ArmyAttackUnit]);
  case aCommand of
    gic_ArmyLink:       begin
                          aWarrior.LinkTo(TKMUnitWarrior(aUnit));
                          fSoundLib.PlayWarrior(aWarrior.GetUnitType, sp_Join);
                        end;
    gic_ArmyAttackUnit: begin
                          aWarrior.GetCommander.PlaceOrder(wo_Attack, aUnit);
                          fSoundLib.PlayWarrior(aWarrior.GetUnitType, sp_Attack);
                        end;
  end;

  SaveCommand(aCommand, aWarrior.ID, aUnit.ID);
end;


procedure TGameInputProcess.WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aHouse:TKMHouse);
begin
  Assert(aCommand = gic_ArmyAttackHouse);
  aWarrior.GetCommander.PlaceOrder(wo_Attack, aHouse);
  fSoundLib.PlayWarrior(aWarrior.GetUnitType, sp_Attack);
  SaveCommand(aCommand, aWarrior.ID, aHouse.ID);
end;


procedure TGameInputProcess.WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aTurnAmount:shortint; aLineAmount:shortint);
begin
  Assert(aCommand = gic_ArmyHalt);
  aWarrior.Halt(aTurnAmount, aLineAmount);
  SaveCommand(aCommand, aWarrior.ID, aTurnAmount, aLineAmount);
end;


procedure TGameInputProcess.WarriorCommand(aWarrior:TKMUnitWarrior; aCommand:TGameInputCommand; aLoc:TKMPoint; aDirection:TKMDirection=dir_NA);
begin
  Assert(aCommand = gic_ArmyWalk);
  aWarrior.GetCommander.PlaceOrder(wo_Walk, aLoc, aDirection);
  fSoundLib.PlayWarrior(aWarrior.GetUnitType, sp_Move);
  SaveCommand(aCommand, aWarrior.ID, aLoc.X, aLoc.Y, integer(aDirection));
end;


procedure TGameInputProcess.Tick(aTick:cardinal);
begin
  while (aTick = fQueue[fCursor].Tick) do begin
    ExecCommand(fCursor);
    inc(fCursor);
  end;
end;



end.

