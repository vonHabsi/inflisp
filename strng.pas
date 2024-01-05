(*----------------------------------------------------------------------------*)
(* Joachim Pimiskern, 1994-2004. Freeware, use it at your own risk.           *)
(*----------------------------------------------------------------------------*)
unit strng;
{$O+,F+}
{$v-}
{$r+}
{$s+}
{$N+}

interface

function  b2s(b: boolean): string;
function  isdigit(z: char): boolean;
function  isspace(z: char) : boolean;
function  empty(s: string): boolean;
function  uppercase(z: char): boolean;
procedure noSpaces(var s: string);
function  fNoSpaces(s: string): string;
procedure noExtension(var s: ShortString);
function  getExt(s: string): string;
procedure kuerze(var s: string);
procedure teilstring(var str2, str1: string);
function  tolower(c: char): char;
function  toupper(c: char): char;
procedure strlwr(var s: string);
function  FirstUp(s: string): string;

procedure strupr(var s: string);
function  fstrupr(s: string): string;

function  ausschnitt(s: string; start, laenge: integer): string;
procedure strcat(var s1: string; s2: string);
function  praefix(a,b: string): boolean;
function  rest(s: string; p: byte): string;
function  match(i,p: string): boolean;
function  AnalogBar(maxLen: integer; echterBruch: real): string;
function  fReverse(s: string): string;

function  fBinaerformat(zahl: extended; breite, nachkomma: integer): string;
function  nibble2char(x: integer): char;
function  char2nibble(c: char): integer;
function  b2hex(x: byte): string;
function  i2hex(x: integer): string;
function  l2hex(x: longint): string;
function  p2s(p: pointer): string;
function  s2s(s: string; von, laenge: integer): string;
function  i2s(zahl, stellen: integer): string;
function  i2s0(zahl, stellen: integer): string;
function  w2s(zahl: word; stellen: integer): string;
function  l2s(zahl: longint; stellen: integer): string;
function  l2s0(zahl: longint; stellen: integer): string;
function  r2s(zahl: double; breite, nachkomma: integer): string;
function  r2s0(zahl: double; breite, nachkomma: integer): string;
function  s2i(s: string): integer;
function  s2l(s: string): longint;
function  s2r(s: string): double;
function  hex2l(s: string): longint;

function  strcount(a: char; b: string): integer;
function  filledstring(c: char; breite: integer): string;
function  firstletter(s: string): char;
function  dtb(s: string): string;
function  deleteLeadingBlanks(s: string): string;
function  spaceTo0(s: string): string;
function  CharCount(c: char; s: string): integer;
function  EntferneFolgendeNullen(s: string): string;
function  mem2s(var mem; len: integer): string;
procedure replace(var s: string; zuErsetzen, durch: char);
function  vorPunkt(s: string): string;
function  CharToStr(c: char): string;
function  StrToLong(s: string): longint;

function  fOemToAnsi(s: string): string;
function  fAnsiToOem(s: string): string;

implementation
uses
   sysutils, winprocs;

function b2s(b: boolean): string;
begin
  if (b) then
     result := 'TRUE '
  else
     result := 'FALSE';
end;


(*--- Ist das Zeichen z eine Ziffer ? ---*)
function isdigit(z: char): boolean;
   begin
     if (z = '0') or (z = '1') or (z = '2') or (z = '3') or
        (z = '4') or (z = '5') or (z = '6') or (z = '7') or
        (z = '8') or (z = '9')
        then isdigit := True
        else isdigit := False;
   end;

(*--- Ist das Zeichen ein erweitertes Leerzeichen ? ---*)
(*--- Hierzu zaehlen  SPACE, NULL, LINEFEED, RETURN ---*)
function isspace(z: char) : boolean;
begin
  if (z = chr(32)) or (z = chr(0)) or (z = chr(10)) or (z = chr(13)) then
     result := true
  else
     result := false;
end;



