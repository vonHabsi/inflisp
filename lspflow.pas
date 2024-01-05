(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspflow;
{$O+,F+}

interface
uses
   lspglobl;

function LspLambda(Body, Umgebung: pNode): pNode;
function LspMacro(Rumpfliste, Argumente, Umgebung: pNode): pNode;
function LspBackQuote(Ausdruck, Umgebung: pNode): pNode;

implementation
uses
   lspmain, lspbasic, lspinout, lspcreat, lspLists, lspinit, lsppredi,
   lsperr;

function LspLambda(Body, Umgebung: pNode): pNode;
   var laeufer: pNode;
       LocalE : pNode;
   begin
     LspLambda := nil;

     LocalE := Umgebung;
     LocalE := LspCons(LspList2(cLspLambda,Body),LocalE); (* GC-Trick *)

     laeufer := Body;
     while laeufer <> nil do
        begin
          LspLambda := LspEval(laeufer^.CarVal,LocalE);
          laeufer   := laeufer^.CdrVal;
        end;
   end;


function LspMacro(Rumpfliste, Argumente, Umgebung: pNode): pNode;
   var laeufer: pNode;
       LocalE : pNode;
   begin
     LspMacro := nil;

     LocalE := Umgebung;
     LocalE := LspCons(LspList2(cLspMacro,Rumpfliste),LocalE); (* GC-Trick *)
     LocalE := LspBindParameters(LspCar(Rumpfliste),Argumente,LocalE);

     laeufer := LspCdr(Rumpfliste);
     while laeufer <> nil do
        begin
          LspMacro := LspEval(LspEval(laeufer^.CarVal,LocalE),LocalE);
          laeufer  := laeufer^.CdrVal;
        end;
   end;










function LspBackQuote(Ausdruck, Umgebung: pNode): pNode;
   begin
     if LspAtom(Ausdruck) then
        LspBackQuote := Ausdruck
     else
        if (LspCar(Ausdruck) = cLspComma) then
           LspBackQuote := LspEval(LspCadr(Ausdruck),Umgebung)
     else
        if LspListp(LspCar(Ausdruck)) and (LspCaar(Ausdruck) = cLspCommaAt) then
           LspBackQuote := LspAppend2(LspEval(LspCadar(Ausdruck),Umgebung),
                                      LspCdr(Ausdruck))
     else
        LspBackQuote := LspCons(LspBackquote(LspCar(Ausdruck),Umgebung),
                                LspBackQuote(LspCdr(Ausdruck),Umgebung));
   end;

end.
