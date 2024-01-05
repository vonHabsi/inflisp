(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lsperr;

interface
uses
   sysutils;


type
   ELispException = class(Exception)
      FSym: string;
      FMsg: string;
      constructor Create(Sym,Msg: string);
      function GetSym: string;
   end;


implementation

constructor ELispException.Create(Sym,Msg: string);
begin
  inherited Create(Sym + ': ' + Msg);
  FSym := Sym;
  FMsg := Msg;
end;

function ELispException.GetSym: string;
begin
  result := FSym;
end;

end.
