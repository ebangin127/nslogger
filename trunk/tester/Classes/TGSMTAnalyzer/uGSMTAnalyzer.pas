unit uGSMTAnalyzer;

interface

uses uGSList, Math;

const
  MaxIOUnit = 65536;
  DivIOUnit = 512;
  IOCountArrayLength = (MaxIOUnit div DivIOUnit) + 2; {Min IO Unit ~ Max IO Unit
                                                        + Over Max IO Unit}
  TouchedArea: Double = 49.0 / 128.0;

type
  TGSMTAnalyzer = class
  private
    FMasterTrace: PTGSList;
    FIOCount: Array[0..IOCountArrayLength - 1] of UINT64;

    FWriteByTrace: UINT64;
    FWriteBySpeedTest: UINT64;

    FIteratorNum: Integer;
    FIteratorLBA: UINT64;

    FPassedAction: TGSNode;

    function ReadMasterTrace: Boolean;
  public
    constructor Create; overload;
    constructor Create(ReceivedList: PTGSList); overload;
    destructor Destroy; override;

    function AssignList(NewList: PTGSList): Boolean;

    function GetWriteBySpeedTest: UINT64;
    function GetError: Double;

    function GetNextAction: PTGSNode;
    function GetLength: UINT64;
    procedure GoToFirst;
  end;

implementation

function TGSMTAnalyzer.ReadMasterTrace: Boolean;
var
  CurrItem: Integer;
  TraceLength: Integer;
  CurrLengthType: Integer;

  CurrTraceNode: PTGSNode;
begin
  result := false;
  if FMasterTrace = nil then
    exit;

  FMasterTrace.GoToFirst;
  TraceLength := FMasterTrace.GetLength;
  for CurrItem := 0 to TraceLength - 1 do
  begin
    CurrTraceNode := FMasterTrace.GetNextItem;
    if CurrTraceNode.FIOType <> TIOTypeInt[ioWrite] then
      Continue;

    CurrLengthType := ceil(CurrTraceNode.FLength / DivIOUnit);
    if CurrLengthType >= IOCountArrayLength then
      CurrLengthType := IOCountArrayLength - 1;

    Inc(FIOCount[CurrLengthType], 1);

    Inc(FWriteByTrace, CurrTraceNode.FLength);
    Inc(FWriteBySpeedTest, CurrLengthType * DivIOUnit);
  end;

  result := true;
end;

constructor TGSMTAnalyzer.Create;
begin

end;

constructor TGSMTAnalyzer.Create(ReceivedList: PTGSList);
begin
  if AssignList(ReceivedList) = false then
    Create;
end;

destructor TGSMTAnalyzer.Destroy;
begin

end;

function TGSMTAnalyzer.AssignList(NewList: PTGSList): Boolean;
begin
  result := false;
  if NewList = nil then
    exit;

  FMasterTrace := NewList;
  result := ReadMasterTrace;
end;

//Get Total Write Byte within Emulated Write Test by This Class
function TGSMTAnalyzer.GetWriteBySpeedTest: UINT64;
begin
  result := 0;
  if FMasterTrace = nil then
    exit;

  result := FWriteBySpeedTest;
end;

function TGSMTAnalyzer.GetError: Double;
begin
  result := 0;
  if FMasterTrace = nil then
    exit;

  result := (FWriteBySpeedTest - FWriteByTrace) / FWriteByTrace * 100;
end;

function TGSMTAnalyzer.GetNextAction: PTGSNode;
var
  CurrIteratorNum: INT64;
  CurrIOUnit: Integer;
begin
  result := nil;
  if FMasterTrace = nil then
    exit;

  CurrIteratorNum := FIteratorNum;
  result := @FPassedAction;
  result.FIOType := TIOTypeInt[ioWrite];
  //For over-length iterator num
  while CurrIteratorNum > -1 do
  begin
    for CurrIOUnit := 0 to Length(FIOCount) - 1 do
    begin
      if CurrIteratorNum < FIOCount[CurrIOUnit] then
      begin
        result.FLBA := FIteratorLBA;
        result.FLength := (CurrIOUnit + 1) * DivIOUnit;
        CurrIteratorNum := -1;

        //Adding Numbers for next iteration
        Inc(FIteratorNum, 1);
        Inc(FIteratorLBA, result.FLength);

        break;
      end
      else
      begin
        Dec(CurrIteratorNum, FIOCount[CurrIOUnit]);
      end;
    end;

    //If the iterator is pointing over-length position
    if CurrIteratorNum > 0 then
    begin
      FIteratorNum := CurrIteratorNum;
      FIteratorLBA := 0;
    end;
  end;
  Inc(CurrIteratorNum, 1);
end;

function TGSMTAnalyzer.GetLength: UINT64;
var
  CurrIOCount: Integer;
begin
  result := 0;

  for CurrIOCount := 0 to Length(FIOCount) - 1 do
  begin
    result := result + FIOCount[CurrIOCount];
  end;
end;

procedure TGSMTAnalyzer.GoToFirst;
begin
  FIteratorNum := 0;
  FIteratorLBA := 0;
end;
end.
