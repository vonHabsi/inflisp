(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsplex;
{$O+,F+,E+,N+}
interface
uses
   lspinout, linestrm;

const
   cLspUnbekanntesToken =  1;
   cLspKlammerAufToken  =  2;
   cLspKlammerZuToken   =  3;
   cLspNilToken         =  4;
   cLspPunktToken       =  5;
   cLspQuoteToken       =  6;
   cLspBackQuoteToken   =  7;
   cLspCommaToken       =  8;
   cLspCommaAtToken     =  9;
   cLspSemikolonToken   = 10;
   cLspSymbolToken      = 11;
   cLspFloatToken       = 12;
   cLspIntegerToken     = 13;
   cLspEndOfFileToken   = 14;
   cLspEndOfLineToken   = 15;
   cLspStringToken      = 16;
   cLspArrayToken       = 17;



type
   tLspToken = record
                  Token          : integer;
                  TokenValString : ShortString;
                  TokenValDouble : double;
                  TokenValLongint: longint;
               end;

   tLex_obj = object
                LookAhead:  tLspToken;
                pEingabe :  pLS_obj;
                Line     :  ShortString; {aktuelle, eben gelesene Zeile}
                p        :  byte;   {Zeiger auf naechstes Zeichen }
                constructor init(ptr: pLS_obj);
                destructor  done;
                procedure   consume(var t: tLspToken);
                procedure   getToken(var t: tLspToken);
              end;
   pLex_obj = ^tLex_obj;


implementation
uses
   lsperr, strng;
(*   ,wjputil
{$else}
   ,crt
{$endif}
   ;         *)



(*----------------------------------------------------------------------------*)
(* Alle Buchstaben, ausser in Strings, in Grossbuchstaben wandeln.            *)
(*----------------------------------------------------------------------------*)
function LspToUpper(s: ShortString): ShortString;
var i: integer;
    QuoteModus: boolean;
begin
  QuoteModus := false;
  for i := 1 to length(s) do
      begin
        if (s[i] = '"') then
           quoteModus := not QuoteModus;
        if (not QuoteModus) then
           s[i] := toUpper(s[i]);
      end;
  result := s;
end;



constructor tLex_obj.Init(ptr: pLS_obj);
begin
  pEingabe := ptr;
  Line := '';
  p    := 1;
  getToken(Lookahead);
end;


destructor tLex_obj.Done;
begin
end;


procedure tLex_obj.consume(var t: tLspToken);
begin
  if (Lookahead.Token = t.Token) then
     getToken(Lookahead)
  else
     raise ELispException.Create('ErrTokenExpected','');
end;



procedure tLex_obj.getToken(var t: tLspToken);
var gefunden  : boolean;
    symboltest: ShortString;
    oldP      : integer;
    d         : double;
    l         : longint;
    error     : integer;
begin
  gefunden := false;
  t.Token  := cLspUnbekanntesToken; {Default-Fehlerfall}



  (*--- Auf den Beginn eines Tokens positionieren ---*)
  repeat
    if ((p > length(line)) or ((p <= length(line)) and (line[p]=';'))) then
       begin
         if (pEingabe^.EndOfFile) then
            begin
              gefunden := true;
              t.Token := cLspEndOfFileToken;
            end
         else
            begin
              line := LspToUpper(pEingabe^.getLine);
              line := line + #32 + #10;
              p    := 1;
            end;
       end;

    (*--- Auf ein nichtleeres Zeichen positionieren ---*)
    while (p <= length(line)) and (line[p] = ' ') do
        inc(p);

  until gefunden or ((p <= length(line)) and (line[p] <> ' ') and (line[p] <> ';'));





  (*-----------------------------------------------------------------------*)
  (* End-Of-Line.  Man beachte, dass dieses Token nur als Trick eingefuegt *)
  (* wurde, um das Hinterherhinken des Parsers wg. Lookahead zu verhindern *)
  (*-----------------------------------------------------------------------*)
  if (not gefunden and (copy(line,p,1) = #10)) then
     begin
       inc(p,1);
       gefunden := true;
       t.Token := cLspEndOfLineToken;
     end;


  (*--- Klammer auf ---*)
  if not gefunden and (copy(line,p,1) = '(') then
     begin
       inc(p,1);
       gefunden := true;
       t.Token := cLspKlammerAufToken;
     end;

  (*--- Klammer zu ---*)
  if not gefunden and (copy(line,p,1) = ')') then
     begin
       inc(p,1);
       gefunden := true;
       t.Token := cLspKlammerZuToken;
     end;

  (*--- Beginn einer Array-Aufzaehlung ---*)
  if not gefunden and (copy(line,p,2) = '#(') then
     begin
       inc(p,2);
       gefunden := true;
       t.Token := cLspArrayToken;
     end;

  (*--- Hochkomma (Quote-Symbol) ---*)
  if not gefunden and (copy(line,p,1) = '''') then
     begin
       inc(p,1);
       gefunden := true;
       t.Token := cLspQuoteToken;
     end;

  (*--- Hochkomma (BackQuote-Symbol) ---*)
  if not gefunden and (copy(line,p,1) = '`') then
     begin
       inc(p,1);
       gefunden := true;
       t.Token := cLspBackQuoteToken;
     end;

  (*--- Comma-At-Symbol ---*)
  if not gefunden and (copy(line,p,2) = ',@') then
     begin
       inc(p,2);
       gefunden := true;
       t.Token := cLspCommaAtToken;
     end;

  (*--- Komma (Comma-Symbol) ---*)
  if not gefunden and (copy(line,p,1) = ',') then
     begin
       inc(p,1);
       gefunden := true;
       t.Token := cLspCommaToken;
     end;

  (*--- Test auf String ---*)
  if not gefunden and (copy(line,p,1) = '"') then
     begin
       symboltest := '';
       inc(p);
       while (p <= length(line)) and
             not (line[p] = '"') do
             begin
               (*--- Test auf Flucht-Character ---*)
               if (line[p] = '\') then
                  begin
                    inc(p);
                  end;
               symboltest := symboltest + line[p];
               inc(p);
             end;
       inc(p,1);

       gefunden := true;
       t.Token          := cLspStringToken;
       t.TokenValString := symboltest;
     end;

  (*--- Test auf allgemeines Symbol ---*)
  if (not gefunden) then
     begin
       symboltest := '';
       oldP := p;
       while (p <= length(line)) and
             not (line[p] = ' ') and
             not (line[p] = ';') and
             not (line[p] = '(') and
             not (line[p] = ')') do
             begin
               symboltest := symboltest + line[p];
               inc(p);
             end;



       (*-----------------------------------------------------------------*)
       if symboltest = '.' then
          begin
            t.Token          := cLspPunktToken;
            exit;
          end;
       (*--- Integerzahl ? -----------------------------------------------*)
       val(symboltest,l,error);
       if (error = 0) then
          begin
            t.Token           := cLspIntegerToken;
            t.TokenValLongint := l;
            exit;
          end;
       (*--- Fliesskommazahl ? -------------------------------------------*)
       val(symboltest,d,error);
       if (error = 0) then
          begin
            t.Token          := cLspFloatToken;
            t.TokenValDouble := d;
            exit;
          end;
       (*-----------------------------------------------------------------*)
       if (symboltest = 'NIL') then
          t.Token  := cLspNilToken
       else
       (*-----------------------------------------------------------------*)
       if (symboltest <> '') then
          begin
            t.Token          := cLspSymbolToken;
            t.TokenValString := symboltest;
          end
       (*-----------------------------------------------------------------*)
       else
          p := oldP;
     end;
end;


end.
