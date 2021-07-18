unit BanSystem;

interface

uses
  Constants;

  procedure AddBannedIP(IP: ShortString; Reason: string;
    Duration: Integer = PERMANENT);
  function DelBannedIP(IP: ShortString): Boolean;
  function CheckBannedIP(IP: ShortString): Boolean;
  function FindBan(IP: ShortString): Integer;
  procedure LoadBannedList(filename: string);
  procedure SaveBannedList(filename: string);
  // bans hardwareids
  procedure AddBannedHW(HW: string; Reason: string;
    Duration: Integer = PERMANENT);
  function DelBannedHW(HW: string): Boolean;
  function CheckBannedHW(HW: string): Boolean;
  function FindBanHW(HW: string): Integer;
  procedure LoadBannedListHW(filename: string);
  procedure SaveBannedListHW(filename: string);
  procedure UpdateIPBanList;
  procedure UpdateHWBanList;

type
  TBanIP = packed record
    IP: string;
    Time: Integer;
    Reason: string;
  end;

  TBanHW = packed record
    HW: string;
    Time: Integer;
    Reason: string;
  end;

var
  BannedIPList: array of TBanIP;
  BannedHWList: array of TBanHW;
  LastBan: string;
  LastBanHW: string;

implementation

uses
  Server, fpmasks, classes, sysutils, Util, ServerHelper;

procedure AddBannedIP(IP: ShortString; Reason: string;
  Duration: Integer = PERMANENT);
var
  i, findex: Integer;
begin
  findex := 0;
  if CheckBannedIP(IP) then
    Exit;
  for i := 1 to High(BannedIPList) do
    if BannedIPList[i].IP = '' then
    begin
      findex := i;
      Break;
    end;

  if findex = 0 then
  begin
    SetLength(BannedIPList, High(BannedIPList) + 2);
    BannedIPList[High(BannedIPList)].IP := IP;
    BannedIPList[High(BannedIPList)].Time := Duration;
    BannedIPList[High(BannedIPList)].Reason := Reason;
  end else
  begin
    BannedIPList[findex].IP := IP;
    BannedIPList[findex].Time := Duration;
    BannedIPList[findex].Reason := Reason;
  end;
  LastBan := IP;
end;

function DelBannedIP(IP: ShortString): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to High(BannedIPList) do
    if (BannedIPList[i].IP = IP) and (IP <> '') then
    begin
      BannedIPList[i].IP := '';
      BannedIPList[i].Time := PERMANENT;
      BannedIPList[i].Reason := '';
      Result := True;
    end;
end;

function CheckBannedIP(IP: ShortString): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to High(BannedIPList) do
    if MatchesMask(IP, BannedIPList[i].IP) then
    begin
      Result := True;
      Break
    end;
end;

function FindBan(IP: ShortString): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 1 to High(BannedIPList) do
    if MatchesMask(IP, BannedIPList[i].IP) then
    begin
      Result := i;
      Break;
    end;
end;

procedure LoadBannedList(filename: string);
var
  i, j: Integer;
  TempArray: TStringList;
  Buff: TStringArray;
  Time: Integer;
begin
  Buff := nil;
  TempArray := TStringList.Create;
  TempArray.LoadFromFile(filename);
  SetLength(BannedIPList, 1);
  j := 1;
  for i := 1 to (TempArray.Count) do
  begin
    Buff := SplitStr(TempArray[i - 1], ':', 4);
    if Trim(Buff[0]) = '' then
      Continue;
    SetLength(BannedIPList, j + 1);
    Inc(j, 1);

    Time := StrToIntDef(Buff[1], Low(Integer));

    if Time = Low(Integer) then
      Continue;

    BannedIPList[High(BannedIPList)].IP := Buff[0];
    BannedIPList[High(BannedIPList)].Time := Time;
    BannedIPList[High(BannedIPList)].Reason := Buff[2];
  end;
  TempArray.free;
end;

procedure SaveBannedList(filename: string);
var
  i: Integer;
  Buff: string;
  SaveFile: TextFile;
begin
  Buff := '';
  for i := 1 to High(BannedIPList) do
  begin
    if BannedIPList[i].IP <> '' then
      Buff := Buff + BannedIPList[i].IP + ':' + IntToStr(BannedIPList[i].Time) +
      ':' + BannedIPList[i].Reason + Chr(13) + Chr(10);
  end;
  AssignFile(SaveFile, filename);
  ReWrite(SaveFile);
  Write(SaveFile, Buff);
  CloseFile(SaveFile);
end;

procedure UpdateIPBanList;
var
  j: Byte;
