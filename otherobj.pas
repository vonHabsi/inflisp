(*----------------------------------------------------------------------------*)
(* In dieser Unit werden alle Objekte eingebunden, die eine Erweiterung des   *)
(* normalen Lisp darstellen                                                   *)
(*                                                                            *)
(* 23.7.1997: das Objekt UNARC-MEMORY eingebaut, das Zugriff auf die          *)
(* Speichermethoden von UNARC gestattet.                                      *)
(*--------------------------------- -------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit otherobj;

interface
uses
   LspGlobl;


procedure LspInitSymbols(var Umgebung: pNode);

implementation
uses
   lspcreat, lspmain
{$ifdef unarc}
   ,lspunarc
{$endif}
   ;

procedure LspInitSymbols(var Umgebung: pNode);
(*----------------------------------------------------------------------------*)
{$ifdef unarc}
var
   memory  : TUnarcMemory;
   clusters: TUnarcClusters;
   concepts: TUnarcConcepts;
   temp: pNode;

{$endif}
(*----------------------------------------------------------------------------*)
begin
  (*--------------------------------------------------------------------------*)
  {$ifdef unarc}
  cLspUnarcMemory     := LspMakeSymbol('UNARC-MEMORY');
  cLspUnarcClusters   := LspMakeSymbol('UNARC-CLUSTERS');
  cLspUnarcConcepts   := LspMakeSymbol('UNARC-CONCEPTS');
  cLspReadLisp        := LspMakeSymbol('READ-LISP');
  cLspFindAssociative := LspMakeSymbol('FIND-ASSOCIATIVE');
  cLspFind            := LspMakeSymbol('FIND');
  cLspReorganize      := LspMakeSymbol('REORGANIZE');


  memory          := TUnarcMemory.Create(nil);
  LspNew(temp);
  temp^.Typ       := cLspObject;
  temp^.ObjectVal := memory;
  memory.Env      := Umgebung;
  LspSetq(cLspUnarcMemory,temp,Umgebung);

  clusters        := TUnarcClusters.Create(nil);
  LspNew(temp);
  temp^.Typ       := cLspObject;
  temp^.ObjectVal := clusters;
  clusters.Env    := Umgebung;
  LspSetq(cLspUnarcClusters,temp,Umgebung);

  concepts        := TUnarcConcepts.Create(nil);
  LspNew(temp);
  temp^.Typ       := cLspObject;
  temp^.ObjectVal := concepts;
  concepts.Env    := Umgebung;
  LspSetq(cLspUnarcConcepts,temp,Umgebung);


  {$endif}
  (*--------------------------------------------------------------------------*)
end;

end.
