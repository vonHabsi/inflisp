(*----------------------------------------------------------------------------*)
(* Author: Joachim Pimiskern, 1994-2004                                       *)
(*----------------------------------------------------------------------------*)
unit express;

interface

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms,
  lspglobl, lsplock, lspmain, lspbasic, lspinf, lspcreat, lsplists;


type
  TLispExpression = class(TComponent)
  private
    (*--- Das letzte Ergebnis als Lisp-Knoten ---*)
    ResultNode       : pNode;

    MyOwnEnvironment : pNode;
    Representation   : pNode;
    Parameters       : pNode;

    FExpression      : TStrings;
    FText            : PChar;
    FExpressionBinary: PChar;
    procedure SetExpression(Value: TStrings);
    procedure ExpressionChanged(Sender: TObject);
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadBinaryData(Stream: TStream);
    procedure WriteBinaryData(Stream: TStream);

    function  ParamByName(s: string): pNode;
  protected
  public
    constructor Create(AOwner: TComponent); override;
    procedure   Loaded; override;
    destructor  Destroy; override;

    (*--- Text als Lisp-Ausdruck liefern ---*)
    function    InternalRepresentation: pNode;
    (*--- Die textuelle Darstellung in e. Lisp-Repraesentation uebersetzen ---*)
    procedure   Prepare;
    (*--- Die Lisp-Ausdruecke der Reihe nach ausfuehren, analog zu (load ...) ---*)
    procedure   Execute;

    procedure   SetIntegerParam(s: string; value: longint);
    procedure   SetFloatParam(s: string; value: double);
    procedure   SetStringParam(s: string; value: string);
    procedure   SetSymbolParam(s: string; value: string);
    procedure   SetBooleanParam(s: string; value: boolean);
    procedure   SetNodeParam(s: string; value: pNode);
    (*--- Den RESULTNODE in diverse andere Typen wandeln ---*)
    function    AsNode   : pNode;
    function    AsInteger: longint;
    function    AsFloat  : double;
    function    AsString : string;
    function    AsSymbol : string;
    function    AsBoolean: boolean;

    property    Text: PChar read FText;
    property    ExpressionBinary: PChar read FExpressionBinary write FExpressionBinary;
  published
    property    Expression: TStrings     read FExpression write SetExpression;
  end;


implementation
uses
   Eval, lspmath, lspstrng, lsppredi,
   EditLsp;

{$r *.dcr}


procedure TLispExpression.SetExpression(Value: TStrings);
begin
(*  Disconnect; *)
  TStringList(Expression).OnChange := nil;
  Expression.Assign(Value);
  TStringList(Expression).OnChange := ExpressionChanged;
  ExpressionChanged(nil);
end;



procedure TLispExpression.ExpressionChanged(Sender: TObject);
begin
  StrDispose(FText);
  FText := Expression.GetText;
  StrDispose(ExpressionBinary);
  ExpressionBinary := nil;
end;





constructor TLispExpression.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExpression := TStringList.Create;
  FText := nil;
end;

destructor TLispExpression.Destroy;
begin
  if (MainTask = nil) then
     raise Exception.Create('TLispExpression.Destroy: Lisp system not initialized');

(*  Destroying; *)
(*  Disconnect; *)
  LspUnlockNodeAddress(@ResultNode);
  LspUnlockNodeAddress(@Parameters);
  LspUnlockNodeAddress(@Representation);
  LspUnlockNodeAddress(@MyOwnEnvironment);

  Expression.Free;
  StrDispose(FText);
  StrDispose(ExpressionBinary);
  inherited Destroy;
end;



procedure TLispExpression.Loaded;
begin
  inherited loaded;

  if (MainTask = nil) then
     raise Exception.Create('TLispExpression.Loaded: Lisp system not initialized');

  MyOwnEnvironment := nil;
  Representation   := nil;
  Parameters       := nil;
  ResultNode       := nil;

  LspLockNodeAddress(@MyOwnEnvironment);
  LspLockNodeAddress(@Representation);
  LspLockNodeAddress(@Parameters);
  LspLockNodeAddress(@ResultNode);
end;



procedure TLispExpression.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('Data', ReadBinaryData, WriteBinaryData, ExpressionBinary <> nil);
end;


procedure TLispExpression.ReadBinaryData(Stream: TStream);
begin
  ExpressionBinary := StrAlloc(Stream.Size);
  Stream.ReadBuffer(ExpressionBinary^, Stream.Size);
end;



procedure TLispExpression.WriteBinaryData(Stream: TStream);
begin
  Stream.WriteBuffer(ExpressionBinary^, StrBufSize(ExpressionBinary));
end;



(*----------------------------------------------------------------------------*)
(* Die textuelle Darstellung der Lisp-Ausdruecke in eine Lisp-Darstellung     *)
(* umwandeln.                                                                 *)
(*----------------------------------------------------------------------------*)
function TLispExpression.InternalRepresentation: pNode;
var m: TMemoryStream;
begin
  m := TMemoryStream.Create;
  Expression.SaveToStream(m);
  result := GetListFromStream(m);
  m.Free;
