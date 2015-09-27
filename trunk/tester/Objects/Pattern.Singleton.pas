unit Pattern.Singleton;

interface

uses SysUtils;

type
  TSingleton<T: Class> = class
  private
    class var Instance: T;
  protected
    class procedure FreeSingletonInstance;
  public
    class procedure Create;
    class procedure Free;
    class function GetInstance: T;
  end;

implementation

class procedure TSingleton<T>.Create;
begin
  raise ENoConstructException.Create('It''s a singleton class!');
end;

class procedure TSingleton<T>.Free;
begin
  raise EInvalidOpException.Create('It''s a singleton class!');
end;

class procedure TSingleton<T>.FreeSingletonInstance;
begin
  Instance.Free;
end;

class function TSingleton<T>.GetInstance: T;
begin
  if Instance = nil then
  begin
    result := inherited Create as T;
  end
  else
  result := Instance;
end;

end.
