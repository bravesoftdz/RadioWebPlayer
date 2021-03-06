unit URadioWebPlayerUtils;

interface

uses Classes, SysUtils, Windows, Forms, FileCtrl, Dialogs;

type
  TParamFile = record
                 Name,
                 Value: string;
               end;
  TArrayParams = array of TParamFile;
  TPositionApp = packed record
                   Left, Top, Height, Width: Cardinal;
                 end;

function GetArquivoConfig: TStringList;
function GetArquivoRadios: TStringList;
function GetConfigFileName: string;
function CarregarArquivoConfiguracao: Boolean;
//procedure GravarConfiguracoes(ArquivoRadios: string; IniciarWindows: Boolean); overload;
procedure GravarConfiguracoes(AParams: TArrayParams); //overload;
procedure CarregarArquivoRadios(FileName: string);
procedure GravarArquivoRadios(lst: TStringList; FileName: string);
procedure SetMute;
function GetVolume: Cardinal;
procedure SetVolume(aVolume: Byte);
procedure LerArquivoConfiguracao;
procedure GravarUltimaPosicao;
procedure RecuperaPosSizeForm(AForm: TForm);
procedure AplicaPosSizeForm(AForm: TForm);

const
  DEFAULT_INI = 'RadioWebPlayer.ini';
  VK_VOLUME_MUTE = $AD;
  VK_VOLUME_DOWN = $AE;
  VK_VOLUME_UP   = $AF;

implementation

uses StrUtils, UVolumeControl;

var
  FArquivoConfig,
  FArquivoRadios: TStringList;
  FArquivoConfigFileName,
  FArquivoRadiosFileName: string;
  FLastPositionApp: TPositionApp;

function GetArquivoConfig: TStringList;
begin
  Result := FArquivoConfig;
end;

function GetArquivoRadios: TStringList;
begin
  Result := FArquivoRadios;
end;

function GetConfigFileName: string;
begin
  Result := ExtractFilePath(Application.ExeName)+DEFAULT_INI;
end;

function CarregarArquivoConfiguracao: Boolean;
var
  sConfigFile: string;
begin
  sConfigFile := GetConfigFileName;

  if (not Assigned(FArquivoConfig)) then
    FArquivoConfig := TStringList.Create;
  FArquivoConfig.Clear;

  Result := FileExists(sConfigFile);

  if Result then
  begin
    FArquivoConfig.LoadFromFile(sConfigFile);
    FArquivoConfigFileName := sConfigFile;
  end;
end;

procedure CarregarArquivoRadios(FileName: string);
begin
  if (not Assigned(FArquivoRadios)) then
    FArquivoRadios := TStringList.Create;
  FArquivoRadios.Clear;

  if FileExists(FileName) then
  begin
    FArquivoRadios.LoadFromFile(FileName);
    FArquivoRadiosFileName := FileName;
  end
  else
    MessageDlg('Arquivo de configura��o "'+FileName+'" n�o encontrado.',
      mtError, [mbOK], 0);
end;

procedure GravarArquivoRadios(lst: TStringList; FileName: string);
begin
  FArquivoRadios.Text := lst.Text;
  FArquivoRadios.SaveToFile(FileName);
end;

procedure GravarConfiguracoes(AParams: TArrayParams);
var
  I: Integer;
begin
  with GetArquivoConfig do
    for I := 0 to Pred(Length(AParams)) do
      if (AParams[I].Name <> '') then
        Values[AParams[I].Name] := AParams[I].Value;

  FArquivoConfig.SaveToFile(FArquivoConfigFileName);
end;

procedure SetMute;
begin
  keybd_event(VK_VOLUME_MUTE, MapVirtualKey(VK_VOLUME_MUTE,0), 0, 0);
  keybd_event(VK_VOLUME_MUTE, MapVirtualKey(VK_VOLUME_MUTE,0), KEYEVENTF_KEYUP, 0);
end;

function GetVolume: Cardinal;
begin
  Result := UVolumeControl.GetVolume(DEVICE_MASTER);
end;

procedure SetVolume(aVolume: Byte);
var
  I:Integer;
begin
  SetMute;
  for I := 0 to aVolume do
  begin
    keybd_event(VK_VOLUME_UP, MapVirtualKey(VK_VOLUME_UP,0), 0, 0);
    keybd_event(VK_VOLUME_UP, MapVirtualKey(VK_VOLUME_UP,0), KEYEVENTF_KEYUP, 0);
  end;
end;

procedure LerArquivoConfiguracao;
var
  sLastPos, sSizeWindow: string;
begin
  if not CarregarArquivoConfiguracao then
    raise Exception.CreateFmt('N�o foi poss�vel carregar o arquivo de configura��o "%s"!', [GetConfigFileName]);

  sLastPos    := FArquivoConfig.Values['LastPos'];
  sSizeWindow := FArquivoConfig.Values['SizeWindow'];
  if (sLastPos <> '') then
  begin
    FLastPositionApp.Top  := StrToIntDef(Copy(sLastPos, 1, Pos(',', sLastPos)-1), 0);
    FLastPositionApp.Left := StrToIntDef(Copy(sLastPos, Pos(',', sLastPos)+1, Length(sLastPos)-Pos(',', sLastPos)), 0);
  end;

  if (sSizeWindow <> '') then
  begin
    FLastPositionApp.Height := StrToIntDef(Copy(sSizeWindow, 1, Pos(',', sSizeWindow)-1), 0);
    FLastPositionApp.Width  := StrToIntDef(Copy(sSizeWindow, Pos(',', sSizeWindow)+1, Length(sSizeWindow)-Pos(',', sSizeWindow)), 0);
  end;

  Application.ShowMainForm := FArquivoConfig.Values['IniciarMinimizado'] <> 'S';
  CarregarArquivoRadios(FArquivoConfig.Values['ArquivoRadios']);  
end;

procedure GravarUltimaPosicao;
var
  Params: TArrayParams;
begin
  SetLength(Params, 2);
  Params[0].Name := 'LastPos';
  Params[0].Value:= IntToStr(FLastPositionApp.Top)+','+IntToStr(FLastPositionApp.Left);
  Params[1].Name := 'SizeWindow';
  Params[1].Value:= IntToStr(FLastPositionApp.Height)+','+IntToStr(FLastPositionApp.Width);
  GravarConfiguracoes(Params);
end;

procedure RecuperaPosSizeForm(AForm: TForm);
begin
  FLastPositionApp.Left  := AForm.Left;
  FLastPositionApp.Top   := AForm.Top;
  FLastPositionApp.Height:= AForm.Height;
  FLastPositionApp.Width := AForm.Width;
end;

procedure AplicaPosSizeForm(AForm: TForm);
begin
  if ((FLastPositionApp.Height > 0) and (FLastPositionApp.Width > 0)) then
  begin
    AForm.Left  := FLastPositionApp.Left;
    AForm.Top   := FLastPositionApp.Top;
   // AForm.Height:= FLastPositionApp.Height;
   // AForm.Width := FLastPositionApp.Width;
  end;
end;

initialization
  LerArquivoConfiguracao;
finalization
  GravarUltimaPosicao;
end.

