unit uRandomBuffer;

interface

uses uMTforDel, SysUtils;

type
  TArrayBuffer = Array of Byte;
  PTArrayBuffer = ^TArrayBuffer;

  PTRandomBuffer = ^TRandomBuffer;
  TRandomBuffer = class(TMersenne)
  private
    FBuffer: TArrayBuffer;
    FIterator: UINT32;
  public
    constructor Create(s: Cardinal); overload;
    constructor Create(init_key: Array of Cardinal; key_length: Integer); overload;

    destructor Delete;

    function CreateBuffer(Length: UINT32): Boolean;
    function FillBuffer(RandomnessInString: String): Boolean; overload;
    function FillBuffer(RandomnessInInteger: Integer): Boolean; overload;
    function DeleteCache: Boolean;

    procedure SetIteratorToFirst;
    function GetBufferPtr(NeededLength: UINT32): Pointer;
    function GetLength: Integer;

    function CompareBuffer(BufOne, BufTwo: TArrayBuffer): Int64;
  end;

implementation
constructor TRandomBuffer.Create(s: Cardinal);
begin
  inherited Create(s);
end;

constructor TRandomBuffer.Create(init_key: Array of Cardinal; key_length: Integer);
begin
  inherited Create(init_key, key_length);
end;

// Length = KByte Unit
function TRandomBuffer.CreateBuffer(Length: UINT32): Boolean;
begin
  result := true;
  try
    SetLength(FBuffer, Length shl 10);
  except
    result := false;
    SetLength(FBuffer, 0);
  end;
end;

function TRandomBuffer.FillBuffer(RandomnessInString: String): Boolean;
begin
  result := FillBuffer(StrToInt(RandomnessInString));
end;

function TRandomBuffer.FillBuffer(RandomnessInInteger: Integer): Boolean;
var
  ArrNumAnd3: Integer;
  BitNum, Randomness: Integer;
  RandomInt: TRandom4int;
  BufferLength: UINT32;
begin
  BufferLength := Length(FBuffer);
  if BufferLength = 0 then
  begin
    result := false;
    exit;
  end;

  result := true;
  try
    Randomness := Round(BufferLength * (RandomnessInInteger / 100));
    for BitNum := 0 to (BufferLength - 1) do
    begin
      if (BitNum >= Randomness) then
      begin
        FBuffer[BitNum] := 0;
      end
      else
      begin
        ArrNumAnd3 := BitNum and 3;
        if ArrNumAnd3 = 0 then
        begin
          RandomInt.RandomInt := genrand_int32;
        end;
        FBuffer[BitNum] := RandomInt.RandomChar[ArrNumAnd3];
      end;
    end;
  except
    result := false;
  end;
end;

destructor TRandomBuffer.Delete;
begin
  DeleteCache;
  inherited;
end;

function TRandomBuffer.DeleteCache: Boolean;
begin
  result := true;
  try
    SetLength(FBuffer, 0);
  except
    result := false;
  end;
end;

procedure TRandomBuffer.SetIteratorToFirst;
begin
  FIterator := 0;
end;

function TRandomBuffer.GetBufferPtr(NeededLength: UINT32): Pointer;
begin
  if NeededLength > UINT32(Length(FBuffer)) then
  begin
    result := nil;
    exit;
  end;

  if NeededLength + FIterator > UINT32(Length(FBuffer)) then
    SetIteratorToFirst;

  result := @FBuffer[FIterator];
  FIterator := FIterator + NeededLength;
end;

function TRandomBuffer.GetLength: Integer;
begin
  result := Length(FBuffer);
end;

function TRandomBuffer.CompareBuffer(BufOne, BufTwo: TArrayBuffer): Int64;
var
  BitNum: Integer;
  CacheSize: UINT32;
begin
  result := -1;
  //Illegal Situations
  if (BufOne = nil) or (BufTwo = nil) then
    exit;
  if Length(BufOne) <> Length(BufTwo) then
    exit;

  result := 0;

  CacheSize := Length(BufOne);
  for BitNum := 0 to (CacheSize - 1) do
  begin
    result := result + Integer(not(BufOne[BitNum] = BufTwo[BitNum]));
  end;
end;
end.
