unit KM_NetServer;
{$I KaM_Remake.inc}
interface
uses Classes, SysUtils, KM_CommonTypes, KM_NetServerOverbyte;


{ Contains basic items we need for smooth Net experience:

    - start the server
    - stop the server

    - optionaly report non-important status messages

    - generate replies/messages:
      1. player# has disconnected
      2. player# binding (ID)
      3. players ping
      4. players IPs
      5. ...

    - handle orders from Host
      0. declaration of host (associate Hoster rights with this player)
      1. kick player#
      2. request for players ping
      3. request for players IPs
      4. ...

      //Following commands will be added to TKMessageKind
      mk_PlayerLost
      mk_IndexOnServer
      mk_Ping
      mk_PlayersIP

      mk_IAmHost
      mk_KickPlayer
      mk_WasKicked
      mk_AskPing
      mk_AskIPs
}
type
  TKMServerClient = class
  private
    fHandle:integer;
    fPing:integer;
  public
    constructor Create(aHandle:integer);
    property Handle:integer read fHandle; //ReadOnly
    property Ping:integer read fPing write fPing;
  end;


  TKMClientsList = class
  private
    fCount:integer;
    fItems:array of TKMServerClient;
    function GetItem(Index:integer):TKMServerClient;
  public
    property Count:integer read fCount;
    procedure AddPlayer(aHandle:integer);
    procedure RemPlayer(aHandle:integer);
    property Item[Index:integer]:TKMServerClient read GetItem; default;
  end;


  TKMNetServer = class
  private
    fServer:TKMNetServerOverbyte;

    fClientList:TKMClientsList;
    fHostHandle:integer;

    fBufferSize:cardinal;
    fBuffer:array of byte;

    fOnStatusMessage:TGetStrProc;
    procedure Error(const S: string);
    procedure ClientConnect(aHandle:integer);
    procedure ClientDisconnect(aHandle:integer);
    procedure SendMessage(aRecipient:integer; aKind:TKMessageKind; aMsg:integer);
    procedure RecieveMessage(aSenderHandle:integer; aData:pointer; aLength:cardinal);
    procedure DataAvailable(aHandle:integer; aData:pointer; aLength:cardinal);
  public
    constructor Create;
    destructor Destroy; override;
    procedure StartListening(aPort:string);
    procedure StopListening;
    property OnStatusMessage:TGetStrProc write fOnStatusMessage;
  end;


implementation


{ TKMServerClient }
constructor TKMServerClient.Create(aHandle: integer);
begin
  Inherited Create;
  fHandle := aHandle;
end;


{ TKMClientsList }
function TKMClientsList.GetItem(Index: integer): TKMServerClient;
begin
  Result := fItems[Index];
end;


procedure TKMClientsList.AddPlayer(aHandle: integer);
begin
  inc(fCount);
  SetLength(fItems, fCount);
  fItems[fCount-1] := TKMServerClient.Create(aHandle);
end;


procedure TKMClientsList.RemPlayer(aHandle: integer);
var i,ID:integer;
begin
  ID := -1; //Convert Handle to Index
  for i:=0 to fCount-1 do
    if fItems[i].Handle = aHandle then
      ID := i;

  Assert(ID <> -1, 'TKMClientsList. Can not remove player');

  fItems[ID].Free;
  for i:=ID to fCount-2 do
    fItems[i] := fItems[i+1]; //Shift only pointers

  dec(fCount);
  SetLength(fItems, fCount);
end;


{ TKMNetServer }
constructor TKMNetServer.Create;
begin
  Inherited;
  fClientList := TKMClientsList.Create;
  fServer := TKMNetServerOverbyte.Create;
end;


destructor TKMNetServer.Destroy;
begin
  fServer.Free;
  fClientList.Free;
  Inherited;
end;


//There's an error in fServer, perhaps fatal for multiplayer.
procedure TKMNetServer.Error(const S: string);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Error '+S);
end;


procedure TKMNetServer.StartListening(aPort:string);
begin
  fHostHandle := NET_ADDRESS_EMPTY;
  fServer.OnError := Error;
  fServer.OnClientConnect := ClientConnect;
  fServer.OnClientDisconnect := ClientDisconnect;
  fServer.OnDataAvailable := DataAvailable;
  fServer.StartListening(aPort);
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Listening..');
end;


procedure TKMNetServer.StopListening;
begin
  fServer.StopListening;
end;


//Someone has connected to us. We can use supplied Handle to negotiate
procedure TKMNetServer.ClientConnect(aHandle:integer);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Got connection '+inttostr(aHandle));
  fClientList.AddPlayer(aHandle);

  //Let the first client be a Host
  if fHostHandle = NET_ADDRESS_EMPTY then
  begin
    fHostHandle := aHandle;
    if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Host assigned to '+inttostr(fHostHandle));
  end;

  //@Lewin: We can tell the Client he is going to be a Host (has control over server and game setup)
  //Someone has to be in charge of that sort of things. And later on we can support reassign of Host
  //role, so any Client could be in charge (e.g. if Host is defeated or quit)

  SendMessage(aHandle, mk_IndexOnServer, aHandle);
