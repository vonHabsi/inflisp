(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsppars;
{$O+,F+}

interface
uses
   lspglobl, lsplex;


function getExpression(pLex: pLex_obj): pNode;


implementation
uses
   lspbasic, lspcreat, lsplists, lsperr, lspinout, lsparray, lspinit;





function getExpression(pLex: pLex_obj): pNode;
   var CollectList,h,tempArray,laeufer,letzterKnoten,temp: pNode;
       i,count: longint;
       Abbruch: boolean;
   begin
     case pLex^.Lookahead.Token of
        (********************************************************************)
        cLspNilToken:
           begin
             getExpression := nil;
            pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        cLspSymbolToken:
           begin
             getExpression := LspMakeSymbol(pLex^.Lookahead.TokenValString);
            pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        cLspStringToken:
           begin
             getExpression := LspMakeString(pLex^.Lookahead.TokenValString);
             pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        cLspIntegerToken:
           begin
             getExpression := LspMakeInteger(pLex^.Lookahead.TokenValLongint);
            pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        cLspFloatToken:
           begin
             getExpression := LspMakeFloat(pLex^.Lookahead.TokenValDouble);
             pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        cLspKlammerZuToken:
           begin
             getExpression := cLspKlammerZu;
             pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        cLspEndOfFileToken:
           begin
             getExpression := cLspEndOfFile;
             pLex^.consume(pLex^.Lookahead);
           end;
        (********************************************************************)
        (*
        cLspEndOfLineToken:
           begin
             getExpression := cLspEndOfLine;
             pLex^.consume(pLex^.Lookahead);
           end;
        *)
        (********************************************************************)
        cLspKlammerAufToken:
           begin
             pLex^.consume(pLex^.Lookahead); { '(' konsumieren }
             (*--- In Collectlist wird die nun kommende Liste gesammelt ---*)
             CollectList   := nil;
             LetzterKnoten := nil;
             Abbruch       := false;
             (*--- Solange sammeln, bis Abschluss mittels Klammer kommt ---*)
             while ((not Abbruch)  and
                    (pLex^.Lookahead.Token <> cLspKlammerZuToken)) do
                 begin
                   (*--- Punktpaar ? ---*)
                   if (pLex^.Lookahead.Token = cLspPunktToken) then
                      begin
                        (*--- Wurde Punkt zu frueh eingegeben ? ---*)
                        if (CollectList = nil) then
                           raise ELispException.Create('ErrWrongDottedPair','')
                        else
                           begin
                             pLex^.consume(pLex^.Lookahead);
                             LspRplacd(LetzterKnoten,getExpression(pLex));
                           end;
                      end
                   else
                      begin
                        temp := getExpression(pLex);

                        h := LspCons(temp,nil);

                        if ((temp = cLspKlammerZu)  or
                            (temp = cLspEndOfFile)) then
                           Abbruch := true
                        else
                        if (temp <> cLspEndOfLine) then
                           begin
                             if (CollectList = nil) then
                                CollectList := h
                             else
                                LspRplacd(letzterKnoten,h);
                             letzterKnoten := h;
                           end;
                      end;
                 end;
             if (not Abbruch) then
                pLex^.consume(pLex^.Lookahead);
             getExpression := CollectList;
           end;
        (********************************************************************)
        cLspArrayToken:
           begin
            pLex^.consume(pLex^.Lookahead); { '#(' konsumieren }
             (*--- In Collectlist wird die nun kommende Liste gesammelt ---*)
             CollectList   := nil;
             LetzterKnoten := nil;
             (*--- Solange sammeln, bis Abschluss mittels Klammer kommt ---*)
             Count := 0;
             while (pLex^.Lookahead.Token <> cLspKlammerZuToken) do
                 begin
                   (*--- Punktpaar ? ---*)
                   if (pLex^.Lookahead.Token = cLspPunktToken) then
                      begin
                        (*--- Wurde Punkt zu frueh eingegeben ? ---*)
                        if (CollectList = nil) then
                           raise ELispException.Create('ErrWrongDottedPair','')
                        else
                           begin
                             pLex^.consume(pLex^.Lookahead);
                             LspRplacd(LetzterKnoten,getExpression(pLex));
                           end;
                      end
                   else
                      begin
                        inc(Count);
                        h := LspCons(getExpression(pLex),nil);
                        if (CollectList = nil) then
                           CollectList := h
                        else
                           LspRplacd(LetzterKnoten,h);
                        letzterKnoten := h;
                      end;
                 end;
            pLex^.consume(pLex^.Lookahead);

             (*----------------------------*)
             (* Liste nun in Array wandeln *)
             (*----------------------------*)
             tempArray := LspMakeArray(LspLength(CollectList));
             laeufer := CollectList;
             for i := 0 to Count - 1 do
                 begin
                 writeln('Fehler');
                 (*
                   tLispArray(tempArray^.ArrayVal^)[i] := LspCar(laeufer);
                   *)
                   laeufer := LspCdr(laeufer);
                 end;

             getExpression := tempArray;
           end;
        (********************************************************************)
        cLspQuoteToken:
        begin
         pLex^.consume(pLex^.Lookahead);
          getExpression := LspCons(LspMakeSymbol('quote'),LspCons(getExpression(pLex),nil));
        end;
        (********************************************************************)
        cLspBackQuoteToken:
        begin
         pLex^.consume(pLex^.Lookahead);
          getExpression := LspCons(LspMakeSymbol('backquote'),LspCons(getExpression(pLex),nil));
        end;
        (********************************************************************)
        cLspCommaToken:
        begin
         pLex^.consume(pLex^.Lookahead);
          getExpression := LspCons(LspMakeSymbol('comma'),LspCons(getExpression(pLex),nil));
        end;
        (********************************************************************)
        cLspCommaAtToken:
        begin
         pLex^.consume(pLex^.Lookahead);
          getExpression := LspCons(LspMakeSymbol('comma-at'),LspCons(getExpression(pLex),nil));
        end;
        (********************************************************************)
        cLspEndOfLineToken:
        begin
          pLex^.consume(pLex^.Lookahead);
          getExpression := getExpression(pLex); (*--- rekursives Weiterlesen ---*)
        end;
        (********************************************************************)
        else
           begin
             pLex^.consume(pLex^.Lookahead);
             raise ELispException.Create('ErrUnexpectedToken','')
           end;
     end;
   end;
end.
