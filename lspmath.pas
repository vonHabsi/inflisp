(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspmath;
{$O+,F+,E+,N+}

interface
uses
   lspglobl;

function LspPlus      (p1, p2: pNode): pNode;
function LspMinus     (p1, p2: pNode): pNode;
function LspTimes     (p1, p2: pNode): pNode;
function LspDivided   (p1, p2: pNode): pNode;
function LspEinsMinus (p: pNode)     : pNode;
function LspEinsPlus  (p: pNode)     : pNode;
function LspExp       (p: pNode)     : pNode;
function LspLn        (p: pNode)     : pNode;
function LspSqr       (p: pNode)     : pNode;
function LspSqrt      (p: pNode)     : pNode;

function LspMathEqual     (p1, p2: pNode): pNode;
function LspMathNotEqual  (p1, p2: pNode): pNode;
function LspLess          (p1, p2: pNode): pNode;
function LspGreater       (p1, p2: pNode): pNode;
function LspGreaterOrEqual(p1, p2: pNode): pNode;
function LspLessOrEqual   (p1, p2: pNode): pNode;

function LspRandomize                : pNode;
function LspRandom    (p: pNode)     : pNode;

function LspGetIntegerVal(p: pNode): longint;
function LspGetFloatVal(p: pNode): double;

implementation
uses
   lsppredi, lsperr, lspcreat;


function LspPlus(p1, p2: pNode): pNode;
var L1,L2: longint;
    D1,D2: double;
    B1,B2: boolean;
begin
  result := nil;

  if (not LspNumberp(p1)) then
     raise ELispException.Create('ErrNumberExpected','First argument wrong');

  if (not LspNumberp(p2)) then
     raise ELispException.Create('ErrNumberExpected','Second argument wrong');


  if (p1^.Typ = cLspInteger) then
     begin
       L1 := p1^.IntegerVal;
       D1 := 0.0;
       B1 := false;
     end
  else
     begin
       L1 := 0;
       D1 := p1^.FloatVal;
       B1 := true;
     end;

  if (p2^.Typ = cLspInteger) then
     begin
       L2 := p2^.IntegerVal;
       D2 := 0.0;
       B2 := false;
     end
  else
     begin
       L2 := 0;
       D2 := p2^.FloatVal;
       B2 := true;
     end;

  if (not B1 and not B2) then result := LspMakeInteger(L1 + L2)
  else
  if (not B1 and     B2) then result := LspMakeFloat  (L1 + D2)
  else
  if (    B1 and not B2) then result := LspMakeFloat  (D1 + L2)
  else
  if (    B1 and     B2) then result := LspMakeFloat  (D1 + D2);
end;

function LspMinus(p1, p2: pNode): pNode;
var L1,L2: longint;
    D1,D2: double;
    B1,B2: boolean;
begin
  result := nil;

  if (not LspNumberp(p1)) then
     raise ELispException.Create('ErrNumberExpected','First argument wrong');

  if (not LspNumberp(p2)) then
     raise ELispException.Create('ErrNumberExpected','Second argument wrong');

  if (p1^.Typ = cLspInteger) then
     begin
       L1 := p1^.IntegerVal;
       D1 := 0.0;
       B1 := false;
     end
  else
     begin
       L1 := 0;
       D1 := p1^.FloatVal;
       B1 := true;
     end;

  if (p2^.Typ = cLspInteger) then
     begin
       L2 := p2^.IntegerVal;
       D2 := 0.0;
       B2 := false;
     end
  else
     begin
       L2 := 0;
       D2 := p2^.FloatVal;
       B2 := true;
     end;

  if (not B1 and not B2) then LspMinus := LspMakeInteger(L1 - L2)
  else
  if (not B1 and     B2) then LspMinus := LspMakeFloat  (L1 - D2)
  else
  if (    B1 and not B2) then LspMinus := LspMakeFloat  (D1 - L2)
  else
  if (    B1 and     B2) then LspMinus := LspMakeFloat  (D1 - D2);
end;






function LspTimes(p1, p2: pNode): pNode;
var L1,L2: longint;
    D1,D2: double;
    B1,B2: boolean;
begin
  result := nil;

  if (not LspNumberp(p1)) then
     raise ELispException.Create('ErrNumberExpected','First argument wrong');

  if (not LspNumberp(p2)) then
     raise ELispException.Create('ErrNumberExpected','Second argument wrong');

  if (p1^.Typ = cLspInteger) then
     begin
       L1 := p1^.IntegerVal;
       D1 := 0.0;
       B1 := false;
     end
  else
     begin
       L1 := 0;
       D1 := p1^.FloatVal;
       B1 := true;
     end;

  if (p2^.Typ = cLspInteger) then
     begin
       L2 := p2^.IntegerVal;
       D2 := 0.0;
       B2 := false;
     end
  else
     begin
       L2 := 0;
       D2 := p2^.FloatVal;
       B2 := true;
     end;

  if (not B1 and not B2) then result := LspMakeInteger(L1 * L2)
  else
  if (not B1 and     B2) then result := LspMakeFloat  (L1 * D2)
  else
  if (    B1 and not B2) then result := LspMakeFloat  (D1 * L2)
  else
  if (    B1 and     B2) then result := LspMakeFloat  (D1 * D2);
end;



function LspDivided(p1, p2: pNode): pNode;
var L1,L2: longint;
    D1,D2: double;
    B1,B2: boolean;
begin
  result := nil;

  if (not LspNumberp(p1)) then
     raise ELispException.Create('ErrNumberExpected','First argument wrong');

  if (not LspNumberp(p2)) then
     raise ELispException.Create('ErrNumberExpected','Second argument wrong');

  if (p1^.Typ = cLspInteger) then
     begin
       L1 := p1^.IntegerVal;
       D1 := 0.0;
       B1 := false;
     end
  else
     begin
       L1 := 0;
       D1 := p1^.FloatVal;
       B1 := true;
     end;

  if (p2^.Typ = cLspInteger) then
     begin
       L2 := p2^.IntegerVal;
       D2 := 0.0;
       B2 := false;
     end
  else
     begin
       L2 := 0;
       D2 := p2^.FloatVal;
       B2 := true;
     end;

  if (not B1 and not B2) then result := LspMakeInteger(L1 div L2)
  else
  if (not B1 and     B2) then result := LspMakeFloat  (L1 / D2)
  else
  if (    B1 and not B2) then result := LspMakeFloat  (D1 / L2)
  else
  if (    B1 and     B2) then result := LspMakeFloat  (D1 / D2);
end;




function LspEinsPlus(p: pNode): pNode;
var L1: longint;
    D1: double;
    B1: boolean;
begin
  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');

  if (p^.Typ = cLspInteger) then
     begin
       L1 := p^.IntegerVal;
       D1 := 0.0;
       B1 := false;
     end
  else
     begin
       L1 := 0;
       D1 := p^.FloatVal;
       B1 := true;
     end;

  if (not B1) then
     result := LspMakeInteger(L1 + 1)
  else
     result := LspMakeFloat(D1 + 1.0);
end;



function LspEinsMinus(p: pNode): pNode;
var L1: longint;
    D1: double;
    B1: boolean;
begin
  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');

  if (p^.Typ = cLspInteger) then
     begin
       L1 := p^.IntegerVal;
       D1 := 0.0;
       B1 := false;
     end
  else
     begin
       L1 := 0;
       D1 := p^.FloatVal;
       B1 := true;
     end;

  if (not B1) then
     result := LspMakeInteger(L1 - 1)
  else
     result := LspMakeFloat(D1 - 1.0);
end;



(*----------------------------------------------------------------------------*)
(* Die Exponentialfunktion                                                    *)
(*----------------------------------------------------------------------------*)
function LspExp(p: pNode): pNode;
begin
  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');
  result := LspMakeFloat(exp(LspGetFloatVal(p)));
end;



(*----------------------------------------------------------------------------*)
(* Der Logarithmus zur Basis e                                                *)
(*----------------------------------------------------------------------------*)
function LspLn(p: pNode): pNode;
begin
  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');

  result := LspMakeFloat(ln(LspGetFloatVal(p)));
end;



(*----------------------------------------------------------------------------*)
(* Das Quadrat einer Ziel                                                     *)
(*----------------------------------------------------------------------------*)
function LspSqr(p: pNode): pNode;
begin
  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');

  result := LspMakeFloat(sqr(LspGetFloatVal(p)));
end;



(*----------------------------------------------------------------------------*)
(* Die Quadratwurzel einer Ziel                                               *)
(*----------------------------------------------------------------------------*)
function LspSqrt(p: pNode): pNode;
begin
  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','First argument wrong');

  result := LspMakeFloat(sqrt(LspGetFloatVal(p)));
end;





(*----------------------------------------------------------------------------*)





(*----------------------------------------------------------------------------*)
(* Basis-Vergleichsfunktion. <,>,<=,>=,<> werden darauf zurueckgefuehrt.      *)
(*----------------------------------------------------------------------------*)
function cmpNodes(p1, p2: pNode): integer;
begin
  result := 0;

  if (p1 = nil) then
     raise ELispException.Create('ErrComparison','First argument must be non-nil');

  if (p2 = nil) then
     raise ELispException.Create('ErrComparison','Second argument must be non-nil');

  if ((p1^.Typ = cLspInteger) and (p2^.Typ = cLspInteger)) then
     begin
       if (p1^.IntegerVal < p2^.IntegerVal) then
          result := -1
       else
       if (p1^.IntegerVal > p2^.IntegerVal) then
          result := 1;
     end
  else
  if ((p1^.Typ = cLspFloat) and (p2^.Typ = cLspFloat)) then
     begin
       if (p1^.FloatVal < p2^.FloatVal) then
          result := -1
       else
       if (p1^.FloatVal > p2^.FloatVal) then
          result := 1;
     end
  else
  if ((p1^.Typ = cLspInteger) and (p2^.Typ = cLspFloat)) then
     begin
       if (p1^.IntegerVal < p2^.FloatVal) then
          result := -1
       else
       if (p1^.IntegerVal > p2^.FloatVal) then
          result := 1;
     end
  else
  if ((p1^.Typ = cLspFloat) and (p2^.Typ = cLspInteger)) then
     begin
       if (p1^.FloatVal < p2^.IntegerVal) then
          result := -1
       else
       if (p1^.FloatVal > p2^.IntegerVal) then
          result := 1;
     end
  else
  if ((p1^.Typ = cLspString) and (p2^.Typ = cLspString)) then
     begin
       if (p1^.StringVal^ < p2^.StringVal^) then
          result := -1
       else
       if (p1^.StringVal^ > p2^.StringVal^) then
          result := 1;
     end
  else
     raise ELispException.Create('ErrComparison','Arguments must be number or string');
end;






function LspMathEqual(p1, p2: pNode): pNode;
begin
  result := BoolToNode(cmpNodes(p1,p2) = 0);
end;

function LspMathNotEqual(p1, p2: pNode): pNode;
begin
  result := BoolToNode(cmpNodes(p1,p2) <> 0);
end;

function LspLess(p1, p2: pNode): pNode;
begin
  result := BoolToNode(cmpNodes(p1,p2) < 0);
end;

function LspGreater(p1, p2: pNode): pNode;
begin
  result := BoolToNode(cmpNodes(p1,p2) > 0);
end;

function LspGreaterOrEqual(p1, p2: pNode): pNode;
begin
  result := BoolToNode(cmpNodes(p1,p2) >= 0);
end;

function LspLessOrEqual(p1, p2: pNode): pNode;
begin
  result := BoolToNode(cmpNodes(p1,p2) <= 0);
end;



(*----------------------------------------------------------------------------*)
(* Zufallszahlengenerator initialisieren                                      *)
(*----------------------------------------------------------------------------*)
function LspRandomize: pNode;
begin
  result := nil;
  randomize;
end;


(*----------------------------------------------------------------------------*)
(* Zufallszahl liefern. Argument ? Falls ja, dann Integerzahl zw. 0 und A - 1 *)
(* Falls kein Argument, dann Doublezahl zw. 0 und 1 liefern.                  *)
(*----------------------------------------------------------------------------*)
function LspRandom(p: pNode): pNode;
begin
  if (p = nil) then
     result := LspMakeFloat(random)
  else
     begin
       if (p^.Typ = cLspInteger) then
          result := LspMakeInteger(random(p^.IntegerVal))
       else
       if (p^.Typ = cLspFloat) then
          result := LspMakeInteger(random(trunc(p^.FloatVal)))
       else
          raise ELispException.Create('ErrNumberExpected','Argument must be number');
     end;
end;


(*----------------------------------------------------------------------------*)
(* Den Integerwert eines numerischen Knotens liefern. Falls Float, so wird    *)
(* trunc davon zurueckgegeben                                                 *)
(*----------------------------------------------------------------------------*)
function LspGetIntegerVal(p: pNode): longint;
begin
  result := 0;

  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');

  if (p^.Typ = cLspInteger) then
     result := p^.IntegerVal
  else
  if (p^.Typ = cLspFloat) then
     result := trunc(p^.FloatVal);
end;


(*----------------------------------------------------------------------------*)
(* Den Floatwert eines numerischen Knotens liefern.                           *)
(*----------------------------------------------------------------------------*)
function LspGetFloatVal(p: pNode): double;
begin
  result := 0.0;

  if (not LspNumberp(p)) then
     raise ELispException.Create('ErrNumberExpected','Argument wrong');

  if (p^.Typ = cLspInteger) then
     result := p^.IntegerVal
  else
  if (p^.Typ = cLspFloat) then
     result := p^.FloatVal;
end;

end.
