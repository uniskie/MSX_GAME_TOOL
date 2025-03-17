@ECHO off

IF "%1"=="/f" SET FORCE_ASM=1
IF "%1"=="/F" SET FORCE_ASM=1

SET KSSFILE=Rune Worth (MSX).kss
SET KSSPLAYER=RuneWorth_kss_head

ECHO ***** for Rune Worth (MSX2) ****************************************
ECHO.
ECHO ** "%KSSFILE%" ���쐬 ���܂�
ECHO.
ECHO �����F
ECHO    RuneWorth_S.dsk ... �V�X�e���f�B�X�N �f�B�X�N�C���[�W
ECHO    RuneWorth_A.dsk ... �Q�[���f�B�X�N A �f�B�X�N�C���[�W
ECHO    RuneWorth_B.dsk ... �Q�[���f�B�X�N B �f�B�X�N�C���[�W
ECHO.
ECHO    bincut2.exe     ... �o�C�i���J�b�^�[
ECHO      https://nezplug.sourceforge.net/
ECHO      https://www.purose.net/befis/download/nezplug/oldsite.shtml
ECHO.
ECHO    AILZ80ASM.exe   ... Z80�A�Z���u���\
ECHO      https://github.com/AILight/AILZ80ASM
ECHO.
ECHO ********************************************************************

SET ER=0
IF NOT EXIST RuneWorth_S.dsk call :no_disk_s
IF NOT EXIST RuneWorth_A.dsk call :no_disk_a
IF NOT EXIST RuneWorth_B.dsk call :no_disk_b
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :check_ok
ECHO *** �����𒆒f���܂��B
GOTO :wait

REM ************************************************
REM  Display ERROR
REM ************************************************
:no_disk_s
SET ER=1
ECHO [ERROR] RuneWorth_S.dsk ... �V�X�e���f�B�X�N �f�B�X�N�C���[�W������܂���B
GOTO :exit_b

:no_disk_a
SET ER=1
ECHO [ERROR] RuneWorth_A.dsk ... �Q�[���f�B�X�N A �f�B�X�N�C���[�W������܂���B
GOTO :exit_b

:no_disk_b
SET ER=1
ECHO [ERROR] RuneWorth_B.dsk ... �Q�[���f�B�X�N B �f�B�X�N�C���[�W������܂���B
GOTO :exit_b

:no_bincut2
SET ER=1
ECHO [ERROR] bincut2.exe ������܂���B
GOTO :exit_b

:no_asm
SET ER=1
ECHO [ERROR] AILZ80ASM.exe ������܂���B
ECHO *** �����𒆒f���܂��B
GOTO :wait

REM ************************************************
:check_ok

REM ************************************************
REM KSS�h���C�o�R���g���[���̃A�Z���u��
REM ************************************************
IF "%FORCE_ASM%"=="1" GOTO :exec_assemble
IF EXIST "%KSSPLAYER%.bin" GOTO skip_asm_player

:exec_assemble
ECHO * "%KSSPLAYER%.bin" ���A�Z���u�����܂��B
IF NOT EXIST AILZ80ASM.exe GOTO :no_asm
REM AILZ80ASM %KSSPLAYER%.asm -f -bin "%KSSPLAYER%.bin" -sm minimal-equ -sym "%KSSPLAYER%.sym" -lst "%KSSPLAYER%.lst" -err "%KSSPLAYER%.err" -gap 0
AILZ80ASM %KSSPLAYER%.asm -f -bin "%KSSPLAYER%.bin" -gap 0
IF ERRORLEVEL 1 GOTO :exit_b

:skip_asm_player

REM ************************************************
ECHO * �o�C�i���f�[�^��؂�o���܂��B
REM ************************************************

REM *** oplldrv4 (RAM:0100-1EFF)
REM +6E00 size:1E00
bincut2 -s 06e00 -l 01e00 -o RuneWorth.opl RuneWorth_S.DSK

REM *** psgdrv4 (RAM:0100-1EFF)
REM +7EBD size:1E00
bincut2 -s 07ebd -l 01e00 -o RuneWorth.psg RuneWorth_S.DSK

REM *** openning MUSIC
REM sector 46-51
REM +8C00-A3FF size:01800
bincut2 -s 08c00 -l 01800 -o RuneWorth_op.mus RuneWorth_S.DSK

REM *** ending MUSIC
REM sector 110-11C
REM +22000-237FF size:01800
bincut2 -s 22000 -l 01800 -o RuneWorth_ed.mus RuneWorth_S.DSK

REM *** common MUSIC (game disk A/B)
REM sector 1DC-213
REM +3B800-427FF size:07000
bincut2 -s 3b800 -l 07000 -o RuneWorth_c.mus RuneWorth_A.DSK

REM *** common MUSIC 2 (game disk A/B) #�� #�댯���A�u�i�C
REM sector 2-4
REM +00400-00800 size:0400
bincut2 -s 00400 -l 00400 -o RuneWorth_c2.mus RuneWorth_A.DSK

REM *** game disk A only MUSIC
REM sector 2AD-2CD
REM +55A00-59BFF size:04200
bincut2 -s 55a00 -l 04200 -o RuneWorth_a.mus RuneWorth_A.DSK

REM *** game disk B only MUSIC
REM sector 265-28F
REM +4CA00-51FFF size:05600
bincut2 -s 4ca00 -l 05600 -o RuneWorth_b.mus RuneWorth_B.DSK

REM ********************************
ECHO * �o�C�i���f�[�^���������܂��B
REM ********************************
copy /b %KSSPLAYER%.bin+RuneWorth.opl+RuneWorth.psg+RuneWorth_op.mus+RuneWorth_c.mus+RuneWorth_c2.mus+RuneWorth_a.mus+RuneWorth_b.mus+RuneWorth_ed.mus "%KSSFILE%"

REM ********************************
ECHO * ��ƃt�@�C����Еt���܂��B
REM ********************************
del RuneWorth.psg
del RuneWorth.opl
del RuneWorth_op.mus
del RuneWorth_ed.mus
del RuneWorth_c.mus
del RuneWorth_c2.mus
del RuneWorth_a.mus
del RuneWorth_b.mus

REM ********************************
ECHO * �I���܂����B
REM ********************************
:wait
PAUSE
GOTO :exit_b


:exit_b