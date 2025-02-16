@echo off
setlocal

if "%1%"=="" (
  echo USAGE: Mad-Pascal.bat ^<inputfile^>.pas
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

set MP_FOLDER=%WUDSN_TOOLS_FOLDER%\PAS\MP
set MADS_FOLDER=%WUDSN_TOOLS_FOLDER%\ASM\MADS\bin\windows_x86_64
set PATH=%MP_FOLDER%\bin\windows;%MADS_FOLDER%;%PATH%

set INPUT_FOLDER=%~dp1
cd /D %INPUT_FOLDER%
set INPUT_FILE=%~n1
set OUTPUT_FILE=%INPUT_FILE%.xex

if exist %INPUT_FILE%.a65 del %INPUT_FILE%.a65
if exist %INPUT_FILE%.lab del %INPUT_FILE%.lab
if exist %INPUT_FILE%.lsr del %INPUT_FILE%.lst
if exist %OUTPUT_FILE% del %OUTPUT_FILE%

mp.exe %INPUT_FILE%.pas -ipath:%MP_FOLDER%\lib -ipath:%MP_FOLDER%\blibs
if ERRORLEVEL 1 (
  echo ERROR: Mad-Pascal error. See error messages above.
  goto :end
) 

mads.exe %INPUT_FILE%.a65 -x -i:%MP_FOLDER%\base -l -t -o:%INPUT_FILE%.xex
if ERRORLEVEL 1 (
  echo ERROR: Mad-Assembler error. See error messages above.
  goto :end
)

start %OUTPUT_FILE%
goto :eof

:end
if "%MODE%"=="SHELL" (
  pause
)
goto :eof



