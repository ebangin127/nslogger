unit OS.Directory;

interface

{$WARN UNIT_PLATFORM OFF}
{$WARN SYMBOL_PLATFORM OFF}

uses Dialogs, SysUtils, ShellAPI, FileCtrl;

function DeleteDirectory(const DirectoryToDelete: String): Boolean;
function SelectDirectory(const DialogTitle: String; const DefaultDir: String):
  String;

implementation

function GetSHFileOpStruct(const DirectoryToDelete: String): TSHFileOpStruct;
begin
  FillChar(result, sizeof(SHFileOpStruct), 0);
  result.Wnd := 0;
  result.pFrom := PChar(DirectoryToDelete);
  result.wFunc := FO_DELETE;
  result.fFlags := result.fFlags or FOF_NOCONFIRMATION;
  result.fFlags := result.fFlags or FOF_SILENT;
end;

function TryToDeleteFoundDirectory(const DirectoryToDelete,
  FoundFile: String): Boolean;
var
  CurrentDirectoryToDelete: String;
begin
  CurrentDirectoryToDelete := ExcludeTrailingPathDelimiter(
    DirectoryToDelete + FoundFile);
  result := (SHFileOperation(GetSHFileOpStruct(
    CurrentDirectoryToDelete)) = 0);
end;

function DeleteDirectory(const DirectoryToDelete: String): Boolean;
var
  ZeroFoundElseNotFound: integer;
  SearchRecord: TSearchRec;
begin
  result := false;
  ZeroFoundElseNotFound := FindFirst(DirectoryToDelete + '*.*', faAnyFile,
    SearchRecord);

  while ZeroFoundElseNotFound = 0 do
  begin
    TryToDeleteFoundDirectory(DirectoryToDelete, SearchRecord.Name);
    ZeroFoundElseNotFound := FindNext(SearchRecord);
  end;

  FindClose(SearchRecord);
end;

function SelectDirectoryNewUI(const DialogTitle: String;
  const DefaultDir: String): String;
var
  FileOpenDialog: TFileOpenDialog;
begin
  FileOpenDialog := TFileOpenDialog.Create(nil);
  try
    FileOpenDialog.Title := DialogTitle;
    FileOpenDialog.Options := [fdoPickFolders, fdoPathMustExist,
      fdoForceFileSystem];
    FileOpenDialog.DefaultFolder := DefaultDir;
    FileOpenDialog.FileName := '';
    if FileOpenDialog.Execute then
      result := FileOpenDialog.FileName;
  finally
    FileOpenDialog.Free;
  end;
end;

function SelectDirectoryOldUI(const DialogTitle: String;
  const DefaultDir: String): String;
begin
  result := DefaultDir;
  FileCtrl.SelectDirectory(DialogTitle, ExtractFileDrive(DefaultDir),
    result, [sdNewUI, sdNewFolder], nil);
end;

function SelectDirectory(const DialogTitle: String; const DefaultDir: String):
  String;
begin
  if Win32MajorVersion >= 6 then
    result := SelectDirectoryNewUI(DialogTitle, DefaultDir)
  else
    result := SelectDirectoryOldUI(DialogTitle, DefaultDir);

  if result <> '' then
    result := result + '\';
end;

end.
