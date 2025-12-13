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
set MADS_FOLDER=%WUDSN_TOOLS_FOLDER%\ASM\MADS
set PATH=%MP_FOLDER%\bin\windows;%MADS_FOLDER%\bin\windows_x86_64;%PATH%

set INPUT_FOLDER=%~dp1
cd /D %INPUT_FOLDER%
set INPUT_FILE=%~n1

ECHO.%INPUT_FOLDER%| FIND /I "c64">Nul && ( 
  set OUTPUT_TARGET=c64
  set OUTPUT_FILE=%INPUT_FILE%.prg
) || (
  set OUTPUT_TARGET=a8
  set OUTPUT_FILE=%INPUT_FILE%.xex
)

if exist %INPUT_FILE%.a65 del %INPUT_FILE%.a65
if exist %INPUT_FILE%.lab del %INPUT_FILE%.lab
if exist %INPUT_FILE%.lsr del %INPUT_FILE%.lst
if exist %OUTPUT_FILE% del %OUTPUT_FILE%

mp.exe %INPUT_FILE%.pas -ipath:%MP_FOLDER%\lib -ipath:%MP_FOLDER%\blibs -t %OUTPUT_TARGET% 
if ERRORLEVEL 1 (
  echo ERROR: Mad-Pascal error. See error messages above.
  goto :end
)

if NOT "%MADS_OPTIONS%"=="" goto :use_mads_options
set MADS_OPTIONS=-x -l -t
:use_mads_options

mads.exe %INPUT_FILE%.a65 -i:%MP_FOLDER%\base %MADS_OPTIONS% -o:%OUTPUT_FILE%
if ERRORLEVEL 1 (
  echo ERROR: Mad-Assembler error. See error messages above.
  goto :end
)

start %OUTPUT_FILE%
pause
goto :eof

:end
if "%MODE%"=="SHELL" (
  pause
)
goto :eof

:contains
set SOURCE_STRING=%1
set SEARCH_STRING=%2
set CONTAINS=NO
ECHO.%SOURCE_STRING%| FIND /I "%SEARCH_STRING%">Nul && ( 
  set CONTAINS=YES
) || (
 rem
)
goto :eof



