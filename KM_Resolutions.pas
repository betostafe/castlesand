unit KM_Resolutions;
{$I KaM_Remake.inc}

interface
uses
  Classes, SysUtils,
  {$IFDEF MSWindows} Windows, {$ENDIF}
  KM_Defaults, KM_Settings;

type
  TKMResolutions = class
  private
    fCount: Integer;
    fItems: array of TScreenResData;

    function GetItem(aIndex: Integer): TScreenResData;
    procedure ReadAvailable;
    procedure Sort;
    procedure SetSettingsIDs(aMainSettings: TMainSettings; Correct:Boolean);  //prepares IDs for TMainSettings

  public
    constructor Create;
    destructor Destroy; override;
    procedure Restore; //restores resolution used before program was started

    property Count: Integer read fCount; //Used by UI
    property Items[aIndex: Integer]: TScreenResData read GetItem; //Used by UI

    function Check(aMainSettings: TMainSettings): Boolean; //Check, if resolution is correct
    procedure FindCorrect(aMainSettings: TMainSettings); //Try to find correct resolution
    procedure SetResolution(aResIndex, aRefIndex: Integer); //Apply the resolution
  end;


implementation


constructor TKMResolutions.Create;
begin
  inherited;
  ReadAvailable;
  Sort;
end;


destructor TKMResolutions.Destroy;
begin
  Restore;
  inherited;
end;


procedure TKMResolutions.ReadAvailable;
var
  I,M,N: integer;
  {$IFDEF MSWindows}DevMode: TDevMode;{$ENDIF}
