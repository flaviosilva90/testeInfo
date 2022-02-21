unit uCadCliente;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JvExStdCtrls, JvCombobox,
  Vcl.Buttons, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, Vcl.Mask, JvExMask, JvToolEdit, JvMaskEdit, Vcl.ExtCtrls,
  Vcl.ComCtrls, JvExComCtrls, JvComCtrls, System.JSON,
  IdMessage, IdExplicitTLSClientServerBase, uClienteVO, uClienteController, System.Generics.Collections,
  IdMessageClient,  IdSMTPBase,  IdSMTP, IdAttachmentFile,  IdText, XMLDoc, XMLIntf;

type
  TfrmCadCliente = class(TForm)
    PageControl1: TJvPageControl;
    TabDados: TTabSheet;
    Panel1: TPanel;
    GroupBox3: TGroupBox;
    Label16: TLabel;
    Label19: TLabel;
    edtNome: TEdit;
    edtDoc: TJvMaskEdit;
    GroupBox4: TGroupBox;
    Label13: TLabel;
    Label15: TLabel;
    edtTel1: TJvMaskEdit;
    edtEmail: TEdit;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    btnBuscaCEP: TSpeedButton;
    Label4: TLabel;
    Label12: TLabel;
    Label5: TLabel;
    Label17: TLabel;
    Label6: TLabel;
    edtCep: TJvMaskEdit;
    edtLogradouro: TEdit;
    edtNumero: TEdit;
    edtCidade: TEdit;
    cbxUF: TJvComboBox;
    edtComplemento: TEdit;
    edtBairro: TEdit;
    edtPais: TEdit;
    btnGravar: TSpeedButton;
    btnLimpar: TSpeedButton;
    Label7: TLabel;
    edtIdentidade: TEdit;
    procedure btnLimparClick(Sender: TObject);
    procedure btnBuscaCEPClick(Sender: TObject);
    procedure btnGravarClick(Sender: TObject);
    procedure edtCepExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure edtDocExit(Sender: TObject);
  private
    { Private declarations }

    LPesquisaCep : boolean;
    LInsereMaisClientes : boolean;
    LContadorClientes : integer;
    ListaClientes: TObjectList<TClienteVO>;
    Cliente : TClienteVO;

    function BuscarEndereco : boolean;
    procedure LimparCampos;
    function RegistrarCliente : boolean;
    procedure ValidarCPF(CPF : string);
  public
    { Public declarations }
  end;

var
  frmCadCliente: TfrmCadCliente;

implementation

{$R *.dfm}

{ TForm1 }

procedure TfrmCadCliente.btnBuscaCEPClick(Sender: TObject);
begin
  LPesquisaCep := True;
  if not BuscarEndereco then
  begin
    MessageDlg('CEP Inv�lido.',mtError,[mbOK],0);
    LimparCampos;
    edtCep.SetFocus;
  end;
end;

procedure TfrmCadCliente.btnGravarClick(Sender: TObject);

  Function ValidaCampos : boolean;
  begin
    Result := True;

    if (edtNome.Text = '') or (edtDoc.Text = '') or (edtCep.Text = '') then
      Result := False;
  end;
begin
  LPesquisaCep := False;

  if not ValidaCampos then
  begin
    MessageDlg('Campos que possuem "*" s�o obrigat�rios.',mtError,[mbOK],0);
    Exit;
  end;

  if not RegistrarCliente and LInsereMaisClientes then
  begin
    MessageDlg('Cliente n�o foi cadastrado. Favor reavaliar os dados informados.',mtError,[mbOK],0);
    Exit;
  end;
end;

procedure TfrmCadCliente.btnLimparClick(Sender: TObject);
begin
  LimparCampos;
end;

function TfrmCadCliente.BuscarEndereco: boolean;
var
  LURL, sResponse : string;
  ArrayCep : TJSONArray;
  cont : integer;
begin

  LURL := 'https://viacep.com.br/ws/' + TClienteController.RetirarCaracteresEspeciais(edtCep.Text)+'/json';

  IdHTTP1.Request.Clear;
  idHttp1.Request.CustomHeaders.Clear;
  IdHTTP1.Request.Accept := 'application/json';
  idHTTP1.Request.ContentType := 'application/json';
  idHTTP1.Request.CharSet := 'utf-8';

  try
    sResponse := idHTTP1.Get(LURL);
    sResponse := '[' + sResponse + ']';
    ArrayCep := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(sResponse),0) as TJSONArray;
    for cont := 0 to ArrayCep.Size -1 do
    begin
      edtLogradouro.Text := ArrayCep.Get(cont).GetValue<string>('logradouro');
      edtBairro.Text := ArrayCep.Get(cont).GetValue<string>('bairro');
      cbxUF.Text := ArrayCep.Get(cont).GetValue<string>('uf');
      edtCidade.Text := ArrayCep.Get(cont).GetValue<string>('localidade');
    end;

  except
    Result := false;
    Exit;
  end;

  Result := true;
  ArrayCep.DisposeOf;
end;


procedure TfrmCadCliente.edtCepExit(Sender: TObject);
begin
  btnBuscaCEP.OnClick(Self);
end;

