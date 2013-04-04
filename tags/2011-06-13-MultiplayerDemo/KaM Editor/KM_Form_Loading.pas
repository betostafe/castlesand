unit KM_Form_Loading;
{$I KM_Editor.inc}
{$IFDEF FPC} {$MODE DELPHI} {$ENDIF}
interface

uses
  SysUtils, Classes, Controls, Forms, Graphics,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, KromOGLUtils,
  {$IFDEF WDC} OpenGL, {$ENDIF}
  {$IFDEF FPC} GL, LResources, {$ENDIF}
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  dglOpenGL, KromUtils;

type
  TFormLoading = class(TForm)
    Label1: TLabel;
    Bar1: TProgressBar;
    Image1: TImage;
    Label3: TLabel;
    Bevel1: TBevel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure Label7Click(Sender: TObject);
    procedure Label4Click(Sender: TObject);
  end;


var
  FormLoading: TFormLoading;


implementation
{$IFDEF WDC} {$R *.dfm} {$ENDIF}


uses KM_Unit1, KM_ReadGFX1, KM_Form_NewMap, KM_LoadDAT;


procedure TFormLoading.FormCreate(Sender: TObject);
var InputParam:string;
begin
  Form1.Hide;
  ExeDir := ExtractFilePath(Application.ExeName);

  Show;
  Refresh;
  Label1.Caption:='Initializing 3D';
  Bar1.Position:=0;
  Refresh;

  InitOpenGL;
  h_DC := GetDC(Form1.Panel1.Handle);
  {$IFDEF MSWindows}
  if h_DC=0 then begin MessageBox(Form1.Handle, 'Unable to get a device context', 'Error', MB_OK or MB_ICONERROR); exit; end;
  if not SetDCPixelFormat(h_DC) then exit;
  h_RC := wglCreateContext(h_DC);
  if h_RC=0 then begin MessageBox(Form1.Handle, 'Unable to create an OpenGL rendering context', 'Error', MB_OK or MB_ICONERROR); exit; end;
  if not wglMakeCurrent(h_DC, h_RC) then begin
    MessageBox(Form1.Handle, 'Unable to activate OpenGL rendering context', 'Error', MB_OK or MB_ICONERROR);
    exit;
  end;
  {$ENDIF}
  {$IFDEF Unix}
  MessageBox(Form1.Handle,'wglMakeCurrent and wglCreateContext not ported', 'Error', MB_OK);
  {$ENDIF}
  ReadExtensions;
  ReadImplementationProperties;
  Form1.RenderInit();
  BuildFont(h_DC,16);
  DecimalSeparator:='.';
  
  if ReadGFX(ExeDir) then begin
    MakeObjectsGFX(nil);
    MakeHousesGFX(nil);
  end else begin
    MessageBox(FormLoading.Handle, 'Objects tab is disabled', 'Warning', MB_OK or MB_ICONWARNING);
    Form1.ObjBlock.Enabled:=false;
    Form1.ObjErase.Enabled:=false;
    Form1.ObjPallete.Enabled:=false;
    Form1.ObjPalleteScroll.Enabled:=false;
  end;

  Hide;
  DoClientAreaResize(Form1);
  Form1.Show;
  Form1.WindowState:=wsMaximized;

  InputParam:=ExtractOpenedFileName(cmdline);
  if FileExists(InputParam) then
    if GetFileExt(InputParam)='MAP' then
      Form1.OpenMap(InputParam)
    else
      if GetFileExt(InputParam)='PRO' then
        Form1.OpenPro(InputParam)
      else
        FormNewMap.InitializeNewMap(96,96)
  else
    FormNewMap.InitializeNewMap(96,96);

  //Form1.OpenMap('save01.map');
  //LoadDAT('mission1.dat');
end;


procedure TFormLoading.Label4Click(Sender: TObject);
begin
  MailTo('kromster80@gmail.com','KaM Editor','');
end;


procedure TFormLoading.Label7Click(Sender: TObject);
begin
  OpenMySite('KaM_Editor');
end;


{$IFDEF FPC}
initialization
  {$I KM_Form_Loading.lrs}
{$ENDIF}


end.