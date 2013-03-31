unit KM_PlayerAI;
{$I KaM_Remake.inc}
interface
uses Classes, KromUtils,
    KM_CommonClasses, KM_Defaults, KM_Houses, KM_Units, KM_Units_Warrior, KM_Utils, KM_Points;

type //For now IDs must match with KaM
  TAIDefencePosType = (adt_FrontLine=0, //Front line troops may not go on attacks, they are for defence
                       adt_BackLine=1); //Back line troops may attack

  TAIDefencePosition = class
  private
    fCurrentCommander: TKMUnitWarrior; //Commander of group currently occupying position
    procedure SetCurrentCommander(aCommander: TKMUnitWarrior);
    procedure ClearCurrentCommander;
  public
    Position: TKMPointDir; //Position and direction the group defending will stand
    GroupType: TGroupType; //Type of group to defend this position (e.g. melee)
    DefenceRadius: integer; //If fighting (or houses being attacked) occurs within this radius from this defence position, this group will get involved
    DefenceType: TAIDefencePosType; //Whether this is a front or back line defence position. See comments on TAIDefencePosType above
    constructor Create(aPos:TKMPointDir; aGroupType:TGroupType; aDefenceRadius:integer; aDefenceType:TAIDefencePosType);
    constructor Load(LoadStream:TKMemoryStream);
    destructor Destroy; override;
    property CurrentCommander: TKMUnitWarrior read fCurrentCommander write SetCurrentCommander;
    procedure Save(SaveStream:TKMemoryStream);
    procedure SyncLoad;
    function IsFullyStocked(aAmount: integer):boolean;
  end;

  TKMPlayerAI = class
  private
    PlayerIndex:integer;
    fTimeOfLastAttackMessage: cardinal;
    fLastEquippedTime: cardinal;
    fHasWonOrLost:boolean; //Has this player won/lost? If so, do not check goals

    fAutobuild:boolean;

    procedure CheckGoals;
    procedure CheckUnitCount;
    procedure CheckArmiesCount;
    procedure CheckArmy;
    function CheckAttackMayOccur(aAttack: TAIAttack; MenAvailable:integer; GroupsAvailableCount: array of integer):boolean;
    procedure OrderAttack(aCommander: TKMUnitWarrior; aTarget: TAIAttackTarget; aCustomPos: TKMPoint);
    procedure RestockPositionWith(aDefenceGroup, aCommander:TKMUnitWarrior);
    function FindPlaceForWarrior(aWarrior:TKMUnitWarrior; aCanLinkToExisting, aTakeClosest:boolean):boolean;
    procedure RetaliateAgainstThreat(aAttacker: TKMUnitWarrior);

  public
    ReqWorkers, ReqSerfFactor, ReqRecruits: word; //Number of each unit type required
    EquipRate: word; //Number of ticks between soldiers being equipped
    RecruitTrainTimeout: Cardinal; //Recruits (for barracks) can only be trained after this many ticks
    TownDefence, MaxSoldiers, Aggressiveness: integer; //-1 means not used or default
    StartPosition: TKMPoint; //Defines roughly where to defend and build around
    TroopFormations: array[TGroupType] of record //Defines how defending troops will be formatted. 0 means leave unchanged.
                                            NumUnits, UnitsPerRow:integer;
                                          end;
    DefencePositionsCount: integer;
    DefencePositions: array of TAIDefencePosition;
    ScriptedAttacksCount: integer;
    ScriptedAttacks: array of TAIAttack;
    constructor Create(aPlayerIndex:integer);
    destructor Destroy; override;

    property Autobuild:boolean read fAutobuild write fAutobuild;

    procedure OwnerUpdate(aPlayer:TPlayerIndex);

    procedure CommanderDied(DeadCommander, NewCommander: TKMUnitWarrior);
    procedure HouseAttackNotification(aHouse: TKMHouse; aAttacker:TKMUnitWarrior);
    procedure UnitAttackNotification(aUnit: TKMUnit; aAttacker:TKMUnitWarrior);
    procedure WarriorEquipped(aWarrior: TKMUnitWarrior);

    function HouseAutoRepair:boolean; //Do we automatically repair all houses?
    procedure AddDefencePosition(aPos:TKMPointDir; aGroupType:TGroupType; aDefenceRadius:integer; aDefenceType:TAIDefencePosType);
    procedure AddAttack(aAttack: TAIAttack);

    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
    procedure SyncLoad;
    procedure UpdateState;

  end;


implementation
uses KM_Game, KM_PlayersCollection, KM_TextLibrary, KM_Goals, KM_Player, KM_PlayerStats, KM_UnitTaskAttackHouse,
     KM_Terrain, KM_ResourceGFX, KM_Sound, KM_MessageStack;


const
  //For compatibility with KaM these must be false. We can add a !REMAKE_AI command later
  //to make them more "intelligent", but for now these are required for the campaigns to be playable.
  AI_FILL_CLOSEST = false;
  AI_LINK_IDLE = false;


