@ECHO OFF
ECHO *****************************************************
ECHO ** Assemble tools for
ECHO **         MAZE of GARIOUS, PARODIUS, HYDLIDE III.
ECHO *****************************************************
IF EXIST "TNIASM.EXE" GOTO EXECASM
ECHO ** You need 'tniASM' to assemble programs.
ECHO **
ECHO ** Download 'tniASM' from here.
ECHO **
ECHO **          http://www.tni.nl/products/tniasm.html
ECHO ** (同じフォルダに置くかパスを通してください)
ECHO *****************************************************
PAUSE
:EXECASM
CALL :ASM GARSTART.ASM
CALL :ASM HYD3STRT.ASM
CALL :ASM HYD3-EXP.ASM
CALL :ASM PARODIUS.ASM
CALL :ASM GAR-MUS.ASM
CALL :ASM PARO-MUS.ASM
ECHO *** BOF FILES ***
DIR *.BOF /B
IF NOT ERRORLEVEL 1 GOTO END
PAUSE
:END
EXIT /B

REM **********************************************
:ASM
ECHO **** MAKE "%~n1.BOF" ****
IF EXIST "%~n1.BOF" (
	IF EXIST "%~n1.BOF.OLD" DEL "%~n1.BOF.OLD"
	ECHO REN "%~n1.BOF" "%~n1.BOF.OLD"
	REN "%~n1.BOF" "%~n1.BOF.OLD"
)
CALL ASM /P %1
ECHO.
EXIT/B
