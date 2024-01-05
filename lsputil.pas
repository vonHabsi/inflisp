(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsputil;

interface
uses
   lspglobl;

function LspTime: pNode;

implementation
uses
   winprocs,
   lspcreat;


function LspTime: pNode;
begin
  result := LspMakeInteger(GetTickCount);
end;


end.
