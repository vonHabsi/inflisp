(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit Eval;

interface
uses
   classes, sysutils,
   LspGlobl,
winprocs;

procedure DoEval(Source, Dest: TStream);
function GetListFromStream(Source: TStream): pNode;

implementation
uses
  lspmain, lspinit, lspcreat, lsplists, lspinout, lsperr,
  lsplock,
  forms, dialogs;

(*-----------------------------------------------------------------------------*)
(* Aufgabe: Stream Source laden und elementweise auswerten. Die Ausgaben dabei *)
(* nach Dest schreiben.                                                        *) 
(*-----------------------------------------------------------------------------*)
procedure DoEval(Source, Dest: TStream);
var InputNode       : pNode;
    OutputNode      : pNode;
    Res             : pNode;
begin
  InputNode  := nil;
  OutputNode := nil;
  Res        := nil;
  LspLockNodeAddress(@InputNode);
  LspLockNodeAddress(@OutputNode);
  LspLockNodeAddress(@Res);

  try
     LspNew(InputNode);
     InputNode^.Typ       := cLspStream;
     InputNode^.StreamVal := Source;

     if (Dest <> nil) then
        begin
          LspNew(OutputNode);
          OutputNode^.Typ       := cLspStream;
          OutputNode^.StreamVal := Dest;
        end
     else
        OutputNode := nil;


     try
        Source.seek(0,0);

        repeat
          Res := LspRead(InputNode);
          if (Res <> cLspEndOfFile) then
             LspPrint(LspEval(Res,MainTask.Environment),OutputNode);
          Application.ProcessMessages;
        until (Res = cLspEndOfFile);

     (*----------------------------------------------------------*)
     (* Es ist notwendig, Stream-Information zu verbergen, denn  *)
     (* das Garbage-Collection-System von Inflisp wuerde auch    *)
     (* den Stream selbst vernichten, der hier aber 'von aussen' *)
     (* geliefert wird. Ein LspDispose ist verboten1, denn dies  *)
     (* wird von Garbage-Collection oder am Programm-Ende        *)
     (* automatisch getan. Tut man es explizit, so geht die      *)
     (* AllObjects-Info verloren !                               *)
     (*----------------------------------------------------------*)
     finally
        if (InputNode <> nil) then
           InputNode^.StreamVal  := nil;

        if (OutputNode <> nil) then
           OutputNode^.StreamVal := nil;
     end;

  finally
     LspUnlockNodeAddress(@InputNode);
     LspUnlockNodeAddress(@OutputNode);
     LspUnlockNodeAddress(@Res);
  end;
end;



(*----------------------------------------------------------------------------*)
(* Einen Delphi-Stream einlesen und Liste aller Ausdruecke zurueckgeben       *)
(*----------------------------------------------------------------------------*)
function GetListFromStream(Source: TStream): pNode;
var StreamNode: pNode;
    exp       : pNode;
begin
  LspNew(StreamNode);
  StreamNode^.Typ       := cLspStream;
  StreamNode^.Flags     := 42;
  StreamNode^.StreamVal := Source;

  Source.seek(0,0);
  Result := nil;
  repeat
    exp := LspRead(StreamNode);
    if (exp <> cLspEndOfFile) then
       Result := LspCons(exp,Result);
  until (exp = cLspEndOfFile);



  (*--------------------------------------------------------------------------*)
  (* Stream-Info verbergen, siehe oben.                                       *)
  (*--------------------------------------------------------------------------*)
  StreamNode^.StreamVal := nil;

  Result := LspReverse(Result);
end;
end.
