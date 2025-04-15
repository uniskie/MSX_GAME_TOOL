@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET G=GULKAVED
SET SRC=DS#9-2.DSK
SET ROMFILE=%G%.ROM

ECHO ***** GULKAVE DISC STATION #9 ver ************************************
ECHO.
ECHO ** "%SRC%"����"%ROMFILE%" ���쐬 ���܂�
ECHO.
ECHO �����F
ECHO    %SRC% ... DISC STATION 9 DISK2 IMAGE
ECHO.
ECHO    bincut2.exe     ... �o�C�i���[�J�b�^�[
ECHO      https://nezplug.sourceforge.net/
ECHO      https://www.purose.net/befis/download/nezplug/oldsite.shtml
ECHO.
ECHO ********************************************************************

SET ER=0
IF NOT EXIST %SRC% call :no_SRC
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :CHECK_OK
GOTO :err_end

REM ************************************************
REM  Display Error
REM ************************************************
:NO_SRC
SET ER=1
ECHO [ERROR] %SRC% ������܂���B
GOTO :EXIT_B

:NO_BINCUT2
SET ER=1
ECHO [ERROR] bincut2.exe ������܂���B
GOTO :EXIT_B

REM ************************************************
:check_ok

REM ************************************************
ECHO * �o�C�i���f�[�^��؂�o���܂��B
REM ************************************************

REM GULKAVE.OBJ
REM ROM IMAGE: +9800H size:8000H
REM (CLUSTER:610 / SECTOR:4C0H) (CLU=SEC/2+1)
BINCUT2 -s 98000 -l 8000 -o %G%.ROM %SRC%
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * �I�����܂����B
REM ********************************
:WAIT
PAUSE
GOTO :EXIT_B

:err_end
REM ********************************
ECHO *** �����𒆒f���܂��B
REM ********************************
GOTO :WAIT

:EXIT_B
