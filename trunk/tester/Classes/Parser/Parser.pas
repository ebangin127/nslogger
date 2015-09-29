unit Parser;

interface

uses
  Classes, Windows, SysUtils, Dialogs,
  uGSList, uGSNode, Parser.Producer, Parser.Consumer, Parser.BufferStorage,
  Parser.Divider, Threading, MMSystem;

procedure ImportTrace(TraceList: TGSList; Path: PChar; MultiConst: Double);

implementation

procedure ImportTrace(TraceList: TGSList; Path: PChar; MultiConst: Double);
const
  DivideCount = 4;
var
  Divider: TDivider;
  DivResult: TDividedResult;
  Producer: Array[0..DivideCount - 1] of TProducer;
  Consumer: Array[0..DivideCount - 1] of TConsumer;
  CommitList: Array[0..DivideCount - 1] of TGSList;
  StartTime, EndTime: Cardinal;
  CurrentIndex: Integer;
  ResultCount: Integer;
begin
  StartTime := TimeGetTime;
  Divider := TDivider.Create(Path);
  DivResult := Divider.Divide(DivideCount);
  FreeAndNil(Divider);

  TParallel.For(0, DivideCount - 1, procedure (CurrentIndex: Integer)
  var
    LocalList: TGSList;
    LocalBufStor: TBufferStorage;
  begin
    LocalList := TGSList.Create;
    LocalBufStor := TBufferStorage.Create;
    Producer[CurrentIndex] :=
      TProducer.Create(LocalBufStor, Path, DivResult[CurrentIndex]);
    Consumer[CurrentIndex] :=
      TConsumer.Create(LocalBufStor, LocalList, MultiConst);
    CommitList[CurrentIndex] := LocalList;
  end);

  ResultCount := 0;
  for CurrentIndex := 0 to DivideCount - 1 do
  begin
    WaitForSingleObject(Producer[CurrentIndex].Handle, INFINITE);
    FreeAndNil(Producer[CurrentIndex]);
    WaitForSingleObject(Consumer[CurrentIndex].Handle, INFINITE);
    FreeAndNil(Consumer[CurrentIndex]);
    ResultCount := ResultCount + CommitList[CurrentIndex].Count;
  end;

  EndTime := TimeGetTime;
  ShowMessage('Time: ' + IntToStr(EndTime - StartTime) + 'ms, Count: ' + IntToStr(ResultCount));
end;
end.
