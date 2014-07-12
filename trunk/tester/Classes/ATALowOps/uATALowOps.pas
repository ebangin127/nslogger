unit uATALowOps;

interface

uses SysUtils, Windows,
     uDiskFunctions;

type
  TATALowOps = class
    class function CreateHandle(DeviceNum: Integer): THandle;

    class function GetInfoATA(hdrive: THandle): TLLBuffer;
    class function GetInfoSCSI(hdrive: THandle): TLLBuffer;

    class function GetSMARTATA(hdrive: THandle; DeviceNum: Integer):
                    SENDCMDOUTPARAMS;
    class function GetSMARTSCSI(hdrive: THandle): SENDCMDOUTPARAMS;

    class function GetNCQStatus(hdrive: THandle): Byte;
  end;

implementation


class function TATALowOps.CreateHandle(DeviceNum: Integer): THandle;
begin
  result := CreateFile(PChar('\\.\PhysicalDrive' + IntToStr(DeviceNum)),
                        GENERIC_READ or GENERIC_WRITE,
                        FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
                        0, 0);
end;

class function TATALowOps.GetInfoATA(hdrive: THandle): TLLBuffer;
var
  ICBuffer: ATA_PTH_BUFFER;
  bResult: Boolean;
  BytesRead: Cardinal;
  CurrBuf: Integer;
