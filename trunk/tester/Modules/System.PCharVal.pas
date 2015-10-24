unit System.PCharVal;

interface

uses
  SysUtils;

function PCharToInt(const S: PChar; const LengthOfS: Integer): Integer;
function PCharToInt64(const S: PChar; const LengthOfS: Integer): Int64;

implementation

function PCharToInt(const S: PChar; const LengthOfS: Integer): Integer;
var
  CurrentPChar: PChar;
  MaxPChar: PChar;
  CurrentChar: Char;
  PositionalNumber: Integer;
  Minus: Boolean;
begin
  if S[0] = #0 then
    raise EArgumentNilException.Create('String is Empty'); 

  PositionalNumber := 0;
  CurrentPChar := S;
  MaxPChar := S;
  Inc(MaxPChar, LengthOfS);
  Minus := S[0] = '-';
  result := 0;

  if Minus then
    Inc(CurrentPChar);

  while true do
  begin
    CurrentChar := CurrentPChar[0];
    case CurrentChar of
      '0'..'9':
        PositionalNumber := Integer(CurrentChar) - Integer('0');
      #0:
        break;
      else
        raise EArgumentException.Create('Wrong Character');
    end;
    if CurrentPChar >= MaxPChar then
      break;
    Inc(CurrentPChar);
    result := (result shl 3) + (result shl 1) + PositionalNumber;
  end;

  if Minus then
    result := -result;
end;

function PCharToInt64(const S: PChar; const LengthOfS: Integer): Int64;
var
  CurrentPChar: PChar;
  MaxPChar: PChar;
  CurrentChar: Char;
  PositionalNumber: Integer;
  Minus: Boolean;
begin
  if S[0] = #0 then
    raise EArgumentNilException.Create('String is Empty'); 

  PositionalNumber := 0;
  CurrentPChar := S;
  MaxPChar := S + LengthOfS;
  Minus := S[0] = '-';
  result := 0;

  if Minus then
    Inc(CurrentPChar);

  while true do
  begin
    CurrentChar := CurrentPChar[0];
    case CurrentChar of
      '0'..'9':
        PositionalNumber := Integer(CurrentChar) - Integer('0');
      #0:
        break;
      else
        raise EArgumentException.Create('Wrong Character');
    end;
    if CurrentPChar >= MaxPChar then
      break;
    Inc(CurrentPChar);
    result := (result shl 3) + (result shl 1) + PositionalNumber;
  end;

  if Minus then
    result := -result;
end;
end.
