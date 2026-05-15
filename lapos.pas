unit lapos;

// Version: 1.0.0
const LAPOS_VERSION = '1.0.0';

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, vpiPC;

type
  TForm3 = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}



begin
    exec_command()
end.
