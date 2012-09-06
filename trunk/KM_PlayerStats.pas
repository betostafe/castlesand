unit KM_PlayerStats;
{$I KaM_Remake.inc}
interface
uses Classes, SysUtils,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults;


{These are mission specific settings and stats for each player}
type
  TKMPlayerStats = class
  private
    fGraphCount: Integer;
    fGraphCapacity: Integer;
    fGraphHouses, fGraphCitizens, fGraphArmy: TCardinalArray;
    fGraphGoods: array [WARE_MIN..WARE_MAX] of TCardinalArray;
    fHouseUnlocked: array [THouseType] of Boolean; //If building requirements performed
    Houses: array [THouseType] of packed record
      Planned,          //Houseplans were placed
      PlanRemoved,      //Houseplans were removed
      Started,          //Construction started
      Ended,            //Construction ended (either done or destroyed/cancelled)
      Initial,          //created by script on mission start
      Built,            //constructed by player
      SelfDestruct,     //deconstructed by player
      Lost,             //lost from attacks and self-demolished
      Destroyed: Word;  //damage to other players
    end;
    Units: array [HUMANS_MIN..HUMANS_MAX] of packed record
      Initial,          //Provided at mission start
      Trained,          //Trained by player
      Lost,             //Died of hunger or killed
      Killed: Word;     //Killed (incl. self)
    end;
    Goods: array [WARE_MIN..WARE_MAX] of packed record
      Initial: Cardinal;
      Produced: Cardinal;
      Consumed: Cardinal;
    end;
    fResourceRatios: array [1..4, 1..4]of Byte;
    function GetGraphGoods(aWare: TresourceType): TCardinalArray;
    function GetRatio(aRes: TResourceType; aHouse: THouseType): Byte;
    procedure SetRatio(aRes: TResourceType; aHouse: THouseType; aValue: Byte);
    procedure UpdateReqDone(aType: THouseType);
  public
    HouseBlocked: array [THouseType] of Boolean; //Allowance derived from mission script
    HouseGranted: array [THouseType] of Boolean; //Allowance derived from mission script

    AllowToTrade: array [WARE_MIN..WARE_MAX] of Boolean; //Allowance derived from mission script
    constructor Create;

    //Input reported by Player
    procedure GoodInitial(aRes: TResourceType; aCount: Cardinal);
    procedure GoodProduced(aRes: TResourceType; aCount: Cardinal);
    procedure GoodConsumed(aRes: TResourceType; aCount: Cardinal = 1);
    procedure HousePlanned(aType: THouseType);
    procedure HousePlanRemoved(aType: THouseType);
    procedure HouseStarted(aType: THouseType);
    procedure HouseEnded(aType: THouseType);
    procedure HouseCreated(aType: THouseType; aWasBuilt: Boolean);
    procedure HouseLost(aType: THouseType);
    procedure HouseSelfDestruct(aType: THouseType);
    procedure HouseDestroyed(aType: THouseType);
    procedure UnitCreated(aType: TUnitType; aWasTrained: Boolean);
    procedure UnitLost(aType: TUnitType);
    procedure UnitKilled(aType: TUnitType);

    property Ratio[aRes: TResourceType; aHouse: THouseType]: Byte read GetRatio write SetRatio;

    //Output
    function GetHouseQty(aType: THouseType): Integer;
    function GetHouseWip(aType: THouseType): Integer;
    function GetUnitQty(aType: TUnitType): Integer;
    function GetResourceQty(aRT: TResourceType): Integer;
    function GetArmyCount: Integer;
    function GetCitizensCount: Integer;
    function GetCanBuild(aType: THouseType): Boolean;

    function GetCitizensTrained: Cardinal;
    function GetCitizensLost: Cardinal;
    function GetCitizensKilled: Cardinal;
    function GetHousesBuilt: Cardinal;
    function GetHousesLost: Cardinal;
    function GetHousesDestroyed: Cardinal;
    function GetWarriorsTrained: Cardinal;
    function GetWarriorsKilled: Cardinal;
    function GetWarriorsLost: Cardinal;
    function GetGoodsProduced(aRT: TResourceType): Cardinal; overload;
    function GetGoodsProduced: Cardinal; overload;
    function GetWeaponsProduced: Cardinal;

    property GraphCount: Integer read fGraphCount;
    property GraphHouses: TCardinalArray read fGraphHouses;
    property GraphCitizens: TCardinalArray read fGraphCitizens;
    property GraphArmy: TCardinalArray read fGraphArmy;
    property GraphGoods[aWare: TResourceType]: TCardinalArray read GetGraphGoods;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    procedure UpdateState;
  end;


