{*******************************************************}
{                                                       }
{       ScriptCore3 unit for SOLDAT                     }
{                                                       }
{       Copyright (c) 2012 Tomasz Kolosowski            }
{                                                       }
{*******************************************************}

// TODO: Documentation
unit ScriptCore3;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
  Classes,
  IniFiles,
  PascalCompiler,
  PascalExec,
  Script,
  ScriptCore3Api,
  ScriptCoreAPIAdapter,
  ScriptCoreFunctions,
  ScriptMath,
  ScriptDateUtils,
  ScriptFileAPI,
  ScriptGame,
  ScriptMap,
  ScriptObject,
  ScriptBullet,
  ScriptPlayer,
  ScriptPlayers,
  ScriptSpawnPoint,
  ScriptTeam,
  ScriptMapsList,
  ScriptBanLists,
  ScriptUnit,
  ScriptGlobal,
  ScriptWeapon,
  SysUtils,
  Vector;

type

  TScriptCore3Conf = object
  private
    FSandboxLevel: Shortint;
    FAllowDlls: Boolean;
    FAllowIniEdit: Boolean;

    FSearchPaths: TStringList;
    FDefines: TStringList;
    FMainFileName: string;
  public
    constructor Create;
    destructor Destroy;
    procedure LoadConfig(INI: TMemIniFile;
      ConfigSectionName, SearchPathsSectionName, DefinesSectionName: string);
    property SandboxLevel: Shortint read FSandboxLevel;
    property AllowDlls: Boolean read FAllowDlls;
    property AllowIniEdit: Boolean read FAllowIniEdit;
    property SearchPaths: TStringList read FSearchPaths;
    property Defines: TStringList read FDefines;
    property MainFileName: string read FMainFileName;
  end;

  TScriptCore3 = class(TScript)
  private
    FConfig: TScriptCore3Conf;
    FExec: TPascalExec;
    FBytecode, FDebugSymbols: string;
    FApi: TList;
    FMainFileName: string;
    FLegacyMode: Boolean;

    FAdapter: TScriptCoreAPIAdapter;
    FGame: TScriptGameAPI;
    FPlayers: TScriptPlayersAPI;
    FUnit: TScriptUnitAPI;
    FMap: TScriptMapAPI;
    FDebug: Boolean;
    FGameMod: Boolean;
    FSpawnPoint: TScriptSpawnPointAPI;
    FCore: TScriptCore3API;
    FFile: TScriptFileAPI;

    FOnWeaponChangeNewPrimary: TScriptWeaponChange;
    FOnWeaponChangeNewSecondary: TScriptWeaponChange;

    procedure WriteInfo(Msg: string);
    procedure Deprecated(FnName: string; Msg: string = '');
    function Compile: Boolean;
    function GetByteCode: Boolean;
    procedure OnException(Sender: TPascalExec; ExError: TPSError;
      const ExParam: string; ExObject: TObject; ProcNo, Position: Cardinal);
    procedure SetHybridMode;
    function GetSandboxLevel: Shortint;
    function GetAllowIniEdit: Boolean;
    {$push}{$warn 3018 off} // Hide "Constructor should be public"
    constructor Create;
    {$pop}
  protected
    procedure HandleException(E: Exception);
  public
    destructor Destroy; override;
    function Prepare: Boolean; override;
    procedure Launch; override;
    function CallFunc(const Params: array of Variant; FuncName: string;
      DefaultReturn: Variant): Variant; override;
    function CallEvent(const Event;
      const Params: array of Variant): Variant; overload;
    // EVENTS
    procedure OnClockTick; override;
    function OnRequestGame(Ip, Hw: string; Port: Word; State: Byte;
      Forwarded: Boolean; Password: string): Integer; override;
    function OnBeforeJoinTeam(Id, Team, OldTeam: Byte): ShortInt; override;
    procedure OnJoinTeam(Id, Team, OldTeam: Byte; JoinGame: Boolean); override;
    procedure OnLeaveGame(Id: Byte; Kicked: Boolean); override;

    procedure OnBeforeMapChange(Map: string); override;
    procedure OnAfterMapChange(Map: string); override;

    procedure OnAdminConnect(Ip: string; Port: Word); override;
    procedure OnAdminDisconnect(Ip: string; Port: Word); override;
    procedure OnAdminMessage(Ip: string; Port: Word; Message: string); override;

    procedure OnFlagGrab(Id, TeamFlag: Byte; GrabbedInBase: Boolean); override;
    procedure OnFlagScore(Id, TeamFlag: Byte); override;
    procedure OnFlagReturn(Id, TeamFlag: Byte); override;
    procedure OnFlagDrop(Id, TeamFlag: Byte; Thrown: Boolean); override;

    procedure OnKitPickup(Id, KitId: Byte); override;

    function OnBeforePlayerRespawn(Id: Byte): TVector2; override;
    procedure OnAfterPlayerRespawn(Id: Byte); override;
    function OnPlayerDamage(Victim, Shooter: Byte; Damage: Single;
      BulletID: Byte): Single; override;
    procedure OnPlayerKill(Killer, Victim, BulletID: Byte); override;
    procedure OnWeaponChange(Id, Primary, Secondary,
      PrimaryAmmo, SecondaryAmmo: Byte); override;

    function OnVoteMapStart(Id: Byte; Map: string): Boolean; override;
    function OnVoteKickStart(Id, Victim: Byte; Reason: string): Boolean; override;
    procedure OnVoteMap(Id: Byte; Map: string); override;
    procedure OnVoteKick(Id, Victim: Byte); override;

    procedure OnPlayerSpeak(Id: Byte; Text: string); override;
    function OnPlayerCommand(Id: Byte; Command: string): Boolean; override;
    function OnConsoleCommand(Ip: string; Port: Word; Command: string): Boolean;
      override;

    property SandboxLevel: Shortint read GetSandboxLevel;
    property AllowIniEdit: Boolean read GetAllowIniEdit;
    property Debug: Boolean read FDebug;
    property GameMod: Boolean read FGameMod;
    property Exec: TPascalExec read FExec;
    property API: TList read FApi;
  end;

