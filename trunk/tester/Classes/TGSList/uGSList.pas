unit uGSList;

interface

uses Windows, Math;

const
  UnitListShlValue = 24;
  UnitListSize = 1 shl UnitListShlValue; //(16777216) = (1 << 24)

type
  TIOType = (ioRead, ioWrite, ioTrim, ioFlush);

  PTGSNode = ^TGSNode;
  TGSNode = record
    FIOType: Word;
    FLength: Word;
    FLBA: UINT64;
  end;

  PTGListLL = ^TGListLL;
  TGListLL = record
    FBody: Array[0..UnitListSize - 1] of TGSNode;
    FNext: PTGListLL;
  end;

  PTGListHeader = ^TGListHeader;
  TGListHeader = record
    FHeadNode: PTGListLL;
    FLength: Integer;
    FCapacity: Integer;
  end;

  PTGSList = ^TGSList;
  TGSList = class
  private
    FListHeader: PTGListHeader;
    FLastList: PTGListLL;

    FIteratorPage: PTGListLL;
    FIteratorNum: Integer;

    FCreatedHeaderByMyself: Boolean;

    function AddMoreList: Boolean; inline;
    function DestroyAllList: Boolean;
    function GetLastNode: PTGSNode; inline;
    function Add(IOType: Word; Length: Word; LBA: UINT64): Boolean; inline;
  public
    constructor Create; overload;
    constructor Create(ReceivedHeader: PTGListHeader); overload;
    destructor Destroy; override;

    function AssignHeader(NewHeader: PTGListHeader): Boolean;

    function AddRead(Length: Word; LBA: UINT64): Boolean;
    function AddWrite(Length: Word; LBA: UINT64): Boolean;
    function AddTrim(Length: Word; LBA: UINT64): Boolean;
    function AddFlush: Boolean;

    function GetNextItem: PTGSNode;
    function GetListHeader: PTGListHeader;

    function GetLength: Integer; inline;
    function GoToFirst: Integer; inline;

    function Test(NeedBackup: Boolean): Boolean;
  end;

const
  TIOTypeInt: Array[TIOType] of Integer = (0, 1, 2, 3);

implementation

function TGSList.AddMoreList: Boolean;
var
  CurrList: Integer;
  CurrListPtr: PTGListLL;
  NewListPtr: PTGListLL;
begin
  result := true;
  GetMem(NewListPtr, SizeOf(TGListLL));

  try
    if FListHeader.FHeadNode <> nil then
    begin
      //Get Last List Ptr
      FLastList.FNext := NewListPtr;
    end
    else
    begin
      //If there is no list, set header
      FListHeader.FHeadNode := NewListPtr;
    end;
    FLastList := NewListPtr;
    Inc(FListHeader.FCapacity);
  except
    FreeMem(NewListPtr);
    result := false;
  end;
end;

function TGSList.DestroyAllList: Boolean;
var
  CurrList: Integer;
  CurrListPtr: PTGListLL;
  ToDeletedPtr: PTGListLL;
  BackupCapacity: Integer;
begin
  result := true;

  try
    CurrListPtr := FListHeader.FHeadNode;
    BackupCapacity := FListHeader.FCapacity;

    FListHeader.FHeadNode := nil;
    FLastList := nil;
    FIteratorPage := nil;
    FIteratorNum := 0;
    FListHeader.FCapacity := 0;
    FListHeader.FLength := 0;

    for CurrList := 0 to BackupCapacity - 1 do
    begin
      ToDeletedPtr := CurrListPtr;
      CurrListPtr := CurrListPtr.FNext;
      FreeMem(ToDeletedPtr);
    end;
  except
    result := false;
  end;
end;

function TGSList.GetLastNode: PTGSNode;
var
  CurrLength: Integer;
  CurrList: PTGListLL;
begin
  CurrLength := FListHeader.FLength;
  CurrList := FListHeader.FHeadNode;

  if (((CurrLength + 1) shr UnitListShlValue) >= FListHeader.FCapacity) then
  begin
    if AddMoreList = false then
    begin
      result := nil;
      exit;
    end;
  end;

  try
    result := @FLastList.FBody[CurrLength and (UnitListSize - 1)];
  except
    result := nil;
  end;
end;

function TGSList.Add(IOType: Word; Length: Word; LBA: UINT64): Boolean;
var
  LastNode: PTGSNode;
