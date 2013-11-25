unit KM_NetFileTransfer;
{$I KaM_Remake.inc}
interface
uses
  SysUtils, KM_Defaults, KM_CommonClasses
  {$IFDEF FPC}, zstream {$ENDIF}
  {$IFDEF WDC}, ZLib {$ENDIF};

type
  TKMTransferType = (kttMap, kttSave);

  TKMFileSender = class
  private
    fReceiverIndex: Integer;
    fChunksInFlight: Byte;
    fSendStream: TKMemoryStream;
    procedure AddFileToStream(aFileName, aPostFix, aExt: UnicodeString);
  public
    constructor Create(aType: TKMTransferType; aName: UnicodeString; aReceiverIndex: Integer);
    destructor Destroy; override;
    procedure WriteChunk(aStream: TKMemoryStream; aLength: Cardinal);
    procedure AckReceived;
    function CanSend: Boolean;
    function StreamEnd: Boolean;
    property ReceiverIndex: Integer read fReceiverIndex;
  end;

  TKMFileReceiver = class
  private
    fReceiveStream: TKMemoryStream;
    fType: TKMTransferType;
    fName: UnicodeString;
    procedure ClearExistingFiles;
    function ValidExtension(Ext: UnicodeString): Boolean;
  public
    constructor Create(aType: TKMTransferType; aName: UnicodeString);
    destructor Destroy; override;
    procedure DataReceived(aStream: TKMemoryStream);
    procedure TransferComplete;
  end;

implementation
uses
  KM_NetworkTypes;

const
  //TODO: Add LIBX and WAV support for maps
  VALID_MAP_EXTENSIONS:  array[1..4] of UnicodeString =         ('map','dat','script','txt');
  VALID_MAP_EXTENSIONS_POSTFIX:  array[1..2] of UnicodeString = ('libx','wav');
  VALID_SAVE_EXTENSIONS: array[1..3] of UnicodeString =         ('sav','bas','rpl');


function GetFullFileName(aType: TKMTransferType; aName, Postfix, aExt: UnicodeString): UnicodeString;
begin
  case aType of
    kttMap:  Result := ExeDir + 'MapsMP' + PathDelim + aName + PathDelim + aName + Postfix + '.' + aExt;
    kttSave: Result := ExeDir + 'SavesMP' + PathDelim + aName + '.' + aExt;
  end;
end;


{ TKMFileSender }
constructor TKMFileSender.Create(aType: TKMTransferType; aName: UnicodeString; aReceiverIndex: Integer);
var
  I: Integer;
  FileName: UnicodeString;
  F: TSearchRec;
  SourceStream: TKMemoryStream;
  CompressionStream: TCompressionStream;
begin
  inherited Create;
  fReceiverIndex := aReceiverIndex;
  fSendStream := TKMemoryStream.Create;
  fSendStream.WriteA('Transfer');
  fSendStream.Write(aType, SizeOf(aType));
  fSendStream.WriteW(aName);
  //Fill stream with data to be sent
  case aType of
    kttMap:  begin
               for I := Low(VALID_MAP_EXTENSIONS) to High(VALID_MAP_EXTENSIONS) do
               begin
                 FileName := GetFullFileName(aType, aName, '', VALID_MAP_EXTENSIONS[I]);
                 if FileExists(FileName) then
                   AddFileToStream(FileName, '', VALID_MAP_EXTENSIONS[I]);
               end;
               for I := Low(VALID_MAP_EXTENSIONS_POSTFIX) to High(VALID_MAP_EXTENSIONS_POSTFIX) do
               begin
                 FileName := GetFullFileName(aType, aName, '.*', VALID_MAP_EXTENSIONS_POSTFIX[I]);
                 if FindFirst(FileName, faAnyFile, F) = 0 then
                 begin
                   repeat
                     if (F.Attr and faDirectory = 0) then
                       AddFileToStream(ExtractFilePath(FileName) + F.Name, ExtractFileExt(ChangeFileExt(F.Name,'')), VALID_MAP_EXTENSIONS_POSTFIX[I]);
                   until FindNext(F) <> 0;
                   FindClose(F);
                 end;
               end;
             end;
    kttSave: for I := Low(VALID_SAVE_EXTENSIONS) to High(VALID_SAVE_EXTENSIONS) do
             begin
               FileName := GetFullFileName(aType, aName, '', VALID_SAVE_EXTENSIONS[I]);
               if FileExists(FileName) then
                 AddFileToStream(FileName, '', VALID_SAVE_EXTENSIONS[I]);
             end;
  end;
  //Compress fSendStream
  SourceStream := fSendStream;
  fSendStream := TKMemoryStream.Create;
  CompressionStream := TCompressionStream.Create(fSendStream);
  CompressionStream.CopyFrom(SourceStream, 0);
  //fSendStream now contains the compressed data from SourceStream
  CompressionStream.Free;
  SourceStream.Free;
  fSendStream.Position := 0;
