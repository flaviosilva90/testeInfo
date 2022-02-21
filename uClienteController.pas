unit uClienteController;

interface

uses   Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, JvExStdCtrls, JvCombobox,
  Vcl.Buttons, IdIOHandler, IdIOHandlerSocket, IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdHTTP, Vcl.Mask, JvExMask, JvToolEdit, JvMaskEdit, Vcl.ExtCtrls,
  Vcl.ComCtrls, JvExComCtrls, JvComCtrls, System.JSON,
  IdMessage, IdExplicitTLSClientServerBase, uClienteVO, System.Generics.Collections,
  IdMessageClient,  IdSMTPBase,  IdSMTP, IdAttachmentFile,  IdText, XMLDoc, XMLIntf;


type
  TClienteController = class
  protected
  public

    class function CriaListaClientes: TObjectList<TClienteVO>;
    class function EnviarEmail(resp : TObjectList<TClienteVO>) : boolean;
    class function ConstruirXML(arquivo : TObjectList<TClienteVO>) : boolean;
    class function RetirarCaracteresEspeciais(texto : string) : string;
  end;

implementation

{ TClienteController }

class function TClienteController.ConstruirXML(
  arquivo: TObjectList<TClienteVO>): boolean;
var
  XMLDocument: TXMLDocument;
  Tabela, Registro, Endereco: IXMLNode;
  I: Integer;
begin
  Result := True;

  try
    XMLDocument := TXMLDocument.Create(nil);
    XMLDocument.Active := True;
    Tabela := XMLDocument.AddChild('Clientes');

    for I := 0 to Pred(arquivo.Count) do
    begin
      Registro := Tabela.AddChild('Registro');

      Registro.ChildValues['Nome'] := arquivo[i].Nome;
      Registro.ChildValues['Identidade'] := RetirarCaracteresEspeciais(arquivo[i].Identidade);
      Registro.ChildValues['CPF'] := RetirarCaracteresEspeciais(arquivo[i].CPF);
      Registro.ChildValues['Telefone'] := RetirarCaracteresEspeciais(arquivo[i].Telefone);
      Registro.ChildValues['Email'] := arquivo[i].Email;

      Endereco := Registro.AddChild('Endereco');
      Endereco.ChildValues['CEP'] := arquivo[i].Cep;
      Endereco.ChildValues['Logradouro'] := arquivo[i].Logradouro;
      Endereco.ChildValues['Numero'] := arquivo[i].Numero;
      Endereco.ChildValues['Complemento'] := arquivo[i].Complemento;
      Endereco.ChildValues['Bairro'] := arquivo[i].Bairro;
      Endereco.ChildValues['Cidade'] := arquivo[i].Cidade;
      Endereco.ChildValues['Estado'] := arquivo[i].Estado;
      Endereco.ChildValues['Pais'] := arquivo[i].Pais;
    end;
    XMLDocument.SaveToFile(ExtractFilePath(Application.ExeName)+'clientes.xml');

  except
    begin
      Result := False;
      Exit;
    end;
  end;

end;

class function TClienteController.CriaListaClientes: TObjectList<TClienteVO>;
begin
  Result := TObjectList<TClienteVO>.Create;
end;

class function TClienteController.EnviarEmail(
  resp: TObjectList<TClienteVO>): boolean;
var
  idMsg                : TIdMessage;
  IdText               : TIdText;
  idSMTP               : TIdSMTP;
  IdSSLIOHandlerSocket : TIdSSLIOHandlerSocketOpenSSL;
  i : integer;
begin
  if not ConstruirXML(resp) then
  begin
    Exit;
  end;

  try
    try

      IdSSLIOHandlerSocket                   := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
      IdSSLIOHandlerSocket.SSLOptions.Method := sslvSSLv23;
      IdSSLIOHandlerSocket.SSLOptions.Mode   := sslmClient;

      idMsg                            := TIdMessage.Create(nil);
      idMsg.CharSet                    := 'utf-8';
      idMsg.Encoding                   := meMIME;
      idMsg.From.Name                  := 'Teste InfoSistemas';
      idMsg.From.Address               := 'fdsilva.desenv@gmail.com';
      idMsg.Priority                   := mpNormal;
      idMsg.Subject                    := 'Lista de Clientes - Teste Flávio';

      idMsg.Recipients.Add;
      idMsg.Recipients.EMailAddresses := 'gustavo.maia@infosistemas.com.br';
      idMsg.BccList.EMailAddresses    := 'fdsilva.desenv@gmail.com';
		  idMsg.CCList.EMailAddresses     := 'luciana.carvalho@infosistemas.com.br';

      idText := TIdText.Create(idMsg.MessageParts);
      for I := 0 to Pred(resp.Count) do
      begin
        idText.Body.Add('Cliente: '+resp[i].Nome + #13 +
                        'Identidade: '+resp[i].Identidade + #13 +
                        'CPF: '+resp[i].CPF + #13 +
                        'Telefone: '+resp[i].Telefone + #13 +
                        'Email: '+resp[i].Email + #13#13 +
                        'Endereço.: '+#13+
                        'CEP: '+resp[i].CEP + #13 +
                        'Logradouro: '+resp[i].Logradouro + #13 +
                        'Número: '+resp[i].Numero + #13 +
                        'Complemento: '+resp[i].Complemento + #13 +
                        'Bairro: '+resp[i].Bairro + #13 +
                        'Cidade: '+resp[i].Cidade + #13 +
                        'Estado: '+resp[i].Estado + #13 +
                        'País: '+resp[i].Pais + #13);

        idText.Body.Add('----------------------------------------------------');

      end;
      idText.ContentType := 'text/html; text/plain; charset=iso-8859-1';

      IdSMTP                           := TIdSMTP.Create(nil);
      IdSMTP.IOHandler                 := IdSSLIOHandlerSocket;
      IdSMTP.UseTLS                    := utUseImplicitTLS;
      IdSMTP.Host                      := 'smtp.gmail.com';
      IdSMTP.AuthType                  := satDefault;
      IdSMTP.Port                      := 465;
      IdSMTP.Username                  := 'fdsilva.desenv@gmail.com';
      IdSMTP.Password                  := 'hmfjkaovyuhhocvt';

      IdSMTP.Connect;
      IdSMTP.Authenticate;

      if FileExists(ExtractFilePath(Application.ExeName)+'clientes.xml') then
        TIdAttachmentFile.Create(idMsg.MessageParts, ExtractFilePath(Application.ExeName)+'clientes.xml');

      if IdSMTP.Connected then
      begin
        try
          IdSMTP.Send(idMsg);
        except on E:Exception do
          begin
            Result := False;
            Showmessage(e.message);
            Exit;
          end;
        end;
      end;

      if IdSMTP.Connected then
        IdSMTP.Disconnect;

      Result := True;
    finally

      UnLoadOpenSSLLibrary;

    end;
  except on e:Exception do
    begin
      Result := False;
      ShowMessage(e.message);
      Exit;
    end;
  end;

end;

class function TClienteController.RetirarCaracteresEspeciais(
  texto: string): string;
var
  vText : PChar;
begin
  vText := PChar(texto);
  Result := '';

  while (vText^ <> #0) do
  begin
    {$IFDEF UNICODE}
    if CharInSet(vText^, ['0'..'9']) then
    {$ELSE}
    if vText^ in ['0'..'9'] then
    {$ENDIF}
      Result := Result + vText^;

    Inc(vText);
  end;

end;

end.
