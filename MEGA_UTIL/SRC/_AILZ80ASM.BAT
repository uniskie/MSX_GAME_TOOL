@SET SYMNAME=%~n1.SYM
@SET TEMP_SYM=%~n1.ORG.SYM
SET ERRCHK=0

@IF /I "%2"=="/P" SET ERRCHK=1
@IF /I "%3"=="/P" SET ERRCHK=1
@IF /I "%2"=="/S" GOTO :SIMPLE
@IF /I "%3"=="/S" GOTO :SIMPLE
@IF /I "%2"=="/F" GOTO :FULL
@IF /I "%3"=="/F" GOTO :FULL
@GOTO :SETBIN

:FULL
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -equ "%~n1.EQU" -adr "%~n1.ADR" -lst "%~n1.LST" -err "%~n1.ERR" -gap 0
@GOTO :CHECK

:SETBIN
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -lst "%~n1.LST" -err "%~n1.ERR" -gap 0
@GOTO :CHECK

:SIMPLE
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -lst "%~n1.LST" -err "%~n1.ERR" -gap 0

:CHECK
@IF ERRORLEVEL 1 GOTO ERR

:MODIFY_SYM
@ECHO OFF
REM PAUSE
SET CNT=0
DEL /F "%SYMNAME%" > NUL 2>&1
ECHO %SYMNAME% *** 1s–Ú‚ÌƒRƒƒ“ƒg‚ðÁ‚µ‚Ä‚¢‚Ü‚· ***
FOR /F "DELIMS= SKIP=1" %%I IN (%TEMP_SYM%) DO (
   IF "%%I" == "" (
      REM ECHO.
      ECHO. >> "%SYMNAME%"
   ) ELSE (
      REM ECHO %%I
      ECHO %%I >> "%SYMNAME%"
    )
)
REM DEL /F "%TEMP_SYM%"

@EXIT /B

:ERR
@IF NOT "%ERCHK%"=="1" GOTO ERREND
@PAUSE

:ERREND
@EXIT /B %ERRORLEVEL%
