program nsloggerTests;
{

  Delphi DUnit Test Project
  -------------------------
  This project contains the DUnit test framework and the GUI/Console test runners.
  Add "CONSOLE_TESTRUNNER" to the conditional defines entry in the project options
  to use the console test runner.  Otherwise the GUI test runner will be used by
  default.

}

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  DUnitTestRunner,
  TestuTraceList in 'TestuTraceList.pas',
  uTraceList in '..\Classes\Tester\uTraceList.pas',
  Trace.Node in '..\Classes\Tester\Trace.Node.pas';

{$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.

