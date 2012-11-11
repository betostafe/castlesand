unit KM_Units_WorkPlan;
{$I KaM_Remake.inc}
interface
uses KM_Defaults, KM_CommonClasses, KM_Points, KM_Terrain, KM_Units;


type
  TUnitWorkPlan = class
  private
    fHome: THouseType;
    fIssued: Boolean;
    function ChooseTree(aLoc, aAvoid:TKMPoint; aRadius:Integer; aPlantAct: TPlantAct; aUnit:TKMUnit; out Tree:TKMPointDir; out PlantAct: TPlantAct):Boolean;
    procedure FillDefaults;
    procedure WalkStyle(aLoc2:TKMPointDir; aTo,aWork:TUnitActionType; aCycles,aDelay:byte; aFrom:TUnitActionType; aScript:TGatheringScript);
    procedure SubActAdd(aAct:THouseActionType; aCycles:single);
    procedure ResourcePlan(Res1:TResourceType; Qty1:byte; Res2:TResourceType; Qty2:byte; Prod1:TResourceType; Prod2:TResourceType=rt_None);
  public
    HasToWalk:boolean;
    Loc:TKMPoint;
    ActionWalkTo:TUnitActionType;
    ActionWorkType:TUnitActionType;
    WorkCyc:integer;
    WorkDir:TKMDirection;
    GatheringScript:TGatheringScript;
    AfterWorkDelay:integer;
    ActionWalkFrom:TUnitActionType;
    Resource1:TResourceType; Count1:byte;
    Resource2:TResourceType; Count2:byte;
    ActCount:byte;
    HouseAct:array[1..32] of record
      Act:THouseActionType;
      TimeToWork:word;
    end;
    Product1:TResourceType; ProdCount1:byte;
    Product2:TResourceType; ProdCount2:byte;
    AfterWorkIdle:integer;
    ResourceDepleted:boolean;
  public
    constructor Create;
    procedure FindPlan(aUnit:TKMUnit; aHome:THouseType; aProduct:TResourceType; aLoc:TKMPoint; aPlantAct: TPlantAct);
    function FindDifferentResource(aUnit:TKMUnit; aLoc, aAvoidLoc: TKMPoint):boolean;
    property IsIssued:boolean read fIssued;
    procedure Save(SaveStream:TKMemoryStream);
    procedure Load(LoadStream:TKMemoryStream);
  end;


implementation
uses KM_Resource, KM_CommonTypes, KM_Utils;


constructor TUnitWorkPlan.Create;
begin
  inherited;

end;


{Houses are only a place on map, they should not issue or perform tasks (except Training)
Everything should be issued by units
Where to go, which walking style, what to do on location, for how long
How to go back in case success, incase bad luck
What to take from supply, how much, take2, much2
What to do, Work/Cycles, What resource to add to Output, how much
E.g. CoalMine: Miner arrives at home and Idles for 5sec, then takes a work task (depending on ResOut count)
Since Loc is 0,0 he immidietely skips to Phase X where he switches house to Work1 (and self busy for same framecount)
Then Work2 and Work3 same way. Then adds resource to out and everything to Idle for 5sec.
E.g. Farmer arrives at home and Idles for 5sec, then takes a work task (depending on ResOut count, HouseType and Need to sow corn)
...... then switches house to Work1 (and self busy for same framecount)
Then Work2 and Work3 same way. Then adds resource to out and everything to Idle for 5sec.}
procedure TUnitWorkPlan.FillDefaults;
begin
  fIssued := False;
  HasToWalk:=false;
  Loc:=KMPoint(0,0);
  ActionWalkTo:=ua_Walk;
  ActionWorkType:=ua_Work;
  WorkCyc:=0;
  WorkDir:=dir_NA;
  GatheringScript:=gs_None;
  AfterWorkDelay:=0;
  ActionWalkFrom:=ua_Walk;
  Resource1:=rt_None; Count1:=0;
  Resource2:=rt_None; Count2:=0;
  ActCount:=0;
  Product1:=rt_None; ProdCount1:=0;
  Product2:=rt_None; ProdCount2:=0;
  AfterWorkIdle:=0;
  ResourceDepleted:=false;