var
  GlobalConfig: TScriptCore3Conf;

function CheckFunction(Dir: string): TScriptCore3;

implementation

uses
  Net,
  NetworkUtils,
  Server,
  Game,
  PascalDebugger,
  ScriptDispatcher,
  ScriptExceptions,
  Variants;

const
  // I'd suggest to leave those constants here (instead of moving to Constants.pas), as they should be used only localy
  BYTECODEEXT = '.psb';
  DEBUGSYMBOLSEXT = '.psd';

function CheckFunction(Dir: string): TScriptCore3;
var
  IniFile: TMemIniFile;
  MainFile, Name: string;
  Version: Single;
begin
  Result := nil;
  IniFile := nil;
  if FileExists(Dir + '/config.ini') then
  begin
    try
      IniFile := TMemIniFile.Create(Dir + '/config.ini');
      if IniFile.SectionExists('Config') then
      begin
        Version := IniFile.ReadFloat('Config', 'Version', 0.1);
        if Version < 0.1 then
        begin
          ScrptDispatcher.WriteInfo('Unknown script version');
          Exit;
        end;
        Name := IniFile.ReadString('Config', 'Name', '');
        if Name = '' then
        begin
          ScrptDispatcher.WriteInfo('[Config] Name is required!');
          Exit;
        end
        else if Length(Name) > 20 then
        begin
          ScrptDispatcher.WriteInfo('Name can be only 20 characters long!');
          Exit;
        end;
        MainFile := IniFile.ReadString('Config', 'MainFile', 'main.pas');
        if not FileExists(Dir + '/' + MainFile) then
        begin
          ScrptDispatcher.WriteInfo('Script''s MainFile not found! (' +
            Dir + '/' + MainFile + ')');
          Exit;
        end;
        Result := TScriptCore3.Create;
        Result.FName := Name;
        Result.FConfig.LoadConfig(IniFile, 'Config', 'SearchPaths', 'Defines');
        if Result.FConfig.SandboxLevel < GlobalConfig.SandboxLevel then
        begin
          Result.WriteInfo('Script''s sandbox level denied by global config.');
          Result.Free;
          Result := nil;
          Exit;
        end;
        if Result.FConfig.AllowDlls and not GlobalConfig.AllowDlls then
        begin
          Result.WriteInfo('AllowDlls denied by global config.');
          Result.Free;
          Result := nil;
          Exit;
        end;

        Result.FGameMod := IniFile.ReadBool('Config', 'Gamemod', False);
        Result.FMainFileName := MainFile;
        Result.FDir := SetDirSeparators(Dir + '/');
        Result.FLegacyMode := IniFile.ReadBool('Config', 'Legacy', False);
        Result.FDebug := IniFile.ReadBool('Config', 'Debug', False);
        if Result.FLegacyMode then
          Result.SetHybridMode;
        Result.FConfig.Defines.AddStrings(GlobalConfig.Defines);
        Result.FConfig.SearchPaths.AddStrings(GlobalConfig.SearchPaths);
      end
      else
        ScrptDispatcher.WriteInfo('[' + Dir + '] CONFIG section not found');
    finally
      IniFile.Free;
    end;
  end;
end;

constructor TScriptCore3Conf.Create;
begin
  inherited;
  Self.FSearchPaths := TStringList.Create;
  Self.FDefines := TStringList.Create;
end;

