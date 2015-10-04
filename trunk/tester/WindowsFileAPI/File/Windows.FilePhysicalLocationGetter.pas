unit Windows.FilePhysicalLocationGetter;

interface

uses
  SysUtils, Generics.Collections, Windows,
  uIoControlFile, uOSFileWithHandle;

type
  TPhysicalLocation = record
    CurrentLocation: Integer;
    Length: Integer;
  end;
  TPhysicalLocationList = TList<TPhysicalLocation>;
  TFilePhysicalLocationGetter = class sealed(TIoControlFile)
  private
    type
      TExtentNode = record
        NextVcn: TLargeInteger;
        Lnc: TLargeInteger;
      end;
      TExtentsBuffer = record
        ExtentCount: DWORD;
        StartingVcn: TLargeInteger;
        Extents: Array[0..0] of TExtentNode;
      end;
      PTLargeInteger = ^TLargeInteger;
  private
    PhysicalLocationList: TPhysicalLocationList;
    function GetIOBufferToGetPhysicalLocation(
      const StartingVCN: TLargeInteger;
      const OutputBufferPointer: Pointer): TIoControlIOBuffer;
    function TryToGetPhysicalLocation: TExtentsBuffer;
  protected
    function GetMinimumPrivilege: TCreateFileDesiredAccess; override;
  public
    constructor Create(FileToGetAccess: String);
    function GetPhysicalLocation: TPhysicalLocationList;
  end;

implementation

{ TFilePhysicalLocationGetter }

constructor TFilePhysicalLocationGetter.Create(FileToGetAccess: String);
begin
  CreateHandle(FileToGetAccess, GetMinimumPrivilege);
end;

function TFilePhysicalLocationGetter.GetMinimumPrivilege:
  TCreateFileDesiredAccess;
begin
  exit(DesiredReadOnly);
end;

function TFilePhysicalLocationGetter.GetIOBufferToGetPhysicalLocation
  (const StartingVCN: PTLargeInteger;
   const OutputBufferPointer: Pointer): TIoControlIOBuffer;
const
  NullInputBuffer = nil;
  NullInputBufferSize = 0;
begin
  result.InputBuffer.Buffer := @StartingVCN;
  result.InputBuffer.Size := sizeof(TLargeInteger);

  result.OutputBuffer.Buffer := OutputBufferPointer;
  result.OutputBuffer.Size := SizeOf(TExtentsBuffer);
end;

function TFilePhysicalLocationGetter.TryToGetPhysicalLocation:
  TExtentsBuffer;
var
  IOBuffer: TIoControlIOBuffer;
  ReturnedBytes: Cardinal;
  PhysicalLocationResult: TExtentsBuffer;
begin
  IOBuffer :=
    GetIOBufferToGetPhysicalLocation(
      @StartingVCN,
      @PhysicalLocationResult);
  ReturnedBytes := IoControl(TIoControlCode.GetLCNPointer, IOBuffer);

  result.DiskSizeInByte := OSGeometryResult.DiskSize;
  result.MediaType :=
    OSMediaTypeToTMediaType(OSGeometryResult.Geometry.MediaType);
end;

function TFilePhysicalLocationGetter.GetPhysicalLocation: TPhysicalLocationList;
begin
  try
    result := TryToGetPhysicalLocation;
  except
    FreeAndNil(PhysicalLocationList);
    result := nil;
  end;
end;

end.
