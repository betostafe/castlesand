unit KM_UnitActionFight;
{$I KaM_Remake.inc}
interface
uses Classes, KM_CommonClasses, KM_Defaults, KM_Utils, KromUtils, Math, SysUtils, KM_Units, KM_Points;

{Fight until we die or the opponent dies}
type
  TUnitActionFight = class(TUnitAction)
  private
    fFightDelay:integer; //Pause for this many ticks before going onto the next Step
    fOpponent:TKMUnit; //Who we are fighting with
    fVertexOccupied: TKMPoint; //The diagonal vertex we are currently occupying

    //Execute is broken up into multiple methods
      function ExecuteValidateOpponent(Step:byte): TActionResult;
      function ExecuteProcessRanged(Step:byte):boolean;
      function ExecuteProcessMelee(Step:byte):boolean;

    function UpdateVertexUsage(aFrom, aTo: TKMPoint):boolean;
    procedure IncVertex(aFrom, aTo: TKMPoint);
    procedure DecVertex;
    procedure MakeSound(IsHit:boolean);
  public
    constructor Create(aUnit: TKMUnit; aActionType: TUnitActionType; aOpponent: TKMUnit);
    constructor Load(LoadStream:TKMemoryStream); override;
    destructor Destroy; override;
    function ActName: TUnitActionName; override;
    function GetExplanation:string; override;
    procedure SyncLoad; override;
    property GetOpponent: TKMUnit read fOpponent;
    function Execute: TActionResult; override;
    procedure Save(SaveStream:TKMemoryStream); override;
  end;


implementation
uses KM_PlayersCollection, KM_Sound, KM_Units_Warrior, KM_Game, KM_Resource;

const STRIKE_STEP = 5; //Melee units place hit on step 5

const
  MeleeSoundsHit:array[0..14] of TSoundFX = (
    sfx_Melee34, sfx_Melee35, sfx_Melee36, sfx_Melee41, sfx_Melee42,
    sfx_Melee44, sfx_Melee45, sfx_Melee46, sfx_Melee47, sfx_Melee48,
    sfx_Melee49, sfx_Melee50, sfx_Melee55, sfx_Melee56, sfx_Melee57);

  MeleeSoundsMiss: array [0..8] of TSoundFX = (
    sfx_Melee37, sfx_Melee38, sfx_Melee39,
    sfx_Melee40, sfx_Melee43, sfx_Melee51,
    sfx_Melee52, sfx_Melee53, sfx_Melee54);


{ TUnitActionFight }
constructor TUnitActionFight.Create(aUnit: TKMUnit; aActionType: TUnitActionType; aOpponent: TKMUnit);
begin
  inherited Create(aUnit, aActionType, True);
  fFightDelay     := -1;
  fOpponent       := aOpponent.GetUnitPointer;
  aUnit.Direction := KMGetDirection(fUnit.GetPosition, fOpponent.GetPosition); //Face the opponent from the beginning
  fVertexOccupied := KMPoint(0,0);
  if KMStepIsDiag(fUnit.GetPosition, fOpponent.GetPosition) and not TKMUnitWarrior(fUnit).IsRanged then
    IncVertex(fUnit.GetPosition, fOpponent.GetPosition);
end;


destructor TUnitActionFight.Destroy;
begin
  fPlayers.CleanUpUnitPointer(fOpponent);
  if not KMSamePoint(fVertexOccupied, KMPoint(0,0)) then
    DecVertex;
  inherited;
end;


constructor TUnitActionFight.Load(LoadStream:TKMemoryStream);
begin
  inherited;
  LoadStream.Read(fOpponent, 4);
  LoadStream.Read(fFightDelay);
  LoadStream.Read(fVertexOccupied);
end;


procedure TUnitActionFight.SyncLoad;
begin
  inherited;
  fOpponent := fPlayers.GetUnitByID(cardinal(fOpponent));
end;