end;


//Someone has disconnected from us.
procedure TKMNetServer.ClientDisconnect(aHandle:integer);
begin
  if Assigned(fOnStatusMessage) then fOnStatusMessage('Server: Client has disconnected '+inttostr(aHandle));
  fClientList.RemPlayer(aHandle);

  if fHostHandle = aHandle then
    fHostHandle := NET_ADDRESS_EMPTY;

  //todo: Send message to remaining clients that client has disconnected
  SendMessage(NET_ADDRESS_ALL, mk_ClientLost, aHandle);
end;


//Assemble the packet as [Sender.Recepient.Length.Data]
procedure TKMNetServer.SendMessage(aRecipient:integer; aKind:TKMessageKind; aMsg:integer);
var i:integer; M:TKMemoryStream;
begin
  M := TKMemoryStream.Create;
  
  M.Write(integer(NET_ADDRESS_SERVER)); //Make sure constant gets treated as 4byte integer
  M.Write(aRecipient);
  M.Write(Integer(5)); //1byte MessageKind + 4byte aHandle
  M.Write(Byte(aKind));
  M.Write(aMsg);
  if aRecipient = NET_ADDRESS_ALL then
    for i:=0 to fClientList.Count-1 do
      fServer.SendData(fClientList[i].Handle, M.Memory, M.Size)
  else
    fServer.SendData(aRecipient, M.Memory, M.Size);
  M.Free;
end;


procedure TKMNetServer.RecieveMessage(aSenderHandle:integer; aData:pointer; aLength:cardinal);
var
  i:integer;
  Kind:TKMessageKind;
  M:TKMemoryStream;
  Msg:string;
  ReMsg:string;
begin
  Assert(aLength >= 1, 'Unexpectedly short message'); //Kind, Message

  M := TKMemoryStream.Create;
  M.WriteBuffer(aData^, aLength);
  M.Position := 0;

  M.Read(Kind, SizeOf(TKMessageKind));

  case Kind of
    mk_AskPingInfo:
            {begin
              //We need to store the time when ping was send
              for i:=0 to fClientList.Count-1 do

              SendMessage(aRecipient:integer; aKind:TKMessageKind; aMsg:integer);


              M.Read(fMyIndexOnServer);
              if Assigned(fOnTextMessage) then fOnTextMessage('Index on Server - ' + inttostr(fMyIndexOnServer));
              case fLANPlayerKind of
                lpk_Host:
                    begin
                      fNetPlayers.Clear;
                      fNetPlayers.AddPlayer(fMyNikname, fMyIndexOnServer);
                      fNetPlayers[fMyIndex].ReadyToStart := true;
                      if Assigned(fOnPlayersSetup) then fOnPlayersSetup(Self);
                    end;
                lpk_Joiner:
                    PacketToHost(mk_AskToJoin, fMyNikname, 0);
              end;
            end;}
  end;

  M.Free;
end;


//Someone has send us something
//For now just repeat the message to everyone excluding Sender
//Send only complete messages to allow to add server messages inbetween
procedure TKMNetServer.DataAvailable(aHandle:integer; aData:pointer; aLength:cardinal);
var PacketSender,PacketRecipient:integer; PacketLength:Cardinal; i:integer;
begin
  //Append new data to buffer
  SetLength(fBuffer, fBufferSize + aLength);
  Move(aData^, fBuffer[fBufferSize], aLength);
  fBufferSize := fBufferSize + aLength;

  //Try to read data packet from buffer
  while fBufferSize >= 12 do
  begin
    PacketSender := PInteger(fBuffer)^;
    PacketRecipient := PInteger(Cardinal(fBuffer)+4)^;
    PacketLength := PCardinal(Cardinal(fBuffer)+8)^;
    if PacketLength <= fBufferSize-12 then
    begin

      case PacketRecipient of
        NET_ADDRESS_ALL: //Transmit to all except sender
            for i:=0 to fClientList.Count-1 do
              if aHandle <> fClientList[i].Handle then
                fServer.SendData(fClientList[i].Handle, @fBuffer[0], PacketLength+12);
        NET_ADDRESS_HOST:
                fServer.SendData(fHostHandle, @fBuffer[0], PacketLength+12);
        NET_ADDRESS_SERVER:
                RecieveMessage(PacketSender, @fBuffer[12], PacketLength);
        else    fServer.SendData(PacketRecipient, @fBuffer[0], PacketLength+12);
      end;

      if 12+PacketLength < fBufferSize then //Check range
        Move(fBuffer[12+PacketLength], fBuffer[0], fBufferSize-PacketLength-12);
      fBufferSize := fBufferSize - PacketLength - 12;
    end else
      Exit;
  end;
end; 


end.
