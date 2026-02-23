@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET VOL=4
SET DISC=2
SET TITLE=EGGY
SET G=EGGY_DS

REM ROM IMAGE: +A20000 size:4000H
REM (CLUSTER:643 / SECTOR:510H)
REM     ;(CLU=SEC/2-5)...(2DD:CLU=SEC/2-(14-2*2)/2)
SET SADR=A2000
SET SIZE=4000

IF "%DISC%"=="0" (
 SET SRC=DS#%VOL%.DSK
) ELSE (
 SET SRC=DS#%VOL%-%DISC%.DSK
)
SET ROMFILE=%G%.ROM

ECHO ********************************************************************
ECHO  %TITLE% ... Disc Station #%DISC% ver
ECHO.
ECHO ** "%SRC%"から"%ROMFILE%" を作成 します
ECHO.
ECHO 準備：
ECHO    %SRC% ... DISC STATION #%VOL% DISK %DISC% IMAGE
ECHO.
ECHO    bincut2.exe     ... バイナリーカッター
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

BINCUT2 -s %SADR% -l %SIZE% -o %G%_RAW.ROM %SRC%
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 4004H-7FEFH SIZE:(4000H-14H)
REM +4 size:3FEC
BINCUT2 -s 4 -l 3FEC -o %G%_BODY.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * 置き換え用バイナリデータを作成します。
REM ********************************

REM 4000H-4003H
ECHO 41 42 F0 7F >%G%_HEAD.TXT
CERTUTIL -decodehex %G%_HEAD.TXT %G%_HEAD.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end

REM 7F00H-7FFFH
ECHO F3 21 10 40 11 10 80 01 00 3F ED B0 C3 10 80 00 >%G%_TAIL.TXT
CERTUTIL -decodehex %G%_TAIL.TXT %G%_TAIL.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * バイナリデータを結合します。
REM ********************************

COPY /B %G%_HEAD.BIN+%G%_BODY.BIN+%G%_TAIL.BIN %G%.ROM>nul
IF ERRORLEVEL 1 GOTO :err_end

IF "%NO_TRASH%"=="1" GOTO :no_trash
REM ********************************
ECHO * 作業ファイルを片付けます。
REM ********************************
DEL %G%_HEAD.BIN>nul
DEL %G%_HEAD.TXT>nul
DEL %G%_TAIL.BIN>nul
DEL %G%_TAIL.TXT>nul
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
