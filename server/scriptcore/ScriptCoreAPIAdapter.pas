unit ScriptCoreAPIAdapter;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
  Classes,
  PascalCompiler,
  PascalExec,
  Script,
  ScriptCore3Api,
  ScriptCoreInterface,
  SysUtils;

type

  TScriptCoreAPIAdapter = class(TScriptCore3API)
  private
    FAppOnIdleTimer: Longint;
    FDisabled: Boolean;
  public
    constructor Create(Script: TScript);
    procedure CompilerRegister(Compiler: TPascalCompiler); override;
    procedure RuntimeRegisterApi(Exec: TPascalExec); override;
    procedure RuntimeRegisterVariables(Exec: TPascalExec); override;
    procedure BeforeExecute(Exec: TPascalExec); override;

    // EVENTS
    procedure OnClockTick;

    function OnRequestGame(Ip: string; Port: Word; State: Byte;
      Forwarded: Boolean; Password: string): Integer;
    procedure OnJoinTeam(Id, Team, OldTeam: Byte; JoinGame: Boolean);
    procedure OnLeaveGame(Id: Byte; Kicked: Boolean);

    procedure OnBeforeMapChange(Map: string);
    procedure OnAfterMapChange(Map: string);

    procedure OnAdminConnect(Ip: string; Port: Word);
    procedure OnAdminDisconnect(Ip: string; Port: Word);
    procedure OnAdminMessage(Ip: string; Port: Word; Message: string);

    procedure OnFlagGrab(Id, TeamFlag: Byte; GrabbedInBase: Boolean);
    procedure OnFlagScore(Id, TeamFlag: Byte);
    procedure OnFlagReturn(Id, TeamFlag: Byte);

    procedure OnAfterPlayerRespawn(Id: Byte);
    function OnPlayerDamage(Victim, Shooter: Byte; Damage: Single;
      BulletID: Byte): Single;
    procedure OnPlayerKill(Killer, Victim, Weapon: Byte);
    procedure OnWeaponChange(Id, Primary, Secondary: Byte);

    function OnVoteMapStart(Id: Byte; Map: string): Boolean;
    function OnVoteKickStart(Id, Victim: Byte; Reason: string): Boolean;
    procedure OnVoteMap(Id: Byte; Map: string);
    procedure OnVoteKick(Id, Victim: Byte);

    procedure OnPlayerSpeak(Id: Byte; Text: string);
    function OnPlayerCommand(Id: Byte; Command: string): Boolean;
    function OnConsoleCommand(Ip: string; Port: Word; Command: string): Boolean;

    property AppOnIdleTimer: Longint read FAppOnIdleTimer;
    property Disabled: Boolean read FDisabled;
  end;

implementation

uses
  Calc,
  Constants,
  fpmasks,
  math,
  Net,
  NetworkServerFunctions,
  NetworkUtils,
  ScriptCore3,
  ScriptDispatcher,
  ServerHelper,
  Sprites,
  strutils,
  {$IFDEF RCON}
  Rcon,
  {$ENDIF}
  Server,
  Game,
  Util,
  Version,
  Weapons;

constructor TScriptCoreAPIAdapter.Create(Script: TScript);
begin
  inherited Create(Script);
  Self.FAppOnIdleTimer := 60;
  Self.FDisabled := False;
end;

