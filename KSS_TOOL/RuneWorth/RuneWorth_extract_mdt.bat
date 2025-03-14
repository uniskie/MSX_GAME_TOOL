@ECHO off

REM ### 保存先フォルダ
set dir_f=RuneWorh_opll
set dir_p=RuneWorh_psg

ECHO *****************************************************************
ECHO **** Extcact mdt file.  (For Rune Worth MSX2 ver.)            ***
ECHO *****************************************************************
ECHO * 77曲*2個あるので、MSX-DOSのファイル数上限を超えるため、
ECHO * OPLL用とPSG用で保存先フォルダを分けます。
ECHO *

SET ER=0
IF NOT EXIST RuneWorth_S.dsk call :no_disk_s
IF NOT EXIST RuneWorth_A.dsk call :no_disk_a
IF NOT EXIST RuneWorth_B.dsk call :no_disk_b
IF NOT EXIST bincut2.exe call :no_bincut2

IF %ER%==0 GOTO :check_ok
ECHO *** 処理を中断します。
GOTO :wait

REM ************************************************
REM  Display ERROR
REM ************************************************
:no_disk_s
SET ER=1
ECHO [ERROR] RuneWorth_S.dsk ... システムディスク ディスクイメージがありません。
GOTO :exit_b

:no_disk_a
SET ER=1
ECHO [ERROR] RuneWorth_A.dsk ... ゲームディスク A ディスクイメージがありません。
GOTO :exit_b

:no_disk_b
SET ER=1
ECHO [ERROR] RuneWorth_B.dsk ... ゲームディスク B ディスクイメージがありません。
GOTO :exit_b

:no_bincut2
SET ER=1
ECHO [ERROR] bincut2.exe がありません。
GOTO :exit_b

REM ************************************************
:check_ok


REM ### 保存先フォルダ作成
IF not EXIST "%dir_f%" mkdir "%dir_f%"
IF not EXIST "%dir_p%" mkdir "%dir_p%"

REM ### 保存ファイル名
set fnm_f=rw-o
set fnm_p=rw-p

set dst_f=%dir_f%\%fnm_f%
set dst_p=%dir_p%\%fnm_p%

REM ### ファイルリスト保存先
set log_f=%dir_f%\list.txt
set log_p=%dir_p%\list.txt
IF EXIST "%log_f%" DEL /f "%log_f%"
IF EXIST "%log_p%" DEL /f "%log_p%"

ECHO *   OPLLファイルリスト: %log_f%
ECHO *   PSG ファイルリスト: %log_p%
ECHO *

:cutmdt
ECHO *****************************************************************
ECHO * mdtデータを切り出します。
ECHO *   OPLL用: %dir_f%
ECHO *   PSG 用: %dir_p%
ECHO *****************************************************************

REM [RuneWorth_kss_head.asm -> extract bat convert MACRO]
REM document.selection.Replace("\\s+$","",eeReplaceAll | eeFindReplaceRegExp,0);
REM document.selection.Replace("^.*\\s+db\\s+0x(\\w{2}),\\s*[01]\\s*;([ABS])\\s+(\\w+)\\s+\\#\\w+\\s+\\((\\d+)\\)\\s+\\[([FP])\\]\\s+(\\d+)(.+)","ECHO %fnm_\\5%-\\6.mdt\\t[\\5] \\6\\7>>\"%log_\\5%\\nbincut2 -s \\3 -l \\100 -o %dst_\\5%-\\6.mdt RuneWorth_\\2.DSK",eeReplaceAll | eeFindReplaceRegExp,0);
REM document.selection.Replace("^;(.+)","REM ;\\1\\n",eeReplaceAll | eeFindReplaceRegExp,0);

REM ;+08c00-0a400 (01800 bytes) START DISK OPENING MUSIC

ECHO %fnm_F%-01.mdt	[F] 01. サリスの滅亡>>"%log_F%
bincut2 -s 08c00 -l 0200 -o %dst_F%-01.mdt RuneWorth_S.DSK
ECHO %fnm_P%-01.mdt	[P] 01. サリスの滅亡>>"%log_P%
bincut2 -s 08e00 -l 0400 -o %dst_P%-01.mdt RuneWorth_S.DSK
ECHO %fnm_F%-02.mdt	[F] 02. ルーンワースのテーマ>>"%log_F%
bincut2 -s 09200 -l 0A00 -o %dst_F%-02.mdt RuneWorth_S.DSK
ECHO %fnm_P%-02.mdt	[P] 02. ルーンワースのテーマ>>"%log_P%
bincut2 -s 09C00 -l 0800 -o %dst_P%-02.mdt RuneWorth_S.DSK

