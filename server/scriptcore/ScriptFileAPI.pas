{*******************************************************}
{                                                       }
{       ScriptFileAPI unit for SOLDAT                   }
{                                                       }
{       Copyright (c) 2013 Tomasz Kolosowski            }
{                                                       }
{*******************************************************}

// TODO: Documentation
unit ScriptFileAPI;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
  Classes,
  IniFiles,
  PascalCompiler,
  PascalExec,
  RegExpr,
  Script,
  ScriptCore3Api,
  ScriptExceptions,
  SysUtils,
  Server,
  uPSC_classes,
  uPSR_classes;

type
  TScriptFileAPI = class;

  TMyIniFile = class(TMemIniFile)
  private
    FAPI: TScriptFileAPI;
  public
    constructor Create(Path: string; API: TScriptFileAPI); overload;
    procedure Rename(const AFileName: string; Reload: Boolean);
  end;

  TMyStringList = class(TStringList)
  private
    FAPI: TScriptFileAPI;
    FOnChange: TNotifyEvent;
    FOnChanging: TNotifyEvent;
    procedure MyOnChange(Sender: TObject);
    procedure MyOnChanging(Sender: TObject);
  public
    constructor Create(API: TScriptFileAPI);
    procedure LoadFromFile(const FileName: string); override;
    procedure SaveToFile(const FileName: string); override;
  end;

  TMyMemoryStream = class(TMemoryStream)
  private
    FAPI: TScriptFileAPI;
  public
    constructor Create(API: TScriptFileAPI);
    procedure LoadFromFile(const FileName: string);
    procedure SaveToFile(const FileName: string);
  end;

  TScriptFile = class(TObject)
  private
    FAPI: TScriptFileAPI;
  public
    constructor Create(API: TScriptFileAPI);
    function CheckAccess(const FilePath: string): Boolean;
    function CreateFileStream(): TMyMemoryStream;
    function CreateFileStreamFromFile(const Path: string): TMyMemoryStream;
    function CreateStringList(): TMyStringList;
    function CreateStringListFromFile(const Path: string): TMyStringList;
    function CreateINI(const Path: string): TMyIniFile;
    function Exists(const Path: string): Boolean;
    function Copy(const Source, Destination: string): Boolean;
    function Move(const Source, Destination: string): Boolean;
    function Delete(const Path: string): Boolean;
  end;

  // TODO: Get rid of TPowerCoreAPI and make such object for each api class
  // ... some day
  TScriptFileAPI = class(TScriptCore3API)
  private
    FFile: TScriptFile;
    function GetSandboxLevel: Byte;
    function GetAllowIniEdit: Boolean;
    function GetDataFolder: string;
  public
    constructor Create(Script: TScript);
    destructor Destroy; override;
    function CheckAccess(var FilePath: string): Boolean;
    procedure CompilerRegister(Compiler: TPascalCompiler); override;
    procedure RuntimeRegisterApi(Exec: TPascalExec); override;
    procedure RuntimeRegisterVariables(Exec: TPascalExec); override;
    property SandboxLevel: Byte read GetSandboxLevel;
    property AllowIniEdit: Boolean read GetAllowIniEdit;
    property DataFolder: string read GetDataFolder;
  end;

implementation

uses
  ScriptCore3;

// Workaround for Kylix
// TODO: Move to Kylix.pas Compatibility Unit
function CopyFile(Source, Destination: String; FailIfExists: Boolean): Boolean;
const
  MAX_BUFFER_SIZE = $10000;
var
  SourceFile, DestFile: TFileStream;
  Buffer: array[0..MAX_BUFFER_SIZE - 1] of Byte;
  NumRead: Integer;
begin
  Result := False;
  Buffer[0] := 0;
  SourceFile := TFileStream.Create(Source, fmOpenRead or fmShareDenyNone);
  try
    if FileExists(Destination) then
    begin
      if FailIfExists then
        Exit;

      DestFile := TFileStream.Create(Destination, fmOpenReadWrite or fmShareDenyWrite);
    end else
    begin
      DestFile := TFileStream.Create(Destination, fmCreate);
    end;

    try
      DestFile.Size := SourceFile.Size;  // presize file for speedup
      DestFile.Position := 0;
      SourceFile.Position := 0;

      NumRead := SourceFile.Read(Buffer[0], MAX_BUFFER_SIZE);
      while NumRead > 0 do
      begin
        DestFile.Write(Buffer[0], NumRead);
        NumRead := SourceFile.Read(Buffer[0], MAX_BUFFER_SIZE);
      end;

    finally
      DestFile.Free;
    end;
  finally
    SourceFile.Free;
  end;
  Result := True;
end;