implementation
uses KM_Resource;


const
  //For now it is the same as KaM
  //The number means how many items should be in houses input max
  DistributionDefaults: array[1..4,1..4]of byte = (
    (5,4,0,0),
    (5,3,4,5),
    (5,3,0,0),
    (5,3,2,0)
    );


{ TKMPlayerStats }
constructor TKMPlayerStats.Create;
var
  W: TResourceType;
  i,k: Integer;
begin
  inherited;

  for W := WARE_MIN to WARE_MAX do
    AllowToTrade[W] := True;

  //Release Store at the start of the game by default
  fHouseUnlocked[ht_Store] := True;

  for i:=1 to 4 do for k:=1 to 4 do
    fResourceRatios[i,k] := DistributionDefaults[i,k];
end;


procedure TKMPlayerStats.UpdateReqDone(aType: THouseType);
var H: THouseType;
begin
  for H := Low(THouseType) to High(THouseType) do
    if fResource.HouseDat[H].ReleasedBy = aType then
      fHouseUnlocked[H] := True;
end;


procedure TKMPlayerStats.HousePlanned(aType: THouseType);
begin
  inc(Houses[aType].Planned);
end;


procedure TKMPlayerStats.HousePlanRemoved(aType: THouseType);
begin
  inc(Houses[aType].PlanRemoved);
end;


//New house in progress
procedure TKMPlayerStats.HouseStarted(aType: THouseType);
begin
  inc(Houses[aType].Started);
end;


//House building process was ended. We don't really know if it was canceled or destroyed or finished
//Other House** methods will handle that
procedure TKMPlayerStats.HouseEnded(aType: THouseType);
begin
  inc(Houses[aType].Ended);
end;


//New house, either built by player or created by mission script
procedure TKMPlayerStats.HouseCreated(aType: THouseType; aWasBuilt:boolean);
begin
  if aWasBuilt then
    inc(Houses[aType].Built)
  else
    inc(Houses[aType].Initial);
  UpdateReqDone(aType);
end;


//Destroyed by enemy
procedure TKMPlayerStats.HouseLost(aType: THouseType);
begin
  inc(Houses[aType].Lost);
end;


procedure TKMPlayerStats.HouseSelfDestruct(aType: THouseType);
begin
  inc(Houses[aType].SelfDestruct);
end;


//Player has destroyed an enemy house
procedure TKMPlayerStats.HouseDestroyed(aType: THouseType);
begin
  inc(Houses[aType].Destroyed);
end;


procedure TKMPlayerStats.UnitCreated(aType: TUnitType; aWasTrained:boolean);
begin
  if aWasTrained then
    inc(Units[aType].Trained)
  else
    inc(Units[aType].Initial);
end;


procedure TKMPlayerStats.UnitLost(aType: TUnitType);
begin
  inc(Units[aType].Lost);
end;


procedure TKMPlayerStats.UnitKilled(aType: TUnitType);
begin
  inc(Units[aType].Killed);
end;


procedure TKMPlayerStats.GoodInitial(aRes: TResourceType; aCount: Cardinal);
begin
  if not DISPLAY_CHARTS_RESULT then Exit;
  if aRes <> rt_None then
    Inc(Goods[aRes].Initial, aCount);
end;


procedure TKMPlayerStats.GoodProduced(aRes: TResourceType; aCount: Cardinal);
var R: TResourceType;
begin
  if aRes <> rt_None then
    case aRes of
      rt_All:     for R := WARE_MIN to WARE_MAX do
                    Inc(Goods[R].Produced, aCount);
      WARE_MIN..
      WARE_MAX:   Inc(Goods[aRes].Produced, aCount);
      else        Assert(False, 'Cant''t add produced good ' + fResource.Resources[aRes].Title);
    end;
end;


procedure TKMPlayerStats.GoodConsumed(aRes: TResourceType; aCount: Cardinal = 1);
begin
  if not DISPLAY_CHARTS_RESULT then Exit;
  if aRes <> rt_None then
    Inc(Goods[aRes].Consumed, aCount);
