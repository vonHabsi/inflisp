(*----------------------------------------------------------------------------*)
(*  Tips zum Debuggen:                                                        *)
(*  Ein beliebter Fehler ist, in irgendeiner Funktion einen lokalen Knoten    *)
(*  mittels LspNew zu allozieren. Den darf man nicht wieder freigeben, das    *)
(*  macht das Lisp-System auf jeden Fall beim Beenden. Achtung: auch GC kann  *)
(*  einen lokalen Knoten freigeben, dann wird er ungültig. Deswegen muss man  *)
(*  ihn ggf. schuetzen mit LspLockNodeAddress und LspUnlockNodeAddress.       *)
(*  Falls beim Beenden von Lisp ein Fehler beim Freigeben eines Knotens       *)
(*  auftritt, kann man ihn so einkreisen: man fuege in TNode eine neue        *)
(*  Variable zaehler ein. Bei jedem LspNew wird ein groesserer Zaehlerwert    *)
(*  mitgegeben. Beim LspDispose logge man die Nummern in ein File, dann       *)
(*  weiss man, welcher Knoten Probleme macht. Dann setzte man in LspNew       *)
(*  einen Breakpoint, falls ein Knoten mit der Nummer alloziert wird.         *)
(*  Nun kann man in der Delphi-IDE den Aufruf-Stack anzeigen lassen.          *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspCreat;
{$O+,F+,E+,N+}



interface
uses
   Classes,
   lspglobl;

type
   TFlagNumber = (fnGC, fnTest);

function  LspTypeToS(Typ: integer): ShortString;
procedure EnableBitOfFlag(p: pNode; bitnr: TFlagNumber);
procedure DisableBitOfFlag(p: pNode; bitnr: TFlagNumber);


procedure LspNew(var p: pNode);
procedure LspDispose(var p: pNode);

function  LspMakeSymbol(s: ShortString): pNode;
function  LspMakeSym   (p: pNode ): pNode;
function  LspMakeInteger(l: longint): pNode;
function  LspMakeFloat(d: double): pNode;
function  LspMakeStream(s: TStream): pNode;
function  LspMakeString(s: ShortString): pNode;

function  LspGenSym: pNode;
function  LspCons(Head,Tail: pNode): pNode;

procedure LspLockGc;
procedure LspUnlockGC;

function  LspGC(Umgebung: pNode): pNode;
procedure DestroyAllObjects;
function  LspSetf(Adresse,Wert,Umgebung: pNode): pNode;

implementation
uses
   sysutils,
   strng, lspbasic, lsppredi, lspmain, lsplists, lspinout, lspinit,
   lsperr, lspmath, lspobjct, lsparray;



const
   GcIsLocked: boolean = false;

(*----------------------------------------------------------------------------*)
(* Den Lisp-Datentyp als String ausgeben                                      *)
(*----------------------------------------------------------------------------*)
function LspTypeToS(Typ: integer): ShortString;
begin
  case Typ of
      cLspSymbol : result := 'Symbol';
      cLspList   : result := 'List';
      cLspFloat  : result := 'Float';
      cLspInteger: result := 'Integer';
      cLspString : result := 'String';
      cLspArray  : result := 'Array';
      cLspFile   : result := 'File';
      cLspObject : result := 'Object';
      cLspStream : result := 'Delphi-Stream';
      else         result := '???' + IntToStr(Typ) + '???'
  end;
end;


(*----------------------------------------------------------------------------*)
(* Jeder Lisp-Knoten hat ein Flag-Byte, wo z.B. Garbage-Collection-Infos      *)
(* gespeichert werden koennen: 76543210                                       *)
(*----------------------------------------------------------------------------*)
procedure EnableBitOfFlag(p: pNode; bitnr: TFlagNumber);
begin
  p^.Flags := p^.Flags or (1 shl ord(bitnr));
end;



procedure DisableBitOfFlag(p: pNode; bitnr: TFlagNumber);
begin
  p^.Flags := p^.Flags and not(1 shl ord(bitnr));
end;



(*-------------------------------------------------------------------------*)
(* Eigene Freispeicherverwaltung                                           *)
(*-------------------------------------------------------------------------*)
procedure LspNew(var p: pNode);
begin
  new(p);
  p^.Typ              := 99;
  p^.Flags            := 0;
  p^.AllObj           := MainTask.AllObjects;
  MainTask.AllObjects := p;
end;


(*----------------------------------------------------------------------------*)
(* Einen Knoten freigeben. Falls es sich um eine komplexe Datenstruktur mit   *)
(* weiteren Verknuepfungen handelt, auch Unterstrukturen freigeben.           *)
(*----------------------------------------------------------------------------*)
procedure LspDispose(var p: pNode);
begin
  if (p = nil) then
     raise ELispException.Create('ErrNonNilExpressionExpected','Dispose');

  if (p^.Typ = cLspArray) then
     p^.ArrayVal.Free;
  if (p^.Typ = cLspFile) then
     dispose(p^.FileVal);
  if (p^.Typ = cLspSymbol) then
     dispose(p^.SymbolVal);
  if (p^.Typ = cLspString) then
     dispose(p^.StringVal);
  if (p^.Typ = cLspObject) then
     TLspObject(p^.ObjectVal).Free;
  (*  if (p^.Typ = cLspNodeAddress) then *)

  (*--- Wenn mehr Erfahrung da ist, ueberlegen, ob dies richtig ist: ---*)
  if (p^.Typ = cLspStream) then
     TLspObject(p^.StreamVal).Free;
  fillchar(p^,sizeof(p^),0);
  dispose(p);
end;



(*-------------------------------------------------------------------------*)
(* Einen String zu einem Symbol-Knoten machen. Es ist zu beachten, dass zu *)
(* jedem Symbolstring nur genau ein Knoten existieren darf, sodass man nur *)
(* die Knotenzeiger (Typ pNode) vergleichen muss, nicht aber die Strings,  *)
(* um die Gleichheit zweier Symbole zu ueberpruefen.                       *)
(*-------------------------------------------------------------------------*)
function LspMakeSymbol(s: ShortString): pNode;
var p       : pNode;
    gefunden: boolean;
    laeufer : pNode;
begin
  result := nil;
  s := AnsiUppercase(s);
  (*--- gibt es das Symbol schon in der globalen Liste ? ---*)
  gefunden := false;
  laeufer := MainTask.GlobalSymbolList;
  while ((laeufer <> nil) and not gefunden) do
     begin
       p := laeufer^.CarVal;
       if (p^.SymbolVal^ = s) then
          begin
            result   := p;
            gefunden := true;
          end
       else
          laeufer := laeufer^.CdrVal;
     end;

  if (not gefunden) then
     begin
       LspNew(p);

       new(p^.SymbolVal);
       p^.Typ        := cLspSymbol;
       p^.SymbolVal^ := s;

       MainTask.GlobalSymbolList := LspCons(p,MainTask.GlobalSymbolList);
       result := p;
     end;
end;






(*----------------------------------------------------------------------------*)
(* Aus einem String-Knoten ein Symbol machen                                  *)
(*----------------------------------------------------------------------------*)
function LspMakeSym(p: pNode): pNode;
begin
  if (not LspStringp(p)) then
     raise ELispException.Create('ErrStringExpected','MAKE-SYM');

  result := LspMakeSymbol(p^.StringVal^);
end;



(*----------------------------------------------------------------------------*)
(* Aus einer Longint-Zahl einen Lisp-Integer-Knoten erzeugen                  *)
(*----------------------------------------------------------------------------*)
function LspMakeInteger(l: longint): pNode;
var p: pNode;
begin
  LspNew(p);
  p^.Typ        := cLspInteger;
  p^.IntegerVal := l;
  result := p;
end;



function LspMakeFloat(d: double): pNode;
var p: pNode;
begin
  LspNew(p);
  p^.Typ      := cLspFloat;
  p^.FloatVal := d;
  result      := p;
end;



(*----------------------------------------------------------------------------*)
(* Aus einem Delphi-Stream einen Lisp--Knoten erzeugen                        *)
(*----------------------------------------------------------------------------*)
function LspMakeStream(s: TStream): pNode;
var p: pNode;
begin
  LspNew(p);
  p^.Typ       := cLspStream;
  p^.StreamVal := s;
  result       := p;
end;



(*----------------------------------------------------------------------------*)
(* Aus einem Pascal-String einen Lisp-String erzeugen.                        *)
(*----------------------------------------------------------------------------*)
function LspMakeString(s: ShortString): pNode;
var p: pNode;
begin
  LspNew(p);
  new(p^.StringVal);
  p^.Typ        := cLspString;
  p^.StringVal^ := s;
  result        := p;
end;


(*
function LspMakeObject(): pNode;
var p: pNode;
begin
  LspNew(p);
     tempTest := new(PSound,Init);
     LspNew(temp);
     temp^.Typ := cLspObject;
     temp^.ObjectVal := tempTest;
     tempTest^.Env := Umgebung;
     LspSetq(cLspTest,temp,Umgebung);
end;
Ü*)


function LspGenSym: pNode;
begin
  LspGenSym := LspMakeSymbol('G'+l2s0(MainTask.GenSymNumber,0));
  inc(MainTask.GenSymNumber);
end;





function LspCons(Head,Tail: pNode): pNode;
var p: pNode;
begin
  LspNew(p);
  p^.Typ    := cLspList;
  p^.CarVal := Head;
  p^.CdrVal := Tail;
  result    := p;
end;



(*----------------------------------------------------------------------------*)
(* Einige Stapel-Operationen fuer Garbage-Collection                          *)
(*----------------------------------------------------------------------------*)
procedure InitStack(var s: pNode);
begin
  s := nil;
end;



function IsEmpty(s: pNode): boolean;
begin
  IsEmpty := s = nil;
end;



procedure Push(Element: pNode; var s: pNode);
var neu: pNode;
begin
  new(neu);
  neu^.CarVal := Element;
  neu^.CdrVal := s;
  s := neu;
end;



procedure Pop(var Element,s: pNode);
var h: pNode;
begin
  if (not IsEmpty(s)) then
     begin
       h := s;
       Element := s^.CarVal;
       s := s^.CdrVal;
       dispose(h);
     end
  else
     Element := nil;
end;



(*----------------------------------------------------------------------------*)
(* Eine Lisp-Datenstruktur markieren (und alle Unterstrukturen)               *)
(*----------------------------------------------------------------------------*)
procedure Markiere(p: pNode);
var Stapel: pNode;
    i     : longint;
    pObj  : TLspObject;
begin
  InitStack(Stapel);
  Push(p,Stapel);

  while (not IsEmpty(Stapel)) do
     begin
       (*--- Oberstes Element vom Stapel runternehmen ---*)
       Pop(p,Stapel);
       (*--- Dieses Element markieren ---*)
       if (p <> nil) then
          EnableBitOfFlag(p,fnGC);
       (*--- Cons-Zelle ---------------------------------------------------*)
       if ((p <> nil) and (p^.Typ = cLspList)) then
          begin
            if (p^.CarVal <> nil) and (p^.CarVal^.Flags = 0) then
               Push(p^.CarVal,Stapel);
            if (p^.CdrVal <> nil) and (p^.CdrVal^.Flags = 0) then
               Push(p^.CdrVal,Stapel);
          end
       else
       (*--- Array --------------------------------------------------------*)
       if ((p <> nil) and (p^.Typ = cLspArray)) then
          begin
            for i := 0 to p^.Size - 1 do
                if (LspAref(p,LspMakeInteger(i)) <> nil) and
                   (LspAref(p,LspMakeInteger(i))^.Flags = 0) then
                   Push(LspAref(p,LspMakeInteger(i)),Stapel);
          end
       else
       (*--- Inflisp-Objekt -----------------------------------------------*)
       if ((p <> nil) and (p^.Typ = cLspObject)) then
          begin
            pObj := p^.ObjectVal as TLspObject;
            if ((pObj.Parent <> nil) and
                (pObj.Parent^.Flags = 0)) then
               Push(pObj.Parent,Stapel);
            if ((pObj.Variablen <> nil) and
                (pObj.Variablen^.Flags = 0)) then
               Push(pObj.Variablen,Stapel);
            if ((pObj.Methoden <> nil) and
                (pObj.Methoden^.Flags = 0)) then
               Push(pObj.Methoden,Stapel);
            if ((pObj.Env <> nil) and
                (pObj.Env^.Flags = 0)) then
               Push(pObj.Env,Stapel);
          end
       else
       (*--- Zeiger auf einen Knoten ? ---------------------------------------*)
       if ((p <> nil) and (p^.Typ = cLspNodeAddress)) then
          begin
          (*
            xx1 := p^.NodeAddressVal <> nil;
            xx2 := (p^.NodeAddressVal^  <> nil);
            xx4 := (p^.NodeAddressVal^^.Flags = 0);*)

            if ((p^.NodeAddressVal <> nil)  and
                (p^.NodeAddressVal^ <> nil) and
                (p^.NodeAddressVal^^.Flags = 0)) then
               Push(p^.NodeAddressVal^,Stapel);
          end
       else
     end;
end;



procedure LspLockGC;
begin
  GcIsLocked := true;
end;

procedure LspUnLockGC;
begin
  GcIsLocked := false;
end;




(*----------------------------------------------------------------------------*)
(* Garbage Collection. Zuerst alle Objekte demarkieren. Dann alle erreichba-  *)
(* ren Objekte markieren. Dann alle nichtmarkierten Objekte freigeben.        *)
(*----------------------------------------------------------------------------*)
function LspGC(Umgebung: pNode): pNode;
var laeufer    : pNode;
    freizugeben: pNode;
begin
  result := nil;
  (*--- Hier duerfte eigentlich nur zu Testzwecken rausgesprungen werden ---*)
  if (GcIsLocked) then
     exit;


  (*--- Phase 1: ALLE Objekte demarkieren ---*)
  laeufer := MainTask.AllObjects;
  while (laeufer <> nil) do
     begin
       DisableBitOfFlag(laeufer,fnGC);
       laeufer := laeufer^.AllObj;
     end;

  (*--- Phase 2: Alle erreichbaren Objekte markieren ---*)
  Markiere(Umgebung);
  Markiere(MainTask.Environment);
  Markiere(MainTask.GlobalSymbolList);
  Markiere(MainTask.LockedNodes);

  (*--- Phase 3: Alle nichtmarkierten Objekte freigeben ---*)
  while (MainTask.AllObjects^.Flags = 0) do
     begin
       freizugeben         := MainTask.AllObjects;
       MainTask.AllObjects := MainTask.AllObjects^.AllObj;
       LspDispose(freizugeben);
     end;

  laeufer := MainTask.AllObjects;
  while (laeufer <> nil) do
     begin
       (*--- Laeufer zeigt immer auf einen gueltigen Knoten ---*)
       freizugeben := laeufer^.AllObj;   (*vielleicht (!) freizugeben*)
       if (freizugeben <> nil) then
          begin
            if (freizugeben^.Flags = 0) then
               begin
                 laeufer^.AllObj := freizugeben^.AllObj;
                 LspDispose(freizugeben);
               end
            else
               laeufer := freizugeben;
          end
       else
          laeufer := nil;
     end;
  LspGC := nil;
end;

procedure DestroyAllObjects;
var laeufer,freizugeben : pNode;
begin
  laeufer := MainTask.AllObjects;
  while (laeufer <> nil) do
     begin
       freizugeben := laeufer;
       laeufer     := laeufer^.AllObj;
       LspDispose(freizugeben);
     end;
end;



function LspSetf(Adresse,Wert,Umgebung: pNode): pNode;
var Feld,Index: pNode;
begin
  result := Wert;

  if (LspSymbolp(Adresse)) then
     LspSetq(Adresse, Wert, Umgebung)
  else
     if (LspConsp(Adresse)) then
        begin
          if (Adresse^.CarVal = cLspAref) then
             begin
               Feld  := LspEval(LspCadr(Adresse),Umgebung);
               Index := LspEval(LspCaddr(Adresse),Umgebung);
               LspSetAtIndex(Feld,Wert,LspGetIntegerVal(Index));
             end;
        end
     else
        raise ELispException.Create('ErrBadArgumentType','SETF');
end;

end.