procedure TScriptCoreAPIAdapter.CompilerRegister(Compiler: TPascalCompiler);
begin
  Compiler.AddType('TStringArray', 'array of string');

  Compiler.AddFunction('procedure PlaySound(Id: Byte; Name: string; X, Y: Single)');
  Compiler.AddFunction('function FormatFloat(A: string; B: extended): string');
  Compiler.AddFunction('function ArrayHigh(A: array of string): Integer');
  Compiler.AddFunction('procedure WriteLn(Data: string)');
  Compiler.AddFunction('function Exp(A: Extended): Extended');
  Compiler.AddFunction('function Random(A,B:Integer): Integer');
  Compiler.AddFunction('function CreateBullet(A, B, C, D, E:Single; F, G: Byte): Integer');
  Compiler.AddFunction('procedure BotChat(A: Byte; B: string)');
  Compiler.AddFunction('procedure GiveBonus(A, B: Byte)');
  Compiler.AddFunction('procedure ServerModifier(A: string; B: Variant)');
  Compiler.AddFunction(
    'function RayCast(A, B, C, D: Single; var E: Single; F: Single): Boolean');
  Compiler.AddFunction(
    'function RayCastEx(A, B, C, D: Single; var E: Single; F: Single; G, H, I: Boolean; J: Byte): Boolean');
  Compiler.AddFunction('procedure SetTeamScore(A: Byte; B: Integer)');
  Compiler.AddFunction('function MD5String(A: string): string');
  Compiler.AddFunction('function ArcTan(A: Extended): Extended');
  Compiler.AddFunction('function Ln(A: Extended): Extended');
  Compiler.AddFunction('function Log10(A: Extended): Extended');
  Compiler.AddFunction('function LogN(A, B: Extended): Extended');
  Compiler.AddFunction('procedure MovePlayer(A: Byte; X, Y: Single)');
  Compiler.AddFunction('function GetObjectStat(A: Byte; B: string): Variant');
  Compiler.AddFunction(
    'procedure ForwardClient(A: string; B: Integer; C: string; D: Integer; E: string)');
  Compiler.AddFunction('function CrossFunc(const A: array of Variant; B: string): Variant');
  Compiler.AddFunction('procedure ResetTarget(A: Byte)');
  Compiler.AddFunction('function GetKeyPress(Id: Byte; Key: string): Boolean');
  Compiler.AddFunction('function GetSpawnStat(A: Byte; B: string): Variant');
  Compiler.AddFunction('procedure SetSpawnStat(A: Byte; B: string; C: Variant)');
  Compiler.AddFunction('function ReadINI(A, B, C, D: string): string');
  Compiler.AddFunction('function RegExpMatch(A, B: string): Boolean');
  Compiler.AddFunction('function RegExpReplace(A, B, C: string; D: Boolean): string');
  Compiler.AddFunction('function RoundTo(A: Extended; B: Integer): Extended');
  Compiler.AddFunction('function FormatDate(A: string): string');
  Compiler.AddFunction('procedure WriteConsole(A: Byte; B: string; C: LongInt)');
  Compiler.AddFunction(
    'procedure DrawText(A: Byte; B: string; C: Integer; D: LongInt; E: Single; F, G: Integer)');
  Compiler.AddFunction(
    'procedure DrawTextEx(Id, Num: Byte; Text: String; Delay: Integer; Colour: Longint; Scale: Single; X, Y: Integer)');
  Compiler.AddFunction('function GetSystem: string');
  Compiler.AddFunction('function GetTickCount: Cardinal');
  Compiler.AddFunction('function RGB(R, G, B: Byte): LongInt');
  Compiler.AddFunction('function IDToName(A: Integer): string');
  Compiler.AddFunction('function NameToID(A: string): Integer');
  Compiler.AddFunction('function NameToHW(A: string): string');
  Compiler.AddFunction('function IDToIP(Id: Byte): string');
  Compiler.AddFunction('function IDToHW(Id: Byte): string');
  Compiler.AddFunction('function IPToID(A: string): Integer');
  Compiler.AddFunction('procedure TCPAdminPM(A, B: string)');
  Compiler.AddFunction('function WeaponNameByNum(A: Integer): string');
  Compiler.AddFunction('function RandomBot: string');
  Compiler.AddFunction('procedure KickPlayer(A: Byte)');
  Compiler.AddFunction('procedure StartVoteKick(A: Byte; B: string)');
  Compiler.AddFunction('procedure StartVoteMap(A, B: string)');
  Compiler.AddFunction('procedure BanPlayer(A: Byte; B: Integer)');
  Compiler.AddFunction('procedure BanPlayerReason(A: Byte; B: Integer; C: string)');
  Compiler.AddFunction('function CheckWeaponAllowed(A: Byte): Boolean');
  Compiler.AddFunction('function Command(A: string): Variant');
  Compiler.AddFunction('procedure StartServer');
  Compiler.AddFunction('function GetPID: Integer');
  Compiler.AddFunction('procedure Shutdown');
  Compiler.AddFunction('procedure UpdateGameStats');
  Compiler.AddFunction('procedure DoDamage(A: Byte; B: Integer)');
  Compiler.AddFunction('procedure DoDamageBy(A, B: Byte; C: Integer)');
  Compiler.AddFunction('procedure ForceWeapon(A, B, C, D: Byte)');
  Compiler.AddFunction('procedure ForceWeaponEx(A, B, C, D, E: Byte)');
  Compiler.AddFunction('procedure SetWeaponActive(A, B: Byte; C: Boolean)');
  Compiler.AddFunction('procedure SetScore(A: Byte; B: Integer)');
  Compiler.AddFunction('function Distance(A, B, C, D: Single): Single');
  Compiler.AddFunction('function SpawnObject(A, B: Single; D: Byte): Integer');
  Compiler.AddFunction('procedure KillObject(A: Integer)');
  Compiler.AddFunction('procedure GetPlayerXY(A: Byte; var X, Y: Single)');
  Compiler.AddFunction('function GetPlayerStat(A: Byte; B: string): Variant');
  Compiler.AddFunction('procedure GetFlagsXY(var A, B, C, D: Single)');
  Compiler.AddFunction('procedure GetFlagsSpawnXY(var A, B, C, D: Single)');
  Compiler.AddFunction('procedure SayToPlayer(A: Byte; B: string)');
  Compiler.AddFunction('procedure Sleep(A: Cardinal)');
  Compiler.AddFunction('function MaskCheck(const A: string; const B: string):Boolean');
  Compiler.AddFunction(
    'function Iif(const A: Boolean; const B: Variant; const C: Variant): Variant');
  Compiler.AddFunction('function GetPiece(const A, B: string; const C: Integer): string');
  Compiler.AddFunction('function ReadFile(A: string): string');
  Compiler.AddFunction('function WriteFile(A, B: string): Boolean');
  Compiler.AddFunction('function WriteLnFile(A: string; B: string): Boolean');
  Compiler.AddFunction('function FileExists(F: string): Boolean');
  Compiler.AddFunction('function ContainsString(const A, B: string): Boolean');
  Compiler.AddFunction(
    'function GetStringIndex(const A: string; const B: array of string): Integer');
  Compiler.AddFunction('function StrPos(const A, S: string): Integer');
  Compiler.AddFunction('function StrReplace(const A, B, C: string): string');
  //Compiler.AddFunction('function HTTPEncode(A: string): string');
  //Compiler.AddFunction('function HTTPDecode(A: string): string');
  Compiler.AddFunction('function shell_exec(A: string): Integer');
  //Compiler.AddFunction('function GetURL(A: string): string');

  // Variables
  Compiler.AddVariable('CoreVersion', 'string');
  Compiler.AddVariable('ScriptName', 'string');
  Compiler.AddVariable('SafeMode', 'Byte');
  Compiler.AddVariable('MaxPlayers', 'Byte');
  Compiler.AddVariable('NumPlayers', 'Byte');
  Compiler.AddVariable('NumBots', 'Byte');
  Compiler.AddVariable('CurrentMap', 'string');
  Compiler.AddVariable('NextMap', 'string');
  Compiler.AddVariable('TimeLimit', 'Integer');
  Compiler.AddVariable('TimeLeft', 'Integer');
  Compiler.AddVariable('ScoreLimit', 'Integer');
  Compiler.AddVariable('GameStyle', 'Byte');
  Compiler.AddVariable('Version', 'string');
  Compiler.AddVariable('ServerVersion', 'string');
  Compiler.AddVariable('ServerName', 'string');
  Compiler.AddVariable('ServerIP', 'string');
  Compiler.AddVariable('ServerPort', 'Integer');
  Compiler.AddVariable('DeathmatchPlayers', 'Byte');
  Compiler.AddVariable('Spectators', 'Byte');
  Compiler.AddVariable('AlphaPlayers', 'Byte');
  Compiler.AddVariable('BravoPlayers', 'Byte');
  Compiler.AddVariable('CharliePlayers', 'Byte');
  Compiler.AddVariable('DeltaPlayers', 'Byte');
  Compiler.AddVariable('AlphaScore', 'Byte');
  Compiler.AddVariable('BravoScore', 'Byte');
  Compiler.AddVariable('CharlieScore', 'Byte');
  Compiler.AddVariable('DeltaScore', 'Byte');
  Compiler.AddVariable('ReqPort', 'Word');

  Compiler.AddVariable('Paused', 'Boolean');
  Compiler.AddVariable('Password', 'string');

  Compiler.AddPtrVariable('DisableScript', 'Boolean');
  Compiler.AddPtrVariable('AppOnIdleTimer', 'LongWord');
  with Compiler.AddConstant('SCRIPT_NAME', 'String') do
  begin
    SetString(Self.FScript.Dir);
  end;
