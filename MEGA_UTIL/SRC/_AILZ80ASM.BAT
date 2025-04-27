@ECHO OFF

SET ASM=AILZ80ASM
SET ERRCHK=0
SET MODE=NORMAL

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

SET SYMNAME=%~n1.SYM
SET TEMP_SYM=%~n1.ORG.SYM
SET DEF_OPT=--gap-default 0
SET DEF_OPT=%DEF_OPT% -oh sym
SET DEF_OPT=%DEF_OPT% --define-label _AILZ80ASM_=0xBEEF
SET DEF_OPT=%DEF_OPT% --no-super-asm
SET DEF_OPT=%DEF_OPT% --disable-warning W9005
REM ローカルラベルの最後に:がある時の警告を非表示

IF "%MODE%"=="FULL" GOTO :FULL
IF "%MODE%"=="SIMPLE" GOTO :SIMPLE
GOTO :NORMAL

:FULL
@ECHO ON
REM %ASM% "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -equ "%~n1.EQU" -adr "%~n1.ADR" -lst "%~n1.LST" -err "%~n1.ERR" %DEF_OPT%
%ASM% "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%SYMNAME%" -equ "%~n1.EQU" -adr "%~n1.ADR" -lst "%~n1.LST" -err "%~n1.ERR" %DEF_OPT%
@ECHO OFF
GOTO :CHECK

:NORMAL
@ECHO ON
REM %ASM% "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" -lst "%~n1.LST" -err "%~n1.ERR" %DEF_OPT%
%ASM% "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%SYMNAME%" -lst "%~n1.LST" -err "%~n1.ERR" %DEF_OPT%
@ECHO OFF
GOTO :CHECK

:SIMPLE
@ECHO ON
REM %ASM% "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%TEMP_SYM%" %DEF_OPT%
%ASM% "%1" -f -bin "%~n1.BIN" -sm minimal-equ -sym "%SYMNAME%" %DEF_OPT%
@ECHO OFF
GOTO :CHECK


:CHECK
IF ERRORLEVEL 1 GOTO ERR

REM :MODIFY_SYM
REM REM PAUSE
REM SET CNT=0
REM DEL /F "%SYMNAME%" > NUL 2>&1
REM ECHO %SYMNAME% *** 1行目のコメントを消しています ***
REM FOR /F "DELIMS= SKIP=1" %%I IN (%TEMP_SYM%) DO (
REM    IF "%%I" == "" (
REM       REM ECHO.
REM       ECHO. >> "%SYMNAME%"
REM    ) ELSE (
REM       REM ECHO %%I
REM       ECHO %%I >> "%SYMNAME%"
REM     )
REM )
REM REM DEL /F "%TEMP_SYM%"

EXIT /B

:ERR
IF NOT "%ERCHK%"=="1" GOTO ERREND
ECHO エラーが発生しました。
PAUSE
PAUSE

:ERREND
EXIT /B %ERRORLEVEL%
