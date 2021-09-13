@echo off

:start
acme %1 %2 %3 %4 %5 %6 %7 %8 %9
if NOT ERRORLEVEL 1 goto end
choice /c:er /n [E]nd or [R]epeat ?
if ERRORLEVEL 2 goto start

:end
