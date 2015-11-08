unit Getter.PhysicalDriveList.BruteForce;

interface

uses
  SysUtils, Threading,
  OSFile, Device.PhysicalDrive, Getter.PhysicalDriveList,
  Device.PhysicalDrive.List, CommandSet.Factory;

type
  TBruteForcePhysicalDriveListGetter = class sealed(TPhysicalDriveListGetter)
  public
    function GetPhysicalDriveList: TPhysicalDriveList; override;
  private
    PhysicalDriveList: TPhysicalDriveList;
    procedure AddDriveToList(CurrentDrive: Integer);
    procedure IfThisDriveAccessibleAddToList(CurrentDrive: Integer);
    function TryToGetIsDriveAccessible(CurrentDrive: Integer): Boolean;
    procedure TryToGetPhysicalDriveList;
    function IsDriveAccessible(CurrentDrive: Integer): Boolean;
  end;

implementation

{ TBruteForcePhysicalDriveGetter }

procedure TBruteForcePhysicalDriveListGetter.AddDriveToList
  (CurrentDrive: Integer);
var
  PhysicalDrive: IPhysicalDrive;
begin
  try
    PhysicalDrive :=
      TPhysicalDrive.Create(
        TPhysicalDrive.BuildFileAddressByNumber(CurrentDrive));
    PhysicalDriveList.Add(PhysicalDrive);
  except
    on ENotSupportedCommandSet do
    else raise;
  end;
end;

function TBruteForcePhysicalDriveListGetter.TryToGetIsDriveAccessible
  (CurrentDrive: Integer): Boolean;
var
  PhysicalDrive: IPhysicalDrive;
begin
  PhysicalDrive :=
    TPhysicalDrive.Create(
      TPhysicalDrive.BuildFileAddressByNumber(CurrentDrive));
  result := PhysicalDrive.IsDriveAvailable;
end;

function TBruteForcePhysicalDriveListGetter.IsDriveAccessible
  (CurrentDrive: Integer): Boolean;
begin
  try
    result := TryToGetIsDriveAccessible(CurrentDrive);
  except
    result := false;
  end;
end;

procedure TBruteForcePhysicalDriveListGetter.IfThisDriveAccessibleAddToList
  (CurrentDrive: Integer);
begin
  if IsDriveAccessible(CurrentDrive) then
    AddDriveToList(CurrentDrive);
end;

procedure TBruteForcePhysicalDriveListGetter.TryToGetPhysicalDriveList;
const
  PHYSICALDRIVE_MAX = 99;
begin
  TParallel.For(0, PHYSICALDRIVE_MAX, procedure (CurrentDrive: Integer)
  begin
    IfThisDriveAccessibleAddToList(CurrentDrive)
  end);
end;

function TBruteForcePhysicalDriveListGetter.GetPhysicalDriveList:
  TPhysicalDriveList;
begin
  try
    PhysicalDriveList := TPhysicalDriveList.Create;
    TryToGetPhysicalDriveList;
  except
    FreeAndNil(PhysicalDriveList);
  end;
  result := PhysicalDriveList;
end;

end.
