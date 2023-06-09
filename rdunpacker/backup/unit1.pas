unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  XMLPropStorage, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    LogMemo: TMemo;
    OpenDialog1: TOpenDialog;
    PkgEdit: TEdit;
    DirEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    PkgBtn: TSpeedButton;
    DirBtn: TSpeedButton;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    UnpackBtn: TSpeedButton;
    StaticText2: TStaticText;
    MainFormStorage: TXMLPropStorage;
    procedure DirBtnClick(Sender: TObject);
    procedure DirEditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PkgBtnClick(Sender: TObject);
    procedure UnpackBtnClick(Sender: TObject);
    procedure UnpackProcess(Command: string);

  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SCompleted = 'Completed. Result in';

implementation

{$R *.lfm}

{ TMainForm }


//Процедура запуска распаковки
procedure TMainForm.UnpackProcess(Command: string);
var
  ExProcess: TProcess;
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
  try
    ExProcess := TProcess.Create(nil);
    LogMemo.Clear;

    ExProcess.Options := ExProcess.Options + [poWaitOnExit, poUsePipes,
      poStdErrToOutput];

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(Command);

    ExProcess.Execute;
    LogMemo.Lines.LoadFromStream(ExProcess.Output);
    //Завершение
    LogMemo.Lines.Add('');
    LogMemo.Lines.Add(SCompleted + ' ' + DirEdit.Text + '/' +
      Copy(PkgEdit.Text, Length(PkgEdit.Text) - 2, 3));

  finally
    ExProcess.Free;
    Screen.Cursor := crDefault;
  end;
end;

//Для разных DPI
procedure TMainForm.FormShow(Sender: TObject);
begin
  MainFormStorage.Restore;

  MainForm.Caption := Application.Title;

  DirBtn.Width := DirEdit.Height;
  PkgBtn.Width := PkgEdit.Height;
end;

//Выбор пакета
procedure TMainForm.PkgBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LogMemo.Clear;
    PkgEdit.Text := OpenDialog1.FileName;
  end;
end;

procedure TMainForm.UnpackBtnClick(Sender: TObject);
begin
  LogMemo.Clear;

  if (not FileExists(PkgEdit.Text)) or (not DirectoryExists(DirEdit.Text)) then
    LogMemo.Lines.Add('!--the folder does not exist for unpacking...')
  else
  begin
    LogMemo.Lines.Add('---unpack started, please wait...');

    //Текущий каталог
    SetCurrentDir(DirEdit.Text);

    if Copy(PkgEdit.Text, Length(PkgEdit.Text) - 3, 4) = '.rpm' then
      UnpackProcess('rm -rf ./tmp ./rpm; mkdir ./tmp ./rpm; 7z x -y "' +
        PkgEdit.Text +
        '" -o./tmp; if [ -f ./tmp/*.zstd ]; then cd ./tmp; zstd -df ./*.zstd; cd -; fi; ' +
        //'" -o./tmp; if [ -f ./tmp/*.zstd ]; then cd ./tmp; 7z x -y ./*.zstd; cd -; fi; '
        '7z x -y ./tmp/*.cpio -o./rpm; rm -rf ./tmp')
    else
      UnpackProcess('rm -rf ./tmp ./deb; mkdir ./tmp ./deb; 7z x -y "' +
        PkgEdit.Text + '" -o./tmp; cd ./tmp; f=$(ls *data*); ext=${f##*.}; cd -; '
        + '[ "$ext" != "tar" ] && tar -xvf ./tmp/data.tar.$ext -C ./deb || ' +
        'tar -xvf ./tmp/data.tar -C ./deb; rm -rf ./tmp');

     { UnpackProcess('rm -rf ./tmp ./deb; mkdir ./tmp ./deb; 7z x -y "' +
        PkgEdit.Text + '" -o./tmp; cd ./tmp; f=$(ls *data*); ext=${f##*.}; cd -; '
        + '[ "$ext" != "tar" ] && 7z x -y ./tmp/data.tar.$ext -o./deb || ' +
        '7z x -y ./tmp/data.tar -o./deb; rm -rf ./tmp'); }

    //Промотать список вниз
    LogMemo.SelStart := Length(LogMemo.Text);
    LogMemo.SelLength := 0;
  end;
end;

//Конфигурация
procedure TMainForm.FormCreate(Sender: TObject);
begin
  if not DirectoryExists(GetUserDir + '.config') then MkDir(GetUserDir + '.config');
  MainFormStorage.FileName := GetUserDir + '.config/rpmdeb-unpacker.cfg';
end;

procedure TMainForm.DirEditChange(Sender: TObject);
begin
  if (DirEdit.Text = '') or (PkgEdit.Text = '') then
    UnpackBtn.Enabled := False
  else
    UnpackBtn.Enabled := True;
end;

//Выбор каталога для распаковки
procedure TMainForm.DirBtnClick(Sender: TObject);
begin
  if SelectDirectoryDialog1.Execute then
    DirEdit.Text := SelectDirectoryDialog1.FileName;
end;

end.