constructor TAIDefencePosition.Create(aPos:TKMPointDir; aGroupType:TGroupType; aDefenceRadius:integer; aDefenceType:TAIDefencePosType);
begin
  Inherited Create;
  Position := aPos;
  GroupType := aGroupType;
  DefenceRadius := aDefenceRadius;
  DefenceType := aDefenceType;
  CurrentCommander := nil; //Unoccupied
end;


destructor TAIDefencePosition.Destroy;
begin
  ClearCurrentCommander; //Ensure pointer is removed
  Inherited;
end;


procedure TAIDefencePosition.ClearCurrentCommander;
begin
  fPlayers.CleanUpUnitPointer(fCurrentCommander);
end;


procedure TAIDefencePosition.SetCurrentCommander(aCommander: TKMUnitWarrior);
begin
  ClearCurrentCommander;
  if aCommander <> nil then
    fCurrentCommander := TKMUnitWarrior(aCommander.GetUnitPointer);
end;


procedure TAIDefencePosition.Save(SaveStream:TKMemoryStream);
begin
  SaveStream.Write(Position);
  SaveStream.Write(GroupType, SizeOf(GroupType));
  SaveStream.Write(DefenceRadius);
  SaveStream.Write(DefenceType, SizeOf(DefenceType));
  if fCurrentCommander <> nil then
    SaveStream.Write(fCurrentCommander.ID) //Store ID
  else
    SaveStream.Write(Integer(0));
end;


constructor TAIDefencePosition.Load(LoadStream:TKMemoryStream);
begin
  Inherited Create;
  LoadStream.Read(Position);
  LoadStream.Read(GroupType, SizeOf(GroupType));
  LoadStream.Read(DefenceRadius);
  LoadStream.Read(DefenceType, SizeOf(DefenceType));
  LoadStream.Read(fCurrentCommander, 4); //subst on syncload
end;


procedure TAIDefencePosition.SyncLoad;
begin
  fCurrentCommander := TKMUnitWarrior(fPlayers.GetUnitByID(cardinal(fCurrentCommander)));
end;


function TAIDefencePosition.IsFullyStocked(aAmount: integer):boolean;
begin
  Result := (CurrentCommander <> nil) and (CurrentCommander.GetMemberCount+1 >= aAmount);
end;


{ TKMPlayerAI }
constructor TKMPlayerAI.Create(aPlayerIndex:integer);
var i: TGroupType;
begin
  Inherited Create;

  PlayerIndex := aPlayerIndex;
  fHasWonOrLost := false;
  fTimeOfLastAttackMessage := 0;
  DefencePositionsCount := 0;
  ScriptedAttacksCount := 0;
  //Set some defaults (these are not measured from KaM)
  ReqWorkers := 3;
  ReqRecruits := 5; //This means the number in the barracks, watchtowers are counted seperately
  EquipRate := 1000; //Measured in KaM: AI equips 1 soldier every ~100 seconds
  ReqSerfFactor := 10; //Means 1 serf per building
  RecruitTrainTimeout := 0; //Can train at start
  fAutobuild := true; //In KaM it is on by default, and most missions turn it off
  StartPosition := KMPoint(1,1);
  MaxSoldiers := high(MaxSoldiers); //No limit by default
  TownDefence := 100; //In KaM 100 is standard, although we don't completely understand this command
  Aggressiveness := 100; //No idea what the default for this is, it's barely used
  for i:=low(TGroupType) to high(TGroupType) do
  begin
    TroopFormations[i].NumUnits := 9; //These are the defaults in KaM
    TroopFormations[i].UnitsPerRow := 3;
  end;
end;


destructor TKMPlayerAI.Destroy;
var i: integer;
begin
  for i:=0 to DefencePositionsCount-1 do DefencePositions[i].Free;
  Inherited;
end;


procedure TKMPlayerAI.CheckGoals;

  function GoalConditionSatisfied(aGoal: TKMGoal):boolean;
  var MS: TKMPlayerStats;
  begin
    Result := false;

    if aGoal.PlayerIndex <> -1 then
      MS := fPlayers[aGoal.PlayerIndex].Stats
    else
      MS := nil;
    Assert((MS <> nil) or (aGoal.GoalCondition = gc_Time)); //Will trigger an error unless it's not gc_Time

    case aGoal.GoalCondition of //todo: add all goal condition checks properly and confirm unknowns with tests in KaM
      gc_BuildTutorial:     Result := MS.GetHouseQty(ht_Tannery)>0;
      gc_Time:              Result := fGame.CheckTime(aGoal.GoalTime);
      gc_Buildings:         Result := (MS.GetHouseQty(ht_Store)>0)or(MS.GetHouseQty(ht_School)>0)or(MS.GetHouseQty(ht_Barracks)>0);
      gc_Troops:            Result := (MS.GetArmyCount>0);
      gc_MilitaryAssets:    Result := (MS.GetArmyCount>0)or(MS.GetHouseQty(ht_Barracks)>0)or(MS.GetHouseQty(ht_CoalMine)>0)or
                                      (MS.GetHouseQty(ht_WeaponWorkshop)>0)or(MS.GetHouseQty(ht_ArmorWorkshop)>0)or(MS.GetHouseQty(ht_Stables)>0)or
                                      (MS.GetHouseQty(ht_IronMine)>0)or(MS.GetHouseQty(ht_IronSmithy)>0)or(MS.GetHouseQty(ht_WeaponSmithy)>0)or
                                      (MS.GetHouseQty(ht_ArmorSmithy)>0)or(MS.GetHouseQty(ht_TownHall)>0)or(MS.GetHouseQty(ht_SiegeWorkshop)>0);
      gc_SerfsAndSchools:   Result := (MS.GetHouseQty(ht_School)>0)or(MS.GetUnitQty(ut_Serf)>0);
      gc_EconomyBuildings:  Result := ((MS.GetHouseQty(ht_Store)>0)or(MS.GetHouseQty(ht_School)>0)or(MS.GetHouseQty(ht_Inn)>0));
      else                  Assert(false, 'Unknown goal');
    end;
    if aGoal.GoalStatus = gs_False then
      Result := not Result; //Reverse condition
  end;

