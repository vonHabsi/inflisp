(*----------------------------------------------------------------------------*)
(* Routinen, um Knoten vor Garbage-Collection zu schuetzen.                   *)
(* Jede Knoten-Adresse soll hoechstens einmal in der Schutzliste vorkommen.   *)
(*                                                                            *)
(* Zu beachten ist: Vor Aufruf von Garbage-Collection muss der gelockte       *)
(* Knoten gueltig sein, d.h. nil sein oder auf einen Knoten zeigen.           *)
(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit Lsplock;

interface
uses
   lspglobl;

procedure LspLockNodeAddress(pp: ppNode);
procedure LspUnlockNodeAddress(pp: ppNode);

implementation
uses
   lspcreat,
strng, dialogs;

procedure LspLockNodeAddress(pp: ppNode);
var p: pNode;
begin
  LspNew(p);
  p^.Typ               := cLspNodeAddress;
  p^.NodeAddressVal    := pp;
  MainTask.LockedNodes := LspCons(p,MainTask.LockedNodes);
end;



(*----------------------------------------------------------------------------*)
(* Eine Knotenadresse von der Sperr-Liste entfernen. Man beachte, dass von    *)
(* der Voraussetzung ausgegangen wird, dass die Liste nur Elemente des Typs   *)
(* cLspNodeAddress hat.                                                       *)
(*----------------------------------------------------------------------------*)
procedure LspUnlockNodeAddress(pp: ppNode);
var laeufer: pNode;
    found  : boolean;
begin
  found   := false;
  laeufer := MainTask.LockedNodes;
  if ((laeufer <> nil) and (laeufer^.CarVal^.NodeAddressVal = pp)) then
     begin
       found                := true;
       MainTask.LockedNodes := MainTask.LockedNodes^.CdrVal;
     end;

  laeufer := MainTask.LockedNodes;
  while ((laeufer <> nil) and (not found)) do
     begin
       if ((laeufer^.CdrVal <> nil) and
           (laeufer^.CdrVal^.CarVal^.NodeAddressVal = pp)) then
          begin
            found := true;
            laeufer^.CdrVal := laeufer^.CdrVal^.CdrVal;
          end
       else
          laeufer := laeufer^.CdrVal;
     end;
end;



end.
