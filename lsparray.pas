(*----------------------------------------------------------------------------*)
(* Array-Funktionen                                                           *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsparray;
{$O+,F+}

interface
uses
   lspglobl;


function  LspMakeArray(Size: pNode): pNode;
function  LspAref(Feld,Index: pNode): pNode;
procedure LspSetAtIndex(Feld, Wert: pNode; Index: longint);
function  LspGetAtIndex(Feld: pNode; Index: longint): pNode;
procedure LspSwapArrayVals(Feld: pNode; Index1, Index2: longint);



implementation
uses
   Classes, Sysutils,
   lsperr, lsppredi, lspmath, lspcreat;



(*----------------------------------------------------------------------------*)
(* Ein Array mit Size Knoten liefern.                                         *)
(*----------------------------------------------------------------------------*)
function LspMakeArray(Size: pNode): pNode;
var s,i  : longint;
    empty: pNode;
begin
  result := nil;
  empty  := nil;

  if (not LspIntegerp(Size)) then
     raise ELispException.Create('ErrIntegerExpected','');

  s := LspGetIntegerVal(Size);

  LspNew(result);
  result^.Typ      := cLspArray;
  result^.Size     := s;
  result^.ArrayVal := TMemoryStream.Create;
  for i := 0 to s - 1 do
      result^.ArrayVal.Write(empty,sizeof(pNode));
end;


(*----------------------------------------------------------------------------*)
(* Auf den Inhalt des Feldes an einer bestimmten Stelle zugreifen             *)
(*----------------------------------------------------------------------------*)
function LspAref(Feld,Index: pNode): pNode;
var i: longint;
begin
  result := nil;

  if (not LspArrayp(Feld)) then
     raise ELispException.Create('ErrArrayExpected','First argument wrong');

  if (not LspIntegerp(Index)) then
     raise ELispException.Create('ErrIntegerExpected','Second argument wrong');

  i := LspGetIntegerVal(Index);

  if ((i < 0) or (i >= Feld^.Size)) then
     raise ELispException.Create('ErrArrayIndexOutOfRange',IntToStr(i));

  Feld^.ArrayVal.Seek(i * sizeof(pNode),0);
  Feld^.ArrayVal.Read(Result, sizeof(pNode));
end;



(*----------------------------------------------------------------------------*)
(* Ein Element des Feldes mit einem Wert belegen                             *)
(*----------------------------------------------------------------------------*)
procedure LspSetAtIndex(Feld, Wert: pNode; Index: longint);
begin
  if (not LspArrayp(Feld)) then
     raise ELispException.Create('ErrArrayExpected','First argument');

  if ((Index < 0) or (Index >= Feld^.Size)) then
     raise ELispException.Create('ErrArrayIndexOutOfRange',IntToStr(Index));

  Feld^.ArrayVal.Seek(Index * sizeof(pNode),0);
  Feld^.ArrayVal.Write(Wert, sizeof(pNode));
end;



(*----------------------------------------------------------------------------*)
(* Den Wert des Feldes an einer bestimmten Stelle holen                       *)
(*----------------------------------------------------------------------------*)
function LspGetAtIndex(Feld: pNode; Index: longint): pNode;
begin
  Result := nil;

  if (not LspArrayp(Feld)) then
     raise ELispException.Create('ErrArrayExpected','First argument');

  if ((Index < 0) or (Index >= Feld^.Size)) then
     raise ELispException.Create('ErrArrayIndexOutOfRange',IntToStr(Index));

  Feld^.ArrayVal.Seek(Index * sizeof(pNode),0);
  Feld^.ArrayVal.Read(Result, sizeof(pNode));
end;


(*----------------------------------------------------------------------------*)
(* Zwei Werte eines Feldes vertauschen                                        *)
(*----------------------------------------------------------------------------*)
procedure LspSwapArrayVals(Feld: pNode; Index1, Index2: longint);
var Value1,Value2: pNode;
begin
  if (not LspArrayp(Feld)) then
     raise ELispException.Create('ErrArrayExpected','First argument');

  if ((Index1 < 0) or (Index1 >= Feld^.Size)) then
     raise ELispException.Create('ErrArrayIndexOutOfRange',IntToStr(Index1));

  if ((Index2 < 0) or (Index2 >= Feld^.Size)) then
     raise ELispException.Create('ErrArrayIndexOutOfRange',IntToStr(Index2));

  Feld^.ArrayVal.Seek(Index1 * sizeof(pNode),0);
  Feld^.ArrayVal.Read(Value1, sizeof(pNode));

  Feld^.ArrayVal.Seek(Index2 * sizeof(pNode),0);
  Feld^.ArrayVal.Read(Value2, sizeof(pNode));

  Feld^.ArrayVal.Seek(Index1 * sizeof(pNode),0);
  Feld^.ArrayVal.Write(Value2, sizeof(pNode));

  Feld^.ArrayVal.Seek(Index2 * sizeof(pNode),0);
  Feld^.ArrayVal.Write(Value1, sizeof(pNode));
end;




end.
