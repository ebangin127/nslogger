unit uSMARTManager;

interface

uses Classes, Generics.Collections, Math, SysUtils,
     uDiskFunctions, uSMARTFunctions;

type
  TSMARTDelta = record
    FID: WORD;
    FOldValue: TSMARTResult;
    FNewValue: TSMARTResult;
  end;
  TSMARTDeltaList = TList<TSMARTDelta>;

  TSMARTManager = class(TList<TSMARTResult>)
  private
    FSMARTInfo: SENDCMDOUTPARAMS;

    function IndexOfById(ID: Smallint): Integer;
    function GetAllSMARTID(SMARTData: SENDCMDOUTPARAMS): Boolean;
  public
    function Compare(a, b: TSMARTManager): TSMARTDeltaList;
    function GetSMARTValueById(ID: Word): TSMARTResult;
    function AssignSMARTData(SMARTData: SENDCMDOUTPARAMS): Boolean;

    function Save(Path: String): Boolean;
    function Load(Path: String): Boolean;
  end;

implementation

function TSMARTManager.IndexOfById(ID: Smallint): Integer;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    if Items[i].FID = ID then
      Exit(i);
  Result := -1;
end;

function TSMARTManager.GetAllSMARTID(SMARTData: SENDCMDOUTPARAMS): Boolean;
var
  CurrInfo, CurrPoint: Integer;
  CurrValue, CurrPercent, CurrID: Integer;
  CurrSMARTResult: TSMARTResult;
  SCSIConst: Integer;
begin
  result := IsValidSMART(SMARTData);
  if result = false then
    exit;

  FSMARTInfo := SMARTData;
  if FSMARTInfo.cBufferSize = 0 then SCSIConst := -6
    else SCSIConst := 0;
  for CurrInfo := 0 to floor(Length(FSMARTInfo.bBuffer) / 12) do
  begin
    CurrID := FSMARTInfo.bBuffer[8 + (CurrInfo * 12) + SCSIConst];
    if IndexOfById(CurrID) = -1 then
    begin
      CurrValue := 0;
      for CurrPoint := 0 to 5 do
      begin
        CurrValue := CurrValue shl 8;
        CurrValue := CurrValue
                      + FSMARTInfo.bBuffer[(6 - CurrPoint)
                                          + ((CurrInfo + 1) * 12) + SCSIConst];
      end;
      CurrPercent := FSMARTInfo.bBuffer[11 + ((CurrInfo + 1) * 12) + SCSIConst];

      CurrSMARTResult.FID := CurrID;
      CurrSMARTResult.FCurrentPercent := CurrPercent;
      CurrSMARTResult.FCurrentValue := CurrValue;

      Add(CurrSMARTResult);
    end;
  end;
end;

function TSMARTManager.Compare(a, b: TSMARTManager): TSMARTDeltaList;
var
  CurrIdxA: Integer;
  CurrIdxB: Integer;
  CurrItemA, CurrItemB: TSMARTResult;
  CurrID: Integer;

  NewDelta: TSMARTDelta;
  SearchedID: TList<Integer>;
begin
  result := TSMARTDeltaList.Create;
  SearchedID := TList<Integer>.Create;

  for CurrIdxA := 0 to a.Count - 1 do
  begin
    CurrID := a[CurrIdxA].FID;
    SearchedID.Add(CurrID);
    CurrItemA := a[CurrIdxA];

    CurrIdxB := b.IndexOfById(CurrID);
    if CurrIdxB = -1 then
    begin
      CurrItemB.FID := -1;
    end
    else
      CurrItemB := b[CurrIdxB];

    if (CurrItemA.FID = -1) or (CurrItemB.FID = -1)
        or (CurrItemB.FCurrentPercent <> CurrItemB.FCurrentPercent)
        or (a[CurrIdxA].FCurrentPercent <> CurrItemB.FCurrentPercent) then
    begin
      NewDelta.FID := CurrID;
      NewDelta.FOldValue := a[CurrIdxA];
      NewDelta.FNewValue := b[CurrIdxB];

      result.Add(NewDelta);
    end;
  end;

  for CurrIdxB := 0 to b.Count - 1 do
  begin
    CurrID := b[CurrIdxB].FID;
    SearchedID.Add(CurrID);
    CurrItemB := b[CurrIdxB];

    if SearchedID.IndexOf(CurrID) = -1 then
    begin
      NewDelta.FID := CurrID;
      NewDelta.FOldValue.FID := -1;
      NewDelta.FNewValue := b[CurrIdxB];

      result.Add(NewDelta);
    end;
  end;

  FreeAndNil(SearchedID);
end;

function TSMARTManager.GetSMARTValueById(ID: Word): TSMARTResult;
begin
  result := Self[IndexOfById(ID)];
end;

function TSMARTManager.AssignSMARTData(SMARTData: SENDCMDOUTPARAMS): Boolean;
begin
  result := GetAllSMARTID(SMARTData);
end;

function TSMARTManager.Save(Path: String): Boolean;
var
  DestFile: TFileStream;
begin
  result := false;

  try
    DestFile := TFileStream.Create(Path, fmOpenWrite);
  except
    exit;
  end;

  DestFile.Seek(0, soBeginning);
  DestFile.Write(FSMARTInfo, sizeof(SENDCMDOUTPARAMS));

  FreeAndNil(DestFile);
  result := true;
end;

function TSMARTManager.Load(Path: String): Boolean;
var
  SrcFile: TFileStream;
begin
  result := false;
  try
    SrcFile := TFileStream.Create(Path, fmOpenRead);
  except
    exit;
  end;

  SrcFile.Read(FSMARTInfo, sizeof(SENDCMDOUTPARAMS));

  FreeAndNil(SrcFile);
  result := true;
end;


end.
