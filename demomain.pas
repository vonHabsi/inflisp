(*----------------------------------------------------------------------------*)
(* Demonstration of the INFLISP lisp interpreter.                             *)
(* Inflisp is encapsulated in the Delphi component TLispExpression.           *)
(* Author: Joachim Pimiskern.                                                 *)
(*----------------------------------------------------------------------------*)
unit demomain;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Express;

type
  TFormDemoMain = class(TForm)
    PanelRight: TPanel;
    ButtonClose: TButton;
    PanelTop: TPanel;
    PanelBottom: TPanel;
    PanelLeft: TPanel;
    PanelMiddle: TPanel;
    Memo1: TMemo;
    Splitter1: TSplitter;
    Memo2: TMemo;
    ButtonRun: TButton;
    LispExpression: TLispExpression;
    ButtonAbout: TButton;
    procedure ButtonCloseClick(Sender: TObject);
    procedure ButtonRunClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ButtonAboutClick(Sender: TObject);
  private
    procedure Process(input,output: TStringList);
  public
  end;

var
  FormDemoMain: TFormDemoMain;

implementation
uses
   lspglobl, lsplock, lspcreat, lspinout;
{$R *.DFM}

procedure TFormDemoMain.ButtonCloseClick(Sender: TObject);
begin
  Close;
end;


procedure TFormDemoMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ((Key = VK_F4) and not (ssAlt in Shift)) then
     ButtonRunClick(nil);
end;




procedure TFormDemoMain.ButtonRunClick(Sender: TObject);
begin
  Process(TStringList(Memo1.Lines),TStringList(Memo2.Lines));
end;


procedure TFormDemoMain.Process(input,output: TStringList);
var OutputNode  : pNode;
    saveSTDOUT  : pNode;
    MemoryStream: TMemoryStream;
begin
  MemoryStream  := TMemoryStream.Create;
  Screen.Cursor := crHourglass;
  try
     OutputNode := nil;
     LspLockNodeAddress(@OutputNode);
     try
        LspNew(OutputNode);
        OutputNode^.Typ            := cLspStream;
        OutputNode^.StreamVal      := MemoryStream;
        saveSTDOUT                 := MainTask.LspStandardOutput; // Store original STDOUT
        MainTask.LspStandardOutput := OutputNode; // Redirect STDOUT to MemoryStream

        try
           LispExpression.Expression.Clear;
           LispExpression.Expression.AddStrings(input);
           LispExpression.Prepare;
           LispExpression.Execute;
           LspPrint(LispExpression.AsNode,OutputNode);

           MemoryStream.Seek(0,0);
           output.Clear;
           output.LoadFromStream(MemoryStream);
        finally
           (*----------------------------------------------------------*)
           (* Es ist notwendig, Stream-Information zu verbergen, denn  *)
           (* das Garbage-Collection-System von Inflisp wuerde auch    *)
           (* den Stream selbst vernichten, der hier aber 'von aussen' *)
           (* geliefert wird. Ein LspDispose ist verboten1, denn dies  *)
           (* wird von Garbage-Collection oder am Programm-Ende        *)
           (* automatisch getan. Tut man es explizit, so geht die      *)
           (* AllObjects-Info verloren !                               *)
           (*----------------------------------------------------------*)
           OutputNode^.StreamVal := nil;

           MainTask.LspStandardOutput := saveSTDOUT; // Restore STDOUT
        end;
     finally
        LspUnlockNodeAddress(@OutputNode);
     end;
  finally
     MemoryStream.Free;
     Screen.Cursor := crDefault;
  end;
end;

procedure TFormDemoMain.ButtonAboutClick(Sender: TObject);
begin
  ShowMessage('INFLISP' + #13#10 +
              'Lisp interpreter' + #13#10 +
              'Author: Joachim Pimiskern, 1994-2004' + #13#10 +
              'Freeware.'
             );
end;

end.
