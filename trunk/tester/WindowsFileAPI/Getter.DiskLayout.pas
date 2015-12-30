unit Getter.DiskLayout;

interface

uses
  Windows,
  OSFile.Handle, OSFile.IoControl, Partition.List;

type
  TDiskLayoutGetter = class sealed(TIoControlFile)
  public
    constructor Create(FileToGetAccess: String); override;
    function GetPartitionList: TPartitionList;
  protected
    function GetMinimumPrivilege: TCreateFileDesiredAccess; override;
  private
    function GetIOBufferToGetLayout(
      OutputBufferPointer: Pointer): TIoControlIOBuffer;
    type
      TPartitionInformation = record
        StartingOffset: LARGE_INTEGER;
        PartitionLength: LARGE_INTEGER;
        HiddenSectors: DWORD;
        PartitionNumber: DWORD;
        PartitionType: BYTE;
        BootIndicator: Boolean;
        RecognizedPartition: Boolean;
        RewritePartition: Boolean;
      end;
      TDiskLayoutInformation = record
        PartitionCount: DWORD;
        Signature: DWORD;
        PartitionEntry: Array[0..127] of TPartitionInformation;
      end;
    function GetDiskLayout: TDiskLayoutInformation;
    procedure GetDiskLayoutAndIfNotReturnedRaiseException(
      IOBuffer: TIoControlIOBuffer);
    function PartitionInformationToPartitionEntry(
      PartitionInformation: TPartitionInformation): TPartitionEntry;
  end;


implementation

{ TDiskLayoutGetter }

constructor TDiskLayoutGetter.Create(FileToGetAccess: String);
begin
  CreateHandle(FileToGetAccess, GetMinimumPrivilege);
end;

procedure TDiskLayoutGetter.GetDiskLayoutAndIfNotReturnedRaiseException
  (IOBuffer: TIoControlIOBuffer);
var
  ReturnedBytes: Cardinal;
begin
  ReturnedBytes := IoControl(TIoControlCode.GetDriveLayout, IOBuffer);
  if ReturnedBytes = 0 then
    ENoDataReturnedFromIO.Create
      ('NoDataReturnedFromIO: No data returned from GetDriveGeometryEX');
end;

function TDiskLayoutGetter.GetIOBufferToGetLayout
  (OutputBufferPointer: Pointer): TIoControlIOBuffer;
const
  NullInputBuffer = nil;
  NullInputBufferSize = 0;
begin
  result.InputBuffer.Buffer := NullInputBuffer;
  result.InputBuffer.Size := NullInputBufferSize;

  result.OutputBuffer.Buffer := OutputBufferPointer;
  result.OutputBuffer.Size := SizeOf(TDiskLayoutInformation);
end;

function TDiskLayoutGetter.GetDiskLayout: TDiskLayoutInformation;
var
  DiskLayoutInformation: TDiskLayoutInformation;
begin
  GetDiskLayoutAndIfNotReturnedRaiseException(
    GetIOBufferToGetLayout(@result));
end;

function TDiskLayoutGetter.GetMinimumPrivilege: TCreateFileDesiredAccess;
begin
  exit(DesiredReadOnly);
end;

function TDiskLayoutGetter.PartitionInformationToPartitionEntry(
  PartitionInformation: TPartitionInformation): TPartitionEntry;
begin
  result.Letter := '';
  result.StartingOffset := PartitionInformation.StartingOffset.QuadPart;
end;

function TDiskLayoutGetter.GetPartitionList: TPartitionList;
const
  UnusedPartition = 0;
var
  DiskLayout: TDiskLayoutInformation;
  CurrentPartition: Integer;
begin
  result := TPartitionList.Create;
  DiskLayout := GetDiskLayout;
  for CurrentPartition := 0 to DiskLayout.PartitionCount - 1 do
    if DiskLayout.PartitionEntry[CurrentPartition].PartitionType <>
      UnusedPartition then
        result.Add(PartitionInformationToPartitionEntry(
          DiskLayout.PartitionEntry[CurrentPartition]));
end;

end.
