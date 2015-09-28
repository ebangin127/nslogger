unit uGSNode;

interface

type
  TIOType = (ioRead, ioWrite, ioTrim, ioFlush);

  TGSNode = record
    FIOType: TIOType;
    FLength: Word;
    FLBA: UInt64;
    constructor CreateByValues(IOType: TIOType; LBALength: Word; LBA: UInt64);
    function GetIOType: TIOType;
    function GetLength: Word;
    function GetLBA: UInt64;
  end;

implementation

{ TGSNode }

constructor TGSNode.CreateByValues(IOType: TIOType; LBALength: Word;
  LBA: UInt64);
begin
  self.FIOType := IOType;
  self.FLength := LBALength;
  self.FLBA := LBA;
end;

function TGSNode.GetIOType: TIOType;
begin
  result := FIOType;
end;

function TGSNode.GetLBA: UInt64;
begin
  result := FLBA;
end;

function TGSNode.GetLength: Word;
begin
  result := FLength;
end;

end.
