@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET VOL=3
SET DISC=2
SET TITLE=ゴジラくん
SET G=GODZILDS

REM ROM IMAGE: +5C000H size:8000H
REM (CLUSTER:363 / SECTOR:2E0H) 
REM     ;(CLU=SEC/2-5)...(2DD:CLU=SEC/2-(14-2*2)/2)
SET SADR=5C000
SET SIZE=8000

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

REM BODY: 4000H-44A3H SIZE:(4A4H)
REM +0 size:4A4
BINCUT2 -s 0 -l 4A4 -o %G%_HEAD.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 44A7H-BFFFH SIZE:(7B59H)
REM +4A7 size:7B59
BINCUT2 -s 4A7 -l 7B59 -o %G%_TAIL.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * 置き換え用バイナリデータを作成します。
REM ********************************

REM 44A4H: CALL 45B2H
ECHO CD B2 45 >%G%_PATCH.TXT
CERTUTIL -decodehex %G%_PATCH.TXT %G%_PATCH.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * バイナリデータを結合します。
REM ********************************

COPY /B %G%_HEAD.BIN+%G%_PATCH.BIN+%G%_TAIL.BIN %G%.ROM>nul
IF ERRORLEVEL 1 GOTO :err_end

IF "%NO_TRASH%"=="1" GOTO :no_trash
REM ********************************
ECHO * 作業ファイルを片付けます。
REM ********************************
DEL %G%_HEAD.BIN>nul
DEL %G%_PATCH.BIN>nul
DEL %G%_PATCH.TXT>nul
DEL %G%_TAIL.BIN>nul
DEL %G%_RAW.ROM>nul

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
