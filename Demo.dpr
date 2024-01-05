program Demo;

uses
  Forms,
  demomain in 'demomain.pas' {FormDemoMain};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFormDemoMain, FormDemoMain);
  Application.Run;
end.
