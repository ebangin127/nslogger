unit uSCSICommandSet;

interface

uses
  Windows, SysUtils,
  uIoControlFile, uCommandSet, uBufferInterpreter, Device.SMARTValueList,
  uSCSIBufferInterpreter;

type
  TSCSICommandSet = class sealed(TCommandSet)
  public
    function IdentifyDevice: TIdentifyDeviceResult; override;
    function SMARTReadData: TSMARTValueList; override;
    function DataSetManagement(StartLBA, LBACount: Int64): Cardinal; override;
    procedure Flush; override;

    function IsDataSetManagementSupported: Boolean; override;

  private
    type
      SCSI_COMMAND_DESCRIPTOR_BLOCK = record
        SCSICommand: UCHAR;
        MiscellaneousCDBInformation: UCHAR;
        LogicalBlockAddress: Array[0..7] of UCHAR;
        TransferParameterListAllocationLength: Array[0..3] of UCHAR;
        MiscellaneousCDBInformation2: UCHAR;
        Control: UCHAR;
      end;
      SCSI_PASS_THROUGH = record
        Length: USHORT;
        ScsiStatus: UCHAR;
        PathId: UCHAR;
        TargetId: UCHAR;
        Lun: UCHAR;
        CdbLength: UCHAR;
        SenseInfoLength: UCHAR;
        DataIn: UCHAR;
        DataTransferLength: ULONG;
        TimeOutValue: ULONG;
        DataBufferOffset: ULONG_PTR;
        SenseInfoOffset: ULONG;
        CommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK;
      end;
      SCSI_24B_SENSE_BUFFER = record
        ResponseCodeAndValidBit: UCHAR;
        Obsolete: UCHAR;
        SenseKeyILIEOMFilemark: UCHAR;
        Information: Array[0..3] of UCHAR;
        AdditionalSenseLengthMinusSeven: UCHAR;
        CommandSpecificInformation: Array[0..3] of UCHAR;
        AdditionalSenseCode: UCHAR;
        AdditionalSenseCodeQualifier: UCHAR;
        FieldReplaceableUnitCode: UCHAR;
        SenseKeySpecific: Array[0..2] of UCHAR;
        AdditionalSenseBytes: Array[0..5] of UCHAR;
      end;
      SCSI_WITH_BUFFER = record
        Parameter: SCSI_PASS_THROUGH;
        SenseBuffer: SCSI_24B_SENSE_BUFFER;
        Buffer: T512Buffer;
      end;

    const
      SCSI_IOCTL_DATA_OUT = 0;
      SCSI_IOCTL_DATA_IN = 1;
      SCSI_IOCTL_DATA_UNSPECIFIED = 2;

  private
    IoInnerBuffer: SCSI_WITH_BUFFER;
    IoOSBuffer: TIoControlIOBuffer;

    function GetCommonBuffer: SCSI_WITH_BUFFER;
    function GetCommonCommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK;
    procedure SetOSBufferByInnerBuffer;
    procedure SetInnerBufferAsFlagsAndCdb(Flags: ULONG;
      CommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK);
    procedure SetInnerBufferToIdentifyDevice;
    function InterpretIdentifyDeviceBuffer: TIdentifyDeviceResult;
    procedure SetBufferAndIdentifyDevice;
    procedure SetBufferAndReadCapacity;
    procedure SetInnerBufferToReadCapacity;
    function InterpretReadCapacityBuffer: TIdentifyDeviceResult;
  end;

implementation

{ TSCSICommandSet }

function TSCSICommandSet.GetCommonBuffer: SCSI_WITH_BUFFER;
const
  SATTargetId = 1;