destructor TScriptCore3Conf.Destroy;
begin
  inherited;
  Self.FSearchPaths.Free;
  Self.FDefines.Free;
end;

procedure TScriptCore3Conf.LoadConfig(INI: TMemIniFile;
  ConfigSectionName, SearchPathsSectionName, DefinesSectionName: string);
begin
  Self.FSandboxLevel := INI.ReadInteger(ConfigSectionName, 'Sandboxed', 2);
  Self.FAllowDlls := INI.ReadBool(ConfigSectionName, 'AllowDLLs', False);
  Self.FAllowIniEdit := INI.ReadBool(ConfigSectionName, 'AllowIniEdit', False);

  INI.ReadSectionRaw(SearchPathsSectionName, Self.FSearchPaths);
  Self.FSearchPaths.Insert(0, './');
  INI.ReadSectionRaw(DefinesSectionName, Self.FDefines);
end;

procedure TScriptCore3.OnException(Sender: TPascalExec; ExError: TPSError;
  const ExParam: string; ExObject: TObject; ProcNo, Position: Cardinal);
var
  UnitName, FunctionName: string;
  Func: TScriptFunction;
  Col, Row: Cardinal;
begin
  Col := 0;
  Row := 0;
  Func := TScriptFunction(Sender.GetProc(ProcNo));
  if ExObject <> nil then
    if (ExObject.ClassInfo = EScriptUnload.ClassInfo) or
       (ExObject.ClassInfo = EScriptRecompile.ClassInfo) then
       Exit;
  if Func <> nil then
    FunctionName := Func.ExportName;
  if Assigned(Self.FUnit.ScriptUnit.OnException) then
  begin
    try
      TPascalDebugger(Sender).GetPosition(UnitName, Col, Row, ProcNo, Position);
    except
    end;
    try
      Self.CallEvent(Self.FUnit.ScriptUnit.OnException,
        [ExError, Sender.GetErrorString2(ExError, ExParam), UnitName, FunctionName, Col, Row]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  end;
end;

procedure TScriptCore3.SetHybridMode;
begin
  Self.FAdapter := TScriptCoreAPIAdapter.Create(Self);
  Self.FApi.Insert(0, TScriptCoreAPIAdapter(Self.FAdapter));
end;

function TScriptCore3.GetSandboxLevel: Shortint;
begin
  Result := Self.FConfig.SandboxLevel;
end;

function TScriptCore3.GetAllowIniEdit: Boolean;
begin
  Result := Self.FConfig.AllowIniEdit;
end;

constructor TScriptCore3.Create;
begin
  inherited;
  Self.FConfig.Create;
  Self.FPlayers := TScriptPlayersAPI.Create(Self);
  Self.FGame := TScriptGameAPI.Create(Self);
  Self.FUnit := TScriptUnitAPI.Create(Self);
  Self.FMap := TScriptMapAPI.Create(Self);
  Self.FSpawnPoint := TScriptSpawnPointAPI.Create(Self);
  Self.FCore := TScriptCore3API.Create(Self);
  Self.FFile := TScriptFileAPI.Create(Self);

  // Workaround for OnWeaponChange: It needs 2 new objects,
  // which do not exist yet, when the method gets called.
  {$push}{$warn 4046 off}
  Self.FOnWeaponChangeNewPrimary := TScriptWeaponChange.Create;
  Self.FOnWeaponChangeNewSecondary := TScriptWeaponChange.Create;
  {$pop}

  Self.FApi := TList.Create;
  Self.FApi.Add(TScriptDateUtilsAPI.Create(Self));
  Self.FApi.Add(TScriptWeaponAPI.Create(Self));
  Self.FApi.Add(TScriptObjectAPI.Create(Self));
  Self.FApi.Add(TScriptBulletAPI.Create(Self));
  Self.FApi.Add(TScriptPlayerAPI.Create(Self));
  Self.FApi.Add(TScriptTeamAPI.Create(Self));
  Self.FApi.Add(TScriptSpawnPointAPI(Self.FSpawnPoint));
  Self.FApi.Add(TScriptFileAPI(Self.FFile));
  Self.FApi.Add(TScriptMapAPI(Self.FMap));
  // The order is important. TScriptPlayersAPI needs to be position 9
  // in the list. If you cannot keep it at position 9, then change the
  // Api number in ScriptGame.pas function RuntimeRegisterVariables, too.
  Self.FApi.Add(TScriptPlayersAPI(Self.FPlayers));
  Self.FApi.Add(TScriptMapsListAPI.Create(Self));
  Self.FApi.Add(TScriptBanListsAPI.Create(Self));
  Self.FApi.Add(TScriptGameAPI(Self.FGame));
  Self.FApi.Add(TScriptUnitAPI(Self.FUnit));
  Self.FApi.Add(TScriptGlobalAPI.Create(Self));
  Self.FApi.Add(TScriptMathAPI.Create(Self));
  Self.FApi.Add(TCoreFunctionsAPI.Create(Self));
end;

procedure TScriptCore3.HandleException(E: Exception);
var
  Message, UnitName: string;
  Col, Row: Cardinal;
  Debugger: TPascalDebugger;
  Func: TAbstractFunction;
  FunctionName: string;
  Error: TPascalError;
begin
  if E.ClassInfo = EScriptUnload.ClassInfo then
  begin
    ScrptDispatcher.UnregisterScript(Self);
  end
  else if E.ClassInfo = EScriptRecompile.ClassInfo then
  begin
    if EScriptRecompile(E).Force then
      Self.Compile;
    Self.Prepare;
    Self.Launch;
  end
  else
  begin
    try
      Func := Self.FExec.Exec.GetProcNo(Self.FExec.Exec.ExceptionProcNo);
      if Func is TScriptFunction then
        FunctionName := TScriptFunction(Func).ExportName
      else
        FunctionName := TExternalFunction(Func).Name;
      if Self.Debug then
      begin
        Debugger := TPascalDebugger(Self.FExec);
        Error := Debugger.LastError;
        Debugger.GetPosition(UnitName, Col, Row);
        if Assigned(Self.FUnit.ScriptUnit.OnUnhandledException) and
           Self.CallEvent(Self.FUnit.ScriptUnit.OnUnhandledException,
             [Error, E.Message, UnitName, FunctionName, Row, Col]) then
           Exit;
        Message := 'In unit ' + UnitName + '(' + IntToStr(Row) + ':' +
          IntToStr(Col) + ') [' + FunctionName + ']: ' +
            Debugger.GetErrorString(Error, E.Message, Debugger.Exec.ExceptionProcNo, Debugger.Exec.ExceptionPos);
      end
      else
      begin
        if Assigned(Self.FUnit.ScriptUnit.OnUnhandledException) and
          Self.CallEvent(Self.FUnit.ScriptUnit.OnUnhandledException,
            [Error, E.Message, '', FunctionName, 0, 0]) then
          Exit;
        Message := 'In function [' + FunctionName + ']: ' + Self.FExec.GetErrorString2(Error, E.Message);
      end;
    except
      Message := E.Message;
    end;
    Self.WriteInfo('Unhandled exception occured: ');
    Self.WriteInfo(Message);
    ScrptDispatcher.UnregisterScript(Self);
  end;
end;

destructor TScriptCore3.Destroy;
var
  I: Shortint;
begin
  inherited;
  if Self.FLegacyMode and (Self.FExec <> nil) then
    Self.CallFunc([], 'DeactivateServer', 0);
  Self.FExec.Free;
  for I := 0 to Self.FApi.Count - 1 do
    TObject(Self.FApi[i]).Free;
  Self.FApi.Free;

  // OnWeaponChange workaround
  FreeAndNil(Self.FOnWeaponChangeNewPrimary);
  FreeAndNil(Self.FOnWeaponChangeNewSecondary);

  Self.FConfig.Destroy;
end;

procedure TScriptCore3.WriteInfo(Msg: string);
begin
  ScrptDispatcher.WriteInfo('[' + Self.Name + '] ' + Msg);
end;

procedure TScriptCore3.Deprecated(FnName: string; Msg: string = '');
begin
  Self.WriteInfo('*DEPRECATED* Function '
    + FnName + ' is deprecated and will be removed in future version. ' + Msg);
end;

function TScriptCore3.Compile: Boolean;
var
  Compiler: TPascalCompiler;
  Messages: TStringList;
  I: Shortint;
  BytecodeFile: TFileStream;
begin
  Result := False;
  Self.WriteInfo('Compilation started');
  Compiler := TPascalCompiler.Create(Self.FDir, Self.FMainFileName);
  Compiler.Defines := Self.FConfig.FDefines;
  Compiler.Api := Self.FApi;
  if Self.FConfig.FAllowDlls then
    Compiler.SupportDLLs := True;
  for I := 0 to Self.FConfig.FSearchPaths.Count - 1 do
    Compiler.AddSearchPath(Self.FDir + Self.FConfig.FSearchPaths[I]);
  try
    Result := Compiler.Compile;
  except
    on E: Exception do
    begin
      Self.WriteInfo('[Error] Unknown error while trying to compile: ' +
        E.Message);
    end;
  end;
  Messages := Compiler.GetMessages();
  for I := 0 to Messages.Count - 1 do
    Self.WriteInfo(Messages[I]);
  if not Result then
  begin
    Self.WriteInfo('Compilation failed');
    Exit;
  end;
  if Self.Debug then
  begin
    Self.FDebugSymbols := Compiler.Debugcode;
    BytecodeFile := TFileStream.Create(Self.FDir +
      ChangeFileExt(Self.FMainFileName, DEBUGSYMBOLSEXT), fmCreate);
    BytecodeFile.WriteAnsiString(Self.FDebugSymbols);
    BytecodeFile.Free;
  end;
  Self.FBytecode := Compiler.Bytecode;
  BytecodeFile := TFileStream.Create(Self.FDir +
    ChangeFileExt(Self.FMainFileName, BYTECODEEXT), fmCreate);
  BytecodeFile.WriteAnsiString(Self.FBytecode);
  BytecodeFile.Free;
  Self.WriteInfo('Compilation complete');
end;

function TScriptCore3.GetByteCode: Boolean;
var
  SearchRec: TSearchRec;
  BytecodeTime: Integer;
  BytecodeFileName: string;
  FileStream: TFileStream;
  I: Shortint;
begin
  BytecodeFileName := Self.FDir + ChangeFileExt(Self.FMainFileName, BYTECODEEXT);
  if not FileExists(BytecodeFileName) then
  begin
    Result := Self.Compile;
  end
  else
  begin
    FindFirst(BytecodeFileName, 0, SearchRec);
    BytecodeTime := SearchRec.Time;
    FindClose(SearchRec);
    FindFirst(ParamStr(0), 0, SearchRec);
    FindClose(SearchRec);
    if SearchRec.Time > BytecodeTime then
    begin
      Result := Self.Compile;
      Exit;
    end;
    FindFirst('server.ini', 0, SearchRec);
    FindClose(SearchRec);
    if SearchRec.Time > BytecodeTime then
    begin
      Result := Self.Compile;
      Exit;
    end;
    for I := 0 to Self.FConfig.FSearchPaths.Count - 1 do
      if DirectoryExists(IncludeTrailingPathDelimiter(Self.FDir +
        Self.FConfig.FSearchPaths[I])) then
      begin
        FindFirst(Self.FDir + Self.FConfig.FSearchPaths[I] + '/*', faAnyFile, SearchRec);
        repeat
          if SearchRec.Time > BytecodeTime then
          begin
            Result := Self.Compile;
            FindClose(SearchRec);
            Exit;
          end;
        until FindNext(SearchRec) <> 0;
      end;
    FindClose(SearchRec);
    // if arrived here then file exists and does not require recompiling
    FileStream := TFileStream.Create(BytecodeFileName, fmOpenRead);
    Self.FBytecode := FileStream.ReadAnsiString;
    FileStream.Free;
    // debug file also should exist at this point
    if Self.FDebug then
    begin
      FileStream := TFileStream.Create(ChangeFileExt(BytecodeFileName,
        DEBUGSYMBOLSEXT), fmOpenRead);
      Self.FDebugSymbols := FileStream.ReadAnsiString;
      FileStream.Free;
    end;
    Result := True;
  end;
end;

function TScriptCore3.Prepare: Boolean;
begin
  Result := False;
  if not Self.GetByteCode then
    Exit;  // any error message should be displayed in GetByteCode();
  Self.FExec.Free;  // just in case
  Self.WriteInfo('Loading bytecode');
  try
    if Self.Debug then
      Self.FExec := TPascalDebugger.Create
    else
      Self.FExec := TPascalExec.Create;
    Self.FExec.OnException := Self.OnException;
    if Self.FConfig.FAllowDlls then
      Self.FExec.AddDllSupport;
    Self.FExec.Api := Self.FApi;
    Self.FExec.Bytecode := Self.FBytecode;
    // Debug symbols must be loaded after bytecode
    if Self.Debug then
      TPascalDebugger(Self.FExec).DebugSymbols := Self.FDebugSymbols;
    Result := True;
  except
    on e: TUnableToLoadException do
    begin
      Self.WriteInfo('[Error] ' + e.Message);
      exit;
    end;
    on e: Exception do
    begin
      Self.HandleException(e);
      exit;
    end;
  end;
  Self.WriteInfo('Bytecode loaded');
end;

procedure TScriptCore3.Launch;
begin
  try
    Self.Lock.Acquire;
    try
      Self.FExec.Execute;
      if Self.FLegacyMode then
        Self.CallFunc([], 'ActivateServer', 0);
    except
      on e: Exception do
      begin
        Self.HandleException(e);
      end;
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.CallFunc(const Params: array of Variant;
  FuncName: string; DefaultReturn: Variant): Variant;
begin
  Result := DefaultReturn;
  try
    Result := Self.FExec.CallFunction(FuncName, Params);
  except
    on e: TProcNotFoundException do
      Exit;
    on e: Exception do
      Self.HandleException(e);
  end;
end;

function TScriptCore3.CallEvent(const Event;
  const Params: array of Variant): Variant;
begin
  try
    Result := Self.FExec.CallEvent(Event, Params);
  except
    on e: TProcNotFoundException do
      Exit;
    on e: Exception do
      Self.HandleException(e);
  end;
end;

procedure TScriptCore3.OnClockTick;
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnClockTick;
      if Assigned(Self.FGame.Game.OnClockTick) and
        (Self.FGame.Game.TickThreshold <> 0) and (MainTickCounter mod
        Self.FGame.Game.TickThreshold = 0) then
        Self.CallEvent(Self.FGame.Game.OnClockTick, [MainTickCounter]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnRequestGame(Ip, Hw: string; Port: Word; State: Byte;
  Forwarded: Boolean; Password: string): Integer;
begin
  Result := State;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
      begin
        Result := Self.FAdapter.OnRequestGame(Ip, Port, State, Forwarded, Password);
        State := Result;
      end;
      if Assigned(Self.FGame.Game.OnRequest) then
        Result := Self.CallEvent(Self.FGame.Game.OnRequest, [Ip, Hw, Port, State, Forwarded, Password]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnBeforeJoinTeam(Id, Team, OldTeam: Byte): ShortInt;
var
  PlayerObj: TScriptActivePlayer;
  OldTeamObj: TScriptTeam;
begin
  Result := Team;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FGame.Game.Teams[Team].OnBeforeJoin) then
      begin
        if (Id < 1) or (Id > MAX_PLAYERS) then
          PlayerObj := nil
        else
          PlayerObj := Self.FPlayers.Players[Id];
        if OldTeam = 255 then
          OldTeamObj := nil
        else
          OldTeamObj := Self.FGame.Game.Teams[OldTeam];
        Result := Self.CallEvent(Self.FGame.Game.Teams[Team].OnBeforeJoin,
          [PtrUInt(PlayerObj), PtrUInt(Self.FGame.Game.Teams[Team]), PtrUInt(OldTeamObj)]);
      end;
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnJoinTeam(Id, Team, OldTeam: Byte; JoinGame: Boolean);
var
  I, J: Byte;
begin
  try
    Self.Lock.Acquire;
    try
      if not JoinGame then
      begin
        Self.FGame.Game.Teams[Team].AddPlayer(Self.FPlayers.Players[Id]);
        Self.FGame.Game.Teams[OldTeam].RemovePlayer(
          Self.FPlayers.Players[Id]);
        if Assigned(Self.FGame.Game.Teams[OldTeam].OnLeave) then
          Self.CallEvent(Self.FGame.Game.Teams[OldTeam].OnLeave,
            [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FGame.Game.Teams[OldTeam]), False]);
      end
      else
      begin
        // Workaround, since a player can join probably the game twice.
        for I := 0 to 5 do
          if Self.FGame.Game.Teams[I].Count > 0 then
            for J := 0 to Self.FGame.Game.Teams[I].Count - 1 do
              if Self.FGame.Game.Teams[I].Player[J].Sprite.Num = Id then
              begin
                Self.FGame.Game.Teams[I].RemovePlayer(
                  Self.FGame.Game.Teams[I].Player[J]);
                Break;
              end;
        Self.FGame.Game.Teams[Team].AddPlayer(Self.FPlayers.Players[Id]);
        if Self.FPlayers.Players.Active.IndexOf(Self.FPlayers.Players[ID]) = -1 then
          Self.FPlayers.Players.Active.Add(Self.FPlayers.Players[Id]);

        if Assigned(Self.FGame.Game.OnJoin) then
          Self.CallEvent(Self.FGame.Game.OnJoin,
            [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FGame.Game.Teams[Team])]);
      end;

      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnJoinTeam(Id, Team, OldTeam, JoinGame);
      if Assigned(Self.FGame.Game.Teams[Team].OnJoin) then
        Self.CallEvent(Self.FGame.Game.Teams[Team].OnJoin,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FGame.Game.Teams[Team])]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnLeaveGame(Id: Byte; Kicked: Boolean);
