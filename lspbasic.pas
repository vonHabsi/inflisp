(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspbasic;
{$O+,F+}


interface
uses
sysutils,
   lspglobl;

function LspCar   (p: pNode): pNode;
function LspCdr   (p: pNode): pNode;
function LspCaar  (p: pNode): pNode;
function LspCadr  (p: pNode): pNode;
function LspCdar  (p: pNode): pNode;
function LspCddr  (p: pNode): pNode;
function LspCaadr (p: pNode): pNode;
function LspCadar (p: pNode): pNode;
function LspCaddr (p: pNode): pNode;
function LspCdddr (p: pNode): pNode;
function LspCaddar(p: pNode): pNode;
function LspCadddr(p: pNode): pNode;
function LspLast  (p: pNode): pNode;

implementation
uses
   strng,
   lsppredi, lsperr;


(*----------------------------------------------------------------------------*)
(* Das erste Element einer Liste liefern.                                     *)
(*----------------------------------------------------------------------------*)
function LspCar(p: pNode): pNode;
begin
  if (p = nil) then
     result := nil
  else
     begin
       if (p^.typ = cLspList) then
          result := p^.CarVal
       else
          raise ELispException.Create('ErrListExpected','CAR');
     end;
end;



(*----------------------------------------------------------------------------*)
(* Die Restliste liefern, nachdem das erste Element entfernt wurde.          *)
(*----------------------------------------------------------------------------*)
function LspCdr(p: pNode): pNode;
begin
  if (p <> nil) then
     begin
       if (p^.typ = cLspList) then
          result := p^.CdrVal
       else
          raise ELispException.Create('ErrListExpected','CDR');
     end
  else
     result := nil;
end;



(*----------------------------------------------------------------------------*)
(* Einen Zeiger auf die letzte Cons-Zelle einer Liste liefern                 *)
(*----------------------------------------------------------------------------*)
function LspLast(p: pNode): pNode;
var laeufer: pNode;
begin
  if (not LspListp(p)) then
     raise ELispException.Create('ErrListExpected','LAST');

  laeufer := p;
  while (LspCdr(laeufer) <> nil) do
      laeufer := LspCdr(laeufer);
  result := laeufer;
end;





(*----------------------------------------------------------------------------*)
(* Ein paar Variationen von Car und Cdr.                                      *)
(*----------------------------------------------------------------------------*)
function LspCaar(p: pNode): pNode;
begin
  result := LspCar(LspCar(p));
end;

function LspCdar(p: pNode): pNode;
begin
  result := LspCdr(LspCar(p));
end;

function LspCadr(p: pNode): pNode;
begin
  result := LspCar(LspCdr(p));
end;

function LspCddr(p: pNode): pNode;
begin
  result := LspCdr(LspCdr(p));
end;

function LspCaadr(p: pNode): pNode;
begin
  result := LspCar(LspCar(LspCdr(p)));
end;

function LspCadar(p: pNode): pNode;
begin
  result := LspCar(LspCdr(LspCar(p)));
end;

function LspCaddr(p: pNode): pNode;
begin
  result := LspCar(LspCdr(LspCdr(p)));
end;

function LspCdddr(p: pNode): pNode;
begin
  result := LspCdr(LspCdr(LspCdr(p)));
end;

function LspCaddar(p: pNode): pNode;
begin
  result := LspCar(LspCdr(LspCdr(LspCar(p))));
end;

function LspCadddr(p: pNode): pNode;
begin
  result := LspCar(LspCdr(LspCdr(LspCdr(p))));
end;

end.
