@REM ECHO OFF
ECHO *****************************************************
ECHO * Assemble tools for ...
ECHO * MAZE of GARIOUS, F1SPIRIT, PARODIUS, HYDLIDE III.
ECHO * KONAMI MSX1 GENERIC
ECHO *****************************************************
WHERE /Q TNIASM.exe
IF ERRORLEVEL 1 GOTO :EXE_NOT_FOUND

SET ERRORS=0

if /i "%1"=="c" GOTO :COPY
if /i "%1"=="/c" GOTO :COPY

:EXECASM
CALL :ASM TFROM.ASM
CALL :ASM HYDLIDE3.ASM
CALL :ASM HYD3-EXP.ASM
CALL :ASM GALIOUS.ASM
CALL :ASM GAL-MUS.ASM
CALL :ASM PARODIUS.ASM
CALL :ASM PARO-MUS.ASM
CALL :ASM F1SPIRIT.ASM
CALL :ASM F1SP-MUS.ASM
CALL :ASM KONAMI.ASM

IF "%ERRORS%"=="1" GOTO :END

:COPY
ECHO *** REFRESH FILES ***
DEL /S tniasm.lst > NUL 2>&1
DEL /S *.LST > NUL 2>&1
DEL /S *.ERR > NUL 2>&1
DEL /S *.EQU > NUL 2>&1
DEL /S *.ADR > NUL 2>&1
DEL /S *.ORG.SYM > NUL 2>&1

CHOICE /M "COPY to FILES folder?" /C YN
IF /I NOT "%ERRORLEVEL%"=="1" GOTO :END


ECHO *** COPY FILES ***
COPY /Y *.BAS ..\FILES\*.*
COPY /Y *.BIN ..\FILES\*.*

:END
PAUSE
EXIT/B

REM **********************************************
:ASM
ECHO **** MAKE "%~n1.BIN" ****
GOTO :SKIP_OLD_BACKUP
IF EXIST "%~n1.BIN" (
	IF EXIST "%~n1.BIN.OLD" DEL "%~n1.BIN.OLD"
	ECHO REN "%~n1.BIN" "%~n1.BIN.OLD"
	REN "%~n1.BIN" "%~n1.BIN.OLD"
)
:SKIP_OLD_BACKUP
CALL ASM /P /S %1
ECHO.
IF ERRORLEVEL 1 GOTO :ERR
IF NOT EXIST "%~n1.BIN" GOTO :ERR
EXIT/B

:EXE_NOT_FOUND
ECHO.
ECHO [ERROR] You need 'tniASM' to assemble programs.
ECHO.
ECHO *****************************************************
ECHO * Download 'tniASM' from here.
ECHO *          http://www.tni.nl/products/tniasm.html
ECHO * (同じフォルダに置くかパスを通してください)
ECHO *****************************************************

:ERR
REM PAUSE
SET ERRORS=1
EXIT/B
