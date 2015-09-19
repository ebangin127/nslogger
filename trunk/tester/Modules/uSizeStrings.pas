unit uSizeStrings;

interface

uses SysUtils, Math;

//날짜, TBW 계산
function GetByte2TBWStr(BW: Int64): String;
function GetDayStr(Day: Double): String;

implementation

function GetByte2TBWStr(BW: Int64): String;
var
  MBW: Double;
begin
  MBW := BW / 1024 / 1024;
  if MBW > (1024 * 1024 * 1024 / 4 * 3) then //Above 0.75PB
  begin
    result := Format('%.2fPBW', [MBW / 1024 / 1024 / 1024]);
  end
  else if MBW > (1024 * 1024 / 4 * 3) then //Above 0.75TB
  begin
    result := Format('%.2fTBW', [MBW / 1024 / 1024]);
  end
  else if MBW > (1024 / 4 * 3) then //Above 0.75GB
  begin
    result := Format('%.2fGBW', [MBW / 1024]);
  end
  else
  begin
    result := Format('%.2fMBW', [MBW]);
  end;
end;

function GetDayStr(Day: Double): String;
const
  Months = [0..11];
  Day28 = [1];
  Day31 = [0, 2, 4, 6, 7, 9, 11];
var
  HWDay: Double;
  CurrMon: Integer;
  CurrMonDays: Integer;
  HWDayYear, HWDayMon, HWDayDay: Integer;
begin
  HWDay := Day;

  HWDayYear := floor(HWDay / 365);
  HWDay := HWDay - (HWDayYear * 365);

  HWDayMon := 0;
  for CurrMon in Months do
  begin
    if CurrMon in Day31 then
      CurrMonDays := 31
    else if CurrMon in Day28 then
      CurrMonDays := 28
    else
      CurrMonDays := 30;

    if HWDay >= CurrMonDays then
    begin
      HWDay := HWDay - CurrMonDays;
      Inc(HWDayMon, 1);
    end
    else
      break;
  end;

  HWDayDay := floor(HWDay);

  if HWDayYear > 0 then //Above 1yr
  begin
    result := Format('%d년 ', [HWDayYear]);
  end;

  if HWDayMon > 0 then //Above 1mon
  begin
    result := result + Format('%d개월 ', [HWDayMon]);
  end;

  if HWDayDay > 0 then
  begin
    result := result + Format('%d일 ', [HWDayDay])
  end
  else if (Day < 1) and (Day >= 0) then
    result := result + Format('%.1f일 ',[Day]);
end;
end.