end;

procedure TScriptCoreAPIAdapter.RuntimeRegisterApi(Exec: TPascalExec);
begin
  Exec.AddFunction(@PlaySound, 'PlaySound');
  Exec.AddFunction(@FormatFloat, 'FormatFloat');
  Exec.AddFunction(@ScriptCoreInterface.SArrayHigh, 'ArrayHigh');
  Exec.AddFunction(@WriteLn, 'WriteLn');
  Exec.AddFunction(@MyExp, 'Exp');
  Exec.AddFunction(@SRand, 'Random');

  Exec.AddFunction(@SCreateBullet, 'CreateBullet');
  Exec.AddFunction(@SBotChat, 'BotChat');
  Exec.AddFunction(@SGiveBonus, 'GiveBonus');
  Exec.AddFunction(@ServerModifier, 'ServerModifier');

  Exec.AddFunction(@SRayCast, 'RayCast');
  Exec.AddFunction(@SRayCastEx, 'RayCastEx');
  Exec.AddFunction(@SetTeamScore, 'SetTeamScore');
  Exec.AddFunction(@MD5StringHelper, 'MD5String');
  Exec.AddFunction(@LogN, 'LogN');

  Exec.AddFunction(@MovePlayer, 'MovePlayer');
  Exec.AddFunction(@GetObjectStat, 'GetObjectStat');
  Exec.AddFunction(@ForwardClient, 'ForwardClient');
  Exec.AddFunction(@CrossFunc, 'CrossFunc');

  Exec.AddFunction(@ResetTarget, 'ResetTarget');
  Exec.AddFunction(@GetKeyPress, 'GetKeyPress');

  Exec.AddFunction(@GetSpawnStat, 'GetSpawnStat');
  Exec.AddFunction(@SetSpawnStat, 'SetSpawnStat');

  Exec.AddFunction(@ReadINI, 'ReadINI');
  Exec.AddFunction(@RegExpMatch, 'RegExpMatch');
  Exec.AddFunction(@RegExpReplace, 'RegExpReplace');

  Exec.AddFunction(@MyRoundTo, 'RoundTo');
  Exec.AddFunction(@MyDate, 'FormatDate');

  //Script.AddMethod(ScriptCore, @TPascalCore.ThreadFunc,
  //  'procedure ThreadFunc(Params: array of Variant; FuncName: string)');
  Exec.AddFunction(@WriteConsole, 'WriteConsole');
  Exec.AddFunction(@DrawText, 'DrawText');
  Exec.AddFunction(@DrawTextEx, 'DrawTextEx');
  Exec.AddFunction(@GetSystem, 'GetSystem');
  Exec.AddFunction(@SGetTickCount, 'GetTickCount');

  Exec.AddFunction(@SRGB, 'RGB');

  Exec.AddFunction(@IDtoName, 'IDToName');
  Exec.AddFunction(@NameToID, 'NameToID');
  Exec.AddFunction(@NameToHW, 'NameToHW');
  Exec.AddFunction(@IDToIP, 'IDToIP');
  Exec.AddFunction(@IDToHW, 'IDToHW');
  {$IFDEF RCON}
  Exec.AddFunction(@SendMessageToAdmin, 'TCPAdminPM');
  {$ENDIF}
  Exec.AddFunction(@SWeaponNameByNum, 'WeaponNameByNum');
  Exec.AddFunction(@RandomBot, 'RandomBot');
  Exec.AddFunction(@SKickPlayer, 'KickPlayer');
  Exec.AddFunction(@MyStartVoteKick, 'StartVoteKick');

  Exec.AddFunction(@MyStartVoteMap, 'StartVoteMap');
  Exec.AddFunction(@SBanPlayer, 'BanPlayer');
  Exec.AddFunction(@SBanPlayerReason, 'BanPlayerReason');

  Exec.AddFunction(@CheckWeaponNotAllowed, 'CheckWeaponAllowed');
  Exec.AddFunction(@SCommand, 'Command');

  Exec.AddFunction(@StartServer, 'StartServer');
  Exec.AddFunction(@GetPID, 'GetPID');
  Exec.AddFunction(@Shutdown, 'Shutdown');
  Exec.AddFunction(@UpdateGameStats, 'UpdateGameStats');
  Exec.AddFunction(@DoDamage, 'DoDamage');
  Exec.AddFunction(@DoDamageBy, 'DoDamageBy');

  Exec.AddFunction(@SForceWeapon, 'ForceWeapon');
  Exec.AddFunction(@SForceWeaponEx, 'ForceWeaponEx');
  Exec.AddFunction(@SetWeaponActive, 'SetWeaponActive');
  Exec.AddFunction(@SetScore, 'SetScore');
  Exec.AddFunction(@Distance, 'Distance');
  Exec.AddFunction(@SCreateThing, 'SpawnObject');
  Exec.AddFunction(@KillThing, 'KillObject');

  Exec.AddFunction(@GetPlayerXY, 'GetPlayerXY');
  Exec.AddFunction(@GetPlayerStat, 'GetPlayerStat');

  Exec.AddFunction(@GetFlagsXY, 'GetFlagsXY');
  Exec.AddFunction(@GetFlagsSpawnXY, 'GetFlagsSpawnXY');
  Exec.AddFunction(@SSendStringToPlayer, 'SayToPlayer');
  Exec.AddFunction(@SSleep, 'Sleep');
  // Script.AddFunction(@SetVariables, 'procedure UpdateVars');

  Exec.AddFunction(@MatchesMask, 'MaskCheck');
  Exec.AddFunction(@util.Iif, 'Iif');
  Exec.AddFunction(@MyGetPiece, 'GetPiece');

  Exec.AddFunction(@MyReadFile, 'ReadFile');
  Exec.AddFunction(@WriteFile, 'WriteFile');
  Exec.AddFunction(@AppendFile, 'WriteLnFile');
  Exec.AddFunction(@ExistsFile, 'FileExists');
  Exec.AddFunction(@AnsiContainsStr, 'ContainsString');
  Exec.AddFunction(@AnsiIndexStr, 'GetStringIndex');
  Exec.AddFunction(@AnsiPos, 'StrPos');
  Exec.AddFunction(@AnsiReplaceStr, 'StrReplace');
  //Exec.AddFunction(@HTTPEncode, 'HTTPEncode');
  //Exec.AddFunction(@HTTPDecode, 'HTTPDecode');

  // Safe Mode Functions
  Exec.AddFunction(@shell_exec, 'shell_exec');
  //Exec.AddFunction(@ScriptGetURL, 'GetURL');
