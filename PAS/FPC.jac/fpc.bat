@echo off
setlocal

if "%1%"=="" (
  echo USAGE: fpc.bat ^<inputfile^>.pas
  goto :eof
)

set MODE=%2

rem Assuming the standard folder structure of WUDSN IDE.
if "%WUDSN_TOOLS_FOLDER%"=="" (

  if "%WUDSN_FOLDER%"=="" (
    echo ERROR: Environment variable WUDSN_FOLDER or WUDSN_TOOLS_FOLDER must be set.
    goto :end
  )
  set WUDSN_TOOLS_FOLDER=%WUDSN_FOLDER%\Tools
)

set FPC_FOLDER=C:\jac\system\Windows\Tools\PAS\Lazarus\fpc\3.2.2\bin\x86_64-win64
set PATH=%FPC_FOLDER%;%PATH%

set INPUT_FOLDER=%~dp1
cd /D %INPUT_FOLDER%
set INPUT_FILE=%~n1
set OUTPUT_FILE=%INPUT_FILE%.exe

if exist %INPUT_FILE%.o del %INPUT_FILE%.o
if exist %OUTPUT_FILE% del %OUTPUT_FILE%

fpc.exe %INPUT_FILE%.pas
if ERRORLEVEL 1 (
  echo ERROR: FPC error. See error messages above.
  goto :end
)
if exist %INPUT_FILE%.o del %INPUT_FILE%.o

start %OUTPUT_FILE%
goto :eof

:end
if "%MODE%"=="SHELL" (
  pause
)
goto :eof




