unit SaveFile.TesterIterator;

interface

uses
  SaveFile;

type
  TSaveFileForTesterIterator = class
  private
    SaveFile: TSaveFile;
  public
    function GetHostWrite: Int64;
    procedure SetHostWrite(const Value: Int64);
    function GetSumLatency: UInt64;
    procedure SetSumLatency(const Value: UInt64);
    function GetStartLatency: Int64;
    procedure SetStartLatency(const Value: Int64);
    function GetEndLatency: Int64;
    procedure SetEndLatency(const Value: Int64);
    function GetMaxLatency: Int64;
    procedure SetMaxLatency(const Value: Int64);
    function GetErrorCount: Integer;
    procedure SetErrorCount(const Value: Integer);
    function GetOverallTestCount: Integer;
    procedure SetOverallTestCount(const Value: Integer);
    function GetIterator: Integer;
    procedure SetIterator(const Value: Integer);
    function GetMeasureCount: Integer;
    procedure SetMeasureCount(const Value: Integer);

    constructor Create(const SaveFileToOpen: TSaveFile);
    destructor Destroy; override;
  end;
implementation

{ TSaveFileForSettingForm }

constructor TSaveFileForTesterIterator.Create(const SaveFileToOpen: TSaveFile);
begin
  SaveFile := SaveFileToOpen;
end;

destructor TSaveFileForTesterIterator.Destroy;
begin
  SaveFile.Free;
  inherited;
end;

function TSaveFileForTesterIterator.GetHostWrite: Int64;
begin
  result := SaveFile.LoadInt64('TBW', 'Written');
end;

function TSaveFileForTesterIterator.GetEndLatency: Int64;
begin
  result := SaveFile.LoadInt64('Latency', 'End');
end;

function TSaveFileForTesterIterator.GetErrorCount: Integer;
begin
  result := SaveFile.LoadInteger('General', 'ErrorCount');
end;

function TSaveFileForTesterIterator.GetIterator: Integer;
begin
  result := SaveFile.LoadInteger('General', 'Iterator');
end;

function TSaveFileForTesterIterator.GetMaxLatency: Int64;
begin
  result := SaveFile.LoadInteger('Latency', 'Max');
end;

function TSaveFileForTesterIterator.GetOverallTestCount: Integer;
begin
  result := SaveFile.LoadInteger('General', 'OverallTestCount');
end;

function TSaveFileForTesterIterator.GetStartLatency: Int64;
begin
  result := SaveFile.LoadInt64('Latency', 'Start');
end;

function TSaveFileForTesterIterator.GetSumLatency: UInt64;
begin
  result := SaveFile.LoadUInt64('Latency', 'Sum');
end;

function TSaveFileForTesterIterator.GetMeasureCount: Integer;
begin
  result := SaveFile.LoadInteger('Latency', 'MeasureCount');
end;

procedure TSaveFileForTesterIterator.SetMeasureCount(const Value: Integer);
begin
  SaveFile.SaveInteger('Latency', 'MeasureCount', Value);
end;

procedure TSaveFileForTesterIterator.SetEndLatency(const Value: Int64);
begin
  SaveFile.SaveInt64('Latency', 'End', Value);
end;

procedure TSaveFileForTesterIterator.SetErrorCount(const Value: Integer);
begin
  SaveFile.SaveInteger('General', 'ErrorCount', Value);
end;

procedure TSaveFileForTesterIterator.SetHostWrite(const Value: Int64);
begin
  SaveFile.SaveInt64('TBW', 'Written', Value);
end;

procedure TSaveFileForTesterIterator.SetIterator(const Value: Integer);
begin
  SaveFile.SaveInteger('General', 'Iterator', Value);
end;

procedure TSaveFileForTesterIterator.SetMaxLatency(const Value: Int64);
begin
  SaveFile.SaveInt64('Latency', 'Max', Value);
end;

procedure TSaveFileForTesterIterator.SetOverallTestCount(const Value: Integer);
begin
  SaveFile.SaveInteger('General', 'OverallTestCount', Value);
end;

procedure TSaveFileForTesterIterator.SetStartLatency(const Value: Int64);
begin
  SaveFile.SaveInt64('Latency', 'Start', Value);
end;

procedure TSaveFileForTesterIterator.SetSumLatency(const Value: UInt64);
begin
  SaveFile.SaveUInt64('Latency', 'Sum', Value);
end;

end.