end;

procedure TScriptCoreAPIAdapter.RuntimeRegisterVariables(Exec: TPascalExec);
begin
  Exec.SetPointerToData('AppOnIdleTimer', @Self.FAppOnIdleTimer,
    Exec.FindType(btU32));
  Exec.SetPointerToData('DisableScript', @Self.FDisabled,
    Exec.FindType(btU8));
end;

procedure TScriptCoreAPIAdapter.BeforeExecute(Exec: TPascalExec);
var
  I: Integer;
  TeamsCount: array[0..5] of Byte;
begin
  try
    for I := 0 to 5 do
      TeamsCount[I] := 0;

    for I := 1 to MAX_SPRITES do
      if (Sprite[I].Active) and (Sprite[I].Player.Team <= TEAM_SPECTATOR) then
        TeamsCount[Sprite[I].Player.Team] :=
          TeamsCount[Sprite[I].Player.Team] + 1;

    Exec.SetValue('CoreVersion', COREVERSION);
    Exec.SetValue('SafeMode', Integer(iif(ScrptDispatcher.SafeMode, 1, 0)));

    Exec.SetValue('DeathmatchPlayers', TeamsCount[0]);
    Exec.SetValue('AlphaPlayers', TeamsCount[1]);
    Exec.SetValue('BravoPlayers', TeamsCount[2]);
    Exec.SetValue('CharliePlayers', TeamsCount[3]);
    Exec.SetValue('DeltaPlayers', TeamsCount[4]);
    Exec.SetValue('Spectators', TeamsCount[5]);

    Exec.SetValue('AlphaScore', TeamScore[1]);
    Exec.SetValue('BravoScore', TeamScore[2]);
    Exec.SetValue('CharlieScore', TeamScore[3]);
    Exec.SetValue('DeltaScore', TeamScore[4]);

    Exec.SetValue('MaxPlayers', sv_maxplayers.Value);
    Exec.SetValue('NumPlayers', PlayersNum);
    Exec.SetValue('NumBots', BotsNum);

    Exec.SetValue('CurrentMap', Map.Name);
    Exec.SetValue('NextMap', CheckNextMap);
    Exec.SetValue('TimeLimit', sv_timelimit.Value div 60 div 60);
    Exec.SetValue('TimeLeft', TimeLimitCounter div 60);
    Exec.SetValue('ScoreLimit', sv_killlimit.Value);
    Exec.SetValue('GameStyle', Byte(sv_gamemode.Value));

    Exec.SetValue('ServerName', sv_hostname.Value);
    Exec.SetValue('Version', SOLDAT_VERSION);
    Exec.SetValue('ServerVersion', DEDVERSION);
    Exec.SetValue('ServerPort', net_port.Value);
    Exec.SetValue('ServerIP', ServerIP);
    // FScripts.Dir holds full path from soldatserver folder, so scripts/Name/,
    // not just Name, hence Copy(9, Length - 9), where 9 = Length('scripts/') + 1
    // and Max - 9 because we need to substract Length('scripts/')
    // and 1 to remove '/' at the end
    Exec.SetValue('ScriptName', Copy(Self.FScript.Dir, 9, Length(Self.FScript.Dir) - 9));
    Exec.SetValue('Password', sv_password.Value);
    Exec.SetValue('Paused', Integer(iif(MapChangeCounter = 999999999, 1, 0)));

  except
    // on E: Exception do
    // WriteLn(' [*] Exception raised on SetVariables(' + E.Message + ')');
  end;
