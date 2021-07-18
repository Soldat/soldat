function TPSExec.InnerfuseCall(_Self, Address: Pointer; CallingConv: TPSCallingConvention; Params: TPSList; res: PPSVariantIFC): Boolean;
var SysCalConv : TCallConv;
    Args: TArray<TValue>;
    Arg : TValue;
    i : Integer;
    fvar: PPSVariantIFC;
    IsConstr : Boolean;
    ctx: TRTTIContext;
    RttiType : TRttiType;
    ResValue : TValue;
begin
  Result := False;
  case CallingConv of
    cdRegister : SysCalConv := ccReg;
    cdPascal : SysCalConv := ccPascal;
    cdCdecl : SysCalConv := ccCdecl;
    cdStdCall : SysCalConv := ccStdCall;
    cdSafeCall : SysCalConv := ccSafeCall;
  else
    SysCalConv := ccReg;//to prevent warning "W1036 Variable might not have been initialized"
  end;

  if Assigned(_Self) then
    Args := Args + [TValue.From<Pointer>( _Self )];

  for I := 0 to Params.Count - 1 do
  begin
    if Params[i] = nil
      then Exit;
    fvar := Params[i];

    if fvar.varparam then
    begin { var param }
      case fvar.aType.BaseType of
        btArray, btVariant, btSet, btStaticArray, btRecord, btInterface, btClass, {$IFNDEF PS_NOWIDESTRING} btWideString, btWideChar, {$ENDIF}
        btU8, btS8, btU16, btS16, btU32, btS32, btSingle, btDouble, btExtended, btString, btPChar, btChar, btCurrency,
        btUnicodeString
        {$IFNDEF PS_NOINT64}, bts64{$ENDIF}:
          Arg := TValue.From<Pointer>( Pointer(fvar.dta) );
        else
          begin
            Exit;
          end;
      end;
    end
    else
    begin  { not a var param }
      case fvar.aType.BaseType of
        { add normal params here }
        {$IFNDEF PS_NOWIDESTRING}
        btWidestring,
        btUnicodestring,
        {$ENDIF}
        btString:                          Arg := TValue.From<String>(pstring(fvar.dta)^);
        btU8, btS8:                        Arg := TValue.From<Byte>(pbyte(fvar.dta)^);
        btU16, BtS16:                      Arg := TValue.From<Word>(pword(fvar.dta)^);
        btU32, btS32:                      Arg := TValue.From<Cardinal>(pCardinal(fvar.dta)^);
        {$IFNDEF PS_NOINT64}bts64:{$ENDIF} Arg := TValue.From<Int64>(pint64(fvar.dta)^);
        btSingle:                          Arg := TValue.From<Single>(PSingle(fvar.dta)^);
        btDouble:                          Arg := TValue.From<Double>(PDouble(fvar.dta)^);
        btExtended:                        Arg := TValue.From<Extended>(PExtended(fvar.dta)^);
        btPChar:                           Arg := TValue.From<PChar>(ppchar(fvar.dta)^);
        btChar:                            Arg := TValue.From<Char>(pchar(fvar.dta)^);
        btClass:                           Arg := TValue.From<TObject>(TObject(fvar.dta^));
        btRecord:                          Arg := TValue.From<Pointer>(fvar.dta);
        btStaticArray:                     Arg := TValue.From<Pointer>(fvar.dta);
        btArray:
          begin
             if Copy(fvar.aType.ExportName, 1, 10) = '!OPENARRAY' then
             begin  //openarray
               //in case of openarray we should provide TWO params: first is pointer to array,
               Args := Args + [TValue.From<Pointer>(Pointer(fvar.Dta^))];
               //2nd - integer with arraylength - 1 (high)
               Arg := TValue.From<Integer>(PSDynArrayGetLength(Pointer(fvar.Dta^), fvar.aType)-1);// = High of OpenArray
             end
             else //dynarray = just push pointer
               Arg := TValue.From<Pointer>(fvar.dta);
          end;
        btSet:
          begin
            case TPSTypeRec_Set(fvar.aType).aByteSize  of
              1: Arg := TValue.From<Byte>(pbyte(fvar.dta)^);
              2: Arg := TValue.From<Word>(pWord(fvar.dta)^);
              3,
              4: Arg := TValue.From<Cardinal>(pCardinal(fvar.dta)^);
              else
                Arg := TValue.From<Pointer>(fvar.dta);
            end;
          end;
        else
