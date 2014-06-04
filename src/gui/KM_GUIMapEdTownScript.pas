unit KM_GUIMapEdTownScript;
{$I KaM_Remake.inc}
interface
uses
   Classes, Controls, KromUtils, Math, StrUtils, SysUtils,
   KM_Controls;

type
  TKMMapEdTownScript = class
  private
    procedure Town_ScriptRefresh;
    procedure Town_ScriptChange(Sender: TObject);
  protected
    Panel_Script: TKMPanel;
    CheckBox_AutoBuild: TKMCheckBox;
    CheckBox_AutoRepair: TKMCheckBox;
    TrackBar_SerfsPer10Houses: TKMTrackBar;
    TrackBar_WorkerCount: TKMTrackBar;
    CheckBox_UnlimitedEquip: TKMCheckBox;
    TrackBar_EquipRateLeather: TKMTrackBar;
    TrackBar_EquipRateIron: TKMTrackBar;
    Button_AIStart: TKMButtonFlat;
  public
    constructor Create(aParent: TKMPanel);

    procedure Show;
    procedure Hide;
    function Visible: Boolean;
  end;


implementation
uses
  KM_HandsCollection, KM_ResTexts, KM_RenderUI, KM_ResFonts, KM_InterfaceGame, KM_GameCursor,
  KM_Defaults, KM_Pics, KM_Hand;


{ TKMMapEdTownScript }
constructor TKMMapEdTownScript.Create(aParent: TKMPanel);
begin
  inherited Create;

  Panel_Script := TKMPanel.Create(aParent, 0, 28, TB_WIDTH, 400);
  TKMLabel.Create(Panel_Script, 0, PAGE_TITLE_Y, TB_WIDTH, 0, gResTexts[TX_MAPED_AI_TITLE], fnt_Outline, taCenter);
  CheckBox_AutoBuild := TKMCheckBox.Create(Panel_Script, 0, 30, TB_WIDTH, 20, gResTexts[TX_MAPED_AI_AUTOBUILD], fnt_Metal);
  CheckBox_AutoBuild.OnClick := Town_ScriptChange;
  CheckBox_AutoRepair := TKMCheckBox.Create(Panel_Script, 0, 50, TB_WIDTH, 20, gResTexts[TX_MAPED_AI_AUTOREPAIR], fnt_Metal);
  CheckBox_AutoRepair.OnClick := Town_ScriptChange;
  TrackBar_SerfsPer10Houses := TKMTrackBar.Create(Panel_Script, 0, 70, TB_WIDTH, 1, 50);
  TrackBar_SerfsPer10Houses.Caption := gResTexts[TX_MAPED_AI_SERFS_PER_10_HOUSES];
  TrackBar_SerfsPer10Houses.OnChange := Town_ScriptChange;
  TrackBar_WorkerCount := TKMTrackBar.Create(Panel_Script, 0, 110, TB_WIDTH, 0, 30);
  TrackBar_WorkerCount.Caption := gResTexts[TX_MAPED_AI_WORKERS];
  TrackBar_WorkerCount.OnChange := Town_ScriptChange;

  CheckBox_UnlimitedEquip := TKMCheckBox.Create(Panel_Script, 0, 156, TB_WIDTH, 20, gResTexts[TX_MAPED_AI_FASTEQUIP], fnt_Metal);
  CheckBox_UnlimitedEquip.OnClick := Town_ScriptChange;
  CheckBox_UnlimitedEquip.Hint := gResTexts[TX_MAPED_AI_FASTEQUIP_HINT];

  TrackBar_EquipRateLeather := TKMTrackBar.Create(Panel_Script, 0, 176, TB_WIDTH, 10, 300);
  TrackBar_EquipRateLeather.Caption := gResTexts[TX_MAPED_AI_DEFENSE_EQUIP_LEATHER];
  TrackBar_EquipRateLeather.Step := 5;
  TrackBar_EquipRateLeather.OnChange := Town_ScriptChange;

  TrackBar_EquipRateIron := TKMTrackBar.Create(Panel_Script, 0, 220, TB_WIDTH, 10, 300);
  TrackBar_EquipRateIron.Caption := gResTexts[TX_MAPED_AI_DEFENSE_EQUIP_IRON];
  TrackBar_EquipRateIron.Step := 5;
  TrackBar_EquipRateIron.OnChange := Town_ScriptChange;

  TKMLabel.Create(Panel_Script, 0, 270, gResTexts[TX_MAPED_AI_START], fnt_Metal, taLeft);
  Button_AIStart         := TKMButtonFlat.Create(Panel_Script, 0, 290, 33, 33, 62, rxGuiMain);
  Button_AIStart.Hint    := gResTexts[TX_MAPED_AI_START_HINT];
  Button_AIStart.OnClick := Town_ScriptChange;
end;


procedure TKMMapEdTownScript.Town_ScriptRefresh;
begin
  CheckBox_AutoBuild.Checked := gHands[MySpectator.HandIndex].AI.Setup.AutoBuild;
  CheckBox_AutoRepair.Checked := gHands[MySpectator.HandIndex].AI.Mayor.AutoRepair;
  TrackBar_SerfsPer10Houses.Position := Round(10*gHands[MySpectator.HandIndex].AI.Setup.SerfsPerHouse);
  TrackBar_WorkerCount.Position := gHands[MySpectator.HandIndex].AI.Setup.WorkerCount;
  CheckBox_UnlimitedEquip.Checked := gHands[MySpectator.HandIndex].AI.Setup.UnlimitedEquip;
  TrackBar_EquipRateLeather.Position := gHands[MySpectator.HandIndex].AI.Setup.EquipRateLeather div 10;
  TrackBar_EquipRateIron.Position := gHands[MySpectator.HandIndex].AI.Setup.EquipRateIron div 10;
end;


procedure TKMMapEdTownScript.Town_ScriptChange(Sender: TObject);
begin
  gHands[MySpectator.HandIndex].AI.Setup.AutoBuild := CheckBox_AutoBuild.Checked;
  gHands[MySpectator.HandIndex].AI.Mayor.AutoRepair := CheckBox_AutoRepair.Checked;
  gHands[MySpectator.HandIndex].AI.Setup.SerfsPerHouse := TrackBar_SerfsPer10Houses.Position / 10;
  gHands[MySpectator.HandIndex].AI.Setup.WorkerCount := TrackBar_WorkerCount.Position;
  gHands[MySpectator.HandIndex].AI.Setup.UnlimitedEquip := CheckBox_UnlimitedEquip.Checked;
  gHands[MySpectator.HandIndex].AI.Setup.EquipRateLeather := TrackBar_EquipRateLeather.Position * 10;
  gHands[MySpectator.HandIndex].AI.Setup.EquipRateIron := TrackBar_EquipRateIron.Position * 10;

  if Sender = Button_AIStart then
    Button_AIStart.Down := not Button_AIStart.Down;

  if Button_AIStart.Down then
  begin
    GameCursor.Mode := cmMarkers;
    GameCursor.Tag1 := MARKER_AISTART;
  end
  else
  begin
    GameCursor.Mode := cmNone;
    GameCursor.Tag1 := 0;
  end;
end;


procedure TKMMapEdTownScript.Hide;
begin
  Panel_Script.Hide;
end;


procedure TKMMapEdTownScript.Show;
begin
  Button_AIStart.Down := False;
  Town_ScriptRefresh;
  Panel_Script.Show;
end;


function TKMMapEdTownScript.Visible: Boolean;
begin
  Result := Panel_Script.Visible;
end;


end.