var i: integer; VictorySatisfied, SurvivalSatisfied: boolean;
begin
  if not CHECK_WIN_CONDITIONS then exit; //Debug switch
  if fHasWonOrLost then exit; //If player has elected to play on past victory or defeat then do not check for any further goals

  VictorySatisfied  := true; //Assume they will win/survive, then prove it with goals
  SurvivalSatisfied := true;

  with fPlayers[PlayerIndex] do
  for i:=0 to Goals.Count-1 do //Test each goal to see if it has occured
    if GoalConditionSatisfied(Goals[i]) then
    begin
      //Display message if set and not already shown and not a blank text
      if (Goals[i].MessageToShow <> 0) and (not Goals[i].MessageHasShown) and (fTextLibrary.GetTextString(Goals[i].MessageToShow) <> '') then
      begin
        if MyPlayer = fPlayers[PlayerIndex] then
          fGame.fGamePlayInterface.MessageIssue(msgText,fTextLibrary.GetTextString(Goals[i].MessageToShow),KMPoint(0,0));
        Goals.SetMessageHasShown(i);
      end;
    end
    else
    begin
      if Goals[i].GoalType = glt_Victory then
        VictorySatisfied := false;
      if Goals[i].GoalType = glt_Survive then
        SurvivalSatisfied := false;
    end;

  if fGame.GameState = gsReplay then exit; //Don't check conditions in Replay
  if (not fGame.MultiplayerMode) and (MyPlayer <> fPlayers[PlayerIndex]) then
    exit; //Don't show message if the player is not us, except in multiplayer mode

  //You can't win and lose at the same time. In KaM defeats override victories, except
  //when there are no goals defined, in which case you win for some weird reason...
  //But given that having no goals is pretty pointless we'll make defeat override so you can't
  //win battle missions by waiting for your troops to simultainiously starve to death.

  if not SurvivalSatisfied then
  begin
    fGame.PlayerDefeat(PlayerIndex);
    fHasWonOrLost := true;
  end
  else
    if VictorySatisfied then
    begin
      fGame.PlayerVictory(PlayerIndex);
      fHasWonOrLost := true;
    end;

end;


{ Check existing unit count vs house count and train missing citizens }
procedure TKMPlayerAI.CheckUnitCount;
var
  i,k:integer;
  H:THouseType;
  UT:TUnitType;
  HS:TKMHouseSchool;
  UnitReq:array[TUnitType]of integer;
  Schools:array of TKMHouseSchool;

  function CheckUnitRequirements(Req:integer; aUnitType:TUnitType):boolean;
  begin
    //We summ up requirements for e.g. Recruits required at Towers and Barracks
    if fPlayers[PlayerIndex].Stats.GetUnitQty(aUnitType) < (Req+UnitReq[aUnitType]) then
    begin
      dec(UnitReq[aUnitType]); //So other schools don't order same unit
      HS.AddUnitToQueue(aUnitType, 1);
      Result := true;
    end
    else
      Result := false;
  end;
