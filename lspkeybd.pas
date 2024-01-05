(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspkeybd;
{$O+,F+,E+,N+}

interface
uses
   sysutils,
   lspglobl, linestrm;



type
   tTastaturInputObjekt = object(tLS_obj)
                             constructor Init;
                             destructor  Done; virtual;
                             procedure   fOpen(filename: ShortString); virtual;
                             procedure   fClose; virtual;
                             function    getLine: ShortString; virtual;
                          end;
   pTastaturInputObjekt = ^tTastaturInputObjekt;


var
   Klammerebene: integer;

implementation
uses
   lsppredi, lsperr, lspbasic, strng,
   dialogs;




(*--- Eingabe per Tastatur ermoeglichen ------------------------------------*)
constructor tTastaturInputObjekt.Init;
begin
  EndOfFile := false;
  Klammerebene := 0;
end;

destructor tTastaturInputObjekt.Done;
begin
end;

procedure tTastaturInputObjekt.fOpen(filename: ShortString);
begin
end;

procedure tTastaturInputObjekt.fClose;
begin
end;


function tTastaturInputObjekt.getLine: ShortString;
var s: ShortString;
begin
  if (Klammerebene <> 0) then
     write(IntToStr(Klammerebene));
  write('> ');
  readln(s);
  inc(Klammerebene,CharCount('(',s)-CharCount(')',s));
  getline := s  + ' ' + chr(10);
end;

end.
