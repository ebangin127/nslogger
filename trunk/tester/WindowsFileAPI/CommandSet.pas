unit CommandSet;

interface

uses
  SysUtils,
  OSFile.Handle, OSFile.IoControl,
  Device.SMART.List, BufferInterpreter;

type
  TCommandSet = class abstract(TIoControlFile)
  public
    constructor Create(FileToGetAccess: String); override;

    function IdentifyDevice: TIdentifyDeviceResult; virtual; abstract;
    function SMARTReadData: TSMARTValueList; virtual; abstract;

    function IsDataSetManagementSupported: Boolean; virtual; abstract;
    function DataSetManagement(StartLBA, LBACount: Int64): Cardinal;
      virtual; abstract;
    procedure Flush; virtual; abstract;

  protected
    function GetMinimumPrivilege: TCreateFileDesiredAccess; override;
  end;

implementation

{ TCommandSet }

constructor TCommandSet.Create(FileToGetAccess: String);
begin
  CreateHandle(FileToGetAccess, GetMinimumPrivilege);
end;

function TCommandSet.GetMinimumPrivilege: TCreateFileDesiredAccess;
begin
  exit(DesiredReadWrite);
end;

end.