(*--- Abfrage, ob ein Zeichen ein Grossbuchstabe ist ---*)
function uppercase(z: char): boolean;
   var i: integer;
       ergebnis: boolean;
       s : string;
   begin
     s := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
     ergebnis := False;
     i := 1;
     while not(ergebnis) and (i <= 26) do
        begin
          if z = s[i] then ergebnis := True;
          inc(i);
        end;
     uppercase := ergebnis;
   end;


(*--- Besteht der String s nur aus Leerzeichen ? ---*)
function empty(s: string): boolean;
var i: integer;
    e: boolean;
begin
  e := true;
  i := 1;
  while e and (i <= length(s)) do
  begin
    if not(isspace(s[i])) then
       e := false
    else
       inc(i);
  end;
  result := e;
end;




(*--- Diese Prozedur entfernt alle Spaces aus einem String ---*)
procedure noSpaces(var s: string);
   var i: integer;
       t: string;
   begin
     t := '';
     for i := 1 to length(s) do
         if (s[i] <> ' ') and
            (s[i] <> chr(0))
            then t := t + s[i];
     s := t;
   end;



function fNoSpaces(s: string): string;
   var i: integer;
       t: string;
   begin
     t := '';
     for i := 1 to length(s) do
         if (s[i] <> ' ') and
            (s[i] <> chr(0))
            then t := t + s[i];
     fNoSpaces := t;
   end;





(*--- Eine evtl. vorhandene Extension entfernen ---*)
procedure noExtension(var s: ShortString);
var i: integer;
    ergebnis: ShortString;
begin
  ergebnis := '';
  i := 1;
  while (i <= length(s)) and (s[i] <> '.') do
     begin
       ergebnis := ergebnis + s[i];
       inc(i);
     end;
  s := ergebnis;
end;


(*----------------------------------------------------------------------------*)
(* Eine eventuell vorhandene Extension eines Strings liefern                  *)
(*----------------------------------------------------------------------------*)
function getExt(s: string): string;
   var p: integer;
   begin
     getExt := '';
     nospaces(s);
     if (s = '.') or (s = '..') then
        exit;
     p := pos('.',s);
     if p = 0 then
        exit;
     getExt := copy(s,p,3);
   end;


   (*--- Stellt das Zeichen c ein editierbares Zeichen dar ? ---*
   function ed_zeichen(c: char): boolean;
      var ergebnis  : boolean;
          i         : integer;
          zugelassen: string[200];
      begin
        ergebnis := False;
        zugelassen := 'abcdefghijklmnopqrstuvwxyz'+
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ'+
                      '0123456789' +
                      ' !$%&/()=?+-*:.,;<>^' +
                      'Ž„™”šá\';
        for i := 1 to length(zugelassen) do
            if zugelassen[i] = c then ergebnis := True;
        ed_zeichen := ergebnis;
      end;                                   *)


  (*--- nachfolgende Spaces aus einem String entfernen ---*)
  procedure kuerze(var s: string);
     var i,j: integer;
         t  : string;
     begin
       i := length(s);
       j := 0;
       while (i > 0) and ((s[i] = ' ') or (s[i] = chr(0))) do
             begin
               inc(j);
               dec(i);
             end;
       t := '';
       for i := 1 to length(s)-j do
           t := t + s[i];
       s := t;
     end;




(*--- Aus dem  String str1 das erste isolierte  Wort auslesen. ---*)
(*--- Das Wort kommt in str2. Str1 wird entsprechend verkuerzt ---*)
procedure teilstring(var str2, str1: string);
var i: integer;
    g,h: string;
begin
  g := '';
  h := '';

  i := 1;
  while (i <= length(str1)) and isspace(str1[i]) do
     inc(i);

  while (i <= length(str1)) and not(isspace(str1[i])) do
     begin
       g := g + str1[i];
       inc(i);
     end;
  while (i <= length(str1)) do
       begin
         h := h + str1[i];
         inc(i);
       end;
  str2 := g;
  str1 := h;