constructor TMyIniFile.Create(Path: string; API: TScriptFileAPI);
begin
  inherited Create(Path);
  Self.FAPI := API;
end;

procedure TMyIniFile.Rename(const AFileName: string; Reload: Boolean);
var
  Path: string;
begin
  Path := AFileName;
  if not Self.FAPI.CheckAccess(Path) then
    raise EAccessDenied.Create('Path is out of sandbox');
  inherited Rename(Path, Reload);
end;

constructor TMyStringList.Create(API: TScriptFileAPI);
begin
  inherited Create;
  Self.FAPI := API;
  Self.OnChange := Self.MyOnChange;
  Self.OnChanging := Self.MyOnChanging;
end;

procedure TMyStringList.MyOnChange(Sender: TObject);
begin
  if Assigned(Self.FOnChange) then
    Self.FAPI.CallEvent(FOnChange, [PtrUInt(Sender)]);
end;

procedure TMyStringList.MyOnChanging(Sender: TObject);
begin
  if Assigned(Self.FOnChanging) then
    Self.FAPI.CallEvent(FOnChanging, [PtrUInt(Sender)]);
end;

procedure TMyStringList.LoadFromFile(const FileName: string);
var
  Path: string;
begin
  Path := FileName;
  if not Self.FAPI.CheckAccess(Path) then
    raise EAccessDenied.Create('Path is out of sandbox');
  inherited LoadFromFile(Path);
end;

procedure TMyStringList.SaveToFile(const FileName: string);
var
  Path: string;
begin
  Path := FileName;
  if not Self.FAPI.CheckAccess(Path) then
    raise EAccessDenied.Create('Path is out of sandbox');
  inherited SaveToFile(Path);
end;

constructor TMyMemoryStream.Create(API: TScriptFileAPI);
begin
  inherited Create;
  Self.FAPI := API;
end;

procedure TMyMemoryStream.LoadFromFile(const FileName: string);
var
  Path: string;
begin
  Path := FileName;
  if not Self.FAPI.CheckAccess(Path) then
    raise EAccessDenied.Create('Path is out of sandbox');
  inherited LoadFromFile(Path);
end;

procedure TMyMemoryStream.SaveToFile(const FileName: string);
var
  Path: string;
begin
  Path := FileName;
  if not Self.FAPI.CheckAccess(Path) then
    raise EAccessDenied.Create('Path is out of sandbox');
  inherited SaveToFile(Path);
end;

constructor TScriptFile.Create(API: TScriptFileAPI);
begin
  Self.FAPI := API;
end;

function TScriptFile.CheckAccess(const FilePath: string): Boolean;
var
  Path: string;
begin
  Path := FilePath;
  Result := Self.FAPI.CheckAccess(Path);
end;

function TScriptFile.CreateFileStream(): TMyMemoryStream;
begin
  Result := TMyMemoryStream.Create(Self.FAPI);
end;

function TScriptFile.CreateFileStreamFromFile(const Path: string): TMyMemoryStream;
var
  NormalizedPath: string;
begin
  NormalizedPath := Path;
  if not Self.FAPI.CheckAccess(NormalizedPath) then
    raise EAccessDenied.Create('Path is out of sandbox');
  Result := Self.CreateFileStream();
  Result.LoadFromFile(NormalizedPath);
end;

function TScriptFile.CreateStringList(): TMyStringList;
begin
  Result := TMyStringList.Create(Self.FAPI);
end;

function TScriptFile.CreateStringListFromFile(const Path: string): TMyStringList;
var
  NormalizedPath: string;
begin
  NormalizedPath := Path;
  if not Self.FAPI.CheckAccess(NormalizedPath) then
    raise EAccessDenied.Create('Path is out of sandbox');
  Result := Self.CreateStringList();
  Result.LoadFromFile(NormalizedPath);
end;

function TScriptFile.CreateINI(const Path: string): TMyIniFile;
var
  NormalizedPath: string;
begin
  NormalizedPath := Path;
  if not Self.FAPI.CheckAccess(NormalizedPath) then
    raise EAccessDenied.Create('Path is out of sandbox');
  Result := TMyIniFile.Create(NormalizedPath, Self.FAPI);
end;

function TScriptFile.Exists(const Path: string): Boolean;
var
  NormalizedPath: string;
begin
  NormalizedPath := Path;
  if not Self.FAPI.CheckAccess(NormalizedPath) then
    raise EAccessDenied.Create('Path is out of sandbox');
  Result := FileExists(NormalizedPath);
end;

function TScriptFile.Copy(const Source, Destination: string): Boolean;
var
  NormalizedSource, NormalizedDestination: string;
