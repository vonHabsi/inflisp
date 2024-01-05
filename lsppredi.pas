(*----------------------------------------------------------------------------*)
(* Funktionen, die einen Wahrheitswert liefern                                *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsppredi;
{$O+,F+,E+,N+}

interface
uses
   lspglobl;

function BoolToNode(b: boolean): pNode;
function LspAtom(p: pNode): boolean;
function LspNull(p: pNode): boolean;
function LspNot(p: pNode): boolean;
function LspAnd(rest, Umgebung: pNode): pNode;
function LspOr(rest, Umgebung: pNode): pNode;
function LspMember(Key, Liste: pNode): pNode;
function LspBoundp(p,Umgebung: pNode): boolean;

function LspConsp(p: pNode): boolean;
function LspListp(p: pNode): boolean;
function LspSymbolp(p: pNode): boolean;
function LspNumberp(p: pNode): boolean;
function LspIntegerp(p: pNode): boolean;
function LspFloatp(p: pNode): boolean;
function LspStringp(p: pNode): boolean;
function LspArrayp(p: pNode): boolean;
function LspFilep(p: pNode): boolean;
function LspObjectp(p: pNode): boolean;
function LspStreamp(p: pNode): boolean;

function LspEq(p1, p2: pNode): boolean;
function LspEql(p1, p2: pNode): boolean;
function LspEqual(p1, p2: pNode): boolean;
function LspIf(Wenn, Dann, Sonst, Umgebung: pNode): pNode;

implementation
uses
   lspinit, lspbasic, lsperr, lsplists, lspmain;



function BoolToNode(b: boolean): pNode;
begin
  if (b) then
     BoolToNode := cLspT
  else
     BoolToNode := nil;
end;



function LspAtom(p: pNode): boolean;
begin
  if (p = nil) then
     LspAtom := true
  else
     LspAtom := (p^.Typ = cLspSymbol ) or
                (p^.Typ = cLspInteger) or
                (p^.Typ = cLspFloat  ) or
                (p^.Typ = cLspString ) or
                (p^.Typ = cLspFile   ) or
                (p^.Typ = cLspObject );
end;



function LspNull(p: pNode): boolean;
begin
  result := p = nil;
end;

function LspNot(p: pNode): boolean;
begin
  result := p = nil;
end;



function LspAnd(rest, Umgebung: pNode): pNode;
   var laeufer : pNode;
       ergebnis: pNode;
   begin
     laeufer  := rest;
     ergebnis := cLspT;
     while (ergebnis <> nil) and (laeufer <> nil) do
        begin
          ergebnis := LspEval(LspCar(laeufer),Umgebung);
          laeufer := LspCdr(laeufer);
        end;
     LspAnd := ergebnis;
   end;



function LspOr(rest, Umgebung: pNode): pNode;
var laeufer : pNode;
    ergebnis: pNode;
begin
  laeufer  := rest;
  ergebnis := nil;
  while (ergebnis = nil) and (laeufer <> nil) do
     begin
       ergebnis := LspEval(LspCar(laeufer),Umgebung);
       laeufer := LspCdr(laeufer);
     end;
  LspOr := ergebnis;
end;




(*----------------------------------------------------------------------------*)
(* Eigentlich sollte die Member-Funktion mit eql als Testfunktion arbeiten.   *)
(* Aber heute brauche ich zufaellig gerade Equal                              *)
(*----------------------------------------------------------------------------*)
function LspMember(Key, Liste: pNode): pNode;
var laeufer: pNode;
begin
  if (not LspListp(Liste)) then
     raise ELispException.Create('ErrListExpected','MEMBER, list');

  laeufer := Liste;
  while (laeufer <> nil) do
     begin
       if (LspEqual(laeufer^.CarVal,Key)) then
          begin
            LspMember := laeufer;
            exit;
          end;
       laeufer := laeufer^.CdrVal;
     end;

  result := nil;
end;



function LspListp(p: pNode): boolean;
begin
  if (p = nil) then
     LspListp := true
  else
     LspListp := (p^.Typ = cLspList);
end;



function LspBoundp(p,Umgebung: pNode): boolean;
begin
  result := LspAssoc(p,Umgebung) <> nil;
end;



function LspConsp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspList);
end;


function LspSymbolp(p: pNode): boolean;
begin
  if (p = nil) then
     result := true
  else
     result := (p^.Typ = cLspSymbol);
end;


function LspNumberp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspInteger) or (p^.Typ = cLspFloat);
end;


function LspIntegerp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspInteger);
end;



function LspFloatp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspFloat);
end;



function LspStringp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspString);
end;



function LspArrayp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspArray);
end;



function LspFilep(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspFile);
end;



function LspObjectp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspObject);
end;


function LspStreamp(p: pNode): boolean;
begin
  if (p = nil) then
     result := false
  else
     result := (p^.Typ = cLspStream);
end;





function LspEq(p1, p2: pNode): boolean;
begin
  result := p1 = p2;
end;



function LspEql(p1, p2: pNode): boolean;
var N1,N2: tNode;
   begin
     if (p1 = p2) then
        LspEql := true
     else
     if (p1 = nil) or (p2 = nil) then
        LspEql := false
     else
        begin
          N1    := p1^;
          N2    := p2^;
          if (N1.Typ <> N2.Typ) then
             LspEql := false
          else
             if (N1.Typ = cLspInteger) then
                LspEql := N1.IntegerVal = N2.IntegerVal
             else
             if (N1.Typ = cLspFloat)   then
                LspEql := N1.FloatVal = N2.FloatVal
             else
             if (N1.Typ = cLspString)  then
                LspEql := N1.StringVal^ = N2.StringVal^
             else
                LspEql := false;
        end;
   end;



function LspEqual(p1, p2: pNode): boolean;
begin
  if (p1 = p2) then
     LspEqual := true
  else
  if (LspAtom(p1) and LspAtom(p2)) then
     LspEqual := LspEql(p1,p2)
  else
  if (LspConsp(p1) and LspConsp(p2)) then
     LspEqual := LspEqual(p1^.CarVal,p2^.CarVal) and
                 LspEqual(p1^.CdrVal,p2^.CdrVal)
  else
     LspEqual := false;
end;




function LspIf(Wenn, Dann, Sonst, Umgebung: pNode): pNode;
begin
  if (LspEval(Wenn,Umgebung) <> nil) then
     LspIf := LspEval(Dann,Umgebung)
  else
     LspIf := LspEval(Sonst,Umgebung);
end;

end.