end;


procedure TUnitWorkPlan.WalkStyle(aLoc2:TKMPointDir; aTo,aWork:TUnitActionType; aCycles,aDelay:byte; aFrom:TUnitActionType; aScript:TGatheringScript);
begin
  Loc:=aLoc2.Loc;
  HasToWalk:=true;
  ActionWalkTo:=aTo;
  ActionWorkType:=aWork;
  WorkCyc:=aCycles;
  AfterWorkDelay:=aDelay;
  GatheringScript:=aScript;
  ActionWalkFrom:=aFrom;
  WorkDir:=aLoc2.Dir;
end;


procedure TUnitWorkPlan.SubActAdd(aAct:THouseActionType; aCycles:single);
begin
  inc(ActCount);
  HouseAct[ActCount].Act := aAct;
  HouseAct[ActCount].TimeToWork := Round(fResource.HouseDat[fHome].Anim[aAct].Count * aCycles);
end;


procedure TUnitWorkPlan.ResourcePlan(Res1:TResourceType; Qty1:byte; Res2:TResourceType; Qty2:byte; Prod1:TResourceType; Prod2:TResourceType=rt_None);
begin
  Resource1:=Res1; Count1:=Qty1;
  Resource2:=Res2; Count2:=Qty2;
  Product1:=Prod1; ProdCount1:=fResource.HouseDat[fHome].ResProductionX;
  if Prod2=rt_None then exit;
  Product2:=Prod2; ProdCount2:=fResource.HouseDat[fHome].ResProductionX;
end;


function TUnitWorkPlan.FindDifferentResource(aUnit:TKMUnit; aLoc, aAvoidLoc: TKMPoint): boolean;
var
  NewLoc: TKMPointDir;
  PlantAct: TPlantAct;
  Found: boolean;
begin
  with fTerrain do
  case GatheringScript of
    gs_StoneCutter:     Found := FindStone(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, aAvoidLoc, NewLoc);
    gs_FarmerSow:       Found := FindCornField(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, aAvoidLoc, taPlant, PlantAct, NewLoc);
    gs_FarmerCorn:      begin
                          Found := FindCornField(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, aAvoidLoc, taAny, PlantAct, NewLoc);
                          if PlantAct = taPlant then
                          begin
                            GatheringScript := gs_FarmerSow; //Switch to sowing corn rather than cutting
                            ActionWalkFrom  := ua_WalkTool; //Carry our scythe back (without the corn) as the player saw us take it out
                            ActionWorkType  := ua_Work1;
                            WorkCyc    := 10;
                            Product1   := rt_None; //Don't produce corn
                            ProdCount1 := 0;
                          end;
                        end;
    gs_FarmerWine:      begin
                          Found := FindWineField(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, aAvoidLoc, NewLoc);
                          NewLoc.Dir := dir_N; //The animation for picking grapes is only defined for facing north
                        end;
    gs_FisherCatch:     Found := FindFishWater(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, aAvoidLoc, NewLoc);
    gs_WoodCutterCut:   Found := ChooseTree(aLoc, KMGetVertexTile(aAvoidLoc, WorkDir), fResource.UnitDat[aUnit.UnitType].MiningRange, taCut, aUnit, NewLoc, PlantAct);
    gs_WoodCutterPlant: Found := ChooseTree(aLoc, aAvoidLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, taPlant, aUnit, NewLoc, PlantAct);
    else                Found := False; //Can find a new resource for an unknown gathering script, so return with false
  end;

  if Found then
  begin
    Loc := NewLoc.Loc;
    WorkDir := NewLoc.Dir;
    Result := true;
  end
  else
    Result := false;
end;


function TUnitWorkPlan.ChooseTree(aLoc, aAvoid:TKMPoint; aRadius:Integer; aPlantAct: TPlantAct; aUnit:TKMUnit; out Tree:TKMPointDir; out PlantAct: TPlantAct):Boolean;
var
  i:Integer;
  T: TKMPoint;
  TreeList: TKMPointDirList;
  BestToPlant,SecondBestToPlant: TKMPointList;
