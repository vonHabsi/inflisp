(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspmain;
{$O+,F+}

interface
uses
   lspglobl;


function MainLoop: pNode;
function LspEval(ausdruck, umgebung: pNode): pNode;
function LspSetq(variable, wert, umgebung: pNode): pNode;
function LspBindParameters(par_liste, arg_liste, umgebung: pNode): pNode;
function Evaluated(Liste, Umgebung: pNode): pNode;



implementation
uses
   lspinit, lspbasic, lsplists, lspcreat, lspinout, lsperr, lsppredi,
   lsplex, lsppars, lspmath, lspflow, lspstrng,
   lsploop, lsparray, lspobjct, lsptype, lspinf, lspkeybd,
   lsputil, lsplock
{$ifdef go}
   ,lspgo, strng
{$endif}
   ;


function LspValueOfVariable(schluessel, umgebung: pNode): pNode; forward;
function LspCond(klauseln, umgebung: pNode): pNode; forward;
function LspApply(prozedur, rest, umgebung: pNode): pNode; forward;


{$ifdef go}
var  zaehler       : longint;
{$endif}

function LspEval(ausdruck, umgebung: pNode): pNode;
begin
  if ((Ausdruck <> nil) and (Ausdruck^.Typ = cLspArray)) then
     result := ausdruck
  else
  if (LspAtom(ausdruck)) then
     begin
       if (LspNumberp(ausdruck)) then
          result := ausdruck
       else
       if (LspStringp(ausdruck)) then
          result := ausdruck
       else
          result := LspValueOfVariable(ausdruck,umgebung);
     end
  else
  if (ausdruck^.CarVal = cLspQuote) then
     result := LspCadr(ausdruck)
  else
  if (ausdruck^.CarVal = cLspBackQuote) then
     result := LspBackQuote(LspCadr(ausdruck),Umgebung)
  else
  if (ausdruck^.CarVal = cLspCond) then
     result := LspCond(LspCdr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspAnd) then
     result := LspAnd(LspCdr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspOr) then
     result := LspOr(LspCdr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspIf) then
     result := LspIf(LspCadr  (ausdruck),
                     LspCaddr (ausdruck),
                     LspCadddr(ausdruck),
                     umgebung)
  else
  if (ausdruck^.CarVal = cLspDoList) then
     result := LspDoList(LspCadr(ausdruck),LspCddr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspDoTimes) then
     result := LspDoTimes(LspCadr(ausdruck),LspCddr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspProgn) then
     result := LspProgn(LspCdr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspWhile) then
     result := LspWhile(LspCdr(ausdruck),umgebung)
  else
  if (ausdruck^.CarVal = cLspTypeOf) then
     result := LspTypeOf(LspCdr(ausdruck),umgebung)
 (*
  else
  if ausdruck^.CarVal = cLspClose then
     result := LspList4(cLspClosure,
                            LspCadr (LspCadr(ausdruck)),
                            LspCaddr(LspCadr(ausdruck)),
                            umgebung)
 *)
  else
  if (ausdruck^.CarVal = cLspSetq) then
     result := LspSetq(LspCadr(ausdruck),
                       LspEval(LspCaddr(ausdruck),umgebung),
                       umgebung)
  else
  if (ausdruck^.CarVal = cLspSetf) then
     result := LspSetf(LspCadr(ausdruck),
                       LspEval(LspCaddr(ausdruck),umgebung),
                       umgebung)
  else
  if (ausdruck^.CarVal = cLspDefun) then
     result := LspSetq(LspCadr(ausdruck),
                       LspCons(cLspLambda,LspCddr(ausdruck)),
                       umgebung)
  else
  if (ausdruck^.CarVal = cLspDefmacro) then
     result := LspSetq(LspCadr(ausdruck),
                       LspCons(cLspMacro,LspCddr(ausdruck)),
                       umgebung)
  else
  if (ausdruck^.CarVal = cLspLet) then
     result := LspLet(LspCadr(ausdruck),
                      LspCddr(ausdruck),
                      umgebung)
  else
     result := LspApply(LspCar(Ausdruck),LspCdr(Ausdruck),umgebung);
end;




(*----------------------------------------------------------------------------*)
(* Trick wegen cLspApply: alle Elemente einer Liste quotieren                 *)
(*----------------------------------------------------------------------------*)
function QuotedList(l: pNode): pNode;
var laeufer: pNode;
begin
  result := nil;

  if (not LspListp(l)) then
     exit;

  laeufer := l;
  while (laeufer <> nil) do
     begin
       result  := LspCons(LspList2(cLspQuote,LspCar(Laeufer)),result);
       laeufer := laeufer^.CdrVal;
     end;
  result := LspReverse(result);
end;




(*----------------------------------------------------------------------------*)
(* Die Liste REST ist die Argumentliste VOR Auswertung d. einzelnen Elemente. *)
(* Die Liste ARG wird nicht uebergeben, sondern in APPLY neu gebildet.        *)
(*----------------------------------------------------------------------------*)
function LspApply(prozedur, rest, umgebung: pNode): pNode;
   var temp: pNode;
   begin
     LspApply := nil;

     if (LspConsp(Prozedur) and (LspCar(prozedur) = cLspMacro)) then
        begin
          LspApply := LspMacro(LspCdr(prozedur),rest,umgebung);
          exit;
        end;




        (*
     arg := Evaluated(rest,Umgebung);
     *)



     (*----------------------------------------------------------*)
     (* Hier folgt eine Aufzaehlung aller eingebauten Funktionen *)
     (*----------------------------------------------------------*)
     if (LspAtom(prozedur) and (prozedur <> nil)) then
        begin
          if (prozedur = cLspCar) then
             LspApply := LspCar(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCdr) then
             LspApply := LspCdr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCaar) then
             LspApply := LspCaar(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCadr) then
             LspApply := LspCadr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCdar) then
             LspApply := LspCdar(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCddr) then
             LspApply := LspCddr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCaadr) then
             LspApply := LspCaadr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCadar) then
             LspApply := LspCadar(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCaddr) then
             LspApply := LspCaddr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCdddr) then
             LspApply := LspCdddr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCaddar) then
             LspApply := LspCaddar(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCadddr) then
             LspApply := LspCadddr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspCons) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspCons(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspLast) then
             LspApply := LspLast(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspMakeList) then
             LspApply := LspList(Evaluated(rest,Umgebung))
          else
          if (prozedur = cLspAppend) then
             LspApply := LspAppend(rest,umgebung)
          else
          if (prozedur = cLspCopy) then
             LspApply := LspCopy(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspReverse) then
             LspApply := LspReverse(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspRplaca) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspRplaca(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspRplacd) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspRplacd(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspAtom) then
             LspApply := BoolToNode(LspAtom(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspNull) then
             LspApply := BoolToNode(LspNull(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspNot) then
             LspApply := BoolToNode(LspNot(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspConsp) then
             LspApply := BoolToNode(LspConsp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspListp) then
             LspApply := BoolToNode(LspListp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspBoundp) then
             LspApply := BoolToNode(LspBoundp(LspCar(Evaluated(rest,Umgebung)),Umgebung))
          else
          if (prozedur = cLspEq) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := BoolToNode(LspEq(LspCar(temp),LspCadr(temp)));
             end
          else
          if (prozedur = cLspEql) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := BoolToNode(LspEql(LspCar(temp),LspCadr(temp)));
             end
          else
          if (prozedur = cLspEqual) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := BoolToNode(LspEqual(LspCar(temp),LspCadr(temp)));
             end
          else
          if (prozedur = cLspAssoc) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspAssoc(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspPlus) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspPlus(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspMinus) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspMinus(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspTimes) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspTimes(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspDivided) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspDivided(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspEinsplus) then
             LspApply := LspEinsplus(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspEinsMinus) then
             LspApply := LspEinsMinus(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspExp) then
             LspApply := LspExp(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspLn) then
             LspApply := LspLn(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSqr) then
             LspApply := LspSqr(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSqrt) then
             LspApply := LspSqrt(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspMathEqual) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspMathEqual(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspMathNotEqual) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspMathNotEqual(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspLess) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspLess(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspGreater) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspGreater(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspGreaterOrEqual) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspGreaterOrEqual(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspLessOrEqual) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspLessOrEqual(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspPrint) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspPrint(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspPrin1) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspPrin1(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspPrinc) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspPrinc(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspFlatSize) then
             LspApply := LspFlatSize(rest,Umgebung)
          else
          if (prozedur = cLspFlatc) then
             LspApply := LspFlatc(rest,Umgebung)
          else
          if (prozedur = cLspTerpri) then
             LspApply := LspTerpri(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspLoad) then
             LspApply := LspLoad(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspGC) then
             LspApply := LspGC(Umgebung)
          else
          if (prozedur = cLspLength) then
             LspApply := LspLength(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspNth) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspNth(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspNthCdr) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspNthCdr(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspRandomize) then
             LspApply := LspRandomize
          else
          if (prozedur = cLspRandom) then
             LspApply := LspRandom(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSymbolName) then
             LspApply := LspSymbolName(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspMakeSymbol) then
             LspApply := LspMakeSym(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspGensym) then
             LspApply := LspGensym
          else
          if (prozedur = cLspExit) then
             begin
               LspApply := nil;
               //               LspError := 'ErrUserBreak'; zu-tun
             end
          else
          if (prozedur = cLspEval) then
             LspApply := LspEval(LspCar(Evaluated(rest,Umgebung)),umgebung)
          else
          if (prozedur = cLspApply) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspEval(LspCons(LspCar(temp),
                                           QuotedList(LspCadr(temp))
                                  ),umgebung)
             end
          else
          if (prozedur = cLspFunCall) then
             LspApply := LspApply(LspEval(LspCar(rest),Umgebung),LspCdr(Rest),Umgebung)
          else
          if (prozedur = cLspEnvironment) then
             LspApply := umgebung
          else
          if (prozedur = cLspGlobalSymbolList) then
             LspApply := MainTask.GlobalSymbolList
          else
          if (prozedur = cLspMember) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspMember(LspCar(temp),LspCadr(temp));
             end
          else
          (*--- Inferenz-Funktionen ------------------------------------------*)
          if (prozedur = cLspIsVariable) then
             LspApply := LLspIsVariable(rest,Umgebung)
          else
          if (prozedur = cLspMatch) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspMatch(LspCar(temp),LspCadr(temp),LspCaddr(temp));
             end
          else
          if (prozedur = cLspTime) then
             LspApply := LspTime
          else
          if (prozedur = cLspEvaluated) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspEvaluated(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspGetVariables) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspGetVariables(LspCar(temp),LspCadr(temp));
             end
          else
          if (prozedur = cLspSymbolp) then
             LspApply := BoolToNode(LspSymbolp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspNumberp) then
             LspApply := BoolToNode(LspNumberp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspIntegerp) then
             LspApply := BoolToNode(LspIntegerp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspFloatp) then
             LspApply := BoolToNode(LspFloatp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspStringp) then
             LspApply := BoolToNode(LspStringp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspArrayp) then
             LspApply := BoolToNode(LspArrayp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspFilep) then
             LspApply := BoolToNode(LspFilep(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspObjectp) then
             LspApply := BoolToNode(LspObjectp(LspCar(Evaluated(rest,Umgebung))))
          else
          if (prozedur = cLspAref) then
             LspApply := LspAref(LspCar(Evaluated(rest,Umgebung)),LspCadr(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspMakeArray) then
             LspApply := LspMakeArray(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspClearScreen) then
             LspApply := LspClearScreen
          else
          if (prozedur = cLspGetKey) then
             LspApply := LspGetKey
          else
          if (prozedur = cLspMakeInstance) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspMakeInstance(LspCar(temp),LspCdr(temp),Umgebung);
             end
          else
          if (prozedur = cLspIsA) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := BoolToNode(LspIsA(LspCar(temp),LspCadr(temp)));
             end
          else
          if (prozedur = cLspDefvar) then
             LspApply := LspDefvar(rest,Umgebung)
          else
          if (prozedur = cLspDefmethod) then
             LspApply := LspDefmethod(rest,Umgebung)
          else
          if (prozedur = cLspSend) then
             LspApply := LspSend(rest,Umgebung)
          else
          if (prozedur = cLspOpenI) then
             LspApply := LspOpenI(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspOpenO) then
             LspApply := LspOpenO(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspClose) then
             LspApply := LspClose(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspFilepos) then
             LspApply := LspFilepos(LspCar (Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSeek) then
             LspApply := LspSeek(LspCar (Evaluated(rest,Umgebung)),
                                 LspCadr(Evaluated(rest,Umgebung))
                                )
          else
          if (prozedur = cLspRead) then
             begin
               temp     := Evaluated(rest,umgebung);
               LspApply := LspRead(LspCar(temp));
             end
          else
          if (prozedur = cLspReadLine) then
             LspApply := LspReadLine(rest,Umgebung)
          else
          if (prozedur = cLspReadChar) then
             LspApply := LspReadChar(rest,Umgebung)
          else
          if (prozedur = cLspWriteChar) then
             LspApply := LspWriteChar(rest,Umgebung)
          else
          if (prozedur = cLspChar) then
             LspApply := LLspChar(rest,Umgebung)
          else
          if (prozedur = cLspString1) then
             LspApply := LLspString(rest,Umgebung)
          else
          if (prozedur = cLspStrcat) then
             LspApply := LLspStrcat(rest,Umgebung)
          else
          if (prozedur = cLspSubstr) then
             LspApply := LLspSubstr(rest,Umgebung)
          else
          if (prozedur = cLspMapCar) then
             LspApply := LspMapCar(rest,Umgebung)
          else
          if (prozedur = cLspQuickSort) then
             LspApply := LspQuickSort(rest,Umgebung)
          else
          if (prozedur = cLspBubbleSort) then
             LspApply := LspBubbleSort(rest,Umgebung)
          (*--- Anwendungsabhaengige Prozeduren ----------------------------------------*)
          {$ifdef go}
          else
          if (prozedur = cLspPatternMatching) then
             LspApply := LspPatternMatching
          else
          if (prozedur = cLspBerechneGebiet) then
             LspApply := LspBerechneGebiet
          else
          if (prozedur = cLspTerritory) then
             LspApply := LspTerritory(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspLiberties) then
             LspApply := LspLiberties(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspEscapeMoves) then
             LspApply := LspEscapeMoves(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspShicho) then
             LspApply := LspShicho(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSinnvoll) then
             LspApply := LspSinnvoll(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspColor) then
             LspApply := LspColor(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspZugvorschlag) then
             LspApply := LspZugvorschlag(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspPClass) then
             LspApply := LspPClass(LspCar(Evaluated(rest,Umgebung)))
          else
          if prozedur = cLspClasses then
             LspApply := LspClasses(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspTranskoord) then
             LspApply := LspTranskoord(LspCar  (Evaluated(rest,Umgebung)),
                                       LspCadr (Evaluated(rest,Umgebung)),
                                       LspCaddr(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspOutMsg) then
             LspApply := LspOutMsg(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspKetten) then
             LspApply := LspKetten
          else
          if (prozedur = cLspNeutral) then
             LspApply := LspNeutral
          else
          if (prozedur = cLspLegal) then
             LspApply := LspLegal(LspCar(Evaluated(rest,Umgebung)),LspCadr(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSetStone) then
             LspApply := LspSetStone(LspCar(Evaluated(rest,Umgebung)),LspCadr(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspName) then
             LspApply := LspName(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspShow) then
             LspApply := LspShow(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspZobrist) then
             LspApply := LspZobrist(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspConnected) then
             LspApply := LspConnected(LspCar(Evaluated(rest,Umgebung)),LspCadr(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspWeakGroups) then
             LspApply := LspWeakGroups
          else
          if (prozedur = cLspPointLiberties) then
             LspApply := LspPointLiberties(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspTouches) then
             LspApply := LspTouches(LspCar(Evaluated(rest,Umgebung)),LspCadr(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspBlackConnected) then
             LspApply := LspBlackConnected
          else
          if (prozedur = cLspWhiteConnected) then
             LspApply := LspWhiteConnected
          else
          if (prozedur = cLspPushBoard) then
             LspApply := LspPushBoard
          else
          if (prozedur = cLspPopBoard) then
             LspApply := LspPopBoard
          else
          if prozedur = cLspZVal then
             LspApply := LspZVal
          else
          if prozedur = cLspNeighbours then
             LspApply := LspNeighbours(LspCar(Evaluated(rest,Umgebung)))
          else
          if prozedur = cLspStrength then
             LspApply := LspStrength(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspBlackTerritory) then
             LspApply := LspBlackTerritory
          else
          if (prozedur = cLspWhiteTerritory) then
             LspApply := LspWhiteTerritory
          else
          if (prozedur = cLspHoehe) then
             LspApply := LspHoehe(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspSetMouse) then
             LspApply := LspSetMouse(LspCar(Evaluated(rest,Umgebung)))
          else
          if (prozedur = cLspNeuralValue) then
             LspApply := LspNeuralValue(LspCar(Evaluated(rest,Umgebung)),LspCadr(Evaluated(rest,Umgebung)))
          {$endif}
          else
          if (LspSymbolp(Prozedur)) then
             LspApply := LspApply(LspEval(prozedur,umgebung),rest,umgebung);
        end
     (*----------------------------------------------------------*)
     else
     (*
        if LspCar(prozedur) = cLspLambda then
           LspApply := LspEval(LspCaddr(prozedur),
                               LspBindParameters(LspCadr(prozedur),
                               Evaluated(rest,umgebung),
                               umgebung))
     *)
        if (LspCar(prozedur) = cLspLambda) then
           LspApply := LspLambda(LspCddr(prozedur),
                                 LspBindParameters(LspCadr(prozedur),
                                                   Evaluated(Rest,Umgebung),
                                                   umgebung))
     else
        if (LspCar(prozedur) = cLspClosure) then
           LspApply := LspEval(LspCaddr(prozedur),
                               LspBindParameters(LspCadr(prozedur),
                                                 Evaluated(Rest,Umgebung),
                                                 LspCadddr(prozedur)))
     (*
     else
        begin
          LspErrorExpression := LspCar(prozedur);
          LspError := cLspUnknownFunctionSymbol;
          LspApply := nil;
        end;
      *)
   end;




function MainLoop: pNode;
var lex     : tLex_obj;
    Eingabe : tTastaturInputObjekt;
    ende    : boolean;
begin
  Eingabe.Init;
  lex.init(@Eingabe);

  try
     ende := false;
     while (not ende) do
       try
          repeat
            LspPrint(LspEval(GetExpression(@lex),MainTask.Environment),MainTask.LspStandardOutput);
            LspTerpri(MainTask.LspStandardOutput);
          until (lex.lookahead.token = cLspEndOfLineToken);
       except
          on e: ELispException do
             if (e.GetSym = 'ErrUserBreak') then
                ende := true;
       end;
  finally
     lex.done;
     Eingabe.Done;
  end;

  result := nil;
end;


function LspBindParameters(par_liste, arg_liste, umgebung: pNode): pNode;
begin
  if (LspCar(par_liste) = cLspRest) then
     result := LspCons(LspList2(LspCadr(par_liste),arg_liste),
                                  Umgebung)
  else
  if (LspCar(par_liste) = cLspOptional) then
     begin
       if (LspCddr(par_liste) <> nil) then
          result := LspCons(LspList2(LspCadr(par_liste),
                                                LspCar(arg_liste)),
                                       LspBindParameters(LspCons(cLspOptional,LspCddr(par_liste)),
                                                         LspCdr(arg_liste),
                                                         umgebung
                                                        ))
       else
          result := LspCons(LspList2(LspCadr(par_liste),
                                                LspCar(arg_liste)),
                                       Umgebung);
     end
  else
  if (LspNull(par_liste) or LspNull(arg_liste)) then
     result := umgebung
  else
     result := LspCons(LspList2(LspCar(par_liste),
                                           LspCar(arg_liste)),
                                  LspBindParameters(LspCdr(par_liste),
                                                    LspCdr(arg_liste),
                                                    umgebung
                                                   ));
end;






(*----------------------------------------------------------------------------*)
(* Den Wert einer Variablen holen.                                            *)
(*----------------------------------------------------------------------------*)
function LspValueOfVariable(schluessel, umgebung: pNode): pNode;
var AssocResult: pNode;
    sym        : string;
begin
  AssocResult := LspAssoc(schluessel,umgebung);
  if (AssocResult = nil) then
     begin
       if (LspSymbolP(schluessel)) then
          sym := LspGetStringVal(LspSymbolName(schluessel))
       else
          sym := 'No bound value';
       raise ELispException.Create('ErrUnboundSymbol',sym);
     end;
  result := LspCadr(AssocResult);
end;

(*----------------------------------------------------------------------------*)
(* Einer Variable einen Wert zuweisen                                         *)
(*----------------------------------------------------------------------------*)
function LspSetq(variable, wert, umgebung: pNode): pNode;
var eintrag: pNode;
begin
  eintrag := LspAssoc(variable,umgebung);
  if (eintrag <> nil) then
     LspRplaca(LspCdr(eintrag),Wert)
  else
     LspRplacd(LspLast(umgebung),LspList1(LspList2(variable,wert)));
  result := wert;
end;










function LspCond(klauseln, umgebung: pNode): pNode;
begin
  if (LspNull(klauseln)) then
     result := nil
  else
  if (LspEval(LspCaar(klauseln), umgebung) <> nil) then
     result := LspEval(LspCadar(klauseln),umgebung)
  else
     result := LspCond(LspCdr(klauseln),umgebung);
end;





(*----------------------------------------------------------------------------*)
(* Eine Liste Elementweise evaluieren                                         *)
(*----------------------------------------------------------------------------*)
function Evaluated(Liste, Umgebung: pNode): pNode;
var laeufer,h: pNode;
begin
  result  := nil;
  h       := nil;
  laeufer := Liste;

  LspLockNodeAddress(@result);
  LspLockNodeAddress(@h);
  LspLockNodeAddress(@laeufer);

  try
     while (laeufer <> nil) do
        begin
          h := LspCons(LspEval(LspCar(laeufer),umgebung),nil);
          if (result = nil) then
             result := h
          else
             LspRplacd(LspLast(result),h);
          laeufer := LspCdr(laeufer);
        end;
  finally
     LspUnlockNodeAddress(@result);
     LspUnlockNodeAddress(@h);
     LspUnlockNodeAddress(@laeufer);
  end;
end;


end.