begin
  NormalizedSource := Source;
  NormalizedDestination := Destination;
  if not Self.FAPI.CheckAccess(NormalizedSource) then
    raise EAccessDenied.Create('Source is out of sandbox');
  if not Self.FAPI.CheckAccess(NormalizedDestination) then
    raise EAccessDenied.Create('Destination is out of sandbox');
  Result := CopyFile(PAnsiChar(NormalizedSource), PAnsiChar(NormalizedDestination), False);
end;

function TScriptFile.Move(const Source, Destination: string): Boolean;
var
  NormalizedSource, NormalizedDestination: string;
begin
  NormalizedSource := Source;
  NormalizedDestination := Destination;
  if not Self.FAPI.CheckAccess(NormalizedSource) then
    raise EAccessDenied.Create('Source is out of sandbox');
  if not Self.FAPI.CheckAccess(NormalizedDestination) then
    raise EAccessDenied.Create('Destination is out of sandbox');
  Result := RenameFile(NormalizedSource, NormalizedDestination);
end;

function TScriptFile.Delete(const Path: string): Boolean;
var
  NormalizedPath: string;
begin
  NormalizedPath := Path;
  if not Self.FAPI.CheckAccess(NormalizedPath) then
    raise EAccessDenied.Create('Path is out of sandbox');
  Result := DeleteFile(PAnsiChar(NormalizedPath));
end;

function TScriptFileAPI.GetSandboxLevel: Byte;
begin
  Result := TScriptCore3(Self.FScript).SandboxLevel;
end;

function TScriptFileAPI.GetAllowIniEdit: Boolean;
begin
  Result := TScriptCore3(Self.FScript).AllowIniEdit;
end;

function TScriptFileAPI.GetDataFolder: string;
begin
  Result := SetDirSeparators(UserDirectory + Self.FScript.Dir + 'data/');
end;

constructor TScriptFileAPI.Create(Script: TScript);
begin
  inherited Create(Script);
  Self.FFile := TScriptFile.Create(Self);
end;

destructor TScriptFileAPI.Destroy;
begin
  Self.FFile.Free;
end;


function TScriptFileAPI.CheckAccess(var FilePath: string): Boolean;
var
  TempPath: string = '';