begin
  TreeList := TKMPointDirList.Create;
  BestToPlant := TKMPointList.Create;
  SecondBestToPlant := TKMPointList.Create;

  fTerrain.FindTree(aLoc, aRadius, aAvoid, aPlantAct, TreeList, BestToPlant, SecondBestToPlant);

  //Convert taAny to either a Tree or a Spot
  if (aPlantAct in [taCut, taAny])
  and ((TreeList.Count > 8) //Always chop the tree if there are many
       or (BestToPlant.Count + SecondBestToPlant.Count = 0)
       or ((TreeList.Count > 0) and (KaMRandom < TreeList.Count / (TreeList.Count + (BestToPlant.Count + SecondBestToPlant.Count)/15)))
      ) then
  begin
    PlantAct := taCut;
    Result := TreeList.GetRandom(Tree);
  end
  else
  begin
    PlantAct := taPlant;
    //First try stumps list
    for i:=BestToPlant.Count-1 downto 0 do
      if not TKMUnitCitizen(aUnit).CanWorkAt(BestToPlant[i], gs_WoodCutterPlant) then
        BestToPlant.DeleteEntry(i);
    Result := BestToPlant.GetRandom(T);
    //Trees must always be planted facing north as that is the direction the animation uses
    if Result then
      Tree := KMPointDir(T, dir_N)
    else
    begin
      //Try empty places list
      for i:=SecondBestToPlant.Count-1 downto 0 do
        if not TKMUnitCitizen(aUnit).CanWorkAt(SecondBestToPlant[i], gs_WoodCutterPlant) then
          SecondBestToPlant.DeleteEntry(i);
      Result := SecondBestToPlant.GetRandom(T);
      //Trees must always be planted facing north as that is the direction the animation uses
      if Result then Tree := KMPointDir(T, dir_N);
    end;
  end;

  TreeList.Free; 
  BestToPlant.Free;
  SecondBestToPlant.Free;
end;


procedure TUnitWorkPlan.FindPlan(aUnit:TKMUnit; aHome:THouseType; aProduct:TResourceType; aLoc:TKMPoint; aPlantAct: TPlantAct);
var
  i:integer;
  Tmp: TKMPointDir;
  PlantAct: TPlantAct;
