@echo off

if not defined DevEnvDir (       
  call "%ProgramFiles%\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x86_x64
)

rem ==== Eliminación segura de archivos previos ====
if exist demo.exe del demo.exe
if exist demo.exp del demo.exp
if exist demo.lib del demo.lib
rem ===============================================

c:\harbour\bin\hbmk2 demo.hbp -comp=msvc64

IF ERRORLEVEL 1 GOTO COMPILEERROR


@cls
demo.exe

GOTO EXIT

:COMPILEERROR

echo *** Error 

pause

:EXIT