end;



(*----------------------------------------------------------------------------*)
(* Von den Strings, also dem Text, in Representation einlesen.                *)
(* Alle Variablen, also Symbole der Art ?a, ?test, usw. werden in der Liste   *)
(* Parameters gespeichert. Die lokale Umgebung von TLispExpression ergibt     *)
(* sich aus dem Append von den Parametern und der globalen Umgebung.          *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.Prepare;
var loop,ListOfVariables,Pair: pNode;
begin
  if (MainTask = nil) then
     raise Exception.Create('TLispExpression: Lisp system not started');

  Representation   := InternalRepresentation;
  MyOwnEnvironment := MainTask.Environment; (* wird noch verlaengert *)
  Parameters       := nil;
  ListOfVariables  := LspGetVariables(Representation,nil);
  loop             := ListOfVariables;
  while (loop <> nil) do
     begin
       Pair             := LspList2(LspCar(loop),nil);
       Parameters       := LspCons(Pair,Parameters);
       MyOwnEnvironment := LspCons(Pair,MyOwnEnvironment);
       loop             := LspCdr(loop);
     end;

(*
LspPrint(Representation,nil);
LspPrint(Parameters,nil);
LspPrint(MyOwnEnvironment,nil);
*)
end;



(*----------------------------------------------------------------------------*)
(* Die Liste Representation laden. Der letzte Wert steht dann in Result       *)
(* Mit Laden ist der Load-Befehl von Lisp gemeint, also alle Anweisungen      *)
(* der Reihe nach ausfuehren.                                                 *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.Execute;
var loop: pNode;
begin
  ResultNode := nil;
  loop := Representation;
  while (loop <> nil) do
     begin
       ResultNode := LspEval(LspCar(loop),MyOwnEnvironment);
       loop       := LspCdr(loop);
     end;
end;





(*----------------------------------------------------------------------------*)
(* Einen Zeiger auf die interne Repraesentation eines Parameters liefern.     *)
(* Ein Ergebnis <> nil wird nur geliefert, wenn der Parameter auch in der     *)
(* Liste Parameters vorkommt.                                                 *)
(*----------------------------------------------------------------------------*)
function TLispExpression.ParamByName(s: string): pNode;
var AsNode: pNode;
begin
  AsNode := LspMakeSymbol(s);
  result := LspAssoc(AsNode,Parameters);
  if (result <> nil) then
     result := LspCar(result);
end;



(*----------------------------------------------------------------------------*)
(* Einen Parameter setzen.                                                    *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.SetIntegerParam(s: string; value: longint);
begin
  LspSetq(ParamByName(s),LspMakeInteger(value),MyOwnEnvironment);
end;



(*----------------------------------------------------------------------------*)
(* Einen Parameter setzen.                                                    *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.SetFloatParam(s: string; value: double);
begin
  LspSetq(ParamByName(s),LspMakeFloat(value),MyOwnEnvironment);
end;



(*----------------------------------------------------------------------------*)
(* Einen Parameter setzen.                                                    *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.SetStringParam(s: string; value: string);
begin
  LspSetq(ParamByName(s),LspMakeString(value),MyOwnEnvironment);
end;



(*----------------------------------------------------------------------------*)
(* Einen Parameter setzen.                                                    *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.SetSymbolParam(s: string; value: string);
begin
  LspSetq(ParamByName(s),LspMakeSymbol(value),MyOwnEnvironment);
end;



(*----------------------------------------------------------------------------*)
(* Einen Parameter setzen.                                                    *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.SetBooleanParam(s: string; value: boolean);
begin
  LspSetq(ParamByName(s),BoolToNode(value),MyOwnEnvironment);
end;



(*----------------------------------------------------------------------------*)
(* Einen Parameter setzen.                                                    *)
(*----------------------------------------------------------------------------*)
procedure TLispExpression.SetNodeParam(s: string; value: pNode);
begin
  LspSetq(ParamByName(s),value,MyOwnEnvironment);
end;



function TLispExpression.AsNode: pNode;
begin
  result := ResultNode;
end;



function TLispExpression.AsInteger: longint;
begin
  if (LspIntegerp(ResultNode)) then
     result := LspGetIntegerVal(ResultNode)
  else
     result := 0;
end;



function TLispExpression.AsFloat: double;
begin
  if (LspNumberp(ResultNode)) then
     result := LspGetFloatVal(ResultNode)
  else
     result := 0.0;
end;



function TLispExpression.AsString: string;
begin
  if (LspStringp(ResultNode)) then
     result := LspGetStringVal(ResultNode)
  else
     result := '';
end;


function TLispExpression.AsSymbol: string;
begin
  if (LspSymbolp(ResultNode)) then
     result := LspGetStringVal(LspSymbolName(ResultNode))
  else
     result := '';
end;


function TLispExpression.AsBoolean: boolean;
begin
  result := ResultNode <> nil;
end;


end.