begin
  fHome := aHome;
  FillDefaults;
  AfterWorkIdle := fResource.HouseDat[aHome].WorkerRest*10;

  //Now we need to fill only specific properties
  case aUnit.UnitType of
    ut_Woodcutter:    if aHome = ht_Woodcutters then
                      begin
                        fIssued := ChooseTree(aLoc, KMPoint(0,0), fResource.UnitDat[aUnit.UnitType].MiningRange, aPlantAct, aUnit, Tmp, PlantAct);
                        if fIssued then
                          case PlantAct of
                            taCut:    begin //Cutting uses DirNW,DirSW,DirSE,DirNE (1,3,5,7) of ua_Work
                                        ResourcePlan(rt_None,0,rt_None,0,rt_Trunk);
                                        WalkStyle(Tmp, ua_WalkBooty,ua_Work,15,20,ua_WalkTool2,gs_WoodCutterCut);
                                      end;
                            taPlant:  begin //Planting uses DirN (0) of ua_Work
                                        WalkStyle(Tmp, ua_WalkTool,ua_Work,12,0,ua_Walk,gs_WoodCutterPlant);
                                      end;
                            else      fIssued := False;
                          end;
                      end;
    ut_Miner:         if aHome = ht_CoalMine then
                      begin
                        fIssued := fTerrain.FindOre(aLoc, rt_Coal, Tmp.Loc);
                        if fIssued then
                        begin
                          Loc := Tmp.Loc;
                          ResourcePlan(rt_None,0,rt_None,0,rt_Coal);
                          GatheringScript := gs_CoalMiner;
                          SubActAdd(ha_Work1,1);
                          SubActAdd(ha_Work2,23);
                          SubActAdd(ha_Work5,1);
                        end else
                          ResourceDepleted := True;
                      end else
                      if aHome = ht_IronMine then
                      begin
                        fIssued := fTerrain.FindOre(aLoc, rt_IronOre, Tmp.Loc);
                        if fIssued then
                        begin
                          Loc := Tmp.Loc;
                          ResourcePlan(rt_None,0,rt_None,0,rt_IronOre);
                          GatheringScript := gs_IronMiner;
                          SubActAdd(ha_Work1,1);
                          SubActAdd(ha_Work2,24);
                          SubActAdd(ha_Work5,1);
                        end else
                          ResourceDepleted := True;
                      end else
                      if aHome = ht_GoldMine then
                      begin
                        fIssued := fTerrain.FindOre(aLoc, rt_GoldOre, Tmp.Loc);
                        if fIssued then
                        begin
                          Loc := Tmp.Loc;
                          ResourcePlan(rt_None,0,rt_None,0,rt_GoldOre);
                          GatheringScript := gs_GoldMiner;
                          SubActAdd(ha_Work1,1);
                          SubActAdd(ha_Work2,24);
                          SubActAdd(ha_Work5,1);
                        end else
                          ResourceDepleted := True;
                      end;
    ut_AnimalBreeder: if aHome = ht_Swine then
                      begin
                        ResourcePlan(rt_Corn,1,rt_None,0,rt_Pig,rt_Skin);
                        GatheringScript := gs_SwineBreeder;
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                        end;
                        SubActAdd(ha_Work2,1);
                        fIssued := True;
                      end else

                      if aHome = ht_Stables then
                      begin
                        ResourcePlan(rt_Corn,1,rt_None,0,rt_Horse);
                        GatheringScript := gs_HorseBreeder;
                        SubActAdd(ha_Work1,1);
                        SubActAdd(ha_Work2,1);
                        SubActAdd(ha_Work3,1);
                        SubActAdd(ha_Work4,1);
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end;
    ut_Farmer:        if aHome = ht_Farm then
                      begin
                        fIssued := fTerrain.FindCornField(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, KMPoint(0,0), aPlantAct, PlantAct, Tmp);
                        if fIssued then
                          case PlantAct of
                            taCut:    begin
                                        ResourcePlan(rt_None,0,rt_None,0,rt_Corn);
                                        WalkStyle(Tmp, ua_WalkTool,ua_Work,6,0,ua_WalkBooty,gs_FarmerCorn);
                                      end;
                            taPlant:  WalkStyle(Tmp, ua_Walk,ua_Work1,10,0,ua_Walk,gs_FarmerSow);
                            else      fIssued := False;
                          end;
                      end else

                      if aHome=ht_Wineyard then
                      begin
                        fIssued := fTerrain.FindWineField(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, KMPoint(0,0), Tmp);
                        if fIssued then
                        begin
                          ResourcePlan(rt_None,0,rt_None,0,rt_Wine);
                          WalkStyle(KMPointDir(Tmp.Loc,dir_N), ua_WalkTool2,ua_Work2,5,0,ua_WalkBooty2,gs_FarmerWine); //The animation for picking grapes is only defined for facing north
                          SubActAdd(ha_Work1,1);
                          SubActAdd(ha_Work2,11);
                          SubActAdd(ha_Work5,1);
                        end;
                      end;
    ut_Lamberjack:    if aHome = ht_Sawmill then
                      begin
                        ResourcePlan(rt_Trunk,1,rt_None,0,rt_Wood);
                        SubActAdd(ha_Work1,1);
                        SubActAdd(ha_Work2,25);
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_ArmorWorkshop) and (aProduct = rt_Armor) then
                      begin
                        ResourcePlan(rt_Leather,1,rt_None,0,rt_Armor);
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work2,0.25);
                        fIssued := True;
                      end else

                      if (aHome = ht_ArmorWorkshop) and (aProduct = rt_Shield) then
                      begin
                        ResourcePlan(rt_Wood,1,rt_None,0,rt_Shield);
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work2,0.25);
                        fIssued := True;
                      end else

                      if (aHome = ht_WeaponWorkshop) and (aProduct = rt_Axe) then
                      begin
                        ResourcePlan(rt_Wood,2,rt_None,0,rt_Axe);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 3 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_WeaponWorkshop) and (aProduct = rt_Pike) then
                      begin
                        ResourcePlan(rt_Wood,2,rt_None,0,rt_Pike);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 3 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_WeaponWorkshop) and (aProduct = rt_Bow) then
                      begin
                        ResourcePlan(rt_Wood,2,rt_None,0,rt_Bow);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 3 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end;
    ut_Baker:         if aHome = ht_Mill then
                      begin
                        ResourcePlan(rt_Corn,1,rt_None,0,rt_Flour);
                        SubActAdd(ha_Work2,47);
                        fIssued := True;
                      end else

                      if aHome = ht_Bakery then
                      begin
                        ResourcePlan(rt_Flour,1,rt_None,0,rt_Bread);
                        for i:=1 to 7 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                        end;
                        fIssued := True;
                      end;
    ut_Butcher:       if aHome = ht_Tannery then
                      begin
                        ResourcePlan(rt_Skin,1,rt_None,0,rt_Leather);
                        SubActAdd(ha_Work1,1);
                        SubActAdd(ha_Work2,29);
                        fIssued := True;
                      end else

                      if aHome = ht_Butchers then
                      begin
                        ResourcePlan(rt_Pig,1,rt_None,0,rt_Sausages);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 6 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work4,1);
                          SubActAdd(ha_Work3,1);
                        end;
                        fIssued := True;
                      end;
    ut_Fisher:        if aHome = ht_FisherHut then
                      begin
                        fIssued := fTerrain.FindFishWater(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, KMPoint(0,0), Tmp);
                        if fIssued then
                        begin
                          ResourcePlan(rt_None,0,rt_None,0,rt_Fish);
                          WalkStyle(Tmp,ua_Walk,ua_Work2,12,0,ua_WalkTool,gs_FisherCatch);
                        end else
                          ResourceDepleted := True;
                      end;
    ut_StoneCutter:   if aHome = ht_Quary then
                      begin
                        fIssued := fTerrain.FindStone(aLoc, fResource.UnitDat[aUnit.UnitType].MiningRange, KMPoint(0,0), Tmp);
                        if fIssued then
                        begin
                          ResourcePlan(rt_None,0,rt_None,0,rt_Stone);
                          WalkStyle(Tmp, ua_Walk,ua_Work,8,0,ua_WalkTool,gs_StoneCutter);
                          SubActAdd(ha_Work1,1);
                          SubActAdd(ha_Work2,9);
                          SubActAdd(ha_Work5,1);
                        end else
                          ResourceDepleted := True;
                      end;
    ut_Smith:         if (aHome = ht_ArmorSmithy) and (aProduct = rt_MetalArmor) then
                      begin
                        ResourcePlan(rt_Steel,1,rt_Coal,1,rt_MetalArmor);
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work2,1);
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_ArmorSmithy) and (aProduct = rt_MetalShield) then
                      begin
                        ResourcePlan(rt_Steel,1,rt_Coal,1,rt_MetalShield);
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work2,1);
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_WeaponSmithy) and (aProduct = rt_Sword) then
                      begin
                        ResourcePlan(rt_Steel,1,rt_Coal,1,rt_Sword);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 3 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_WeaponSmithy) and (aProduct = rt_Hallebard) then
                      begin
                        ResourcePlan(rt_Steel,1,rt_Coal,1,rt_Hallebard);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 3 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end else

                      if (aHome = ht_WeaponSmithy) and (aProduct = rt_Arbalet) then
                      begin
                        ResourcePlan(rt_Steel,1,rt_Coal,1,rt_Arbalet);
                        SubActAdd(ha_Work1,1);
                        for i:=1 to 3 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work5,1);
                        fIssued := True;
                      end;
    ut_Metallurgist:  if aHome = ht_IronSmithy then
                      begin
                        ResourcePlan(rt_IronOre,1,rt_Coal,1,rt_Steel);
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                        end;
                        SubActAdd(ha_Work2,1);
                        SubActAdd(ha_Work3,0.25);
                        fIssued := True;
                      end else
                      if aHome = ht_Metallurgists then
                      begin
                        ResourcePlan(rt_GoldOre,1,rt_Coal,1,rt_Gold);
                        for i:=1 to 4 do begin
                          SubActAdd(ha_Work2,1);
                          SubActAdd(ha_Work3,1);
                          SubActAdd(ha_Work4,1);
                        end;
                        SubActAdd(ha_Work2,1);
                        SubActAdd(ha_Work3,0.1);
                        fIssued := True;
                      end;
  else
    Assert(false, 'No work plan for ' +
                  fResource.UnitDat[aUnit.UnitType].UnitName + ' in ' +
                  fResource.HouseDat[aHome].HouseName);
  end;
