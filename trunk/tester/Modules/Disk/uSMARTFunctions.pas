unit uSMARTFunctions;

interface

uses SysUtils, Math, Generics.Collections,
     uDiskFunctions;

type
  PTSMARTResult = ^TSMARTResult;
  TSMARTResult = record
    FID: SmallInt;
    FCurrentPercent: SmallInt;
    FCurrentValue: UInt64;
  end;

function ExtractSMART(SMARTData: SENDCMDOUTPARAMS; WantedInfo: Integer):
                      UInt64; overload;
function ExtractSMART(SMARTData: SENDCMDOUTPARAMS; WantedInfo: String):
                      UInt64; overload;
function ExtractSMARTPercent(const SMARTData: SENDCMDOUTPARAMS;
                                    WantedInfo: Integer): UInt64; overload;
function ExtractSMARTPercent(const SMARTData: SENDCMDOUTPARAMS;
                                    WantedInfo: String): UInt64; overload;
function IsValidSMART(const SMARTData: SENDCMDOUTPARAMS): Boolean;

implementation

function ExtractSMART(SMARTData: SENDCMDOUTPARAMS; WantedInfo: Integer):
                      UInt64; overload;
var
  CurrInfo, CurrPoint: Integer;
  SCSIConst: Integer;
begin
  FillChar(result, SizeOf(result), #0);
  if SMARTData.cBufferSize = 0 then SCSIConst := -6
    else SCSIConst := 0;
  for CurrInfo := 0 to floor(Length(SMARTData.bBuffer) / 12) do
  begin
    if SMARTData.bBuffer[8 + (CurrInfo * 12) + SCSIConst] = WantedInfo then
    begin
      result := 0;
      for CurrPoint := 0 to 5 do
      begin
        result := result shl 8;
        result := result
                  + SMARTData.bBuffer[(6 - CurrPoint)
                                      + ((CurrInfo + 1) * 12) + SCSIConst];
      end;
      break;
    end;
  end;
end;

function ExtractSMART(SMARTData: SENDCMDOUTPARAMS; WantedInfo: String):
                      UInt64; overload;
var
  WantedInfoInt: Integer;
begin
  WantedInfoInt := StrToInt('$' + WantedInfo);
  result := ExtractSMART(SMARTData, WantedInfoInt);
end;

function ExtractSMARTPercent(const SMARTData: SENDCMDOUTPARAMS;
                                    WantedInfo: Integer): UInt64; overload;
var
  CurrInfo: Integer;
  SCSIConst: Integer;
begin
  result := 0;
  if SMARTData.cBufferSize = 0 then SCSIConst := -6
    else SCSIConst := 0;
  for CurrInfo := 0 to floor(Length(SMARTData.bBuffer) / 12) do
  begin
    if SMARTData.bBuffer[8 + (CurrInfo * 12) + SCSIConst] = WantedInfo then
    begin
      Result := SMARTData.bBuffer[11 + ((CurrInfo + 1) * 12) + SCSIConst];
      break;
    end;
  end;
end;

function ExtractSMARTPercent(const SMARTData: SENDCMDOUTPARAMS;
                              WantedInfo: String): UInt64; overload;
var
  WantedInfoInt: Integer;
begin
  WantedInfoInt := StrToInt('$' + WantedInfo);
  result := ExtractSMARTPercent(SMARTData, WantedInfoInt);
end;

function IsValidSMART(const SMARTData: SENDCMDOUTPARAMS): Boolean;
var
  Verifier: Byte;
  CurrVrfy: Integer;
begin
  Verifier := 0;
  result := false;
  for CurrVrfy := 0 to Length(SMARTData.bBuffer) - 1 do
    Verifier := Verifier or SMARTData.bBuffer[CurrVrfy];
  if Verifier <> 0 then result := true;
end;

end.
