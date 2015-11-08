unit Partition.List;

interface

uses
  Windows, Generics.Collections;

type
  TPartitionEntry = record
    Letter: String;
    StartingOffset: TLargeInteger;
  end;

  TPartitionList = TList<TPartitionEntry>;
implementation

end.
