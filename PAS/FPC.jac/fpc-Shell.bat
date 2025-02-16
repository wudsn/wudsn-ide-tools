@echo off
setlocal
cd /D "%~dp0"

call fpc.bat "%1" SHELL