REM ;+3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC

ECHO %fnm_F%-03.mdt	[F] 03. 旅立ち>>"%log_F%
bincut2 -s 3b800 -l 0200 -o %dst_F%-03.mdt RuneWorth_A.DSK
ECHO %fnm_P%-03.mdt	[P] 03. 旅立ち>>"%log_P%
bincut2 -s 3ba00 -l 0200 -o %dst_P%-03.mdt RuneWorth_A.DSK
ECHO %fnm_F%-14.mdt	[F] 14. 死んでしまった>>"%log_F%
bincut2 -s 3bc00 -l 0400 -o %dst_F%-14.mdt RuneWorth_A.DSK
ECHO %fnm_P%-14.mdt	[P] 14. 死んでしまった>>"%log_P%
bincut2 -s 3c000 -l 0400 -o %dst_P%-14.mdt RuneWorth_A.DSK
ECHO %fnm_F%-06.mdt	[F] 06. ウェイデニッツ公国>>"%log_F%
bincut2 -s 3c400 -l 0800 -o %dst_F%-06.mdt RuneWorth_A.DSK
ECHO %fnm_P%-06.mdt	[P] 06. ウェイデニッツ公国>>"%log_P%
bincut2 -s 3cc00 -l 0600 -o %dst_P%-06.mdt RuneWorth_A.DSK
ECHO %fnm_F%-12.mdt	[F] 12. もったいない>>"%log_F%
bincut2 -s 3d200 -l 0400 -o %dst_F%-12.mdt RuneWorth_A.DSK
ECHO %fnm_P%-12.mdt	[P] 12. もったいない>>"%log_P%
bincut2 -s 3d600 -l 0400 -o %dst_P%-12.mdt RuneWorth_A.DSK
ECHO %fnm_F%-11.mdt	[F] 11. 祈り>>"%log_F%
bincut2 -s 3da00 -l 0600 -o %dst_F%-11.mdt RuneWorth_A.DSK
ECHO %fnm_P%-11.mdt	[P] 11. 祈り>>"%log_P%
bincut2 -s 3e000 -l 0400 -o %dst_P%-11.mdt RuneWorth_A.DSK
ECHO %fnm_F%-13.mdt	[F] 13. 5時からの男のために>>"%log_F%
bincut2 -s 3e400 -l 0600 -o %dst_F%-13.mdt RuneWorth_A.DSK
ECHO %fnm_P%-13.mdt	[P] 13. 5時からの男のために>>"%log_P%
bincut2 -s 3ea00 -l 0400 -o %dst_P%-13.mdt RuneWorth_A.DSK
ECHO %fnm_F%-17.mdt	[F] 17. URE-P>>"%log_F%
bincut2 -s 3ee00 -l 0600 -o %dst_F%-17.mdt RuneWorth_A.DSK
ECHO %fnm_P%-17.mdt	[P] 17. URE-P>>"%log_P%
bincut2 -s 3f400 -l 0600 -o %dst_P%-17.mdt RuneWorth_A.DSK
ECHO %fnm_F%-15.mdt	[F] 15. KANA-P>>"%log_F%
bincut2 -s 3fa00 -l 0400 -o %dst_F%-15.mdt RuneWorth_A.DSK
ECHO %fnm_P%-15.mdt	[P] 15. KANA-P>>"%log_P%
bincut2 -s 3fe00 -l 0200 -o %dst_P%-15.mdt RuneWorth_A.DSK
ECHO %fnm_F%-36.mdt	[F] 36. * GAME OVER>>"%log_F%
bincut2 -s 40000 -l 0200 -o %dst_F%-36.mdt RuneWorth_A.DSK
ECHO %fnm_P%-36.mdt	[P] 36. * GAME OVER>>"%log_P%
bincut2 -s 40200 -l 0200 -o %dst_P%-36.mdt RuneWorth_A.DSK
ECHO %fnm_F%-16.mdt	[F] 16. もっと KANA-P>>"%log_F%
bincut2 -s 40400 -l 0200 -o %dst_F%-16.mdt RuneWorth_A.DSK
ECHO %fnm_P%-16.mdt	[P] 16. もっと KANA-P>>"%log_P%
bincut2 -s 40600 -l 0200 -o %dst_P%-16.mdt RuneWorth_A.DSK
ECHO %fnm_F%-19.mdt	[F] 19. うろわば！>>"%log_F%
bincut2 -s 40800 -l 0400 -o %dst_F%-19.mdt RuneWorth_A.DSK
ECHO %fnm_P%-19.mdt	[P] 19. うろわば！>>"%log_P%
bincut2 -s 40c00 -l 0400 -o %dst_P%-19.mdt RuneWorth_A.DSK
ECHO %fnm_F%-20.mdt	[F] 20. 神々のガミガミ>>"%log_F%
bincut2 -s 41000 -l 0400 -o %dst_F%-20.mdt RuneWorth_A.DSK
ECHO %fnm_P%-20.mdt	[P] 20. 神々のガミガミ>>"%log_P%
bincut2 -s 41400 -l 0400 -o %dst_P%-20.mdt RuneWorth_A.DSK
ECHO %fnm_F%-32.mdt	[F] 32. 限りなき戦い>>"%log_F%
bincut2 -s 41800 -l 0400 -o %dst_F%-32.mdt RuneWorth_A.DSK
ECHO %fnm_P%-32.mdt	[P] 32. 限りなき戦い>>"%log_P%
bincut2 -s 41c00 -l 0400 -o %dst_P%-32.mdt RuneWorth_A.DSK
ECHO %fnm_F%-38.mdt	[F] 38. * ファンファーレ>>"%log_F%
bincut2 -s 42000 -l 0200 -o %dst_F%-38.mdt RuneWorth_A.DSK
ECHO %fnm_P%-38.mdt	[P] 38. * ファンファーレ>>"%log_P%
bincut2 -s 42200 -l 0200 -o %dst_P%-38.mdt RuneWorth_A.DSK
ECHO %fnm_F%-39.mdt	[F] 39. * リカルトの竪琴>>"%log_F%
bincut2 -s 42400 -l 0200 -o %dst_F%-39.mdt RuneWorth_A.DSK
ECHO %fnm_P%-39.mdt	[P] 39. * リカルトの竪琴>>"%log_P%
bincut2 -s 42600 -l 0200 -o %dst_P%-39.mdt RuneWorth_A.DSK

