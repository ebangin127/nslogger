unit Trace.Node;

interface

type
  TIOType = (ioRead, ioWrite, ioTrim, ioFlush);

  TTraceNode = record
    FIOType: TIOType;
    FLength: Word;
    FLBA: UInt64;
    constructor CreateByValues(IOType: TIOType; LBALength: Word; LBA: UInt64);
    function GetIOType: TIOType;
    function GetLength: Word;
    function GetLBA: UInt64;
  end;

implementation

{ TTraceNode }

constructor TTraceNode.CreateByValues(IOType: TIOType; LBALength: Word;
  LBA: UInt64);
begin
  self.FIOType := IOType;
  self.FLength := LBALength;
  self.FLBA := LBA;
end;

function TTraceNode.GetIOType: TIOType;
begin
  result := FIOType;
end;

function TTraceNode.GetLBA: UInt64;
begin
  result := FLBA;
end;

function TTraceNode.GetLength: Word;
begin
  result := FLength;
end;

end.