end;






  function  tolower(c: char): char;
     var ergebnis: char;
     begin
       ergebnis := c;
       if (ord(c) >= ord('A')) and
          (ord(c) <= ord('Z'))
          then ergebnis := chr(ord(c)-ord('A')+ord('a'));

       (*--- Sonderfall: Umlaute ---*)
       if c = 'Ž'
          then ergebnis := '„';
       if c = '™'
          then ergebnis := '”';
       if c = 'š'
          then ergebnis := '';

       tolower := ergebnis;
     end;



  (*--- Einen Buchstaben in einen Grossbuchstaben umwandeln ---*)
  function  toupper(c: char): char;
     var ergebnis: char;
     begin
       ergebnis := c;
       if (ord(c) >= ord('a')) and
          (ord(c) <= ord('z'))
          then ergebnis := chr(ord(c)-ord('a')+ord('A'));

       (*--- Sonderfall: Umlaute ---*)
       if c = '„'
          then ergebnis := 'Ž';
       if c = '”'
          then ergebnis := '™';
       if c = ''
          then ergebnis := 'š';

       toupper := ergebnis;
     end;



  (*--- Grossbuchstaben in einem String in Kleinbuchstaben uebersetzen ---*)
  procedure strlwr(var s: string);
     var i: integer;
     begin
       for i := 1 to length(s) do
           s[i] := tolower(s[i]);
     end;

(*--- Einen String mit dem ersten Buchstaben groß und Rest klein liefern   ---*)
function  FirstUp(s: string): string;
var i: integer;
begin
  s[1] := toupper(s[1]);
  for i := 2 to length(s) do
      s[i] := tolower(s[i]);
  result := s;
end;


  (*--- Kleinbuchstaben in einem String in Grossbuchstaben uebersetzen ---*)
  procedure strupr(var s: string);
     var i: integer;
     begin
       for i := 1 to length(s) do
           s[i] := toupper(s[i]);
     end;


  (*--- String in Grossbuchstaben-String wandeln; Original bleibt erhalten ---*)
  function  fstrupr(s: string): string;
     var e: string;
         i: integer;
     begin
       e := '';
       for i := 1 to length(s) do
           e := e + toupper(s[i]);
       fstrupr := e;
     end;



  (*-- Wie Copy, nur dass hier Bereiche ausserhalb mit ' ' gefuellt werden --*)
  function ausschnitt(s: string; start, laenge: integer): string;
  var i: integer;
      t: string;
  begin
    t := '';
    for i := 1 to laenge do
        t := t + ' ';
    t := t + s;
    for i := 1 to laenge do
        t := t + ' ';
    ausschnitt := copy(t,start+laenge,laenge);
  end;






  procedure strcat(var s1: string; s2: string);
     begin
       s1 := s1 + s2;
     end;


  function praefix(a,b: string): boolean;
     begin
       if Copy(b,1,length(a)) = a then
          praefix := True
       else
          praefix := False;
     end;

  function rest(s: string; p: byte): string;
     begin
       rest := Copy(s,p,length(s));
     end;



 (*--- Wildcard-Matching i = Instanz, p = Pattern ---*)
function match(i,p: string): boolean;

var tempI,tempP: string;


    function loescheDoppelteSterne(s: string): string;
       var ergebnis: string;
           letztesZeichen: char;
           i: integer;
       begin
         ergebnis       := '';
         letztesZeichen := 'a';
         for i := 1 to length(s) do
             if not((letztesZeichen = '*') and (s[i] = '*')) then
                begin
                  letztesZeichen := s[i];
                  ergebnis := ergebnis + s[i];
                end;
         loescheDoppelteSterne := ergebnis;
       end;

