unit uDiskFunctions;

interface

uses Windows, SysUtils, Dialogs, Math, Classes,
     ComObj, ShellAPI, Variants, ActiveX,
     uStrFunctions;

type
  //--GetMotherDrive--//
  DISK_EXTENT = RECORD
    DiskNumber: DWORD;
    StartingOffset: TLargeInteger;
    ExtentLength: TLargeInteger;
  end;

  VOLUME_DISK_EXTENTS = Record
    NumberOfDiskExtents: DWORD;
    Extents: Array[0..50] of DISK_EXTENT;
  end;
  //---GetMotherDrive---//

  //---DeviceIOCtl에 필수---//
  TDRIVERSTATUS = Record
    bDriverError: UChar;
    bIDEError: UChar;
    bReserved: Array[0..1] of UCHAR;
    dwReserved: Array[0..1] of UCHAR;
    class operator Equal(a: TDRIVERSTATUS; b: TDRIVERSTATUS) : Boolean;
    class operator NotEqual(a: TDRIVERSTATUS; b: TDRIVERSTATUS) : Boolean;
  end;

  SENDCMDOUTPARAMS = Record
    cBufferSize: DWORD;
    DriverStatus: TDRIVERSTATUS;
    bBuffer: Array[0..1023] of UCHAR;
    class operator Equal(a: SENDCMDOUTPARAMS; b: SENDCMDOUTPARAMS) : Boolean;
    class operator NotEqual(a: SENDCMDOUTPARAMS; b: SENDCMDOUTPARAMS) : Boolean;
  end;

  IDEREGS  = packed Record
    bFeaturesReg: UCHAR;
    bSectorCountReg: UCHAR;
    bSectorNumberReg: UCHAR;
    bCylLowReg: UCHAR;
    bCylHighReg: UCHAR;
    bDriveHeadReg: UCHAR;
    bCommandReg: UCHAR;
    bReserved: UCHAR;
  end;

  SENDCMDINPARAMS  = Record
    cBufferSize: dword;
    irDriveRegs: IDEREGS;
    bDriveNumber: byte;
    bReserved: Array[0..2] of byte;
    dwReserved: Array[0..3] of dword;
  end;
  //---DeviceIOCtl에 필수---//


  //---ATA + DeviceIOCtl---//
  ATA_PASS_THROUGH_EX = Packed Record
    Length: USHORT;
    AtaFlags: USHORT;
    PathId: UCHAR;
    TargetId: UCHAR;
    Lun: UCHAR;
    ReservedAsUchar: UCHAR;
    DataTransferLength: ULONG;
    TimeOutValue: ULONG;
    ReservedAsUlong: ULONG;
    DataBufferOffset: ULONG_PTR;
    PreviousTaskFile: Array[0..7] of UCHAR;
    CurrentTaskFile: Array[0..7] of UCHAR;
  end;

  ATA_PASS_THROUGH_DIRECT = Record
    Length: USHORT;
    AtaFlags: USHORT;
    PathId: UCHAR;
    TargetId: UCHAR;
    Lun: UCHAR;
    ReservedAsUchar: UCHAR;
    DataTransferLength: ULONG;
    TimeOutValue: ULONG;
    ReservedAsUlong: ULONG;
    DataBuffer: PVOID;
    PreviousTaskFile: Array[0..7] of UCHAR;
    CurrentTaskFile: Array[0..7] of UCHAR;
  end;

  ATA_PTH_BUFFER = Packed Record
    PTH: ATA_PASS_THROUGH_EX;
    Buffer: Array[0..511] of Byte;
  end;

  ATA_PTH_BUFFER_4K = Packed Record
    PTH: ATA_PASS_THROUGH_EX;
    Buffer: Array[0..4095] of Byte;
  end;

  ATA_PTH_DIR_BUFFER = Packed Record
    PTH: ATA_PASS_THROUGH_DIRECT;
    Buffer: Array[0..511] of Byte;
  end;

  ATA_PTH_DIR_BUFFER_4K = Packed Record
    PTH: ATA_PASS_THROUGH_DIRECT;
    Buffer: Array[0..4095] of Byte;
  end;
  //---ATA + DeviceIOCtl---//


  //---GetPartitionList---//
  TDriveLetters = Record
    LetterCount: Byte;
    Letters: Array[0..99] of String;
    StartOffset: Array[0..99] of TLargeInteger;
  end;
  //---GetPartitionList---//


  //---Trim Command--//
  PSTARTING_LCN_INPUT_BUFFER = ^STARTING_LCN_INPUT_BUFFER;
  {$EXTERNALSYM PSTARTING_LCN_INPUT_BUFFER}
  STARTING_LCN_INPUT_BUFFER = record
    StartingLcn: LARGE_INTEGER;
  end;

  PVOLUME_BITMAP_BUFFER = ^VOLUME_BITMAP_BUFFER;
  {$EXTERNALSYM PVOLUME_BITMAP_BUFFER}
  VOLUME_BITMAP_BUFFER = record
    StartingLcn: LARGE_INTEGER;
    BitmapSize: LARGE_INTEGER;
    Buffer: array [0..4095] of Byte;
  end;
  //---Trim Command--//

  //---Firmware--//
  FirmCheck = record
    FirmExists: Boolean;
    FirmPath: String;
  end;
  //---Firmware--//

  TSSDListResult = record
    ResultList: TStringList;
    WMIEnabled: Boolean;
  end;