REM ;+00200-00500 (00300 bytes) GAME DISK A/B COMMON MUSIC 2

ECHO %fnm_F%-37.mdt	[F] 37. * 宝箱ゲット>>"%log_F%
bincut2 -s 00400 -l 0100 -o %dst_F%-37.mdt RuneWorth_A.DSK
ECHO %fnm_F%-21.mdt	[F] 21. 危険がアブナイ>>"%log_F%
bincut2 -s 00500 -l 0100 -o %dst_F%-21.mdt RuneWorth_A.DSK
ECHO %fnm_P%-37.mdt	[P] 37. * 宝箱ゲット>>"%log_P%
bincut2 -s 00600 -l 0100 -o %dst_P%-37.mdt RuneWorth_A.DSK
ECHO %fnm_P%-21.mdt	[P] 21. 危険がアブナイ>>"%log_P%
bincut2 -s 00700 -l 0100 -o %dst_P%-21.mdt RuneWorth_A.DSK

REM ;+55A00-5A000 (04600 bytes) GAME DISK A MUSIC

ECHO %fnm_F%-04.mdt	[F] 04. ザノバ砦>>"%log_F%
bincut2 -s 55a00 -l 0800 -o %dst_F%-04.mdt RuneWorth_A.DSK
ECHO %fnm_P%-04.mdt	[P] 04. ザノバ砦>>"%log_P%
bincut2 -s 56200 -l 0600 -o %dst_P%-04.mdt RuneWorth_A.DSK
ECHO %fnm_F%-05.mdt	[F] 05. 神聖サイア王国>>"%log_F%
bincut2 -s 56800 -l 0600 -o %dst_F%-05.mdt RuneWorth_A.DSK
ECHO %fnm_P%-05.mdt	[P] 05. 神聖サイア王国>>"%log_P%
bincut2 -s 56e00 -l 0400 -o %dst_P%-05.mdt RuneWorth_A.DSK
ECHO %fnm_F%-08.mdt	[F] 08. シャタパーサ連邦>>"%log_F%
bincut2 -s 57200 -l 0200 -o %dst_F%-08.mdt RuneWorth_A.DSK
ECHO %fnm_P%-08.mdt	[P] 08. シャタパーサ連邦>>"%log_P%
bincut2 -s 57400 -l 0200 -o %dst_P%-08.mdt RuneWorth_A.DSK
ECHO %fnm_F%-18.mdt	[F] 18. ミリムはオ・ト・ナ>>"%log_F%
bincut2 -s 57600 -l 0400 -o %dst_F%-18.mdt RuneWorth_A.DSK
ECHO %fnm_P%-18.mdt	[P] 18. ミリムはオ・ト・ナ>>"%log_P%
bincut2 -s 57a00 -l 0400 -o %dst_P%-18.mdt RuneWorth_A.DSK
ECHO %fnm_F%-10.mdt	[F] 10. おーたま>>"%log_F%
bincut2 -s 57e00 -l 0400 -o %dst_F%-10.mdt RuneWorth_A.DSK
ECHO %fnm_P%-10.mdt	[P] 10. おーたま>>"%log_P%
bincut2 -s 58200 -l 0200 -o %dst_P%-10.mdt RuneWorth_A.DSK
ECHO %fnm_F%-26.mdt	[F] 26. サータルスの導き>>"%log_F%
bincut2 -s 58400 -l 0400 -o %dst_F%-26.mdt RuneWorth_A.DSK
ECHO %fnm_P%-26.mdt	[P] 26. サータルスの導き>>"%log_P%
bincut2 -s 58800 -l 0400 -o %dst_P%-26.mdt RuneWorth_A.DSK
ECHO %fnm_F%-27.mdt	[F] 27. 無法都市>>"%log_F%
bincut2 -s 58c00 -l 0400 -o %dst_F%-27.mdt RuneWorth_A.DSK
ECHO %fnm_P%-27.mdt	[P] 27. 無法都市>>"%log_P%
bincut2 -s 59000 -l 0400 -o %dst_P%-27.mdt RuneWorth_A.DSK
ECHO %fnm_F%-28.mdt	[F] 28. ラマスカエル燃ゆ>>"%log_F%
bincut2 -s 59400 -l 0400 -o %dst_F%-28.mdt RuneWorth_A.DSK
ECHO %fnm_P%-28.mdt	[P] 28. ラマスカエル燃ゆ>>"%log_P%
bincut2 -s 59800 -l 0400 -o %dst_P%-28.mdt RuneWorth_A.DSK

