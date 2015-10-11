unit Windows.Directory;

interface

{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}

uses Dialogs, SysUtils, ShellAPI, FileCtrl;

function DeleteDirectory(const DirPath: String): Boolean;
function SelectDirectory(DialogTitle: String; DefaultDir: String): String;

implementation

function DeleteDirectory(const DirPath: String): Boolean;
var
  SHFileOpStruct: TSHFileOpStruct;
  DirBuf: array [0..255] of char;
  Directory: string;
  iFindResult: integer;
 srSchRec : TSearchRec;
begin
  Result := False;
  iFindResult := FindFirst(DirPath + '*.*', faAnyFile, srSchRec);
  while iFindResult = 0 do
  begin
    try
      Directory := ExcludeTrailingPathDelimiter(DirPath + srSchRec.Name);
      Fillchar(SHFileOpStruct, sizeof(SHFileOpStruct), 0);
      FillChar(DirBuf, sizeof(DirBuf), 0);
      StrPCopy(DirBuf, Directory);
      with SHFileOpStruct do
      begin
        Wnd := 0;
        pFrom := @DirBuf;
        wFunc := FO_DELETE;
        fFlags := fFlags or FOF_NOCONFIRMATION;
        fFlags := fFlags or FOF_SILENT;
      end;
      Result := (SHFileOperation(SHFileOpStruct) = 0);
    except
      Result := False;
    end;
    iFindResult := FindNext(srSchRec);
  end;
  FindClose(srSchRec);
end;

function SelectDirectory(DialogTitle: String; DefaultDir: String): String;
begin
   if Win32MajorVersion >= 6 then
    with TFileOpenDialog.Create(nil) do
      try
        Title := DialogTitle;
        Options := [fdoPickFolders, fdoPathMustExist, fdoForceFileSystem];
        DefaultFolder := DefaultDir;
        FileName := DefaultDir;
        if Execute then
          result := FileName;
      finally
        Free;
      end
  else
    if FileCtrl.SelectDirectory('Select Directory',
                              ExtractFileDrive(DefaultDir), DefaultDir,
                              [sdNewUI, sdNewFolder], nil) = true then
      result := DefaultDir;

  if result <> '' then
    result := result + '\';
end;

end.
