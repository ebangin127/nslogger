unit Tester.CommandIssuer;

interface

uses
  Windows, SysUtils, Generics.Collections, MMSystem,
  uRandomBuffer, Trace.Node, uCommandSet, uCommandSetFactory,
  Device.PhysicalDrive;

const
  MaxIOSize = 65536;
  TimeoutInMilliSec = 10000;
  MaxParallelIO = 4;

type
  TCommandResult = record
    CommandSuccess: Boolean;
    OverlapFinished: Boolean;
  end;

  TTesterCommandIssuer = class
  private
    type
      T48BitLBA = record
        Hi, Lo: UINT;
      end;
  private
    FOverlapped: TList<POVERLAPPED>;
    FRandomBuffer: TRandomBuffer;
    FDriveHandle: THandle;
    FCommandSet: TCommandSet;
    function GetOverlapPtr(const LBA: T48BitLBA): POVERLAPPED;
    function WaitForOverlapped(Handle: THandle;
      pOverlapped: POVERLAPPED): Cardinal;
    function AddAndIfFullClear(const Overlap: POVERLAPPED): TCommandResult;

    procedure DisposeOverlapPtr(const POVERLAPPEDToDispose: POVERLAPPED);
    function LBATo48BitLBA(const LBAInInt64: Int64): T48BitLBA;
    function LBAToByte(const LBA: Cardinal): Cardinal;
    function ValidResult(const ErrorCode: Cardinal): Boolean;

  public
    function DiskWrite(const Contents: TTraceNode): TCommandResult;
    function DiskRead(const Contents: TTraceNode): TCommandResult;
    function DiskTrim(const Contents: TTraceNode): TCommandResult;
    function DiskFlush: TCommandResult;
    function ClearList: Boolean;
    function SetDisk(DriveNumber: Integer): Boolean;
    function AssignBuffer(RandBuf: PTRandomBuffer): Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

function TTesterCommandIssuer.GetOverlapPtr(const LBA: T48BitLBA):
  POVERLAPPED;
begin
  GetMem(result, sizeof(OVERLAPPED));
  FillMemory(result, sizeof(OVERLAPPED), 0);
  result.hEvent := CreateEvent(nil, true, false, nil);
  result.Offset := LBA.Lo;
  result.OffsetHigh := LBA.Hi;
end;

procedure TTesterCommandIssuer.DisposeOverlapPtr(const POVERLAPPEDToDispose:
  POVERLAPPED);
begin
  CloseHandle(POVERLAPPEDToDispose.hEvent);
  FreeMem(POVERLAPPEDToDispose);
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

function TTesterCommandIssuer.WaitForOverlapped(Handle: THandle;
  pOverlapped: POVERLAPPED): Cardinal;
var
  BytesReturned: DWORD;
begin
  WaitForSingleObject(pOverlapped.hEvent, TimeoutInMilliSec);
  result := 0;

  if (not GetOverlappedResult(Handle, pOverlapped^, BytesReturned, false)) or
     (BytesReturned = 0)
  then
  begin
    result := GetLastError;
  end;
end;

function TTesterCommandIssuer.AddAndIfFullClear(const Overlap: POVERLAPPED):
  TCommandResult;
begin
  result.OverlapFinished := false;
  FOverlapped.Add(Overlap);
  if FOverlapped.Count > MaxParallelIO then
  begin
    result.CommandSuccess := ClearList;
    result.OverlapFinished := true;
  end;
end;

function TTesterCommandIssuer.DiskWrite(const Contents: TTraceNode):
  TCommandResult;
var
  BytesWritten: Cardinal;
  BufferPoint: Pointer;
  LBA: T48BitLBA;
  IOLength: Cardinal;
  Overlap: POVERLAPPED;
  AddAndIfFullClearResult: TCommandResult;
begin
  result.OverlapFinished := false;
  IOLength := LBAToByte(Contents.GetLength);
  BufferPoint := FRandomBuffer.GetBufferPtr(IOLength);
  LBA := LBATo48BitLBA(Contents.GetLBA);
  Overlap := GetOverlapPtr(LBA);

  WriteFile(FDriveHandle, BufferPoint^, IOLength, BytesWritten, Overlap);
  result.CommandSuccess := ValidResult(GetLastError);

  if GetLastError = ERROR_IO_PENDING then
  begin
    AddAndIfFullClearResult := AddAndIfFullClear(Overlap);
    if AddAndIfFullClearResult.OverlapFinished then
      result := AddAndIfFullClearResult;
  end
  else if result.CommandSuccess then
    DisposeOverlapPtr(Overlap);
end;

function TTesterCommandIssuer.DiskRead(const Contents: TTraceNode):
  TCommandResult;
var
  BytesRead: Cardinal;
  BufferPoint: Pointer;
  LBA: T48BitLBA;
  IOLength: UINT;
  Overlap: POVERLAPPED;
  ReadBuffer: Array[0..MaxIOSize - 1] of Byte;
  AddAndIfFullClearResult: TCommandResult;
begin
  result.OverlapFinished := false;
  IOLength := LBAToByte(Contents.GetLength);
  BufferPoint := @ReadBuffer;
  LBA := LBATo48BitLBA(Contents.GetLBA);
  Overlap := GetOverlapPtr(LBA);

  ReadFile(FDriveHandle, BufferPoint, IOLength, BytesRead, Overlap);
  result.CommandSuccess := ValidResult(GetLastError);

  if GetLastError = ERROR_IO_PENDING then
  begin
    AddAndIfFullClearResult := AddAndIfFullClear(Overlap);
    if AddAndIfFullClearResult.OverlapFinished then
      result := AddAndIfFullClearResult;
  end
  else if result.CommandSuccess then
    DisposeOverlapPtr(Overlap);
end;

function TTesterCommandIssuer.DiskTrim(const Contents: TTraceNode):
  TCommandResult;
var
  TrimResult: Cardinal;
begin
  result.OverlapFinished := true;
  TrimResult :=
    FCommandSet.DataSetManagement(Contents.GetLBA, Contents.GetLength);
  result.CommandSuccess := TrimResult = ERROR_SUCCESS;
end;

function TTesterCommandIssuer.DiskFlush: TCommandResult;
var
  FlushResult: Cardinal;
begin
  result.OverlapFinished := true;
  FlushResult := ERROR_SUCCESS;
  try
    FCommandSet.Flush;
  except
    on E: EOSError do
      FlushResult := E.ErrorCode
    else
      raise;
  end;
  result.CommandSuccess := FlushResult = ERROR_SUCCESS;
end;

function TTesterCommandIssuer.ClearList: Boolean;
var
  Overlap: POVERLAPPED;
begin
  result := true;

  if FOverlapped.Count = 0 then
    exit;

  for Overlap in FOverlapped do
  begin
    result :=
      result and
      (WaitForOverlapped(FDriveHandle, Overlap) = ERROR_SUCCESS);
    DisposeOverlapPtr(Overlap);
  end;
  FOverlapped.Clear;
end;

constructor TTesterCommandIssuer.Create;
begin
  FOverlapped := TList<POVERLAPPED>.Create;
end;

destructor TTesterCommandIssuer.Destroy;
begin
  if FDriveHandle <> 0 then
  begin
    CloseHandle(FDriveHandle);
    FreeAndNil(FCommandSet);
    FDriveHandle := 0;
  end;
  FreeAndNil(FOverlapped);
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


