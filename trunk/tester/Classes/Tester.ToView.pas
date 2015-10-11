unit Tester.ToView;

interface

uses
  SysUtils, ComCtrls, StdCtrls, Math, Classes,
  LanguageStrings;

type
  TTesterToView = class
  private
    procedure SyncApplyProgress(const TBWStr, DayStr: String;
      const HostWrite, MaxHostWrite: UInt64);
    procedure SyncApplyLatency(const Average, Max: Double);
    procedure SyncApplyFFR(const CurrentFFR, MaxFFR: Double);
    procedure SyncApplyLatencyToProgressBar(const Latency: Double; const StaticText:
      TStaticText; const ProgressBar: TProgressBar);
    procedure SyncApplyStart;
    procedure SyncAddToAlert(const Value: String);
    procedure SyncFreezeAlertListBox;
    procedure SyncUnfreezeAlertListBox;
  public
    procedure ApplyProgress(const TBWStr, DayStr: String;
      const HostWrite, MaxHostWrite: UInt64);
    procedure ApplyLatency(const Average, Max: Double);
    procedure ApplyFFR(const CurrentFFR, MaxFFR: Double);
    procedure ApplyLatencyToProgressBar(const Latency: Double; const StaticText:
      TStaticText; const ProgressBar: TProgressBar);
    procedure ApplyStart;
    procedure AddToAlert(const Value: String);
    procedure FreezeAlertListBox;
    procedure UnfreezeAlertListBox;
  end;

implementation

uses
  Form.Main;

{ TTesterToView }

procedure TTesterToView.AddToAlert(const Value: String);
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncAddToAlert(Value);
  end);
end;

procedure TTesterToView.ApplyFFR(const CurrentFFR, MaxFFR: Double);
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncApplyFFR(CurrentFFR, MaxFFR);
  end);
end;

procedure TTesterToView.ApplyLatency(const Average, Max: Double);
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncApplyLatency(Average, Max);
  end);
end;

procedure TTesterToView.ApplyLatencyToProgressBar(const Latency: Double;
  const StaticText: TStaticText; const ProgressBar: TProgressBar);
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncApplyLatencyToProgressBar(Latency, StaticText, ProgressBar);
  end);
end;

procedure TTesterToView.ApplyProgress(const TBWStr, DayStr: String;
  const HostWrite, MaxHostWrite: UInt64);
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncApplyProgress(TBWStr, DayStr, HostWrite, MaxHostWrite);
  end);
end;

procedure TTesterToView.ApplyStart;
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncApplyStart;
  end);
end;

procedure TTesterToView.FreezeAlertListBox;
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncFreezeAlertListBox;
  end);
end;

procedure TTesterToView.UnfreezeAlertListBox;
begin
  TThread.Queue(TThread.CurrentThread, procedure
  begin
    if fMain <> nil then
      SyncUnfreezeAlertListBox;
  end);
end;

procedure TTesterToView.SyncAddToAlert(const Value: String);
begin
  fMain.lAlert.Items.Add(Value);
end;

procedure TTesterToView.SyncApplyFFR(const CurrentFFR, MaxFFR: Double);
begin
  fMain.sFFR.Caption := FormatFloat('0.####', CurrentFFR) + '%';
  fMain.pFFR.Position := round((CurrentFFR / MaxFFR) * 100);
  if fMain.pFFR.Position > 10 then
    fMain.pFFR.State := TProgressBarState.pbsPaused
  else if fMain.pFFR.Position > 50 then
    fMain.pFFR.State := TProgressBarState.pbsError;
end;

procedure TTesterToView.SyncApplyLatencyToProgressBar(const Latency: Double;
  const StaticText: TStaticText; const ProgressBar: TProgressBar);
const
  ABNORMAL_VALUE = 500;
  ERROR_VALUE = 10000;
var
  Position: Integer;
begin
  if Latency < ABNORMAL_VALUE then
  begin
    StaticText.Caption := TesterToViewGood[CurrLang] + '(';
    ProgressBar.State := pbsNormal;
  end
  else if Latency < ERROR_VALUE then
  begin
    StaticText.Caption := TesterToViewNormal[CurrLang] + '(';
    ProgressBar.State := pbsPaused;
  end
  else if Latency >= ERROR_VALUE then
  begin
    StaticText.Caption := TesterToViewBad[CurrLang] + '(';
    ProgressBar.State := pbsError;
  end;
  StaticText.Caption :=
    StaticText.Caption + Format('%.2f%s)', [Latency, 'ms']);
  Position := 0;
  if Latency > 0 then
    Position := round(Log10((Latency / ERROR_VALUE) * 100) / 2 * 100);
  ProgressBar.Position := Min(Position, 100);
end;

procedure TTesterToView.SyncApplyLatency(const Average, Max: Double);
begin
  SyncApplyLatencyToProgressBar(Average, fMain.sAvgLatency, fMain.pAvgLatency);
  SyncApplyLatencyToProgressBar(Max, fMain.sMaxLatency, fMain.pMaxLatency);
end;

procedure TTesterToView.SyncApplyProgress(const TBWStr, DayStr: String;
  const HostWrite, MaxHostWrite: UInt64);
var
  TestProgress: Integer;
  NewCaption: String;
begin
  TestProgress :=
    round(((HostWrite / MaxHostWrite) - (HostWrite div MaxHostWrite)) * 100);
  fMain.pTestProgress.Position := TestProgress;
  fMain.sTestProgress.Caption := IntToStr(TestProgress) + '% (';

  fMain.sTestProgress.Caption := fMain.sTestProgress.Caption + TBWStr + ' / ';
  fMain.sTestProgress.Caption := fMain.sTestProgress.Caption + DayStr;

  NewCaption := fMain.sTestProgress.Caption;
  NewCaption[Length(NewCaption)] := ')';
  fMain.sTestProgress.Caption := NewCaption;
end;

procedure TTesterToView.SyncApplyStart;
begin
  fMain.iSave.Enabled := true;
  fMain.iForceReten.Enabled := true;

  fMain.lSave.Enabled := true;
  fMain.lForceReten.Enabled := true;
end;

procedure TTesterToView.SyncUnfreezeAlertListBox;
begin
  fMain.lAlert.Items.EndUpdate;
end;

procedure TTesterToView.SyncFreezeAlertListBox;
begin
  fMain.lAlert.Items.BeginUpdate;
end;

end.
