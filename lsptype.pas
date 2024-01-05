(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsptype;
{$O+,F+}

interface
uses
   lspglobl;


function LspTypeOf(Args,Umgebung: pNode): pNode;

implementation
uses
   lspmain, lsperr, lspinit, lspbasic;


(*----------------------------------------------------------------------------*)
(* Den Typ eines Lisp-Knotens als Symbol zurueckliefern                       *)
(*----------------------------------------------------------------------------*)
function LspTypeOf(Args,Umgebung: pNode): pNode;
var e : pNode;
    i : pNode;
begin
  e := evaluated(Args,Umgebung);

  if (e = nil) then
     raise ELispException.Create('ErrTooFewArguments','TYPE-OF');

  if (LspCdr(e) <> nil) then
     raise ELispException.Create('ErrTooManyArguments','TYPE-OF');

  i := LspCar(e);
  case i^.Typ of
     cLspSymbol     : result := cLspDPSymbol ;
     cLspList       : result := cLspDPCons   ;
     cLspFloat      : result := cLspDPFloat  ;
     cLspInteger    : result := cLspDPInteger;
     cLspString     : result := cLspDPString ;
     cLspArray      : result := cLspDPArray  ;
     cLspFile       : result := cLspDPFile   ;
     else raise ELispException.Create('ErrUnknownType','TYPE-OF');
  end;
end;



end.
