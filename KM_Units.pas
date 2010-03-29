unit KM_Units;
interface
uses
  Classes, Math, SysUtils, KromUtils, Windows,
  KM_CommonTypes, KM_Defaults, KM_Utils, KM_Houses, KM_Terrain, KM_Units_WorkPlan;

//Memo on directives:
//Dynamic - declared and used (overriden) occasionally
//Virtual - declared and used (overriden) always
//Abstract - declared but used only in child classes

type TCheckAxis = (ax_X, ax_Y);
type
  TKMUnit = class;
  TKMUnitWorker = class;

  TUnitAction = class(TObject)
  protected
    fActionName: TUnitActionName;
    fActionType: TUnitActionType;
    IsStepDone: boolean; //True when single action element is done (unit walked to new tile, single attack loop done)
  public
    constructor Create(aActionType: TUnitActionType);
    constructor Load(LoadStream:TKMemoryStream); virtual;
    procedure SyncLoad(); virtual; abstract;
    procedure Execute(KMUnit: TKMUnit; out DoEnd: Boolean); virtual; abstract;
    property GetActionType: TUnitActionType read fActionType;
    property GetIsStepDone:boolean read IsStepDone write IsStepDone;
    procedure Save(SaveStream:TKMemoryStream); virtual;
  end;


  TUnitTask = class(TObject)
  protected
    fTaskName:TUnitTaskName;
    fUnit:TKMUnit; //Unit who's performing the Task
    fPhase:byte;
    fPhase2:byte;
  public
    constructor Create(aUnit:TKMUnit);
    constructor Load(LoadStream:TKMemoryStream); virtual;
    procedure SyncLoad(); dynamic;
    destructor Destroy; override;
    procedure Abandon; virtual;
    function WalkShouldAbandon:boolean; dynamic;
    property Phase:byte read fPhase write fPhase;
    procedure Execute(out TaskDone:boolean); virtual; abstract;
    procedure Save(SaveStream:TKMemoryStream); virtual;
  end;

    TTaskSelfTrain = class(TUnitTask)
    private
      fSchool:TKMHouseSchool;
    public
      constructor Create(aUnit:TKMUnit; aSchool:TKMHouseSchool);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      procedure Abandon(); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildRoad = class(TUnitTask)
    private
      fLoc:TKMPoint;
      buildID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildWine = class(TUnitTask)
    private
      fLoc:TKMPoint;
      buildID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildField = class(TUnitTask)
    private
      fLoc:TKMPoint;
      buildID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildWall = class(TUnitTask)
    private
      fLoc:TKMPoint;
      buildID:integer;
    public
      constructor Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildHouseArea = class(TUnitTask)
    private
      fHouse:TKMHouse;
      buildID:integer;
      Step:byte;
      ListOfCells:array[1..4*4]of TKMPoint;
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildHouse = class(TUnitTask)
    private
      fHouse:TKMHouse;
      buildID:integer;
      LocCount:byte; //Count for locations around the house from where worker can build
      CurLoc:byte; //Current WIP location
      Cells:array[1..4*4]of TKMPointDir; //List of surrounding cells and directions
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      procedure Abandon(); override;
      function WalkShouldAbandon:boolean; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskBuildHouseRepair = class(TUnitTask)
    private
      fHouse:TKMHouse;
      buildID:integer;
      LocCount:byte; //Count for locations around the house from where worker can build
      CurLoc:byte; //Current WIP location
      Cells:array[1..4*4]of TKMPointDir; //List of surrounding cells and directions
    public
      constructor Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      function WalkShouldAbandon:boolean; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskGoHome = class(TUnitTask)
    public
      constructor Create(aUnit:TKMUnit);
      procedure Execute(out TaskDone:boolean); override;
    end;

    TTaskGoEat = class(TUnitTask)
    private
      fInn:TKMHouseInn;
      PlaceID:byte; //Units place in Inn
    public
      constructor Create(aInn:TKMHouseInn; aUnit:TKMUnit);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure SyncLoad(); override;
      destructor Destroy; override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;


    {Yep, this is a Task}
    TTaskDie = class(TUnitTask)
    private
      SequenceLength:integer;
    public
      constructor Create(aUnit:TKMUnit);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

    TTaskGoOutShowHungry = class(TUnitTask)
    public
      constructor Create(aUnit:TKMUnit);
      constructor Load(LoadStream:TKMemoryStream); override;
      procedure Execute(out TaskDone:boolean); override;
      procedure Save(SaveStream:TKMemoryStream); override;
    end;

  TKMUnit = class(TObject) //todo: actions should return enum result
  protected
    fUnitType: TUnitType;
    fUnitTask: TUnitTask;
    fCurrentAction: TUnitAction;
    fThought:TUnitThought;
    fHitPoints:byte;
    fHitPointCounter: cardinal;
    fCondition:integer; //Unit condition, when it reaches zero unit should die
    fOwner:TPlayerID;
    fHome:TKMHouse;
    fPosition: TKMPointF;
    fVisible:boolean;
    fIsDead:boolean;
    fPointerCount:integer;
    fInHouse: TKMHouse; //House we are currently in //todo: This is WIP and is causing weird errors. To fix.
    fPrevPosition: TKMPoint;
    fNextPosition: TKMPoint; //Thats where unit is going to. Next tile in route or same tile if stay on place
    procedure CloseUnit;
    procedure SetAction(aAction: TUnitAction; aStep:integer);
  public
    ID:integer; //unique unit ID, used for save/load to sync to
    AnimStep: integer;
    Direction: TKMDirection;
    IsExchanging:boolean; //Current walk is an exchange, used for sliding
    property PrevPosition: TKMPoint read fPrevPosition;
    property NextPosition: TKMPoint read fNextPosition;
  public
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
    constructor Load(LoadStream:TKMemoryStream); dynamic;
    procedure SyncLoad(); virtual;
    destructor Destroy; override;
    function GetSelf:TKMUnit; //Returns self and adds one to the pointer counter
    procedure RemovePointer;  //Decreases the pointer counter
    property GetPointerCount:integer read fPointerCount;
    procedure KillUnit; virtual;
    function GetSupportedActions: TUnitActionTypeSet; virtual;
    function HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): Boolean;
    procedure UpdateNextPosition(aLoc:TKMPoint);
    procedure SetActionFight(aAction: TUnitActionType; aOpponent:TKMUnit);
    procedure SetActionGoIn(aAction: TUnitActionType; aGoDir: TGoInDirection; aHouse:TKMHouse);
    procedure SetActionStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
    procedure SetActionLockedStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
    procedure SetActionWalk(aKMUnit: TKMUnit; aLocB,aAvoid:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true; aTargetUnit:TKMUnit=nil); overload;
    procedure SetActionWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true; aSetPushed:boolean=false; aWalkToNear:boolean=false); overload;
    procedure SetActionAbandonWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
    procedure Feed(Amount:single);
    procedure AbandonWalk;
    function GetDesiredPassability(aUseCanWalk:boolean=false):TPassability;
    property GetOwner:TPlayerID read fOwner;
    function GetSpeed():single;
    property GetHome:TKMHouse read fHome;
    property GetUnitAction: TUnitAction read fCurrentAction;
    function GetUnitActionType():TUnitActionType;
    property GetUnitTask: TUnitTask read fUnitTask;
    property SetUnitTask: TUnitTask write fUnitTask;
    property GetUnitType: TUnitType read fUnitType;
    function GetUnitTaskText():string;
    function GetUnitActText():string;
    property GetCondition: integer read fCondition;
    property SetCondition: integer write fCondition;
    procedure SetFullCondition;
    procedure HitPointsDecrease(aAmount:integer=1);
    property GetHitPoints:byte read fHitPoints;
    function GetMaxHitPoints:byte;
    procedure CancelUnitTask;
    property IsVisible: boolean read fVisible;
    property SetVisibility:boolean write fVisible;
    procedure SetInHouse(aInHouse:TKMHouse);
    property GetInHouse:TKMHouse read fInHouse write SetInHouse;
    property IsDead:boolean read fIsDead;
    function IsArmyUnit():boolean;
    procedure RemoveUntrainedFromSchool();
    function CanGoEat:boolean;
    //property IsAtHome: boolean read UnitAtHome;
    function GetPosition():TKMPoint;
    property PositionF:TKMPointF read fPosition write fPosition;
    property Thought:TUnitThought read fThought write fThought;
  protected
    procedure UpdateHunger;
    procedure UpdateFOW();
    procedure UpdateThoughts();
    procedure UpdateVisibility();
    procedure UpdateHitPoints();
    function GetSlide(aCheck:TCheckAxis): single;
  public
    procedure Save(SaveStream:TKMemoryStream); virtual;
    function UpdateState():boolean; virtual;
    procedure Paint; virtual;
  end;

  //This is a common class for units going out of their homes for resources
  TKMUnitCitizen = class(TKMUnit)
  public
    WorkPlan:TUnitWorkPlan;
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
    constructor Load(LoadStream:TKMemoryStream); override;
    destructor Destroy; override;
    function FindHome():boolean;
    function InitiateMining():TUnitTask;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;

  //Serf class - transports all goods ingame between houses
  TKMUnitSerf = class(TKMUnit)
    Carry: TResourceType;
  public
    constructor Load(LoadStream:TKMemoryStream); override;
    function GiveResource(Res:TResourceType):boolean;
    function TakeResource(Res:TResourceType):boolean;
    function GetActionFromQueue(aHouse:TKMHouse=nil):TUnitTask;
    procedure SetNewDelivery(aDelivery:TUnitTask);
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;

  //Worker class - builds everything ingame
  TKMUnitWorker = class(TKMUnit)
  public
    function GetActionFromQueue():TUnitTask;
    procedure AbandonWork;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;


  //Animals
  TKMUnitAnimal = class(TKMUnit)
    fFishCount:byte; //1-5
  public
    constructor Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType); overload;
    constructor Load(LoadStream:TKMemoryStream); override;
    function ReduceFish:boolean;
    function GetSupportedActions: TUnitActionTypeSet; override;
    procedure Save(SaveStream:TKMemoryStream); override;
    function UpdateState():boolean; override;
    procedure Paint(); override;
  end;


  TKMUnitsCollection = class(TKMList)
  private
    //Groups:array of integer;
    function GetUnit(Index: Integer): TKMUnit;
    procedure SetUnit(Index: Integer; Item: TKMUnit);
    property Units[Index: Integer]: TKMUnit read GetUnit write SetUnit; //Use instead of Items[.]
  public
    destructor Destroy; override;
    function Add(aOwner:TPlayerID;  aUnitType:TUnitType; PosX, PosY:integer; AutoPlace:boolean=true):TKMUnit;
    function AddGroup(aOwner:TPlayerID;  aUnitType:TUnitType; PosX, PosY:integer; aDir:TKMDirection; aUnitPerRow, aUnitCount:word):TKMUnit;
    procedure RemoveUnit(aUnit:TKMUnit);
    function HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): TKMUnit;
    function GetUnitByID(aID: Integer): TKMUnit;
    procedure GetLocations(aOwner:TPlayerID; out Loc:TKMPointList);
    function GetTotalPointers: integer;
    function GetUnitCount: integer;
    function GetUnitByIndex(aIndex:integer): TKMUnit;
    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
    procedure SyncLoad();
    procedure UpdateState;
    procedure Paint();
  end;

implementation
uses KM_Unit1, KM_Render, KM_DeliverQueue, KM_LoadLib, KM_PlayersCollection, KM_SoundFX, KM_Viewport, KM_Game,
KM_ResourceGFX,
KM_UnitActionAbandonWalk, KM_UnitActionFight, KM_UnitActionGoInOut, KM_UnitActionStay, KM_UnitActionWalkTo,
KM_Units_Warrior, KM_UnitTaskDelivery, KM_UnitTaskMining;


{ TKMUnitCitizen }
constructor TKMUnitCitizen.Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited;
  WorkPlan := TUnitWorkPlan.Create;
end;


constructor TKMUnitCitizen.Load(LoadStream:TKMemoryStream);
var HasPlan:boolean;
begin
  Inherited;
  WorkPlan := TUnitWorkPlan.Create;
  LoadStream.Read(HasPlan);
  if HasPlan then
  begin
    WorkPlan.Load(LoadStream);
    if fUnitTask is TTaskMining then
      TTaskMining(fUnitTask).WorkPlan := WorkPlan; //restore reference
  end;
end;


destructor TKMUnitCitizen.Destroy;
begin
  FreeAndNil(WorkPlan);
  Inherited;
end;


function TKMUnitCitizen.FindHome():boolean;
var KMHouse:TKMHouse;
begin
  Result:=false;
  KMHouse:=fPlayers.Player[byte(fOwner)].FindEmptyHouse(fUnitType,GetPosition);
  if KMHouse<>nil then begin
    fHome:=KMHouse.GetSelf;
    Result:=true;
  end;
end;


