(*----------------------------------------------------------------------------*)
(* Funktionen, die den Inferenzmechanismus betreffen                          *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspinf;
{$O+,F+}

interface
uses
   lspglobl;


function LLspIsVariable(Args,Umgebung: pNode): pNode;
function LspIsVariable(p: pNode): boolean;
function LspMatch(Instance,Pattern,Restrictions: pNode): pNode;
function LspEvaluated(Ausdruck,Bindungen: pNode): pNode;
function LspGetVariables(Ausdruck,Bisher: pNode): pNode;


implementation
uses
   lsppredi, lspmain, lspexpct, lspstrng, lspbasic, lspinit, lsplists,
   lspcreat;



function LLspIsVariable(Args,Umgebung: pNode): pNode;
var e : pNode;
begin
  result := nil;

  e := evaluated(Args,Umgebung);
  e := LspCar(e);

  if (e = nil) or (e^.Typ <> cLspSymbol) then
     exit;

  result := BoolToNode(e^.SymbolVal^[1] = '?');
end;



function LspIsVariable(p: pNode): boolean;
begin
  result := false;
  if ((p = nil) or (p^.Typ <> cLspSymbol)) then
     exit;
  result := p^.SymbolVal^[1] = '?';
end;



function LspMatch(Instance,Pattern,Restrictions: pNode): pNode;
var temp: pNode;
begin
  if ((Instance = nil) and (Pattern = nil)) then
     begin
       LspMatch := Restrictions;
       exit;
     end;

  if ((Instance <> nil) and
      LspIsVariable(Pattern)) then
      begin
        temp := LspAssoc(Pattern,Restrictions);
        if (temp = nil) then
           LspMatch := LspCons(LspList2(Pattern,Instance),Restrictions)
        else
        if (LspEqual(Instance,LspCadr(temp))) then
           LspMatch := Restrictions
        else
           LspMatch := cLspError;
        exit;
      end;


  if (LspAtom(Instance)) then
     begin
       if (not LspAtom(Pattern)) then
          LspMatch := cLspError
       else
       if (LspIsVariable(Pattern)) then
          begin
            temp := LspAssoc(Pattern,Restrictions);
            if (temp = nil) then
               LspMatch := LspCons(LspList2(Pattern,Instance),Restrictions)
            else
            if LspEqual(Instance,LspCadr(temp)) then
               LspMatch := Restrictions
            else
               LspMatch := cLspError;
          end
       else
          begin
            if LspEqual(Instance,Pattern) then
               LspMatch := Restrictions
            else
               LspMatch := cLspError;
          end;
       exit;
     end;


  if (not LspConsp(Pattern)) then
     LspMatch := cLspError
  else
     begin
       temp := LspMatch(LspCar(Instance),LspCar(Pattern),Restrictions);
       if ((temp <> nil) and (temp^.Typ = cLspSymbol)) then
          LspMatch := cLspError
       else
          LspMatch := LspMatch(LspCdr(Instance),LspCdr(Pattern),temp);
     end;
end;



function LspEvaluated(Ausdruck,Bindungen: pNode): pNode;
var temp: pNode;
begin
  if (Ausdruck = nil) then
     LspEvaluated := nil
  else
  if (LspListp(Ausdruck)) then
     LspEvaluated := LspCons(LspEvaluated(LspCar(Ausdruck),Bindungen),
                             LspEvaluated(LspCdr(Ausdruck),Bindungen))
  else
  begin
    temp := LspAssoc(Ausdruck,Bindungen);
    if (temp <> nil) then
       LspEvaluated := LspCadr(temp)
    else
       LspEvaluated := Ausdruck;
  end;
end;



(*----------------------------------------------------------------------------*)
(* Aus einem Lisp-Ausdruck alle Variablen eindeutig liefern                   *)
(*----------------------------------------------------------------------------*)
function LspGetVariables(Ausdruck,Bisher: pNode): pNode;
var temp: pNode;
begin
  if (Ausdruck = nil) then
     result := bisher
  else
  if (LspIsVariable(Ausdruck)) then
     begin
       if (LspMember(Ausdruck,Bisher) = nil) then
          result := LspCons(Ausdruck,Bisher)
       else
          result := Bisher;
     end
  else
  if (LspAtom(Ausdruck)) then
     result := bisher
  else
     begin
       temp   := LspGetVariables(LspCar(Ausdruck),Bisher);
       result := LspGetVariables(LspCdr(Ausdruck),temp);
     end;
end;



end.
