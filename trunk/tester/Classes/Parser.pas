unit Parser;

interface

uses
  Classes, Windows, SysUtils, Dialogs,
  Trace.List, Trace.Node, Parser.Producer, Parser.Consumer,
  Parser.BufferStorage, Parser.Divider, Pattern.Singleton;

type
  TParser = class(TSingleton<TParser>)
  public
    function ImportTrace(const Path: String; const MultiConst: Double;
      const DividedAreaToGet: TDividedArea): TTraceList;
  end;

implementation

function TParser.ImportTrace(const Path: String; const MultiConst: Double;
  const DividedAreaToGet: TDividedArea): TTraceList;
var
  Producer: TProducer;
  Consumer: TConsumer;
  BufferStorage: TBufferStorage;
begin
  result := TTraceList.Create;
  BufferStorage := TBufferStorage.Create;
  Producer := TProducer.Create(BufferStorage, Path, DividedAreaToGet);
  Consumer := TConsumer.Create(BufferStorage, result, MultiConst);

  WaitForSingleObject(Producer.Handle, INFINITE);
  FreeAndNil(Producer);
  WaitForSingleObject(Consumer.Handle, INFINITE);
  FreeAndNil(Consumer);
end;

initialization
finalization
  TParser.FreeSingletonInstance;
end.