begin
  result := true;
  LastNode := GetLastNode;
  if LastNode <> nil then
  begin
    LastNode.FIOType := IOType;
    LastNode.FLength := Length;
    LastNode.FLBA := LBA;
    Inc(FListHeader.FLength);
  end
  else
  begin
    result := false;
  end;
end;

constructor TGSList.Create;
begin
  GetMem(FListHeader, SizeOf(TGListHeader));
  ZeroMemory(FListHeader, SizeOf(TGListHeader));
  FCreatedHeaderByMyself := true;
  AddMoreList;
  GoToFirst;
end;

constructor TGSList.Create(ReceivedHeader: PTGListHeader);
begin
  if AssignHeader(ReceivedHeader) = false then
    Create;
end;

destructor TGSList.Destroy;
begin
  DestroyAllList;
  if FCreatedHeaderByMyself then
  begin
    FreeMem(FListHeader);
  end;
end;

function TGSList.AssignHeader(NewHeader: PTGListHeader): Boolean;
var
  CurrListPtr: PTGListLL;
  CurrList: Integer;
begin
  if (NewHeader <> nil) and (NewHeader.FHeadNode <> nil) then
  begin
    FListHeader := NewHeader;
    //Get Last List Ptr
    CurrListPtr := FListHeader.FHeadNode;
    for CurrList := 1 to FListHeader.FCapacity - 1 do
    begin
      CurrListPtr := CurrListPtr.FNext;
    end;
    FLastList := CurrListPtr;
    FCreatedHeaderByMyself := false;
    result := true;
  end
  else
  begin
    result := false;
  end;
end;

function TGSList.AddRead(Length: Word; LBA: UINT64): Boolean;
begin
  result := Add(TIOTypeInt[ioRead], Length, LBA);
end;

function TGSList.AddWrite(Length: Word; LBA: UINT64): Boolean;
begin
  result := Add(TIOTypeInt[ioWrite], Length, LBA);
end;

function TGSList.AddTrim(Length: Word; LBA: UINT64): Boolean;
begin
  result := Add(TIOTypeInt[ioTrim], Length, LBA);
end;

function TGSList.AddFlush: Boolean;
begin
  result := Add(TIOTypeInt[ioFlush], 0, 0);
end;

function TGSList.GetNextItem: PTGSNode;
var
  IndexInList: Integer;
begin
  IndexInList := FIteratorNum and (UnitListSize - 1);

  if FListHeader.FLength = 0 then
  begin
    result := nil;
    exit;
  end;

  if FIteratorNum - FListHeader.FLength > 0 then
  begin
    FIteratorNum := 0;
  end;

  if FIteratorNum = 0 then
    FIteratorPage := FListHeader.FHeadNode;

  try
    if (FIteratorNum <> 0) and (IndexInList = 0) then
    begin
      FIteratorPage := FIteratorPage.FNext;
    end;

    result := @FIteratorPage.FBody[IndexInList];
    Inc(FIteratorNum);
  except
    result := nil;
  end;
end;

function TGSList.GetLength: Integer;
begin
  result := FListHeader.FLength;
end;

function TGSList.GetListHeader: PTGListHeader;
begin
  result := FListHeader;
end;

function TGSList.GoToFirst: Integer;
begin
  FIteratorPage := FListHeader.FHeadNode;
  FIteratorNum := 0;
end;

function TGSList.Test(NeedBackup: Boolean): Boolean;
var
  CurrItem: Integer;
  OriginalList: PTGListHeader;
begin
  result := false;

  if NeedBackup then
  begin
    //Backup the original header
    OriginalList := FListHeader;
  end;

  //Make the test header
  FListHeader := nil;
  GetMem(FListHeader, SizeOf(TGListHeader));
  ZeroMemory(FListHeader, SizeOf(TGListHeader));
  AddMoreList;

  try
    for CurrItem := 0 to 39923531 do
    begin
      AddWrite(CurrItem, CurrItem);
    end;

    for CurrItem := 0 to GetLength - 1 do
    begin
      if CurrItem = 39923531 then
        result := (GetNextItem.FLBA = 39923531)
      else
        GetNextItem;
    end;
  finally
    if NeedBackup then
    begin
      DestroyAllList;
      FreeMem(FListHeader, SizeOf(TGListHeader));
      FListHeader := OriginalList;
    end;
  end;
end;

end.
