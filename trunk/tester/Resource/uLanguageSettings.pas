unit uLanguageSettings;

interface

uses Windows;

var
  CurrLang: Integer;

const
  LANG_HANGUL = 0;
  LANG_ENGLISH = 1;

const
  CapDay: Array[0..1] of String = ('��' , 'day');
  CapCount: Array[0..1] of String = ('��' , '');
  CapSec: Array[0..1] of String = ('��' , 'sec');
  CapMin: Array[0..1] of String = ('��' , 'min');
  CapHour: Array[0..1] of String = ('�ð�' , 'hour');
  CapMultiple: Array[0..1] of String = ('' , 's');

procedure DetermineLanguage;

implementation

procedure DetermineLanguage;
begin
  if GetSystemDefaultLangID = 1042 then
    CurrLang := LANG_HANGUL
  else
    CurrLang := LANG_ENGLISH;
end;

initialization
  DetermineLanguage;
end.
