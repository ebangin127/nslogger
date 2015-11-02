unit Getter.DriveAvailability;

interface

uses
  Windows, SysUtils,
  OSFile.Handle, OSFile.IoControl;

type
  TDriveAvailabilityGetter = class sealed(TIoControlFile)
  public
    constructor Create(FileToGetAccess: String); override;

    function GetAvailability: Boolean;

  protected
    function GetMinimumPrivilege: TCreateFileDesiredAccess; override;

  private
    function GetNullBuffer: TIoControlIOBuffer;
  end;

implementation

{ TDriveAvailabilityGetter }

constructor TDriveAvailabilityGetter.Create(FileToGetAccess: String);
begin
  CreateHandle(FileToGetAccess, GetMinimumPrivilege);
end;

function TDriveAvailabilityGetter.GetNullBuffer: TIoControlIOBuffer;
begin
  result.InputBuffer.Buffer := nil;
  result.InputBuffer.Size := 0;

  result.OutputBuffer.Buffer := nil;
  result.OutputBuffer.Size := 0;
end;

function TDriveAvailabilityGetter.GetAvailability: Boolean;
begin
  if not IsHandleValid(GetFileHandle) then
    exit(false);

  result :=
    ExceptionFreeIoControl(TIoControlCode.StorageCheckVerify, GetNullBuffer) =
    ERROR_SUCCESS;
end;

function TDriveAvailabilityGetter.GetMinimumPrivilege: TCreateFileDesiredAccess;
begin
  exit(DesiredReadOnly);
end;

end.