REM ;+4CA00-52000 (05600 bytes) GAME DISK B MUSIC

ECHO %fnm_F%-07.mdt	[F] 07. バハマーン神国>>"%log_F%
bincut2 -s 4ca00 -l 0400 -o %dst_F%-07.mdt RuneWorth_B.DSK
ECHO %fnm_P%-07.mdt	[P] 07. バハマーン神国>>"%log_P%
bincut2 -s 4ce00 -l 0400 -o %dst_P%-07.mdt RuneWorth_B.DSK
ECHO %fnm_F%-09.mdt	[F] 09. ウェーデル山脈>>"%log_F%
bincut2 -s 4d200 -l 0200 -o %dst_F%-09.mdt RuneWorth_B.DSK
ECHO %fnm_P%-09.mdt	[P] 09. ウェーデル山脈>>"%log_P%
bincut2 -s 4d400 -l 0200 -o %dst_P%-09.mdt RuneWorth_B.DSK
ECHO %fnm_F%-22.mdt	[F] 22. 永久凍土>>"%log_F%
bincut2 -s 4d600 -l 0400 -o %dst_F%-22.mdt RuneWorth_B.DSK
ECHO %fnm_P%-22.mdt	[P] 22. 永久凍土>>"%log_P%
bincut2 -s 4da00 -l 0400 -o %dst_P%-22.mdt RuneWorth_B.DSK
ECHO %fnm_F%-23.mdt	[F] 23. オールマムの野望>>"%log_F%
bincut2 -s 4de00 -l 0400 -o %dst_F%-23.mdt RuneWorth_B.DSK
ECHO %fnm_P%-23.mdt	[P] 23. オールマムの野望>>"%log_P%
bincut2 -s 4e200 -l 0400 -o %dst_P%-23.mdt RuneWorth_B.DSK
ECHO %fnm_F%-24.mdt	[F] 24. 戦慄の魔導士>>"%log_F%
bincut2 -s 4e600 -l 0600 -o %dst_F%-24.mdt RuneWorth_B.DSK
ECHO %fnm_P%-24.mdt	[P] 24. 戦慄の魔導士>>"%log_P%
bincut2 -s 4ec00 -l 0400 -o %dst_P%-24.mdt RuneWorth_B.DSK
ECHO %fnm_F%-25.mdt	[F] 25. あやかしの塔>>"%log_F%
bincut2 -s 4f000 -l 0400 -o %dst_F%-25.mdt RuneWorth_B.DSK
ECHO %fnm_P%-25.mdt	[P] 25. あやかしの塔>>"%log_P%
bincut2 -s 4f400 -l 0400 -o %dst_P%-25.mdt RuneWorth_B.DSK
ECHO %fnm_F%-29.mdt	[F] 29. エリースの涙>>"%log_F%
bincut2 -s 4f800 -l 0400 -o %dst_F%-29.mdt RuneWorth_B.DSK
ECHO %fnm_P%-29.mdt	[P] 29. エリースの涙>>"%log_P%
bincut2 -s 4fc00 -l 0400 -o %dst_P%-29.mdt RuneWorth_B.DSK
ECHO %fnm_F%-30.mdt	[F] 30. 暗殺魔術団ヴィーフォ>>"%log_F%
bincut2 -s 50000 -l 0600 -o %dst_F%-30.mdt RuneWorth_B.DSK
ECHO %fnm_P%-30.mdt	[P] 30. 暗殺魔術団ヴィーフォ>>"%log_P%
bincut2 -s 50600 -l 0400 -o %dst_P%-30.mdt RuneWorth_B.DSK
ECHO %fnm_F%-31.mdt	[F] 31. 暗黒からの脱出>>"%log_F%
bincut2 -s 50a00 -l 0600 -o %dst_F%-31.mdt RuneWorth_B.DSK
ECHO %fnm_P%-31.mdt	[P] 31. 暗黒からの脱出>>"%log_P%
bincut2 -s 51000 -l 0600 -o %dst_P%-31.mdt RuneWorth_B.DSK
ECHO %fnm_F%-33.mdt	[F] 33. 邪神復活>>"%log_F%
bincut2 -s 51600 -l 0600 -o %dst_F%-33.mdt RuneWorth_B.DSK
ECHO %fnm_P%-33.mdt	[P] 33. 邪神復活>>"%log_P%
bincut2 -s 51c00 -l 0400 -o %dst_P%-33.mdt RuneWorth_B.DSK