function match1(vonI,BisI,vonP,bisP: byte): boolean;
    var ergebnis: boolean;
    begin
      tempP := Copy(p,vonP,bisP);
      tempI := Copy(i,vonI,bisI);

      {
      writeln('------------------------------');
      writeln('<',tempI,'>');
      writeln('<',tempP,'>');
       }

      ergebnis := False;
      tempP := Copy(p,vonP,bisP);
      tempI := Copy(i,vonI,bisI);
      if not(ergebnis) and (length(tempI) = 0) and (length(tempP) = 0) then
         ergebnis := TRUE;
      tempP := Copy(p,vonP,bisP);
      tempI := Copy(i,vonI,bisI);
      if not(ergebnis) and (length(tempP) > 0) and (tempP[1] <> '*') and (tempP[1] <> '?') then
         ergebnis := (length(tempI) > 0) and
                  (tempP[1] = tempI[1])   and
                  match1(vonI+1,bisI,vonP+1,bisP);
      tempP := Copy(p,vonP,bisP);
      tempI := Copy(i,vonI,bisI);
      if not(ergebnis) and (length(tempP) > 0) and (tempP[1] = '?') then
         ergebnis := (length(tempI) > 0) and
                  match1(vonI+1,bisI,vonP+1,bisP);
      tempP := Copy(p,vonP,bisP);
      tempI := Copy(i,vonI,bisI);
      if not(ergebnis) and (length(tempP) > 0) and (tempP[1] = '*') then
         begin
           ergebnis := match1(vonI,bisI,vonP+1,bisP);
           tempP := Copy(p,vonP,bisP);
           tempI := Copy(i,vonI,bisI);
           if not ergebnis then
              ergebnis := ((length(tempI) > 0) and match1(vonI+1,bisI,vonP,bisP));
         end;
      match1 := ergebnis;
end; {match1}

begin
  strupr(i);
  strupr(p);
  p := loescheDoppelteSterne(p);
  match := match1(1,length(i),1,length(p));
end;



(*--- Einen Balken der Art ±±±±±þþþþþþþ als String liefern ---*)
function AnalogBar(maxLen: integer; echterBruch: real): string;
   var i: integer;
       ergebnis: string;
   begin
     if echterBruch < 0.0 then
        echterBruch := 0.0;
     if echterBruch > 1.0 then
        echterBruch := 1.0;

     ergebnis := '';
     for i := 1 to trunc(maxLen * echterBruch + 0.5) do
         ergebnis := ergebnis + '±';
     for i := 1 to trunc(maxLen * (1-echterBruch) + 0.5) do
         ergebnis := ergebnis + 'þ';
     AnalogBar := ergebnis;
   end;




(*--- Zu einem String den Umkehrstring liefern ---*)
function  fReverse(s: string): string;
   var e: string;
       i: integer;
   begin
     e := '';
     for i := length(s) downto 1 do
         e := e + s[i];
     fReverse := e;
   end;



(*--- Eine Fliesskommazahl in einen ASCII-Binaerstring wandeln ---*)
function  fBinaerformat(zahl: extended; breite, nachkomma: integer): string;
   var e: string;
       h: extended;
       d: extended;
   begin
     h := zahl;
     e := '';

     d := 1.0;
     while zahl-d >= 0.0 do
        d := d + d;
     d := d / 2;



     while length(e)<200 do
        begin
          if d = 0.5 then
             strcat(e,'.');

          if h-d >= 0.0 then
             begin
               strcat(e,'1');
               h := h - d;
             end
          else
             strcat(e,'0');
          d := d / 2;
        end;

     fBinaerformat := e;
   end;


(*--- Eine Zahl aus dem Bereich 0..15 als Hexziffer ausgeben ---*)
function nibble2char(x: integer): char;
   const hexziffer : string[16] = '0123456789abcdef';
   begin
     if (x >= 0) and (x <= 15) then
        nibble2char := hexziffer[succ(x)]
     else
        nibble2char := '?';
   end;





function char2nibble(c: char): integer;
   const hexziffer : string[16] = '0123456789abcdef';
   begin
     c := tolower(c);
     char2nibble := pos(c,hexziffer) - 1;
   end;



