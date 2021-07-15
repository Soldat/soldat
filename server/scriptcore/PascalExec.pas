{*******************************************************}
{                                                       }
{       PascalExec unit for SOLDAT                      }
{                                                       }
{       Copyright (c) 2012 Tomasz Kolosowski            }
{                                                       }
{*******************************************************}

// TODO: Documentation
unit PascalExec;

{$IFDEF FPC}{$mode delphi}{$INTERFACES CORBA}{$ENDIF}

interface

uses
  // general
  Classes, SysUtils,
  // pascal script
  uPSR_dll, uPSR_std, uPSRuntime, uPSUtils;

// just so that api units doesn't have to import uPSUtils unit
const
  btReturnAddress = uPSUtils.btReturnAddress;
  btU8 = uPSUtils.btU8;
  btS8 = uPSUtils.btS8;
  btU16 = uPSUtils.btU16;
  btS16 = uPSUtils.btS16;
  btU32 = uPSUtils.btU32;
  btS32 = uPSUtils.btS32;
  btSingle = uPSUtils.btSingle;
  btDouble = uPSUtils.btDouble;
  btExtended = uPSUtils.btExtended;
  btString = uPSUtils.btString;
  btRecord = uPSUtils.btRecord;
  btArray = uPSUtils.btArray;
  btPointer = uPSUtils.btPointer;
  btPChar = uPSUtils.btPChar;
  btResourcePointer = uPSUtils.btResourcePointer;
  btVariant = uPSUtils.btVariant;
{$IFNDEF PS_NOINT64}
  btS64 = uPSUtils.btS64;
{$ENDIF}
  btChar = uPSUtils.btChar;
{$IFNDEF PS_NOWIDESTRING}
  btWideString = uPSUtils.btWideString;
  btWideChar = uPSUtils.btWideChar;
{$ENDIF}
  btProcPtr = uPSUtils.btProcPtr;
  btStaticArray = uPSUtils.btStaticArray;
  btSet = uPSUtils.btSet;
  btCurrency = uPSUtils.btCurrency;
  btClass = uPSUtils.btClass;
  btInterface = uPSUtils.btInterface;
  btNotificationVariant = uPSUtils.btNotificationVariant;
  btUnicodeString = uPSUtils.btUnicodeString;
  btType = uPSUtils.btType;
  btEnum = uPSUtils.btEnum;
  btExtClass = uPSUtils.btExtClass;

type

  // just so that api units doesn't have to import uPSRuntime unit
  TPascalRuntimeClass = uPSRuntime.TPSRuntimeClass;

  TUnableToLoadException = class(Exception)
  end;

  TProcNotFoundException = class(Exception)
  end;

  TPascalExec = class;

  TPSError = uPSRuntime.TPSError;

  TFunction = uPSRuntime.TPSProcRec;
  TScriptFunction = uPSRuntime.TPSInternalProcRec;

  TAbstractFunction = uPSRuntime.TPSProcRec;

  TExternalFunction = uPSRuntime.TPSExternalProcRec;

  TOnException = procedure(Sender: TPascalExec; ExError: TPSError;
    const ExParam: string; ExObject: TObject; ProcNo, Position: Cardinal) of object;

  TPascalExec = class(TObject)
  private
    procedure CallInitializations;
    procedure CallFinalizations;
  protected
    FOnException: TOnException;
    FExec: TPSExec;
    FClassImporter: TPSRuntimeClassImporter;
    FInitializationProcNums: array of Integer;
    FFinalizationProcNums: array of Integer;
    FMainProcNum: Cardinal;
    FApi: TList;
    //constructor CreateClone(Exec: TPascalExec);
    procedure CreateExec; virtual;
    procedure LoadBytecode(Bytecode: string); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function CallFunction(FuncName: String; ProcNo: Cardinal; Parameters: array of Variant): Variant; overload;
    function CallFunction(FuncName: string; Parameters: array of Variant): Variant; overload;
    // NOTE(pewpew): CallEvent is a hack to bypass MyAllEventsHandler in PascalScript.
    function CallEvent(const Event; Params: array of Variant): Variant;
    procedure Execute;
    function GetErrorString: string; virtual;
    function GetErrorString2(Param: TPSError; const Message: string): string;
    function GetProc(C: Cardinal): TFunction;
    procedure AddDllSupport;
    //function CreateNewThread: TPascalExec;
    function AddClass(aClass: TClass): TPascalRuntimeClass; overload;
    function AddClass(aClass: TClass; Name: string): TPascalRuntimeClass; overload;
    procedure AddFunction(ProcPtr: Pointer; Name: string);
    procedure AddObjectMethod(Obj, ProcPtr: Pointer; Name: string);
    function FindType(BaseType: TPSBaseType): TPSTypeRec;
    procedure SetPointerToData(VarName: string; Data: Pointer; aType: TPSTypeRec);
    procedure SetValue(VarName: string; Value: Cardinal); overload;
    procedure SetValue(VarName: string; Value: Int64); overload;
    procedure SetValue(VarName: string; Value: Extended); overload;
    procedure SetValue(VarName: string; Value: Currency); overload;
    procedure SetValue(VarName: string; Value: Longint); overload;
    procedure SetValue(VarName: string; Value: string); overload;
    procedure SetValue(VarName: string; Value: widestring); overload;
    procedure SetValue(VarName: string; Value: unicodestring);overload;
    property Bytecode: string write LoadBytecode;
    property Error: string read GetErrorString;
    property Api: TList read FApi write FApi;
    property Exec: TPSExec read FExec;
    property ClassImporter: TPSRuntimeClassImporter read FClassImporter;
    property OnException: TOnException read FOnException write FOnException;
  end;

  IRuntimeAPI = interface
    ['{31a151f5-423b-48a0-9b22-7d994094b0fc}']
    procedure RuntimeRegisterApi(Exec: TPascalExec);
    procedure RuntimeRegisterVariables(Exec: TPascalExec);
    procedure BeforeExecute(Exec: TPascalExec);
    procedure AfterExecute(Exec: TPascalExec);
  end;

