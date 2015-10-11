unit Parser;

interface

uses
  Classes, Windows, SysUtils, Dialogs,
  Trace.MultiList, Trace.List, Trace.Node, Parser.Producer, Parser.Consumer,
  Parser.BufferStorage, Parser.Divider, Threading, MMSystem;

procedure ImportTrace(const TraceMultiList: TTraceMultiList;
  const Path: PChar; const MultiConst: Double);

implementation

procedure ImportTrace(const TraceMultiList: TTraceMultiList; const Path: PChar;
  const MultiConst: Double);
var
  DivideCount: Integer;
  Divider: TDivider;
  DivResult: TDividedResult;
  Producer: Array of TProducer;
  Consumer: Array of TConsumer;
  CommitList: Array of TTraceList;
  CurrentIndex: Integer;
begin
  DivideCount := TThread.ProcessorCount;
  SetLength(Producer, DivideCount);
  SetLength(Consumer, DivideCount);
  SetLength(CommitList, DivideCount);

  Divider := TDivider.Create(Path);
  DivResult := Divider.Divide(DivideCount);
  FreeAndNil(Divider);

  TParallel.For(0, DivideCount - 1, procedure (CurrentIndex: Integer)
  var
    LocalList: TTraceList;
    LocalBufStor: TBufferStorage;
  begin
    LocalList := TTraceList.Create;
    LocalBufStor := TBufferStorage.Create;
    Producer[CurrentIndex] :=
      TProducer.Create(LocalBufStor, Path, DivResult[CurrentIndex]);
    Consumer[CurrentIndex] :=
      TConsumer.Create(LocalBufStor, LocalList, MultiConst);
    CommitList[CurrentIndex] := LocalList;
  end);

  for CurrentIndex := 0 to DivideCount - 1 do
  begin
    WaitForSingleObject(Producer[CurrentIndex].Handle, INFINITE);
    FreeAndNil(Producer[CurrentIndex]);
    WaitForSingleObject(Consumer[CurrentIndex].Handle, INFINITE);
    FreeAndNil(Consumer[CurrentIndex]);
    TraceMultiList.AddList(CommitList[CurrentIndex]);
  end;
end;
end.