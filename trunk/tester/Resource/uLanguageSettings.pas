unit uLanguageSettings;

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
    ('���Ϸ� ����', 'SaveToFile');
  CommonLoadFromFile: TLanguageString =
    ('���Ͽ��� �ҷ�����', 'Load from file');

  TimeSec: TLanguageString = ('��', 'sec');
  TimeMin: TLanguageString = ('��', 'min');
  TimeHour: TLanguageString = ('�ð�', 'hour');
  TimeDay: TLanguageString = ('��', 'day');
  TimeMonth: TLanguageString = ('��', 'month');
  TimeYear: TLanguageString = ('��', 'year');
  TimeMultiple: TLanguageString = ('', 's');

  MainForceRetentionTest: TLanguageString =
    ('���� ���ټ� �׽�Ʈ', 'Retention Test requested by user');
  MainSaveAndQuit: TLanguageString =
    ('���� �� ����', 'Save and quit');
  MainTestEndNormally: TLanguageString =
    ('�׽�Ʈ ���� ����', 'Test exited normally');
  MainWrittenAmount: TLanguageString =
    ('���ⷮ', 'Host Write');
  MainAverageLatency: TLanguageString =
    ('��� ����', 'Average Latency');
  MainMaxLatency: TLanguageString =
    ('�ִ� ����', 'Maximum Latency');
  MainRetentionTestEnd: TLanguageString =
    ('���ټ� �׽�Ʈ ����', 'Retention Test end');
  MainRetentionCanceled: TLanguageString =
    ('���ټ� �׽�Ʈ ���� ���', 'Retention Test verification canceled');
  MainWantRepeatTest: TLanguageString =
    ('���ټ� �׽�Ʈ�� �ݺ��Ͻðڽ��ϱ�?',
     'Do you want to repeat Retention Test?');
  MainPreconditioningEnd: TLanguageString =
    ('�׽�Ʈ ���� �غ� �Ϸ�', 'Preconditioning process end');

  TesterThreadExitHostWrite: TLanguageString =
    ('��ǥ TBW�� �����Ͽ� ���� ����', 'Exit by reaching TBW');
  TesterThreadExitPeriodicRetention: TLanguageString =
    ('�ֱ��� ���ټ� �׽�Ʈ', 'Periodic retention test');
  TesterThreadExitRetentionExtended: TLanguageString =
    ('���ټ� �׽�Ʈ �ݺ� ����', 'Retention Test extended by user');
  TesterThreadExitFFR: TLanguageString =
    ('��� ������(FFR) ������', 'Abnormal FFR above set FFR limit');
  TesterThreadExitNormal: TLanguageString =
    ('����ڿ� ���� ����', 'Exit by user');
  TesterThreadTestNumPre: TLanguageString = ('�׽�Ʈ #', 'Test #');
  TesterThreadTestStarted: TLanguageString = ('����', 'started');
  TesterThreadIteratorPosition: TLanguageString =
    ('�ݺ��� ��ġ', 'Iterator Position');
  TesterThreadErrorAt: TLanguageString =
    ('������ ����', 'error occured as listed below');
  TesterThreadRead: TLanguageString = ('�б�', 'Read');
  TesterThreadWrite: TLanguageString = ('����', 'Write');
  TesterThreadTrim: TLanguageString = ('Ʈ��', 'Trim');
  TesterThreadFlush: TLanguageString = ('�÷���', 'Flush');
  TesterThreadError: TLanguageString = ('����', 'error');
  TesterThreadPosition: TLanguageString = ('��ġ', 'Position');
  TesterThreadLength: TLanguageString = ('����', 'Length');
  TesterThreadErrorEnd: TLanguageString = ('������ ���� ��', 'listing end');

  TesterToViewGood: TLanguageString = ('��ȣ', 'Good');
  TesterToViewNormal: TLanguageString = ('����', 'Normal');
  TesterToViewBad: TLanguageString = ('����', 'Bad');

  SettingNoTestFileError: TLanguageString =
    ('�׽�Ʈ ������ �����ϴ�', 'There''s no test file');
  SettingInvalidDrive: TLanguageString =
    ('��� ��ġ�� �ùٸ��� �Է����ּ���', 'Set valid drive');
  SettingInvalidTBWToWrite: TLanguageString =
    ('��ǥ TBW�� �ùٸ��� �Է����ּ���', 'Set valid TBW to write');
  SettingInvalidRetentionTestPeriod: TLanguageString =
    ('���ټ� �׽�Ʈ �ֱ⸦ �ùٸ��� �Է����ּ���',
     'Set valid retention test period');
  SettingInvalidFFR: TLanguageString =
    ('��� �������� �ùٸ��� �Է����ּ���', 'Set valid FFR');
  SettingTBWToWriteIsLowerThanPeriod: TLanguageString =
    ('��ǥ TBW�� ���ټ� �׽�Ʈ �ֱ⺸�� ���� �� �����ϴ�',
     'TBW to write can''t be lower than Retention test period');
  SettingOverwriteLog: TLanguageString =
    ('�ش� ������ �̹� �αװ� �ֽ��ϴ�. �����ðڽ��ϱ�?',
     'Do you want to overwrite existing log in this folder?');
  SettingSelectFolderToSaveLog: TLanguageString =
    ('�αװ� ����� ������ �������ּ���',
     'Select folder to save log');
  SettingSelectFolderSavedLog: TLanguageString =
    ('�αװ� ����� ������ �������ּ���',
     'Select folder that has test log');

  RetentionStartPreconditioning: TLanguageString =
    ('�׽�Ʈ ���� �غ� ����', 'Start preconditioning');
  RetentionPreconditioning: TLanguageString =
    ('�׽�Ʈ ���� �غ�', 'Preconditioning');
  RetentionStartVerifying: TLanguageString =
    ('���� ����', 'Start verifying');

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