var
  Team: Byte;
begin
  try
    Self.Lock.Acquire;
    try
      Team := Self.FPlayers.Players[Id].Team;
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnLeaveGame(Id, Kicked);
      if Assigned(Self.FGame.Game.OnLeave) then
        Self.CallEvent(Self.FGame.Game.OnLeave,
          [PtrUInt(Self.FPlayers.Players[Id]), Kicked]);
      if Assigned(Self.FGame.Game.Teams[Team].OnLeave) then
        Self.CallEvent(Self.FGame.Game.Teams[Team].OnLeave,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FGame.Game.Teams[Team]), Kicked]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.FGame.Game.Teams[Team].RemovePlayer(Self.FPlayers.Players[Id]);
    Self.FPlayers.Players.Active.Remove(Self.FPlayers.Players[Id]);
    Self.Lock.Release;
  end;
end;


procedure TScriptCore3.OnBeforeMapChange(Map: string);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnBeforeMapChange(Map);
      if Assigned(Self.FMap.Map.OnBeforeMapChange) then
        Self.CallEvent(Self.FMap.Map.OnBeforeMapChange, [Map]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnAfterMapChange(Map: string);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnAfterMapChange(Map);
      if Assigned(Self.FMap.Map.OnAfterMapChange) then
        Self.CallEvent(Self.FMap.Map.OnAfterMapChange, [Map]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;


procedure TScriptCore3.OnAdminConnect(Ip: string; Port: Word);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnAdminConnect(Ip, Port);
      if Assigned(Self.FGame.Game.OnAdminConnect) then
        Self.CallEvent(Self.FGame.Game.OnAdminConnect, [Ip, Port]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnAdminDisconnect(Ip: string; Port: Word);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnAdminDisconnect(Ip, Port);
      if Assigned(Self.FGame.Game.OnAdminDisconnect) then
        Self.CallEvent(Self.FGame.Game.OnAdminDisconnect, [Ip, Port]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnAdminMessage(Ip: string; Port: Word; Message: string);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnAdminMessage(Ip, Port, Message);
      if Assigned(Self.FGame.Game.OnTCPMessage) then
        Self.CallEvent(Self.FGame.Game.OnTCPMessage, [Ip, Port, Message]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;


procedure TScriptCore3.OnFlagGrab(Id, TeamFlag: Byte; GrabbedInBase: Boolean);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnFlagGrab(Id, TeamFlag, GrabbedInBase);
      if Assigned(Self.FPlayers.Players[Id].OnFlagGrab) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnFlagGrab,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FMap.Map.GetFlag(TeamFlag)), TeamFlag, GrabbedInBase]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnFlagScore(Id, TeamFlag: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnFlagScore(Id, TeamFlag);
      if Assigned(Self.FPlayers.Players[Id].OnFlagScore) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnFlagScore,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FMap.Map.GetFlag(TeamFlag)), TeamFlag]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnFlagReturn(Id, TeamFlag: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnFlagReturn(Id, TeamFlag);
      if Assigned(Self.FPlayers.Players[Id].OnFlagReturn) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnFlagReturn,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FMap.Map.GetFlag(TeamFlag)), TeamFlag]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnFlagDrop(Id, TeamFlag: Byte; Thrown: Boolean);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FPlayers.Players[Id].OnFlagDrop) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnFlagDrop,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FMap.Map.GetFlag(TeamFlag)), TeamFlag, Thrown]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnKitPickup(Id, KitId: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FPlayers.Players[Id].OnKitPickup) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnKitPickup,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FMap.Map.Objects[KitId])]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnBeforePlayerRespawn(Id: Byte): TVector2;
