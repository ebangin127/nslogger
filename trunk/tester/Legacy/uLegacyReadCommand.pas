unit uLegacyReadCommand;

interface

uses Classes, SysUtils, Dialogs, Windows, uLegacyDiskFunctions;

function ReadSector(const hPhyDevice: THandle; StartLBA: Int64;
                    Buffer: PTLLBufferLarge): Integer;

const
  TRIM_ZeroSector = 1;
  TRIM_NonZeroSector = 0;
  TRIM_Error = 2;

implementation

function ReadSector(const hPhyDevice: THandle; StartLBA: Int64;
                    Buffer: PTLLBufferLarge): Integer;
var
  ICDBuffer: PATA_PTH_DIR_BUFFER_LARGE;
  BytesRead: Cardinal;
  CurrError: Integer;
  SectorCount: Integer;
begin
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
