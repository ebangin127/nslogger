unit MeasureUnit.Time;

interface

uses
  SysUtils, Math,
  uLanguageSettings;

type
  TimeUnit = record
    FPowerOfSUnit: Integer;
  end;

const
  UnittimePerHigherUnittime = 60;
  HourUnit: TimeUnit = (FPowerOfSUnit: 2);
  MinuteUnit: TimeUnit = (FPowerOfSUnit: 1);
  SecondUnit: TimeUnit = (FPowerOfSUnit: 0);

function FormatTimeInSecond(TimeInSecond: Double): String;

implementation

function GetTimeUnitString
  (var TimeInSecond: Double;
   UnitToTest: TimeUnit;
   UnitName: String): String;
var
  UnitSizeInSecond: Int64;
  TimeInThisUnit: Integer;
begin
  result := '';
  UnitSizeInSecond :=
    Floor(Power(UnittimePerHigherUnittime, UnitToTest.FPowerOfSUnit));

  TimeInThisUnit := Floor(TimeInSecond / UnitSizeInSecond);
  if TimeInThisUnit > 0 then
  begin
    TimeInSecond := TimeInSecond - (TimeInThisUnit * UnitSizeInSecond);

    result := IntToStr(TimeInThisUnit) + UnitName;
    if TimeInThisUnit > 1 then
      result := result + TimeMultiple[CurrLang];
  end;
end;

function FormatTimeInSecond(TimeInSecond: Double): String;
var
  CurrStr: String;
begin
  CurrStr :=
    GetTimeUnitString(TimeInSecond, HourUnit, TimeHour[CurrLang]);
  if CurrStr <> '' then
    result := CurrStr + ' ';

  CurrStr :=
    GetTimeUnitString(TimeInSecond, MinuteUnit, TimeMin[CurrLang]);
  if CurrStr <> '' then
    result := result + CurrStr + ' ';

  CurrStr :=
    GetTimeUnitString(TimeInSecond, SecondUnit, TimeSec[CurrLang]);
  if CurrStr <> '' then
    result := result + CurrStr + ' ';
end;

end.