implementation

procedure OnException(Sender: TPSExec; ExError: TPSError; const ExParam: tbtstring;
  ExObject: TObject; ProcNo, Position: Cardinal);
var
  Exec: TPascalExec;
begin
  Exec := TPascalExec(Sender.Id);
  if Assigned(Exec.FOnException) then
    Exec.OnException(Exec, ExError, ExParam, ExObject, ProcNo, Position);
end;

constructor TPascalExec.Create;
begin
  Self.CreateExec;
  Self.FExec.Id := Self;
  Self.FExec.OnException := PascalExec.OnException;
  Self.FClassImporter := TPSRuntimeClassImporter.CreateAndRegister(Self.FExec, False);
  Self.FMainProcNum := InvalidVal;
end;

//constructor TPascalExec.CreateClone(Exec: TPascalExec);
//begin
//  // FApiClassList is irrevelant
//  self.FExec := Exec.FExec.CreateFromThis();
//  self.FInitializationProcNums := Exec.FInitializationProcNums;
//  self.FFinalizationProcNums := Exec.FFinalizationProcNums;
//end;

destructor TPascalExec.Destroy;
begin
  Self.CallFinalizations;
  Self.FExec.Stop;
  Self.FExec.Free;
  Self.FClassImporter.Free;
end;

procedure TPascalExec.CreateExec;
begin
  Self.FExec := TPSExec.Create;
end;

procedure TPascalExec.LoadBytecode(Bytecode: string);
var
  I: Integer;
  Name: string;
  Proc: TPSProcRec;
  ApiObj: IRuntimeAPI;
begin
  RegisterClassLibraryRuntime(Self.FExec, Self.FClassImporter);
  RIRegisterTObject(Self.FClassImporter);
  if Self.FApi <> nil then
    for I := 0 to Self.FApi.Count - 1 do
    begin
      TInterfacedObject(Self.FApi[I]).GetInterface(IRuntimeAPI, ApiObj);
      ApiObj.RuntimeRegisterApi(Self);
    end;
  if not Self.FExec.LoadData(Bytecode) then
    raise TUnableToLoadException.Create(Self.GetErrorString);
  if Self.FApi <> nil then
    for I := 0 to Self.FApi.Count - 1 do
    begin
      TInterfacedObject(Self.FApi[I]).GetInterface(IRuntimeAPI, ApiObj);
      ApiObj.RuntimeRegisterVariables(Self);
    end;
  for I := 0 to Self.FExec.GetProcCount - 1 do
  begin
    Proc := Self.FExec.GetProcNo(I);
    // make sure it's not null...
    if Proc = nil then
      continue;
    // ..and that it's script's function,
    // we don't want to catch dll calls here
    // or casting will fail
    if Proc.ClassType <> TPSInternalProcRec then
      continue;
    Name := TPSInternalProcRec(Proc).ExportName;
    if Copy(Name, 1, 6) = '!MAIN_' then
    begin
      SetLength(Self.FInitializationProcNums, Length(Self.FInitializationProcNums) + 1);
      Self.FInitializationProcNums[Length(Self.FInitializationProcNums) - 1] := I;
    end
    else if Copy(Name, 1, 8) = '!FINISH_' then
    begin
      SetLength(Self.FFinalizationProcNums,
        Length(Self.FFinalizationProcNums) + 1);
      Self.FFinalizationProcNums[Length(Self.FFinalizationProcNums) - 1] := I;
    end
    else if Copy(Name, 1, Length(Name)) = '!MAIN' then
      Self.FMainProcNum := I;
  end;
end;

function TPascalExec.GetErrorString: string;
begin
  Result := PSErrorToString(Self.FExec.ExceptionCode, Self.FExec.ExceptionString);
end;

function TPascalExec.GetErrorString2(Param: TPSError; const Message: string): string;
begin
  Result := PSErrorToString(Param, Message);
end;

procedure TPascalExec.CallInitializations();
var
  I: Integer;
begin
  for I := 0 to Length(FInitializationProcNums) - 1 do
    Self.FExec.RunProcP([], Self.FInitializationProcNums[I]);
end;