end;


//How many houses are there
function TKMPlayerStats.GetHouseQty(aType: THouseType): Integer;
var H: THouseType;
begin
  Result := 0;
  case aType of
    ht_None:    ;
    ht_Any:     for H := Low(THouseType) to High(THouseType) do
                if fResource.HouseDat[H].IsValid then
                  Inc(Result, Houses[H].Initial + Houses[H].Built - Houses[H].SelfDestruct - Houses[H].Lost);
    else        Result := Houses[aType].Initial + Houses[aType].Built - Houses[aType].SelfDestruct - Houses[aType].Lost;
  end;
end;


//How many houses are planned and in progress
function TKMPlayerStats.GetHouseWip(aType: THouseType): Integer;
var H: THouseType;
begin
  Result := 0;
  case aType of
    ht_None:    ;
    ht_Any:     for H := Low(THouseType) to High(THouseType) do
                if fResource.HouseDat[H].IsValid then
                  Inc(Result, Houses[H].Started + Houses[H].Planned - Houses[H].Ended - Houses[H].PlanRemoved);
    else        Result := Houses[aType].Started + Houses[aType].Planned - Houses[aType].Ended - Houses[aType].PlanRemoved;
  end;
end;


function TKMPlayerStats.GetUnitQty(aType: TUnitType): Integer;
var UT: TUnitType;
begin
  Result := 0;
  case aType of
    ut_None:    ;
    ut_Any:     for UT := HUMANS_MIN to HUMANS_MAX do
                  Result := Units[UT].Initial + Units[UT].Trained - Units[UT].Lost;
    else        begin
                  Result := Units[aType].Initial + Units[aType].Trained - Units[aType].Lost;
                  if aType = ut_Recruit then
                    for UT := WARRIOR_EQUIPABLE_MIN to WARRIOR_EQUIPABLE_MAX do
                      dec(Result, Units[UT].Trained); //Trained soldiers use a recruit
                end;
  end;
end;


function TKMPlayerStats.GetResourceQty(aRT: TResourceType): Integer;
var RT: TResourceType;
begin
  Result := 0;
  case aRT of
    rt_None:    ;
    rt_All:     for RT := WARE_MIN to WARE_MAX do
                  Result := Goods[RT].Initial + Goods[RT].Produced - Goods[RT].Consumed;
    rt_Warfare: for RT := WARFARE_MIN to WARFARE_MAX do
                  Result := Goods[RT].Initial + Goods[RT].Produced - Goods[RT].Consumed;
    else        Result := Goods[aRT].Initial + Goods[aRT].Produced - Goods[aRT].Consumed;
  end;
end;


function TKMPlayerStats.GetArmyCount: Integer;
var UT: TUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Result := Result + GetUnitQty(UT);
end;


function TKMPlayerStats.GetCitizensCount: Integer;
var UT: TUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    Result := Result + GetUnitQty(UT);
end;


//Houses might be blocked by mission script
function TKMPlayerStats.GetCanBuild(aType: THouseType): Boolean;
begin
  Result := (fHouseUnlocked[aType] or HouseGranted[aType]) and not HouseBlocked[aType];
end;


function TKMPlayerStats.GetRatio(aRes: TResourceType; aHouse: THouseType): Byte;
begin
  Result := 5; //Default should be 5, for house/resource combinations that don't have a setting (on a side note this should be the only place the resourse limit is defined)
  case aRes of
    rt_Steel: if aHouse = ht_WeaponSmithy   then Result := fResourceRatios[1,1] else
              if aHouse = ht_ArmorSmithy    then Result := fResourceRatios[1,2];
    rt_Coal:  if aHouse = ht_IronSmithy     then Result := fResourceRatios[2,1] else
              if aHouse = ht_Metallurgists  then Result := fResourceRatios[2,2] else
              if aHouse = ht_WeaponSmithy   then Result := fResourceRatios[2,3] else
              if aHouse = ht_ArmorSmithy    then Result := fResourceRatios[2,4];
    rt_Wood:  if aHouse = ht_ArmorWorkshop  then Result := fResourceRatios[3,1] else
              if aHouse = ht_WeaponWorkshop then Result := fResourceRatios[3,2];
    rt_Corn:  if aHouse = ht_Mill           then Result := fResourceRatios[4,1] else
              if aHouse = ht_Swine          then Result := fResourceRatios[4,2] else
              if aHouse = ht_Stables        then Result := fResourceRatios[4,3];
  end;
