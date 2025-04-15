@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET G=EI_DS
SET SRC=DS#15-1.DSK
SET ROMFILE=%G%.ROM

ECHO ***** E.I. DISC STATION #15 ver ************************************
ECHO.
ECHO ** "%SRC%"から"%ROMFILE%" を作成 します
ECHO.
ECHO 準備：
ECHO    %SRC% ... DISC STATION 15 DISK1 IMAGE
ECHO.
ECHO    bincut2.exe     ... バイナリーカッター
ECHO      https://nezplug.sourceforge.net/
ECHO      https://www.purose.net/befis/download/nezplug/oldsite.shtml
ECHO.
ECHO ********************************************************************

SET ER=0
IF NOT EXIST %SRC% call :NO_SRC
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :CHECK_OK
GOTO :err_end

REM ************************************************
REM  Display Error
REM ************************************************
:NO_SRC
SET ER=1
ECHO [ERROR] %SRC% がありません。
GOTO :EXIT_B

:NO_BINCUT2
SET ER=1
ECHO [ERROR] bincut2.exe がありません。
GOTO :EXIT_B

REM ************************************************
:check_ok

REM ************************************************
ECHO * バイナリデータを切り出します。
REM ************************************************

REM ROM IMAGE: +6C000H size:4000H
rem (CLUSTER:434 / SECTOR:360H) (CLU=SEC/2+1)
BINCUT2 -s 6C000 -l 4000 -o %G%_RAW.ROM %SRC%

REM BOOT CODE: 4000H-4023H SIZE=24H 
REM +0000 size:24
BINCUT2 -s 0 -l 24 -o %G%_BOOT.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 4024H-7FCFH SIZE:(3FD0H-24H)
REM +24 size:3FAC
BINCUT2 -s 24 -l 3FAC -o %G%_BODY.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * 追加用バイナリデータを作成します。
REM ********************************

ECHO 41 42 D0 7F 00 00 00 00 00 00 00 00 00 00 00 00>%G%_HEAD.TXT
ECHO 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00>>%G%_HEAD.TXT
ECHO 00 00 00 00 >>%G%_HEAD.TXT
CERTUTIL -decodehex %G%_HEAD.TXT %G%_HEAD.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end

ECHO FF FF FF FF FF FF FF FF FF FF FF FF>%G%_TAIL.TXT
CERTUTIL -decodehex %G%_TAIL.TXT %G%_TAIL.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end


REM ********************************
ECHO * バイナリデータを結合します。
REM ********************************

COPY /B %G%_HEAD.BIN+%G%_BODY.BIN+%G%_BOOT.BIN+%G%_TAIL.BIN %G%.ROM>nul
IF ERRORLEVEL 1 GOTO :err_end

IF "%NO_TRASH%"=="1" GOTO :no_trash
REM ********************************
ECHO * 作業ファイルを片付けます。
REM ********************************
DEL %G%_HEAD.BIN>nul
DEL %G%_HEAD.TXT>nul
DEL %G%_TAIL.BIN>nul
DEL %G%_TAIL.TXT>nul
DEL %G%_BOOT.BIN>nul
DEL %G%_BODY.BIN>nul
DEL %G%_RAW.ROM>nul
:no_trash

REM ********************************
ECHO * 終了しました。
REM ********************************
:WAIT
PAUSE
GOTO :EXIT_B

:err_end
REM ********************************
ECHO *** 処理を中断します。
REM ********************************
GOTO :WAIT

:EXIT_B