end;

procedure TScriptCoreAPIAdapter.OnClockTick;
begin
  if not Self.Disabled and (Self.AppOnIdleTimer > 0) and
    (MainTickCounter mod Self.AppOnIdleTimer = 0) then
    Self.FScript.CallFunc([MainTickCounter], 'AppOnIdle', 0);
end;

function TScriptCoreAPIAdapter.OnRequestGame(Ip: string; Port: Word;
  State: Byte; Forwarded: Boolean; Password: string): Integer;
begin
  if Self.Disabled then
  begin
    TScriptCore3(Self.FScript).Exec.SetValue('ReqPort', Port);
    State := Self.FScript.CallFunc([Ip, State], 'OnRequestGame', State);
    State := Self.FScript.CallFunc([Ip, Port, State, Forwarded, Password],
      'OnRequestGameEx', State);
  end;
  Result := State;
end;

procedure TScriptCoreAPIAdapter.OnJoinTeam(Id, Team, OldTeam: Byte; JoinGame: Boolean);
{$push}{$warn 5024 off}
begin
  if Sprite[Id].Player.ControlMethod <> Net.HUMAN then
    Exit;
  if not Self.Disabled then begin
    if JoinGame then
      Self.FScript.CallFunc([Id, Team], 'OnJoinGame', 0);
    Self.FScript.CallFunc([Id, Team], 'OnJoinTeam', 0);
  end;