//디스크 - 파티션 간 관계 얻어오기
function GetPartitionList(DiskNumber: String): TDriveLetters;
function GetMotherDrive(const VolumeToGet: String): VOLUME_DISK_EXTENTS;
procedure GetChildDrives(DiskNumber: String; ChildDrives: TStrings);

//용량, 볼륨 이름 및 각종 정보 얻어오기
function GetFixedDrivesFunction: TDriveLetters;
function GetIsDriveAccessible(DeviceName: String; Handle: THandle = 0): Boolean;

const
  IOCTL_SCSI_BASE = FILE_DEVICE_CONTROLLER;
  IOCTL_ATA_PASS_THROUGH = (IOCTL_SCSI_BASE shl 16) or ((FILE_READ_ACCESS or FILE_WRITE_ACCESS) shl 14)
                            or ($040B shl 2) or (METHOD_BUFFERED);
  IOCTL_ATA_PASS_THROUGH_DIRECT = $4D030;

  ATA_FLAGS_DRDY_REQUIRED = 1;
  ATA_FLAGS_DATA_IN = 1 shl 1;
  ATA_FLAGS_DATA_OUT = 1 shl 2;
  ATA_FLAGS_48BIT_COMMAND = 1 shl 3;
  ATA_FLAGS_USE_DMA = 1 shl 4;

  VolumeNames = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

implementation

uses uHDDInfo;

class operator TDRIVERSTATUS.Equal(a: TDRIVERSTATUS; b: TDRIVERSTATUS): Boolean;
begin
  result := true;

  if a.bDriverError <> b.bDriverError then
  begin
    exit(false);
  end;

  if a.bIDEError <> b.bIDEError then
  begin
    exit(false);
  end;
end;

class operator TDRIVERSTATUS.NotEqual(a: TDRIVERSTATUS; b: TDRIVERSTATUS): Boolean;
begin
  result := not (a = b);
end;


class operator SENDCMDOUTPARAMS.Equal(a: SENDCMDOUTPARAMS; b: SENDCMDOUTPARAMS): Boolean;
var
  CurrElem: Integer;
begin
  result := true;

  if a.cBufferSize <> b.cBufferSize then
  begin
    exit(false);
  end;

  if a.DriverStatus <> b.DriverStatus then
  begin
    exit(false);
  end;

  for CurrElem := 0 to a.cBufferSize - 1 do
  begin
    if a.bBuffer[CurrElem] <> b.bBuffer[CurrElem] then
    begin
      exit(false);
    end;
  end;
end;

class operator SENDCMDOUTPARAMS.NotEqual(a: SENDCMDOUTPARAMS; b: SENDCMDOUTPARAMS) : Boolean;
begin
  result := not (a = b);
end;

procedure GetChildDrives(DiskNumber: String; ChildDrives: TStrings);
var
  CurrDrv, DriveCount: Integer;
  DrvNames: TDriveLetters;
