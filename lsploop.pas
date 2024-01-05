(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsploop;
{$O+,F+}

interface
uses
   lspglobl;

function LspLet(Variablen,Body,Umgebung: pNode): pNode;
function LspDoList(SymListRes, Body, Umgebung: pNode): pNode;
function LspDoTimes(SymCountRes, Body, Umgebung: pNode): pNode;
function LspProgn(Body, Umgebung: pNode): pNode;
function LspWhile(Body, Umgebung: pNode): pNode;


implementation
uses
   lsppredi, lsperr, lspbasic, lspcreat, lsplists, lspmain, lspmath, lspinit,
   lspinout;

function LspLet(Variablen,Body,Umgebung: pNode): pNode;
var laeufer       : pNode;
    b,c,d         : pNode;
    localE  : pNode;
begin
  LspLet := nil;

  if (not LspListp(Variablen)) then
     raise ELispException.Create('ErrListExpected','Variables of LET');

  laeufer := Variablen;

  localE := Umgebung;
  LocalE := LspCons(LspList2(cLspLet,Variablen),LocalE); (* GC-Trick *)
  LocalE := LspCons(LspList2(cLspLet,Body     ),LocalE); (* GC-Trick *)


  while (laeufer <> nil) do
     begin
       c := laeufer^.CarVal;
       if (LspSymbolp(c)) then
          localE := LspCons(LspList2(c,nil),localE)
       else
       if (LspListp(c)) then
          begin
            d := LspCar(c);
            if (not LspSymbolp(d)) then
               raise ELispException.Create('ErrSymbolExpected','');
            localE := LspCons(LspList2(d,LspEval(LspCadr(c),localE)),localE);
          end
       else
          raise ELispException.Create('ErrSymbolOrListExpected','');

       laeufer := LspCdr(laeufer);
     end;

  b := Body;
  while (b <> nil) do
     begin
       result := LspEval(b^.CarVal,localE);
       b := b^.CdrVal;
     end;
end;






function LspDoList(SymListRes, Body, Umgebung: pNode): pNode;
var Symbol        : pNode;
    Liste         : pNode;
    b             : pNode;
    localE        : pNode;
    tempP         : pNode;
begin
  (*--- Syntaktische Ueberpruefung der Parameter ---*)
  if (not LspListp(SymListRes)) then
     raise ELispException.Create('ErrListExpected','DOLIST, SymListRes');

  LocalE    := Umgebung;
  Symbol    := LspCar(SymListRes);
  Liste     := LspEval(LspCadr(SymListRes),LocalE);

  if (LspNull(Symbol) or not LspSymbolp(Symbol)) then
     raise ELispException.Create('ErrNonNilSymbolExpected','DOLIST, CAR of SymListRes');

  if (not LspListp(Liste)) then
     raise ELispException.Create('ErrListExpected','DOLIST, CADR of SymListRes');

  (*--- Variablenbindung an den Anfang der Umgebung ---*)
  LocalE := LspCons(LspList2(cLspDoList ,SymListRes),LocalE); (* GC-Trick *)
  LocalE := LspCons(LspList2(cLspDoList ,Body      ),LocalE); (* GC-Trick *)
  LocalE := LspCons(LspList2(cLspDoList ,Liste     ),LocalE); (* GC-Trick *)
  LocalE := LspCons(LspList2(Symbol,LspCar(Liste)  ),LocalE);

  (*--- Eigentliche Schleife ausfuehren ---*)
  while (Liste <> nil) do
  begin
    b := Body;
    while (b <> nil) do
    begin
      LspEval(LspCar(b),localE);
      b := LspCdr(b);
    end;

    Liste := LspCdr(Liste);
    tempP := LspAssoc(Symbol,LocalE);
    tempP^.CdrVal := Liste;
  end;

  result := LspEval(LspCaddr(SymListRes),LocalE);
end;



function LspDoTimes(SymCountRes, Body, Umgebung: pNode): pNode;
var Symbol        : pNode;
    Count         : pNode;
    _Count,i      : longint;
    b             : pNode;
    localE        : pNode;
begin
  if (not LspListp(SymCountRes)) then
     raise ELispException.Create('ErrListExpected','DOTIMES, SymListRes');

  LocalE    := Umgebung;
  Symbol    := LspCar(SymCountRes);
  Count     := LspEval(LspCadr(SymCountRes),LocalE);

  if (LspNull(Symbol) or not LspSymbolp(Symbol)) then
     raise ELispException.Create('ErrNonNilSymbolExpected','DOTIMES, CAR of SymListRes');

  if (not LspIntegerp(Count)) then
     raise ELispException.Create('ErrIntegerExpected','DOTIMES, CADR of SymListRes');

  _Count := LspGetIntegerVal(Count);

  (*--- Variablenbindung an den Anfang der Umgebung ---*)
  LocalE := LspCons(LspList2(cLspDoTimes,SymCountRes ),LocalE); (* GC-Trick *)
  LocalE := LspCons(LspList2(cLspDoTimes,Body        ),LocalE); (* GC-Trick *)
  LocalE := LspCons(LspList2(Symbol,LspMakeInteger(0)),LocalE);

  (*--- Eigentliche Schleife ausfuehren ---*)
  for i := 0 to _Count - 1 do
     begin
       LspSetq(Symbol,LspMakeInteger(i),localE);

       (*--- Schleifenkoerper ---*)
       b := Body;
       while (b <> nil) do
       begin
         LspEval(LspCar(b),localE);
         b := LspCdr(b);
       end;
     end;

  result := LspEval(LspCaddr(SymCountRes),LocalE);
end;





function LspProgn(Body, Umgebung: pNode): pNode;
var b,LocalE: pNode;
begin
  LspProgn := nil;

  LocalE := Umgebung;
  LocalE := LspCons(LspList2(cLspProgn,Body),LocalE); (* GC-Trick *)

  b := Body;
  while (b <> nil) do
     begin
       LspProgn := LspEval(LspCar(b),LocalE);
       b := LspCdr(b);
     end;
end;



function LspWhile(Body, Umgebung: pNode): pNode;
var b,Bedingung,LocalE: pNode;
begin
  LspWhile := nil;

  LocalE := Umgebung;
  LocalE := LspCons(LspList2(cLspWhile,Body),LocalE); (* GC-Trick *)


  Bedingung := LspCar(Body);
  while LspEval(Bedingung,LocalE) <> nil do
     begin
       b := LspCdr(Body);
       while (b <> nil) do
          begin
            LspWhile := LspEval(LspCar(b),LocalE);
            b := LspCdr(b);
          end;
     end;
end;

end.
