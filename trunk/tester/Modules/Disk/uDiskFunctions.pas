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

  //---DeviceIOCtl�� �ʼ�---//
  TDRIVERSTATUS = Record
    bDriverError: UChar;
    bIDEError: UChar;
    bReserved: Array[0..1] of UCHAR;
    dwReserved: Array[0..1] of UCHAR;
  end;

  SENDCMDOUTPARAMS  = Record
    cBufferSize: DWORD;
    DriverStatus: TDRIVERSTATUS;
    bBuffer: Array[0..1023] of UCHAR;
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
  //---DeviceIOCtl�� �ʼ�---//


  //---ATA + DeviceIOCtl---//
  TLLBuffer = Array[0..511] of Byte;
  TLLBufferEx = Array[0..4095] of Byte;

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
    Buffer: TLLBuffer;
  end;

  ATA_PTH_BUFFER_4K = Packed Record
    PTH: ATA_PASS_THROUGH_EX;
    Buffer: TLLBufferEx;
  end;

  ATA_PTH_DIR_BUFFER = Packed Record
    PTH: ATA_PASS_THROUGH_DIRECT;
    Buffer: TLLBuffer;
  end;

  ATA_PTH_DIR_BUFFER_4K = Packed Record
    PTH: ATA_PASS_THROUGH_DIRECT;
    Buffer: TLLBufferEx;
  end;
  //---ATA + DeviceIOCtl---//


  //---SAT + DeviceIOCtl---//
  SCSI_PASS_THROUGH = record
    Length: Word;
    ScsiStatus: Byte;
    PathId: Byte;
    TargetId: Byte;
    Lun: Byte;
    CdbLength: Byte;
    SenseInfoLength: Byte;
    DataIn: Byte;
    DataTransferLength: ULong;
    TimeOutValue: ULong;
    DataBufferOffset: ULong;
    SenseInfoOffset: ULong;
    Cdb: array[0..12] of UCHAR;
  end;

  SCSI_PTH_BUFFER = record
    spt: SCSI_PASS_THROUGH;
    SenseBuf: array[0..31] of UCHAR;
    Buffer: TLLBuffer;
  end;
  //---SAT + DeviceIOCtl---//


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

  //---NCQ---//
  STORAGE_QUERY_TYPE = (PropertyStandardQuery = 0, PropertyExistsQuery,
                        PropertyMaskQuery, PropertyQueryMaxDefined);
  TStorageQueryType = STORAGE_QUERY_TYPE;

  STORAGE_PROPERTY_ID = (StorageDeviceProperty = 0, StorageAdapterProperty);
  TStoragePropertyID = STORAGE_PROPERTY_ID;

  STORAGE_PROPERTY_QUERY = packed record
    PropertyId: DWORD;
    QueryType: DWORD;
    AdditionalParameters: array[0..3] of Byte;
  end;

  STORAGE_BUS_TYPE = (BusTypeUnknown = 0, BusTypeScsi, BusTypeAtapi,
    BusTypeAta, BusType1394, BusTypeSsa, BusTypeFibre,
    BusTypeUsb, BusTypeRAID, BusTypeiScsi, BusTypeSas,
    BusTypeSata, BusTypeMaxReserved = $7F);

  STORAGE_DEVICE_DESCRIPTOR = packed record
    Version: DWORD;
    Size: DWORD;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Boolean;
    CommandQueueing: Boolean;
    VendorIdOffset: DWORD;
    ProductIdOffset: DWORD;
    ProductRevisionOffset: DWORD;
    SerialNumberOffset: DWORD;
    BusType: STORAGE_BUS_TYPE;
    RawPropertiesLength: DWORD;
    RawDeviceProperties: PChar;
  end;

  STORAGE_ADAPTOR_DESCRIPTOR = packed record
    Version: DWORD;
    Size: DWORD;
    MaximumTransferLength: DWORD;
    MaximumPhysicalPages: DWORD;
    AlignmentMask: DWORD;
    AdaptorUsesPio: Boolean;
    AdaptorScansDown: Boolean;
    CommandQueueing: Boolean;
    AccelatedTransfer: Boolean;
    BusType: STORAGE_BUS_TYPE;
    BusMajorVersion: WORD;
    BusMinorVersion: WORD;
  end;
  //---NCQ---//

//��ũ - ��Ƽ�� �� ���� ������
function GetPartitionList(DiskNumber: String): TDriveLetters;
function GetMotherDrive(const VolumeToGet: String): VOLUME_DISK_EXTENTS;

//�뷮, ���� �̸� �� ���� ���� ������
function GetFixedDrivesFunction: TDriveLetters;
function GetIsDriveAccessible(DeviceName: String; Handle: THandle = 0): Boolean;

//Fixed HDD, USB Mass Storage ���� ������
function GetSSDList: TSSDListResult;

//��¥, TBW ���
function GetTBWStr(MBW: Double): String;
function GetDayStr(Day: Double): String;

