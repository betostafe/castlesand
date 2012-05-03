unit TestKM_Campaigns;
interface
uses
  TestFramework, SysUtils, KM_Points, KM_Defaults, KM_CommonClasses, Classes, KromUtils,
  KM_Campaigns, KM_Locales, KM_Log, KM_Pics, KM_TextLibrary, KM_Resource, Math;

type
  // Test methods for class TKMCampaign
  TestTKMCampaign = class(TTestCase)
  strict private
    FKMCampaign: TKMCampaign;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLoadFromFile;
    procedure TestSaveToFile;
    procedure TestLoadFromPath;
    procedure TestMissionFile;
    procedure TestMissionTitle;
    procedure TestMissionText;
  end;

  // Test methods for class TKMCampaignsCollection
  TestTKMCampaignsCollection = class(TTestCase)
  strict private
    FKMCampaignsCollection: TKMCampaignsCollection;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestScanFolder;
    procedure TestLoadProgress;
    procedure TestSaveProgress;
    procedure TestSetActive;
    procedure TestCount;
    procedure TestCampaignByTitle;
    procedure TestUnlockNextMap;
    procedure TestSave;
    procedure TestLoad;
  end;

implementation

procedure TestTKMCampaign.SetUp;
begin
  ExeDir := ExtractFilePath(ParamStr(0)) + '..\';
  FKMCampaign := TKMCampaign.Create;
  fLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'Temp\temp.log');
  fResource := TResource.Create(nil, nil, nil);
end;

procedure TestTKMCampaign.TearDown;
begin
  fResource.Free;
  fLog.Free;
  FKMCampaign.Free;
  FKMCampaign := nil;
end;

procedure TestTKMCampaign.TestLoadFromFile;
begin
  FKMCampaign.LoadFromFile('..\Campaigns\The Shattered Kingdom\info.cmp');

  Check(FKMCampaign.MapCount = 20);
  Check(FKMCampaign.Maps[0].NodeCount > 0);
  Check(FKMCampaign.ShortTitle <> '');
  Check(FKMCampaign.UnlockedMap = 0);
  Check(FKMCampaign.MissionFile(0) <> '');
  Check(FKMCampaign.BackGroundPic.RX <> rxTrees);
  Check(FKMCampaign.BackGroundPic.ID <> 0);
end;

procedure TestTKMCampaign.TestSaveToFile;
var
  FileLoad, FileSave: string;
begin
  //Test with sample file
  FileLoad := ExtractFilePath(ParamStr(0)) + '..\Campaigns\The Shattered Kingdom\info.cmp';
  FileSave := ExtractFilePath(ParamStr(0)) + 'Temp\campaign.tmp';
  ForceDirectories(ExtractFilePath(FileSave));
  FKMCampaign.LoadFromFile(FileLoad);
  FKMCampaign.SaveToFile(FileSave);
  Check(CheckSameContents(FileLoad, FileSave));
end;

procedure TestTKMCampaign.TestLoadFromPath;
var
  FileSave: string;
begin
  FileSave := ExtractFilePath(ParamStr(0)) + 'Temp\campaign.tmp';

  //Test empty file
  FKMCampaign.SaveToFile(FileSave);
  FKMCampaign.LoadFromFile(FileSave);
  Check(FKMCampaign.MapCount = 0);
  Check(FKMCampaign.ShortTitle = '');
end;

procedure TestTKMCampaign.TestMissionFile;
begin
  FKMCampaign.LoadFromFile('..\Campaigns\The Shattered Kingdom\info.cmp');
  Check(FKMCampaign.MissionFile(0) = 'TSK01\TSK01.dat', 'Unexpected result: ' + FKMCampaign.MissionFile(0));
  FKMCampaign.LoadFromFile('..\Campaigns\The Peasants Rebellion\info.cmp');
  Check(FKMCampaign.MissionFile(0) = 'TPR01\TPR01.dat', 'Unexpected result: ' + FKMCampaign.MissionFile(0));
end;

procedure TestTKMCampaign.TestMissionTitle;
begin
  //FKMCampaign.MissionTitle(aIndex);
end;

procedure TestTKMCampaign.TestMissionText;
begin
  //ReturnValue := FKMCampaign.MissionText(aIndex);
end;

