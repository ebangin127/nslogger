unit Parser.ReadBuffer;

interface

uses
  SysUtils, Windows;

type
  TReadBuffer = Array of Char;

  IManagedReadBuffer = interface
    procedure SetItem(Index: Integer; NewChar: Char);
    function GetItem(Index: Integer): Char;
    function GetBuffer: TReadBuffer; 
    procedure SetBufferLength(NewLength: Integer);
    function GetLength: Integer;
    property Items[Index: Integer]: Char read GetItem write SetItem; default;
  end;

  TManagedReadBuffer = class(TInterfacedObject, IManagedReadBuffer)
  private
    FReadBuffer: TReadBuffer;
    FLength: Integer;
    procedure SetItem(Index: Integer; NewChar: Char);
    function GetItem(Index: Integer): Char;
  public
    constructor Create(BufferLength: Integer); 
    function GetBuffer: TReadBuffer; 
    procedure SetBufferLength(NewLength: Integer);
    function GetLength: Integer;
    property Items[Index: Integer]: Char read GetItem write SetItem; default;
  end;

implementation

{ TManagedReadBuffer }

constructor TManagedReadBuffer.Create(BufferLength: Integer);
begin
  SetBufferLength(BufferLength);
end;

function TManagedReadBuffer.GetBuffer: TReadBuffer;
begin
  result := FReadBuffer;
end;

procedure TManagedReadBuffer.SetBufferLength(NewLength: Integer);
begin
  if Length(FReadBuffer) < NewLength then
    SetLength(FReadBuffer, NewLength);
  FLength := NewLength;
end;

function TManagedReadBuffer.GetLength: Integer;
begin
  result := FLength;
end;

procedure TManagedReadBuffer.SetItem(Index: Integer; NewChar: Char);
begin
  FReadBuffer[Index] := NewChar;
end;

function TManagedReadBuffer.GetItem(Index: Integer): Char;
begin
  result := FReadBuffer[Index];
end;

end.
