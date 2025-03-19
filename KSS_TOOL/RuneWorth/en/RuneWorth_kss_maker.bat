@ECHO OFF

IF "%1"=="/f" SET FORCE_ASM=1
IF "%1"=="/F" SET FORCE_ASM=1

SET KSSFILE=Rune Worth (MSX).kss
SET KSSPLAYER=RuneWorth_kss_head

ECHO ***** for Rune Worth (MSX2) ****************************************
ECHO.
ECHO ** make the "%KSSFILE%" 
ECHO.
ECHO Required:
ECHO    RuneWorth_S.dsk ... Start Disk disk-image
ECHO    RuneWorth_A.dsk ... Game Disk A disk-image
ECHO    RuneWorth_B.dsk ... Game Disk B disk-image
ECHO.
ECHO    bincut2.exe     ... Binary Cutter
ECHO      https://nezplug.sourceforge.net/
ECHO      https://www.purose.net/befis/download/nezplug/oldsite.shtml
ECHO.
ECHO    AILZ80ASM.exe   ... Z80 Assembler
ECHO      https://github.com/AILight/AILZ80ASM
ECHO.
ECHO ********************************************************************

SET ER=0
IF NOT EXIST RuneWorth_S.dsk call :no_disk_s
IF NOT EXIST RuneWorth_A.dsk call :no_disk_a
IF NOT EXIST RuneWorth_B.dsk call :no_disk_b
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :CHECK_OK
ECHO *** Aborted.
GOTO :WAIT

REM ************************************************
REM  Display Error
REM ************************************************
:NO_DISK_S
SET ER=1
ECHO [ERROR] RuneWorth_S.dsk ... Start Disk disk-image is not found.
GOTO :EXIT_B

:NO_DISK_A
SET ER=1
ECHO [ERROR] RuneWorth_A.dsk ... Game Disk A disk-image is not found.
GOTO :EXIT_B

:NO_DISK_B
SET ER=1
ECHO [ERROR] RuneWorth_B.dsk ... Game Disk B disk-image is not found.
GOTO :EXIT_B

:NO_BINCUT2
SET ER=1
ECHO [ERROR] bincut2.exe is not found.
GOTO :EXIT_B

:NO_ASM
SET ER=1
ECHO [ERROR] AILZ80ASM.exe is not found.
ECHO *** Aborted.
GOTO :WAIT

REM ************************************************
:check_ok

REM ************************************************
REM Assemble the KSS header. (driver controller)
REM ************************************************
IF "%FORCE_ASM%"=="1" GOTO :exec_assemble
IF EXIST "%KSSPLAYER%.bin" GOTO skip_asm_player

:exec_assemble
ECHO * Assembling "%KSSPLAYER%.bin".
IF NOT EXIST AILZ80ASM.exe GOTO :no_asm
REM AILZ80ASM %KSSPLAYER%.asm -f -bin "%KSSPLAYER%.bin" -sm minimal-equ -sym "%KSSPLAYER%.sym" -lst "%KSSPLAYER%.lst" -err "%KSSPLAYER%.err" -gap 0
AILZ80ASM %KSSPLAYER%.asm -f -bin "%KSSPLAYER%.bin" -gap 0
IF ERRORLEVEL 1 GOTO :exit_b

:skip_asm_player

REM ************************************************
ECHO * Extracts binary data.
REM ************************************************

REM *** OPLLDRV (RAM:0100-1EFF)
REM +6E00 size:1E00
BINCUT2 -s 06E00 -l 01E00 -o RuneWorth.OPL RuneWorth_S.DSK

REM *** PSGDRV (RAM:0100-1EFF)
REM +7EBD size:1E00
BINCUT2 -s 07EBD -l 01E00 -o RuneWorth.PSG RuneWorth_S.DSK

REM *** OPENNING MUSIC (SYSTEM DISK)
REM SECTOR 46-51
REM +8C00-A3FF size:01800
BINCUT2 -s 08C00 -l 01800 -o RuneWorth_OP.MUS RuneWorth_S.DSK

REM *** ENDING MUSIC (SYSTEM DISK)
REM SECTOR 110-11C
REM +22000-237FF size:01800
BINCUT2 -s 22000 -l 01800 -o RuneWorth_ED.MUS RuneWorth_S.DSK

REM *** COMMON MUSIC (GAME DISK A/B)
REM SECTOR 1DC-213
REM +3B800-427FF size:07000
BINCUT2 -s 3B800 -l 07000 -o RuneWorth_C.MUS RuneWorth_A.DSK

REM *** COMMON MUSIC 2 (GAME DISK A/B) #tresurebox #Look out, it's Dangerous
REM SECTOR 2-4
REM +00400-00800 size:0400
BINCUT2 -s 00400 -l 00400 -o RuneWorth_C2.MUS RuneWorth_A.DSK

REM *** GAME DISK A ONLY MUSIC
REM SECTOR 2AD-2CD
REM +55A00-59BFF size:04200
BINCUT2 -s 55A00 -l 04200 -o RuneWorth_A.MUS RuneWorth_A.DSK

REM *** GAME DISK B ONLY MUSIC
REM SECTOR 265-28F
REM +4CA00-51FFF size:05600
BINCUT2 -s 4CA00 -l 05600 -o RuneWorth_B.MUS RuneWorth_B.DSK

REM ********************************
ECHO * Combine binary data.
REM ********************************
COPY /B %KSSPLAYER%.BIN+RuneWorth.OPL+RuneWorth.PSG+RuneWorth_OP.MUS+RuneWorth_C.MUS+RuneWorth_C2.MUS+RuneWorth_A.MUS+RuneWorth_B.MUS+RuneWorth_ED.MUS "%KSSFILE%">nul

REM ********************************
ECHO * Clean up working files.
REM ********************************
DEL RuneWorth.PSG>nul
DEL RuneWorth.OPL>nul
DEL RuneWorth_OP.MUS>nul
DEL RuneWorth_ED.MUS>nul
DEL RuneWorth_C.MUS>nul
DEL RuneWorth_C2.MUS>nul
DEL RuneWorth_A.MUS>nul
DEL RuneWorth_B.MUS>nul

REM ********************************
ECHO * Finished.
REM ********************************
:WAIT
PAUSE
GOTO :EXIT_B


:EXIT_B
