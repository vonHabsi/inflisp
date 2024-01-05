(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspobjct;
{$O+,F+}

interface
uses
   lspglobl;

type
   TLspObject  = class(TObject)
                   Parent    : pNode;
                   Variablen : pNode;
                   Methoden  : pNode;
                   Env       : pNode;

                   constructor Create(ParentLspObject: pNode); virtual;
                   destructor  Destroy; override;
                   function    CreateChild(Args, Environment: pNode): TLspObject; virtual;
                   function    DispatchMessage(Methode, Args, Environment: pNode): pNode; virtual;
                 end;




function LspMakeInstance(Parent, Args, Environment: pNode): pNode;
function LspDefvar(Args, Umgebung: pNode): pNode;
function LspDefmethod(Args, Umgebung: pNode): pNode;
function LspIsA(objekt1, objekt2: pNode): boolean;
function LspSend(Args, Umgebung: pNode): pNode;

implementation
uses
   dialogs,
   lspcreat, lsperr, lspinout, lspmain, lspbasic, lsppredi, lsplists,
   lspinit;



constructor TLspObject.Create(ParentLspObject: pNode);
begin
  Parent    := ParentLspObject;
  Variablen := nil;
  Methoden  := nil;
  Env       := nil;
end;



destructor TLspObject.Destroy;
begin
  inherited Destroy;
end;


(*----------------------------------------------------------------------------*)
(* Ein Nachkommen-Objekt erzeugen und einen Zeiger auf dieses zurueckliefern. *)
(* Falls ein von tLspObject abgeleitetes Objekt diese Methode nicht ableitet, *)
(* sind die mittels MAKE-INSTANCE erzeugten Nachkommen vom Typ tLspObject.    *)
(*----------------------------------------------------------------------------*)
function TLspObject.CreateChild(Args,Environment: pNode): TLspObject;
begin
  CreateChild := TLspObject.Create(nil);
end;





(*----------------------------------------------------------------------------*)
(* Nachrichtenverteiler: Zuerst schauen, ob Methode durch Lisp ueberschrieben *)
(* wurde. Danach die Methoden des Parent-Objektes absuchen.                   *)
(*----------------------------------------------------------------------------*)
function tLspObject.DispatchMessage(Methode, Args, Environment: pNode): pNode;
begin
  DispatchMessage := cLspMethodNotFound;
end;



(*----------------------------------------------------------------------------*)
(* Ein Objekt ableiten, dessen Vorfahr schon Lisp-Objekt ist (Parent).        *)
(*----------------------------------------------------------------------------*)
function LspMakeInstance(Parent, Args, Environment: pNode): pNode;
var p: TLspObject;
begin
  if ((Parent <> nil) and (Parent^.Typ <> cLspObject)) then
     raise ELispException.Create('ErrObjectOrNilExpected','MAKE-INSTANCE, Parent');

  LspNew(result);
  result^.Typ := cLspObject;

  (*--------------------------------------------------------------------*)
  (* Falls kein Parent-Objekt angegeben wurde, ist das neue Objekt ganz *)
  (* einfach vom Typ tLspObject, anderenfalls ist es vom Elterntyp      *)
  (*--------------------------------------------------------------------*)
  if (Parent = nil) then
     result^.ObjectVal := TLspObject.Create(Parent)
  else
     result^.ObjectVal := TLspObject(Parent^.ObjectVal).CreateChild(Args,Environment);

  TLspObject(result^.ObjectVal).Parent := Parent;

  if (Parent = nil) then
     TLspObject(result^.ObjectVal).Env := Environment
  else
     begin
       p := Parent^.ObjectVal as TLspObject;
       TLspObject(result^.ObjectVal).Env := p.Env;
     end;
end;



(*----------------------------------------------------------------------------*)
(* Eine Variable eines internen Objektes definieren und Wert initialisieren.  *)
(* (DEFVAR <Objekt> <Variable> <Wert>)                                        *)
(*----------------------------------------------------------------------------*)
function LspDefvar(Args, Umgebung: pNode): pNode;
var Objekt  : pNode;
    Variable: pNode;
    Wert    : pNode;
    Search  : pNode;
    pObj    : TLspObject;
begin
  Objekt   := LspEval(LspCar(Args),Umgebung);
  Variable := LspCadr(Args);
  Wert     := LspEval(LspCaddr(Args),Umgebung);

  if ((Objekt = nil) or (Objekt^.Typ <> cLspObject)) then
     raise ELispException.Create('ErrObjectExpected','DEFVAR, first argument');

  if (not LspSymbolp(Variable)) then
     raise ELispException.Create('ErrSymbolExpected','DEFVAR, variable');

  pObj := Objekt^.ObjectVal as TLspObject;

  Search := LspAssoc(Variable,pObj.Variablen);

  if (Search = nil) then
     pObj.Variablen := LspCons(LspList2(Variable,Wert),pObj.Variablen)
  else
     LspRplaca(LspLast(Search),Wert);

  pObj.Env := LspCons(LspList2(Variable,Wert),pObj.Env);

  result := Variable;
end;




(*----------------------------------------------------------------------------*)
(* Eine Methode eines internen Objektes festlegen.                            *)
(*----------------------------------------------------------------------------*)
function LspDefmethod(Args, Umgebung: pNode): pNode;
var Objekt        : pNode;
    Methode       : pNode;
    Arglist       : pNode;
    Rumpf         : pNode;
    LambdaAusdruck: pNode;
    Search        : pNode;
    pObj          : TLspObject;
begin
  Objekt   := LspEval(LspCar(Args),Umgebung);
  Methode  := LspCadr(Args);
  Arglist  := LspCaddr(Args);
  Rumpf    := LspCdddr(Args);

  if ((Objekt = nil) or (Objekt^.Typ <> cLspObject)) then
     raise ELispException.Create('ErrObjectExpected','DefMethod, first argument');

  if (not LspSymbolp(Methode)) then
     raise ELispException.Create('ErrSymbolExpected','DefMethod, method');

  pObj := Objekt^.ObjectVal as TLspObject;

  LambdaAusdruck := LspCons(cLspLambda,LspCons(Arglist,Rumpf));

  Search := LspAssoc(Methode,pObj.Methoden);
  if (Search = nil) then
     pObj.Methoden := LspCons(LspList2(Methode,LambdaAusdruck),pObj.Methoden)
  else
     LspRplaca(LspLast(Search),LambdaAusdruck);

  pObj.Env := LspCons(LspList2(Methode,LambdaAusdruck),pObj.Env);

  result := Methode;
end;




(*----------------------------------------------------------------------------*)
(* Feststellen, ob ein bestimmtes Objekt Nachkomme eines anderen Objektes ist *)
(*----------------------------------------------------------------------------*)
function LspIsA(objekt1, objekt2: pNode): boolean;
var o1: TLspObject;
begin
  result := false;

  if ((not LspObjectp(objekt1)) or (not LspObjectp(objekt2))) then
     exit;

  o1 := Objekt1^.ObjectVal as TLspObject;

  if (o1.Parent = Objekt2) then
     result := true
  else
     result := LspIsA(o1.Parent,Objekt2);
end;



(*----------------------------------------------------------------------------*)
(* Eine Methode eines Objektes aufrufen                                       *)
(*----------------------------------------------------------------------------*)
function LspSend(Args, Umgebung: pNode): pNode;
var Objekt        : pNode;
    Methode       : pNode;
    Arglist       : pNode;
    Search        : pNode;
    pObj          : TLspObject;
begin
  Objekt   := LspEval(LspCar(Args),Umgebung);
  Methode  := LspCadr(Args);
(* alt, moeglicherweise falsch Arglist  := Evaluated(LspCddr(Args),Umgebung); *)
  Arglist  := LspCddr(Args);

  (*--- Typueberpruefung --------------------------------------------------*)
  if ((Objekt = nil) or (Objekt^.Typ <> cLspObject)) then
     raise ELispException.Create('ErrObjectExpected','SEND, first argument');

  if (not LspSymbolp(Methode)) then
     raise ELispException.Create('ErrSymbolExpected','SEND, method');
  (*-----------------------------------------------------------------------*)

  pObj := Objekt^.ObjectVal as TLspObject;
  Search := LspAssoc(Methode,pObj.Env);

  if (Search <> nil) then
     result := LspEval(LspCons(LspCadr(Search),Arglist),pObj.Env)
  else
     result := pObj.DispatchMessage(Methode,Arglist,Umgebung);
end;




end.