begin
  FillChar(result, SizeOf(result), #0);
	result.Parameter.Length :=
    SizeOf(result.Parameter);
  result.Parameter.TargetId := SATTargetId;
  result.Parameter.CdbLength := SizeOf(result.Parameter.CommandDescriptorBlock);
	result.Parameter.SenseInfoLength :=
    SizeOf(result.SenseBuffer);
	result.Parameter.DataTransferLength :=
    SizeOf(result.Buffer);
	result.Parameter.TimeOutValue := 2;
	result.Parameter.DataBufferOffset :=
    PAnsiChar(@result.Buffer) - PAnsiChar(@result);
	result.Parameter.SenseInfoOffset :=
    PAnsiChar(@result.SenseBuffer) - PAnsiChar(@result);
end;

function TSCSICommandSet.GetCommonCommandDescriptorBlock:
  SCSI_COMMAND_DESCRIPTOR_BLOCK;
begin
  FillChar(result, SizeOf(result), #0);
end;

procedure TSCSICommandSet.SetInnerBufferAsFlagsAndCdb
  (Flags: ULONG; CommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK);
begin
  IoInnerBuffer := GetCommonBuffer;
	IoInnerBuffer.Parameter.DataIn := Flags;
  IoInnerBuffer.Parameter.CommandDescriptorBlock := CommandDescriptorBlock;
end;

procedure TSCSICommandSet.SetInnerBufferToIdentifyDevice;
const
  InquiryCommand = $12;
  AllocationLowBit = 2;
var
  CommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK;
begin
  CommandDescriptorBlock := GetCommonCommandDescriptorBlock;
  CommandDescriptorBlock.SCSICommand := InquiryCommand;
  CommandDescriptorBlock.LogicalBlockAddress[AllocationLowBit] := $60;
  SetInnerBufferAsFlagsAndCdb(SCSI_IOCTL_DATA_IN, CommandDescriptorBlock);
end;

procedure TSCSICommandSet.SetOSBufferByInnerBuffer;
begin
  IoOSBuffer.InputBuffer.Size := SizeOf(IoInnerBuffer);
  IoOSBuffer.InputBuffer.Buffer := @IOInnerBuffer;

  IoOSBuffer.OutputBuffer.Size := SizeOf(IoInnerBuffer);
  IoOSBuffer.OutputBuffer.Buffer := @IOInnerBuffer;
end;

procedure TSCSICommandSet.SetBufferAndIdentifyDevice;
begin
  SetInnerBufferToIdentifyDevice;
  SetOSBufferByInnerBuffer;
  IoControl(TIoControlCode.SCSIPassThrough, IoOSBuffer);
end;

function TSCSICommandSet.InterpretIdentifyDeviceBuffer:
  TIdentifyDeviceResult;
var
  SCSIBufferInterpreter: TSCSIBufferInterpreter;
begin
  SCSIBufferInterpreter := TSCSIBufferInterpreter.Create;
  result :=
    SCSIBufferInterpreter.BufferToIdentifyDeviceResult(IoInnerBuffer.Buffer);
  FreeAndNil(SCSIBufferInterpreter);
end;

procedure TSCSICommandSet.SetBufferAndReadCapacity;
begin
  SetInnerBufferToReadCapacity;
  SetOSBufferByInnerBuffer;
  IoControl(TIoControlCode.SCSIPassThrough, IoOSBuffer);
end;

procedure TSCSICommandSet.SetInnerBufferToReadCapacity;
const
  ReadCapacityCommand = $9E;
  AllocationLowBit = 2;
var
  CommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK;
begin
  CommandDescriptorBlock := GetCommonCommandDescriptorBlock;
  CommandDescriptorBlock.SCSICommand := ReadCapacityCommand;
  CommandDescriptorBlock.MiscellaneousCDBInformation := $10;
  CommandDescriptorBlock.TransferParameterListAllocationLength[
    AllocationLowBit] := 10;
  SetInnerBufferAsFlagsAndCdb(SCSI_IOCTL_DATA_IN, CommandDescriptorBlock);
end;

function TSCSICommandSet.IdentifyDevice: TIdentifyDeviceResult;
var
  ReadCapacityResult: TIdentifyDeviceResult;
begin
  SetBufferAndIdentifyDevice;
  result := InterpretIdentifyDeviceBuffer;
  result.StorageInterface := TStorageInterface.SCSI;
  SetBufferAndReadCapacity;
  ReadCapacityResult := InterpretReadCapacityBuffer;
  result.UserSizeInKB := ReadCapacityResult.UserSizeInKB;
  result.LBASize := ReadCapacityResult.LBASize;
  result.IsDataSetManagementSupported := IsDataSetManagementSupported;
end;

function TSCSICommandSet.InterpretReadCapacityBuffer: TIdentifyDeviceResult;
var
  SCSIBufferInterpreter: TSCSIBufferInterpreter;
begin
  SCSIBufferInterpreter := TSCSIBufferInterpreter.Create;
  result :=
    SCSIBufferInterpreter.BufferToCapacityAndLBA(IoInnerBuffer.Buffer);
  FreeAndNil(SCSIBufferInterpreter);
end;

function TSCSICommandSet.SMARTReadData: TSMARTValueList;
begin
  raise ENotSupportedException.Create
    ('Not Supported Operation: SMART in SCSI');
end;

procedure TSCSICommandSet.Flush;
const
  FlushCommand = $91;
var
  CommandDescriptorBlock: SCSI_COMMAND_DESCRIPTOR_BLOCK;
begin
  CommandDescriptorBlock := GetCommonCommandDescriptorBlock;
  CommandDescriptorBlock.SCSICommand := FlushCommand;
  SetInnerBufferAsFlagsAndCdb(SCSI_IOCTL_DATA_UNSPECIFIED,
    CommandDescriptorBlock);
end;

function TSCSICommandSet.IsDataSetManagementSupported: Boolean;
begin
  exit(false);
end;

function TSCSICommandSet.DataSetManagement(StartLBA, LBACount: Int64): Cardinal;
begin
  raise ENotSupportedException.Create
    ('Not Supported Operation: DataSetManagement in SCSI');
end;

end.
