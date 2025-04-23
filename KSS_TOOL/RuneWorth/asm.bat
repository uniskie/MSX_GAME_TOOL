@ECHO OFF
SET SYMNAME=%~n1.SYM
SET TEMP_SYM=%~n1.ORG.SYM
SET DEF_OPT=--gap-default 0 --no-super-asm --define-label _AILZ80ASM_

REM ローカルラベルの最後に:がある時の警告を非表示
SET DEF_OPT=%DEF_OPT% --disable-warning W9005

SET ERRCHK=0
SET MODE=SIMPLE

:CHECK_OPTION
IF /I "%1"=="/P" (
  SHIFT /1
  SET ERCHK=1
  GOTO :CHECK_OPTION
)
IF /I "%1"=="/S" (
  SHIFT /1
  SET MODE=SIMPLE
  GOTO :CHECK_OPTION
)
IF /I "%1"=="/F" (
  SHIFT /1
  SET MODE=FULL
  GOTO :CHECK_OPTION
)
IF /I "%2"=="/P" SET ERRCHK=1
IF /I "%3"=="/P" SET ERRCHK=1
IF /I "%2"=="/S" SET MODE=SIMPLE
IF /I "%3"=="/S" SET MODE=SIMPLE
IF /I "%2"=="/F" SET MODE=FULL
IF /I "%3"=="/F" SET MODE=FULL

:FULL
@ECHO ON
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -equ "%~n1.EQU" -adr "%~n1.ADR" -lst "%~n1.LST" -err "%~n1.ERR" %DEF_OPT%
@ECHO OFF
GOTO :CHECK

:SIMPLE
@ECHO ON
AILZ80ASM "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -lst "%~n1.LST" -err "%~n1.ERR" %DEF_OPT%
@ECHO OFF

:CHECK
IF ERRORLEVEL 1 GOTO ERR

:MODIFY_SYM
REM PAUSE
SET CNT=0
DEL /F "%SYMNAME%" > NUL 2>&1
ECHO %SYMNAME% *** 1行目のコメントを消しています ***
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

EXIT /B

:ERR
IF NOT "%ERCHK%"=="1" GOTO ERREND
PAUSE

:ERREND
EXIT /B %ERRORLEVEL%