begin
  //Find school and make sure it's free of tasks
  FillChar(UnitReq,SizeOf(UnitReq),#0); //Clear up

  //Citizens
  //Count overall unit requirement (excluding Barracks and ownerless houses)
  for H:=Low(THouseType) to High(THouseType) do
    if fResource.HouseDat[H].IsValid and (fResource.HouseDat[H].OwnerType <> ut_None) and (H <> ht_Barracks) then
      inc(UnitReq[fResource.HouseDat[H].OwnerType], fPlayers[PlayerIndex].Stats.GetHouseQty(H));

  //Schools
  //Count overall schools count and exclude already training units from UnitReq
  SetLength(Schools, fPlayers[PlayerIndex].Stats.GetHouseQty(ht_School));
  k := 1;
  HS := TKMHouseSchool(fPlayers[PlayerIndex].FindHouse(ht_School,k));
  while HS <> nil do
  begin
    Schools[k-1] := HS;
    for i:=1 to 6 do //Decrease requirement for each unit in training
      if HS.UnitQueue[i]<>ut_None then
        dec(UnitReq[HS.UnitQueue[i]]); //Can be negative and compensated by e.g. ReqRecruits
    inc(k);
    HS := TKMHouseSchool(fPlayers[PlayerIndex].FindHouse(ht_School,k));
  end;

  //Order the training
  for k:=1 to Length(Schools) do
  begin
    HS := Schools[k-1];
    if (HS<>nil)and(HS.UnitQueue[1]=ut_None) then
    begin
      //Order citizen training
      for UT:=Low(UnitReq) to High(UnitReq) do
        if (UnitReq[UT] > 0) and
           (UnitReq[UT] > fPlayers[PlayerIndex].Stats.GetUnitQty(UT)) and
           (UT <> ut_None) then
        begin
          dec(UnitReq[UT]); //So other schools don't order same unit
          HS.AddUnitToQueue(UT, 1);
          break; //Don't need more UnitTypes yet
        end;

      //If we are here then a citizen to train wasn't found, so try other unit types (citizens get top priority)
      //Serf factor is like this: Serfs = (10/FACTOR)*Total_Building_Count) (from: http://atfreeforum.com/knights/viewtopic.php?t=465)
      if (HS.UnitQueue[1] = ut_None) then //Still haven't found a match...
        if not CheckUnitRequirements(Round((10/ReqSerfFactor)*fPlayers[PlayerIndex].Stats.GetHouseQty(ht_Any)), ut_Serf) then
          if not CheckUnitRequirements(ReqWorkers, ut_Worker) then
            if fGame.CheckTime(RecruitTrainTimeout) then //Recruits can only be trained after this time
              if not CheckUnitRequirements(ReqRecruits * fPlayers[PlayerIndex].Stats.GetHouseQty(ht_Barracks), ut_Recruit) then
                break; //There's no unit demand at all
    end;
  end;
end;


procedure TKMPlayerAI.CheckArmiesCount;
var
  Barracks:array of TKMHouseBarracks;
  HB:TKMHouseBarracks;
  GType: TGroupType;
  i,k:integer;
  TrainedSomething:boolean;
  GroupReq: array[TGroupType] of integer;
begin
  if fGame.IsPeaceTime then Exit; //Do not process train soldiers during peacetime
  if fPlayers[PlayerIndex].Stats.GetArmyCount >= MaxSoldiers then Exit; //Don't train if we have reached our limit
  if not fGame.CheckTime(fLastEquippedTime+EquipRate) then Exit; //Delay between equipping soldiers for KaM compatibility
  fLastEquippedTime := fGame.GameTickCount;

  //Create a list of troops that need to be trained based on defence position requirements
  FillChar(GroupReq, SizeOf(GroupReq), #0); //Clear up
  for k:=0 to DefencePositionsCount-1 do
    with DefencePositions[k] do
    if CurrentCommander = nil then
      inc(GroupReq[GroupType], TroopFormations[GroupType].NumUnits)
    else
      inc(GroupReq[GroupType], TroopFormations[GroupType].NumUnits - (TKMUnitWarrior(CurrentCommander).GetMemberCount+1));

  //Find barracks
  SetLength(Barracks, fPlayers[PlayerIndex].Stats.GetHouseQty(ht_Barracks));
  k := 1;
  HB := TKMHouseBarracks(fPlayers[PlayerIndex].FindHouse(ht_Barracks,k));
  while HB <> nil do
  begin
    Barracks[k-1] := HB;
    inc(k);
    HB := TKMHouseBarracks(fPlayers[PlayerIndex].FindHouse(ht_Barracks,k));
  end;

  //Train troops where possible in each barracks
  for k:=1 to Length(Barracks) do
  begin
    HB := Barracks[k-1];
    //Chose a random group type that we are going to attempt to train (so we don't always train certain group types first)
    i := 0;
    repeat
      GType := TGroupType(KaMRandom(4)); //Pick random from overall count
      inc(i);
    until (GroupReq[GType] > 0) or (i > 9); //Limit number of attempts to guarantee it doesn't loop forever

    for i:=1 to 3 do
    begin
      TrainedSomething := false;
      if AITroopTrainOrder[GType,i] <> ut_None then
        while HB.CanEquip(AITroopTrainOrder[GType,i]) and (GroupReq[GType] > 0) and
              (fPlayers[PlayerIndex].Stats.GetArmyCount < MaxSoldiers) do
        begin
          HB.Equip(AITroopTrainOrder[GType,i], 1);
          dec(GroupReq[GType]);
          TrainedSomething := true;
          if EquipRate > 0 then break; //Only equip 1 soldier when we have a restricted equip rate
        end;
      if TrainedSomething and (EquipRate > 0) then break; //Only equip 1 soldier when we have a restricted equip rate
    end;
  end;
end;


function TKMPlayerAI.CheckAttackMayOccur(aAttack: TAIAttack; MenAvailable:integer; GroupsAvailableCount: array of integer):boolean;
var GT: TGroupType;
begin
  with aAttack do
  begin
    Result := ((AttackType = aat_Repeating) or not HasOccured)
              and fGame.CheckTime(Delay)
              and (TotalMen <= MenAvailable);

    if not TakeAll then
      for GT := Low(TGroupType) to High(TGroupType) do
        Result := Result AND (GroupAmounts[GT] <= GroupsAvailableCount[byte(GT)]);

    //todo: Add support for the AI attack feature Range
  end;
end;


procedure TKMPlayerAI.OrderAttack(aCommander: TKMUnitWarrior; aTarget: TAIAttackTarget; aCustomPos: TKMPoint);
var
  TargetHouse: TKMHouse;
  TargetUnit: TKMUnit;
begin
  TargetHouse := nil;
  TargetUnit  := nil;

  //Find target
  case aTarget of
    att_ClosestUnit:                  TargetUnit := fPlayers.GetClosestUnit(aCommander.GetPosition, PlayerIndex, at_Enemy);
    att_ClosestBuildingFromArmy:      TargetHouse := fPlayers.GetClosestHouse(aCommander.GetPosition, PlayerIndex, at_Enemy, false);
    att_ClosestBuildingFromStartPos:  TargetHouse := fPlayers.GetClosestHouse(StartPosition, PlayerIndex, at_Enemy, false);
    att_CustomPosition:               begin
                                        TargetHouse := fPlayers.HousesHitTest(aCustomPos.X, aCustomPos.Y);
                                        if (TargetHouse <> nil) and
                                           (fPlayers.CheckAlliance(PlayerIndex, TargetHouse.GetOwner) = at_Ally) then
                                          TargetHouse := nil;
                                        TargetUnit := fTerrain.UnitsHitTest(aCustomPos.X, aCustomPos.Y);
                                        if (TargetUnit <> nil) and
                                           (fPlayers.CheckAlliance(PlayerIndex, TargetUnit.GetOwner) = at_Ally) then
                                          TargetUnit := nil;
                                      end;
  end;

  //Choose best option
  if TargetHouse <> nil then
    aCommander.OrderAttackHouse(TargetHouse)
  else if TargetUnit <> nil then
    aCommander.OrderAttackUnit(TargetUnit)
  else if aTarget = att_CustomPosition then
    aCommander.OrderWalk(aCustomPos);
end;


procedure TKMPlayerAI.RestockPositionWith(aDefenceGroup, aCommander:TKMUnitWarrior);
var Needed: integer;
begin
  Needed := TroopFormations[UnitGroups[aDefenceGroup.UnitType]].NumUnits - (aDefenceGroup.GetMemberCount+1);
  if Needed <= 0 then exit;
  if aCommander.GetMemberCount+1 <= Needed then
    aCommander.OrderLinkTo(aDefenceGroup) //Link entire group
  else
    aCommander.OrderSplitLinkTo(aDefenceGroup,Needed); //Link only as many units as are needed
end;


function TKMPlayerAI.FindPlaceForWarrior(aWarrior:TKMUnitWarrior; aCanLinkToExisting, aTakeClosest:boolean):boolean;
var k, MenRequired, Matched: integer;
    Distance, Best: single;
begin
  Result := false;
  Matched := -1;  Best := 9999;
  for k:=0 to DefencePositionsCount-1 do
  begin
    if aCanLinkToExisting then
      MenRequired := TroopFormations[DefencePositions[k].GroupType].NumUnits
    else MenRequired := 1; //If not aCanLinkToExisting then a group with 1 member or more counts as fully stocked already
    if (DefencePositions[k].GroupType = UnitGroups[aWarrior.UnitType]) and
       not DefencePositions[k].IsFullyStocked(MenRequired) then
    begin
      //Take closest position that is empty or requries restocking
      Distance := GetLength(aWarrior.GetPosition,DefencePositions[k].Position.Loc);
      if Distance < Best then
      begin
        Matched := k;
        Best := Distance;
        if not aTakeClosest then break; //Take first one we find - that's what KaM does
      end;
    end;
  end;
  if Matched <> -1 then
  begin
    Result := true;
    if DefencePositions[Matched].CurrentCommander = nil then
    begin //New position
      DefencePositions[Matched].CurrentCommander := aWarrior.GetCommander;
      aWarrior.OrderWalk(DefencePositions[Matched].Position);
    end
    else //Restock existing position
      RestockPositionWith(DefencePositions[Matched].CurrentCommander,aWarrior.GetCommander);
  end;
end;


procedure TKMPlayerAI.CheckArmy;
var AttackTotalAvailable: integer; //Total number of warriors available to attack the enemy
    AttackGroupsCount: array[TGroupType] of integer;
    AttackGroups: array[TGroupType] of array of TKMUnitWarrior;

  procedure AddToAvailableToAttack(aCommander: TKMUnitWarrior);
  var GT: TGroupType;
  begin
    GT := UnitGroups[aCommander.UnitType];
    if Length(AttackGroups[GT]) <= AttackGroupsCount[GT] then
      SetLength(AttackGroups[GT],AttackGroupsCount[GT]+10);
    AttackGroups[GT,AttackGroupsCount[GT]] := aCommander;
    inc(AttackGroupsCount[GT]);
    AttackTotalAvailable := AttackTotalAvailable + aCommander.GetMemberCount+1;
  end;

var i, k, j: integer;
    G: TGroupType;
    Positioned: boolean;
    NeedsLinkingTo: array[TGroupType] of TKMUnitWarrior;
begin
  AttackTotalAvailable := 0;
  for G:=Low(TGroupType) to High(TGroupType) do
  begin
    NeedsLinkingTo[G] := nil;
    AttackGroupsCount[G] := 0;
  end;

  //Hotfix until we refactor AI: Make sure no defence position commander is dead or not a commander
  for k:=0 to DefencePositionsCount-1 do
    with DefencePositions[k] do
      if (CurrentCommander <> nil) and (CurrentCommander.IsDeadOrDying or not CurrentCommander.IsCommander) then
        CurrentCommander := nil;

  //Iterate units list in search of warrior commanders, and then check the following: Hunger, (feed) formation, (units per row) position (from defence positions)
  for i:=0 to fPlayers[PlayerIndex].Units.Count-1 do
  begin
    if TKMUnit(fPlayers[PlayerIndex].Units.Items[i]) is TKMUnitWarrior then
      with TKMUnitWarrior(fPlayers[PlayerIndex].Units.Items[i]) do
      if not IsDeadOrDying and Visible then //Ignore warriors which are dead or still in barracks
      begin
        //ALL WARRIORS: Check hunger and feed
        if (Condition < UNIT_MIN_CONDITION) then GetCommander.OrderFood;
        //ONLY COMMANDERS:
        if IsCommander then
        begin
          //If the warrior is busy then skip this group because the AI should not give orders to fighting warriors
          if ArmyInFight or (GetUnitTask is TTaskAttackHouse) or (OrderTarget <> nil) then
          begin
            //If this group belongs to a defence position and they are too far away we should disassociate
            //them from the defence position so new warriors can take up the defence if needs be
            for k:=0 to DefencePositionsCount-1 do
              with DefencePositions[k] do
                if (CurrentCommander = GetCommander) and (KMLength(Position.Loc, GetPosition) > DefenceRadius) then
                  CurrentCommander := nil;
            Continue;
          end;

          if fGame.IsPeaceTime then Continue; //Do not process attack or defence during peacetime

          //Check formation. If the script has defined a group with more units per row than there should be, do not change it
          if UnitsPerRow < TroopFormations[UnitGroups[UnitType]].UnitsPerRow then
            UnitsPerRow := TroopFormations[UnitGroups[UnitType]].UnitsPerRow;
          //Position this group to defend if they already belong to a defence position
          Positioned := false;
          for k:=0 to DefencePositionsCount-1 do
            if DefencePositions[k].CurrentCommander = GetCommander then
            begin
              OrderWalk(DefencePositions[k].Position);
              Positioned := true; //We already have a position, finished with this group

              //If this group is available to attack then count them
              if DefencePositions[k].DefenceType = adt_BackLine then
                AddToAvailableToAttack(GetCommander);

              //In KaM the order of defence positions is the priority: The first defined is higher priority
              for j:=0 to k-1 do
                if (DefencePositions[j].CurrentCommander = nil) and
                   (DefencePositions[j].GroupType = UnitGroups[UnitType]) then
                   begin
                     DefencePositions[k].CurrentCommander := nil; //Leave current position
                     DefencePositions[j].CurrentCommander := GetCommander; //Take new position
                     break;
                   end;

              break;
            end;

          //Look for group that needs additional members, or a new position to defend
          //In this case we choose the closest group, then move to a higher priority one later (see above)
          //This means at the start of the mission troops will take the position they are placed at rather than swapping around
          if not Positioned then
            Positioned := FindPlaceForWarrior(TKMUnitWarrior(fPlayers[PlayerIndex].Units.Items[i]), AI_LINK_IDLE, AI_FILL_CLOSEST);

          //Just chill and link with other idle groups
          if not Positioned then
          begin
            AddToAvailableToAttack(GetCommander); //Idle groups may also attack
            if AI_LINK_IDLE then
              //If this group doesn't have enough members
              if (GetMemberCount+1 < TroopFormations[UnitGroups[UnitType]].NumUnits) then
                if NeedsLinkingTo[UnitGroups[UnitType]] = nil then
                  NeedsLinkingTo[UnitGroups[UnitType]] := GetCommander //Flag us as needing to be added to
                else
                begin
                  RestockPositionWith(NeedsLinkingTo[UnitGroups[UnitType]],GetCommander);
                  if NeedsLinkingTo[UnitGroups[UnitType]].GetMemberCount+1 >= TroopFormations[UnitGroups[UnitType]].NumUnits then
                    NeedsLinkingTo[UnitGroups[UnitType]] := nil; //Group is now full
                end;
          end;

        end;
      end;
  end;

  //Now process AI attacks (we have compiled a list of warriors available to attack)
  if not fGame.IsPeaceTime then
    for i:=0 to ScriptedAttacksCount-1 do
    with ScriptedAttacks[i] do
    begin
      //Check conditions are right
      if not CheckAttackMayOccur(ScriptedAttacks[i], AttackTotalAvailable, AttackGroupsCount) then continue;
      //Order groups to attack
      if TakeAll then
      begin
        for G:=Low(TGroupType) to High(TGroupType) do
          for j:=1 to AttackGroupsCount[G] do
            OrderAttack(AttackGroups[G, integer(j)-1],Target,CustomPosition);
      end
      else
      begin
        for G:=Low(TGroupType) to High(TGroupType) do
          for j:=1 to GroupAmounts[G] do
            OrderAttack(AttackGroups[G, integer(j)-1],Target,CustomPosition);
      end;
      HasOccured := true;
    end;
end;


procedure TKMPlayerAI.OwnerUpdate(aPlayer:TPlayerIndex);
begin
  PlayerIndex := aPlayer;
end;


//This is run by commanders when they die.
//Dead commander is the one that died, NewCommander is the one that replaced him.
//We need to update CurrentCommander for defence positions in this case.
procedure TKMPlayerAI.CommanderDied(DeadCommander, NewCommander: TKMUnitWarrior);
var i: integer;
begin
  for i:=0 to DefencePositionsCount-1 do
    with DefencePositions[i] do
      if CurrentCommander = DeadCommander then
        CurrentCommander := NewCommander; //Don't need to use GetPointer/ReleasePointer because setting CurrentCommander does that
end;


procedure TKMPlayerAI.WarriorEquipped(aWarrior: TKMUnitWarrior);
begin
  Assert(aWarrior.IsCommander); //A warrior walking out of the barracks should not be linked yet
  FindPlaceForWarrior(aWarrior, true, AI_FILL_CLOSEST);
end;


procedure TKMPlayerAI.RetaliateAgainstThreat(aAttacker: TKMUnitWarrior);
var i: integer;
begin
  if fPlayers[PlayerIndex].PlayerType = pt_Human then Exit;

  //todo: Right now "idle" troops (without an assigned defence position) will do nothing (no attacking, defending, etc.)
  //Any defence position that is within their defence radius of this threat will retaliate against it
  for i := 0 to DefencePositionsCount-1 do
    with DefencePositions[i] do
      if (CurrentCommander <> nil) and (not CurrentCommander.ArmyInFight)
      and (CurrentCommander.OrderTarget = nil)
      and (KMLength(CurrentCommander.GetPosition, aAttacker.GetPosition) <= DefenceRadius) then
        CurrentCommander.OrderAttackUnit(aAttacker);
end;


//aHouse is our house that was attacked
procedure TKMPlayerAI.HouseAttackNotification(aHouse: TKMHouse; aAttacker:TKMUnitWarrior);
begin
  case fPlayers[PlayerIndex].PlayerType of
    pt_Human:
      begin
        if fGame.CheckTime(fTimeOfLastAttackMessage + TIME_ATTACK_WARNINGS) then
        begin
          //Process anyway for multiplayer consistency
          //(and it is desired behaviour: if player saw attack,
          //don't notify him as soon as he looks away)
          fTimeOfLastAttackMessage := fGame.GameTickCount;
          if (MyPlayer = fPlayers[PlayerIndex]) and (GetLength(fGame.Viewport.Position, KMPointF(aHouse.GetPosition)) >= DISTANCE_FOR_WARNINGS) then
            fSoundLib.PlayNotification(an_Town);
        end;
      end;
    pt_Computer:
      RetaliateAgainstThreat(aAttacker);
  end;
end;


//aUnit is our unit that was attacked
procedure TKMPlayerAI.UnitAttackNotification(aUnit: TKMUnit; aAttacker:TKMUnitWarrior);
begin
  case fPlayers[PlayerIndex].PlayerType of
    pt_Human:
      if fGame.CheckTime(fTimeOfLastAttackMessage + TIME_ATTACK_WARNINGS) then
      begin
        fTimeOfLastAttackMessage := fGame.GameTickCount; //Process anyway for multiplayer consistency (and it is desired behaviour: if player saw attack, don't notify him as soon as he looks away)
        if (MyPlayer = fPlayers[PlayerIndex]) and (GetLength(fGame.Viewport.Position, KMPointF(aUnit.GetPosition)) >= DISTANCE_FOR_WARNINGS) then
        begin
          if aUnit is TKMUnitWarrior then
            fSoundLib.PlayNotification(an_Troops)
          else
            fSoundLib.PlayNotification(an_Citizens);
        end;
      end;
    pt_Computer:
      if aUnit is TKMUnitWarrior then
      begin
        //If we are attacked, then we should counter attack the attacker!
        with TKMUnitWarrior(aUnit).GetCommander do
          if not ArmyInFight then
            OrderAttackUnit(aAttacker);
      end
      else
        RetaliateAgainstThreat(aAttacker); //Come to the defence of our citizens
  end;
end;


//Do we automatically repair all houses?
//For now use fAutobuild, which is what KaM does. Later we can add a script command to turn this on and off
//Also could be changed later to disable repairing when under attack? (only repair if the enemy goes away?)
function TKMPlayerAI.HouseAutoRepair:boolean;
begin
  Result := fAutobuild;
end;


procedure TKMPlayerAI.AddDefencePosition(aPos:TKMPointDir; aGroupType:TGroupType; aDefenceRadius:integer; aDefenceType:TAIDefencePosType);
begin
  SetLength(DefencePositions, DefencePositionsCount+1);
  DefencePositions[DefencePositionsCount] := TAIDefencePosition.Create(aPos,aGroupType,aDefenceRadius,aDefenceType);
  inc(DefencePositionsCount);
end;


procedure TKMPlayerAI.AddAttack(aAttack: TAIAttack);
begin
  SetLength(ScriptedAttacks, ScriptedAttacksCount+1);
  ScriptedAttacks[ScriptedAttacksCount] := aAttack;
  inc(ScriptedAttacksCount);
end;


procedure TKMPlayerAI.Save(SaveStream:TKMemoryStream);
var i: integer;
begin
  SaveStream.Write('PlayerAI');
  SaveStream.Write(PlayerIndex);
  SaveStream.Write(fHasWonOrLost);
  SaveStream.Write(fTimeOfLastAttackMessage);
  SaveStream.Write(fLastEquippedTime);
  SaveStream.Write(ReqWorkers);
  SaveStream.Write(ReqSerfFactor);
  SaveStream.Write(ReqRecruits);
  SaveStream.Write(EquipRate);
  SaveStream.Write(RecruitTrainTimeout);
  SaveStream.Write(TownDefence);
  SaveStream.Write(MaxSoldiers);
  SaveStream.Write(Aggressiveness);
  SaveStream.Write(StartPosition);
  SaveStream.Write(fAutobuild);
  SaveStream.Write(TroopFormations, SizeOf(TroopFormations));
  SaveStream.Write(DefencePositionsCount);
  for i:=0 to DefencePositionsCount-1 do
    DefencePositions[i].Save(SaveStream);
  SaveStream.Write(ScriptedAttacksCount);
  for i:=0 to ScriptedAttacksCount-1 do
    SaveStream.Write(ScriptedAttacks[i], SizeOf(ScriptedAttacks[i]));
end;


procedure TKMPlayerAI.Load(LoadStream:TKMemoryStream);
var i: integer; s: string;
begin
  LoadStream.Read(s);
  Assert(s = 'PlayerAI');
  LoadStream.Read(PlayerIndex);
  LoadStream.Read(fHasWonOrLost);
  LoadStream.Read(fTimeOfLastAttackMessage);
  LoadStream.Read(fLastEquippedTime);
  LoadStream.Read(ReqWorkers);
  LoadStream.Read(ReqSerfFactor);
  LoadStream.Read(ReqRecruits);
  LoadStream.Read(EquipRate);
  LoadStream.Read(RecruitTrainTimeout);
  LoadStream.Read(TownDefence);
  LoadStream.Read(MaxSoldiers);
  LoadStream.Read(Aggressiveness);
  LoadStream.Read(StartPosition);
  LoadStream.Read(fAutobuild);
  LoadStream.Read(TroopFormations, SizeOf(TroopFormations));
  LoadStream.Read(DefencePositionsCount);
  SetLength(DefencePositions, DefencePositionsCount);
  for i:=0 to DefencePositionsCount-1 do
    DefencePositions[i] := TAIDefencePosition.Load(LoadStream);
  LoadStream.Read(ScriptedAttacksCount);
  SetLength(ScriptedAttacks, ScriptedAttacksCount);
  for i:=0 to ScriptedAttacksCount-1 do
    LoadStream.Read(ScriptedAttacks[i], SizeOf(ScriptedAttacks[i]));
end;


procedure TKMPlayerAI.SyncLoad;
var i: integer;
begin
  for i:=0 to DefencePositionsCount-1 do
    DefencePositions[i].SyncLoad;
end;


procedure TKMPlayerAI.UpdateState;
begin

  //Check goals for all players to maintain multiplayer consistency
  case fPlayers[PlayerIndex].PlayerType of
    pt_Human:     CheckGoals; //This procedure manages victory, loss and messages all in one
    pt_Computer:  if (MyPlayer <> fPlayers[PlayerIndex]) then
                  begin
                    CheckUnitCount; //Train new units (citizens, serfs, workers and recruits) if needed
                    CheckArmy; //Feed army, position defence, arrange/organise groups
                    CheckArmiesCount; //Train new soldiers if needed
                    //CheckHouseCount; //Build new houses if needed
                    //CheckEnemyPresence; //Check enemy threat in close range and issue defensive attacks (or flee?)
                    //CheckAndIssueAttack; //Attack enemy
                    //Anything Else?
                  end;
  end;
end;


end.