function TUnitActionFight.ActName: TUnitActionName;
begin
  Result := uan_Fight;
end;


function TUnitActionFight.GetExplanation: string;
begin
  Result := 'Fighting';
end;


function TUnitActionFight.UpdateVertexUsage(aFrom, aTo: TKMPoint):boolean;
begin
  Result := true;
  if KMStepIsDiag(aFrom, aTo) then
  begin
    //If the new target has the same vertex as the old one, no change is needed
    if KMSamePoint(KMGetDiagVertex(aFrom, aTo), fVertexOccupied) then Exit;
    //Otherwise the new target's vertex is different to the old one, so remove old vertex usage and add new
    DecVertex;
    if fUnit.VertexUsageCompatible(aFrom, aTo) then
      IncVertex(aFrom, aTo)
    else
      Result := false; //This vertex is being used so we can't fight
  end
  else
    //The new target is not diagonal, make sure any old vertex usage is removed
    DecVertex;
end;


procedure TUnitActionFight.IncVertex(aFrom, aTo: TKMPoint);
begin
  //Tell fTerrain that this vertex is being used so no other unit walks over the top of us
  Assert(KMSamePoint(fVertexOccupied, KMPoint(0,0)), 'Fight vertex in use');

  fUnit.VertexAdd(aFrom, aTo);
  fVertexOccupied := KMGetDiagVertex(aFrom,aTo);
end;


procedure TUnitActionFight.DecVertex;
begin
  //Tell fTerrain that this vertex is not being used anymore
  if KMSamePoint(fVertexOccupied, KMPoint(0,0)) then exit;

  fUnit.VertexRem(fVertexOccupied);
  fVertexOccupied := KMPoint(0,0);
end;


procedure TUnitActionFight.MakeSound(IsHit:boolean);
var MakeBattleCry: boolean;
begin
  //Randomly make a battle cry. KaMRandom must always happen regardless of tile relevation.
  MakeBattleCry := KaMRandom(20) = 0;

  //Do not play sounds if unit is invisible to MyPlayer
  //We should not use KaMRandom below this line because sound playback depends on FOW and is individual for each player
  if MyPlayer.FogOfWar.CheckTileRevelation(fUnit.GetPosition.X, fUnit.GetPosition.Y, true) < 255 then exit;

  if MakeBattleCry then fSoundLib.PlayWarrior(fUnit.UnitType, sp_BattleCry, fUnit.PositionF);

  case fUnit.UnitType of
    ut_Arbaletman: fSoundLib.Play(sfx_CrossbowDraw, fUnit.PositionF); //Aiming
    ut_Bowman:     fSoundLib.Play(sfx_BowDraw,      fUnit.PositionF); //Aiming
    ut_Slingshot:  fSoundLib.Play(sfx_SlingerShoot, fUnit.PositionF);
    else           begin
                     if IsHit then
                       fSoundLib.Play(MeleeSoundsHit[Random(Length(MeleeSoundsHit))], fUnit.PositionF)
                     else
                       fSoundLib.Play(MeleeSoundsMiss[Random(Length(MeleeSoundsMiss))], fUnit.PositionF);
                   end;
  end;
end;


