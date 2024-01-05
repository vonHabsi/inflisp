(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit lspexpct;
{$O+,F+}

interface
uses
   lspglobl;

const
   cTypAnyType      = 0;
   cTypInteger      = 1;
   cTypFile         = 2;
   cTypString       = 3;
   cTypFileOrStream = 4;
   cTypList         = 5;
   cTypSymbol       = 6;

function Expect(var ZuBesetzen,Argumente: pNode; Typ: integer): boolean;

implementation
uses
   sysutils,
   lsppredi, lsperr, lspbasic;



function Expect(var ZuBesetzen,Argumente: pNode; Typ: integer): boolean;
begin
  if (not LspListp(Argumente)) then
     raise ELispException.Create('ErrListExpected','Arguments wrong');

     ZuBesetzen := LspCar(Argumente);
     Argumente  := LspCdr(Argumente);

     case Typ of
        (*--------------------------------------------------------------------*)
        cTypAnyType:
        begin
          result := true;
        end;
        (*--------------------------------------------------------------------*)
        cTypInteger:
        begin
          if (LspIntegerp(ZuBesetzen)) then
             result := true
          else
             raise ELispException.Create('ErrIntegerExpected','');
           end;
        (*--------------------------------------------------------------------*)
        cTypFile:
        begin
          if (LspFilep(ZuBesetzen)) then
             result := true
          else
             raise ELispException.Create('ErrFileExpected','');
        end;
        (*--------------------------------------------------------------------*)
        cTypFileOrStream:
        begin
          if (LspFilep(ZuBesetzen) or LspConsp(ZuBesetzen)) then
             result := true
          else
             raise ELispException.Create('ErrFileOrStreamExpected','');
        end;
        (*--------------------------------------------------------------------*)
        cTypString:
        begin
          if (LspStringp(ZuBesetzen)) then
             result := true
          else
             raise ELispException.Create('ErrStringExpected','');
        end;
        (*--------------------------------------------------------------------*)
        cTypList:
        begin
          if (LspListp(ZuBesetzen)) then
             result := true
          else
             raise ELispException.Create('ErrListExpected','');
        end;
        (*--------------------------------------------------------------------*)
        cTypSymbol:
        begin
          if (LspSymbolp(ZuBesetzen)) then
             result := true
          else
             raise ELispException.Create('ErrSymbolExpected','');
        end;
        (*--------------------------------------------------------------------*)
//        else expect := false; Dies ist die Originalzeile vor den Exceptions
        else raise ELispException.Create('ErrExpect','Unexpected type ' + IntToStr(Typ));
     end;
   end;

end.
