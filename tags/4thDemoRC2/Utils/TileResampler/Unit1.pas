unit Unit1;
{$I TilesetResampler.inc}

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}
interface

uses
  Forms, Controls, StdCtrls, Classes, SysUtils, Dialogs, KromUtils
  {$IFDEF MSWindows}, Windows {$ENDIF}
  {$IFDEF Unix}, LCLType {$ENDIF}
  {$IFDEF WDC}, ZLibEx {$ENDIF}
  {$IFDEF FPC} ,LResources, zstream, fileutil {$ENDIF}
  ;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  end;

var
  Form1: TForm1;

implementation
{$IFDEF WDC}
  {$R *.dfm}
{$ENDIF}

procedure TForm1.Button1Click(Sender: TObject);
var f,f2:file;
    h:array[1..18]of char;
    b:array[1..160]of char;
    i,k:integer;
begin
  assignfile(f,'Tiles.tga'); reset (f,1);
  assignfile(f2,'Tiles1.tga'); rewrite (f2,1);
  blockread(f,h,18);
  h[13]:=#0; h[15]:=#0; //512x512
  blockwrite(f2,h,18); 
  for i:=1 to 640 do for k:=1 to 16 do begin
    blockread(f,b,160);
    if (i-1) mod 40 in [4,9,14,19,24,29,34,39] then else begin
      blockwrite(f2,b[0*4+1],4*4);
      blockwrite(f2,b[5*4+1],3*4);
      blockwrite(f2,b[9*4+1],4*4);
      blockwrite(f2,b[14*4+1],3*4);
      blockwrite(f2,b[18*4+1],4*4);
      blockwrite(f2,b[23*4+1],3*4);
      blockwrite(f2,b[27*4+1],4*4);
      blockwrite(f2,b[32*4+1],3*4);
      blockwrite(f2,b[36*4+1],4*4);
    end;
  end;
  closefile(f);
  closefile(f2);
end;


procedure TForm1.Button2Click(Sender: TObject);
var f1,f2,f3,f4,f5,f6:file;
    h:array[1..18]of char;
    e:array[1..4]of char;
    a,b,c:array[1..4]of char;
    i,k:integer;
begin
  assignfile(f1,'11.tga'); reset (f1,1);
  assignfile(f2,'22.tga'); reset (f2,1);
  assignfile(f3,'33.tga'); reset (f3,1);
  assignfile(f4,'out1.tga'); rewrite (f4,1);
  assignfile(f5,'out2.tga'); rewrite (f5,1);
  assignfile(f6,'out3.tga'); rewrite (f6,1);
  blockread(f1,h,18);
  blockread(f2,h,18);
  blockread(f3,h,18);
  blockwrite(f4,h,18);
  blockwrite(f5,h,18);
  blockwrite(f6,h,18);
  FillChar(e,4,#0);
  for i:=1 to 640 do for k:=1 to 640 do begin
    blockread(f1,a,4);
    blockread(f2,b,4);
    blockread(f3,c,4);
    if (a[1]=b[1])and(b[1]=c[1])
    and(a[2]=b[2])and(b[2]=c[2])
    and(a[3]=b[3])and(b[3]=c[3])
    then begin
      blockwrite(f4,e,4);
      blockwrite(f5,e,4);
      blockwrite(f6,e,4);
    end else begin
      blockwrite(f4,a,4);
      blockwrite(f5,b,4);
      blockwrite(f6,c,4);
    end;
  end;
  closefile(f1);
  closefile(f2);
  closefile(f3);
  closefile(f4);
  closefile(f5);
  closefile(f6);
end;


procedure TForm1.Button3Click(Sender: TObject);
var
  InputStream, OutputStream: TFileStream;
  {$IFDEF WDC}
  CompressionStream: TZCompressionStream;
  {$ENDIF}
  {$IFDEF FPC}
  CompressionStream: TCompressionStream;
  {$ENDIF}
  c:char;
begin
  if not RunOpenDialog(OpenDialog1, '', '', 'Any file|*.*') then exit;
  InputStream := TFileStream.Create(OpenDialog1.FileName, fmOpenRead);
  InputStream.Position := 0;
  InputStream.Read(c, 1);

  if c = #120 then begin
    Application.MessageBox('File is already a zLib archive', 'Error', MB_OK);
    InputStream.Free;
    exit;
  end;
  InputStream.Position := 0; //Reset just in case

  OutputStream := TFileStream.Create(OpenDialog1.FileName+'.tmp', fmCreate);
  {$IFDEF WDC}
  CompressionStream := TZCompressionStream.Create(OutputStream, zcMax);
  {$ENDIF}
  {$IFDEF FPC}
  CompressionStream := TCompressionStream.Create(clMax, OutputStream);
  {$ENDIF}
  CompressionStream.CopyFrom(InputStream, InputStream.Size);
  CompressionStream.Free;
  OutputStream.Free;
  InputStream.Free;
  CopyFile(PChar(OpenDialog1.FileName+'.tmp'),PChar(OpenDialog1.FileName), false); //Overwrite
  DeleteFile(PChar(OpenDialog1.FileName+'.tmp'));
end;


procedure TForm1.Button4Click(Sender: TObject);
var
  InputStream: TFileStream;
  OutputStream: TMemoryStream;
  {$IFDEF WDC}
  DeCompressionStream: TZDecompressionStream;
  {$ENDIF}
  {$IFDEF FPC}
  DeCompressionStream: TDecompressionStream;
  i: Integer;
  Buf: array[0..1023]of Byte;
  {$ENDIF}
  c:char;
begin
  if not RunOpenDialog(OpenDialog1, '', '', 'Any file|*.*') then exit;
  InputStream := TFileStream.Create(OpenDialog1.FileName, fmOpenRead);
  InputStream.Position := 0;
  InputStream.Read(c, 1);

  if c <> #120 then begin
    Application.MessageBox('File is not a zLib archive', 'Error', MB_OK);
    InputStream.Free;
    exit;
  end;
  InputStream.Position := 0; //Reset just in case

  OutputStream := TMemoryStream.Create;
  {$IFDEF WDC}
  DecompressionStream := TZDecompressionStream.Create(InputStream);
  OutputStream.CopyFrom(DecompressionStream, 0);
  {$ENDIF}
  {$IFDEF FPC}
  DecompressionStream := TDecompressionStream.Create(InputStream);
  repeat
  i:=DecompressionStream.Read(Buf, SizeOf(Buf));
  if i <> 0 then OutputStream.Write(Buf, i);
  until i <= 0;
  {$ENDIF}
  InputStream.Free; //Free the Stream before we write to same filename
  OutputStream.SaveToFile(OpenDialog1.Filename);
  DecompressionStream.Free;
  OutputStream.Free;
end;


{$IFDEF FPC}
initialization
  {$i Unit1.lrs}
{$ENDIF}

end.