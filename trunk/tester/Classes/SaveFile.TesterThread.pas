unit SaveFile.TesterThread;

interface

uses
  SaveFile;

type
  TSaveFileForTesterThread = class
  private
    SaveFile: TSaveFile;
  public
    procedure SetDiskNumber(const Value: Integer);
    procedure SetTracePath(const Value: String);
    procedure SetTraceOriginalLBA(const Value: String);
    function GetTBWToRetention: UInt64;
    procedure SetTBWToRetention(const Value: UInt64);
    function GetRandomSeed: Int64;
    procedure SetRandomSeed(const Value: Int64);
    function GetMaxFFR: Integer;
    procedure SetMaxFFR(const Value: Integer);
    function GetNeedRetention: Boolean;
    procedure SetNeedRetention(const Value: Boolean);
    function GetLastRetention: Integer;
    procedure SetLastRetention(const Value: Integer);

    constructor Create(const SaveFileToOpen: TSaveFile);
    destructor Destroy; override;
  end;
implementation

{ TSaveFileForSettingForm }

constructor TSaveFileForTesterThread.Create(const SaveFileToOpen: TSaveFile);
begin
  SaveFile := SaveFileToOpen;
end;

destructor TSaveFileForTesterThread.Destroy;
begin
  SaveFile.Free;
  inherited;
end;

procedure TSaveFileForTesterThread.SetDiskNumber(const Value: Integer);
begin
  SaveFile.SaveInteger('Target', 'DiskNumber', Value);
end;

function TSaveFileForTesterThread.GetTBWToRetention: UInt64;
begin
  result := SaveFile.LoadUInt64('TBW', 'ToRetention');
end;

procedure TSaveFileForTesterThread.SetTBWToRetention(const Value: UInt64);
begin
  SaveFile.SaveUInt64('TBW', 'ToRetention', Value);
end;

procedure TSaveFileForTesterThread.SetRandomSeed(const Value: Int64);
begin
  SaveFile.SaveInt64('General', 'RandomSeed', Value);
end;

function TSaveFileForTesterThread.GetRandomSeed: Int64;
begin
  result := SaveFile.LoadInt64('General', 'RandomSeed');
end;

procedure TSaveFileForTesterThread.SetTraceOriginalLBA(const Value: String);
begin
  SaveFile.SaveString('Trace', 'OriginalLBA', Value);
end;

procedure TSaveFileForTesterThread.SetTracePath(const Value: String);
begin
  SaveFile.SaveString('Trace', 'Path', Value);
end;

function TSaveFileForTesterThread.GetMaxFFR: Integer;
begin
  result := SaveFile.LoadInteger('General', 'MaxFFR');
end;

procedure TSaveFileForTesterThread.SetMaxFFR(const Value: Integer);
begin
  SaveFile.SaveInteger('General', 'MaxFFR', Value);
end;

function TSaveFileForTesterThread.GetNeedRetention: Boolean;
begin
  result := SaveFile.LoadBoolean('General', 'NeedVerify');
end;

procedure TSaveFileForTesterThread.SetNeedRetention(const Value: Boolean);
begin
  SaveFile.SaveBoolean('General', 'NeedVerify', Value);
end;

function TSaveFileForTesterThread.GetLastRetention: Integer;
begin
  result := SaveFile.LoadInteger('TBW', 'LastRetentionTBW');
end;

procedure TSaveFileForTesterThread.SetLastRetention(const Value: Integer);
begin
  SaveFile.SaveInteger('TBW', 'LastRetentionTBW', Value);
end;

end.