procedure TKMUnitCitizen.Paint();
var UnitType:integer; AnimAct,AnimDir:integer; XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;
  UnitType:=byte(fUnitType);
  AnimAct:=byte(fCurrentAction.fActionType);
  AnimDir:=byte(Direction);

  XPaintPos := fPosition.X+0.5+GetSlide(ax_X);
  YPaintPos := fPosition.Y+ 1 +GetSlide(ax_Y);

  if SHOW_UNIT_ROUTES then
    if fCurrentAction is TUnitActionWalkTo then
      fRender.RenderDebugUnitRoute(TUnitActionWalkTo(fCurrentAction).NodeList,
                                   TUnitActionWalkTo(fCurrentAction).NodePos,
                                   $FF00FFFF);

  case fCurrentAction.fActionType of
  ua_Walk:
    begin
      fRender.RenderUnit(UnitType,       1, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,true);
      if ua_WalkArm in UnitSupportedActions[byte(UnitType)] then
        fRender.RenderUnit(UnitType,       9, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,false);
    end;
  ua_Work..ua_Eat:
      fRender.RenderUnit(UnitType, AnimAct, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,true);
  ua_WalkArm .. ua_WalkBooty2:
    begin
      fRender.RenderUnit(UnitType,       1, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,true);
      fRender.RenderUnit(UnitType, AnimAct, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,false);
    end;
  end;

  if fThought<>th_None then
    fRender.RenderUnitThought(fThought, XPaintPos, fPosition.Y+1);
end;


procedure TKMUnitCitizen.Save(SaveStream:TKMemoryStream);
var HasPlan:boolean;
begin
  Inherited;
  HasPlan := WorkPlan<>nil;
  SaveStream.Write(HasPlan);
  if HasPlan then WorkPlan.Save(SaveStream);
end;


function TKMUnitCitizen.UpdateState():boolean;
var H:TKMHouseInn; RestTime: integer;
begin
  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;
  if Self.IsDead then exit; //Caused by SelfTrain.Abandoned

  fThought:=th_None;

{  if fUnitTask=nil then //Which is always nil if 'Inherited UpdateState' works properly
  if not TestHunger then
  if not TestHasHome then
  if not TestAtHome then
  if not TestMining then
    Idle..}

  //Reset unit activity if home was destroyed, except when unit is dying or eating (finish eating/dying first)
  if (fHome<>nil)and(fHome.IsDestroyed)and(not(fUnitTask is TTaskDie))and(not(fUnitTask is TTaskGoEat)) then
  begin
    if fCurrentAction is TUnitActionWalkTo then AbandonWalk;
    FreeAndNil(fUnitTask);
    fHome.RemovePointer;
    fHome := nil;
  end;
    

  if fCondition<UNIT_MIN_CONDITION then
  begin
    H:=fPlayers.Player[byte(fOwner)].FindInn(GetPosition,Self,not fVisible);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self)
    else
      if fHome <> nil then
        if not fVisible then
          fUnitTask:=TTaskGoOutShowHungry.Create(Self)
        else
          fUnitTask:=TTaskGoHome.Create(Self);
  end;

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    if (fHome=nil) then
      if FindHome then
        fUnitTask:=TTaskGoHome.Create(Self) //Home found - go there
      else begin
        fThought:=th_Quest; //Always show quest when idle, unlike serfs who randomly show it
        SetActionStay(120, ua_Walk) //There's no home
      end
    else
      if fVisible then//Unit is not at home, still it has one
        fUnitTask:=TTaskGoHome.Create(Self)
      else
        fUnitTask:=InitiateMining; //Unit is at home, so go get a job

  if fHome <> nil then
       RestTime := HouseDAT[integer(fHome.GetHouseType)].WorkerRest*10
  else RestTime := 120; //Unit may not have a home; if so, load a default value

  if fUnitTask=nil then begin
    if random(2) = 0 then fThought := th_Quest;
    SetActionStay(RestTime, ua_Walk); //Absolutely nothing to do ...
  end;

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


function TKMUnitCitizen.InitiateMining():TUnitTask;
var i,Tmp,Res:integer;
begin
  Result:=nil;

  Res:=1;
  //Check if House has production orders
  //Random pick from whole amount
  if HousePlaceOrders[byte(fHome.GetHouseType)] then
  begin
    Tmp := fHome.CheckResOrder(1)+fHome.CheckResOrder(2)+fHome.CheckResOrder(3)+fHome.CheckResOrder(4);
    if Tmp=0 then exit; //No orders
    Tmp:=Random(Tmp)+1; //Pick random from overall count
    for i:=1 to 4 do begin
      if InRange(Tmp,1,fHome.CheckResOrder(i)) then Res:=i;
      dec(Tmp,fHome.CheckResOrder(i));
    end;
  end;

  //if not KMSamePoint(GetPosition,fHome.GetEntrance) then begin
  //  fLog.AssertToLog(KMSamePoint(GetPosition,fHome.GetEntrance),'Asking for work from wrong spot');
  //  fViewport.SetCenter(GetPosition.X,GetPosition.Y);
  //end;

  WorkPlan.FindPlan(fUnitType,fHome.GetHouseType,HouseOutput[byte(fHome.GetHouseType),Res],KMPointY1(fHome.GetEntrance));

  //Now issue a message if we failed because the resource is depleted
  if fOwner=MyPlayer.PlayerID then //Don't show for AI players
  if WorkPlan.ResourceDepleted and not fHome.ResourceDepletedMsgIssued then
  if fHome.GetHouseType = ht_FisherHut then
  begin
    //todo: Put these messages into LIB file (use one from original KaM once final has been decided on for SR3 which has changed this message)
    if not fTerrain.CanFindFishingWater(KMPointY1(fHome.GetEntrance),RANGE_FISHERMAN) then
      fGame.fGamePlayInterface.IssueMessage(msgHouse,'Your fisherman''s hut is too far away from the water.', fHome.GetEntrance)
    else
      fGame.fGamePlayInterface.IssueMessage(msgHouse,'Your fisherman cannot catch any further fish in the nearby water bodies.', fHome.GetEntrance);
    fHome.ResourceDepletedMsgIssued := true;
  end
  else
  begin
    case fHome.GetHouseType of
      ht_Quary:    Tmp := 290;
      ht_CoalMine: Tmp := 291;
      ht_IronMine: Tmp := 292;
      ht_GoldMine: Tmp := 293;
      else Tmp := 0;
    end;
    if Tmp <> 0 then
      fGame.fGamePlayInterface.IssueMessage(msgHouse,fTextLibrary.GetTextString(Tmp), fHome.GetEntrance);
    fHome.ResourceDepletedMsgIssued := true;
  end;

  if (not WorkPlan.IsIssued) or
     ((WorkPlan.Resource1<>rt_None)and(fHome.CheckResIn(WorkPlan.Resource1)<WorkPlan.Count1)) or
     ((WorkPlan.Resource2<>rt_None)and(fHome.CheckResIn(WorkPlan.Resource2)<WorkPlan.Count2)) or
     (fHome.CheckResOut(WorkPlan.Product1)>=MAX_RES_IN_HOUSE) or
     (fHome.CheckResOut(WorkPlan.Product2)>=MAX_RES_IN_HOUSE) then
  else
  begin
    if HousePlaceOrders[byte(fHome.GetHouseType)] then
      fHome.ResRemOrder(Res);
    Result := TTaskMining.Create(WorkPlan,Self);
  end;
end;


{ TKMSerf }
constructor TKMUnitSerf.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(Carry, SizeOf(Carry));
end;


procedure TKMUnitSerf.Paint();
var AnimAct,AnimDir:integer; XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;
  AnimAct:=integer(fCurrentAction.fActionType); //should correspond with UnitAction
  AnimDir:=integer(Direction);

  XPaintPos := fPosition.X+0.5+GetSlide(ax_X);
  YPaintPos := fPosition.Y+ 1 +GetSlide(ax_Y);

  if SHOW_UNIT_ROUTES then
    if fCurrentAction is TUnitActionWalkTo then
      fRender.RenderDebugUnitRoute(TUnitActionWalkTo(fCurrentAction).NodeList,TUnitActionWalkTo(fCurrentAction).NodePos,$FFFF00FF);

  fRender.RenderUnit(byte(GetUnitType), AnimAct, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,true);

  if fUnitTask is TTaskDie then exit; //Do not show unnecessary arms

  if Carry<>rt_None then
    fRender.RenderUnitCarry(integer(Carry), AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos)
  else
    fRender.RenderUnit(byte(GetUnitType), 9, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,false);

  if fThought<>th_None then
    fRender.RenderUnitThought(fThought, XPaintPos, YPaintPos);
end;


procedure TKMUnitSerf.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(Carry, SizeOf(Carry));
end;


function TKMUnitSerf.UpdateState():boolean;
var
  H:TKMHouseInn;
  OldThought:TUnitThought;
begin
  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;

  OldThought:=fThought;
  fThought:=th_None;

  if fCondition<UNIT_MIN_CONDITION then begin
    H:=fPlayers.Player[byte(fOwner)].FindInn(GetPosition,Self);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self);
  end;

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    fUnitTask:=GetActionFromQueue;

  //Only show quest thought if we are idle and not thinking anything else (e.g. death)
  if fUnitTask=nil then begin
    if (random(2)=0)and(OldThought=th_None) then fThought:=th_Quest; //
    SetActionStay(60,ua_Walk); //Stay idle
  end;

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


function TKMUnitSerf.GiveResource(Res:TResourceType):boolean;
begin
  Result:=false;
  if Carry<>rt_None then exit;
  Carry:=Res;
  Result:=true;
end;


function TKMUnitSerf.TakeResource(Res:TResourceType):boolean;
begin
  Result:=true;
  if Carry=rt_None then
    Result:=false
  else
    Carry:=rt_None;
end;


function TKMUnitSerf.GetActionFromQueue(aHouse:TKMHouse=nil):TUnitTask;
begin
  Result:=fPlayers.Player[byte(fOwner)].DeliverList.AskForDelivery(Self,aHouse);
end;


procedure TKMUnitSerf.SetNewDelivery(aDelivery:TUnitTask);
begin
  fUnitTask := aDelivery;
end;


{ TKMWorker }
procedure TKMUnitWorker.Paint();
var AnimAct,AnimDir:integer; XPaintPos, YPaintPos: single;
begin
  inherited;
  if not fVisible then exit;

  if SHOW_UNIT_ROUTES then
    if fCurrentAction is TUnitActionWalkTo then
      fRender.RenderDebugUnitRoute(TUnitActionWalkTo(fCurrentAction).NodeList,TUnitActionWalkTo(fCurrentAction).NodePos,$FFFFFFFF);

  AnimAct:=integer(fCurrentAction.fActionType); //should correspond with UnitAction
  AnimDir:=integer(Direction);

  XPaintPos := fPosition.X+0.5+GetSlide(ax_X);
  YPaintPos := fPosition.Y+ 1 +GetSlide(ax_Y);

  fRender.RenderUnit(byte(GetUnitType), AnimAct, AnimDir, AnimStep, byte(fOwner), XPaintPos, YPaintPos,true);

  if fThought<>th_None then
    fRender.RenderUnitThought(fThought, XPaintPos, YPaintPos);
end;


procedure TKMUnitWorker.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  //Nothing to save yet
end;


function TKMUnitWorker.UpdateState():boolean;
var
  H:TKMHouseInn;
begin
  Result:=true; //Required for override compatibility
  if Inherited UpdateState then exit;

  if fCondition<UNIT_MIN_CONDITION then begin
    H:=fPlayers.Player[byte(fOwner)].FindInn(GetPosition,Self);
    if H<>nil then
      fUnitTask:=TTaskGoEat.Create(H,Self);
  end;

  if (fThought = th_Build)and(fUnitTask = nil) then
    fThought := th_None; //Remove build thought if we are no longer doing anything

  if fUnitTask=nil then //If Unit still got nothing to do, nevermind hunger
    fUnitTask:=GetActionFromQueue;

  if fUnitTask=nil then SetActionStay(20,ua_Walk);

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


function TKMUnitWorker.GetActionFromQueue():TUnitTask;
begin
                   Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForHouseRepair(Self);
if Result=nil then Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForHousePlan(Self);
if Result=nil then Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForRoad(Self);
if Result=nil then Result:=fPlayers.Player[byte(fOwner)].BuildList.AskForHouse(Self);
end;