begin
  for j := 1 to High(BannedIPList) do
    if (BannedIPList[j].IP <> '') then
    begin
      if BannedIPList[j].Time > 0 then
      begin
        Dec(BannedIPList[j].Time, 3600);
        if (BannedIPList[j].Time < 0) and
          not (BannedIPList[j].Time = PERMANENT) then
          BannedIPList[j].Time := 0;
      end;
      if (BannedIPList[j].Time = 0) and
        not (BannedIPList[j].Time = PERMANENT) then
      begin
        MainConsole.Console('IP number ' + BannedIPList[j].IP +
          ' (' + BannedIPList[j].Reason + ') unbanned',
          CLIENT_MESSAGE_COLOR);
        DelBannedIP(BannedIPList[j].IP);
        SaveTxtLists;
      end;
    end;
end;

// hardware id bans
procedure AddBannedHW(HW: string; Reason: string;
  Duration: Integer = PERMANENT);
var
  i, findex: Integer;
begin
  findex := 0;
  if CheckBannedHW(HW) then
    Exit;
  for i := 1 to High(BannedHWList) do
    if BannedHWList[i].HW = '' then
    begin
      findex := i;
      Break;
    end;

  if findex = 0 then
  begin
    SetLength(BannedHWList, High(BannedHWList) + 2);
    BannedHWList[High(BannedHWList)].HW := HW;
    BannedHWList[High(BannedHWList)].Time := Duration;
    BannedHWList[High(BannedHWList)].Reason := Reason;
  end else
  begin
    BannedHWList[findex].HW := HW;
    BannedHWList[findex].Time := Duration;
    BannedHWList[findex].Reason := Reason;
  end;
  LastBanHW := HW;
end;

function DelBannedHW(HW: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to High(BannedHWList) do
    if (BannedHWList[i].HW = HW) and (HW <> '') then
    begin
      BannedHWList[i].HW := '';
      BannedHWList[i].Time := PERMANENT;
      BannedHWList[i].Reason := '';
      Result := True;
    end;
end;

function CheckBannedHW(HW: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to High(BannedHWList) do
    if MatchesMask(HW, BannedHWList[i].HW) then
    begin
      Result := True;
      Break
    end;
end;

function FindBanHW(HW: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 1 to High(BannedHWList) do
    if MatchesMask(HW, BannedHWList[i].HW) then
    begin
      Result := i;
      Break;
    end;
end;

procedure LoadBannedListHW(filename: string);
var
  i, j: Integer;
  TempArray: TStringList;
  Buff: TStringArray;
  Time: Integer;
begin
  Buff := nil;
  TempArray := TStringList.Create;
  TempArray.LoadFromFile(filename);
  SetLength(BannedHWList, 1);
  j := 1;
  for i := 1 to (TempArray.Count) do
  begin
    Buff := SplitStr(TempArray[i - 1], ':', 4);
    if Trim(Buff[0]) = '' then
      Continue;

    Time := StrToIntDef(Buff[1], Low(Integer));

    if Time = Low(Integer) then
      Continue;

    SetLength(BannedHWList, j + 1);
    Inc(j, 1);
    BannedHWList[High(BannedHWList)].HW := Buff[0];
    BannedHWList[High(BannedHWList)].Time := Time;
    BannedHWList[High(BannedHWList)].Reason := Buff[2];
  end;
  TempArray.free;
end;

procedure SaveBannedListHW(filename: string);
var
  i: Integer;
  Buff: string;
  SaveFile: TextFile;
begin
  Buff := '';
  for i := 1 to High(BannedHWList) do
  begin
    if BannedHWList[i].HW <> '' then
      Buff := Buff + BannedHWList[i].HW + ':' + IntToStr(BannedHWList[i].Time) +
      ':' + BannedHWList[i].Reason + Chr(13) + Chr(10);
  end;
  AssignFile(SaveFile, filename);
  ReWrite(SaveFile);
  Write(SaveFile, Buff);
  CloseFile(SaveFile);
end;

procedure UpdateHWBanList;
var
  j: Byte;
begin
  for j := 1 to High(BannedHWList) do
    if (BannedHWList[j].HW <> '') then
    begin
      if BannedHWList[j].Time > 0 then
      begin
        Dec(BannedHWList[j].Time, 3600);
        if (BannedHWList[j].Time < 0) and
          not (BannedHWList[j].Time = PERMANENT) then
          BannedHWList[j].Time := 0;
      end;
      if (BannedHWList[j].Time = 0) and
        not (BannedHWList[j].Time = PERMANENT) then
      begin
        MainConsole.Console('Hardware ID ' + BannedHWList[j].HW +
          ' (' + BannedHWList[j].Reason + ') unbanned',
          CLIENT_MESSAGE_COLOR);
        DelBannedHW(BannedHWList[j].HW);
        SaveTxtLists;
      end;
    end;
end;

end.
