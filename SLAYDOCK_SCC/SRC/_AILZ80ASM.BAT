@set symname=%~n1.SYM
@set temp_sym=%~n1.org.SYM

@if "%2"=="" goto :simple
@if /i "%2"=="/f" goto :full
@goto :setbin

:full
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%temp_sym%" -equ "%~n1.EQU" -adr "%~n1.ADR" -lst "%~n1.LST" -err "%~n1.ERR" -gap 0
@call :modify_sym
@goto :exit

:setbin
AILZ80ASM "%1" -f -bin "%2" -sm minimal-equ -sym "%temp_sym%" -lst "%~n1.LST" -err "%~n1.ERR" -gap 0
@call :modify_sym
@goto :exit

:simple
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%temp_sym%" -lst "%~n1.LST" -err "%~n1.ERR" -gap 0
@call :modify_sym
@goto :exit

:modify_sym
@echo off
rem pause
set cnt=0
del /f "%symname%" > nul 2>&1
echo %symname% *** 1s–Ú‚ÌƒRƒƒ“ƒg‚ðÁ‚µ‚Ä‚¢‚Ü‚· ***
for /f "delims= skip=1" %%i in (%temp_sym%) do (
   if "%%i" == "" (
      rem echo.
      echo. >> "%symname%"
   ) else (
      rem echo %%i
      echo %%i >> "%symname%"
    )
)
rem del /f "%temp_sym%"

:exit