end;


destructor TKMFileSender.Destroy;
begin
  fSendStream.Free;
  inherited;
end;


procedure TKMFileSender.AckReceived;
begin
  Dec(fChunksInFlight);
end;


function TKMFileSender.CanSend: Boolean;
begin
  Result := fChunksInFlight <= MAX_CHUNKS_BEFORE_ACK;
end;


procedure TKMFileSender.AddFileToStream(aFileName, aPostFix, aExt: UnicodeString);
var FileStream: TKMemoryStream;
begin
  FileStream := TKMemoryStream.Create;
  FileStream.LoadFromFile(aFileName);

  fSendStream.WriteA('FileStart');
  fSendStream.WriteW(aPostFix);
  fSendStream.WriteW(aExt);
  fSendStream.Write(Cardinal(FileStream.Size));
  if FileStream.Size > 0 then
    fSendStream.CopyFrom(FileStream, FileStream.Size);

  FileStream.Free;
end;


procedure TKMFileSender.WriteChunk(aStream: TKMemoryStream; aLength: Cardinal);
begin
  if aLength > fSendStream.Size - fSendStream.Position then
    aLength := fSendStream.Size - fSendStream.Position;

  aStream.WriteA('FileChunk');
  aStream.Write(aLength);
  aStream.Write(Cardinal(fSendStream.Position));
  aStream.CopyFrom(fSendStream, aLength);
  Inc(fChunksInFlight);
end;


function TKMFileSender.StreamEnd: Boolean;
begin
  Result := fSendStream.Position = fSendStream.Size;
end;


{ TKMFileReceiver }
constructor TKMFileReceiver.Create(aType: TKMTransferType; aName: UnicodeString);
begin
  inherited Create;
  fReceiveStream := TKMemoryStream.Create;
  fType := aType;
  fName := aName;
end;


destructor TKMFileReceiver.Destroy;
begin
  fReceiveStream.Free;
  inherited;
end;


procedure TKMFileReceiver.DataReceived(aStream: TKMemoryStream);
var ChunkSize, tmp: Cardinal;
begin
  aStream.ReadAssert('FileChunk');
  aStream.Read(ChunkSize);
  aStream.Read(tmp);
  Assert(aStream.Size - aStream.Position = ChunkSize, 'Chunk corrupted');
  fReceiveStream.CopyFrom(aStream, ChunkSize);
end;


procedure TKMFileReceiver.ClearExistingFiles;
var
  FileName: UnicodeString;
  F: TSearchRec;
  I: Integer;