procedure TKMUnitWorker.AbandonWork;
begin
  //This will be called when we die, and we should abandom our task (if any) and clean up stuff like temporary passability
  if fUnitTask <> nil then
  begin
    //Road, wine and field: remove the markup that disallows all other building (mu_UnderConstruction) only if we have started digging
    if (fUnitTask is TTaskBuildRoad)
    or (fUnitTask is TTaskBuildWine)
    or (fUnitTask is TTaskBuildField)
    or (fUnitTask is TTaskBuildWall) then
      if fUnitTask.fPhase > 1 then fTerrain.RemMarkup(TTaskBuildRoad(fUnitTask).fLoc)
      else fPlayers.Player[byte(fOwner)].BuildList.ReOpenRoad(TTaskBuildRoad(fUnitTask).buildID); //Allow other workers to take this task

    //House area: remove house, restoring terrain to normal
    if fUnitTask is TTaskBuildHouseArea then
    begin
      if fUnitTask.fPhase <= 1 then
        fPlayers.Player[byte(fOwner)].BuildList.ReOpenHousePlan(TTaskBuildHouseArea(fUnitTask).buildID) //Allow other workers to take this task
      else //Otherwise we must destroy the house
        if TTaskBuildHouseArea(fUnitTask).fHouse <> nil then
          fPlayers.Player[Integer(fOwner)].RemHouse(TTaskBuildHouseArea(fUnitTask).fHouse.GetPosition,true);
    end;
    //Build House and Repair: No action necessary, another worker will finish it automatically
  end;
end;


{ TKMUnitAnimal }
constructor TKMUnitAnimal.Create(const aOwner: TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited;
  if aUnitType = ut_Fish then fFishCount := 5;  //Always start with 5 fish in the group
end;


constructor TKMUnitAnimal.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fFishCount)
end;


function TKMUnitAnimal.ReduceFish:boolean;
begin
  Result := false;
  if fUnitType <> ut_Fish then exit;
  if fFishCount > 1 then
  begin
    fFishCount := fFishCount-1;
    Result := true;
  end
  else if fFishCount = 1 then
  begin
    KillUnit;
    Result := true;
  end;
end;


function TKMUnitAnimal.GetSupportedActions: TUnitActionTypeSet;
begin
  Result:= [ua_Walk];
end;


procedure TKMUnitAnimal.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fFishCount);
end;


function TKMUnitAnimal.UpdateState():boolean;
var
  ActDone,TaskDone: Boolean;
  Spot:TKMPoint; //Target spot where unit will go
  SpotJit:byte; 
begin
  Result:=true; //Required for override compatibility

  ActDone:=true;
  TaskDone:=true;

  if fCurrentAction <> nil then
    fCurrentAction.Execute(Self, ActDone);

  if ActDone then FreeAndNil(fCurrentAction) else exit;

  if fUnitTask <> nil then
    fUnitTask.Execute(TaskDone);

  if TaskDone then FreeAndNil(fUnitTask) else exit;

  //First make sure the animal isn't stuck (check passibility of our position)
  if not fTerrain.CheckPassability(GetPosition,AnimalTerrain[byte(GetUnitType)]) then
  begin
    //Animal is stuck so it dies
    KillUnit;
    exit;
  end;

  SpotJit:=16; //Initial Spot jitter, it limits number of Spot guessing attempts reducing the range to 0

  repeat //Where unit should go, keep picking until target is walkable for the unit
    dec(SpotJit,1);
    Spot:=fTerrain.EnsureTileInMapCoords(GetPosition.X+RandomS(SpotJit),GetPosition.Y+RandomS(SpotJit));
  until((SpotJit=0)or(fTerrain.Route_CanBeMade(GetPosition,Spot,AnimalTerrain[byte(GetUnitType)],true)));

  if KMSamePoint(GetPosition,Spot) then begin
    SetActionStay(20, ua_Walk);
    exit;
  end;

  SetActionWalk(Self, Spot, KMPoint(0,0));
  if not TUnitActionWalkTo(fCurrentAction).fRouteBuilt then SetActionStay(5, ua_Walk);

  fLog.AssertToLog(fCurrentAction<>nil,'Unit has no action!');
end;


procedure TKMUnitAnimal.Paint();
var AnimAct,AnimDir:integer;
begin
inherited;
  if fUnitType = ut_Fish then
       AnimAct:=byte(fFishCount) //For fish the action is the number of fish in the group
  else AnimAct:=byte(fCurrentAction.fActionType); //should correspond with UnitAction

  AnimDir:=byte(Direction);
  fRender.RenderUnit(byte(Self.GetUnitType), AnimAct, AnimDir, AnimStep, 0, fPosition.X+0.5+GetSlide(ax_X), fPosition.Y+1+GetSlide(ax_Y),true);
end;


{ TKMUnit }
constructor TKMUnit.Create(const aOwner:TPlayerID; PosX, PosY:integer; aUnitType:TUnitType);
begin
  Inherited Create;
  fPointerCount := 0;
  fIsDead       := false;
  fThought      := th_None;
  fHome         := nil;
  fInHouse      := nil;
  fPosition.X   := PosX;
  fPosition.Y   := PosY;
  fPrevPosition := GetPosition; //Init values
  fNextPosition := GetPosition; //Init values
  fOwner        := aOwner;
  fUnitType     := aUnitType;
  Direction     := dir_S;
  fVisible      := true;
  IsExchanging  := false;
  ID            := fGame.GetNewID;
  AnimStep      := UnitStillFrames[Direction]; //Use still frame at begining, so units don't all change frame on first tick
  //Units start with a random amount of condition ranging from 3/4 to full.
  //This means that they won't all go eat at the same time and cause crowding, blockages, food shortages and other problems.
  fCondition    := UNIT_MAX_CONDITION - Random(UNIT_MAX_CONDITION div 4);
  fHitPoints    := GetMaxHitPoints;
  fHitPointCounter := 1;

  SetActionStay(10, ua_Walk);
  fTerrain.UnitAdd(NextPosition);
end;


destructor TKMUnit.Destroy;
begin
  FreeAndNil(fCurrentAction);
  FreeAndNil(fUnitTask);
  SetInHouse(nil); //Free pointer
  Inherited;
end;


constructor TKMUnit.Load(LoadStream:TKMemoryStream);
var HasTask,HasAct:boolean; TaskName:TUnitTaskName; ActName: TUnitActionName;
begin
  Inherited Create;
  LoadStream.Read(fUnitType, SizeOf(fUnitType));
  LoadStream.Read(HasTask);
  if HasTask then
  begin
    LoadStream.Read(TaskName, SizeOf(TaskName)); //Save task type before anything else for it will be used on loading to create specific task type
    LoadStream.Seek(-SizeOf(TaskName), soFromCurrent); //rewind
    case TaskName of
      utn_Unknown:         fUnitTask := nil;
      utn_SelfTrain:       fUnitTask := TTaskSelfTrain.Load(LoadStream);
      utn_Deliver:         fUnitTask := TTaskDeliver.Load(LoadStream);
      utn_BuildRoad:       fUnitTask := TTaskBuildRoad.Load(LoadStream);
      utn_BuildWine:       fUnitTask := TTaskBuildWine.Load(LoadStream);
      utn_BuildField:      fUnitTask := TTaskBuildField.Load(LoadStream);
      utn_BuildWall:       fUnitTask := TTaskBuildWall.Load(LoadStream);
      utn_BuildHouseArea:  fUnitTask := TTaskBuildHouseArea.Load(LoadStream);
      utn_BuildHouse:      fUnitTask := TTaskBuildHouse.Load(LoadStream);
      utn_BuildHouseRepair:fUnitTask := TTaskBuildHouseRepair.Load(LoadStream);
      utn_GoHome:          fUnitTask := TTaskGoHome.Load(LoadStream);
      utn_GoEat:           fUnitTask := TTaskGoEat.Load(LoadStream);
      utn_Mining:          fUnitTask := TTaskMining.Load(LoadStream);
      utn_Die:             fUnitTask := TTaskDie.Load(LoadStream);
      utn_GoOutShowHungry: fUnitTask := TTaskGoOutShowHungry.Load(LoadStream);
      else                 fUnitTask := nil;
    end;
  end
  else
    fUnitTask := nil;

  LoadStream.Read(HasAct);
  if HasAct then
  begin
    LoadStream.Read(ActName, SizeOf(ActName));
    LoadStream.Seek(-SizeOf(ActName), soFromCurrent); //rewind
    case ActName of
      uan_Unknown:     fCurrentAction := nil;
      uan_Stay:        fCurrentAction := TUnitActionStay.Load(LoadStream);
      uan_WalkTo:      fCurrentAction := TUnitActionWalkTo.Load(LoadStream);
      uan_AbandonWalk: fCurrentAction := TUnitActionAbandonWalk.Load(LoadStream);
      uan_GoInOut:     fCurrentAction := TUnitActionGoInOut.Load(LoadStream);
      uan_Fight:       fCurrentAction := TUnitActionFight.Load(LoadStream);
      else             fCurrentAction := nil;
    end;
  end
  else
    fCurrentAction := nil;

  LoadStream.Read(fThought, SizeOf(fThought));
  LoadStream.Read(fCondition);
  LoadStream.Read(fHitPoints);
  LoadStream.Read(fHitPointCounter, 4);
  LoadStream.Read(fInHouse, 4);
  LoadStream.Read(fOwner, SizeOf(fOwner));
  LoadStream.Read(fHome, 4); //Substitute it with reference on SyncLoad
  LoadStream.Read(fPosition, 8); //2 floats
  LoadStream.Read(fVisible);
  LoadStream.Read(fIsDead);
  LoadStream.Read(IsExchanging);
  LoadStream.Read(fPointerCount);
  LoadStream.Read(ID);
  LoadStream.Read(AnimStep);
  LoadStream.Read(Direction, SizeOf(Direction));
  LoadStream.Read(fPrevPosition);
  LoadStream.Read(fNextPosition);
end;


procedure TKMUnit.SyncLoad();
begin
  if fUnitTask<>nil then fUnitTask.SyncLoad;
  if fCurrentAction<>nil then fCurrentAction.SyncLoad;
  fHome := fPlayers.GetHouseByID(integer(fHome));
  fInHouse := fPlayers.GetHouseByID(integer(fInHouse));
end;


{Returns self and adds on to the pointer counter}
function TKMUnit.GetSelf:TKMUnit;
begin
  inc(fPointerCount);
  Result := Self;
end;


{Decreases the pointer counter}
procedure TKMUnit.RemovePointer;
begin
  dec(fPointerCount);
end;


{Erase everything related to unit status to exclude it from being accessed by anything but the old pointers}
procedure TKMUnit.CloseUnit;
begin
  if fHome<>nil then
  begin
    fHome.GetHasOwner := false;
    fHome.RemovePointer;
  end;

  fTerrain.UnitRem(NextPosition); //Must happen before we nil NextPosition

  fIsDead       := true;
  fThought      := th_None;
  fHome         := nil;
  fPosition     := KMPointF(0,0);
  fPrevPosition := KMPoint(0,0);
  fNextPosition := KMPoint(0,0);
  fOwner        := play_none;
  //Do not reset the unit type when they die as we still need to know during Load
  //fUnitType     := ut_None;
  Direction     := dir_NA;
  fVisible      := false;
  fCondition    := 0;
  AnimStep      := 0;
  FreeAndNil(fCurrentAction);
  FreeAndNil(fUnitTask);

  if (fGame.fGamePlayInterface <> nil) and (Self = fGame.fGamePlayInterface.GetShownUnit) then
    fGame.fGamePlayInterface.ClearShownUnit; //If this unit is being shown then we must clear it otherwise it sometimes crashes
  //MapEd doesn't need this yet
end;


{Call this procedure to properly kill a unit}
//killing a unit is done in 3 steps
// Kill - release all unit-specific tasks
// TTaskDie - perform dying animation
// CloseUnit - erase all unit data and hide it from further access
procedure TKMUnit.KillUnit;
begin
  if fPlayers.Selected = Self then fPlayers.Selected := nil;
  if fGame.fGamePlayInterface.GetShownUnit = Self then fGame.fGamePlayInterface.ShowUnitInfo(nil);
  if (fUnitTask is TTaskDie) then exit; //Don't kill unit if it's already dying

  //Abandon delivery if any
  if (Self is TKMUnitSerf) and (Self.fUnitTask is TTaskDeliver) then
    TTaskDeliver(Self.fUnitTask).Abandon;

  //Abandon work if any
  if Self is TKMUnitWorker then
    TKMUnitWorker(Self).AbandonWork;

  //Update statistics
  if Assigned(fPlayers) and (fOwner <> play_animals) and Assigned(fPlayers.Player[byte(fOwner)]) then
    fPlayers.Player[byte(fOwner)].DestroyedUnit(fUnitType);

  fThought := th_None; //Reset thought
  SetAction(nil, 0); //Dispose of current action
  FreeAndNil(fUnitTask); //Should be overriden to dispose of Task-specific items
  fUnitTask := TTaskDie.Create(Self);
end;


function TKMUnit.GetSupportedActions: TUnitActionTypeSet;
begin
  Result := UnitSupportedActions[integer(fUnitType)];
end;


function TKMUnit.GetPosition():TKMPoint;
begin
  Result := KMPointRound(fPosition);
end;


function TKMUnit.GetSpeed():single;
begin
  Result := UnitStat[byte(fUnitType)].Speed/24;
end;