function TUnitActionFight.ExecuteValidateOpponent(Step:byte): TActionResult;
begin
  Result := ActContinues;
  //See if Opponent has walked away (i.e. Serf) or died
  if (fOpponent.IsDeadOrDying) or (not fOpponent.Visible) //Don't continue to fight dead units in units that have gone into a house
  or not InRange(KMLength(fUnit.GetPosition, fOpponent.GetPosition), TKMUnitWarrior(fUnit).GetFightMinRange, TKMUnitWarrior(fUnit).GetFightMaxRange)
  or not fUnit.CanWalkDiagonaly(fUnit.GetPosition, fOpponent.GetPosition) then //Might be a tree between us now
  begin
    //After killing an opponent there is a very high chance that there is another enemy to be fought immediately
    //Try to start fighting that enemy by reusing this FightAction, rather than destorying it and making a new one
    Locked := false; //Fight can be interrupted by FindEnemy, otherwise it will always return nil!
    fPlayers.CleanUpUnitPointer(fOpponent); //We are finished with the old opponent
    fOpponent := TKMUnitWarrior(fUnit).FindEnemy; //Find a new opponent
    if fOpponent <> nil then
    begin
      //Start fighting this opponent by resetting the action
      fOpponent.GetUnitPointer; //Add to pointer count
      Locked := true;
      fFightDelay := -1;
      //Ranged units should turn to face the new opponent immediately
      if TKMUnitWarrior(fUnit).IsRanged then
        fUnit.Direction := KMGetDirection(fUnit.GetPosition, fOpponent.GetPosition)
      else
        //Melee: If we haven't yet placed our strike, reset the animation step
        //Otherwise finish this strike then we can face the new opponent automatically
        if Step <= STRIKE_STEP then
          fUnit.AnimStep := 0; //Rest fight animation/sequence
    end
    else
    begin
      //Tell commanders to reposition after a fight, if we don't have other plans (order)
      if TKMUnitWarrior(fUnit).IsCommander and not TKMUnitWarrior(fUnit).ArmyInFight and
         (TKMUnitWarrior(fUnit).GetOrder = wo_None) and (fUnit.UnitTask = nil) then
        TKMUnitWarrior(fUnit).OrderWalk(fUnit.GetPosition); //Don't use halt because that returns us to fOrderLoc
      //No one else to fight, so we exit
      Result := ActDone;
    end;
  end;
end;


//A result of true means exit from Execute
function TUnitActionFight.ExecuteProcessRanged(Step:byte):boolean;
begin
  Result := false;
  if Step = FIRING_DELAY then
  begin
    if fFightDelay=-1 then //Initialize
    begin
      if fUnit.UnitType <> ut_Slingshot then MakeSound(False);
      fFightDelay := AIMING_DELAY_MIN + KaMRandom(AIMING_DELAY_ADD);
    end;

    if fFightDelay>0 then begin
      dec(fFightDelay);
      Result := true; //do not increment AnimStep, just exit;
      exit;
    end;
    if fUnit.UnitType = ut_Slingshot then MakeSound(false);

    //Fire the arrow
    case fUnit.UnitType of
      ut_Arbaletman: fGame.Projectiles.AimTarget(fUnit.PositionF, fOpponent, pt_Bolt, fUnit.GetOwner, RANGE_ARBALETMAN_MAX, RANGE_ARBALETMAN_MIN);
      ut_Bowman:     fGame.Projectiles.AimTarget(fUnit.PositionF, fOpponent, pt_Arrow, fUnit.GetOwner, RANGE_BOWMAN_MAX, RANGE_BOWMAN_MIN);
      ut_Slingshot:  ;
      else Assert(false, 'Unknown shooter');
    end;

    fFightDelay := -1; //Reset
  end;
  if Step = SLINGSHOT_FIRING_DELAY then
    if fUnit.UnitType = ut_Slingshot then
      fGame.Projectiles.AimTarget(fUnit.PositionF, fOpponent, pt_SlingRock, fUnit.GetOwner, RANGE_SLINGSHOT_MAX, RANGE_SLINGSHOT_MIN);
end;