procedure TPascalExec.CallFinalizations();
var
  I: Integer;
begin
  for I := 0 to Length(FFinalizationProcNums) - 1 do
    Self.FExec.RunProcP([], Self.FFinalizationProcNums[I]);
end;

function TPascalExec.CallFunction(FuncName: String; ProcNo: Cardinal;
  Parameters: array of Variant): Variant; overload;
var
  i: Shortint;
  ApiObj: IRuntimeAPI;
begin
  if ProcNo = uPSRuntime.InvalidVal then
    raise TProcNotFoundException.Create(FuncName + ' not found');
  if Self.FExec.GetProcNo(ProcNo).ClassType <> TPSInternalProcRec then
    raise TProcNotFoundException.Create(FuncName + ' not found');
  // let whatever exception happen here fly out
  for i := 0 to Self.FApi.Count - 1 do
  begin
    TInterfacedObject(Self.FApi[I]).GetInterface(IRuntimeAPI, ApiObj);
    ApiObj.BeforeExecute(Self);
  end;
  try
    Result := Self.FExec.RunProcP(Parameters, ProcNo);
  finally
    for i := Self.FApi.Count - 1  to 0 do
    begin
      TInterfacedObject(Self.FApi[I]).GetInterface(IRuntimeAPI, ApiObj);
      ApiObj.AfterExecute(Self);
    end;
  end;
end;

function TPascalExec.CallFunction(FuncName: string;
  Parameters: array of Variant): Variant; overload;
var
  ProcNo: Cardinal;
begin
  ProcNo := Self.FExec.GetProc(FuncName);
  Result := CallFunction(FuncName, ProcNo, Parameters);
end;

function TPascalExec.CallEvent(const Event; Params: array of Variant): Variant;
var
  ProcNo: Cardinal;
  Func: TAbstractFunction;
  EventName: String;
begin
  ProcNo := PScriptMethodInfo(TMethod(Event).Data).ProcNo;

  Func := Self.Exec.GetProcNo(ProcNo);
  if Func is TScriptFunction then
    EventName := TScriptFunction(Func).ExportName
  else
    EventName := TExternalFunction(Func).Name;

  Result := CallFunction(EventName, ProcNo, Params);
end;

procedure TPascalExec.Execute();
var
  i: Shortint;
  ApiObj: IRuntimeAPI;
begin
  for i := 0 to Self.FApi.Count - 1 do
  begin
    TInterfacedObject(Self.FApi[I]).GetInterface(IRuntimeAPI, ApiObj);
    ApiObj.BeforeExecute(Self);
  end;
  Self.CallInitializations;
  if Self.FMainProcNum <> InvalidVal then
    Self.FExec.RunProcP([], Self.FMainProcNum);
end;

function TPascalExec.GetProc(C: Cardinal): TFunction;
begin
  Result := Self.Exec.GetProcNo(C);
end;

procedure TPascalExec.AddDllSupport;
begin
  RegisterDLLRuntime(Self.FExec);
end;

//function TPascalExec.CreateNewThread: TPascalExec;
//begin
//  Result := TPascalExec.CreateClone(self);
//end;

function TPascalExec.AddClass(aClass: TClass): TPascalRuntimeClass;
begin
  Result := Self.FClassImporter.Add(aClass);
end;

function TPascalExec.AddClass(aClass: TClass; Name: string): TPascalRuntimeClass;
begin
  Result := Self.FClassImporter.Add2(aClass, Name);
end;

procedure TPascalExec.AddFunction(ProcPtr: Pointer; Name: string);
begin
  Self.FExec.RegisterDelphiFunction(ProcPtr, Name, cdRegister);
end;

procedure TPascalExec.AddObjectMethod(Obj, ProcPtr: Pointer; Name: string);
begin
  Self.FExec.RegisterDelphiMethod(Obj, ProcPtr, Name, cdRegister);
end;

function TPascalExec.FindType(BaseType: TPSBaseType): TPSTypeRec;
begin
  Result := Self.FExec.FindType2(BaseType);
end;

procedure TPascalExec.SetPointerToData(VarName: string; Data: Pointer;
  aType: TPSTypeRec);
var
  v: PIFVariant;
  t: TPSVariantIFC;
begin
  v := self.FExec.GetVar2(VarName);
  if (aType = nil) or (v = nil) then
    raise Exception.Create('Unable to find variable');
  t.Dta := @PPSVariantData(v).Data;
  t.aType := v.FType;
  t.VarParam := False;
  VNSetPointerTo(t, Data, aType);
end;

procedure TPascalExec.SetValue(VarName: string; Value: Cardinal);
begin
  VSetUInt(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: Int64);
begin
  VSetInt64(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: Extended);
begin
  VSetReal(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: Currency);
begin
  VSetCurrency(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: Longint);
begin
  VSetInt(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: string);
begin
  VSetString(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: widestring);
begin
  VSetWideString(Self.Exec.GetVar2(VarName), Value);
end;

procedure TPascalExec.SetValue(VarName: string; Value: unicodestring);
begin
  VSetUnicodeString(Self.Exec.GetVar2(VarName), Value);
end;

end.