function TKMUnit.GetUnitActionType():TUnitActionType;
begin
  Result := GetUnitAction.fActionType;
end;


function TKMUnit.GetUnitTaskText():string;
begin
  Result:='Idle';                                      {----------} //Thats allowed width
  if fUnitTask is TTaskSelfTrain        then Result := 'Self-training';
  if fUnitTask is TTaskDeliver          then Result := 'Delivering';
  if fUnitTask is TTaskBuildRoad        then Result := 'Building road';
  if fUnitTask is TTaskBuildWine        then Result := 'Building wine field';
  if fUnitTask is TTaskBuildField       then Result := 'Building corn field';
  if fUnitTask is TTaskBuildWall        then Result := 'Building a wall';
  if fUnitTask is TTaskBuildHouseArea   then Result := 'Preparing house area';
  if fUnitTask is TTaskBuildHouse       then Result := 'Building house';
  if fUnitTask is TTaskBuildHouseRepair then Result := 'Repairing house';
  if fUnitTask is TTaskGoHome           then Result := 'Going home';
  if fUnitTask is TTaskGoEat            then Result := 'Going to eat';
  if fUnitTask is TTaskMining           then Result := 'Mining resources';
  if fUnitTask is TTaskDie              then Result := 'Dying';
  if fUnitTask is TTaskGoOutShowHungry  then Result := 'Showing hunger';
end;


function TKMUnit.GetUnitActText():string;
begin
  Result:=' - ';
  if fCurrentAction is TUnitActionWalkTo then
    Result := TInteractionStatusNames[TUnitActionWalkTo(fCurrentAction).GetInteractionStatus]+': '
             +TUnitActionWalkTo(fCurrentAction).Explanation;
end;


procedure TKMUnit.SetFullCondition;
begin
  fCondition := UNIT_MAX_CONDITION;
end;


procedure TKMUnit.HitPointsDecrease(aAmount:integer=1);
begin
  //When we are first hit reset the counter
  if (aAmount > 0) and (fHitPoints = GetMaxHitPoints) then fHitPointCounter := 1;
  fHitPoints := EnsureRange(fHitPoints-aAmount,0,GetMaxHitPoints);
  if fHitPoints = 0 then KillUnit;
end;


function TKMUnit.GetMaxHitPoints:byte;
begin
  fLog.AssertToLog(byte(GetUnitType) in [1..41],'GetHP: Unit type must be in 1..41 range');
  Result := EnsureRange(UnitStat[byte(fUnitType)].HitPoints,0,255);
end;


procedure TKMUnit.CancelUnitTask;
begin
  if (fUnitTask <> nil)and(fCurrentAction is TUnitActionWalkTo) then
    AbandonWalk;
  FreeAndNil(fUnitTask);
end;


procedure TKMUnit.SetInHouse(aInHouse:TKMHouse);
begin
  if fInHouse <> nil then
    fInHouse.RemovePointer;
  if aInHouse <> nil then
    fInHouse := aInHouse.GetSelf
  else
    fInHouse := nil;
end;


function TKMUnit.HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): Boolean;
begin
  Result := (X = GetPosition.X) and //Keep comparing X,Y to GetPosition incase input is negative numbers
            (Y = GetPosition.Y) and
            ((fUnitType=UT)or(UT=ut_Any));
end;


procedure TKMUnit.UpdateNextPosition(aLoc:TKMPoint);
begin
  //As long as we only ever set PrevPos to NextPos and do so everytime before NextPos changes, there can be no problems (as were occouring in GetSlide)
  //This procedure ensures that these values always get updated correctly so we don't get a problem where GetLength(PrevPosition,NextPosition) > sqrt(2)
  fPrevPosition := NextPosition;
  fNextPosition := aLoc;
end;


procedure TKMUnit.SetAction(aAction: TUnitAction; aStep:integer);
begin
  AnimStep := aStep;
  if aAction = nil then
  begin
    FreeAndNil(fCurrentAction);
    Exit;
  end;
  if not (aAction.GetActionType in GetSupportedActions) then
  begin
    FreeAndNil(aAction);
    exit;
  end;
  if fCurrentAction <> aAction then
  begin
    fCurrentAction.Free;
    fCurrentAction := aAction;
  end;
end;


procedure TKMUnit.SetActionFight(aAction: TUnitActionType; aOpponent: TKMUnit);
begin
  SetAction(TUnitActionFight.Create(aAction, aOpponent, Self),0);
end;


procedure TKMUnit.SetActionGoIn(aAction: TUnitActionType; aGoDir: TGoInDirection; aHouse:TKMHouse);
begin
  SetAction(TUnitActionGoInOut.Create(aAction, aGoDir, aHouse),0);
end;


procedure TKMUnit.SetActionStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
begin
  //When standing still in walk, use default frame
  if (aAction = ua_Walk)and(aStayStill) then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TUnitActionStay.Create(aTimeToStay, aAction, aStayStill, aStillFrame), aStep);
end;


procedure TKMUnit.SetActionLockedStay(aTimeToStay:integer; aAction: TUnitActionType; aStayStill:boolean=true; aStillFrame:byte=0; aStep:integer=0);
begin
  //Same as above but we will ignore get-out-of-the-way (push) requests from interaction system
  if (aAction = ua_Walk)and(aStayStill) then
  begin
    aStillFrame := UnitStillFrames[Direction];
    aStep := UnitStillFrames[Direction];
  end;
  SetAction(TUnitActionStay.Create(aTimeToStay, aAction, aStayStill, aStillFrame, true),aStep);
end;


procedure TKMUnit.SetActionWalk(aKMUnit: TKMUnit; aLocB,aAvoid:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true; aTargetUnit:TKMUnit=nil);
begin
  SetAction(TUnitActionWalkTo.Create(aKMUnit, aLocB, aAvoid, aActionType, aWalkToSpot, false, false, aTargetUnit),0);
end;


procedure TKMUnit.SetActionWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk; aWalkToSpot:boolean=true; aSetPushed:boolean=false; aWalkToNear:boolean=false);
begin
  SetAction(TUnitActionWalkTo.Create(aKMUnit, aLocB, KMPoint(0,0), aActionType, aWalkToSpot, aSetPushed, aWalkToNear),0);
end;


procedure TKMUnit.SetActionAbandonWalk(aKMUnit: TKMUnit; aLocB:TKMPoint; aActionType:TUnitActionType=ua_Walk);
var TempVertexOccupied: TKMPoint;
begin
  if GetUnitAction is TUnitActionWalkTo then
  begin
    TempVertexOccupied := TUnitActionWalkTo(GetUnitAction).fVertexOccupied;
    TUnitActionWalkTo(GetUnitAction).fVertexOccupied := KMPoint(0,0); //So it doesn't try to DecVertex on destroy (now it's AbandonWalk's responsibility)
  end
  else TempVertexOccupied := KMPoint(0,0);
  SetAction(TUnitActionAbandonWalk.Create(aLocB,TempVertexOccupied, aActionType),aKMUnit.AnimStep); //Use the current animation step, to ensure smooth transition
end;


procedure TKMUnit.AbandonWalk;
begin
  if GetUnitAction is TUnitActionWalkTo then
    SetActionAbandonWalk(Self, NextPosition, ua_Walk)
  else
    SetActionStay(0, ua_Walk); //Error
end;


function TKMUnit.GetDesiredPassability(aUseCanWalk:boolean=false):TPassability;
begin
  case fUnitType of //Select desired passability depending on unit type
    ut_Serf..ut_Fisher,ut_StoneCutter..ut_Recruit: Result := canWalkRoad; //Citizens except Worker
    ut_Wolf..ut_Duck:                              Result := AnimalTerrain[byte(fUnitType)] //Animals
    else                                           Result := canWalk; //Worker, Warriors
  end;

  if (not DO_SERFS_WALK_ROADS) and (fUnitType in [ut_Serf..ut_Fisher,ut_StoneCutter..ut_Recruit]) then Result := canWalk; //Reset villagers to canWalk for debug (not animals!)

  //Delivery to unit
  if (fUnitType = ut_Serf)
  and(fUnitTask is TTaskDeliver)
  and(TTaskDeliver(fUnitTask).DeliverKind = dk_Unit)
  then
    Result := canWalk;

  //Preparing house area
  if (fUnitType = ut_Worker)
  and(((fUnitTask is TTaskBuildHouseArea)
  and(TTaskBuildHouseArea(fUnitTask).fPhase > 1)) //Worker has arrived on site
  or (mu_HouseFenceNoWalk = fTerrain.Land[GetPosition.Y,GetPosition.X].Markup)) //If we are standing on site after building
  then
    Result := canWorker; //Special mode that allows us to walk on building sites

  //Thats for 'miners' at work
  if (fUnitType in [ut_Woodcutter, ut_Farmer, ut_Fisher, ut_StoneCutter])
  and(fUnitTask is TTaskMining)
  then
    Result := canWalk;

  //aUseCanWalk means use canWalk unless we are a worker on a building site
  if aUseCanWalk and (Result <> canWorker) then
    Result := canWalk;
end;


procedure TKMUnit.Feed(Amount:single);
begin
  fCondition := min(fCondition + round(Amount), UNIT_MAX_CONDITION);
end;


{Check wherever this unit is armed}
function TKMUnit.IsArmyUnit():boolean;
begin
  Result:= fUnitType in [ut_Militia .. ut_Barbarian];
end;


procedure TKMUnit.RemoveUntrainedFromSchool();
begin
  CloseUnit; //Provide this procedure as a pointer to the private procedure CloseUnit so that CloseUnit is not run by mistake
end;

function TKMUnit.CanGoEat:boolean;
begin
  Result := fPlayers.Player[byte(fOwner)].FindInn(GetPosition,Self) <> nil;
end;


procedure TKMUnit.UpdateHunger;
begin
  if fCondition>0 then //Make unit hungry as long as they are not currently eating in the inn
    if not((fUnitTask is TTaskGoEat) and (TTaskGoEat(fUnitTask).PlaceID<>0)) then
      dec(fCondition);

  //Feed the unit automatically. Don't align it with dec(fCondition) cos FOW uses it as a timer 
  if (not DO_UNIT_HUNGER)and(fCondition<UNIT_MIN_CONDITION+100) then fCondition := UNIT_MAX_CONDITION;

  if fCondition = 0 then
    KillUnit;
end;


procedure TKMUnit.UpdateFOW;
begin
  //Can use fCondition as a sort of counter to reveal terrain X times a sec
  if fCondition mod 10 = 0 then fTerrain.RevealCircle(GetPosition, UnitStat[byte(fUnitType)].Sight, 20, fOwner);
end;


procedure TKMUnit.UpdateThoughts;
begin
  if (fThought <> th_Death) and (fCondition <= UNIT_MIN_CONDITION div 3) then
    fThought := th_Death;

  if (fThought in [th_Death, th_Eat]) and (fCondition > UNIT_MIN_CONDITION) then
    fThought := th_None;

  if (fUnitTask is TTaskDie) then //Clear thought if we are in the process of dying
    fThought := th_None;
end;


procedure TKMUnit.UpdateVisibility;
begin
  if GetInHouse <> nil then
    if GetInHouse.IsDestroyed then
    begin
      SetVisibility := true;
      //If we are walking into/out of the house then don't set our position, ActionGoInOut will sort it out
      if (not (GetUnitAction is TUnitActionGoInOut)) or (not TUnitActionGoInOut(GetUnitAction).GetHasStarted) then
      begin
        //Position in a spiral nearest to center of house, updating IsUnit.
        fTerrain.UnitRem(GetPosition);
        fPosition := KMPointF(fPlayers.FindPlaceForUnit(GetInHouse.GetPosition.X,GetInHouse.GetPosition.Y,GetUnitType));
        fTerrain.UnitAdd(GetPosition);
        //Make sure these are reset properly
        IsExchanging := false;
        fPrevPosition := GetPosition;
        fNextPosition := GetPosition;
        if GetUnitAction is TUnitActionGoInOut then SetActionLockedStay(0,ua_Walk); //Abandon the walk out in this case
      end;
      GetInHouse := nil; //Can't be in a destroyed house
    end;
end;


procedure TKMUnit.UpdateHitPoints;
begin
  //Use fHitPointCounter as a counter to restore hit points every X ticks
  if (GetUnitAction is TUnitActionFight) and not fGame.fGameSettings.fHitPointRestoreInFights then exit;
  if fGame.fGameSettings.fHitPointRestorePace = 0 then exit; //0 pace means don't restore
  if fHitPointCounter mod fGame.fGameSettings.fHitPointRestorePace = 0 then HitPointsDecrease(-1); //Add 1 hit point
  inc(fHitPointCounter);
end;