//A result of true means exit from Execute
function TUnitActionFight.ExecuteProcessMelee(Step:byte):boolean;
var IsHit: boolean; Damage: word;
begin
  Result := false;
  //Melee units place hit on this step
  if Step = STRIKE_STEP then
  begin
    //Base damage is the unit attack strength + AttackHorse if the enemy is mounted
    Damage := fResource.UnitDat[fUnit.UnitType].Attack;
    if (fOpponent.UnitType in [low(UnitGroups) .. high(UnitGroups)]) and (UnitGroups[fOpponent.UnitType] = gt_Mounted) then
      Damage := Damage + fResource.UnitDat[fUnit.UnitType].AttackHorse;

    Damage := Damage * (GetDirModifier(fUnit.Direction,fOpponent.Direction)+1); //Direction modifier
    //Defence modifier
    Damage := Damage div Math.max(fResource.UnitDat[fOpponent.UnitType].Defence, 1); //Not needed, but animals have 0 defence

    IsHit := (Damage >= KaMRandom(101)); //Damage is a % chance to hit
    if IsHit then
      if fOpponent.HitPointsDecrease(1) then
        fPlayers.Player[fUnit.GetOwner].Stats.UnitKilled(fOpponent.UnitType);

    MakeSound(IsHit); //Different sounds for hit and for miss
  end;

  //In KaM melee units pause for 1 tick on Steps [0,3,6]. Made it random so troops are not striking in sync,
  //plus it adds randomness to battles
  if Step in [0,3,6] then
  begin
    if fFightDelay=-1 then //Initialize
    begin
      fFightDelay := KaMRandom(2);
    end;

    if fFightDelay>0 then begin
      dec(fFightDelay);
      Result := true; //Means exit from Execute
      exit;
    end;

    fFightDelay := -1; //Reset
  end;
end;


function TUnitActionFight.Execute: TActionResult;
var Cycle,Step:byte;
begin
  Cycle := max(fResource.UnitDat[fUnit.UnitType].UnitAnim[ActionType, fUnit.Direction].Count, 1);
  Step  := fUnit.AnimStep mod Cycle;

  Result := ExecuteValidateOpponent(Step);
  if Result = ActDone then exit;
  Step  := fUnit.AnimStep mod Cycle; //Can be changed by ExecuteValidateOpponent, so recalculate it

  //Opponent can walk next to us, keep facing him
  if Step = 0 then //Only change direction between strikes, otherwise it looks odd
    fUnit.Direction := KMGetDirection(fUnit.GetPosition, fOpponent.GetPosition);

  //If the vertex usage has changed we should update it
  if not TKMUnitWarrior(fUnit).IsRanged then //Ranged units do not use verticies
    if not UpdateVertexUsage(fUnit.GetPosition, fOpponent.GetPosition) then
    begin
      //The vertex is being used so we can't fight
      Result := ActDone;
      exit;
    end;

  if Step = 1 then
  begin
    //Tell the Opponent we are attacking him
    fPlayers.Player[fOpponent.GetOwner].AI.UnitAttackNotification(fOpponent, TKMUnitWarrior(fUnit));

    //Tell our AI that we are in a battle and might need assistance! (only for melee battles against warriors)
    if (fOpponent is TKMUnitWarrior) and not TKMUnitWarrior(fUnit).IsRanged then
      fPlayers.Player[fUnit.GetOwner].AI.UnitAttackNotification(fUnit, TKMUnitWarrior(fOpponent));
  end;

  if TKMUnitWarrior(fUnit).IsRanged then
  begin
    if ExecuteProcessRanged(Step) then
      exit;
  end
  else
    if ExecuteProcessMelee(Step) then
      exit;

  //Aiming Archers and pausing melee may miss a few ticks, (exited above) so don't put anything critical below!

  StepDone := (fUnit.AnimStep mod Cycle = 0) or TKMUnitWarrior(fUnit).IsRanged; //Archers may abandon at any time as they need to walk off imediantly
  inc(fUnit.AnimStep);
end;


procedure TUnitActionFight.Save(SaveStream:TKMemoryStream);
begin
  inherited;
  if fOpponent <> nil then
    SaveStream.Write(fOpponent.ID) //Store ID, then substitute it with reference on SyncLoad
  else
    SaveStream.Write(Integer(0));
  SaveStream.Write(fFightDelay);
  SaveStream.Write(fVertexOccupied);
end;




end.
