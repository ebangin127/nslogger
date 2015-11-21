unit Getter.PhysicalDriveList;

interface

uses
  OSFile, Device.PhysicalDrive.List, Device.PhysicalDrive, CommandSet.Factory;

type
  TPhysicalDriveListGetter = class abstract
  public
    function GetPhysicalDriveList: TPhysicalDriveList;
  protected
    procedure AddDriveToList(const DrivePath: String);
    procedure TryToGetPhysicalDriveList; virtual; abstract;
  private
    PhysicalDriveList: TPhysicalDriveList;
  end;

implementation

{ TPhysicalDriveListGetter }

procedure TPhysicalDriveListGetter.AddDriveToList(const DrivePath: String);
var
  PhysicalDrive: IPhysicalDrive;
begin
  try
    PhysicalDrive := TPhysicalDrive.Create(DrivePath);
    PhysicalDriveList.Add(PhysicalDrive);
  except
    on ENotSupportedCommandSet do
    else raise;
  end;
end;

function TPhysicalDriveListGetter.GetPhysicalDriveList: TPhysicalDriveList;
begin
  PhysicalDriveList := TPhysicalDriveList.Create;
  TryToGetPhysicalDriveList;
  result := PhysicalDriveList;
end;

end.