end;


procedure TKMPlayerStats.SetRatio(aRes: TResourceType; aHouse: THouseType; aValue: Byte);
begin
  case aRes of
    rt_Steel: if aHouse = ht_WeaponSmithy   then fResourceRatios[1,1] := aValue else
              if aHouse = ht_ArmorSmithy    then fResourceRatios[1,2] := aValue;
    rt_Coal:  if aHouse = ht_IronSmithy     then fResourceRatios[2,1] := aValue else
              if aHouse = ht_Metallurgists  then fResourceRatios[2,2] := aValue else
              if aHouse = ht_WeaponSmithy   then fResourceRatios[2,3] := aValue else
              if aHouse = ht_ArmorSmithy    then fResourceRatios[2,4] := aValue;
    rt_Wood:  if aHouse = ht_ArmorWorkshop  then fResourceRatios[3,1] := aValue else
              if aHouse = ht_WeaponWorkshop then fResourceRatios[3,2] := aValue;
    rt_Corn:  if aHouse = ht_Mill           then fResourceRatios[4,1] := aValue else
              if aHouse = ht_Swine          then fResourceRatios[4,2] := aValue else
              if aHouse = ht_Stables        then fResourceRatios[4,3] := aValue;
    else Assert(False, 'Unexpected resource at SetRatio');
  end;
end;


//The value includes only citizens, Warriors are counted separately
function TKMPlayerStats.GetCitizensTrained: Cardinal;
var UT: TUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    inc(Result, Units[UT].Trained);
end;


function TKMPlayerStats.GetCitizensLost: Cardinal;
var UT: TUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    inc(Result, Units[UT].Lost);
end;


function TKMPlayerStats.GetCitizensKilled: Cardinal;
var UT: TUnitType;
begin
  Result := 0;
  for UT := CITIZEN_MIN to CITIZEN_MAX do
    inc(Result, Units[UT].Killed);
end;


function TKMPlayerStats.GetHousesBuilt: Cardinal;
var HT: THouseType;
begin
  Result := 0;
  for HT := Low(THouseType) to High(THouseType) do
    inc(Result, Houses[HT].Built);
end;



function TKMPlayerStats.GetHousesLost: Cardinal;
var HT: THouseType;
begin
  Result := 0;
  for HT := Low(THouseType) to High(THouseType) do
    inc(Result, Houses[HT].Lost);
end;


function TKMPlayerStats.GetHousesDestroyed: Cardinal;
var HT: THouseType;
begin
  Result := 0;
  for HT := Low(THouseType) to High(THouseType) do
  if fResource.HouseDat[HT].IsValid then
    Inc(Result, Houses[HT].Destroyed);
end;


//The value includes all Warriors
function TKMPlayerStats.GetWarriorsTrained: Cardinal;
var UT: TUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, Units[UT].Trained);
end;


function TKMPlayerStats.GetWarriorsLost: Cardinal;
var UT: TUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, Units[UT].Lost);
end;


function TKMPlayerStats.GetWarriorsKilled: Cardinal;
var UT: TUnitType;
begin
  Result := 0;
  for UT := WARRIOR_MIN to WARRIOR_MAX do
    Inc(Result, Units[UT].Killed);
end;


function TKMPlayerStats.GetGoodsProduced(aRT: TResourceType): Cardinal;
begin
  //todo: Handle rt_SpecialTypes
  Result := Goods[aRT].Produced;
end;


//Everything except weapons
function TKMPlayerStats.GetGoodsProduced: Cardinal;
var RT: TResourceType;
begin
  Result := 0;
  for RT := WARE_MIN to WARE_MAX do
  if fResource.Resources[RT].IsGood then
    Inc(Result, Goods[RT].Produced);
end;


//KaM includes all weapons and armor, but not horses
function TKMPlayerStats.GetWeaponsProduced: Cardinal;
var RT: TResourceType;
begin
  Result := 0;
  for RT := WARE_MIN to WARE_MAX do
  if fResource.Resources[RT].IsWeapon then
    Inc(Result, Goods[RT].Produced);