REM ;+22000-23800 (01800 bytes) START DISK ENDING MUSIC

ECHO %fnm_F%-34.mdt	[F] 34. やすらぎ>>"%log_F%
bincut2 -s 22000 -l 0800 -o %dst_F%-34.mdt RuneWorth_S.DSK
ECHO %fnm_P%-34.mdt	[P] 34. やすらぎ>>"%log_P%
bincut2 -s 22800 -l 0600 -o %dst_P%-34.mdt RuneWorth_S.DSK
ECHO %fnm_F%-35.mdt	[F] 35. 明日がふり返る>>"%log_F%
bincut2 -s 22E00 -l 0600 -o %dst_F%-35.mdt RuneWorth_S.DSK
ECHO %fnm_P%-35.mdt	[P] 35. 明日がふり返る>>"%log_P%
bincut2 -s 23400 -l 0400 -o %dst_P%-35.mdt RuneWorth_S.DSK


ECHO *****************************************************************
ECHO * 一括再生用バッチファイルを作成します。
ECHO *****************************************************************

ECHO *   OPLL: %dir_p%\PLAY-P.BAT
ECHO *   PSG : %dir_f%\PLAY-O.BAT

IF EXIST %dir_p%\PLAY-P.BAT (DEL /f %dir_p%\PLAY-P.BAT)
FOR %%i IN (%dir_p%\*.mdt) DO (
  echo psg %%~nxi >> %dir_p%\PLAY-P.BAT
)

IF EXIST %dir_f%\PLAY-O.BAT (DEL /F %dir_f%\PLAY-O.BAT)
FOR %%i IN (%dir_f%\*.mdt) DO (
  echo opll %%~nxi >> %dir_f%\PLAY-O.BAT
)

ECHO *****************************************************************
ECHO * 演奏は T^&E SOFT提供の OPLL.COM / PSG.COM を使用してください
ECHO *
ECHO * 収録先 ^> MSXFAN 1995年6月号付録のアンデッドラインBGMツール一式
ECHO *****************************************************************

IF EXIST "MSXDOS*.SYS" (
COPY "MSXDOS*.SYS" "%dir_f%\"
COPY "MSXDOS*.SYS" "%dir_p%\"
)
IF EXIST "COMMAND*.COM" (
COPY "COMMAND*.COM" "%dir_f%\"
COPY "COMMAND*.COM" "%dir_p%\"
)
IF EXIST "CHGCPU.COM" (
COPY "CHGCPU.COM" "%dir_f%\"
)
IF EXIST "OPLL.COM" (
COPY "OPLL.COM" "%dir_f%\"
)
IF EXIST "PSG.COM" (
COPY "PSG.COM" "%dir_p%\"
)

REM ********************************
ECHO * 終了ました。
REM ********************************
:wait
PAUSE
GOTO :exit_b

:exit_b