function TKMUnit.GetSlide(aCheck:TCheckAxis): single;
var DY,DX, PixelPos, LookupDiagonal: shortint;
begin
  Result := 0;
  if (not IsExchanging) or not (GetUnitAction.fActionName in [uan_WalkTo,uan_GoInOut]) then exit;

  //Uses Y because a walk in the Y means a slide in the X
  DX := sign(NextPosition.X - fPosition.X);
  DY := sign(NextPosition.Y - fPosition.Y);
  if (aCheck = ax_X) and (DY = 0) then exit; //Unit is not shifted
  if (aCheck = ax_Y) and (DX = 0) then exit;

  LookupDiagonal := abs(DX) + abs(DY); //which gives us swith: 1-straight, 2-diagonal.

  if aCheck = ax_X then begin
    PixelPos := Round(abs(fPosition.Y-PrevPosition.Y)*CELL_SIZE_PX*sqrt(LookupDiagonal)); //Diagonal movement *sqrt(2)
    Result := (DY*SlideLookup[LookupDiagonal,PixelPos])/CELL_SIZE_PX;
  end;
  if aCheck = ax_Y then begin
    PixelPos := Round(abs(fPosition.X-PrevPosition.X)*CELL_SIZE_PX*sqrt(LookupDiagonal)); //Diagonal movement *sqrt(2)
    Result := -(DX*SlideLookup[LookupDiagonal,PixelPos])/CELL_SIZE_PX;
  end;
end;


procedure TKMUnit.Save(SaveStream:TKMemoryStream);
var HasTask,HasAct:boolean;
begin
  SaveStream.Write(fUnitType, SizeOf(fUnitType));

  HasTask := fUnitTask <> nil; //Thats our switch to know if unit should write down his task.
  SaveStream.Write(HasTask);
  if HasTask then fUnitTask.Save(SaveStream); //TaskType gets written first in fUnitTask.Save

  HasAct := fCurrentAction <> nil;
  SaveStream.Write(HasAct);
  if HasAct then fCurrentAction.Save(SaveStream);

  SaveStream.Write(fThought, SizeOf(fThought));
  SaveStream.Write(fCondition);
  SaveStream.Write(fHitPoints);
  SaveStream.Write(fHitPointCounter, 4);

  if fInHouse <> nil then
    SaveStream.Write(fInHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);

  SaveStream.Write(fOwner, SizeOf(fOwner));

  if fHome <> nil then
    SaveStream.Write(fHome.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);

  SaveStream.Write(fPosition, 8); //2floats
  SaveStream.Write(fVisible);
  SaveStream.Write(fIsDead);
  SaveStream.Write(IsExchanging);
  SaveStream.Write(fPointerCount);

  SaveStream.Write(ID);
  SaveStream.Write(AnimStep);
  SaveStream.Write(Direction, SizeOf(Direction));
  SaveStream.Write(fPrevPosition);
  SaveStream.Write(fNextPosition);
end;


{Here are common Unit.UpdateState routines}
function TKMUnit.UpdateState():boolean;
var
  ActDone,TaskDone: Boolean;
begin
  //There are layers of unit activity (bottom to top):
  // - Action (Atom creating layer (walk 1frame, etc..))
  // - Task (Action creating layer)
  // - specific UpdateState (Task creating layer)

  Result := true;

  UpdateHunger();
  UpdateFOW();
  UpdateThoughts();
  UpdateHitPoints();
  UpdateVisibility(); //incase units home was destroyed

  //
  //Performing Tasks and Actions now
  //------------------------------------------------------------------------------------------------

  ActDone         := true;
  TaskDone        := true;

  //Shortcut to freeze unit in place if it's on an unwalkable tile
  if fCurrentAction is TUnitActionWalkTo then
    if GetDesiredPassability = canWalkRoad then
    begin
      if not fTerrain.CheckPassability(GetPosition, canWalk) then
        exit;
    end else
    if not fTerrain.CheckPassability(GetPosition, GetDesiredPassability) then
      exit;

//todo: new task handling pattern
{
  if fCurrentAction<>nil then
  case fCurrentAction.Execute(Self) of
    ActContinues: exit;
    ActAborted: fUnitTask.Abandon; //abandon the task properly, move along to unit task-specific UpdateState
    ActDone: ; move along to unit task
  end;

  if fUnitTask <> nil then
  case fUnitTask.Execute() of
    TaskContinues: exit;
    TaskAbandoned,
    TaskDone: ; //move along to unit-specific UpdateState
  end;
}

  if fCurrentAction <> nil then
    fCurrentAction.Execute(Self, ActDone);

  if ActDone then FreeAndNil(fCurrentAction) else exit;

  if fUnitTask <> nil then
    fUnitTask.Execute(TaskDone);

  if TaskDone then FreeAndNil(fUnitTask) else exit;

  //If we get to this point then it means that common part is done and now
  //we can perform unit-specific activities (ask for job, etc..)
  Result := false;
end;


procedure TKMUnit.Paint();
begin
  //fLog.AssertToLog(fUnitTask<>nil,'Unit '+TypeToString(fUnitType)+' has no task!');
  if fCurrentAction=nil then
  begin
    fLog.AssertToLog(fCurrentAction<>nil,'Unit '+TypeToString(fUnitType)+' has no action!');
    SetActionStay(10, ua_Walk);
  end;
  //Here should be catched any cases where unit has no current action - this is a flaw in TTasks somewhere
  //Unit always meant to have some Action performed.
end;


constructor TUnitTask.Create(aUnit:TKMUnit);
begin
  Inherited Create;
  fTaskName := utn_Unknown;
  if aUnit <> nil then fUnit := aUnit.GetSelf;
  fPhase    := 0;
  fPhase2   := 0;
end;


constructor TUnitTask.Load(LoadStream:TKMemoryStream);
begin
  Inherited Create;
  LoadStream.Read(fTaskName, SizeOf(fTaskName));
  LoadStream.Read(fUnit, 4);//Substitute it with reference on SyncLoad
  LoadStream.Read(fPhase);
  LoadStream.Read(fPhase2);
end;


procedure TUnitTask.SyncLoad();
begin
  fUnit := fPlayers.GetUnitByID(integer(fUnit));
end;


destructor TUnitTask.Destroy;
begin
  if fUnit <> nil then fUnit.RemovePointer;
  Inherited Destroy;
end;


procedure TUnitTask.Abandon;
begin
  //Shortcut to abandon and declare task done
  fUnit.Thought := th_None; //Stop any thoughts
  if fUnit <> nil then fUnit.RemovePointer;
  fUnit         := nil;
  fPhase        := MAXBYTE-1; //-1 so that if it is increased on the next run it won't overrun before exiting
  fPhase2       := MAXBYTE-1;
end;


function TUnitTask.WalkShouldAbandon:boolean;
begin
  Result := false; //Only used in some child classes
end;


procedure TUnitTask.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(fTaskName, SizeOf(fTaskName)); //Save task type before anything else for it will be used on loading to create specific task type
  if fUnit <> nil then
    SaveStream.Write(fUnit.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(fPhase);
  SaveStream.Write(fPhase2);
end;


{ TTaskSelfTrain }
{Train itself in school}
constructor TTaskSelfTrain.Create(aUnit:TKMUnit; aSchool:TKMHouseSchool);
begin
  Inherited Create(aUnit);
  fTaskName := utn_SelfTrain;
  if aSchool <> nil then fSchool:=TKMHouseSchool(aSchool.GetSelf);
  fUnit.fVisible:=false;
  fUnit.SetActionStay(0,ua_Walk);
end;


constructor TTaskSelfTrain.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fSchool, 4);
end;


procedure TTaskSelfTrain.SyncLoad();
begin
  Inherited;
  fSchool := TKMHouseSchool(fPlayers.GetHouseByID(integer(fSchool)));
end;


destructor TTaskSelfTrain.Destroy;
begin
  if fSchool <> nil then fSchool.RemovePointer;
  Inherited Destroy;
end;


procedure TTaskSelfTrain.Abandon();
var TempUnit: TKMUnit;
begin
  TempUnit := fUnit; //Make local copy of the pointer because Inherited will set the pointer to nil
  Inherited;
  TempUnit.RemoveUntrainedFromSchool; //Abort if someone has destroyed our school
end;


procedure TTaskSelfTrain.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if fSchool.IsDestroyed then
  begin
    Abandon;
    TaskDone:=true;
    exit;
  end;

  with fUnit do
    case fPhase of
      0: begin
          fSchool.SetState(hst_Work);
          fSchool.fCurrentAction.SubActionWork(ha_Work1);
          SetActionStay(29,ua_Walk);
        end;
      1: begin
          fSchool.fCurrentAction.SubActionWork(ha_Work2);
          SetActionStay(29,ua_Walk);
        end;
      2: begin
          fSchool.fCurrentAction.SubActionWork(ha_Work3);
          SetActionStay(29,ua_Walk);
        end;
      3: begin
          fSchool.fCurrentAction.SubActionWork(ha_Work4);
          SetActionStay(29,ua_Walk);
        end;
      4: begin
          fSchool.fCurrentAction.SubActionWork(ha_Work5);
          SetActionStay(29,ua_Walk);
        end;
      5: begin
          fSchool.SetState(hst_Idle);
          SetActionStay(9,ua_Walk);
          if fTerrain.CheckTileRevelation(GetPosition.X, GetPosition.Y, MyPlayer.PlayerID) >= 255 then
            fSoundLib.Play(sfx_SchoolDing,GetPosition); //Ding as the clock strikes 12 if the location is visible
         end;
      6: begin
          SetActionGoIn(ua_Walk,gd_GoOutside,fSchool);
          fSchool.UnitTrainingComplete;
          fPlayers.Player[byte(fOwner)].CreatedUnit(fUnitType,true);
         end;
      else TaskDone:=true;
    end;
  inc(fPhase);
end;


procedure TTaskSelfTrain.Save(SaveStream:TKMemoryStream);
begin
  Inherited;
  if fSchool <> nil then
    SaveStream.Write(fSchool.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
end;


{ TTaskBuildRoad }
constructor TTaskBuildRoad.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildRoad;
  fLoc      := aLoc;
  buildID   := aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskBuildRoad.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(buildID);
end;


procedure TTaskBuildRoad.Execute(out TaskDone:boolean);
begin
TaskDone:=false;
with fUnit do
case fPhase of
0: begin
     SetActionWalk(fUnit,fLoc);
     fThought := th_Build;
   end;
1: begin
     fThought := th_None;
     fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
     fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(buildID); //Close the job now because it can no longer be cancelled
     SetActionStay(11,ua_Work1,false);
   end;
2: begin
     fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house) after first dig
     fTerrain.IncDigState(fLoc);
     SetActionStay(11,ua_Work1,false);
   end;
3: begin
     fTerrain.IncDigState(fLoc);
     SetActionStay(11,ua_Work1,false);
     fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(nil, fUnit, rt_Stone, 1, dt_Once, di_High);
   end;

4: begin
     SetActionStay(30,ua_Work1);
     fThought:=th_Stone;
   end;

5: begin
     SetActionStay(11,ua_Work2,false);
     fThought:=th_None;
   end;
6: begin
     fTerrain.IncDigState(fLoc);
     SetActionStay(11,ua_Work2,false);
   end;
7: begin
     fTerrain.IncDigState(fLoc);
     fTerrain.FlattenTerrain(fLoc); //Flatten the terrain slightly on and around the road
     if MapElem[fTerrain.Land[fLoc.Y,fLoc.X].Obj+1].WineOrCorn then
       fTerrain.Land[fLoc.Y,fLoc.X].Obj:=255; //Remove fields and other quads as they won't fit with road
     SetActionStay(11,ua_Work2,false);
   end;
8: begin
     fTerrain.SetRoad(fLoc,fOwner);
     SetActionStay(5,ua_Walk);
     fTerrain.RemMarkup(fLoc);
   end;
else TaskDone:=true;
end;
if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rt_Stone
end;


procedure TTaskBuildRoad.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(buildID);
end;


{ TTaskBuildWine }
constructor TTaskBuildWine.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildWine;
  fLoc      := aLoc;
  buildID   := aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskBuildWine.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(buildID);
end;


procedure TTaskBuildWine.Execute(out TaskDone:boolean);
begin
TaskDone:=false;
with fUnit do
case fPhase of
 0: begin
      SetActionWalk(fUnit,fLoc);
      fThought := th_Build;
    end;
 1: begin
      fThought := th_None;
      fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
      fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
      fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(buildID); //Close the job now because it can no longer be cancelled
      SetActionStay(12*4,ua_Work1,false);
    end;
 2: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(24,ua_Work1,false);
    end;
 3: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(24,ua_Work1,false);
      fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(nil,fUnit,rt_Wood, 1, dt_Once, di_High);
    end;
 4: begin
      fTerrain.ResetDigState(fLoc);
      fTerrain.SetField(fLoc,fOwner,ft_InitWine);
      SetActionStay(30,ua_Work1);
      fThought:=th_Wood;
    end;
 5: begin
      SetActionStay(11*8,ua_Work2,false);
      fThought:=th_None;
    end;  
 6: begin
      fTerrain.SetField(fLoc,fOwner,ft_Wine);
      SetActionStay(5,ua_Walk);
      fTerrain.RemMarkup(fLoc);
    end;
 else TaskDone:=true;
