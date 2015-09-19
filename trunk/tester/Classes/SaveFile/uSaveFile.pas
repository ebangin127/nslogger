unit uSaveFile;

interface

uses SysUtils, IniFiles;

type
  TIniFile64 = class(TIniFile)
  public
    function ReadInt64(const Section, Ident: string; Default: Int64): Int64;
    function ReadUInt64(const Section, Ident: string; Default: UInt64): UInt64;
  end;

  TSaveFile = class
  private
    FMaxTBW: UINT64;
    FRetTBW: UINT64;
    FCurrTBW: UINT64;

    FStartLatency, FEndLatency: Int64; //Unit: us(10^-6)
    FSumLatency, FMaxLatency: Int64; //Unit: us(10^-6)
    FRandomSeed: Int64;
    FErrorCount: Integer;
    FMaxFFR: Integer;

    FOverallTestCount: Integer;
    FIterator: Integer;
    FDisknum: Integer;

    FTracePath: String;
    FModel: String;
    FSerial: String;

    FNeedVerify: Boolean;
  public
    //TGSTestThread
    property NeedVerify: Boolean read FNeedVerify write FNeedVerify;
    property MaxTBW: UINT64 read FMaxTBW write FMaxTBW;
    property RetTBW: UINT64 read FRetTBW write FRetTBW;
    property MaxFFR: Integer read FMaxFFR write FMaxFFR;
    property CurrTBW: UINT64 read FCurrTBW write FCurrTBW;
    property TracePath: String read FTracePath write FTracePath;
    property Model: String read FModel write FModel;
    property Serial: String read FSerial write FSerial;

    //TGSTester
    property StartLatency: Int64 read FStartLatency write FStartLatency;
    property EndLatency: Int64 read FEndLatency write FEndLatency;
    property SumLatency: Int64 read FSumLatency write FSumLatency;
    property MaxLatency: Int64 read FMaxLatency write FMaxLatency;
    property RandomSeed: Int64 read FRandomSeed write FRandomSeed;
    property ErrorCount: Integer read FErrorCount write FErrorCount;

    property OverallTestCount: Integer read FOverallTestCount write FOverallTestCount;
    property Iterator: Integer read FIterator write FIterator;
    property Disknum: Integer read FDisknum write FDisknum;

    function SaveToFile(FilePath: String): Boolean;
    function LoadFromFile(FilePath: String): Boolean;
  end;

implementation

{ TSaveFile }

function TSaveFile.LoadFromFile(FilePath: String): Boolean;
var
  IniFile: TIniFile64;
begin
  if not FileExists(FilePath) then
    exit(false);

  try
    IniFile := TIniFile64.Create(FilePath);
  except
    FreeAndNil(IniFile);
    exit(false);
  end;

  NeedVerify := IniFile.ReadBool('MainInfo', 'NeedVerify', false);
  MaxTBW := IniFile.ReadUInt64('MainInfo', 'MaxTBW', 0);
  RetTBW := IniFile.ReadUInt64('MainInfo', 'RetTBW', 0);
  MaxFFR := IniFile.ReadInteger('MainInfo', 'MaxFFR', 0);
  CurrTBW := IniFile.ReadUInt64('MainInfo', 'CurrTBW', 0);
  TracePath := IniFile.ReadString('MainInfo', 'TracePath', '');
  Model := IniFile.ReadString('MainInfo', 'Model', '');
  Serial := IniFile.ReadString('MainInfo', 'Serial', '');

  StartLatency := IniFile.ReadInt64('TesterInfo', 'StartLatency', 0);
  EndLatency := IniFile.ReadInt64('TesterInfo', 'EndLatency', 0);
  SumLatency := IniFile.ReadInt64('TesterInfo', 'SumLatency', 0);
  MaxLatency := IniFile.ReadInt64('TesterInfo', 'MaxLatency', 0);
  RandomSeed := IniFile.ReadInt64('TesterInfo', 'RandomSeed', 0);
  ErrorCount := IniFile.ReadInt64('TesterInfo', 'ErrorCount', 0);

  OverallTestCount := IniFile.ReadInteger('TesterInfo', 'OverallTestCount', 0);
  Iterator := IniFile.ReadInteger('TesterInfo', 'Iterator', 0);
  Disknum := IniFile.ReadInteger('TesterInfo', 'Disknum', 0);

  result := true;
  FreeAndNil(IniFile);
end;

function TSaveFile.SaveToFile(FilePath: String): Boolean;
var
  IniFile: TIniFile;
begin
  try
    IniFile := TIniFile.Create(FilePath);
  except
    FreeAndNil(IniFile);
    exit(false);
  end;

  IniFile.WriteBool('MainInfo', 'NeedVerify', NeedVerify);
  IniFile.WriteString('MainInfo', 'MaxTBW', UIntToStr(MaxTBW));
  IniFile.WriteString('MainInfo', 'RetTBW', UIntToStr(RetTBW));
  IniFile.WriteInteger('MainInfo', 'MaxFFR', MaxFFR);
  IniFile.WriteString('MainInfo', 'CurrTBW', UIntToStr(CurrTBW));
  IniFile.WriteString('MainInfo', 'TracePath', TracePath);
  IniFile.WriteString('MainInfo', 'Model', Model);
  IniFile.WriteString('MainInfo', 'Serial', Serial);

  IniFile.WriteString('TesterInfo', 'StartLatency', IntToStr(StartLatency));
  IniFile.WriteString('TesterInfo', 'EndLatency', IntToStr(EndLatency));
  IniFile.WriteString('TesterInfo', 'SumLatency', IntToStr(SumLatency));
  IniFile.WriteString('TesterInfo', 'MaxLatency', IntToStr(MaxLatency));
  IniFile.WriteString('TesterInfo', 'RandomSeed', IntToStr(RandomSeed));
  IniFile.WriteInteger('TesterInfo', 'ErrorCount', ErrorCount);

  IniFile.WriteInteger('TesterInfo', 'OverallTestCount', OverallTestCount);
  IniFile.WriteInteger('TesterInfo', 'Iterator', Iterator);
  IniFile.WriteInteger('TesterInfo', 'Disknum', Disknum);

  result := true;
  FreeAndNil(IniFile);
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

end.
