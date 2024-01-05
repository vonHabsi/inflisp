(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2008                                       *)
(*----------------------------------------------------------------------------*)
unit expr_reg;

interface

uses
  dsgnintf;

//
// In the case you get a compiler error here, try
//
// uses
//   designintf,
//   designeditors;
// 
// and add a reference to designide.dcp in the package.
// See also InstallationNotes.txt
//




type
  TLispEditor = class(TPropertyEditor)
     procedure Edit; override;
     function GetAttributes: TPropertyAttributes; override;
     function GetValue: string; override;
  end;

procedure Register;

implementation
uses
  classes, controls,
  express, editlsp;
//uses
//   Eval, lspmath, lspstrng, lsppredi,
//   EditLsp;


function TLispEditor.GetAttributes: TPropertyAttributes;
begin
  GetAttributes := [paDialog, paReadOnly];
end;

function TLispEditor.GetValue: string;
begin
  GetValue := '(Click)';
end;





(*
procedure TLispEditor.Edit;
var FormEditExpression: TFormEditExpression;
begin
  if (GetComponent(0) <> nil) then
  begin
    FormEditExpression := TFormEditExpression.Create(nil);
    try
      FormEditExpression.ShowModal;
    finally
      FormEditExpression.Free;
    end;
  end;
end;
*)

(*----------------------------------------------------------------------------*)
(* Einen Editor fuer die Expression-Property aufrufen                         *)
(*----------------------------------------------------------------------------*)
procedure TLispEditor.Edit;
var FormEditExpression: TFormEditExpression;
begin
  FormEditExpression := TFormEditExpression.Create(nil);
  try
    FormEditExpression.Memo.Lines.Assign(TStrings(GetOrdValue));
    if (FormEditExpression.ShowModal = mrOK) then
       SetOrdValue(Longint(FormEditExpression.Memo.Lines));
  finally
    FormEditExpression.Free;
  end;
end;




procedure Register;
begin
  RegisterComponents('Inflisp', [TLispExpression]);
  RegisterPropertyEditor(TypeInfo(TStrings),TLispExpression,'',TLispEditor);
end;

initialization


end.