var
  VariantResult: Variant;
begin
  try
    Self.Lock.Acquire;
    Result := SpriteParts.Pos[Id];
    try
      VariantResult := PtrUInt(@Result);
      if Assigned(Self.FPlayers.Players[Id].OnBeforeRespawn) then
        VariantResult := Self.CallEvent(Self.FPlayers.Players[Id].OnBeforeRespawn,
          [PtrUInt(Self.FPlayers.Players[Id])]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnAfterPlayerRespawn(Id: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnAfterPlayerRespawn(Id);
      if Assigned(Self.FPlayers.Players[Id].OnAfterRespawn) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnAfterRespawn,
          [PtrUInt(Self.FPlayers.Players[Id])]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnPlayerDamage(Victim, Shooter: Byte; Damage: Single;
  BulletID: Byte): Single;
begin
  Result := Damage;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
      begin
        Result := Self.FAdapter.OnPlayerDamage(Victim, Shooter, Damage, BulletID);
        Damage := Result;
      end;
      if Assigned(Self.FPlayers.Players[Shooter].OnDamage) then
        Result := Self.CallEvent(Self.FPlayers.Players[Shooter].OnDamage,
          [PtrUInt(Self.FPlayers.Players[Shooter]), PtrUInt(Self.FPlayers.Players[Victim]), Damage, BulletID]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnPlayerKill(Killer, Victim, BulletID: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnPlayerKill(Killer, Victim, Bullet[BulletID].OwnerWeapon);
      if Assigned(Self.FPlayers.Players[Killer].OnKill) then
        Self.CallEvent(Self.FPlayers.Players[Killer].OnKill,
          [PtrUInt(Self.FPlayers.Players[Killer]), PtrUInt(Self.FPlayers.Players[Victim]), BulletID]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnWeaponChange(Id, Primary, Secondary,
  PrimaryAmmo, SecondaryAmmo: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnWeaponChange(Id, Primary, Secondary);
      if Assigned(Self.FPlayers.Players[Id].OnWeaponChange) then
      begin
        // OnWeaponChange workaround
        Self.FOnWeaponChangeNewPrimary.SetGun(Primary, PrimaryAmmo);
        Self.FOnWeaponChangeNewSecondary.SetGun(Secondary, SecondaryAmmo);
        {$push}{$warn 4040 off}
        Self.CallEvent(Self.FPlayers.Players[Id].OnWeaponChange,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(TScriptPlayerWeapon(Self.FOnWeaponChangeNewPrimary)), PtrUInt(TScriptPlayerWeapon(Self.FOnWeaponChangeNewSecondary))]);
        {$pop}
      end;
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;


function TScriptCore3.OnVoteMapStart(Id: Byte; Map: string): Boolean;
begin
  Result := False;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Result := Self.FAdapter.OnVoteMapStart(Id, Map);
      if Assigned(Self.FPlayers.Players[Id].OnVoteMapStart) then
        Result := Result or Self.CallEvent(Self.FPlayers.Players[Id].OnVoteMapStart,
          [PtrUInt(Self.FPlayers.Players[Id]), Map]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnVoteKickStart(Id, Victim: Byte; Reason: string): Boolean;
begin
  Result := False;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Result := Self.FAdapter.OnVoteKickStart(Id, Victim, Reason);
      // ID may be 255 if it's a votekick started by server cheat checks.
      // FIXME: this means that server triggered votekicks won't be announced to scripts.
      if (Id <> 255) and Assigned(Self.FPlayers.Players[Id].OnVoteKickStart) then
        Result := Result or Self.CallEvent(Self.FPlayers.Players[Id].OnVoteKickStart,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FPlayers.Players[Victim]), Reason]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnVoteMap(Id: Byte; Map: string);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnVoteMap(Id, Map);
      if Assigned(Self.FPlayers.Players[Id].OnVoteMap) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnVoteMap,
          [PtrUInt(Self.FPlayers.Players[Id]), Map]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnVoteKick(Id, Victim: Byte);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnVoteKick(Id, Victim);
      if Assigned(Self.FPlayers.Players[Id].OnVoteKick) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnVoteKick,
          [PtrUInt(Self.FPlayers.Players[Id]), PtrUInt(Self.FPlayers.Players[Victim])]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

procedure TScriptCore3.OnPlayerSpeak(Id: Byte; Text: string);
begin
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Self.FAdapter.OnPlayerSpeak(Id, Text);
      if Assigned(Self.FPlayers.Players[Id].OnSpeak) then
        Self.CallEvent(Self.FPlayers.Players[Id].OnSpeak,
          [PtrUInt(Self.FPlayers.Players[Id]), Text]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnPlayerCommand(Id: Byte; Command: string): Boolean;
begin
  Result := False;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Result := Self.FAdapter.OnPlayerCommand(Id, Command);
      if Assigned(Self.FPlayers.Players[Id].OnCommand) then
        Result := Result or Self.CallEvent(Self.FPlayers.Players[Id].OnCommand,
          [PtrUInt(Self.FPlayers.Players[Id]), Command]);
      if Assigned(Self.FGame.Game.OnAdminCommand) then
        if IsRemoteAdminIP(Self.FPlayers.Players[Id].IP) or
           IsAdminIP(Self.FPlayers.Players[Id].IP) then
          Result := Result or
            Self.CallEvent(Self.FGame.Game.OnAdminCommand,
              [PtrUInt(Self.FPlayers.Players[Id]), Command]);
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

function TScriptCore3.OnConsoleCommand(Ip: string; Port: Word; Command: string): Boolean;
begin
  Result := False;
  try
    Self.Lock.Acquire;
    try
      if Assigned(Self.FAdapter) then
        Result := Self.FAdapter.OnConsoleCommand(Ip, Port, Command);
      if Assigned(Self.FGame.Game.OnTCPCommand) then
      begin
        Self.Deprecated('Game.OnTCPCommand', 'Use OnAdminCommand instead (Player = nil)');
        Result := Self.CallEvent(Self.FGame.Game.OnTCPCommand, [Ip, Port, Command]) or Result;
      end;
      if Assigned(Self.FGame.Game.OnAdminCommand) then
        Result := Self.CallEvent(Self.FGame.Game.OnAdminCommand,
          [PtrUInt(nil), Command]) or Result;
    except
      on e: Exception do
        Self.HandleException(e);
    end;
  finally
    Self.Lock.Release;
  end;
end;

initialization
  GlobalConfig.Create;

finalization
  GlobalConfig.Destroy;

end.