end;
if fPhase<>4 then inc(fPhase); //Phase=4 is when worker waits for rt_Wood
end;


procedure TTaskBuildWine.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(buildID);
end;


{ TTaskBuildField }
constructor TTaskBuildField.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildField;
  fLoc      := aLoc;
  buildID   := aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskBuildField.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(buildID);
end;


procedure TTaskBuildField.Execute(out TaskDone:boolean);
begin
TaskDone:=false;
with fUnit do
case fPhase of
  0: begin
       SetActionWalk(fUnit,fLoc);
       fThought := th_Build;
     end;
  1: begin
      fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
      fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(buildID); //Close the job now because it can no longer be cancelled
      SetActionLockedStay(0,ua_Walk);
     end;
  2: begin
      SetActionStay(11,ua_Work1,false);
      inc(fPhase2);
      if fPhase2 = 2 then fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
      if fPhase2 in [6,8] then fTerrain.IncDigState(fLoc);
     end;
  3: begin
      fThought := th_None; //Keep thinking build until it's done
      fTerrain.SetField(fLoc,fOwner,ft_Corn);
      SetActionStay(5,ua_Walk);
      fTerrain.RemMarkup(fLoc);
     end;
  else TaskDone:=true;
end;
if fPhase2 in [0,10] then inc(fPhase);
end;


procedure TTaskBuildField.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(buildID);
end;


{ TTaskBuildWall }
constructor TTaskBuildWall.Create(aWorker:TKMUnitWorker; aLoc:TKMPoint; aID:integer);
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildWall;
  fLoc      := aLoc;
  buildID   := aID;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskBuildWall.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fLoc);
  LoadStream.Read(buildID);
end;


procedure TTaskBuildWall.Execute(out TaskDone:boolean);
begin
TaskDone:=false;
with fUnit do
case fPhase of
  0: begin
       SetActionWalk(fUnit,fLoc);
       fThought := th_Build;
     end;
  1: begin
      fTerrain.SetMarkup(fLoc,mu_UnderConstruction);
      fTerrain.ResetDigState(fLoc); //Remove any dig over that might have been there (e.g. destroyed house)
      fPlayers.Player[byte(fOwner)].BuildList.CloseRoad(buildID); //Close the job now because it can no longer be cancelled
      SetActionLockedStay(0,ua_Walk);
     end;
  2: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(22,ua_Work1,false);
    end;
  3: begin
      fTerrain.IncDigState(fLoc);
      SetActionStay(22,ua_Work1,false);
      fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(nil, fUnit, rt_Wood, 1, dt_Once, di_High);
    end;
  4: begin
      SetActionStay(30,ua_Work1);
      fThought:=th_Wood;
    end;
  5: begin
      fThought := th_None;
      SetActionStay(22,ua_Work2,false);
    end;
  6: begin
      fTerrain.ResetDigState(fLoc);
      fTerrain.IncDigState(fLoc);
      SetActionStay(22,ua_Work2,false);
    end;
    //Ask for 2 more wood now
    //@Lewin: It's yet incomplete
  7: begin
      //Walk away from tile and continue building from the side
      SetActionWalk(fUnit,fTerrain.GetOutOfTheWay(fUnit.GetPosition,KMPoint(0,0),GetDesiredPassability));
    end;
  8: begin
      //fTerrain.IncWallState(fLoc);
      SetActionStay(11,ua_Work,false);
    end;
  9: begin
      fTerrain.SetWall(fLoc,fOwner);
      SetActionLockedStay(0,ua_Work);
      fTerrain.RemMarkup(fLoc);
     end;
  else TaskDone:=true;
end;
if (fPhase<>4)and(fPhase<>8) then inc(fPhase); //Phase=4 is when worker waits for rt_Wood
if fPhase=8 then inc(fPhase2);
if fPhase2=5 then inc(fPhase); //wait 5 cycles
end;


procedure TTaskBuildWall.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(fLoc);
  SaveStream.Write(buildID);
end;


{ TTaskBuildHouseArea }
constructor TTaskBuildHouseArea.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
var i,k:integer;
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildHouseArea;
  fHouse    := aHouse.GetSelf;
  buildID   := aID;
  Step      := 0;
  for i := 1 to 4 do for k := 1 to 4 do
  if HousePlanYX[byte(fHouse.GetHouseType),i,k] <> 0 then begin
    inc(Step);
    ListOfCells[Step] := KMPoint(fHouse.GetPosition.X + k - 3,fHouse.GetPosition.Y + i - 4);
  end;
  fUnit.SetActionLockedStay(0, ua_Walk);
end;


constructor TTaskBuildHouseArea.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  Inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(buildID);
  LoadStream.Read(Step);
  for i:=1 to length(ListOfCells) do
  LoadStream.Read(ListOfCells[i]);
end;


procedure TTaskBuildHouseArea.SyncLoad();
begin
  Inherited;
  fHouse := fPlayers.GetHouseByID(integer(fHouse));
end;


destructor TTaskBuildHouseArea.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer; 
  Inherited Destroy;
end;


{Prepare building site - flatten terrain}
procedure TTaskBuildHouseArea.Execute(out TaskDone:boolean);
begin
TaskDone:=false;

if fHouse.IsDestroyed then
begin
  Abandon;
  TaskDone := true;
  exit;
end;

with fUnit do
case fPhase of
0:  begin
      SetActionWalk(fUnit,fHouse.GetEntrance);
      fThought := th_Build;
    end;
1:  if not fHouse.IsDestroyed then begin //House plan was cancelled before worker has arrived on site
      fPlayers.Player[byte(fOwner)].BuildList.CloseHousePlan(buildID);
      fTerrain.SetHouse(fHouse.GetPosition, fHouse.GetHouseType, hs_Fence, fOwner);
      fHouse.SetBuildingState(hbs_NoGlyph);
      SetActionStay(5,ua_Walk);
      fThought := th_None;
    end else begin
      TaskDone:=true;
      fThought := th_None;
    end;
2:  SetActionWalk(fUnit,ListOfCells[Step]);
3:  begin
      SetActionStay(11,ua_Work1,false); //Don't flatten terrain here as we haven't started digging yet
    end;
4:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
    end;
5:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
    end;
6:  begin
      SetActionStay(11,ua_Work1,false);
      fTerrain.FlattenTerrain(ListOfCells[Step]);
      fTerrain.FlattenTerrain(ListOfCells[Step]); //Flatten the terrain twice now to ensure it really is flat
      if not fHouse.IsDestroyed then
      if KMSamePoint(fHouse.GetEntrance,ListOfCells[Step]) then
        fTerrain.SetRoad(fHouse.GetEntrance, fOwner);
      fTerrain.Land[ListOfCells[Step].Y,ListOfCells[Step].X].Obj:=255; //All objects are removed
      fTerrain.SetMarkup(ListOfCells[Step],mu_HouseFenceNoWalk); //Block passability on tile
      fTerrain.RecalculatePassability(ListOfCells[Step]);
      dec(Step);
    end;
7:  SetActionStay(0,ua_Walk);
8:  begin
      fHouse.SetBuildingState(hbs_Wood);
      fPlayers.Player[byte(fOwner)].BuildList.AddNewHouse(fHouse); //Add the house to JobList, so then all workers could take it
      with HouseDAT[byte(fHouse.GetHouseType)] do begin
        fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(fHouse, nil, rt_Wood, WoodCost, dt_Once, di_High);
        fPlayers.Player[byte(fOwner)].DeliverList.AddNewDemand(fHouse, nil, rt_Stone, StoneCost, dt_Once, di_High);
      end;
      SetActionStay(1,ua_Walk);
    end;
else TaskDone:=true;
end;
inc(fPhase);
if (fPhase=7)and(Step>0) then fPhase:=2; //Repeat with next cell
end;


procedure TTaskBuildHouseArea.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  Inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(buildID);
  SaveStream.Write(Step);
  for i:=1 to length(ListOfCells) do
  SaveStream.Write(ListOfCells[i]);
end;


{ TTaskBuildHouse }
constructor TTaskBuildHouse.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
  var i,k:integer; ht:byte; Loc:TKMPoint;
  procedure AddLoc(X,Y:word; Dir:TKMDirection);
  begin
    //First check that the passabilty is correct, as the house may be placed against blocked terrain
    if not fTerrain.CheckPassability(KMPoint(X,Y),aWorker.GetDesiredPassability) then exit;
    inc(LocCount);
    Cells[LocCount].Loc:=KMPoint(X,Y);
    Cells[LocCount].Dir:=byte(Dir);
  end;
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildHouse;
  fHouse    := aHouse.GetSelf;
  Loc       := fHouse.GetPosition;
  buildID   := aID;
  LocCount  := 0;
  CurLoc    := 0;
  ht        := byte(fHouse.GetHouseType);
  //Create list of surrounding tiles and directions
  for i:=1 to 4 do for k:=1 to 4 do
  if HousePlanYX[ht,i,k]<>0 then
  begin
    if (i=1)or(HousePlanYX[ht,i-1,k]=0) then
      AddLoc(Loc.X + k - 3, Loc.Y + i - 4 - 1, dir_S); //Above
    if (i=4)or(HousePlanYX[ht,i+1,k]=0) then
      AddLoc(Loc.X + k - 3, Loc.Y + i - 4 + 1, dir_N); //Below
    if (k=4)or(HousePlanYX[ht,i,k+1]=0) then
      AddLoc(Loc.X + k - 3 + 1, Loc.Y + i - 4, dir_W); //FromRight
    if (k=1)or(HousePlanYX[ht,i,k-1]=0) then
      AddLoc(Loc.X + k - 3 - 1, Loc.Y + i - 4, dir_E);     //FromLeft
  end;
  
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskBuildHouse.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  Inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(buildID);
  LoadStream.Read(LocCount);
  LoadStream.Read(CurLoc);
  for i:=1 to length(Cells) do
  begin
    LoadStream.Read(Cells[i].Loc);
    LoadStream.Read(Cells[i].Dir,SizeOf(Cells[i].Dir));
  end;
end;


procedure TTaskBuildHouse.SyncLoad();
begin
  Inherited;
  fHouse := fPlayers.GetHouseByID(integer(fHouse));
end;


destructor TTaskBuildHouse.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer;
  Inherited Destroy;
end;

procedure TTaskBuildHouse.Abandon();
begin
  fPlayers.Player[byte(fUnit.fOwner)].BuildList.CloseHouse(buildID);
  Inherited;
end;

function TTaskBuildHouse.WalkShouldAbandon:boolean;
begin
  //If we are walking to the house but the house is destroyed or has run out of resources we should abandon
  Result := (fHouse.IsDestroyed or (not fHouse.CheckResToBuild));
end;

{Build the house}
procedure TTaskBuildHouse.Execute(out TaskDone:boolean);
  function PickRandomSpot(): byte;
  var i, MyCount: integer; Spots: array[1..16] of byte;
  begin
    MyCount := 0;
    for i:=1 to LocCount do
      if not KMSamePoint(Cells[i].Loc,fUnit.GetPosition) then
        if fTerrain.TileInMapCoords(Cells[i].Loc.X,Cells[i].Loc.Y) then
          if fTerrain.Route_CanBeMade(fUnit.GetPosition, Cells[i].Loc ,fUnit.GetDesiredPassability, true) then
          begin
            inc(MyCount);
            Spots[MyCount] := i;
          end;
    if MyCount > 0 then
      Result := Spots[Random(MyCount)+1]
    else Result := 0;
  end;
begin
  TaskDone:=false;
  //If the house has been destroyed during the building process then exit immediately
  if fHouse.IsDestroyed then
  begin
    Abandon;
    TaskDone:=true; //Drop the task
    exit;
  end;
  with fUnit do
    case fPhase of
      //Pick random location and go there
      0: begin
           //If house has not enough resource to be built, consider building task is done
           //and look for a new task that has enough resouces. Once this house has building resources
           //delivered it will be available from build queue again.
           if not fHouse.CheckResToBuild then begin
             TaskDone:=true; //Drop the task
             fThought := th_None;
             exit;
           end;
           fThought := th_Build;
           CurLoc := PickRandomSpot();
           SetActionWalk(fUnit,Cells[CurLoc].Loc);
         end;
      1: begin
           //Remember that we could be here because the walk abandoned, so this is definatly needed
           if not fHouse.CheckResToBuild then begin
             TaskDone:=true; //Drop the task
             fThought := th_None;
             exit;
           end;
           Direction:=TKMDirection(Cells[CurLoc].Dir);
           SetActionLockedStay(0,ua_Walk);
         end;
      2: begin
           SetActionLockedStay(5,ua_Work,false,0,0); //Start animation
           Direction:=TKMDirection(Cells[CurLoc].Dir);
           //Remove house plan when we start the stone phase (it is still required for wood) But don't do it every time we hit if it's already done!
           if fHouse.IsStone and (fTerrain.Land[fHouse.GetPosition.Y,fHouse.GetPosition.X].Markup <> mu_House) then
             fTerrain.SetHouse(fHouse.GetPosition, fHouse.GetHouseType, hs_Built, fOwner);
         end;
      3: begin
           //Cancel building no matter progress if resource depleted or unit is hungry and is able to eat
           if ((fCondition<UNIT_MIN_CONDITION)and(CanGoEat))or(not fHouse.CheckResToBuild) then begin
             TaskDone:=true; //Drop the task
             fThought := th_None;
             exit;
           end;
           fHouse.IncBuildingProgress;
           SetActionLockedStay(6,ua_Work,false,0,5); //Do building and end animation
           inc(fPhase2);
         end;
      4: begin
           fPlayers.Player[byte(fOwner)].BuildList.CloseHouse(buildID);
           SetActionLockedStay(1,ua_Walk);
           fThought := th_None;
         end;
      else TaskDone:=true;
    end;
  inc(fPhase);
  if (fPhase=4) and (not fHouse.IsComplete) then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase:=0 //Then goto new spot
    else
      fPhase:=2; //else do more hits
