{*******************************************************}
{                                                       }
{       ScriptUnit unit for SOLDAT                      }
{                                                       }
{       Copyright (c) 2013 Tomasz Kolosowski            }
{                                                       }
{*******************************************************}

// TODO: Documentation
unit ScriptUnit;

{$IFDEF FPC}{$mode delphi}{$ENDIF}

interface

uses
  Classes,
  PascalCompiler,
  PascalExec,
  Script,
  ScriptCore3Api,
  SysUtils;

type

  TOnException = procedure(ErrorCode: TPSError; Message, UnitName, FunctionName: string;
    Row, Col: Cardinal) of object;

  TOnUnhandledException = function(ErrorCode: TPSError; Message, UnitName, FunctionName: string;
    Row, Col: Cardinal): Boolean of object;

  TScriptUnit = class(TObject)
  private
    FScript: TScript;
    FOnException: TOnException;
    FOnUnhandledException: TOnUnhandledException;
    function GetName: string;
    function GetVersion: string;
    function GetDir: string;
    function GetDebugMode: Boolean;
  public
    constructor Create(Script: TScript);
    procedure Recompile(Force: Boolean);
    procedure Unload;
    property Name: string read GetName;
    property Version: string read GetVersion;
    property Dir: string read GetDir;
    property DebugMode: Boolean read GetDebugMode;
    property OnException: TOnException read FOnException write FOnException;
    property OnUnhandledException: TOnUnhandledException
        read FOnUnhandledException write FOnUnhandledException;
  end;

  TScriptUnitAPI = class(TScriptCore3API)
  private
    FUnit: TScriptUnit;
  public
    constructor Create(Script: TScript);
    procedure CompilerRegister(Compiler: TPascalCompiler); override;
    procedure RuntimeRegisterApi(Exec: TPascalExec); override;
    procedure RuntimeRegisterVariables(Exec: TPascalExec); override;
    property ScriptUnit: TScriptUnit read FUnit;
  end;

implementation

uses
  ScriptCore3,
  ScriptExceptions;

function TScriptUnit.GetName: string;
begin
  Result := Self.FScript.Name;
end;

function TScriptUnit.GetVersion: string;
begin
  // TODO: reimplement
  Result := '3.0 alpha';
end;

function TScriptUnit.GetDir: string;
begin
  Result := Self.FScript.Dir;
end;

function TScriptUnit.GetDebugMode: Boolean;
begin
  Result := TScriptCore3(Self.FScript).Debug;
end;

constructor TScriptUnit.Create(Script: TScript);
begin
  Self.FScript := Script;
end;

procedure TScriptUnit.Recompile(Force: Boolean);
begin
  // Explained below.
  raise EScriptRecompile.Create('Recompiling script', Force);
end;

procedure TScriptUnit.Unload;
begin
  // This is a bit of an ugly hack. This function is called form inside the script,
  // so to actually fulfill it's wish to unload we can do one of two things:
  // - mark it for unloading, let it run and unload it at the end of current pass
  // - unload it immidiately
  // In the 2nd case, we need to somehow unwind the stack, as the script cannot
  // continue to execute after shredding it's objects.
  // Easiest way to do that is to throw an exception, so we throw it here,
  // catch it later and after we're sure there's nothing executing,
  // we destroy the object.
  // This is even uglier since script can catch it. Then whole thing just won't work.
  raise EScriptUnload.Create('Unloading script');
end;

constructor TScriptUnitAPI.Create(Script: TScript);
begin
  inherited Create(Script);
  Self.FUnit := TScriptUnit.Create(Script);
end;

procedure TScriptUnitAPI.CompilerRegister(Compiler: TPascalCompiler);
var
  ScriptClass: TPascalCompiletimeClass;
