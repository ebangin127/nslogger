unit Tester.CommandIssuer;

interface

uses
  Windows, SysUtils, Generics.Collections, MMSystem,
  RandomBuffer, Trace.Node, CommandSet, CommandSet.Factory,
  Device.PhysicalDrive, Device.SMART.List, ErrorCode.List, Error.List,
  Overlapped, Overlapped.List, Overlapped.OS, Overlapped.AnonymousMethod;

const
  MaxIOSize = 65536;
  TimeoutInMilliSec = 10000;
  MaxParallelIO = 4;

type
  TCommandResult = record
    OverlapFinished: Boolean;
  end;

  TTesterCommandIssuer = class
  private
    type
      T48BitLBA = record
        Hi, Lo: UINT;
      end;
  private
    FOverlappedList: TOverlappedList;
    FRandomBuffer: TRandomBuffer;
    FDriveHandle: THandle;
    FCommandSet: TCommandSet;
    FPendingCommandList: TList<TTraceNode>;
    FFailedCommandList: TErrorList;
    function AddAndIfFullClear(const Overlap: IOverlapped): TCommandResult;
    function LBATo48BitLBA(const LBAInInt64: Int64): T48BitLBA;
    function LBAToByte(const LBA: Cardinal): Cardinal;
    function ValidResult(const ErrorCode: Cardinal): Boolean;
    function GetOverlap(const LBA: T48BitLBA): POverlapped;
    procedure RefreshFailedCommandSet;
    function AddOSOverlappedAndIfFullClear(
      const Overlap: POverlapped): TCommandResult;
  public
    function DiskWrite(const Contents: TTraceNode): TCommandResult;
    function DiskRead(const Contents: TTraceNode): TCommandResult;
    function DiskTrim(const Contents: TTraceNode): TCommandResult;
    function DiskFlush: TCommandResult;
    function GetSMARTList: TSMARTValueList;
    function ClearList: TErrorCodeList;
    function SetDisk(DriveNumber: Integer): Boolean;
    function AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
    function GetFailedCommandList: TErrorList;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

function TTesterCommandIssuer.GetFailedCommandList: TErrorList;
begin
  result := FFailedCommandList;
end;

function TTesterCommandIssuer.GetOverlap(const LBA: T48BitLBA): POverlapped;
begin
  GetMem(result, SizeOf(_OVERLAPPED));
  ZeroMemory(result, sizeof(_OVERLAPPED));
  result.hEvent := CreateEvent(nil, true, false, nil);
  result.Offset := LBA.Lo;
  result.OffsetHigh := LBA.Hi;
end;

function TTesterCommandIssuer.GetSMARTList: TSMARTValueList;
begin
  result := FCommandSet.SMARTReadData;
end;

function TTesterCommandIssuer.LBAToByte(const LBA: Cardinal): Cardinal;
begin
  result := LBA shl 9;
end;

function TTesterCommandIssuer.LBATo48BitLBA(const LBAInInt64: Int64): T48BitLBA;
begin
  result.Lo := LBAInInt64 shl 9 and $FFFFFFFF;
  result.Hi := LBAInInt64 shr 23 and $FFFFFFFF;
end;

function TTesterCommandIssuer.ValidResult(const ErrorCode: Cardinal):
  Boolean;
begin
  result := (ErrorCode = ERROR_SUCCESS) or (ErrorCode = ERROR_IO_PENDING);
end;

function TTesterCommandIssuer.AddOSOverlappedAndIfFullClear(
  const Overlap: POverlapped): TCommandResult;
begin
  result := AddAndIfFullClear(TOSOverlapped.Create(FDriveHandle, Overlap));
end;

function TTesterCommandIssuer.AddAndIfFullClear(const Overlap: IOverlapped):
  TCommandResult;
begin
  result.OverlapFinished := false;
  FOverlappedList.Add(Overlap);
  if FOverlappedList.Count > MaxParallelIO then
  begin
    RefreshFailedCommandSet;
    result.OverlapFinished := true;
  end;
end;

procedure TTesterCommandIssuer.RefreshFailedCommandSet;
var
  ErrorCodeList: TErrorCodeList;
  CurrentIndex: Integer;
begin
  ErrorCodeList := ClearList;
  if not ErrorCodeList.IsAllSucceed then
  begin
    for CurrentIndex := 0 to ErrorCodeList.Count - 1 do
      if ErrorCodeList[CurrentIndex] > ERROR_SUCCESS then
        FFailedCommandList.Add(CreateErrorNode(
          FPendingCommandList[CurrentIndex], ErrorCodeList[CurrentIndex]));
  end;
  FreeAndNil(ErrorCodeList);
  FPendingCommandList.Clear;
end;