end;
{$pop}

procedure TScriptCoreAPIAdapter.OnLeaveGame(Id: Byte; Kicked: Boolean);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, Sprite[Id].Player.Team, Kicked], 'OnLeaveGame', 0);
end;

procedure TScriptCoreAPIAdapter.OnBeforeMapChange(Map: string);
{$push}{$warn 5024 off}
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([], 'OnGameEnd', 0);
end;
{$pop}

procedure TScriptCoreAPIAdapter.OnAfterMapChange(Map: string);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Map], 'OnMapChange', 0);
end;

procedure TScriptCoreAPIAdapter.OnAdminConnect(Ip: string; Port: Word);
{$push}{$warn 5024 off}
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Ip], 'OnAdminConnect', 0);
end;
{$pop}

procedure TScriptCoreAPIAdapter.OnAdminDisconnect(Ip: string; Port: Word);
{$push}{$warn 5024 off}
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Ip], 'OnAdminDisconnect', 0);
end;
{$pop}

procedure TScriptCoreAPIAdapter.OnAdminMessage(Ip: string; Port: Word; Message: string);
{$push}{$warn 5024 off}
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Ip, Message], 'OnAdminMessage', 0);
end;
{$pop}

procedure TScriptCoreAPIAdapter.OnFlagGrab(Id, TeamFlag: Byte; GrabbedInBase: Boolean);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, TeamFlag, GrabbedInBase], 'OnFlagGrab', 0);
end;