end;


procedure TUnitWorkPlan.Load(LoadStream:TKMemoryStream);
var i:integer;
begin
  LoadStream.ReadAssert('WorkPlan');
  LoadStream.Read(fHome, SizeOf(fHome));
  LoadStream.Read(fIssued);
//public
  LoadStream.Read(HasToWalk);
  LoadStream.Read(Loc);
  LoadStream.Read(ActionWalkTo, SizeOf(ActionWalkTo));
  LoadStream.Read(ActionWorkType, SizeOf(ActionWorkType));
  LoadStream.Read(WorkCyc);
  LoadStream.Read(WorkDir);
  LoadStream.Read(GatheringScript, SizeOf(GatheringScript));
  LoadStream.Read(AfterWorkDelay);
  LoadStream.Read(ActionWalkFrom, SizeOf(ActionWalkFrom));
  LoadStream.Read(Resource1, SizeOf(Resource1));
  LoadStream.Read(Count1);
  LoadStream.Read(Resource2, SizeOf(Resource2));
  LoadStream.Read(Count2);
  LoadStream.Read(ActCount);
  for i:=1 to ActCount do //Write only assigned
  begin
    LoadStream.Read(HouseAct[i].Act, SizeOf(HouseAct[i].Act));
    LoadStream.Read(HouseAct[i].TimeToWork);
  end;
  LoadStream.Read(Product1, SizeOf(Product1));
  LoadStream.Read(ProdCount1);
  LoadStream.Read(Product2, SizeOf(Product2));
  LoadStream.Read(ProdCount2);
  LoadStream.Read(AfterWorkIdle);
  LoadStream.Read(ResourceDepleted);