begin
  ChildDrives.Clear;
  DrvNames := GetPartitionList(DiskNumber);
  DriveCount := DrvNames.LetterCount;
  for CurrDrv := 0 to DriveCount - 1 do
    ChildDrives.Add(DrvNames.Letters[CurrDrv] + '\');
end;

function GetFixedDrivesFunction: TDriveLetters;
var
  CurrDrv, DrvStrLen: Integer;
  DriveCount: Byte;
  Drives: Array[0..255] of char;
  DrvName: String;
begin
  FillChar(Drives, 256, #0 );
  DrvStrLen := GetLogicalDriveStrings(256, Drives);
  DriveCount := 0;

  for CurrDrv := 0 to DrvStrLen - 1 do
  begin
    if Drives[CurrDrv] = #0  then
    begin
      if GetDriveType(PChar(DrvName)) = DRIVE_FIXED then
      begin
        if DrvName[Length(DrvName)] = '\' then
          DrvName := Copy(DrvName, 1, Length(DrvName) - 1);
        result.Letters[DriveCount] := DrvName;
        DriveCount := DriveCount + 1;
      end;
      DrvName := '';
    end
    else
      DrvName := DrvName + Drives[CurrDrv];
  end;
  result.LetterCount := DriveCount;
end;


function GetIsDriveAccessible(DeviceName: String; Handle: THandle = 0): Boolean;
var
  hdrive: THandle;
  dwBytesReturned: DWORD;
begin
  Result := false;

  if Handle <> 0 then hdrive := Handle
  else hdrive := CreateFile(PChar(DeviceName), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

  if hdrive <> INVALID_HANDLE_VALUE then
  begin
    try
      Result := DeviceIoControl(hdrive, IOCTL_STORAGE_CHECK_VERIFY, nil, 0, nil, 0, dwBytesReturned, nil);
    finally
      if Handle = 0 then CloseHandle(hdrive);
    end;
  end;
end;

function GetMotherDrive(const VolumeToGet: String): VOLUME_DISK_EXTENTS;
var
  RetBytes: DWORD;
  hDevice: Longint;
  Status: Longbool;
  VolumeName: Array[0..MAX_PATH] of Char;
  i: Integer;
begin
  for i := 0 to MAX_PATH do
    VolumeName[i] := #0;
  QueryDosDeviceW(PChar(VolumeToGet), VolumeName, MAX_PATH);
  try
    hDevice := CreateFile(PChar('\\.\' + VolumeToGet), GENERIC_READ,
                FILE_SHARE_WRITE or FILE_SHARE_READ, nil, OPEN_EXISTING, 0, 0);
  except
    exit;
  end;
  if Pos('ramdriv', lowercase(VolumeName)) > 0 then
    result.NumberOfDiskExtents := 0
  else
  begin
    If hDevice <> -1 Then
    begin
      Status := DeviceIoControl (hDevice, IOCTL_VOLUME_GET_VOLUME_DISK_EXTENTS,
                nil, 0, @result, Sizeof(VOLUME_DISK_EXTENTS), RetBytes, nil);
      if (status = false) then
      begin
        result.NumberOfDiskExtents := 0;
      end;
      CloseHandle(hDevice);
    end
    else
    begin
      result.NumberOfDiskExtents := 0;
    end;
  end;
end;

function GetPartitionList(DiskNumber: String): TDriveLetters;
var
  CurrDrv, CurrExtents: Integer;
  CurrDrvInfo: VOLUME_DISK_EXTENTS;
  CurrPartition, DiskNumberInt: Cardinal;
  FixedDrives: TDriveLetters;
begin
  FixedDrives := GetFixedDrivesFunction;
  DiskNumberInt := StrToInt(DiskNumber);
  CurrPartition := 0;

  for CurrDrv := 0 to (FixedDrives.LetterCount - 1) do
  begin
    CurrDrvInfo := GetMotherDrive(FixedDrives.Letters[CurrDrv]);
    for CurrExtents := 0 to (CurrDrvInfo.NumberOfDiskExtents - 1) do
    begin
      if CurrDrvInfo.Extents[CurrExtents].DiskNumber = DiskNumberInt then
      begin
        result.Letters[CurrPartition] := FixedDrives.Letters[CurrDrv];
        result.StartOffset[CurrPartition] :=
          CurrDrvInfo.Extents[CurrExtents].StartingOffset;
        CurrPartition := CurrPartition + 1;
      end;
    end;
  end;

  result.LetterCount := CurrPartition;
end;
end.