procedure TfrmCadCliente.edtDocExit(Sender: TObject);
begin
  if MessageDlg('Deseja validar o CPF?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
    ValidarCPF(TClienteController.RetirarCaracteresEspeciais(edtDoc.Text));
end;

procedure TfrmCadCliente.FormCreate(Sender: TObject);
begin
  LInsereMaisClientes := false;
  LContadorClientes := 0;
end;

procedure TfrmCadCliente.LimparCampos;
begin
  if not LPesquisaCep then
  begin
    edtNome.Clear;
    edtIdentidade.Clear;
    edtDoc.Clear;
    edtDoc.EditMask := '!000.000.000-00;0;_';
    edtTel1.Clear;
    edtTel1.EditMask := '!\(99\)00000-0000;0;_';
    edtEmail.Clear;
    edtCep.Clear;
    edtCep.EditMask := '00000\-999;0;_';
  end;

  edtLogradouro.Clear;
  edtNumero.Clear;
  edtBairro.Clear;
  edtCidade.Clear;
  edtComplemento.Clear;
  edtPais.Clear;
  cbxUF.ItemIndex := -1;

  edtNome.SetFocus;
end;

function TfrmCadCliente.RegistrarCliente : Boolean;
var
  mensagem : string;
begin
  Result := True;

  if not LInsereMaisClientes then
    ListaClientes := TClienteController.CriaListaClientes;

  try
    ListaClientes.Add(TClienteVO.Create);
    ListaClientes[LContadorClientes].Nome := edtNome.Text;
    ListaClientes[LContadorClientes].CPF  := edtDoc.Text;
    ListaClientes[LContadorClientes].Identidade := edtIdentidade.Text;
    ListaClientes[LContadorClientes].Telefone := edtTel1.Text;
    ListaClientes[LContadorClientes].Email := edtEmail.Text;
    ListaClientes[LContadorClientes].CEP := edtCep.Text;
    ListaClientes[LContadorClientes].Logradouro := edtLogradouro.Text;
    ListaClientes[LContadorClientes].Numero := edtNumero.Text;
    ListaClientes[LContadorClientes].Complemento := edtComplemento.Text;
    ListaClientes[LContadorClientes].Bairro := edtBairro.Text;
    ListaClientes[LContadorClientes].Cidade := edtCidade.Text;
    ListaClientes[LContadorClientes].Estado := cbxUF.Text;
    ListaClientes[LContadorClientes].Pais := edtPais.Text;
  except
    Result := false;
    LInsereMaisClientes := true;
    Exit;
  end;

  if ListaClientes.Count = 1 then
    mensagem := 'do cliente cadastrado ao inv�s de continuar cadastrando mais clientes'
  else
    mensagem := 'dos clientes (total.: '+IntToStr(ListaClientes.Count)+') cadastrados ao inv�s de continuar cadastrando mais clientes';

  LContadorClientes := LContadorClientes + 1;
  if MessageDlg('Deseja enviar o e-mail '+mensagem+'?',mtConfirmation,[mbYes,mbNo],0) = mrYes then
  begin
    if not TClienteController.EnviarEmail(ListaClientes) then
    begin
      MessageDlg('Erro ao enviar e-mail.',mtError,[mbOK],0);
    end
    else
    begin
      MessageDlg('E-mail enviado com sucesso.',mtInformation,[mbOK],0);
      if Assigned(ListaClientes) then
      begin
        try
          ListaClientes.Clear;
          FreeAndNil(ListaClientes);
          LInsereMaisClientes := false;
          LContadorClientes := 0;
        except
        end;
      end;
    end;
  end
  else
    LInsereMaisClientes := true;

  LimparCampos;
end;

procedure TfrmCadCliente.ValidarCPF(CPF : string);
var  dig10, dig11: string;
    s, i, r, peso: integer;
begin

  if ((CPF = '00000000000') or (CPF = '11111111111') or
      (CPF = '22222222222') or (CPF = '33333333333') or
      (CPF = '44444444444') or (CPF = '55555555555') or
      (CPF = '66666666666') or (CPF = '77777777777') or
      (CPF = '88888888888') or (CPF = '99999999999') or
      (length(CPF) <> 11)) then
      begin
        MessageDlg('CPF Inv�lido.',mtError,[mbOK],0);
        edtDoc.Clear;
        edtDoc.EditMask := '!000.000.000-00;0;_';
        exit;
      end;


  try

    s := 0;
    peso := 10;
    for i := 1 to 9 do
    begin

      s := s + (StrToInt(CPF[i]) * peso);
      peso := peso - 1;
    end;
    r := 11 - (s mod 11);
    if ((r = 10) or (r = 11)) then
      dig10 := '0'
    else
      str(r:1, dig10);


    s := 0;
    peso := 11;
    for i := 1 to 10 do
    begin
      s := s + (StrToInt(CPF[i]) * peso);
      peso := peso - 1;
    end;
    r := 11 - (s mod 11);
    if ((r = 10) or (r = 11)) then
      dig11 := '0'
    else
      str(r:1, dig11);


    if ((dig10 = CPF[10]) and (dig11 = CPF[11])) then
      MessageDlg('CPF v�lido.',mtInformation,[mbOK],0)
    else
    begin
      MessageDlg('CPF Inv�lido.',mtError,[mbOK],0);
      edtDoc.Clear;
      edtDoc.EditMask := '!000.000.000-00;0;_';
      Exit;
    end;
  except
    begin
      MessageDlg('CPF Inv�lido.',mtError,[mbOK],0);
      edtDoc.Clear;
      edtDoc.EditMask := '!000.000.000-00;0;_';
      Exit;
    end;
  end;

end;

end.