end;


function TKMPlayerStats.GetGraphGoods(aWare: TresourceType): TCardinalArray;
begin
  Result := fGraphGoods[aWare];
end;


procedure TKMPlayerStats.Save(SaveStream: TKMemoryStream);
var R: TResourceType;
begin
  SaveStream.Write('PlayerStats');
  SaveStream.Write(Houses, SizeOf(Houses));
  SaveStream.Write(Units, SizeOf(Units));
  SaveStream.Write(Goods, SizeOf(Goods));
  SaveStream.Write(fResourceRatios, SizeOf(fResourceRatios));
  SaveStream.Write(HouseBlocked, SizeOf(HouseBlocked));
  SaveStream.Write(HouseGranted, SizeOf(HouseGranted));
  SaveStream.Write(AllowToTrade, SizeOf(AllowToTrade));
  SaveStream.Write(fHouseUnlocked, SizeOf(fHouseUnlocked));

  SaveStream.Write(fGraphCount);
  if fGraphCount <> 0 then
  begin
    SaveStream.Write(fGraphHouses[0], SizeOf(fGraphHouses[0]) * fGraphCount);
    SaveStream.Write(fGraphCitizens[0], SizeOf(fGraphCitizens[0]) * fGraphCount);
    SaveStream.Write(fGraphArmy[0], SizeOf(fGraphArmy[0]) * fGraphCount);
    for R := WARE_MIN to WARE_MAX do
      SaveStream.Write(fGraphGoods[R][0], SizeOf(fGraphGoods[R][0]) * fGraphCount);
  end;
end;


procedure TKMPlayerStats.Load(LoadStream: TKMemoryStream);
var R: TResourceType;
begin
  LoadStream.ReadAssert('PlayerStats');
  LoadStream.Read(Houses, SizeOf(Houses));
  LoadStream.Read(Units, SizeOf(Units));
  LoadStream.Read(Goods, SizeOf(Goods));
  LoadStream.Read(fResourceRatios, SizeOf(fResourceRatios));
  LoadStream.Read(HouseBlocked, SizeOf(HouseBlocked));
  LoadStream.Read(HouseGranted, SizeOf(HouseGranted));
  LoadStream.Read(AllowToTrade, SizeOf(AllowToTrade));
  LoadStream.Read(fHouseUnlocked, SizeOf(fHouseUnlocked));

  LoadStream.Read(fGraphCount);
  if fGraphCount <> 0 then
  begin
    fGraphCapacity := fGraphCount;
    SetLength(fGraphHouses, fGraphCount);
    SetLength(fGraphCitizens, fGraphCount);
    SetLength(fGraphArmy, fGraphCount);
    LoadStream.Read(fGraphHouses[0], SizeOf(fGraphHouses[0]) * fGraphCount);
    LoadStream.Read(fGraphCitizens[0], SizeOf(fGraphCitizens[0]) * fGraphCount);
    LoadStream.Read(fGraphArmy[0], SizeOf(fGraphArmy[0]) * fGraphCount);
    for R := WARE_MIN to WARE_MAX do
    begin
      SetLength(fGraphGoods[R], fGraphCount);
      LoadStream.Read(fGraphGoods[R][0], SizeOf(fGraphGoods[R][0]) * fGraphCount);
    end;
  end;
end;


procedure TKMPlayerStats.UpdateState;
var I: TResourceType;
begin
  if not DISPLAY_CHARTS_RESULT then Exit;

  //Store player stats in graph

  //Grow the list
  if fGraphCount >= fGraphCapacity then
  begin
    fGraphCapacity := fGraphCount + 32;
    SetLength(fGraphHouses, fGraphCapacity);
    SetLength(fGraphCitizens, fGraphCapacity);
    SetLength(fGraphArmy, fGraphCapacity);
    for I := WARE_MIN to WARE_MAX do
      SetLength(fGraphGoods[I], fGraphCapacity);
  end;

  fGraphHouses[fGraphCount] := GetHouseQty(ht_Any);
  fGraphArmy[fGraphCount] := GetArmyCount;
  fGraphCitizens[fGraphCount] := GetCitizensCount;

  for I := WARE_MIN to WARE_MAX do
    fGraphGoods[I, fGraphCount] := Goods[I].Produced;

  Inc(fGraphCount);
end;


end.
