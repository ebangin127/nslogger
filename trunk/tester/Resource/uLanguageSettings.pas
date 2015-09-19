unit uLanguageSettings;

interface

uses Windows;

var
  CurrLang: Integer;

const
  LANG_HANGUL = 0;
  LANG_ENGLISH = 1;

const
  CapDay: Array[0..1] of String = ('일' , 'day');
  CapCount: Array[0..1] of String = ('개' , '');
  CapSec: Array[0..1] of String = ('초' , 'sec');
  CapMin: Array[0..1] of String = ('분' , 'min');
  CapHour: Array[0..1] of String = ('시간' , 'hour');
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
