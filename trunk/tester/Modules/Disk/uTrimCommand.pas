unit uTrimCommand;

interface

uses Classes, SysUtils, uDiskFunctions, Dialogs, Windows;

function SendTrimCommand(const DriveLetter: String; StartLBA, LBACount: Int64):
                          Cardinal; overload;
function SendTrimCommand(const hPhyDevice: THandle; StartLBA, LBACount: Int64):
                          Cardinal; overload;
function SendTrimCommand(const hPhyDevice: THandle; StartLBA, LBACount: Int64;
                          pOverlapped: POVERLAPPED): Cardinal; overload;

function SendFlushCommand(const DriveLetter: String): Cardinal; overload;
function SendFlushCommand(const hPhyDevice: THandle): Cardinal; overload;
function SendFlushCommand(const hPhyDevice: THandle; pOverlapped: POVERLAPPED):
                         Cardinal; overload;

function ReadSector(const hPhyDevice: THandle; StartLBA: Int64;
                    Buffer: PTLLBufferLarge): Integer;

const
  TRIM_ZeroSector = 1;
  TRIM_NonZeroSector = 0;
  TRIM_Error = 2;

implementation

function SendTrimCommand(const DriveLetter: String; StartLBA, LBACount: Int64): Cardinal;
var
  hPhyDevice: THandle;
begin
  hPhyDevice := CreateFile(
                PChar(DriveLetter),
                GENERIC_READ or GENERIC_WRITE,
                FILE_SHARE_READ or FILE_SHARE_WRITE,
                nil,
                OPEN_EXISTING,
                0,
                0);

  result := SendTrimCommand(hPhyDevice, StartLBA, LBACount);

  CloseHandle(hPhyDevice);
end;

function SendTrimCommand(const hPhyDevice: THandle; StartLBA, LBACount: Int64): Cardinal;
begin
  result := SendTrimCommand(hPhyDevice, StartLBA, LBACount, nil);
end;

function SendTrimCommand(const hPhyDevice: THandle; StartLBA, LBACount: Int64;
                          pOverlapped: POVERLAPPED): Cardinal;
var
  ICDBuffer: ATA_PTH_DIR_BUFFER;
  BytesRead: Cardinal;
