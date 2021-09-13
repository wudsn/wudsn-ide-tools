@echo on
rem
rem Build script for creating the WUDSN IDE Windows 64-bit zero installation download archives.
rem The script also creates/updates the "compilers.zip" and "makefiles.zip" download archives.
rem Call with parameter "compilers-new.zip" to only build that archive.
rem Make sure the the Eclipse instance for the zero installation download is not active when the script is started.
rem
set COMPILERS=C:\jac\system\Java\Programming\Repositories\WUDSN-IDE\com.wudsn.ide.asm.compilers\binaries\compilers
set WUDSN=C:\jac\wudsn
set WORKSPACE=%WUDSN%\Workspace
set TOOLS=%WUDSN%\Tools
set WWW=%TOOLS%\WWW
set TARGET_DIR=C:\jac\system\WWW\Sites\www.wudsn.com\productions\java\ide\downloads
set PREFS_FILE=%WORKSPACE%\.metadata\.plugins\org.eclipse.core.runtime\.settings\com.wudsn.ide.asm.prefs
set WINRAR="C:\jac\system\Windows\Tools\FIL\WinRAR\winrar"

rem The "/tmp/compilers/compilers.zip" archive is for compiling on other platforms without breaking the original archive.
rem See "build-compilers-step1.bat".
call :CreateCompilersArchive
if "%1" == "compilers-step1" (
  call :UploadOne %TARGET%  "http://www.wudsn.com:81/tmp/compilers/compilers.zip"
  goto :eof
) else (
  move %TARGET% %TARGET_DIR%\compilers.zip
)

call :CreateMakefilesArchive
call :CopyCompilers
call :ClearWorkspace
call :PackAll
start %TARGET_DIR%
call :UploadAll
goto :eof

:CreateCompilersArchive
set TARGET_CD=%COMPILERS%
set TARGET=%TARGET_DIR%\compilers.zip
call :PackOne
goto :eof

:CreateMakefilesArchive
set TARGET_CD=%TARGET_DIR%\makefiles
set TARGET=%TARGET_DIR%\makefiles.zip
call :PackOne
goto :eof

:CopyCompilers
echo Copying compilers to zero installation distribution.
robocopy %COMPILERS%\ASM %TOOLS%\ASM /MIR /NFL /NDL /NJH /NJS
goto :eof

:ClearWorkspace
echo Clearing workspace.
set HISTORY_FOLDER=%WORKSPACE%\.metadata\.plugins\org.eclipse.core.resources\.history
del /S /Q %HISTORY_FOLDER%
mkdir %HISTORY_FOLDER%
echo "Log cleared." >%WORKSPACE%\.metadata\.log
call :ClearExample %WORKSPACE%\AppleII
call :ClearExample %WORKSPACE%\Atari2600
call :ClearExample %WORKSPACE%\Atari800
call :ClearExample %WORKSPACE%\C64
call :ClearExample %WORKSPACE%\NES
goto :eof

:ClearExample
if exist %1\*.atdbg del %1\*.atdbg
if exist %1\*.b     del %1\*.b
if exist %1\*.bin   del %1\*.bin
if exist %1\*.lab   del %1\*.lab
if exist %1\*.lst   del %1\*.lst
if exist %1\*.prg   del %1\*.prg
if exist %1\*.sym   del %1\*.sym
if exist %1\*.xex   del %1\*.xex
goto :eof

:PackAll
set TARGET_CD=%WUDSN%

echo Creating 64-bit compilation by excluding 32-bit parts and setting 64-bit executables in preferences
set TARGET=%TARGET_DIR%\wudsn-ide-win64.zip
set EXCLUDED_FILES=-x@%TOOLS%\WWW\build-exclude-win64.txt
%WWW%\fart.exe %PREFS_FILE% Altirra.exe Altirra64.exe
%WWW%\fart.exe %PREFS_FILE% Stella\\32-bit Stella\\64-bit
%WWW%\fart.exe %PREFS_FILE% WinVICE\\x86 WinVICE\\x64
call :PackOne
goto :eof

:PackOne
echo Packing %TARGET%
if exist %TARGET% del %TARGET%
cd %TARGET_CD%
%WINRAR% a -r -afzip %EXCLUDED_FILES% %TARGET% *.*
if not exist %TARGET% (
  echo Operation cancelled for target %TARGET%.
  pause
  exit /b
)
goto :eof

:UploadAll
echo Press any key to upload file to the web site.
pause
call C:\jac\system\WWW\Sites\www.wudsn.com\productions\www\site\export\upload.bat java/ide/downloads
goto :eof