//            writeln(stderr, 'Parameter type not implemented!');
          Exit;
      end;  { case }
    end;
    Args := Args + [Arg];
  end;

  IsConstr := (Integer(CallingConv) and 64) <> 0;
  if not assigned(res) then
  begin
    Invoke(Address,Args,SysCalConv,nil,False,IsConstr);  { ignore return }
  end
  else begin
    case res.atype.basetype of
      { add result types here }
      btString:                tbtstring(res.dta^) := tbtstring(Invoke(Address,Args,SysCalConv,TypeInfo(String),False,IsConstr).AsString)
      ;
      {$IFNDEF PS_NOWIDESTRING}
      btUnicodeString:         tbtunicodestring(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(String),False,IsConstr).AsString;
      btWideString:            tbtWideString(res.dta^) := Invoke(Address,Args,SysCalConv,TypeInfo(String),False,IsConstr).AsString;
      {$ENDIF}
      btU8, btS8:              pbyte(res.dta)^ := Byte(Invoke(Address,Args,SysCalConv,TypeInfo(Byte),False,IsConstr).AsInteger);
      btU16, btS16:            pword(res.dta)^ := word(Invoke(Address,Args,SysCalConv,TypeInfo(Word),False,IsConstr).AsInteger);
      btU32, btS32:            pCardinal(res.dta)^ := Cardinal(Invoke(Address,Args,SysCalConv,TypeInfo(Cardinal),False,IsConstr).AsInteger);
      {$IFNDEF PS_NOINT64}bts64:{$ENDIF}   pInt64(res.dta)^ := Int64(Invoke(Address,Args,SysCalConv,TypeInfo(Int64),False,IsConstr).AsInt64);
      btSingle:                psingle(res.dta)^ := Double(Invoke(Address,Args,SysCalConv,TypeInfo(Single),False,IsConstr).AsExtended);
      btDouble:                pdouble(res.dta)^ := Double(Invoke(Address,Args,SysCalConv,TypeInfo(Double),False,IsConstr).AsExtended);
      btExtended:              pextended(res.dta)^ := Extended(Invoke(Address,Args,SysCalConv,TypeInfo(Extended),False,IsConstr).AsExtended);
      {$IFDEF FPC}
      btPChar:                 ppchar(res.dta)^ := pchar(Invoke(Address,Args,SysCalConv,TypeInfo(PChar),False,IsConstr).AsOrdinal);
      btChar:                  pchar(res.dta)^ := Char(Invoke(Address,Args,SysCalConv,TypeInfo(Char),False,IsConstr).AsChar);
      {$ELSE}
      btPChar:                 ppchar(res.dta)^ := pchar(Invoke(Address,Args,SysCalConv,TypeInfo(PChar),False,IsConstr).AsType<PChar>());
      btChar:                  pchar(res.dta)^ := Char(Invoke(Address,Args,SysCalConv,TypeInfo(Char),False,IsConstr).AsType<Char>());
      {$ENDIF}
      btSet:
        begin
          case TPSTypeRec_Set(res.aType).aByteSize  of
            1: byte(res.Dta^) := Byte(Invoke(Address,Args,SysCalConv,TypeInfo(Byte),False,IsConstr).AsInteger);
            2: word(res.Dta^) := word(Invoke(Address,Args,SysCalConv,TypeInfo(Word),False,IsConstr).AsInteger);
            3,
            4: Longint(res.Dta^) := Cardinal(Invoke(Address,Args,SysCalConv,TypeInfo(Cardinal),False,IsConstr).AsInteger);
            {$IFNDEF FPC}
            else
            begin
              for RttiType in ctx.GetTypes do
                if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkSet)
                  and (RttiType.TypeSize = TPSTypeRec_Set(res.aType).aByteSize) then
                begin
                  Invoke(Address,Args,SysCalConv,RttiType.Handle,False,IsConstr).ExtractRawData(res.dta);
                  Break;
                end;
            end;
            {$ENDIF}
          end;
        end;
      btClass:
      begin
        {$IFNDEF FPC}for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkClass) then{$ENDIF}
          begin
            TObject(res.dta^) := Invoke(Address,Args,SysCalConv,{$IFDEF FPC}TypeInfo(TObject){$ELSE}RttiType.Handle{$ENDIF},False,IsConstr).AsObject;
            {$IFNDEF FPC}Break;{$ENDIF}
          end;
      end;
      {$IFNDEF FPC}
      btStaticArray:
      begin
        for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkArray) then
          begin
            CopyArrayContents(res.dta, Invoke(Address,Args,SysCalConv,RttiType.Handle,False,IsConstr).GetReferenceToRawData, TPSTypeRec_StaticArray(res.aType).Size, TPSTypeRec_StaticArray(res.aType).ArrayType);
            Break;
          end;
      end;
      btRecord:
      begin
        for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkRecord) then
          begin
            CopyArrayContents(res.dta, (Invoke(Address,Args,SysCalConv,RttiType.Handle,False,IsConstr).GetReferenceToRawData), 1, res.aType);
            Break;
          end;
      end;
      btArray: //need to check with open arrays
      begin
        for RttiType in ctx.GetTypes do
          if (RttiType.Name.ToUpper.EndsWith(String(res.aType.FExportName))) and (RttiType.TypeKind = tkDynArray) then
          begin
            ResValue := Invoke(Address,Args,SysCalConv,RttiType.Handle,False,IsConstr);
            if ResValue.GetArrayLength > 0 then
              CopyArrayContents(res.dta, ResValue.GetReferenceToRawData, 1, res.aType)
            else
              res.dta := nil;
            Break;
          end;
      end;
      {$ENDIF}
      else
//          writeln(stderr, 'Result type not implemented!');
        Exit;
    end;  { case }
  end; //assigned(res)

  Result := True;
end;
