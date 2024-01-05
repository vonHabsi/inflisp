(*----------------------------------------------------------------------------*)
(* Listenverarbeitende und listenliefernde Funktionen.                        *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsplists;
{$O+,F+}

interface
uses
   lspglobl;

function Quoted(p: pNode): pNode;
function LspReverse(Liste: pNode): pNode;
function LspList(Rest: pNode): pNode;
function LspList1(p: pNode): pNode;
function LspList2(p1,p2: pNode): pNode;
function LspList3(p1,p2,p3: pNode): pNode;
function LspList4(p1,p2,p3,p4: pNode): pNode;
function LspCopy(p: pNode): pNode;
function LspLength(p: pNode): pNode;
function LspNth(n,l: pNode): pNode;
function LspNthCdr(n,l: pNode): pNode;
function LspAppend2(l1,l2: pNode): pNode;
function LspAppend(Args,Umgebung: pNode): pNode;
function LspRplaca(x,y: pNode): pNode;
function LspRplacd(x,y: pNode): pNode;
function LspAssoc(key, list: pNode): pNode;
function LspMapCar(Args,Umgebung: pNode): pNode;
function LspListToArray(l: pNode): pNode;
function LspArrayToList(a: pNode): pNode;
function LspQuickSort(Args,Umgebung: pNode): pNode;
function LspBubbleSort(Args,Umgebung: pNode): pNode;

implementation
uses
   lspcreat, lspbasic, lsppredi, lsperr, lspinout, lspmath, lspstrng,
   lspmain, lspexpct, lspinit, lsparray, lsplock,
   strng;


function Quoted(p: pNode): pNode;
begin
  result := LspList2(cLspQuote,p);
end;



(*----------------------------------------------------------------------------*)
(* Eine Liste umkehren                                                        *)
(*----------------------------------------------------------------------------*)
function LspReverse(Liste: pNode): pNode;
var laeufer : pNode;
    ergebnis: pNode;
begin
  if (not LspListp(Liste)) then
     raise ELispException.Create('ErrListExpected','');

  ergebnis := nil;
  laeufer  := Liste;
  while (laeufer <> nil) do
     begin
       ergebnis := LspCons(LspCar(laeufer),ergebnis);
       laeufer := laeufer^.CdrVal;
     end;

  result := ergebnis;
end;



function LspList(Rest: pNode): pNode;
begin
  if (not LspListp(Rest)) then
     raise ELispException.Create('ErrListExpected','');

  result := Rest;
end;



function LspList1(p: pNode): pNode;
begin
  result := LspCons(p, nil);
end;



function LspList2(p1,p2: pNode): pNode;
begin
  result := LspCons(p1, LspCons(p2, nil));
end;


function LspList3(p1,p2,p3: pNode): pNode;
begin
  result := LspCons(p1,LspCons(p2,LspCons(p3,nil)));
end;


function LspList4(p1,p2,p3,p4: pNode): pNode;
begin
  result := LspCons(p1,LspCons(p2,LspCons(p3,LspCons(p4,nil))));
end;



(*----------------------------------------------------------------------------*)
(* Sonderbehandlung fuer Arrays: elementweise kopieren                        *)
(*----------------------------------------------------------------------------*)
function CopyOfArray(p: pNode): pNode;
var i: longint;
begin
  if (not LspArrayp(p)) then
     raise ELispException.Create('ErrArrayExpected','');

  result := LspMakeArray(LspLength(p));

  for i := 0 to p^.Size - 1 do
      LspSetAtIndex(result,LspGetAtIndex(p,i),i);
end;



(*----------------------------------------------------------------------------*)
(* Einen Ausdruck rekursiv kopieren                                           *)
(*----------------------------------------------------------------------------*)
function LspCopy(p: pNode): pNode;
begin
  if (LspArrayp(p)) then
     result := CopyOfArray(p)
  else
  if (LspAtom(p)) then
     result := p
  else
  if (LspListp(p)) then
     result := LspCons(LspCopy(p^.CarVal),LspCopy(p^.CdrVal))
  else
     raise ELispException.Create('ErrCannotCopy','Illegal type of argument');
end;



(*----------------------------------------------------------------------------*)
(* Laenge einer Liste, eines Strings oder eines Arrays berechnen              *)
(*----------------------------------------------------------------------------*)
function LspLength(p: pNode): pNode;
var laeufer: pNode;
    res    : longint;
begin
  Res  := 0;

  if (LspListp(p)) then
     begin
       laeufer := p;
       while (laeufer <> nil) do
          begin
            inc(Res);
            laeufer := laeufer^.CdrVal;
          end;
     end
  else
  if (LspArrayp(p)) then
     Res := p^.Size
  else
  if (LspStringp(p)) then
     Res := length(LspGetStringVal(p))
  else
     raise ELispException.Create('ErrBadArgument','List, array or string expected');

  result := LspMakeInteger(Res);
end;





(*----------------------------------------------------------------------------*)
(* Den Car des n-ten Cdr einer Liste holen. n beginnt bei 0                   *)
(*----------------------------------------------------------------------------*)
function LspNth(n,l: pNode): pNode;
var i,nn: longint;
begin
  if (not LspIntegerp(n)) then
     raise ELispException.Create('ErrIntegerExpected','First argument');

  if (not LspListp(l)) then
     raise ELispException.Create('ErrListExpected','Second argument');

  nn := LspGetIntegerVal(n);
  Result := l;
  for i := 0 to nn - 1 do
      result := LspCdr(Result);
  result := LspCar(Result);
end;




(*----------------------------------------------------------------------------*)
(* Den n-ten Cdr einer Liste holen. n beginnt bei 0                           *)
(*----------------------------------------------------------------------------*)
function LspNthCdr(n,l: pNode): pNode;
var i,_n: longint;
begin
  if (not LspIntegerp(n)) then
     raise ELispException.Create('ErrIntegerExpected','First argument');

  if (not LspListp(l)) then
     raise ELispException.Create('ErrListExpected','Second argument');

  _n := LspGetIntegerVal(n);
  result := l;
  for i := 0 to _n - 1 do
      result := LspCdr(result);
end;




(*----------------------------------------------------------------------------*)
(* Zwei Listen aneinander haengen                                             *)
(*----------------------------------------------------------------------------*)
function LspAppend2(l1,l2: pNode): pNode;
var c1,c2,h: pNode;
begin
  (*--- Sicherstellen, dass Listen vorliegen ---*)
  if (not LspListp(l1)) then
     raise ELispException.Create('ErrListExpected','First argument');

  if (not LspListp(l2)) then
     raise ELispException.Create('ErrListExpected','Second argument');

  c1 := LspCopy(l1);   {Liste 1 kopieren}
  h  := LspLast(c1);   {Ans Ende der Kopie}
  c2 := LspCopy(l2);   {Liste 2 kopieren}

  if (c1 = nil) then
     result := c2
  else
     begin
       h^.CdrVal := c2; {Beide Kopien aneinander haengen}
       result := c1;
     end;
end;



function LspAppend(Args,Umgebung: pNode): pNode;
var e      : pNode;
    i      : pNode;
    laeufer: pNode;
    res    : pNode;
begin
  e := evaluated(Args,Umgebung);
  res := nil;

  while (e <> nil) do
  begin
    if (not expect(i,e,cTypList)) then
       raise ELispException.Create('ErrListExpected','');

    laeufer := i;
    while (laeufer <> nil) do
    begin
      res  := LspCons(LspCar(laeufer),Res);
      laeufer := laeufer^.CdrVal;
    end;
  end;

  result := LspReverse(Res);
end;



function LspRplaca(x,y: pNode): pNode;
begin
  if (not LspConsp(x)) then
     raise ELispException.Create('ErrConsExpected','First argument')
  else
     begin
       x^.CarVal := y;
       result    := x;
     end;
end;



function LspRplacd(x,y: pNode): pNode;
begin
  if (not LspConsp(x)) then
     raise ELispException.Create('ErrConsExpected','First argument')
  else
     begin
       x^.CdrVal := y;
       result    := x;
     end;
end;



function LspAssoc(key, list: pNode): pNode;
var laeufer : pNode;
    gefunden: boolean;
    car     : pNode;
begin
  result := nil;
  
  if (not LspListp(list)) then
     raise ELispException.Create('ErrListExpected','Second argument');

  gefunden := false;
  laeufer  := list;
  while ((laeufer <> nil) and not gefunden) do
     begin
       car := laeufer^.CarVal;
       if (LspConsp(car) and LspEql(car^.CarVal,key)) then
          begin
            result   := car;
            gefunden := true;
          end
       else
          laeufer := laeufer^.CdrVal;
     end;
end;


(*----------------------------------------------------------------------------*)
(* Eine Funktion auf alle Elemente einer Liste anwenden                       *)
(*----------------------------------------------------------------------------*)
function LspMapCar(Args,Umgebung: pNode): pNode;
var e,f,l   : pNode;
    temp    : pNode;
    Argument: pNode;
    res     : pNode;
    laeufer : pNode;
begin
  e := Args;

  f := LspCar(e);
  e := LspCdr(e);

  e := evaluated(e,Umgebung);
  res := nil;

  if (not expect(l,e,cTypList)) then
     raise ELispException.Create('ErrListExpected','');

  laeufer := l;
  while (laeufer <> nil) do
  begin
    Argument := LspCons(cLspQuote,LspCons(LspCons(LspCar(laeufer),nil),nil));
    temp     := LspEval(LspCons(cLspApply,LspList2(f,Argument)),Umgebung);
    res      := LspCons(temp,res);
    laeufer  := laeufer^.CdrVal;
  end;

  result := LspReverse(Res);
end;


(*----------------------------------------------------------------------------*)
(* Eine Liste in ein Array umwandeln.                                         *)
(*----------------------------------------------------------------------------*)
function LspListToArray(l: pNode): pNode;
var size, laeufer: pNode;
    i: longint;
begin
  if (not LspListp(l)) then
     raise ELispException.Create('ErrListExpected','');

  size    := LspLength(l);
  result  := LspMakeArray(Size);
  i       := 0;
  laeufer := l;
  while (laeufer <> nil) do
     begin
       LspSetAtIndex(Result,laeufer^.CarVal,i);
       laeufer := laeufer^.CdrVal;
       inc(i);
     end;
end;



(*----------------------------------------------------------------------------*)
(* Ein Array in eine Liste umwandeln                                          *)
(*----------------------------------------------------------------------------*)
function LspArrayToList(a: pNode): pNode;
var i,size : longint;
begin
  if (not LspArrayp(a)) then
     raise ELispException.Create('ErrArrayExpected','First argument');

  result := nil;
  size := a^.Size;
  for i := size-1 downto 0 do
      result := LspCons(LspGetAtIndex(a,i),result);
end;


(*----------------------------------------------------------------------------*)
(* Eine Liste sortieren. Die Liste wird zuerst in ein Array umgewandelt, dann *)
(* wird der Quicksort-Algorithmus angewandt. Schlieﬂlich wird das sortierte   *)
(* Array wieder in eine Liste umgewandelt.                                    *)
(* Syntax: (QUICK-SORT <Liste> <Kleiner-Funktion>)                            *)
(*----------------------------------------------------------------------------*)
function LspQuickSort(Args,Umgebung: pNode): pNode;
var Liste  : pNode;
    Feld   : pNode;
    LessFct: pNode;
    pivot  : pNode;
   procedure _Sort(Feld, LessFct: pNode;l,r: longint);
   var i,j,x: longint;
   begin
     if (l >= r) then
        exit;

     i := l;
     j := r;
     x := (l+r) div 2;
     pivot := LspGetAtIndex(Feld,x);
     while (i <= j) do
        begin
          while (LspEval(LspList3(LessFct,Quoted(LspGetAtIndex(Feld,i)),Quoted(pivot)),Umgebung) <> nil) do
             inc(i);
          while (LspEval(LspList3(LessFct,Quoted(pivot),Quoted(LspGetAtIndex(Feld,j))),Umgebung) <> nil) do
             dec(j);
          if (i <= j) then
             begin
               LspSwapArrayVals(Feld,i,j);
               inc(i);
               dec(j);
             end;
        end;
        _Sort(Feld,LessFct,l,j);
        _Sort(Feld,LessFct,i,r);
   end;
begin
  Liste   := nil;
  Feld    := nil;
  LessFct := nil;

  LspLockNodeAddress(@Result);
  LspLockNodeAddress(@Liste);
  LspLockNodeAddress(@Feld);
  LspLockNodeAddress(@LessFct);
  LspLockNodeAddress(@args);
  LspLockNodeAddress(@pivot);

  try
     Args := Evaluated(Args,Umgebung);

     if (not Expect(Liste,Args,cTypList)) then
        raise ELispException.Create('ErrListExpected','QUICK-SORT');

     Expect(LessFct,Args,cTypAnyType);

     result := LspListToArray(Liste);
     _Sort(Result,LessFct,0,LspGetIntegerVal(LspLength(Liste))-1);
     result := LspArrayToList(result);
  finally
     LspUnlockNodeAddress(@Result);
     LspUnlockNodeAddress(@Liste);
     LspUnlockNodeAddress(@Feld);
     LspUnlockNodeAddress(@LessFct);
     LspUnlockNodeAddress(@args);
     LspUnlockNodeAddress(@pivot);
  end;
end;



function LspBubbleSort(Args,Umgebung: pNode): pNode;
var Liste  : pNode;
    Feld   : pNode;
    LessFct: pNode;
    flag   : boolean;
    laeufer: pNode;
    temp   : pNode;
begin
  Liste   := nil;
  Feld    := nil;
  LessFct := nil;
  laeufer := nil;
  temp    := nil;

  LspLockNodeAddress(@Liste);
  LspLockNodeAddress(@Feld);
  LspLockNodeAddress(@LessFct);
  LspLockNodeAddress(@laeufer);
  LspLockNodeAddress(@temp);
  LspLockNodeAddress(@args);


  try
     Args := Evaluated(Args,Umgebung);

     if (not Expect(Liste,Args,cTypList)) then
        raise ELispException.Create('ErrListExpected','BUBBLESORT');

     Expect(LessFct,Args,cTypAnyType);

     flag := true;
     while (flag) do
        begin
          if (random < 0.1) then
             LspGc(Umgebung);
          flag    := false;
          laeufer := liste;
          while (laeufer <> nil) do
             begin
               if ((LspCar(laeufer)  <> nil) and
                   (LspCadr(laeufer) <> nil) and
                   (LspEval(LspList3(LessFct,Quoted(LspCadr(laeufer)),Quoted(LspCar(laeufer))),Umgebung) <> nil)) then
                   begin
                     flag := true;
                     temp := LspCar(laeufer);
                     LspRplaca(laeufer, LspCadr(laeufer));
                     LspRplaca(LspCdr(laeufer),temp);
                   end;
               laeufer := LspCdr(laeufer);
             end;
        end;
  finally
     LspUnLockNodeAddress(@Liste);
     LspUnLockNodeAddress(@Feld);
     LspUnLockNodeAddress(@LessFct);
     LspUnLockNodeAddress(@laeufer);
     LspUnLockNodeAddress(@temp);
     LspUnLockNodeAddress(@args);
  end;

  result := Liste;
end;


end.
