unit Error.List;

interface

uses
  Generics.Collections,
  Trace.Node, Windows;

type
  TErrorNode = TPair<TTraceNode, Cardinal>;
  TErrorList = TList<TErrorNode>;

function CreateErrorNode(const TraceNode: TTraceNode;
  const ErrorCode: Cardinal): TErrorNode;

implementation

function CreateErrorNode(const TraceNode: TTraceNode;
  const ErrorCode: Cardinal): TErrorNode;
begin
  result.Key := TraceNode;
  result.Value := ErrorCode;
end;

end.
