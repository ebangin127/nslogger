unit uPreCondThread;

interface

uses
  StdCtrls, ComCtrls, Classes, SysUtils, Windows, Dialogs,
  Device.PhysicalDrive, uRandomBuffer, uStrFunctions;

const
  LinearRead = 16 shl 20; // 16MB

type
  TPreCondThread = class(TThread)
  private
    FBufStor: TRandomBuffer;
    FFileStream: TFileStream;
    FMaxLength, FCurrWritten: Int64;
    FProgressBar: TProgressBar;
    FStaticText: TStaticText;
  public
    property CurrWritten: Int64 read FCurrWritten;

    constructor Create(Path: String; ProgressBar: TProgressBar;
                       StaticText: TStaticText);
    destructor Destroy; override;

    procedure Execute; override;
    procedure ApplyProgress;
    procedure EndCopy;
  end;

implementation

uses
  Form.Retention;

{ TPreCondThread }

procedure TPreCondThread.EndCopy;
begin
  fRetSel.EndTask := true;
  fRetSel.Written := CurrWritten;
  fRetSel.Close;
end;

procedure TPreCondThread.ApplyProgress;
var
  MaxMega, CurrMega: Int64;
begin
  MaxMega := FMaxLength shr 20;
  CurrMega := FCurrWritten shr 20;

  FStaticText.Caption := IntToStr(MaxMega) + 'MB / ' +
                         IntToStr(CurrMega) + 'MB';
  FProgressBar.Position := (CurrMega * 100) div MaxMega;
end;

constructor TPreCondThread.Create(Path: String; ProgressBar: TProgressBar;
                                  StaticText: TStaticText);
var
  RandomSeed: Int64;
  PhysicalDrive: IPhysicalDrive;
begin
  inherited Create(false);

  if QueryPerformanceCounter(RandomSeed) = false then
    RandomSeed := GetTickCount;

  PhysicalDrive :=
    TPhysicalDrive.Create(Path);
  FMaxLength := PhysicalDrive.IdentifyDeviceResult.UserSizeInKB * 1024;
    //Unit: Bytes
  PhysicalDrive := nil;

  FBufStor := TRandomBuffer.Create(RandomSeed);
  FBufStor.CreateBuffer(LinearRead shr 10);
  FBufStor.FillBuffer(100);
  FCurrWritten := 0;

  FProgressBar := ProgressBar;
  FStaticText := StaticText;

  FFileStream := TFileStream.Create(Path, fmOpenWrite or fmShareDenyNone);
end;

destructor TPreCondThread.Destroy;
begin
  inherited;
end;

procedure TPreCondThread.Execute;
const
  FiftyMB = 50 shl 10;
  Period = FiftyMB div LinearRead;
var
  Buffer: Pointer;
  WrittenLength: Integer;
  CurrNum: Integer;
  CurrSize: Int64;
  RemainSize: Int64;
begin
  inherited;

  CurrNum := Period;
  FFileStream.Position := 0;

  CurrSize := LinearRead;
  repeat
    Buffer := FBufStor.GetBufferPtr(LinearRead);
    if Buffer = nil then
      exit;

    RemainSize := FMaxLength - FFileStream.Position;
    if CurrSize > RemainSize then
      CurrSize := RemainSize;
    WrittenLength := FFileStream.Write(Buffer, CurrSize);

    Inc(FCurrWritten, WrittenLength);

    if CurrNum = 0 then
    begin
      Synchronize(ApplyProgress);
      CurrNum := Period;
    end
    else
      Dec(CurrNum);
  until FFileStream.Position = FMaxLength;
  FreeAndNil(FFileStream);

  Synchronize(EndCopy);
end;

end.
