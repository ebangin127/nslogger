// HDDInfo - Originated from, and rewritten version of Naraeon SSD Tools SSDInfo.
// So, it has no duplicated part with Naraeon SSD Tools.
// License: CCL CC BY-NC-SA 2.0 KR
// It cannot be licensed any illegal purpose of above license.

unit uHDDInfo;

interface

uses Windows, Classes, Math, Dialogs, SysUtils,
      uDiskFunctions, uStrFunctions;

type
  THDDInfo = class
    Model: String;
    Firmware: String;
    Serial: String;
    DeviceName: String;
    UserSize: UInt64;

    procedure SetDeviceName(Harddisk: string); virtual;

    constructor Create;
  end;

const
  ModelStart = 27;
  ModelEnd = 46;
  FirmStart = 23;
  FirmEnd = 26;
  SerialStart = 10;
  SerialEnd = 19;
  UserSizeStart = 100;
  UserSizeEnd = 103;

implementation

constructor THDDInfo.Create;
begin
  Model := '';
  Firmware := '';
  Serial := '';
  DeviceName := '';
end;

procedure THDDInfo.SetDeviceName(Harddisk: string);
var
  IBuf: ATA_PTH_BUFFER;
  driveHandle: THandle;
  result: Boolean;
  bRead: Cardinal;
  BufNum: Integer;
begin
  DeviceName := '\\.\' + Harddisk;
  Model := '';
  Firmware := '';
  Serial := '';

  FillChar(IBuf, SizeOf(IBuf), #0);

  driveHandle := CreateFile(PChar(DeviceName), GENERIC_READ or GENERIC_WRITE,
                 FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

  IBuf.PTH.Length := SizeOf(IBuf.PTH);
  IBuf.PTH.AtaFlags := ATA_FLAGS_DATA_IN;
  IBuf.PTH.DataTransferLength := 512;
  IBuf.PTH.TimeOutValue := 2;
  IBuf.PTH.DataBufferOffset := PChar(@IBuf.Buffer)
                                    - PChar(@IBuf.PTH) + 20;

  IBuf.PTH.CurrentTaskFile[6] := $EC;

  result := DeviceIOControl(driveHandle, IOCTL_ATA_PASS_THROUGH, @IBuf,
                              SizeOf(IBuf), @IBuf, SizeOf(IBuf),
                              bRead, nil);
  if result and (GetLastError = 0) then
  begin
    for BufNum := ModelStart to ModelEnd do
      Model := Model + Chr(IBuf.Buffer[BufNum * 2 + 1]) +
                       Chr(IBuf.Buffer[BufNum * 2]);
    Model := Model;

    for BufNum := FirmStart to FirmEnd do
      Firmware := Firmware + Chr(IBuf.Buffer[BufNum * 2 + 1]) +
                             Chr(IBuf.Buffer[BufNum * 2]);
    Firmware := Firmware;

    for BufNum := SerialStart to SerialEnd do
      Serial := Serial + Chr(IBuf.Buffer[BufNum * 2 + 1]) +
                         Chr(IBuf.Buffer[BufNum * 2]);
    Serial := Serial;

    UserSize := 0;
    for BufNum := UserSizeStart to UserSizeEnd do
    begin
      UserSize := UserSize + IBuf.Buffer[BufNum * 2] shl
                    (((BufNum - UserSizeStart) * 2) * 8);
      UserSize := UserSize + IBuf.Buffer[BufNum * 2 + 1]  shl
                    ((((BufNum - UserSizeStart) * 2) + 1) * 8);
    end;
  end;
  CloseHandle(driveHandle);
end;
end.