end;


procedure TTaskBuildHouse.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(buildID);
  SaveStream.Write(LocCount);
  SaveStream.Write(CurLoc);
  for i:=1 to length(Cells) do
  begin
    SaveStream.Write(Cells[i].Loc);
    SaveStream.Write(Cells[i].Dir,SizeOf(Cells[i].Dir));
  end;
end;


{ TTaskBuildHouseRepair }
constructor TTaskBuildHouseRepair.Create(aWorker:TKMUnitWorker; aHouse:TKMHouse; aID:integer);
  var i,k:integer; ht:byte; Loc:TKMPoint;
  procedure AddLoc(X,Y:word; Dir:TKMDirection);
  begin
    inc(LocCount);
    Cells[LocCount].Loc:=KMPoint(X,Y);
    Cells[LocCount].Dir:=byte(Dir);
  end;
begin
  Inherited Create(aWorker);
  fTaskName := utn_BuildHouseRepair;
  fHouse:=aHouse.GetSelf;
  Loc:=fHouse.GetPosition;
  buildID:=aID;
  LocCount:=0;
  CurLoc:=0;
  ht:=byte(fHouse.GetHouseType);
  //Create list of surrounding tiles and directions
  for i:=1 to 4 do for k:=1 to 4 do
  if HousePlanYX[ht,i,k]<>0 then
    if (i=1)or(HousePlanYX[ht,i-1,k]=0) then AddLoc(Loc.X + k - 3, Loc.Y + i - 4 - 1, dir_S) else //Up
    if (i=4)or(HousePlanYX[ht,i+1,k]=0) then AddLoc(Loc.X + k - 3, Loc.Y + i - 4 + 1, dir_N) else //Down
    if (k=4)or(HousePlanYX[ht,i,k+1]=0) then AddLoc(Loc.X + k - 3 + 1, Loc.Y + i - 4, dir_W) else //Right
    if (k=1)or(HousePlanYX[ht,i,k-1]=0) then AddLoc(Loc.X + k - 3 - 1, Loc.Y + i - 4, dir_E);     //Left
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskBuildHouseRepair.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  Inherited;
  LoadStream.Read(fHouse, 4);
  LoadStream.Read(buildID);
  LoadStream.Read(LocCount);
  LoadStream.Read(CurLoc);
  for i:=1 to length(Cells) do
  begin
    LoadStream.Read(Cells[i].Loc);
    LoadStream.Read(Cells[i].Dir, SizeOf(Cells[i].Dir));
  end;
end;


procedure TTaskBuildHouseRepair.SyncLoad();
begin
  Inherited;
  fHouse := fPlayers.GetHouseByID(integer(fHouse));
end;


destructor TTaskBuildHouseRepair.Destroy;
begin
  if fHouse <> nil then fHouse.RemovePointer;
  Inherited Destroy;
end;

function TTaskBuildHouseRepair.WalkShouldAbandon:boolean;
begin
  Result := (fHouse.IsDestroyed)or(not fHouse.IsDamaged)or(not fHouse.BuildingRepair);
end;

{Repair the house}
procedure TTaskBuildHouseRepair.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if (fHouse.IsDestroyed)or(not fHouse.IsDamaged)or(not fHouse.BuildingRepair) then begin
    Abandon;
    TaskDone:=true; //Drop the task
    exit;
  end;

  with fUnit do
    case fPhase of
      //Pick random location and go there
      0: begin
           fThought := th_Build;
           CurLoc:=Random(LocCount)+1;
           SetActionWalk(fUnit,Cells[CurLoc].Loc);
         end;
      1: begin
           Direction:=TKMDirection(Cells[CurLoc].Dir);
           SetActionLockedStay(0,ua_Walk);
         end;
      2: begin
           SetActionStay(5,ua_Work,false,0,0); //Start animation
           Direction:=TKMDirection(Cells[CurLoc].Dir);
         end;
      3: begin
           if (fCondition<UNIT_MIN_CONDITION) and CanGoEat then begin
             TaskDone:=true; //Drop the task
             exit;
           end;
           fHouse.AddRepair;
           SetActionStay(6,ua_Work,false,0,5); //Do building and end animation
           inc(fPhase2);
         end;
      4: begin
           fThought := th_None;
           fPlayers.Player[byte(fOwner)].BuildList.CloseHouse(buildID);
           SetActionStay(1,ua_Walk);
         end;
      else TaskDone:=true;
    end;
  inc(fPhase);
  if (fPhase=4) and (fHouse.IsDamaged) then //If animation cycle is done
    if fPhase2 mod 5 = 0 then //if worker did [5] hits from same spot
      fPhase:=0 //Then goto new spot
    else
      fPhase:=2; //else do more hits
end;


procedure TTaskBuildHouseRepair.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  inherited;
  if fHouse <> nil then
    SaveStream.Write(fHouse.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(buildID);
  SaveStream.Write(LocCount);
  SaveStream.Write(CurLoc);
  for i:=1 to length(Cells) do
  begin
    SaveStream.Write(Cells[i].Loc);
    SaveStream.Write(Cells[i].Dir, SizeOf(Cells[i].Dir));
  end;
end;


{ TTaskGoHome }
constructor TTaskGoHome.Create(aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_GoHome;
  if fUnit <> nil then fUnit.SetActionLockedStay(0, ua_Walk);
end;


procedure TTaskGoHome.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if fUnit.fHome.IsDestroyed then begin
    Abandon;
    TaskDone:=true;
    exit;
  end;
  with fUnit do
  case fPhase of
    0: begin
         fThought := th_Home;
         SetActionWalk(fUnit,KMPointY1(fHome.GetEntrance));
       end;
    1: SetActionGoIn(ua_Walk, gd_GoInside, fHome);
    2: begin
        fThought := th_None; //Only stop thinking once we are right inside
        fHome.SetState(hst_Idle);
        SetActionStay(5,ua_Walk);
       end;
    else TaskDone:=true;
  end;
  inc(fPhase);
  if (fUnit.fCurrentAction=nil)and(not TaskDone) then
    fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


{ TTaskDie }
constructor TTaskDie.Create(aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_Die;
  fUnit.SetActionLockedStay(0,ua_Walk);
  SequenceLength := fResource.GetUnitSequenceLength(fUnit.fUnitType,ua_Die,fUnit.Direction);
  if fUnit is TKMUnitAnimal then SequenceLength := 0; //Animals don't have a dying sequence. Can be changed later.
end;


constructor TTaskDie.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(SequenceLength);
end;


procedure TTaskDie.Execute(out TaskDone:boolean);
begin
TaskDone := false;
with fUnit do
case fPhase of
  0: if not fVisible then begin
       if fHome<>nil then begin
         fHome.SetState(hst_Idle);
         fHome.SetState(hst_Empty);
         SetActionGoIn(ua_Walk,gd_GoOutside,fUnit.fHome);
       end
       else
         SetActionGoIn(ua_Walk,gd_GoOutside,fPlayers.HousesHitTest(fUnit.NextPosition.X,fUnit.NextPosition.Y));
                                         //Inn or Store or etc.. for units without home.
                                         //Which means that our current approach to deduce housetype from
                                         //fUnit.fHome is wrong
     end else
     SetActionLockedStay(0,ua_Walk);
  1: if SequenceLength > 0 then SetActionLockedStay(SequenceLength,ua_Die,false)
     else SetActionLockedStay(0,ua_Walk);
  else begin
      fUnit.CloseUnit;
      exit;
     end;
end;
inc(fPhase);
end;


procedure TTaskDie.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  SaveStream.Write(SequenceLength);
end;

{ TTaskGoOutShowHungry }
constructor TTaskGoOutShowHungry.Create(aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_GoOutShowHungry;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskGoOutShowHungry.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
end;


procedure TTaskGoOutShowHungry.Execute(out TaskDone:boolean);
begin
  TaskDone:=false;
  if fUnit.fHome.IsDestroyed then begin
    Abandon;
    TaskDone:=true;
    exit;
  end;
  with fUnit do
  case fPhase of
    0: begin
         fThought := th_Eat;
         SetActionStay(20,ua_Walk);
       end;
    1: begin
         SetActionGoIn(ua_Walk,gd_GoOutside,fUnit.fHome);
         fHome.SetState(hst_Empty);
       end;
    2: SetActionStay(4,ua_Walk);
    3: SetActionGoIn(ua_Walk,gd_GoInside,fUnit.fHome);
    4: begin
         SetActionStay(20,ua_Walk);
         fHome.SetState(hst_Idle);
       end;
    else begin
         fThought := th_None;
         TaskDone := true;
       end;
  end;
  inc(fPhase);
  if (fUnit.fCurrentAction=nil)and(not TaskDone) then
    fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskGoOutShowHungry.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  //nothing more here yet
end;


{ TTaskGoEat }
constructor TTaskGoEat.Create(aInn:TKMHouseInn; aUnit:TKMUnit);
begin
  Inherited Create(aUnit);
  fTaskName := utn_GoEat;
  fInn      := TKMHouseInn(aInn.GetSelf);
  PlaceID   := 0;
  fUnit.SetActionLockedStay(0,ua_Walk);
end;


constructor TTaskGoEat.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(fInn, 4);
  LoadStream.Read(PlaceID);
end;


procedure TTaskGoEat.SyncLoad();
begin
  Inherited;
  fInn := TKMHouseInn(fPlayers.GetHouseByID(integer(fInn)));
end;


destructor TTaskGoEat.Destroy;
begin
  if fInn <> nil then fInn.RemovePointer;
  Inherited Destroy;
end;


procedure TTaskGoEat.Execute(out TaskDone:boolean);
begin
TaskDone:=false;

if fInn.IsDestroyed then
begin
  Abandon;
  TaskDone:=true;
  exit;
end;

with fUnit do
case fPhase of
 0: begin
      fThought := th_Eat;
      if fHome<>nil then fHome.SetState(hst_Empty);
      if not fVisible then SetActionGoIn(ua_Walk,gd_GoOutside,fUnit.fHome) else
                           SetActionLockedStay(0,ua_Walk); //Walk outside the house
    end;
 1: begin
      SetActionWalk(fUnit,KMPointY1(fInn.GetEntrance));
    end;
 2: begin
      SetActionGoIn(ua_Walk,gd_GoInside,fInn); //Enter Inn
      PlaceID := fInn.EaterGetsInside(fUnitType);
    end;
 3: //Units are fed acording to this: (from knightsandmerchants.de tips and tricks)
    //Bread    = +40%
    //Sausages = +60%
    //Wine     = +20%
    //Fish     = +50%
    if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Bread)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Bread);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.4);
      fInn.UpdateEater(PlaceID,2); //Order is Wine-Bread-Sausages-Fish
    end else
      SetActionLockedStay(0,ua_Walk);
 4: if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Sausages)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Sausages);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.6);
      fInn.UpdateEater(PlaceID,3);
    end else
      SetActionLockedStay(0,ua_Walk);
 5: if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Wine)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Wine);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.2);
      fInn.UpdateEater(PlaceID,1);
    end else
      SetActionLockedStay(0,ua_Walk);
 6: if (fCondition<UNIT_MAX_CONDITION)and(fInn.CheckResIn(rt_Fish)>0)and(PlaceID<>0) then begin
      fInn.ResTakeFromIn(rt_Fish);
      SetActionStay(29*4,ua_Eat,false);
      Feed(UNIT_MAX_CONDITION*0.5);
      fInn.UpdateEater(PlaceID,4);
    end else
      SetActionLockedStay(0,ua_Walk);
 7: begin
      //Stop showing hungry if we no longer are, but if we are then walk out of the inn thinking hungry so that the player will know that we haven't been fed
      if fCondition<UNIT_MAX_CONDITION then
        fThought := th_Eat
      else fThought := th_None;
      SetActionGoIn(ua_Walk,gd_GoOutside,fInn); //Exit Inn
      fInn.EatersGoesOut(PlaceID);
      PlaceID:=0;
    end;
 else TaskDone:=true;
