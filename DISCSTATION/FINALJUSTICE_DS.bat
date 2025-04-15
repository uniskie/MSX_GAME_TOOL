@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET G=FINALJUD
SET SRC=DS#8-1.DSK
SET ROMFILE=%G%.ROM

ECHO ***** FINAL JUSTICE DISC STATION #8 ver ****************************
ECHO.
ECHO ** "%SRC%"����"%ROMFILE%" ���쐬 ���܂�
ECHO.
ECHO �����F
ECHO    %SRC% ... DISC STATION 8 DISK1 IMAGE
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

REM ROM IMAGE: +60000 size:4000H
REM (CLUSTER:386 / SECTOR:300H) (CLU=SEC/2+2)
BINCUT2 -s 60000 -l 4000 -o %G%_RAW.ROM %SRC%
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 402H-4FFFH SIZE:(4000H-2)
REM +24 size:3FFE
BINCUT2 -s 2 -l 3FFFE -o %G%_BODY.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * �u�������p�o�C�i���f�[�^���쐬���܂��B
REM ********************************

ECHO 41 42 >%G%_HEAD.TXT
CERTUTIL -decodehex %G%_HEAD.TXT %G%_HEAD.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * �o�C�i���f�[�^���������܂��B
REM ********************************

COPY /B %G%_HEAD.BIN+%G%_BODY.BIN %G%.ROM>nul
IF ERRORLEVEL 1 GOTO :err_end

IF "%NO_TRASH%"=="1" GOTO :no_trash
REM ********************************
ECHO * ��ƃt�@�C����Еt���܂��B
REM ********************************
DEL %G%_HEAD.BIN>nul
DEL %G%_HEAD.TXT>nul
DEL %G%_BODY.BIN>nul
DEL %G%_RAW.ROM>nul

:no_trash

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