end;


procedure TUnitWorkPlan.Save(SaveStream:TKMemoryStream);
var i:integer;
begin
  SaveStream.Write('WorkPlan');
  SaveStream.Write(fHome, SizeOf(fHome));
  SaveStream.Write(fIssued);
//public
  SaveStream.Write(HasToWalk);
  SaveStream.Write(Loc);
  SaveStream.Write(ActionWalkTo, SizeOf(ActionWalkTo));
  SaveStream.Write(ActionWorkType, SizeOf(ActionWorkType));
  SaveStream.Write(WorkCyc);
  SaveStream.Write(WorkDir);
  SaveStream.Write(GatheringScript, SizeOf(GatheringScript));
  SaveStream.Write(AfterWorkDelay);
  SaveStream.Write(ActionWalkFrom, SizeOf(ActionWalkFrom));
  SaveStream.Write(Resource1, SizeOf(Resource1));
  SaveStream.Write(Count1);
  SaveStream.Write(Resource2, SizeOf(Resource2));
  SaveStream.Write(Count2);
  SaveStream.Write(ActCount);
  for i:=1 to ActCount do //Write only assigned
  begin
    SaveStream.Write(HouseAct[i].Act, SizeOf(HouseAct[i].Act));
    SaveStream.Write(HouseAct[i].TimeToWork);
  end;
  SaveStream.Write(Product1, SizeOf(Product1));
  SaveStream.Write(ProdCount1);
  SaveStream.Write(Product2, SizeOf(Product2));
  SaveStream.Write(ProdCount2);
  SaveStream.Write(AfterWorkIdle);
  SaveStream.Write(ResourceDepleted);
end;


end.
