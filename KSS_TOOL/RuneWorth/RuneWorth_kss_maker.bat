@ECHO OFF

set BAT=%0
:arg_loop
IF "%1"=="" GOTO :arg_end
IF "%1"=="/f" SET FORCE_ASM=1
IF "%1"=="/F" SET FORCE_ASM=1
IF "%1"=="/r" SET NO_TRASH=1
IF "%1"=="/R" SET NO_TRASH=1
SHIFT
GOTO :arg_loop
:arg_end

SET W=RuneWorth
SET KSSFILE=Rune Worth (MSX).kss
SET KSSPLAYER=RuneWorth_kss_head

ECHO ***** for Rune Worth (MSX2) ****************************************
ECHO.
ECHO ** "%KSSFILE%" を作成 します
ECHO.
ECHO 準備：
ECHO    RuneWorth_S.dsk ... スタートディスク ディスクイメージ
ECHO    RuneWorth_A.dsk ... ゲームディスク A ディスクイメージ
ECHO    RuneWorth_B.dsk ... ゲームディスク B ディスクイメージ
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
IF NOT EXIST RuneWorth_S.dsk call :no_disk_s
IF NOT EXIST RuneWorth_A.dsk call :no_disk_a
IF NOT EXIST RuneWorth_B.dsk call :no_disk_b
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :CHECK_OK
GOTO :err_end

REM ************************************************
REM  Display Error
REM ************************************************
:NO_DISK_S
SET ER=1
ECHO [ERROR] RuneWorth_S.dsk ... スタートディスク ディスクイメージ がありません。
GOTO :EXIT_B

:NO_DISK_A
SET ER=1
ECHO [ERROR] RuneWorth_A.dsk ... ゲームディスク A ディスクイメージ がありません。
GOTO :EXIT_B

:NO_DISK_B
SET ER=1
ECHO [ERROR] RuneWorth_B.dsk ... ゲームディスク B ディスクイメージ がありません。
GOTO :EXIT_B

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
REM KSSヘッダ（コールエントリ）のアセンブル
REM ************************************************
IF "%FORCE_ASM%"=="1" GOTO :exec_assemble
IF EXIST "%KSSPLAYER%.bin" GOTO skip_asm_player

:exec_assemble
ECHO * "%KSSPLAYER%.bin" をアセンブルします。
IF NOT EXIST AILZ80ASM.exe GOTO :no_asm
AILZ80ASM %KSSPLAYER%.asm -f -bin "%KSSPLAYER%.bin" -sm minimal-equ -sym "%KSSPLAYER%.sym" -lst "%KSSPLAYER%.lst" -err "%KSSPLAYER%.err" -gap 0
REM AILZ80ASM %KSSPLAYER%.asm -f -bin "%KSSPLAYER%.bin" -gap 0
IF ERRORLEVEL 1 GOTO :err_end

:skip_asm_player

REM ************************************************
ECHO * バイナリデータを切り出します。
REM ************************************************

REM *** MUSICDRV (RAM:0100-1FFF)
REM +6E00 size:1E00
BINCUT2 -s 06E00 -l 01E00 -o %W%.DRV RuneWorth_S.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** OPLLDRV (RAM:0100-11FF)
REM +6E00 size:1100
BINCUT2 -s 06E00 -l 01100 -o %W%.OPL RuneWorth_S.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** PSGDRV (RAM:0100-11FF)
REM +7EBD size:1100
BINCUT2 -s 07EBD -l 01100 -o %W%.PSG RuneWorth_S.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** OPENNING MUSIC
REM SECTOR 46-51
REM +8C00-A3FF size:01800
BINCUT2 -s 08C00 -l 01800 -o %W%_OP.MUS RuneWorth_S.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** ENDING MUSIC
REM SECTOR 110-11C
REM +22000-237FF size:01800
BINCUT2 -s 22000 -l 01800 -o %W%_ED.MUS RuneWorth_S.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** COMMON MUSIC (GAME DISK A/B)
REM SECTOR 1DC-213
REM +3B800-427FF size:07000
BINCUT2 -s 3B800 -l 07000 -o %W%_C.MUS RuneWorth_A.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** COMMON MUSIC 2 (GAME DISK A/B) #宝箱 #危険がアブナイ
REM SECTOR 2-4
REM +00400-00800 size:0400
BINCUT2 -s 00400 -l 00400 -o %W%_C2.MUS RuneWorth_A.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** GAME DISK A ONLY MUSIC
REM SECTOR 2AD-2CD
REM +55A00-59BFF size:04200
BINCUT2 -s 55A00 -l 04200 -o %W%_A.MUS RuneWorth_A.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM *** GAME DISK B ONLY MUSIC
REM SECTOR 265-28F
REM +4CA00-51FFF size:05600
BINCUT2 -s 4CA00 -l 05600 -o %W%_B.MUS RuneWorth_B.DSK
IF ERRORLEVEL 1 GOTO :err_end

REM ********************************
ECHO * バイナリデータを結合します。
REM ********************************
REM COPY /B %KSSPLAYER%.BIN+%W%.OPL+%W%.PSG+%W%_OP.MUS+%W%_C.MUS+%W%_C2.MUS+%W%_A.MUS+%W%_B.MUS+%W%_ED.MUS "%KSSFILE%">nul
COPY /B %KSSPLAYER%.BIN+%W%.DRV+%W%_OP.MUS+%W%_C.MUS+%W%_C2.MUS+%W%_A.MUS+%W%_B.MUS+%W%_ED.MUS "%KSSFILE%">nul

IF "%NO_TRASH%"=="1" GOTO :no_trash
REM ********************************
ECHO * 作業ファイルを片付けます。
REM ********************************
DEL %W%.PSG>nul
DEL %W%.OPL>nul
DEL %W%_OP.MUS>nul
DEL %W%_ED.MUS>nul
DEL %W%_C.MUS>nul
DEL %W%_C2.MUS>nul
DEL %W%_A.MUS>nul
DEL %W%_B.MUS>nul
:no_trash

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