procedure TestTKMCampaignsCollection.SetUp;
begin
  ExeDir := ExtractFilePath(ParamStr(0)) + '..\';
  fLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'Temp\log.tmp');
  fLocales := TKMLocales.Create(ExeDir+'data\locales.txt');
  fResource := TResource.Create(nil, nil, nil);
  fTextLibrary := TTextLibrary.Create(ExeDir + 'data\text\', 'eng');
  FKMCampaignsCollection := TKMCampaignsCollection.Create;
end;

procedure TestTKMCampaignsCollection.TearDown;
begin
  fTextLibrary.Free;
  fResource.Free;
  fLocales.Free;
  fLog.Free;
  FKMCampaignsCollection.Free;
  FKMCampaignsCollection := nil;
end;

procedure TestTKMCampaignsCollection.TestCount;
begin
  Check(FKMCampaignsCollection.Count = 0);

  FKMCampaignsCollection.ScanFolder(ExeDir + 'Campaigns\');
  Check(FKMCampaignsCollection.Count >= 2, 'TSK and TPR campaigns should be there');
end;

procedure TestTKMCampaignsCollection.TestCampaignByTitle;
var
  ReturnValue: TKMCampaign;
  aShortTitle: AnsiString;
begin
  // TODO: Setup method call parameters
  //ReturnValue := FKMCampaignsCollection.CampaignByTitle(aShortTitle);
  // TODO: Validate method results
end;

procedure TestTKMCampaignsCollection.TestUnlockNextMap;
var I: Integer;
begin
  //Check that first map is available
  FKMCampaignsCollection.ScanFolder(ExeDir + 'Campaigns\');
  FKMCampaignsCollection.SetActive(FKMCampaignsCollection.Campaigns[0], 0);
  Check(FKMCampaignsCollection.ActiveCampaign.UnlockedMap = 0, 'First map should be unlocked');

  //Unlock all the maps consequentaly
  for I := 0 to FKMCampaignsCollection.Count do
  begin
    FKMCampaignsCollection.UnlockNextMap;
    Check(FKMCampaignsCollection.ActiveCampaign.UnlockedMap = Min(I+1, FKMCampaignsCollection.Count - 1), 'Wrong next map ' + IntToStr(I));
  end;
end;

procedure TestTKMCampaignsCollection.TestSave;
var
  SaveStream: TKMemoryStream;
begin
  //Empty collection
  SaveStream := TKMemoryStream.Create;
  FKMCampaignsCollection.Save(SaveStream);
  SaveStream.Position := 0;
  FKMCampaignsCollection.Load(SaveStream);
  Check(FKMCampaignsCollection.Count = 0);
  SaveStream.Free;
end;

procedure TestTKMCampaignsCollection.TestLoad;
begin
  //
end;

procedure TestTKMCampaignsCollection.TestScanFolder;
begin
  FKMCampaignsCollection.ScanFolder(ExeDir + 'Campaigns\');
  Check(FKMCampaignsCollection.Count >= 2);
end;

procedure TestTKMCampaignsCollection.TestLoadProgress;
begin
  //
end;

procedure TestTKMCampaignsCollection.TestSaveProgress;
var
  FileName: string;
begin
  //Empty
  FileName := ExtractFilePath(ParamStr(0)) + 'Temp\camp.tmp';
  FKMCampaignsCollection.SaveProgress(FileName);
  FKMCampaignsCollection.LoadProgress(FileName);
  Check(FKMCampaignsCollection.Count = 0);
  Check(FKMCampaignsCollection.ActiveCampaign = nil, 'Empty campaign should be nil');
  Check(FKMCampaignsCollection.ActiveCampaignMap = 0, 'Empty map should be empty');

  //Filled
end;

procedure TestTKMCampaignsCollection.TestSetActive;
begin
  //Check that first map is available
  FKMCampaignsCollection.ScanFolder(ExeDir + 'Campaigns\');
  Check(FKMCampaignsCollection.ActiveCampaign = nil, 'Initial campaign should be nil');
  Check(FKMCampaignsCollection.ActiveCampaignMap = 0, 'Initial map should be empty');

  //Select first campaign
  FKMCampaignsCollection.SetActive(FKMCampaignsCollection.Campaigns[0], 0);
  Check(FKMCampaignsCollection.ActiveCampaign = FKMCampaignsCollection.Campaigns[0]);
  Check(FKMCampaignsCollection.ActiveCampaignMap = 0);
  Check(FKMCampaignsCollection.ActiveCampaign.UnlockedMap = 0, 'First map should be unlocked');
end;

initialization
  // Register any test cases with the test runner
  RegisterTest('Campaigns', TestTKMCampaign.Suite);
  RegisterTest('Campaigns', TestTKMCampaignsCollection.Suite);
end.

