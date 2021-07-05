  {$IF (defined(cpuaarch64) or defined(cpuarm))}
    {$DEFINE USEINVOKECALL}
  {$IFEND}



  {$DEFINE PS_HAVEVARIANT}
  {$DEFINE PS_DYNARRAY}
  {$ifndef mswindows}
    {$DEFINE PS_NOIDISPATCH}
  {$endif}
  {$if (fpc_version>2) or ((fpc_version=2) and ((fpc_release=2) and (fpc_patch>=4)) or (fpc_release>2))}
    {$UNDEF FPC_OLD_FIX}
    {$DEFINE PS_STACKALIGN}
    {$UNDEF PS_FPCSTRINGWORKAROUND}
    {$DEFINE PS_RESBEFOREPARAMETERS}
    {$DEFINE x64_string_result_as_varparameter}
    {$ifdef mswindows}
      {$if (fpc_version>2) or ((fpc_version=2) and (fpc_release>5))}
       {$DEFINE PS_FPC_HAS_COM}
      {$endif}
    {$endif}
  {FreePascal 2.3.1 and above has much Delphi compatibility bugs fixed}
  {$else}
    {$DEFINE FPC_OLD_FIX}
    {$DEFINE PS_FPCSTRINGWORKAROUND}
  {$ifend}
  {$DEFINE DELPHI3UP}
  {$DEFINE DELPHI6UP}
