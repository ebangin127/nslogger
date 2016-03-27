unit LanguageStrings;

interface

uses Windows;

var
  CurrLang: Integer;

type
  TLanguageString = Array[0..1] of String;

const
  LANG_HANGUL = 0;
  LANG_ENGLISH = 1;

const
  CommonSaveToFile: TLanguageString =
    ('파일로 저장', 'SaveToFile');
  CommonLoadFromFile: TLanguageString =
    ('파일에서 불러오기', 'Load from file');

  TimeSec: TLanguageString = ('초', 'sec');
  TimeMin: TLanguageString = ('분', 'min');
  TimeHour: TLanguageString = ('시간', 'hour');
  TimeDay: TLanguageString = ('일', 'day');
  TimeMonth: TLanguageString = ('월', 'month');
  TimeYear: TLanguageString = ('년', 'year');
  TimeMultiple: TLanguageString = ('', 's');

  MainForceRetentionTest: TLanguageString =
    ('임의 리텐션 테스트', 'Retention Test requested by user');
  MainSaveAndQuit: TLanguageString =
    ('저장 후 종료', 'Save and quit');
  MainTestEndNormally: TLanguageString =
    ('테스트 정상 종료', 'Test exited normally');
  MainWrittenAmount: TLanguageString =
    ('쓰기량', 'Host Write');
  MainAverageLatency: TLanguageString =
    ('평균 지연', 'Average Latency');
  MainMaxLatency: TLanguageString =
    ('최대 지연', 'Maximum Latency');
  MainRetentionTestEnd: TLanguageString =
    ('리텐션 테스트 종료', 'Retention Test end');
  MainRetentionCanceled: TLanguageString =
    ('리텐션 테스트 검증 취소', 'Retention Test verification canceled');
  MainWantRepeatTest: TLanguageString =
    ('리텐션 테스트를 반복하시겠습니까?',
     'Do you want to repeat Retention Test?');
  MainPreconditioningEnd: TLanguageString =
    ('테스트 사전 준비 완료', 'Preconditioning process end');

  TesterThreadExitHostWrite: TLanguageString =
    ('목표 TBW에 도달하여 쓰기 종료', 'Exit by reaching TBW');
  TesterThreadExitPeriodicRetention: TLanguageString =
    ('주기적 리텐션 테스트', 'Periodic retention test');
  TesterThreadExitRetentionExtended: TLanguageString =
    ('리텐션 테스트 반복 진행', 'Retention Test extended by user');
  TesterThreadExitFFR: TLanguageString =
    ('기능 실패율(FFR) 비정상', 'Abnormal FFR above set FFR limit');
  TesterThreadExitNormal: TLanguageString =
    ('사용자에 의한 종료', 'Exit by user');
  TesterThreadTestNumPre: TLanguageString = ('테스트 #', 'Test #');
  TesterThreadTestStarted: TLanguageString = ('시작', 'started');
  TesterThreadIteratorPosition: TLanguageString =
    ('반복자 위치', 'Iterator Position');
  TesterThreadErrorAt: TLanguageString =
    ('지점의 오류', 'error occured as listed below');
  TesterThreadRead: TLanguageString = ('읽기', 'Read');
  TesterThreadWrite: TLanguageString = ('쓰기', 'Write');
  TesterThreadTrim: TLanguageString = ('트림', 'Trim');
  TesterThreadFlush: TLanguageString = ('플러시', 'Flush');
  TesterThreadError: TLanguageString = ('오류', 'error');
  TesterThreadPosition: TLanguageString = ('위치', 'Position');
  TesterThreadLength: TLanguageString = ('길이', 'Length');
  TesterThreadErrorEnd: TLanguageString = ('지점의 오류 끝', 'listing end');
  TesterThreadNewValue: TLanguageString =
    ('새로운 값', '새로운 값');

  TesterToViewGood: TLanguageString = ('양호', 'Good');
  TesterToViewNormal: TLanguageString = ('보통', 'Normal');
  TesterToViewBad: TLanguageString = ('나쁨', 'Bad');

  SettingNoTestFileError: TLanguageString =
    ('테스트 파일이 없습니다', 'There''s no test file');
  SettingInvalidDrive: TLanguageString =
    ('대상 위치를 올바르게 입력해주세요', 'Set valid drive');
  SettingInvalidRetentionTestPeriod: TLanguageString =
    ('리텐션 테스트 주기를 올바르게 입력해주세요',
     'Set valid retention test period');
  SettingInvalidFFR: TLanguageString =
    ('기능 실패율을 올바르게 입력해주세요', 'Set valid FFR');
  SettingOverwriteLog: TLanguageString =
    ('해당 폴더에 이미 로그가 있습니다. 덮어씌우시겠습니까?',
     'Do you want to overwrite existing log in this folder?');
  SettingInvalidTracePath: TLanguageString =
    ('트레이스 위치를 올바르게 입력해주세요',
     'Set valid Trace Path');
  SettingInvalidOriginalLBA: TLanguageString =
    ('트레이스 기준 용량을 올바르게 입력해주세요',
     'Set valid Capacity of Storage that Trace gathered from');
  SettingSelectFolderToSaveLog: TLanguageString =
    ('로그가 저장될 폴더를 선택해주세요',
     'Select folder to save log');
  SettingSelectFolderSavedLog: TLanguageString =
    ('로그가 저장된 폴더를 선택해주세요',
     'Select folder that has test log');

  RetentionStartPreconditioning: TLanguageString =
    ('테스트 사전 준비 시작', 'Start preconditioning');
  RetentionPreconditioning: TLanguageString =
    ('테스트 사전 준비', 'Preconditioning');
  RetentionStartVerifying: TLanguageString =
    ('검증 시작', 'Start verifying');

procedure DetermineLanguage;

implementation

procedure DetermineLanguage;
begin
  if GetUserDefaultLCID = 1042 then
    CurrLang := LANG_HANGUL
  else
    CurrLang := LANG_ENGLISH;
end;

initialization
  DetermineLanguage;
end.
