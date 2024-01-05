(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspstrng;
{$O+,F+}

interface
uses
   lspglobl;


function LspGetStringVal(p: pNode): ShortString;
function LspSymbolName(p: pNode): pNode;
{
function LspAref(a,n: pNode): pNode;
}
function LLspChar(Args,Umgebung: pNode): pNode;
function LLspString(Args,Umgebung: pNode): pNode;
function LLspStrcat(Args,Umgebung: pNode): pNode;
function LLspSubstr(Args,Umgebung: pNode): pNode;

implementation
uses
   lsperr, lsppredi, lspcreat, lspmath, lspmain, lspexpct;

(*----------------------------------------------------------------------------*)
(* Den Stringwert eines Stringknotens holen                                   *)
(*----------------------------------------------------------------------------*)
function LspGetStringVal(p: pNode): ShortString;
begin
  if ((p = nil) or (p^.Typ <> cLspString)) then
     raise ELispException.Create('ErrStringExpected','');
  result := p^.StringVal^;
end;



(*----------------------------------------------------------------------------*)
(* Den Symbolnamen in einen Lisp-String umwandeln.                            *)
(* NIL ist Symbol, darf aber zu keinem Ergebnis fuehren                       *) 
(*----------------------------------------------------------------------------*)
function LspSymbolName(p: pNode): pNode;
begin
  if (LspNull(p) or not LspSymbolp(p)) then
     raise ELispException.Create('ErrNonNilSymbolExpected','');
  result := LspMakeString(p^.SymbolVal^);
end;



        {
(*----------------------------------------------------------------------------*)
(* Das n-te Element eines Arrays a liefern                                    *)
(*----------------------------------------------------------------------------*)
function LspAref(a,n: pNode): pNode;
   var s: ShortString;
       i: integer;
   begin
     LspAref := nil;
     s := LspGetStringVal(a);

     if LspError <> 0 then
        exit;

     i := LspGetIntegerVal(n);
     if LspError <> 0 then
        exit;
     LspAref := LspMakeString(s[i]);
   end;
         }

(*----------------------------------------------------------------------------*)
(* Aus einem String ein Zeichen (ASCII-Code) extrahieren                      *)
(*----------------------------------------------------------------------------*)
function LLspChar(Args,Umgebung: pNode): pNode;
var e : pNode;
    i1: pNode;
    i2: pNode;
    s : ShortString;
    i : integer;
begin
  result := nil;

  e := evaluated(Args,Umgebung);

  if (not expect(i1,e,cTypString)) then
     exit;

  if (not expect(i2,e,cTypInteger)) then
      exit;

  s := LspGetStringVal(i1);
  i := LspGetIntegerVal(i2);
  result := LspMakeInteger(ord(s[i+1]));
end;



(*----------------------------------------------------------------------------*)
(* Aus einer Zahl einen 1-Zeichen-String machen                               *)
(*----------------------------------------------------------------------------*)
function LLspString(Args,Umgebung: pNode): pNode;
var e : pNode;
    i1: pNode;
    i : integer;
begin
  result := nil;
  e := evaluated(Args,Umgebung);

  if (not expect(i1,e,cTypInteger)) then
     exit;

  i := LspGetIntegerVal(i1);
  result := LspMakeString(chr(i));
end;



(*----------------------------------------------------------------------------*)
(* Eine Liste von Strings konkatenieren                                       *)
(*----------------------------------------------------------------------------*)
function LLspStrcat(Args,Umgebung: pNode): pNode;
   var e : pNode;
       s : ShortString;
       h1: pNode;
       h : ShortString;
   begin
     e := evaluated(Args,Umgebung);

     s := '';
     while (e <> nil) do
        begin
          if (not expect(h1,e,cTypString)) then
             begin
               result := nil;
               exit;
             end;
          h := LspGetStringVal(h1);
          s := s + h;
        end;

     result := LspMakeString(s);
   end;

(*----------------------------------------------------------------------------*)
(* Aus einem String einen Teilstring entnehmen (SUBSTR <s> <Startpos> <Lng.>) *)
(*----------------------------------------------------------------------------*)
function LLspSubstr(Args,Umgebung: pNode): pNode;
var e : pNode;
    s1: pNode;
    s : ShortString;
    p1: pNode;
    p : integer;
    l1: pNode;
    l : integer;
begin
  result := nil;
  e := evaluated(Args,Umgebung);

  if (not expect(s1,e,cTypString)) then
     exit;

  s := LspGetStringVal(s1);

  if (not expect(p1,e,cTypInteger)) then
     exit;

  p := LspGetIntegerVal(p1);

  if (e <> nil) then
     begin
       expect(l1,e,cTypInteger);
       l := LspGetIntegerVal(l1);
     end
  else
     l := 256;

  result := LspMakeString(copy(s,p,l));
end;



end.