begin
  // Resolve file path
  case FilePath[1] of
    {$IFDEF UNIX}
    '/': FilePath := ExpandFileName(FilePath);
    {$ENDIF}
    '~': FilePath := ExpandFileName(Self.DataFolder +
        Copy(FilePath, 3, Length(FilePath)));
    else
    begin
      {$IFDEF MSWINDOWS}
      if (FilePath[1] in ['A'..'Z'])
          and ((Copy(FilePath, 2, 2) = ':\')
          or (Copy(FilePath, 2, 2) = ':/')) then
        FilePath := ExpandFileName(FilePath)
      else
      {$ENDIF}
      FilePath := ExpandFileName(UserDirectory + FilePath);
    end;
  end;

  //Check permissions
  case Self.SandboxLevel of
    // Resolving of non-sandbox (possibly absolute) paths is done on purpose
    // to normalize slashes for further functions (expand function does it).
    // Though since they don't fall into scope of permission check...
    0: Result := True;
    // Level 1 sandbox, restrict to soldatserver's folder
    1:
    begin
      Result := UserDirectory = Copy(FilePath, 1, Length(UserDirectory));
      // Prevent from accessing server.ini and config.ini files,
      // as it could be used to escalate script's privlages
      if Result and not Self.AllowIniEdit then
      begin
        TempPath := Copy(FilePath, Length(UserDirectory) + 1,
          Length(FilePath) - Length(UserDirectory));
        Result := (TempPath <> 'server.ini') and (TempPath <> 'soldat.ini');
      end;

      // TODO: Maybe think about something lighter than regexp
      if Result then
        Result := not ExecRegExpr('scripts(\\|/)\w+(\\|/)config.ini', TempPath);
    end;
      // Level 2 sandbox, restrict to script's data folder (script_folder/data)
    else
    begin
      Result := Self.DataFolder = Copy(FilePath, 1, Length(Self.DataFolder));
    end;
  end;

  // Since some API functions allow to show the path (the normalized one),
  // relativise it to hide soldatserver's folder absolute path
  if Result then
    FilePath := ExtractRelativepath(UserDirectory, FilePath);
end;

// INI

procedure FileNameReadHelper(Self: TMyIniFile; var Result: string);
begin
  Result := Self.FileName;
end;

procedure CaseSensitiveReadHelper(Self: TMyIniFile; var Result: Boolean);
begin
  Result := ifoCaseSensitive in Self.Options;
end;

procedure CaseSensitiveWriteHelper(Self: TMyIniFile; const Result: Boolean);
begin
  if Result then
    Self.Options := Self.Options + [ifoCaseSensitive]
  else
    Self.Options := Self.Options - [ifoCaseSensitive]
end;

procedure StripQuotesReadHelper(Self: TMyIniFile; var Result: Boolean);
begin
  Result := ifoStripQuotes in Self.Options;
end;

procedure StripQuotesWriteHelper(Self: TMyIniFile; const Result: Boolean);
begin
  if Result then
    Self.Options := Self.Options + [ifoStripQuotes]
  else
    Self.Options := Self.Options - [ifoStripQuotes]
end;


procedure CacheUpdatesReadHelper(Self: TMyIniFile; var Result: Boolean);
begin
  Result := Self.CacheUpdates;
end;

procedure CacheUpdatesWriteHelper(Self: TMyIniFile; const Result: Boolean);
begin
  Self.CacheUpdates := Result;
end;

// Stream

procedure PositionReadHelper(Self: TMyMemoryStream; var Result: Int64);
begin
  Result := Self.Position;
end;

procedure PositionWriteHelper(Self: TMyMemoryStream; const Result: Int64);
begin
  Self.Position := Result;
end;

procedure SizeReadHelper(Self: TMyMemoryStream; var Result: Int64);
begin
  Result := Self.Size;
end;

procedure SizeWriteHelper(Self: TMyMemoryStream; const Result: Int64);
begin
  Self.Size := Result;
end;

procedure DataStringReadHelper(Self: TStringStream; var Result: string);
begin
  Result := Self.DataString;
end;

//String list

procedure CountReadHelper(Self: TMyStringList; var Result: Integer);
begin
  Result := Self.Count;
end;

procedure TextReadHelper(Self: TMyStringList; var Result: string);
begin
  Result := Self.Text;
end;

procedure TextWriteHelper(Self: TMyStringList; const Result: string);
begin
  Self.Text := Result;
end;

procedure CommaTextReadHelper(Self: TMyStringList; var Result: string);
begin
  Result := Self.CommaText;
end;

procedure CommaTextWriteHelper(Self: TMyStringList; const Result: string);
begin
  Self.CommaText := Result;
end;

procedure StringsReadHelper(Self: TMyStringList; var Result: string;
  const Num: Integer);
begin
  Result := Self.Strings[Num];
end;

procedure StringsWriteHelper(Self: TMyStringList; const Result: string;
  const Num: Integer);
begin
  Self.Strings[Num] := Result;
end;

procedure ObjectsReadHelper(Self: TMyStringList; var Result: TObject;
  const Num: Integer);
begin
  Result := Self.Objects[Num];
end;

procedure ObjectsWriteHelper(Self: TMyStringList; const Result: TObject;
  const Num: Integer);
begin
  Self.Objects[Num] := Result;
end;

procedure NamesReadHelper(Self: TMyStringList; var Result: string; const Num: Integer);
begin
  Result := Self.Names[Num];
end;

procedure ValuesReadHelper(Self: TMyStringList; var Result: string; const Key: string);
begin
  Result := Self.Values[Key];
end;

procedure ValuesWriteHelper(Self: TMyStringList; const Result: string;
  const Key: string);
begin
  Self.Values[Key] := Result;
end;

procedure DuplicatesReadHelper(Self: TMyStringList; var Result: TDuplicates);
begin
  Result := Self.Duplicates;
end;

procedure DuplicatesWriteHelper(Self: TMyStringList; const Result: TDuplicates);
begin
  Self.Duplicates := Result;
end;

procedure SortedReadHelper(Self: TMyStringList; var Result: Boolean);
begin
  Result := Self.Sorted;
end;

procedure SortedWriteHelper(Self: TMyStringList; const Result: Boolean);
begin
  Self.Sorted := Result;
end;

procedure OnChangeReadHelper(Self: TMyStringList; var Result: TNotifyEvent);
begin
  Result := Self.FOnChange;
end;

procedure OnChangeWriteHelper(Self: TMyStringList; const Result: TNotifyEvent);
begin
  Self.FOnChange := Result;
end;

procedure OnChangingReadHelper(Self: TMyStringList; var Result: TNotifyEvent);
begin
  Result := Self.FOnChanging;
end;

procedure OnChangingWriteHelper(Self: TMyStringList; const Result: TNotifyEvent);
begin
  Self.FOnChanging := Result;
end;


procedure TScriptFileAPI.CompilerRegister(Compiler: TPascalCompiler);
var
  FileAPI, StringList, Stream, Strings: TPascalCompiletimeClass;
begin
  SIRegister_Classes_TypesAndConsts(Compiler.Compiler);

  // TODO: move methods belonging to TStrings out of TStringList
  Strings := Compiler.AddClass(nil, 'TStrings');

  StringList := Compiler.AddClass(Strings, 'TStringList');
  Compiler.AddType('TNotifyEvent', 'procedure (Sender: TObject)');
  Compiler.AddType('TDuplicates', '(dupIgnore, dupAccept, dupError)');
  Compiler.AddType('TStringListSortCompare',
    'function(List: TStringList; Index1, Index2: Integer): Integer');

  with Compiler.AddConstant('soFromBeginning', 'Integer') do
  begin
    SetInt(1);
  end;

  with Compiler.AddConstant('soFromCurrent', 'Integer') do
  begin
    SetInt(2);
  end;

  with Compiler.AddConstant('soFromEnd', 'Integer') do
  begin
    SetInt(3);
  end;
  with StringList do
  begin
    RegisterMethod('procedure Free');
    RegisterMethod('function GetNamePath: string');
    RegisterMethod('function Add(S: string): Integer');
    RegisterMethod('procedure Append(S: string)');
    RegisterMethod('procedure AddStrings(Strings: TStrings)');
    RegisterMethod('procedure Clear');
    RegisterMethod('procedure Delete(Index: Integer)');
    RegisterMethod('function IndexOf(const S: string): Integer');
    RegisterMethod('procedure Insert(Index: Integer; S: string)');
    RegisterProperty('Count', 'Integer', iptR);
    RegisterProperty('Text', 'String', iptRW);
    RegisterProperty('CommaText', 'String', iptRW);
    RegisterMethod('procedure LoadFromFile(FileName: string)');
    RegisterMethod('procedure SaveToFile(FileName: string)');
    RegisterProperty('Strings', 'String Integer', iptRW);
    SetDefaultPropery('Strings');
    RegisterProperty('Objects', 'TObject Integer', iptRW);
    RegisterMethod('procedure BeginUpdate');
    RegisterMethod('procedure EndUpdate');
    RegisterMethod('function Equals(Strings: TStrings): Boolean');
    RegisterMethod('procedure Exchange(Index1, Index2: Integer)');
    RegisterMethod('function IndexOfName(Name: string): Integer');
    RegisterMethod('procedure LoadFromStream(Stream: TStream)');
    RegisterMethod('procedure Move(CurIndex, NewIndex: Integer)');
    RegisterMethod('procedure SaveToStream(Stream: TStream)');
    RegisterMethod('procedure SetText(Text: PChar)');
    RegisterProperty('Names', 'String Integer', iptR);
    RegisterProperty('Values', 'String String', iptRW);
    RegisterMethod('function AddObject(S:String;AObject:TObject):integer');
    RegisterMethod('function GetText:PChar');
    RegisterMethod('function IndexofObject(AObject:tObject):Integer');
    RegisterMethod('procedure InsertObject(Index:Integer;S:String;AObject:TObject)');
    RegisterMethod('function Find(S:String;var Index:Integer):Boolean');
    RegisterMethod('procedure Sort');
    RegisterProperty('Duplicates', 'TDuplicates', iptRW);
    RegisterProperty('Sorted', 'Boolean', iptRW);
    RegisterProperty('OnChange', 'TNotifyEvent', iptRW);
    RegisterProperty('OnChanging', 'TNotifyEvent', iptRW);
  end;

  with Compiler.AddClass(nil, 'TIniFile') do
  begin
    RegisterMethod('procedure Free');
    RegisterMethod('function SectionExists(const Section: string): Boolean');
    RegisterMethod('function ReadString(const Section, Ident, Default: string): string');
    RegisterMethod('procedure WriteString(const Section, Ident, Value: String)');
    RegisterMethod('function ReadInteger(const Section, Ident: string; Default: Longint): Longint');
    RegisterMethod('procedure WriteInteger(const Section, Ident: string; Value: Longint)');
    RegisterMethod('function ReadBool(const Section, Ident: string; Default: Boolean): Boolean');
    RegisterMethod('procedure WriteBool(const Section, Ident: string; Value: Boolean)');
    RegisterMethod('function ReadDate(const Section, Ident: string; Default: TDateTime): TDateTime');
    RegisterMethod(
      'function ReadDateTime(const Section, Ident: string; Default: TDateTime): TDateTime');
    RegisterMethod('function ReadFloat(const Section, Ident: string; Default: Double): Double');
    RegisterMethod('function ReadTime(const Section, Ident: string; Default: TDateTime): TDateTime');
    RegisterMethod('function ReadBinaryStream(const Section, Name: string; Value: TStream): Integer');
    RegisterMethod('procedure WriteDate(const Section, Ident: string; Value: TDateTime)');
    RegisterMethod('procedure WriteDateTime(const Section, Ident: string; Value: TDateTime)');
    RegisterMethod('procedure WriteFloat(const Section, Ident: string; Value: Double)');
    RegisterMethod('procedure WriteTime(const Section, Ident: string; Value: TDateTime)');
    RegisterMethod('procedure WriteBinaryStream(const Section, Name: string; Value: TStream)');
    RegisterMethod('procedure ReadSection(const Section: string; Strings: TStrings);');
    RegisterMethod('procedure ReadSections(Strings: TStrings)');
    RegisterMethod('procedure ReadSectionRaw(const Section: string; Strings: TStrings)');
    RegisterMethod('procedure ReadSectionValues(const Section: string; Strings: TStrings)');
    RegisterMethod('procedure EraseSection(const Section: string)');
    RegisterMethod('procedure DeleteKey(const Section, Ident: String)');
    RegisterMethod('procedure UpdateFile');
    RegisterMethod('function ValueExists(const Section, Ident: string): Boolean');
    RegisterMethod('procedure Clear');
    RegisterMethod('procedure GetStrings(List: TStrings)');
    RegisterMethod('procedure Rename(const AFileName: string; Reload: Boolean)');
    RegisterMethod('procedure SetStrings(List: TStrings)');
    RegisterProperty('FileName', 'string', iptR);
    RegisterProperty('CaseSensitive', 'Boolean', iptRW);
    RegisterProperty('StripQuotes', 'Boolean', iptRW);
    RegisterProperty('CacheUpdates', 'Boolean', iptRW);
  end;

  Stream := Compiler.AddClass(nil, 'TStream');
  with Stream do
  begin
    IsAbstract := True;
    RegisterMethod('procedure Free');
    RegisterMethod('function Read(var Buffer:string;Count:LongInt):LongInt');
    RegisterMethod('function Write(const Buffer:string;Count:LongInt):LongInt');
    RegisterMethod('function Seek(Offset:LongInt;Origin:Word):LongInt');
    RegisterMethod('procedure ReadBuffer(Buffer:string;Count:LongInt)');
    RegisterMethod('procedure WriteBuffer(Buffer:string;Count:LongInt)');
    RegisterMethod('function CopyFrom(Source:TStream;Count:Int64):LongInt');
    RegisterProperty('Position', 'Int64', iptRW);
    RegisterProperty('Size', 'Int64', iptRW);
  end;

  with Compiler.AddClass(Stream, 'TFileStream') do
  begin
    RegisterMethod('procedure Clear');
    RegisterMethod('procedure LoadFromStream(Stream:TStream)');
    RegisterMethod('procedure LoadFromFile(FileName:string)');
    RegisterMethod('procedure SaveToStream(Stream:TStream)');
    RegisterMethod('procedure SaveToFile(FileName:string)');
    RegisterMethod('procedure SetSize(NewSize:LongInt)');
  end;

  with Compiler.AddClass(Stream, 'TStringStream') do
  begin
    RegisterMethod('constructor Create(const AString: string)');
    RegisterMethod('function Read(var Buffer: string; Count: Longint): Longint');
    RegisterMethod('function ReadString(Count: Longint): string');
    RegisterMethod('function Seek(Offset: Longint; Origin: Word): Longint');
    RegisterMethod('function Write(const Buffer: string; Count: Longint): Longint');
    RegisterMethod('procedure WriteString(const AString: string)');
    RegisterProperty('DataString', 'string', iptR);
  end;

  FileAPI := Compiler.AddClass(nil, 'TFile');
  with FileAPI do
  begin
    RegisterMethod('function CheckAccess(const FilePath: string): Boolean');
    RegisterMethod('function CreateFileStream(): TFileStream');
    RegisterMethod('function CreateFileStreamFromFile(const Path: string): TFileStream');
    RegisterMethod('function CreateStringList(): TStringList');
    RegisterMethod('function CreateStringListFromFile(const Path: string): TStringList');
    RegisterMethod('function CreateINI(const Path: string): TIniFile');
    RegisterMethod('function Exists(const Source: string): Boolean');
    RegisterMethod('function Copy(const Source, Destination: string): Boolean');
    RegisterMethod('function Move(const Source, Destination: string): Boolean');
    RegisterMethod('function Delete(const Source: string): Boolean');
  end;
  Compiler.AddPtrVariable('File', FileAPI.aType);
  SIRegisterTBITS(Compiler.Compiler);
  SIRegisterTPARSER(Compiler.Compiler);
end;

procedure TScriptFileAPI.RuntimeRegisterApi(Exec: TPascalExec);
begin
  RIRegisterTBITS(Exec.ClassImporter);
  RIRegisterTPARSER(Exec.ClassImporter);

  with Exec.AddClass(TMyIniFile, 'TIniFile') do
  begin
    RegisterMethod(@TMyIniFile.Free, 'Free');
    RegisterMethod(@TMyIniFile.SectionExists, 'SectionExists');
    RegisterMethod(@TMyIniFile.ReadString, 'ReadString');
    RegisterMethod(@TMyIniFile.WriteString, 'WriteString');
    RegisterMethod(@TMyIniFile.ReadInteger, 'ReadInteger');
    RegisterMethod(@TMyIniFile.WriteInteger, 'WriteInteger');
    RegisterMethod(@TMyIniFile.ReadBool, 'ReadBool');
    RegisterMethod(@TMyIniFile.WriteBool, 'WriteBool');
    RegisterMethod(@TMyIniFile.ReadDate, 'ReadDate');
    RegisterMethod(@TMyIniFile.ReadDateTime, 'ReadDateTime');
    RegisterMethod(@TMyIniFile.ReadFloat, 'ReadFloat');
    RegisterMethod(@TMyIniFile.ReadTime, 'ReadTime');
    RegisterMethod(@TMyIniFile.ReadBinaryStream, 'ReadBinaryStream');
    RegisterMethod(@TMyIniFile.WriteDate, 'WriteDate');
    RegisterMethod(@TMyIniFile.WriteDateTime, 'WriteDateTime');
    RegisterMethod(@TMyIniFile.WriteFloat, 'WriteFloat');
    RegisterMethod(@TMyIniFile.WriteTime, 'WriteTime');
    RegisterMethod(@TMyIniFile.WriteBinaryStream, 'WriteBinaryStream');
    RegisterMethod(@TMyIniFile.ReadSection, 'ReadSection');
    RegisterMethod(@TMyIniFile.ReadSections, 'ReadSections');
    RegisterMethod(@TMyIniFile.ReadSectionRaw, 'ReadSectionRaw');
    RegisterMethod(@TMyIniFile.ReadSectionValues, 'ReadSectionValues');
    RegisterMethod(@TMyIniFile.EraseSection, 'EraseSection');
    RegisterMethod(@TMyIniFile.DeleteKey, 'DeleteKey');
    RegisterMethod(@TMyIniFile.UpdateFile, 'UpdateFile');
    RegisterMethod(@TMyIniFile.ValueExists, 'ValueExists');
    RegisterMethod(@TMyIniFile.Clear, 'Clear');
    RegisterMethod(@TMyIniFile.GetStrings, 'GetStrings');
    RegisterMethod(@TMyIniFile.Rename, 'Rename');
    RegisterMethod(@TMyIniFile.SetStrings, 'SetStrings');
    RegisterPropertyHelper(@FileNameReadHelper, nil, 'FileName');
    RegisterPropertyHelper(@CaseSensitiveReadHelper, @CaseSensitiveWriteHelper,
      'CaseSensitive');
    RegisterPropertyHelper(@StripQuotesReadHelper, @StripQuotesWriteHelper,
      'StripQuotes');
    RegisterPropertyHelper(@CacheUpdatesReadHelper, @CacheUpdatesWriteHelper,
      'CacheUpdates');
  end;

  with Exec.AddClass(TMyStringList, 'TStringList') do
  begin
    RegisterMethod(@TMyStringList.Free, 'Free');
    RegisterMethod(@TMyStringList.GetNamePath, 'GetNamePath');
    RegisterMethod(@TMyStringList.Add, 'Add');
    RegisterMethod(@TMyStringList.Append, 'Append');
    RegisterMethod(@TMyStringList.AddStrings, 'AddStrings');
    RegisterMethod(@TMyStringList.Clear, 'Clear');
    RegisterMethod(@TMyStringList.Delete, 'Delete');
    RegisterMethod(@TMyStringList.IndexOf, 'IndexOf');
    RegisterMethod(@TMyStringList.Insert, 'Insert');
    RegisterMethod(@TMyStringList.LoadFromFile, 'LoadFromFile');
    RegisterMethod(@TMyStringList.SaveToFile, 'SaveToFile');
    RegisterMethod(@TMyStringList.BeginUpdate, 'BeginUpdate');
    RegisterMethod(@TMyStringList.EndUpdate, 'EndUpdate');
    RegisterMethod(@TMyStringList.Equals, 'Equals');
    RegisterMethod(@TMyStringList.Exchange, 'Exchange');
    RegisterMethod(@TMyStringList.IndexOfName, 'IndexOfName');
    RegisterMethod(@TMyStringList.LoadFromStream, 'LoadFromStream');
    RegisterMethod(@TMyStringList.Move, 'Move');
    RegisterMethod(@TMyStringList.SaveToStream, 'SaveToStream');
    RegisterMethod(@TMyStringList.SetText, 'SetText');
    RegisterMethod(@TMyStringList.AddObject, 'AddObject');
    RegisterMethod(@TMyStringList.GetText, 'GetText');
    RegisterMethod(@TMyStringList.IndexofObject, 'IndexofObject');
    RegisterMethod(@TMyStringList.InsertObject, 'InsertObject');
    RegisterMethod(@TMyStringList.Find, 'Find');
    RegisterMethod(@TMyStringList.Sort, 'Sort');
    RegisterPropertyHelper(@StringsReadHelper, @StringsWriteHelper, 'Strings');
    RegisterPropertyHelper(@ObjectsReadHelper, @ObjectsWriteHelper, 'Objects');
    RegisterPropertyHelper(@NamesReadHelper, nil, 'Names');
    RegisterPropertyHelper(@ValuesReadHelper, @ValuesWriteHelper, 'Values');
    RegisterPropertyHelper(@CountReadHelper, nil, 'Count');
    RegisterPropertyHelper(@TextReadHelper, @TextWriteHelper, 'Text');
    RegisterPropertyHelper(@CommaTextReadHelper, @CommaTextWriteHelper,
      'CommaText');
    RegisterPropertyHelper(@DuplicatesReadHelper, @DuplicatesWriteHelper,
      'Duplicates');
    RegisterPropertyHelper(@SortedReadHelper, @SortedWriteHelper, 'Sorted');
    RegisterEventPropertyHelper(@OnChangeReadHelper, @OnChangeWriteHelper,
      'OnChange');
    RegisterEventPropertyHelper(@OnChangingReadHelper, @OnChangingWriteHelper,
      'OnChanging');

  end;

  with Exec.AddClass(TStream) do
  begin
    RegisterMethod(@TStream.Free, 'Free');
    RegisterMethod(@TStream.Read, 'Read');
    RegisterMethod(@TStream.Write, 'Write');
    RegisterMethod(@TStream.Seek, 'Seek');
    RegisterMethod(@TStream.ReadBuffer, 'ReadBuffer');
    RegisterMethod(@TStream.WriteBuffer, 'WriteBuffer');
    RegisterMethod(@TStream.CopyFrom, 'CopyFrom');
    RegisterPropertyHelper(@PositionReadHelper, @PositionWriteHelper,
      'Position');
    RegisterPropertyHelper(@SizeReadHelper, @SizeWriteHelper, 'Size');
  end;

  with Exec.AddClass(TMyMemoryStream, 'TFileStream') do
  begin
    RegisterMethod(@TMyMemoryStream.Clear, 'Clear');
    RegisterMethod(@TMyMemoryStream.LoadFromStream, 'LoadFromStream');
    RegisterMethod(@TMyMemoryStream.LoadFromFile, 'LoadFromFile');
    RegisterMethod(@TMyMemoryStream.SaveToStream, 'SaveToStream');
    RegisterMethod(@TMyMemoryStream.SaveToFile, 'SaveToFile');
    RegisterMethod(@TMyMemoryStream.SetSize, 'SetSize');
  end;

  with Exec.AddClass(TStringStream) do
  begin
    RegisterConstructor(@TStringStream.Create, 'Create');
    RegisterMethod(@TStringStream.Read, 'Read');
    RegisterMethod(@TStringStream.ReadString, 'ReadString');
    RegisterMethod(@TStringStream.Seek, 'Seek');
    RegisterMethod(@TStringStream.Write, 'Write');
    RegisterMethod(@TStringStream.WriteString, 'WriteString');
    RegisterPropertyHelper(@DataStringReadHelper, nil, 'DataString');
  end;

  with Exec.AddClass(TScriptFile, 'TFile') do
  begin
    RegisterMethod(@TScriptFile.CheckAccess, 'CheckAccess');
    RegisterMethod(@TScriptFile.CreateFileStream, 'CreateFileStream');
    RegisterMethod(@TScriptFile.CreateFileStreamFromFile, 'CreateFileStreamFromFile');
    RegisterMethod(@TScriptFile.CreateStringList, 'CreateStringList');
    RegisterMethod(@TScriptFile.CreateStringListFromFile, 'CreateStringListFromFile');
    RegisterMethod(@TScriptFile.CreateINI, 'CreateINI');
    RegisterMethod(@TScriptFile.Copy, 'Copy');
    RegisterMethod(@TScriptFile.Exists, 'Exists');
    RegisterMethod(@TScriptFile.Move, 'Move');
    RegisterMethod(@TScriptFile.Delete, 'Delete');
  end;
end;

procedure TScriptFileAPI.RuntimeRegisterVariables(Exec: TPascalExec);
begin
  // auto create data directory if not exist
  if not FileExists(UserDirectory + self.FScript.Dir + 'data') then
    CreateDir(UserDirectory + self.FScript.Dir + 'data');
  Exec.SetPointerToData('File', @Self.FFile, Exec.FindType(btClass));
end;

end.
