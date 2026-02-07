@ECHO OFF

SET BASE=bootsec
SET DSKFILE=..\extFdd_fix.dsk
SET DSKPART=disk_part.bin

ECHO ********************************************************************
ECHO.
ECHO ** "%DSKFILE%" を作成 します
ECHO.
ECHO    bincut2.exe     ... バイナリーカッター
ECHO      https://nezplug.sourceforge.net/
ECHO      https://www.purose.net/befis/download/nezplug/oldsite.shtml
ECHO.
ECHO    AILZ80ASM.exe   ... Z80アセンブラ―
ECHO      https://github.com/AILight/AILZ80ASM
ECHO.
ECHO ********************************************************************

SET ER=0
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :CHECK_OK
GOTO :err_end

REM ************************************************
REM  Display Error
REM ************************************************

:NO_BINCUT2
SET ER=1
ECHO [ERROR] bincut2.exe がありません。
GOTO :EXIT_B

:NO_ASM
SET ER=1
ECHO [ERROR] AILZ80ASM.exe がありません。
GOTO :err_end

REM ************************************************
:check_ok

REM ************************************************
REM アセンブル
REM ************************************************
:exec_assemble
ECHO * "%BASE%.asm" をアセンブルします。
IF NOT EXIST AILZ80ASM.exe GOTO :no_asm
AILZ80ASM %BASE%.asm -f -bin "%BASE%.bin" -sm minimal-equ -sym "%BASE%.sym" -lst "%BASE%.lst" -err "%BASE%.err" -gap 0
REM AILZ80ASM %BASE%.asm -f -bin "%BASE%.bin" -gap 0
IF ERRORLEVEL 1 GOTO :err_end

REM ************************************************
ECHO * ディスクイメージのブートセクタ以降を切り出します
REM ************************************************

REM *** ディスクイメージの0x100以降を切り出す
BINCUT2 -s 100 -l B3F00 -o "%DSKPART%" "%DSKFILE%"
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * バイナリデータを結合します。
REM ********************************
COPY /B %BASE%.bin+%BASE%.drv+%DSKPART% "%DSKFILE%">nul

REM ********************************
ECHO * 作業ファイルを片付けます。
REM ********************************
DEL %DSKPART%>nul

REM ********************************
ECHO * 終了ました。
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
