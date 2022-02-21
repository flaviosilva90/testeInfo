program testeInfo;

uses
  Vcl.Forms,
  uCadCliente in 'uCadCliente.pas' {frmCadCliente},
  uClienteVO in 'uClienteVO.pas',
  uClienteController in 'uClienteController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmCadCliente, frmCadCliente);
  Application.Run;
end.