function TTesterCommandIssuer.DiskWrite(const Contents: TTraceNode):
  TCommandResult;
var
  BytesWritten: Cardinal;
  BufferPoint: Pointer;
  LBA: T48BitLBA;
  IOLength: Cardinal;
  Overlap: POverlapped;
begin
  result.OverlapFinished := false;
  IOLength := LBAToByte(Contents.GetLength);
  BufferPoint := FRandomBuffer.GetBufferPtr(IOLength);
  LBA := LBATo48BitLBA(Contents.GetLBA);

  Overlap := GetOverlap(LBA);
  WriteFile(FDriveHandle, BufferPoint^, IOLength, BytesWritten, Overlap);
  if not ValidResult(GetLastError) then
    FFailedCommandList.Add(CreateErrorNode(Contents, GetLastError));

  if GetLastError = ERROR_IO_PENDING then
  begin
    FPendingCommandList.Add(Contents);
    result := AddOSOverlappedAndIfFullClear(Overlap);
  end;
end;

function TTesterCommandIssuer.DiskRead(const Contents: TTraceNode):
  TCommandResult;
var
  BytesRead: Cardinal;
  BufferPoint: Pointer;
  LBA: T48BitLBA;
  IOLength: UINT;
  Overlap: POverlapped;
  ReadBuffer: Array[0..MaxIOSize - 1] of Byte;
begin
  result.OverlapFinished := false;
  IOLength := LBAToByte(Contents.GetLength);
  BufferPoint := @ReadBuffer;
  LBA := LBATo48BitLBA(Contents.GetLBA);

  Overlap := GetOverlap(LBA);
  ReadFile(FDriveHandle, BufferPoint, IOLength, BytesRead, Overlap);
  if not ValidResult(GetLastError) then
    FFailedCommandList.Add(CreateErrorNode(Contents, GetLastError));

  if GetLastError = ERROR_IO_PENDING then
  begin
    FPendingCommandList.Add(Contents);
    result := AddOSOverlappedAndIfFullClear(Overlap);
  end;
end;

function TTesterCommandIssuer.DiskTrim(const Contents: TTraceNode):
  TCommandResult;
var
  CapturedLBA: UInt64;
  CapturedLength: Word;
begin
  result.OverlapFinished := false;
  CapturedLBA := Contents.GetLBA;
  CapturedLength := Contents.GetLength;

  FPendingCommandList.Add(Contents);
  result := AddAndIfFullClear(TAnonymousMethodOverlapped.Create(
    function: Cardinal
    begin
      result :=
        FCommandSet.DataSetManagement(CapturedLBA, CapturedLength);
    end));
end;

function TTesterCommandIssuer.DiskFlush: TCommandResult;
begin
  result := AddAndIfFullClear(TAnonymousMethodOverlapped.Create(
    function: Cardinal
    begin
      result := ERROR_SUCCESS;
      try
        FCommandSet.Flush;
      except
        on E: EOSError do
          result := E.ErrorCode
        else
          raise;
      end;
    end));
end;

function TTesterCommandIssuer.ClearList: TErrorCodeList;
begin
  result := FOverlappedList.WaitAndGetErrorCode;
  FOverlappedList.Clear;
end;

constructor TTesterCommandIssuer.Create;
begin
  FOverlappedList := TOverlappedList.Create;
  FPendingCommandList := TList<TTraceNode>.Create;
  FFailedCommandList := TErrorList.Create;
end;

destructor TTesterCommandIssuer.Destroy;
begin
  if FDriveHandle <> 0 then
  begin
    CloseHandle(FDriveHandle);
    FreeAndNil(FCommandSet);
    FDriveHandle := 0;
  end;
  FreeAndNil(FOverlappedList);
  FreeAndNil(FFailedCommandList);
  FreeAndNil(FPendingCommandList);
end;

function TTesterCommandIssuer.SetDisk(DriveNumber: Integer): Boolean;
begin
  if FDriveHandle <> 0 then
  begin
    CloseHandle(FDriveHandle);
    FreeAndNil(FCommandSet);
    FDriveHandle := 0;
  end;

  FDriveHandle :=
    CreateFile(PChar(TPhysicalDrive.BuildFileAddressByNumber(DriveNumber)),
      GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE,
      nil, OPEN_EXISTING, FILE_FLAG_NO_BUFFERING or FILE_FLAG_OVERLAPPED, 0);
  FCommandSet :=
    CommandSetFactory.GetSuitableCommandSet(
      TPhysicalDrive.BuildFileAddressByNumber(DriveNumber));

  result := (GetLastError = 0);
end;

function TTesterCommandIssuer.AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
begin
  result := RandBuf <> nil;
  FRandomBuffer := RandBuf^;
end;
end.