begin
  result := 0;
  FillChar(ICDBuffer, SizeOf(ICDBuffer), #0);

  if StartLBA <> 0 then
  begin
    ICDBuffer.PTH.Length := SizeOf(ICDBuffer.PTH);
    ICDBuffer.PTH.AtaFlags := ATA_FLAGS_48BIT_COMMAND or ATA_FLAGS_DATA_OUT or ATA_FLAGS_USE_DMA;
    ICDBuffer.PTH.DataTransferLength := SizeOf(ICDBuffer.Buffer);
    ICDBuffer.PTH.TimeOutValue := 30;
    ICDBuffer.PTH.DataBuffer := @ICDBuffer.Buffer;

    ICDBuffer.PTH.CurrentTaskFile[0] := 1;
    ICDBuffer.PTH.CurrentTaskFile[1] := 1;
    ICDBuffer.PTH.CurrentTaskFile[6] := $6;

    ICDBuffer.Buffer[0] := StartLBA and 255;
    StartLBA := StartLBA shr 8;
    ICDBuffer.Buffer[1] := StartLBA and 255;
    StartLBA := StartLBA shr 8;
    ICDBuffer.Buffer[2] := StartLBA and 255;
    StartLBA := StartLBA shr 8;
    ICDBuffer.Buffer[3] := StartLBA and 255;
    StartLBA := StartLBA shr 8;
    ICDBuffer.Buffer[4] := StartLBA and 255;
    StartLBA := StartLBA shr 8;
    ICDBuffer.Buffer[5] := StartLBA;

    ICDBuffer.Buffer[6] := LBACount and 255;
    ICDBuffer.Buffer[7] := LBACount shr 8;

    DeviceIOControl(hPhyDevice, IOCTL_ATA_PASS_THROUGH_DIRECT, @ICDBuffer, SizeOf(ICDBuffer), @ICDBuffer, SizeOf(ICDBuffer), BytesRead, pOverlapped);
    result := GetLastError;
  end;
end;

function SendFlushCommand(const DriveLetter: String): Cardinal;
var
  hPhyDevice: THandle;
begin
  hPhyDevice := CreateFile(
                PChar(DriveLetter),
                GENERIC_READ or GENERIC_WRITE,
                FILE_SHARE_READ or FILE_SHARE_WRITE,
                nil,
                OPEN_EXISTING,
                0,
                0);

  result := SendFlushCommand(hPhyDevice);

  CloseHandle(hPhyDevice);
end;

function SendFlushCommand(const hPhyDevice: THandle): Cardinal;
begin
  result := SendFlushCommand(hPhyDevice, nil);
end;

function SendFlushCommand(const hPhyDevice: THandle; pOverlapped: POVERLAPPED):
                         Cardinal;
var
  ICBuffer: ATA_PTH_BUFFER;
  bResult: Boolean;
  BytesRead: Cardinal;
  CurrBuf: Integer;
begin
  FillChar(ICBuffer, SizeOf(ICBuffer), #0);

  If hPhyDevice <> 0 Then
  begin
    ICBuffer.PTH.Length := SizeOf(ICBuffer.PTH);
    ICBuffer.PTH.AtaFlags := ATA_FLAGS_DATA_IN;
    ICBuffer.PTH.DataTransferLength := 512;
    ICBuffer.PTH.TimeOutValue := 2;
    ICBuffer.PTH.DataBufferOffset := PChar(@ICBuffer.Buffer) - PChar(@ICBuffer.PTH) + 20;

    ICBuffer.PTH.CurrentTaskFile[6] := $E7;

    bResult := DeviceIOControl(hPhyDevice, IOCTL_ATA_PASS_THROUGH, @ICBuffer,
                              SizeOf(ICBuffer), @ICBuffer, SizeOf(ICBuffer),
                              BytesRead, nil);
    result := GetLastError;
  end;
end;

function ReadSector(const hPhyDevice: THandle; StartLBA: Int64;
                    Buffer: PTLLBufferLarge): Integer;
var
  ICDBuffer: PATA_PTH_DIR_BUFFER_LARGE;
  BytesRead: Cardinal;
  CurrError: Integer;
  SectorCount: Integer;
begin
  result := 0;
  GetMem(ICDBuffer, SizeOf(ATA_PTH_DIR_BUFFER_LARGE));
  FillMemory(ICDBuffer, SizeOf(ATA_PTH_DIR_BUFFER_LARGE), 0);

  ICDBuffer.PTH.Length := SizeOf(ICDBuffer.PTH);
  ICDBuffer.PTH.AtaFlags := ATA_FLAGS_48BIT_COMMAND or ATA_FLAGS_DATA_IN;
  ICDBuffer.PTH.DataTransferLength := SizeOf(ICDBuffer.Buffer);
  ICDBuffer.PTH.TimeOutValue := 10;
  ICDBuffer.PTH.DataBuffer := @ICDBuffer.Buffer;

  ICDBuffer.PTH.CurrentTaskFile[2] := StartLBA and 255;
  StartLBA := StartLBA shr 8;
  ICDBuffer.PTH.CurrentTaskFile[3] := StartLBA and 255;
  StartLBA := StartLBA shr 8;
  ICDBuffer.PTH.CurrentTaskFile[4] := StartLBA and 255;
  StartLBA := StartLBA shr 8;
  ICDBuffer.PTH.PreviousTaskFile[2] := StartLBA and 255;
  StartLBA := StartLBA shr 8;
  ICDBuffer.PTH.PreviousTaskFile[3] := StartLBA and 255;
  StartLBA := StartLBA shr 8;
  ICDBuffer.PTH.PreviousTaskFile[4] := StartLBA and 255;

  SectorCount := SizeOf(ICDBuffer.Buffer) div 512;

  ICDBuffer.PTH.CurrentTaskFile[1] := LongRec(SectorCount).Bytes[0];
  ICDBuffer.PTH.PreviousTaskFile[1] := LongRec(SectorCount).Bytes[1];
  ICDBuffer.PTH.CurrentTaskFile[5] := $1 shl 6;
  ICDBuffer.PTH.CurrentTaskFile[6] := $24;

  DeviceIOControl(hPhyDevice, IOCTL_ATA_PASS_THROUGH_DIRECT,
                  ICDBuffer, SizeOf(ATA_PTH_DIR_BUFFER_LARGE),
                  ICDBuffer, SizeOf(ATA_PTH_DIR_BUFFER_LARGE),
                  BytesRead, nil);

  CurrError := GetLastError;
  if (CurrError = ERROR_SUCCESS) and (ICDBuffer.PTH.DataTransferLength = OneMega) then
  begin
    result := ICDBuffer.PTH.DataTransferLength;
    CopyMemory(Buffer, @ICDBuffer.Buffer, result);
  end
  else
  begin
    result := -1;
  end;
  FreeMem(ICDBuffer);
end;
end.