end;
inc(fPhase);
if (fUnit.fCurrentAction=nil)and(not TaskDone) then
  fLog.AssertToLog(false,'(fUnit.fCurrentAction=nil)and(not TaskDone)');
end;


procedure TTaskGoEat.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  if fInn <> nil then
    SaveStream.Write(fInn.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Zero);
  SaveStream.Write(PlaceID);
end;


{ TUnitAction }
constructor TUnitAction.Create(aActionType: TUnitActionType);
begin
  Inherited Create;
  fActionName := uan_Unknown;
  fActionType := aActionType;
  IsStepDone  := false;
end;


constructor TUnitAction.Load(LoadStream:TKMemoryStream);
begin
  Inherited Create;
  LoadStream.Read(fActionName, SizeOf(fActionName));
  LoadStream.Read(fActionType, SizeOf(fActionType));
  LoadStream.Read(IsStepDone);
end;


procedure TUnitAction.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(fActionName, SizeOf(fActionName));
  SaveStream.Write(fActionType, SizeOf(fActionType));
  SaveStream.Write(IsStepDone);
end;


{ TKMUnitsCollection }
destructor TKMUnitsCollection.Destroy;
begin
  //No need to free units individually since they are Freed by TKMList.Clear command.
  Inherited;
end;


function TKMUnitsCollection.GetUnit(Index: Integer): TKMUnit;
begin
  Result := TKMUnit(Items[Index])
end;


procedure TKMUnitsCollection.SetUnit(Index: Integer; Item: TKMUnit);
begin
  Items[Index] := Item;
end;


{ AutoPlace means should we find a spot for this unit or just place it where we are told.
  Used for creating units still inside schools }
function TKMUnitsCollection.Add(aOwner: TPlayerID; aUnitType: TUnitType; PosX, PosY:integer; AutoPlace:boolean=true):TKMUnit;
var U:Integer; P:TKMPoint;
begin
  if AutoPlace then begin
    P:=fPlayers.FindPlaceForUnit(PosX,PosY,aUnitType);
    PosX:=P.X;
    PosY:=P.Y;
  end;

  if not fTerrain.TileInMapCoords(PosX, PosY) then begin
    fLog.AppendLog('Unable to add unit to '+TypeToString(KMPoint(PosX,PosY)));
    Result:=nil;
    exit;
  end;

  U:=-1;
  case aUnitType of
    ut_Serf:    U:= Inherited Add(TKMUnitSerf.Create(aOwner,PosX,PosY,aUnitType));
    ut_Worker:  U:= Inherited Add(TKMUnitWorker.Create(aOwner,PosX,PosY,aUnitType));

    ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                U:= Inherited Add(TKMUnitCitizen.Create(aOwner,PosX,PosY,aUnitType));

    ut_Recruit: U:= Inherited Add(TKMUnitCitizen.Create(aOwner,PosX,PosY,aUnitType));

    ut_Militia..ut_Barbarian:   U:= Inherited Add(TKMUnitWarrior.Create(aOwner,PosX,PosY,aUnitType));
    //ut_Bowman:   Inherited Add(TKMUnitArcher.Create(aOwner,PosX,PosY,aUnitType)); //I guess it will be stand-alone

    ut_Wolf..ut_Duck:           U:= Inherited Add(TKMUnitAnimal.Create(aOwner,PosX,PosY,aUnitType));

    else
    fLog.AssertToLog(false,'Such unit doesn''t exist yet - '+TypeToString(aUnitType));
  end;

  if U=-1 then Result:=nil else Result:=Units[U];

end;


function TKMUnitsCollection.AddGroup(aOwner:TPlayerID;  aUnitType:TUnitType; PosX, PosY:integer; aDir:TKMDirection; aUnitPerRow, aUnitCount:word):TKMUnit;
var U:TKMUnit; Commander,W:TKMUnitWarrior; i,px,py:integer; UnitPosition:TKMPoint;
begin
  aUnitPerRow := min(aUnitPerRow,aUnitCount); //Can have more rows than units
  if not (aUnitType in [ut_Militia .. ut_Barbarian]) then
  begin
    for i:=1 to aUnitCount do
    begin
      px := (i-1) mod aUnitPerRow - aUnitPerRow div 2;
      py := (i-1) div aUnitPerRow;
      UnitPosition := GetPositionInGroup(PosX, PosY, aDir, px, py);
      U := Add(aOwner, aUnitType, UnitPosition.X, UnitPosition.Y); //U will be _nil_ if unit didn't fit on map
      if U<>nil then
      begin
        fPlayers.Player[byte(aOwner)].CreatedUnit(aUnitType, false);
        U.Direction := aDir;
      end;
    end;
    Result := nil; //Dunno what to return here
    exit; // Don't do anything else for citizens
  end;

  //Add commander first
  Commander := TKMUnitWarrior(Add(aOwner, aUnitType, PosX, PosY));
  Result := Commander;

  if Commander=nil then exit; //Don't add group without a commander
  fPlayers.Player[byte(aOwner)].CreatedUnit(aUnitType, false);

  Commander.UnitsPerRow := aUnitPerRow;
  Commander.Direction := aDir;
  Commander.GetOrderLoc.Dir := byte(aDir)-1; //So when they click Halt for the first time it knows where to place them

  for i:=1 to aUnitCount do begin
    px := (i-1) mod aUnitPerRow - aUnitPerRow div 2;
    py := (i-1) div aUnitPerRow;
    UnitPosition := GetPositionInGroup(PosX, PosY, aDir, px, py);

    if not ((UnitPosition.X = PosX)and(UnitPosition.Y = PosY)) then //Skip commander
    begin
      W := TKMUnitWarrior(Add(aOwner, aUnitType, UnitPosition.X, UnitPosition.Y)); //W will be _nil_ if unit didn't fit on map
      if W<>nil then
      begin
        fPlayers.Player[byte(aOwner)].CreatedUnit(aUnitType, false);
        W.Direction := aDir;
        W.fCommander := Commander;
        W.fCondition := Commander.fCondition; //Whole group will have same condition
        Commander.AddMember(W);
      end;
    end;
  end;
end;


procedure TKMUnitsCollection.RemoveUnit(aUnit:TKMUnit);
begin
  aUnit.CloseUnit; //Should free up the unit properly (freeing terrain usage and memory)
  aUnit.Free;
  Remove(aUnit);
end;


function TKMUnitsCollection.HitTest(X, Y: Integer; const UT:TUnitType = ut_Any): TKMUnit;
var
  I: Integer;
begin
  Result:= nil;
  for I := 0 to Count - 1 do
    if Units[I].HitTest(X, Y, UT) and (not Units[I].IsDead) then
    begin
      Result:= Units[I];
      Break;
    end;
end;


function TKMUnitsCollection.GetUnitByID(aID: Integer): TKMUnit;
var i:integer;
begin
  Result := nil;
  for i := 0 to Count-1 do
    if aID = Units[i].ID then
    begin
      Result := Units[i];
      exit;
    end;
end;


procedure TKMUnitsCollection.GetLocations(aOwner:TPlayerID; out Loc:TKMPointList);
var i:integer;
begin
  Loc.Clearup;
  for I := 0 to Count - 1 do
    if (Units[i].fOwner = aOwner) and not(Units[i].fUnitType in [ut_Wolf..ut_Duck]) then
      Loc.AddEntry(Units[i].GetPosition);
end;


function TKMUnitsCollection.GetTotalPointers: integer;
var i:integer;
begin
  Result:=0;
  for I := 0 to Count - 1 do
    inc(Result, Units[i].GetPointerCount);
end;


function TKMUnitsCollection.GetUnitCount: integer;
begin
  Result := Count;
end;


function TKMUnitsCollection.GetUnitByIndex(aIndex:integer): TKMUnit;
begin
  Result := Units[aIndex];
end;


procedure TKMUnitsCollection.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  SaveStream.Write('Units');
  SaveStream.Write(Count);
  for i := 0 to Count - 1 do
    Units[i].Save(SaveStream);
end;


procedure TKMUnitsCollection.Load(LoadStream:TKMemoryStream);
var i,UnitCount:integer; s:string; UnitType:TUnitType;
begin
  LoadStream.Read(s); if s <> 'Units' then exit;
  LoadStream.Read(UnitCount);
  for i := 0 to UnitCount - 1 do
  begin
    LoadStream.Read(UnitType, SizeOf(UnitType));
    LoadStream.Seek(-SizeOf(UnitType), soFromCurrent); //rewind
    case UnitType of
      ut_Serf:                  Inherited Add(TKMUnitSerf.Load(LoadStream));
      ut_Worker:                Inherited Add(TKMUnitWorker.Load(LoadStream));
      ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                                Inherited Add(TKMUnitCitizen.Load(LoadStream));
      ut_Recruit:               Inherited Add(TKMUnitCitizen.Load(LoadStream));
      ut_Militia..ut_Barbarian: Inherited Add(TKMUnitWarrior.Load(LoadStream));
      //ut_Bowman:   Inherited Add(TKMUnitArcher.Load(LoadStream)); //I guess it will be stand-alone
      ut_Wolf..ut_Duck:         Inherited Add(TKMUnitAnimal.Load(LoadStream));
    else fLog.AssertToLog(false, 'Unknown unit type in Savegame')
    end;
  end;
end;


procedure TKMUnitsCollection.SyncLoad();
var i:integer;
begin
  for i := 0 to Count - 1 do
  begin
    case Units[i].fUnitType of
      ut_Serf:                  TKMUnitSerf(Items[I]).SyncLoad;
      ut_Worker:                TKMUnitWorker(Items[I]).SyncLoad;
      ut_WoodCutter..ut_Fisher,{ut_Worker,}ut_StoneCutter..ut_Metallurgist:
                                TKMUnitCitizen(Items[I]).SyncLoad;
      ut_Recruit:               TKMUnitCitizen(Items[I]).SyncLoad;
      ut_Militia..ut_Barbarian: TKMUnitWarrior(Items[I]).SyncLoad;
      //ut_Bowman:              TKMUnitArcher(Items[I]).SyncLoad; //I guess it will be stand-alone
      ut_Wolf..ut_Duck:         TKMUnitAnimal(Items[I]).SyncLoad;
    end;
  end;
end;


procedure TKMUnitsCollection.UpdateState;
var
  I, ID: Integer;
  IDsToDelete: array of integer;
begin
  ID := 0;
  for I := 0 to Count - 1 do
  if not Units[i].IsDead then
    Units[i].UpdateState
  else //Else try to destroy the unit object if all pointers are freed
    if (Items[I] <> nil) and FREE_POINTERS and (Units[i].GetPointerCount = 0) then
    begin
      SetLength(IDsToDelete,ID+1);
      IDsToDelete[ID] := I;
      inc(ID);
    end;

  //Must remove list entry after for loop is complete otherwise the indexes change
  for I := ID-1 downto 0 do
  begin
    Units[IDsToDelete[I]].Free; //Because no one needs this anymore it must DIE!!!!! :D
    Delete(IDsToDelete[I]);
  end;

  //   --     POINTER FREEING SYSTEM - DESCRIPTION     --   //
  //  This system was implemented because unit and house objects cannot be freed until all pointers to them
  //  (in tasks, delivery queue, etc.) have been freed, otherwise we have pointer integrity issues.

  //   --     ROUGH OUTLINE     --   //
  // - Units and houses have fPointerCount, which is the number of pointers to them. (e.g. tasks, deliveries)
  //   This is kept up to date by the thing that is using the pointer. On create it uses GetSelf to increase
  //   the pointer count and on destroy it decreases it. (this will be a source of errors and will need to be checked when changing pointers)
  // - When a unit dies, the object is not destroyed. Instead a flag (boolean) is set to say that we want to
  //   destroy but can't because there are still pointers to the unit. From then on every update state it checks
  //   to see if the pointer count is 0 yet. If it is then the unit is destroyed.
  // - For each place that contains a pointer, it should check everytime the pointer is used to see if it has been
  //   destroy. If it has then we free the pointer and reduce the count. (and do any other action nececary due to the unit/house dying)

end;


procedure TKMUnitsCollection.Paint();
var i:integer; x1,x2,y1,y2,Margin:integer;
begin
  if TestViewportClipInset then Margin:=-3 else Margin:=3;
  x1 := fViewport.GetClip.Left - Margin;
  x2 := fViewport.GetClip.Right + Margin;
  y1 := fViewport.GetClip.Top - Margin;
  y2 := fViewport.GetClip.Bottom + Margin;

  for I := 0 to Count - 1 do
  if (Items[I] <> nil) and (not Units[i].IsDead) then
  if (InRange(Units[i].fPosition.X,x1,x2) and InRange(Units[i].fPosition.Y,y1,y2)) then
    Units[i].Paint();
end;


end.
