(*----------------------------------------------------------------------------*)
(* Property editor for TLispExpression.                                       *)
(* Author: Joachim Pimiskern; 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit Editlsp;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons;

type
  TFormEditExpression = class(TForm)
    Memo: TMemo;
    GroupBox: TGroupBox;
    ButtonOK: TBitBtn;
    ButtonCancel: TBitBtn;
    procedure ButtonOKClick(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;


implementation

{$R *.DFM}

procedure TFormEditExpression.ButtonOKClick(Sender: TObject);
begin
  ModalResult := mrOK;
end;

procedure TFormEditExpression.ButtonCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TFormEditExpression.FormResize(Sender: TObject);
begin
  Memo.Width  := Width - 40;
  Memo.Left   := 20;
  Memo.Top    := 20;
  Memo.Height := Height - 140;

  GroupBox.Width := Width - 40;
  GroupBox.Left  := 20;
  GroupBox.Top   := Height - 100;

  ButtonOK     . Left := Width div 2 - 10 - ButtonOk.Width - GroupBox.Left;
  ButtonCancel . Left := Width div 2 + 10                  - GroupBox.Left;
end;

end.
 