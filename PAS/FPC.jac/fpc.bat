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
set INPUT_FILE_EXT=%~nx1
set OUTPUT_FILE=%INPUT_FILE%.exe
set LOG_FILE=%INPUT_FILE%.log

if exist %INPUT_FILE%.o del %INPUT_FILE%.o
if exist %OUTPUT_FILE% del %OUTPUT_FILE%
if exist %LOG_FILE% del %LOG_FILE%

rem Use recommended settings.
fpc.exe -MDelphi -vh -O3 %INPUT_FILE_EXT%

if ERRORLEVEL 1 (
  echo ERROR: FPC error. See error messages above.
  goto :end
)
if exist %INPUT_FILE%.o del %INPUT_FILE%.o

if "%MODE%"=="SHELL" goto :shell
goto :eof

:shell
%OUTPUT_FILE%
if exist %LOG_FILE% (
    type %LOG_FILE%
    goto :end
)
goto :end

:end
if "%MODE%"=="SHELL" (
  pause
)
goto :eof




