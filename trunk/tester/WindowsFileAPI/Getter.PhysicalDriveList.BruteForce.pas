unit Getter.PhysicalDriveList.BruteForce;

interface

uses
  SysUtils, Threading,
  OSFile, Device.PhysicalDrive, Getter.PhysicalDriveList,
  Device.PhysicalDrive.List, CommandSet.Factory;

type
  TBruteForcePhysicalDriveListGetter = class sealed(TPhysicalDriveListGetter)
  private
    procedure IfThisDriveAccessibleAddToList(CurrentDrive: Integer);
    function TryToGetIsDriveAccessible(CurrentDrive: Integer): Boolean;
    function IsDriveAccessible(CurrentDrive: Integer): Boolean;
  protected
    procedure TryToGetPhysicalDriveList; override;
  end;

implementation

{ TBruteForcePhysicalDriveGetter }

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
    AddDriveToList(TPhysicalDrive.BuildFileAddressByNumber(CurrentDrive));
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

end.