begin
  Compiler.AddType('TErrorType',
    '(ErNoError, erCannotImport, erInvalidType, ErInternalError, ' +
    'erInvalidHeader, erInvalidOpcode, erInvalidOpcodeParameter, erNoMainProc,' +
    'erOutOfGlobalVarsRange, erOutOfProcRange, ErOutOfRange, erOutOfStackRange,' +
    'ErTypeMismatch, erUnexpectedEof, erVersionError, ErDivideByZero, ErMathError,' +
    'erCouldNotCallProc, erOutofRecordRange, erOutOfMemory, erException,' +
    'erNullPointerException, erNullVariantError, erInterfaceNotSupported, erCustomError)');

  Compiler.AddType('TOnException',
    'procedure (ErrorCode: TErrorType; Message, UnitName, FunctionName: string; Row, Col: Cardinal)');

  Compiler.AddType('TOnUnhandledException',
    'function (ErrorCode: TErrorType; Message, UnitName, FunctionName: string; Row, Col: Cardinal): Boolean');

  ScriptClass := Compiler.AddClass(nil, 'TScript');
  with ScriptClass do
  begin
    RegisterMethod('procedure Recompile(Force: Boolean)');
    RegisterMethod('procedure Unload');
    RegisterProperty('Name', 'string', iptR);
    RegisterProperty('Version', 'string', iptR);
    RegisterProperty('Dir', 'string', iptR);
    RegisterProperty('DebugMode', 'Boolean', iptR);
    RegisterProperty('OnException', 'TOnException', iptRW);
    RegisterProperty('OnUnhandledException', 'TOnUnhandledException', iptRW);
  end;

  Compiler.AddPtrVariable('Script', ScriptClass.aType);
end;

procedure NameReadHelper(Self: TScriptUnit; var Result: string);
begin
  Result := Self.Name;
end;

procedure VersionReadHelper(Self: TScriptUnit; var Result: string);
begin
  Result := Self.Version;
end;

procedure DirReadHelper(Self: TScriptUnit; var Result: string);
begin
  Result := Self.Dir;
end;

procedure DebugModeReadHelper(Self: TScriptUnit; var Result: Boolean);
begin
  Result := Self.DebugMode;
end;

procedure OnExceptionReadHelper(Self: TScriptUnit; var Result: TOnException);
begin
  Result := Self.OnException;
end;

procedure OnExceptionWriteHelper(Self: TScriptUnit; const Result: TOnException);
begin
  Self.OnException := Result;
end;

procedure OnUnhandledExceptionReadHelper(Self: TScriptUnit; var Result: TOnUnhandledException);
begin
  Result := Self.OnUnhandledException;
end;

procedure OnUnhandledExceptionWriteHelper(Self: TScriptUnit; const Result: TOnUnhandledException);
begin
  Self.OnUnhandledException := Result;
end;

procedure TScriptUnitAPI.RuntimeRegisterApi(Exec: TPascalExec);
begin
  with Exec.AddClass(TScriptUnit, 'TScript') do
  begin
    RegisterMethod(@TScriptUnit.Recompile, 'Recompile');
    RegisterMethod(@TScriptUnit.Unload, 'Unload');
    RegisterPropertyHelper(@NameReadHelper, nil, 'Name');
    RegisterPropertyHelper(@VersionReadHelper, nil, 'Version');
    RegisterPropertyHelper(@DirReadHelper, nil, 'Dir');
    RegisterPropertyHelper(@DebugModeReadHelper, nil, 'DebugMode');
    RegisterEventPropertyHelper(@OnExceptionReadHelper, @OnExceptionWriteHelper,
      'OnException');
    RegisterEventPropertyHelper(@OnUnhandledExceptionReadHelper, @OnUnhandledExceptionWriteHelper,
      'OnUnhandledException');
  end;
end;

procedure TScriptUnitAPI.RuntimeRegisterVariables(Exec: TPascalExec);
begin
  Exec.SetPointerToData('Script', @Self.FUnit, Exec.FindType(btClass));
end;

end.
