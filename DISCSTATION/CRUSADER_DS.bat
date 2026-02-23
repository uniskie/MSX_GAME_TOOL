@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET VOL=10
SET DISC=1
SET TITLE=CRUSADER
SET G=CRUSADDS

REM ROM IMAGE: +74000H size:8000H
REM (CLUSTER:459 / SECTOR:3A0H)
REM     (CLU=SEC/2-5)...(2DD:CLU=SEC/2-(14-2*2)/2)
SET SADR=74000
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

REM BOOT CODE: 4000H-4007H SIZE=8H 
REM +0000 size:8
BINCUT2 -s 0 -l 8 -o %G%_BOOT.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM ** NO_BUGFIX **
REM REM BODY: 400BH-BFFFH SIZE:(8000H-BH)
REM REM +B size:7FF5
REM BINCUT2 -s B -l 7FF5 -o %G%_BODY.BIN %G%_RAW.ROM
REM IF ERRORLEVEL 1 GOTO :err_end

REM ** BUGFIX:MSX2以降で起動しない事がある問題の修正 **
REM BODY: 400BH-4814H SIZE:80AH
REM +B size:80A
BINCUT2 -s B -l 80A -o %G%_FIX0.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 4815H-4822H SIZE:0EH
REM +815 size:E
REM POP IX ;4815: DD E1
REM POP HL ;4822: E1
BINCUT2 -s 815 -l E -o %G%_FIX1.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 4823H-4825H SIZE:03H
REM +823 size:3
REM CALL 433EH ;4823: CD 3E 43 ; この先でレジスタ破壊
BINCUT2 -s 823 -l 3 -o %G%_FIX2.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM BODY: 4826H-BFFFH SIZE:77DAH
REM +826 size:77DA
BINCUT2 -s 826 -l 77DA -o %G%_FIX3.BIN %G%_RAW.ROM
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * 置き換え用バイナリデータを作成します。
REM ********************************

ECHO CD 3E 41 >%G%_PATCH.TXT
CERTUTIL -decodehex %G%_PATCH.TXT %G%_PATCH.BIN>nul
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * バイナリデータを結合します。
REM ********************************

REM ** NO_BUGFIX **
REM COPY /B %G%_BOOT.BIN+%G%_PATCH.BIN+%G%_BODY.BIN %G%.ROM>nul
REM IF ERRORLEVEL 1 GOTO :err_end

REM ** BUGFIX **
COPY /B %G%_BOOT.BIN+%G%_PATCH.BIN+%G%_FIX0.BIN+%G%_FIX2.BIN+%G%_FIX1.BIN+%G%_FIX3.BIN %G%.ROM>nul
IF ERRORLEVEL 1 GOTO :err_end

IF "%NO_TRASH%"=="1" GOTO :no_trash
REM ********************************
ECHO * 作業ファイルを片付けます。
REM ********************************
DEL %G%_PATCH.BIN>nul
DEL %G%_PATCH.TXT>nul
DEL %G%_BOOT.BIN>nul
DEL %G%_RAW.ROM>nul
REM ** NO_BUGFIX **
REM DEL %G%_BODY.BIN>nul
REM ** BUGFIX **
DEL %G%_FIX0.BIN>nul
DEL %G%_FIX1.BIN>nul
DEL %G%_FIX2.BIN>nul
DEL %G%_FIX3.BIN>nul

:no_trash
ECHO.
ECHO 注） ** タイプは NORMAL4000H
ECHO         または Plain 32K page1-2 を指定してください **
ECHO      （openMSXのauto detectは正しく認識しません）
ECHO.

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