begin
  //Prepare destination
  case fType of
    kttMap:  begin
               //Create folder if it is missing
               FileName := ExeDir + 'MapsMP' + PathDelim + fName;
               if not DirectoryExists(FileName) then
                 CreateDir(FileName)
               else
                 //If any files already exist in the folder, delete them
                 if FindFirst(FileName + PathDelim + fName + '*.*', faAnyFile, F) = 0 then
                 begin
                   repeat
                     if (F.Attr and faDirectory = 0) then
                       DeleteFile(FileName + PathDelim + F.Name);
                   until FindNext(F) <> 0;
                   FindClose(F);
                 end;
             end;
    kttSave: begin
               if not DirectoryExists(ExeDir + 'SavesMP') then
                 CreateDir(ExeDir + 'SavesMP')
               else
               begin
                 FileName := ExeDir + 'SavesMP' + PathDelim + fName;
                 for I := Low(VALID_SAVE_EXTENSIONS) to High(VALID_SAVE_EXTENSIONS) do
                   if FileExists(FileName + '.' + VALID_SAVE_EXTENSIONS[I]) then
                     DeleteFile(FileName + '.' + VALID_SAVE_EXTENSIONS[I]);
               end;
             end;
  end;
end;


function TKMFileReceiver.ValidExtension(Ext: UnicodeString): Boolean;
var I: Integer;
begin
  case fType of
    kttMap: begin
               for I := Low(VALID_MAP_EXTENSIONS) to High(VALID_MAP_EXTENSIONS) do
                 if Ext = VALID_MAP_EXTENSIONS[I] then
                 begin
                   Result := True;
                   Exit;
                 end;
               for I := Low(VALID_MAP_EXTENSIONS_POSTFIX) to High(VALID_MAP_EXTENSIONS_POSTFIX) do
                 if Ext = VALID_MAP_EXTENSIONS_POSTFIX[I] then
                 begin
                   Result := True;
                   Exit;
                 end;
            end;
    kttSave: for I := Low(VALID_SAVE_EXTENSIONS) to High(VALID_SAVE_EXTENSIONS) do
               if Ext = VALID_SAVE_EXTENSIONS[I] then
               begin
                 Result := True;
                 Exit;
               end;
  end;
  Result := False;
end;


procedure TKMFileReceiver.TransferComplete;
var
  ReadType: TKMTransferType;
  ReadName, Ext, Postfix, FileName: UnicodeString;
  ReadSize: Cardinal;
  FileStream: TKMemoryStream;
  DecompressionStream: TDecompressionStream;
  ReadStream: TKMemoryStream;
begin
  if fReceiveStream.Size = 0 then Exit; //Transfer was aborted

  //Decompress the stream
  fReceiveStream.Position := 0;
  DecompressionStream := TDecompressionStream.Create(fReceiveStream);
  //We need custom methods like ReadAssert, ReadW, etc. so we need to read from a TKMemoryStream
  ReadStream := TKMemoryStream.Create;
  ReadStream.CopyFromDecompression(DecompressionStream);
  DecompressionStream.Free;
  ReadStream.Position := 0;

  //Read from the stream
  ReadStream.ReadAssert('Transfer');
  ReadStream.Read(ReadType, SizeOf(ReadType));
  Assert(ReadType = fType, 'Unexpected transfer type received');
  ReadStream.ReadW(ReadName);
  Assert(ReadName = fName, 'Unexpected transfer name received');

  ClearExistingFiles;

  //Load each file
  while ReadStream.Position < ReadStream.Size do
  begin
    ReadStream.ReadAssert('FileStart');
    ReadStream.ReadW(Postfix);
    ReadStream.ReadW(Ext);
    //Check EXT is valid (so we don't allow EXEs and stuff)
    Assert(ValidExtension(Ext), 'Unexpected file extension received');

    ReadStream.Read(ReadSize);
    FileStream := TKMemoryStream.Create;
    FileStream.CopyFrom(ReadStream, ReadSize);

    FileName := GetFullFileName(fType, fName, Postfix, Ext);
    Assert(not FileExists(FileName), 'Transfer file already exists');
    FileStream.SaveToFile(FileName);
    FileStream.Free;
  end;
  ReadStream.Free;
end;

end.