const
  IOCTL_SCSI_BASE = FILE_DEVICE_CONTROLLER;
  IOCTL_ATA_PASS_THROUGH = (IOCTL_SCSI_BASE shl 16) or ((FILE_READ_ACCESS or FILE_WRITE_ACCESS) shl 14)
                            or ($040B shl 2) or (METHOD_BUFFERED);
  IOCTL_ATA_PASS_THROUGH_DIRECT = $4D030;
  IOCTL_SCSI_PASS_THROUGH      =  $0004D004;

  SMART_READ_ATTRIBUTE_VALUES = $D0;
  SMART_CYL_LOW = $4F;
  SMART_CYL_HI = $C2;
  SMART_CMD = $B0;

  ATA_FLAGS_DRDY_REQUIRED = 1;
  ATA_FLAGS_DATA_IN = 1 shl 1;
  ATA_FLAGS_DATA_OUT = 1 shl 2;
  ATA_FLAGS_48BIT_COMMAND = 1 shl 3;
  ATA_FLAGS_USE_DMA = 1 shl 4;

  ATAMode = false;
  SCSIMode = true;

  VolumeNames = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

implementation

uses uSSDInfo;

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
  else hdrive := CreateFile(PChar(DeviceName), 0,
                            FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
                            OPEN_EXISTING, 0, 0);

  if hdrive <> INVALID_HANDLE_VALUE then
  begin
    try
      Result := DeviceIoControl(hdrive, IOCTL_STORAGE_CHECK_VERIFY, nil, 0,
                                nil, 0, dwBytesReturned, nil);
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

function GetSSDList: TSSDListResult;
var
  i: Integer;
  iValue: LongWord;
  wsFileObj: WideString;
  OleDrives: OleVariant;
  Dispatch: IDispatch;
  OleDrivesVar: OleVariant;
  OleEnum: IEnumvariant;
  OleCtx: IBindCtx;
  OleMoniker: IMoniker;
  ATAList, SCSIList: TStringList;
begin
  wsFileObj := 'winmgmts:\\localhost\root\cimv2';
  ATAList := TStringList.Create;
  SCSIList := TStringList.Create;
  result.WMIEnabled := true;
  try
    OleCheck(CreateBindCtx(0, OleCtx));
    OleCheck(MkParseDisplayName(OleCtx, PWideChar(wsFileObj), i, OleMoniker));
    OleCheck(OleMoniker.BindToObject(OleCtx, nil, IUnknown, Dispatch));


    OleDrivesVar := OleVariant(Dispatch).ExecQuery('Select * from Win32_DiskDrive');
    OleEnum := IUnknown(OleDrivesVar._NewEnum) as IEnumVariant;


    while OleEnum.Next(1, OleDrives, iValue) = 0 do
    begin
      if (not VarIsNull(OleDrives.DeviceID <> '')) and (OleDrives.MediaLoaded) and (not VarIsNull(OleDrives.MediaType))then
      begin
        if Pos('hard', Lowercase(OleDrives.MediaType)) >= 0 then
          if OleDrives.InterfaceType = 'IDE' then
            ATAList.Add(OleDrives.DeviceID)
          else if OleDrives.InterfaceType = 'USB' then
            SCSIList.Add(OleDrives.DeviceID + 'U')
          else if OleDrives.InterfaceType = 'SCSI' then
            SCSIList.Add(OleDrives.DeviceID + 'H');
      end;
      OleDrives := Unassigned;
    end;
    OleDrivesVar :=  Unassigned;
  except
    on e: Exception do
    begin
      ATAList.Add(e.Message);
      ATAList.SaveToFile('C:\NSTwmierror.txt');
      ATAList.Clear;
      result.WMIEnabled := false;
    end;
  end;
  for i := 0 to ATAList.Count - 1 do
    ATAList[i] := ExtractDeviceNum(ATAList[i]);
  for i := 0 to SCSIList.Count - 1 do
    SCSIList[i] := ExtractDeviceNum(SCSIList[i]);
  result.ResultList := TStringList.Create;
  result.ResultList.AddStrings(ATAList);
  result.ResultList.Add('/');
  result.ResultList.AddStrings(SCSIList);
  FreeAndNil(ATAList);
  FreeAndNil(SCSIList);
end;

function GetTBWStr(MBW: Double): String;
begin
  if MBW > (1024 * 1024 * 1024 / 4 * 3) then //Above 0.75PB
  begin
    result := Format('%.2fPBW', [MBW / 1024 / 1024 / 1024]);
  end
  else if MBW > (1024 * 1024 / 4 * 3) then //Above 0.75TB
  begin
    result := Format('%.2fTBW', [MBW / 1024 / 1024]);
  end
  else if MBW > (1024 / 4 * 3) then //Above 0.75GB
  begin
    result := Format('%.2fGBW', [MBW / 1024]);
  end
  else
  begin
    result := Format('%.2fMBW', [MBW]);
  end;
end;

function GetDayStr(Day: Double): String;
var
  HWDay: Double;
  HWDayYear, HWDayMon, HWDayDay: Integer;
begin
  HWDay := Day;
  HWDayYear := floor(HWDay / 365);
  HWDayMon := floor((HWDay - (HWDayYear * 365)) / 30);
  HWDayDay := floor(HWDay - (HWDayYear * 365) - (HWDayMon * 30));

  if HWDayYear > 0 then //Above 1yr
  begin
    result := Format('%d�� ', [HWDayYear]);
  end;

  if HWDay > 30 then //Above 1mon
  begin
    result := result + Format('%d���� ', [HWDayMon]);
  end;

  if HWDayDay > 0 then
  begin
    result := result + Format('%d�� ', [HWDayDay]);
  end;
end;
end.

