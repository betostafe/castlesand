unit KM_UnitActionStay;
{$I KaM_Remake.inc}
interface
uses Classes, KM_Defaults, KromUtils, KM_CommonTypes, KM_Units, SysUtils, Math, KM_Points;

{Stay in place for set time}
type
  TUnitActionStay = class(TUnitAction)
  private
    StayStill:boolean;
    TimeToStay:integer;
    StillFrame:byte;
    procedure MakeSound(KMUnit: TKMUnit; Cycle,Step:byte);
  public
    constructor Create(aTimeToStay:integer; aActionType:TUnitActionType; aStayStill:boolean; aStillFrame:byte; aLocked:boolean);
    constructor Load(LoadStream:TKMemoryStream); override;
    class function ActName: TUnitActionName; override;
    function GetExplanation: string; override;
    function HowLongLeftToStay:integer;
    function Execute(KMUnit: TKMUnit):TActionResult; override;
    procedure Save(SaveStream:TKMemoryStream); override;
  end;


implementation
uses KM_PlayersCollection, KM_Sound, KM_ResourceGFX;


{ TUnitActionStay }
constructor TUnitActionStay.Create(aTimeToStay:integer; aActionType:TUnitActionType; aStayStill:boolean; aStillFrame:byte; aLocked:boolean);
begin
  Inherited Create(aActionType);
  StayStill   := aStayStill;
  TimeToStay  := aTimeToStay;
  StillFrame  := aStillFrame;
  Locked      := aLocked;
end;


constructor TUnitActionStay.Load(LoadStream:TKMemoryStream);
begin
  Inherited;
  LoadStream.Read(StayStill);
  LoadStream.Read(TimeToStay);
  LoadStream.Read(StillFrame);
end;


class function TUnitActionStay.ActName: TUnitActionName;
begin
  Result := uan_Stay;
end;


function TUnitActionStay.GetExplanation: string;
begin
  Result := 'Staying';
end;


//If someone whats to know how much time unit has to stay
function TUnitActionStay.HowLongLeftToStay:integer;
begin
  Result := EnsureRange(TimeToStay, 0, maxint);
end;


procedure TUnitActionStay.MakeSound(KMUnit: TKMUnit; Cycle,Step:byte);
begin
  //Do not play sounds if unit is invisible to MyPlayer
  if MyPlayer.FogOfWar.CheckTileRevelation(KMUnit.GetPosition.X, KMUnit.GetPosition.Y) < 255 then exit;

  //Various UnitTypes and ActionTypes produce all the sounds
  case KMUnit.UnitType of 
    ut_Worker: case ActionType of
                 ua_Work:  if Step = 3 then fSoundLib.Play(sfx_housebuild,KMUnit.PositionF);
                 ua_Work1: if Step = 0 then fSoundLib.Play(sfx_Dig,KMUnit.PositionF);
                 ua_Work2: if Step = 8 then fSoundLib.Play(sfx_Pave,KMUnit.PositionF);
               end;
    ut_Farmer: case ActionType of
                 ua_Work:  if Step = 8 then fSoundLib.Play(sfx_CornCut,KMUnit.PositionF);
                 ua_Work1: if Step = 0 then fSoundLib.Play(sfx_CornSow,KMUnit.PositionF,true,0.6);
               end;
    ut_StoneCutter: if ActionType = ua_Work then
                           if Step = 3 then fSoundLib.Play(sfx_minestone,KMUnit.PositionF,true,1.4);
    ut_WoodCutter: case ActionType of
                     ua_Work: if (KMUnit.AnimStep mod Cycle = 3) and (KMUnit.Direction <> dir_N) then fSoundLib.Play(sfx_ChopTree, KMUnit.PositionF,true)
                     else     if (KMUnit.AnimStep mod Cycle = 0) and (KMUnit.Direction =  dir_N) then fSoundLib.Play(sfx_WoodcutterDig, KMUnit.PositionF,true);
                   end;
  end;
end;


function TUnitActionStay.Execute(KMUnit: TKMUnit):TActionResult;
var Cycle,Step:byte;
begin
  if not StayStill then
  begin
    Cycle := max(fResource.UnitDat[KMUnit.UnitType].UnitAnim[ActionType, KMUnit.Direction].Count, 1);
    Step  := KMUnit.AnimStep mod Cycle;

    StepDone := KMUnit.AnimStep mod Cycle = 0;

    if TimeToStay >= 1 then MakeSound(KMUnit, Cycle, Step);

    inc(KMUnit.AnimStep);
  end
  else
  begin
    KMUnit.AnimStep := StillFrame;
    StepDone := true;
  end;

  dec(TimeToStay);
  if TimeToStay<=0 then
    Result := ActDone
  else
    Result := ActContinues;
end;


procedure TUnitActionStay.Save(SaveStream:TKMemoryStream);
begin
  Inherited;
  SaveStream.Write(StayStill);
  SaveStream.Write(TimeToStay);
  SaveStream.Write(StillFrame);
end;




end.