procedure TScriptCoreAPIAdapter.OnFlagScore(Id, TeamFlag: Byte);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, TeamFlag], 'OnFlagScore', 0);
end;

procedure TScriptCoreAPIAdapter.OnFlagReturn(Id, TeamFlag: Byte);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, TeamFlag], 'OnFlagReturn', 0);
end;

procedure TScriptCoreAPIAdapter.OnAfterPlayerRespawn(Id: Byte);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id], 'OnPlayerRespawn', 0);
end;

function TScriptCoreAPIAdapter.OnPlayerDamage(Victim, Shooter: Byte;
  Damage: Single; BulletID: Byte): Single;
begin
  if not Self.Disabled then
  begin
    Damage := Self.FScript.CallFunc([Victim, Shooter, Damage],
      'OnPlayerDamage', Damage);
    Damage := Self.FScript.CallFunc([Victim, Shooter, Damage, WeaponNumInternalToExternal(Bullet[BulletID].OwnerWeapon)],
      'OnPlayerDamageEx', Damage);
  end;
  Result := Damage;
end;

procedure TScriptCoreAPIAdapter.OnPlayerKill(Killer, Victim, Weapon: Byte);
begin
  if not Self.Disabled then
  begin
    if Killer = Victim then
      Weapon := 100;
    Self.FScript.CallFunc([Killer, Victim, WeaponNameByNum(Weapon)],
      'OnPlayerKill', 0);
    Self.FScript.CallFunc([Killer, Victim, WeaponNumInternalToExternal(Weapon)],
      'OnPlayerKillEx', 0);
  end;
end;

procedure TScriptCoreAPIAdapter.OnWeaponChange(Id, Primary, Secondary: Byte);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, WeaponNumInternalToExternal(Primary), WeaponNumInternalToExternal(Secondary)], 'OnWeaponChange', 0);
end;

function TScriptCoreAPIAdapter.OnVoteMapStart(Id: Byte; Map: string): Boolean;
begin
  Result := False;
  if not Self.Disabled then
    Result := Self.FScript.CallFunc([Id, Map], 'OnVoteMapStart', False);
end;

function TScriptCoreAPIAdapter.OnVoteKickStart(Id, Victim: Byte;
  Reason: string): Boolean;
begin
  Result := False;
  if not Self.Disabled then
    Result := Self.FScript.CallFunc([Id, Victim, Reason], 'OnVoteKickStart', False);
end;

procedure TScriptCoreAPIAdapter.OnVoteMap(Id: Byte; Map: string);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, Map], 'OnVoteMap', 0);
end;

procedure TScriptCoreAPIAdapter.OnVoteKick(Id, Victim: Byte);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, Victim], 'OnVoteKick', 0);
end;

procedure TScriptCoreAPIAdapter.OnPlayerSpeak(Id: Byte; Text: string);
begin
  if not Self.Disabled then
    Self.FScript.CallFunc([Id, Text], 'OnPlayerSpeak', 0);
end;

function TScriptCoreAPIAdapter.OnPlayerCommand(Id: Byte; Command: string): Boolean;
begin
  Result := False;
  if not Self.Disabled then
  begin
    if IsRemoteAdminIP(Sprite[Id].Player.IP) or
       IsAdminIP(Sprite[Id].Player.IP) then
      Result := Self.FScript.CallFunc([Id, Command], 'OnCommand', False);
    Result := Result or Self.FScript.CallFunc([Id, Command], 'OnPlayerCommand', False);
  end;
end;

function TScriptCoreAPIAdapter.OnConsoleCommand(Ip: string; Port: Word;
  Command: string): Boolean;
{$push}{$warn 5024 off}
begin
  Result := False;
  if not Self.Disabled then
    Result := Self.FScript.CallFunc([255, Command], 'OnCommand', False);
end;
{$pop}

end.