function  b2hex(x: byte): string;
begin
  setLength(result,2);
  result[2] := nibble2char(x and $000f);
  x := x shr 4;
  result[1] := nibble2char(x and $000f);
end;


function  i2hex(x: integer): string;
begin
  setLength(result,4);
  result[4] := nibble2char(x and $000f);
  x := x shr 4;
  result[3] := nibble2char(x and $000f);
  x := x shr 4;
  result[2] := nibble2char(x and $000f);
  x := x shr 4;
  result[1] := nibble2char(x and $000f);
end;




function  l2hex(x: longint): string;
begin
  setLength(result,8);
  result[8] := nibble2char(x and $000f);
  x := x shr 4;
  result[7] := nibble2char(x and $000f);
  x := x shr 4;
  result[6] := nibble2char(x and $000f);
  x := x shr 4;
  result[5] := nibble2char(x and $000f);
  x := x shr 4;
  result[4] := nibble2char(x and $000f);
  x := x shr 4;
  result[3] := nibble2char(x and $000f);
  x := x shr 4;
  result[2] := nibble2char(x and $000f);
  x := x shr 4;
  result[1] := nibble2char(x and $000f);
end;



function p2s(p: pointer): string;
   begin
     p2s := l2hex(longint(p));
   end;


function  s2s(s: string; von, laenge: integer): string;
begin
  result := copy(s,von,laenge);
  while length(result) < laenge do
     result := result + ' ';
end;

function i2s(zahl, stellen: integer): string;
var ergebnis: string;
begin
  if zahl <> 0 then
     str(zahl:stellen,ergebnis)
  else
     ergebnis := s2s('',1,stellen);
  i2s := ergebnis;
end;


function i2s0(zahl, stellen: integer): string;
begin
 str(zahl:stellen,result);
end;


function  w2s(zahl: word; stellen: integer): string;
   var ergebnis: string;
   begin
     if zahl <> 0 then
        str(zahl:stellen,ergebnis)
     else
        ergebnis := s2s('',1,stellen);
     w2s := ergebnis;
   end;


function l2s(zahl: longint; stellen: integer): string;
   var ergebnis: string;
   begin
     if zahl <> 0 then
        str(zahl:stellen,ergebnis)
     else
        ergebnis := s2s('',1,stellen);
     l2s := ergebnis;
   end;


function l2s0(zahl: longint; stellen: integer): string;
begin
 str(zahl:stellen,result);
end;


function  r2s(zahl: double; breite, nachkomma: integer): string;
   var ergebnis: string;
   begin
     if zahl <> 0 then
        str(zahl:breite:nachkomma,ergebnis)
     else
        ergebnis := s2s('',1,breite);
     r2s := ergebnis;
   end;

function r2s0(zahl: double; breite, nachkomma: integer): string;
   var ergebnis: string;
   begin
     str(zahl:breite:nachkomma,ergebnis);
     r2s0 := ergebnis;
   end;

function  s2i(s: string): integer;
var ergebnis, error: integer;
begin
  val(s,ergebnis,error);
  if error = 0 then
     s2i := ergebnis
  else
     s2i := 0;
end;



function  s2l(s: string): longint;
var ergebnis: longint;
    error   : integer;
begin
  val(s,ergebnis,error);
  if (error = 0) then
     s2l := ergebnis
  else
     s2l := 0;
end;


function s2r(s: string): double;
var ergebnis: double;
    error   : integer;
begin
  val(s,ergebnis,error);
  if (error = 0) then
     s2r := ergebnis
  else
     s2r := 0;
end;





(*----------------------------------------------------------------------------*)
(* Hex-Adresse in Longint-Zahl wandeln                                        *)
(*----------------------------------------------------------------------------*)
function hex2l(s: string): longint;
   var ergebnis: longint;
       i       : integer;
   begin
     ergebnis := 0;
     for i := 1 to length(s) do
         begin
           ergebnis := ergebnis shl 4;
           ergebnis := ergebnis + char2nibble(s[i]);
         end;
     hex2l := ergebnis;
   end;



