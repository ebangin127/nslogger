unit SaveFile;

interface

uses SysUtils, IniFiles;

type
  TIniFile64 = class(TIniFile)
  public
    function ReadInt64(const Section, Ident: string; Default: Int64): Int64;
    function ReadUInt64(const Section, Ident: string; Default: UInt64): UInt64;
    procedure WriteInt64(const Section, Ident: string; const Value: Int64);
    procedure WriteUInt64(const Section, Ident: string; const Value: UInt64);
  end;

  TSaveFile = class
  private
    FIniFile: TIniFile64;
  public
    procedure SaveBoolean(const Section, Ident: String; const Value: Boolean);
    procedure SaveInteger(const Section, Ident: String; const Value: Integer);
    procedure SaveInt64(const Section, Ident: String; const Value: Int64);
    procedure SaveUInt64(const Section, Ident: String; const Value: UInt64);
    procedure SaveString(const Section, Ident: String; const Value: String);
    procedure SaveDouble(const Section, Ident: String; const Value: Double);

    function LoadBoolean(const Section, Ident: String): Boolean;
    function LoadInteger(const Section, Ident: String): Integer;
    function LoadInt64(const Section, Ident: String): Int64;
    function LoadUInt64(const Section, Ident: String): UInt64;
    function LoadString(const Section, Ident: String): String;
    function LoadDouble(const Section, Ident: String): Double;

    constructor Create(const FilePath: String);
    destructor Destroy; override;
  end;

implementation

procedure TSaveFile.SaveBoolean(const Section, Ident: String;
  const Value: Boolean);
begin
  FIniFile.WriteBool(Section, Ident, Value);
end;

procedure TSaveFile.SaveDouble(const Section, Ident: String;
  const Value: Double);
begin
  FIniFile.WriteFloat(Section, Ident, Value);
end;

procedure TSaveFile.SaveInteger(const Section, Ident: String;
  const Value: Integer);
begin
  FIniFile.WriteInteger(Section, Ident, Value);
end;

procedure TSaveFile.SaveUInt64(const Section, Ident: String;
  const Value: UInt64);
begin
  FIniFile.WriteUInt64(Section, Ident, Value);
end;

procedure TSaveFile.SaveInt64(const Section, Ident: String; const Value: Int64);
begin
  FIniFile.WriteInt64(Section, Ident, Value);
end;

procedure TSaveFile.SaveString(const Section, Ident: String;
  const Value: String);
begin
  FIniFile.WriteString(Section, Ident, Value);
end;

function TSaveFile.LoadBoolean(const Section, Ident: String): Boolean;
begin
  result := FIniFile.ReadBool(Section, Ident, false);
end;

function TSaveFile.LoadDouble(const Section, Ident: String): Double;
begin
  result := FIniFile.ReadFloat(Section, Ident, 0);
end;

function TSaveFile.LoadInt64(const Section, Ident: String): Int64;
begin
  result := FIniFile.ReadInt64(Section, Ident, 0);
end;

function TSaveFile.LoadInteger(const Section, Ident: String): Integer;
begin
  result := FIniFile.ReadInteger(Section, Ident, 0);
end;

function TSaveFile.LoadUInt64(const Section, Ident: String): UInt64;
begin
  result := FIniFile.ReadUInt64(Section, Ident, 0);
end;

function TSaveFile.LoadString(const Section, Ident: String): String;
begin
  result := FIniFile.ReadString(Section, Ident, '');
end;

constructor TSaveFile.Create(const FilePath: String);
begin
  FIniFile := TIniFile64.Create(FilePath);
end;

destructor TSaveFile.Destroy;
begin
  FreeAndNil(FIniFile);
end;

{ TIniFile64 }

function TIniFile64.ReadInt64(const Section, Ident: string;
  Default: Int64): Int64;
begin
  result := StrToInt64(ReadString(Section, Ident, IntToStr(Default)));
end;

function TIniFile64.ReadUInt64(const Section, Ident: string;
  Default: UInt64): UInt64;
begin
  result := StrToUInt64(ReadString(Section, Ident, UIntToStr(Default)));
end;

procedure TIniFile64.WriteInt64(const Section, Ident: string;
  const Value: Int64);
begin
  WriteString(Section, Ident, IntToStr(Value));
end;

procedure TIniFile64.WriteUInt64(const Section, Ident: string;
  const Value: UInt64);
begin
  WriteString(Section, Ident, UIntToStr(Value));
end;

end.
