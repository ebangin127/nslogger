unit uSCSIBufferInterpreter;

interface

uses
  SysUtils,
  uBufferInterpreter, Device.SMARTValueList, MeasureUnit.DataSize;

type
  TSCSIBufferInterpreter = class sealed(TBufferInterpreter)
  public
    function BufferToIdentifyDeviceResult
      (Buffer: T512Buffer): TIdentifyDeviceResult; override;
    function BufferToSMARTValueList
      (Buffer: T512Buffer): TSMARTValueList; override;
    function BufferToCapacityAndLBA(Buffer: T512Buffer): TIdentifyDeviceResult;

  private
    BufferInterpreting: T512Buffer;
    function GetFirmwareFromBuffer: String;
    function GetLBASizeFromBuffer: Cardinal;
    function GetModelFromBuffer: String;
    function GetSerialFromBuffer: String;
    function GetLBASize(Buffer: T512Buffer): Integer;
  end;

implementation

{ TSCSIBufferInterpreter }

function TSCSIBufferInterpreter.BufferToSMARTValueList
  (Buffer: T512Buffer): TSMARTValueList;
begin
  raise ENotSupportedException.Create
    ('Not Supported Operation: SMART in SCSI');
end;

function TSCSIBufferInterpreter.GetModelFromBuffer: String;
const
  SCSIModelStart = 8;
  SCSIModelEnd = 31;
var
  CurrentByte: Integer;
begin
  result := '';
  for CurrentByte := SCSIModelStart to SCSIModelEnd do
    result := result + Chr(BufferInterpreting[CurrentByte]);
  result := Trim(result);
end;

function TSCSIBufferInterpreter.GetFirmwareFromBuffer: String;
const
  SCSIFirmwareStart = 32;
  SCSIFirmwareEnd = 35;
var
  CurrentByte: Integer;
begin
  result := '';
  for CurrentByte := SCSIFirmwareStart to SCSIFirmwareEnd do
    result := result + Chr(BufferInterpreting[CurrentByte]);
  result := Trim(result);
end;

function TSCSIBufferInterpreter.GetSerialFromBuffer: String;
const
  SCSISerialStart = 36;
  SCSISerialEnd = 43;
var
  CurrentByte: Integer;
begin
  result := '';
  for CurrentByte := SCSISerialStart to SCSISerialEnd do
    result := result + Chr(BufferInterpreting[CurrentByte]);
  result := Trim(result);
end;

function TSCSIBufferInterpreter.GetLBASizeFromBuffer: Cardinal;
const
  ATA_LBA_SIZE = 512;
begin
  result := ATA_LBA_SIZE;
end;

function TSCSIBufferInterpreter.GetLBASize(Buffer: T512Buffer): Integer;
var
  CurrentByte: Integer;
const
  LBASizeStart = 8;
  LBASizeEnd = 11;
begin
  result := 0;
  for CurrentByte := LBASizeStart to LBASizeEnd do
  begin
    result := result shl 8;
    result := result + Buffer[CurrentByte];
  end;
end;

function TSCSIBufferInterpreter.BufferToCapacityAndLBA(Buffer: T512Buffer):
  TIdentifyDeviceResult;
  function ByteToDenaryKB: TDatasizeUnitChangeSetting;
  begin
    result.FNumeralSystem := Denary;
    result.FFromUnit := ByteUnit;
    result.FToUnit := KiloUnit;
  end;
var
  CurrentByte: Integer;
  ResultInByte: UInt64;
const
  LBAStart = 0;
  LBAEnd = 7;
begin
  ResultInByte := 0;
  for CurrentByte := LBAStart to LBAEnd do
  begin
    ResultInByte := ResultInByte shl 8;
    ResultInByte := ResultInByte + Buffer[CurrentByte];
  end;
  result.LBASize := GetLBASize(Buffer);
  result.UserSizeInKB := round(
    ChangeDatasizeUnit(ResultInByte * result.LBASize, ByteToDenaryKB));
end;

function TSCSIBufferInterpreter.BufferToIdentifyDeviceResult
  (Buffer: T512Buffer): TIdentifyDeviceResult;
begin
  BufferInterpreting := Buffer;
  result.Model := GetModelFromBuffer;
  result.Firmware := GetFirmwareFromBuffer;
  result.Serial := GetSerialFromBuffer;
  result.UserSizeInKB := 0;
  result.SATASpeed := TSATASpeed.NotSATA;
  result.LBASize := GetLBASizeFromBuffer;
end;

end.