function  strcount(a: char; b: string): integer;
   var ergebnis, i: integer;
   begin
     ergebnis := 0;
     for i := 1 to length(b) do
         if b[i] = a then
            inc(ergebnis);
     strcount := ergebnis;
   end;


function filledstring(c: char; breite: integer): string;
   var i: integer;
       e: string;
   begin
     e := '';
     for i := 1 to breite do
         e := e + c;
     filledstring := e;
   end;



(*--- Das erste nichtleere Zeichen eines Strings holen ---*)
function firstletter(s: string): char;
   var e: char;
       i: integer;
       gefunden: boolean;
   begin
     e := ' ';
     i := 1;
     gefunden := false;
     while (i <= length(s)) and (not gefunden) do
        begin
          if not isspace(s[i]) then
             begin
               e := s[i];
               gefunden := true;
             end;
          inc(i);
        end;
     firstletter := e;
   end;


(*----------------------------------------------------------------------------*)
(* Delete Trailing Blanks... folgende Blanks loeschen                         *)
(*----------------------------------------------------------------------------*)
function dtb(s: string): string;
   var i: integer;
   begin
     i := length(s);
     while (i >= 1) and (s[i] = ' ') do
        dec(i);
     dtb := copy(s,1,i);
   end;

function  deleteLeadingBlanks(s: string): string;
   var i: integer;
   begin
     i := 1;
     while (i <= length(s)) and (s[i] = ' ') do
        inc(i);
     deleteLeadingBlanks := copy(s,i,255);
   end;

function  spaceTo0(s: string): string;
   var e: string;
       i: integer;
   begin
     e := '';
     for i := 1 to length(s) do
         if s[i] = ' ' then
            e := e + '0'
         else
            e := e + s[i];
     spaceTo0 := e;
   end;


function CharCount(c: char; s: string): integer;
   var e,i: integer;
   begin
     e := 0;
     for i := 1 to length(s) do
         if s[i] = c then
            inc(e);
     CharCount := e;
   end;


function  EntferneFolgendeNullen(s: string): string;
   var i: integer;
   begin
     i := length(s);
     while (i >= 1) and (s[i] = '0') do
        dec(i);
     if (i >= 1) and (s[i] = '.') then
        dec(i);
     EntferneFolgendeNullen := copy(s,1,i);
   end;



function  mem2s(var mem; len: integer): string;
begin
  setLength(result,len);
  move(mem,result[1],len);
end;


(*----------------------------------------------------------------------------*)
(* In einem String ein Zeichen durch ein anderes ersetzen                     *)
(*----------------------------------------------------------------------------*)
procedure replace(var s: string; zuErsetzen, durch: char);
   var x: integer;
   begin
     x := pos(zuErsetzen,s);
     while x <> 0 do
        begin
          s[x] := durch;
          x := pos(zuErsetzen,s);
        end;
   end;

function vorPunkt(s: string): string;
   var ergebnis: string;
   begin
     replace(s,'.',' ');
     teilstring(ergebnis,s);
     vorPunkt := ergebnis;
   end;


function  CharToStr(c: char): string;
var s: string;
begin
  s := '';
  CharToStr := c + s;
end;


function  StrToLong(s: string): longint;
begin
  try
    result := StrToInt(s);
  except
    result := 0;
  end;
end;


(*----------------------------------------------------------------------------*)
(* Windows-String in Ansi-String uebersetzen                                  *)
(*----------------------------------------------------------------------------*)
function fOemToAnsi(s: string): string;
var a,b: array[0..255] of char;
begin
  strpcopy(a,s);
  oemtoansi(a,b);
  result := strpas(b);
end;


function  fAnsiToOem(s: string): string;
var a,b: array[0..255] of char;
begin
  strpcopy(a,s);
  ansitooem(a,b);
  result := strpas(b);
end;


end.