begin
  {$IFDEF MSWindows}
  I := 0;
  fCount := 0;
  while EnumDisplaySettings(nil, I, DevMode) do
  with DevMode do
  begin
    Inc(I);
    //Take only 32bpp modes
    //Exclude rotated modes, as Win reports them too
    if (dmBitsPerPel = 32) and (dmPelsWidth > dmPelsHeight)
    and (dmPelsWidth >= 1024) and (dmPelsHeight >= 768)
    and (dmDisplayFrequency > 0) then
    begin
      //Find next empty place and avoid duplicating
      N := 0;
      while (N < fCount) and (fItems[N].Width <> 0)
            and ((fItems[N].Width <> dmPelsWidth) or (fItems[N].Height <> dmPelsHeight)) do
        Inc(N);
      if (fCount < N+1) then
      begin
        //increasing length of array
        SetLength(fItems, N+1);
        //we don't want random data in freshly allocated space
        FillChar(fItems[N], SizeOf(TScreenResData), #0);
        inc(fCount);
      end;
      if (N < fCount) and (fItems[N].Width = 0) then
      begin
        fItems[N].Width := dmPelsWidth;
        fItems[N].Height := dmPelsHeight;
      end;
      //Find next empty place and avoid duplicating
      M := 0;
      while (N < fCount) and (M < fItems[N].RefRateCount)
            and (fItems[N].RefRate[M] <> 0)
            and (fItems[N].RefRate[M] <> dmDisplayFrequency) do
        Inc(M);

      if (fItems[N].RefRateCount < M+1) then
      begin
        //increasing length of array
        SetLength(fItems[N].RefRate, M+1);
        //we don't want random data in freshly allocated space
        FillChar(fItems[N].RefRate[M], SizeOf(Word), #0);
        inc(fItems[N].RefRateCount);
      end;

      if (M < fItems[N].RefRateCount) and (N < fCount) and (fItems[N].RefRate[M] = 0) then
        fItems[N].RefRate[M] := dmDisplayFrequency;
    end;
  end;
  {$ENDIF}
end;


procedure TKMResolutions.Sort;
var I,J,K:integer;
    TempScreenResData:TScreenResData;
    TempRefRate:Word;
begin
  if fCount > 0 then
    for I:=0 to fCount-1 do
    begin
      for J:=0 to fItems[I].RefRateCount-1 do
      begin
        //firstly, refresh rates for each resolution are being sorted
        K:=J;  //iterator will be modified, but we don't want to lose it
        while ((K>0) and (fItems[I].RefRate[K] < fItems[I].RefRate[K-1]) and
             //excluding zero values from sorting, so they are kept at the end of array
               (fItems[I].RefRate[K] > 0)) do
        begin
          //simple replacement of data
          TempRefRate := fItems[I].RefRate[K];
          fItems[I].RefRate[K] := fItems[I].RefRate[K-1];
          fItems[I].RefRate[K-1] := TempRefRate;
          dec(K);
        end;
      end;
      if I=0 then continue;
      J:=I;  //iterator will be modified, but we don't want to lose it
      //moving resolution to its final position
      while ((J>0) and (((fItems[J].Width < fItems[J-1].Width) and
           //excluding zero values from sorting, so they are kept at the end of array
             (fItems[J].Width > 0) and (fItems[J].Height > 0)) or
             ((fItems[J].Width = fItems[J-1].Width) and
             (fItems[J].Height < fItems[J-1].Height)))) do
      begin
        //simple replacement of data
        TempScreenResData := fItems[J];
        fItems[J] := fItems[J-1];
        fItems[J-1] := TempScreenResData;
        dec(J);
      end;
    end;
end;


function TKMResolutions.GetItem(aIndex: Integer): TScreenResData;
begin
  if (fCount>0) and (aIndex in [0..fCount-1]) then
    Result := fItems[aIndex];
end;


procedure TKMResolutions.Restore;
begin
  {$IFDEF MSWindows}
    ChangeDisplaySettings(DEVMODE(nil^), 0);
  {$ENDIF}
end;


function TKMResolutions.Check(aMainSettings: TMainSettings): Boolean;
var I, J: Integer;
begin
  //Try to find matching Resolution
  Result := False;
  if fCount > 0 then
    for I := 0 to fCount-1 do
      if (fItems[I].Width = aMainSettings.ResolutionWidth)
      and(fItems[I].Height = aMainSettings.ResolutionHeight) then
        for J := 0 to fItems[I].RefRateCount-1 do
          if (aMainSettings.RefreshRate = fItems[I].RefRate[J]) then
          begin
            Result := True;
            SetSettingsIDs(aMainSettings, True);
          end;
end;


procedure TKMResolutions.SetResolution(aResIndex,aRefIndex: Integer);
{$IFDEF MSWindows} var DeviceMode: DEVMODE; {$ENDIF}
begin
  if (fCount > 0) and (aResIndex in [0..fCount-1]) and
     (aRefIndex in [0..fItems[aResIndex].RefRateCount-1]) then
  begin
    {$IFDEF MSWindows}
    ZeroMemory(@DeviceMode, SizeOf(DeviceMode));
    with DeviceMode do
    begin
      dmSize := SizeOf(TDeviceMode);
      dmPelsWidth := fItems[aResIndex].Width;
      dmPelsHeight := fItems[aResIndex].Height;
      dmBitsPerPel := 32;
      dmDisplayFrequency := fItems[aResIndex].RefRate[aRefIndex];
      dmFields := DM_DISPLAYFREQUENCY or DM_BITSPERPEL or DM_PELSWIDTH or DM_PELSHEIGHT;
    end;

    ChangeDisplaySettings(DeviceMode, CDS_FULLSCREEN);
    {$ENDIF}
  end;
end;


procedure TKMResolutions.FindCorrect(aMainSettings:TMainSettings);
{$IFDEF MSWindows}var DevMode: TDevMode;{$ENDIF}
begin
  {$IFDEF MSWindows}
  EnumDisplaySettings(nil, Cardinal(-1){ENUM_CURRENT_SETTINGS}, DevMode);
  with DevMode do
  begin
    //we need to check, if current resolution is lower than we can support
    if (dmPelsWidth >= 1024) and (dmPelsHeight >= 768) and (fCount > 0) then
    begin
      aMainSettings.ResolutionWidth := dmPelsWidth;
      aMainSettings.ResolutionHeight := dmPelsHeight;
      aMainSettings.RefreshRate := dmDisplayFrequency;
    end
    else if fCount > 0 then
    //we cannot support currently used resolution, but
    //we can switch to supported one
    begin
      aMainSettings.ResolutionWidth := fItems[0].Width;
      aMainSettings.ResolutionHeight := fItems[0].Height;
      aMainSettings.RefreshRate := fItems[0].RefRate[0];
    end
    //there is no supported resolution
    //forcing windowed mode
    else aMainSettings.FullScreen := false;
  end;
  {$ENDIF}
  //correct values must be saved immediately
  aMainSettings.SaveSettings(True);

  SetSettingsIDs(aMainSettings, False);
end;


//we need to set this IDs in settings, so we don't work on "physical" values
//and everything is kept inside this class, not in TMainSettings
procedure TKMResolutions.SetSettingsIDs(aMainSettings:TMainSettings; Correct:Boolean);
var I,J: Integer;
  {$IFDEF MSWindows}DevMode: TDevMode;{$ENDIF}
begin
  if fCount > 0 then
  begin
    if Correct then
    //looking for IDs for data from settings file
      for I:=0 to fCount-1 do
        if (fItems[I].Width = aMainSettings.ResolutionWidth) and (fItems[I].Height = aMainSettings.ResolutionHeight) then
          for J:=0 to fItems[I].RefRateCount-1 do
            if fItems[I].RefRate[J] = aMainSettings.RefreshRate then
            begin
              aMainSettings.ResolutionID := I;
              aMainSettings.RefreshRateID := J;
            end;
    if not Correct then
    //looking for IDs for data retrieved from system
    begin
      EnumDisplaySettings(nil, Cardinal(-1){ENUM_CURRENT_SETTINGS}, DevMode);
      for I := 0 to fCount-1 do
        with DevMode do
        begin
          if (fItems[I].Width = dmPelsWidth) and (fItems[I].Height = dmPelsHeight) then
            for J := 0 to fItems[I].RefRateCount-1 do
              if fItems[I].RefRate[J] = dmDisplayFrequency  then
              begin
                aMainSettings.ResolutionID := I;
                aMainSettings.RefreshRateID := J;
              end;
        end;
      end;
  end;
end;


end.