begin
  FillChar(ICBuffer, SizeOf(ICBuffer), #0);

  If GetLastError = 0 Then
  begin
    ICBuffer.PTH.Length := SizeOf(ICBuffer.PTH);
    ICBuffer.PTH.AtaFlags := ATA_FLAGS_DATA_IN;
    ICBuffer.PTH.DataTransferLength := 512;
    ICBuffer.PTH.TimeOutValue := 2;
    ICBuffer.PTH.DataBufferOffset := PChar(@ICBuffer.Buffer)
                                      - PChar(@ICBuffer.PTH) + 20;

    ICBuffer.PTH.CurrentTaskFile[6] := $EC;

    bResult := DeviceIOControl(hdrive, IOCTL_ATA_PASS_THROUGH, @ICBuffer,
                                SizeOf(ICBuffer), @ICBuffer, SizeOf(ICBuffer),
                                BytesRead, nil);
    if bResult and (GetLastError = 0) then
    begin
      exit(ICBuffer.Buffer);
    end;
  end;

  FillChar(ICBuffer, SizeOf(ICBuffer), #0);
  exit(ICBuffer.Buffer);
end;

class function TATALowOps.GetInfoSCSI(hdrive: THandle): TLLBuffer;
var
  dwBytesReturned: DWORD;
  Status: Longbool;
  ICBuffer: SCSI_PTH_BUFFER;
  CurrBuf: Integer;
begin
  fillchar(ICBuffer, SizeOf(ICBuffer), #0);
	ICBuffer.spt.Length     := sizeof(SCSI_PASS_THROUGH);
  ICBuffer.spt.TargetId   := 1;
  ICBuffer.spt.CdbLength  := 12;
	ICBuffer.spt.SenseInfoLength := 24;
	ICBuffer.spt.DataIn  := 1;
	ICBuffer.spt.DataTransferLength := 512;
	ICBuffer.spt.TimeOutValue := 2;
	ICBuffer.spt.DataBufferOffset := PAnsiChar(@ICBuffer.Buffer)
                                    - PAnsiChar(@ICBuffer);
	ICBuffer.spt.SenseInfoOffset  := PAnsiChar(@ICBuffer.SenseBuf)
                                    - PAnsiChar(@ICBuffer);
  ICBuffer.spt.Cdb[0] := $A1;
  ICBuffer.spt.Cdb[1] := $8;
  ICBuffer.spt.Cdb[2] := $E;
  ICBuffer.spt.Cdb[4] := $1;
	ICBuffer.spt.Cdb[9] := $EC;

  If GetLastError = 0 Then
  begin
    Status := DeviceIoControl(hdrive, IOCTL_SCSI_PASS_THROUGH, @ICBuffer,
                              SizeOf(ICBuffer), @ICBuffer, SizeOf(ICBuffer),
                              dwBytesReturned, nil);

    if status and (GetLastError = 0) and (ICBuffer.SenseBuf[0] = 0) then
    begin
      exit(ICBuffer.Buffer);
    end;
  end;

  FillChar(ICBuffer, SizeOf(ICBuffer), #0);
  exit(ICBuffer.Buffer);
end;

class function TATALowOps.GetSMARTATA(hdrive: THandle; DeviceNum: Integer):
                                    SENDCMDOUTPARAMS;
var
  dwBytesReturned: DWORD;
  opar: SENDCMDOUTPARAMS;
  opar2: SENDCMDOUTPARAMS;
  Status: Longbool;
  ipar2: SENDCMDINPARAMS;
begin
  ipar2.cBufferSize := 512;
  ipar2.bDriveNumber := DeviceNum;
  ipar2.irDriveRegs.bFeaturesReg := SMART_READ_ATTRIBUTE_VALUES;
  ipar2.irDriveRegs.bSectorCountReg := 1;
  ipar2.irDriveRegs.bSectorNumberReg := 1;
  ipar2.irDriveRegs.bCylLowReg := SMART_CYL_LOW;
  ipar2.irDriveRegs.bCylHighReg := SMART_CYL_HI;
  ipar2.irDriveRegs.bDriveHeadReg := ((DeviceNum and 1) shl 4) or $a0;
  ipar2.irDriveRegs.bCommandReg := SMART_CMD;

  fillchar(opar, SizeOf(opar), #0);

  if GetLastError = 0 Then
  begin
    Status := DeviceIoControl(hdrive, SMART_RCV_DRIVE_DATA, @ipar2,
                              SizeOf(SENDCMDINPARAMS), @opar,
                              SizeOf(SENDCMDOUTPARAMS), dwBytesReturned, nil);
    if (status = false) or (getLastError <> 0) then
      result := opar2;
  end;

  Result := opar;
end;

class function TATALowOps.GetSMARTSCSI(hdrive: THandle): SENDCMDOUTPARAMS;
var
  dwBytesReturned: DWORD;
  opar: SENDCMDOUTPARAMS;
  opar2: SENDCMDOUTPARAMS;
  Status: Longbool;
  ICBuffer: SCSI_PTH_BUFFER;
  CurrBuf: Integer;
begin
  fillchar(ICBuffer, SizeOf(ICBuffer), #0);
  fillchar(opar, SizeOf(opar), #0);
  fillchar(opar2, SizeOf(opar2), #0);
	ICBuffer.spt.Length     := sizeof(SCSI_PASS_THROUGH);
  ICBuffer.spt.TargetId   := 1;
  ICBuffer.spt.CdbLength  := 12;
	ICBuffer.spt.SenseInfoLength := 24;
	ICBuffer.spt.DataIn  := 1;
	ICBuffer.spt.DataTransferLength := 512;
	ICBuffer.spt.TimeOutValue := 2;
	ICBuffer.spt.DataBufferOffset := PAnsiChar(@ICBuffer.Buffer)
                                    - PAnsiChar(@ICBuffer);
	ICBuffer.spt.SenseInfoOffset  := PAnsiChar(@ICBuffer.SenseBuf)
                                    - PAnsiChar(@ICBuffer);
  ICBuffer.spt.Cdb[0] := $A1;
  ICBuffer.spt.Cdb[1] := $8;
  ICBuffer.spt.Cdb[2] := $E;
	ICBuffer.spt.Cdb[3] := $D0;
  ICBuffer.spt.Cdb[4] := $1;
  ICBuffer.spt.Cdb[5] := $0;
  ICBuffer.spt.Cdb[6] := $4F;
  ICBuffer.spt.Cdb[7] := $C2;
  ICBuffer.spt.Cdb[8] := $0;
	ICBuffer.spt.Cdb[9] := $B0;

  fillchar(opar, SizeOf(opar), #0);

  If GetLastError = 0 Then
  begin
    Status := DeviceIoControl(hdrive, IOCTL_SCSI_PASS_THROUGH, @ICBuffer,
                              SizeOf(ICBuffer), @ICBuffer, SizeOf(ICBuffer),
                              dwBytesReturned, nil);
    if status = false then
      result := opar2;
  end;

  for CurrBuf := 0 to 511 do
    opar.bBuffer[CurrBuf] := ICBuffer.Buffer[CurrBuf];
  Result := opar;
end;

class function TATALowOps.GetNCQStatus(hdrive: THandle): Byte;
var
  Query: STORAGE_PROPERTY_QUERY;
  dwBytesReturned: DWORD;
  Buffer: array [0..1023] of Byte;
  InputBuf: STORAGE_ADAPTOR_DESCRIPTOR absolute Buffer;
begin
  Result := 0;

  if hdrive <> INVALID_HANDLE_VALUE then
  begin
    dwBytesReturned := 0;
    FillChar(Query, SizeOf(Query), 0);
    FillChar(Buffer, SizeOf(Buffer), 0);
    InputBuf.Size := SizeOf(Buffer);
    Query.PropertyId := Cardinal(StorageAdapterProperty);
    Query.QueryType := Cardinal(PropertyStandardQuery);
    if DeviceIoControl(hdrive, IOCTL_STORAGE_QUERY_PROPERTY, @Query,
                        SizeOf(Query), @Buffer, SizeOf(Buffer),
                        dwBytesReturned, nil) = false then
    begin
      exit;
    end
    else
    begin
      if (InputBuf.BusType <> BusTypeSata) and
          (InputBuf.BusType <> BusTypeSCSI) and
          (InputBuf.BusType <> BusTypeAta) then
          Result := 0
      else
          Result := Byte((InputBuf.CommandQueueing and
                          (InputBuf.BusType = BusTypeSCSI)) or
                         (InputBuf.BusType = BusTypeSata)) + 1;
    end;
  end;
end;

end.
