@ECHO OFF

REM ### 保存先フォルダ
SET DIR_F=RuneWorth_OPLL
SET DIR_P=RuneWorth_PSG

ECHO ***** for Rune Worth (MSX2) ****************************************
ECHO.
ECHO ** MDTファイル（BGMデータ）を抽出します。
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
ECHO *****************************************************************
ECHO.

SET ER=0
IF NOT EXIST RuneWorth_S.DSK CALL :NO_DISK_S
IF NOT EXIST RuneWorth_A.DSK CALL :NO_DISK_A
IF NOT EXIST RuneWorth_B.DSK CALL :NO_DISK_B
IF NOT EXIST bincut2.exe CALL :NO_bincut2

IF %ER%==0 GOTO :CHECK_OK
ECHO *** 処理を中断します。
GOTO :WAIT

REM ************************************************
REM  DISPLAY ERROR
REM ************************************************
:NO_DISK_S
SET ER=1
ECHO [ERROR] RuneWorth_S.DSK ... スタートディスク ディスクイメージ がありません。
GOTO :EXIT_B

:NO_DISK_A
SET ER=1
ECHO [ERROR] RuneWorth_A.DSK ... ゲームディスク A ディスクイメージ がありません。
GOTO :EXIT_B

:NO_DISK_B
SET ER=1
ECHO [ERROR] RuneWorth_B.DSK ... ゲームディスク B ディスクイメージ がありません。
GOTO :EXIT_B

:NO_bincut2
SET ER=1
ECHO [ERROR] bincut2.exe がありません。
GOTO :EXIT_B

REM ************************************************
:CHECK_OK


REM ### 保存先フォルダ作成
IF NOT EXIST "%DIR_F%" MKDIR "%DIR_F%"
IF NOT EXIST "%DIR_P%" MKDIR "%DIR_P%"

REM ### 保存ファイル名
SET FNM_F=RW-O
SET FNM_P=RW-P

SET DST_F=%DIR_F%\%FNM_F%
SET DST_P=%DIR_P%\%FNM_P%

REM ### ファイルリスト保存先
SET LOG_NAME=LIST.TXT
SET LOG_F=%DIR_F%\%LOG_NAME%
SET LOG_P=%DIR_P%\%LOG_NAME%
IF EXIST "%LOG_F%" DEL /F "%LOG_F%"
IF EXIST "%LOG_P%" DEL /F "%LOG_P%"

:CUTMDT
REM *****************************************************************
ECHO ** MDTデータを切り出します。
ECHO    OPLL用とPSG用で保存先フォルダを分けます。
ECHO    (77*2=154曲 は MSX-DOSのファイル数上限を超えるため）
ECHO.
ECHO    OPLL用: %DIR_F%
ECHO    PSG 用: %DIR_P%
REM *****************************************************************
ECHO.

REM *** OPLLDRV (RAM:0100-1EFF)
REM +6E00 SIZE:1E00
bincut2 -s 06E00 -l 01E00 -o %DIR_F%\OPLL.DRV RuneWorth_S.DSK

REM *** PSGDRV (RAM:0100-1EFF)
REM +7EBD SIZE:1E00
bincut2 -s 07EBD -l 01E00 -o %DIR_P%\PSG.DRV RuneWorth_S.DSK

GOTO :SKIP_EMEDITOR_MACRO
// RuneWorth_kss_head.asm -> 切り出しコマンド変換 MACRO
document.selection.Replace("(終わり際がおかしいのでループさせた方が安全)","",eeReplaceAll,0)
document.selection.Replace("\\s+$","",eeReplaceAll | eeFindReplaceRegExp,0);
document.selection.Replace("^.*\\s+db\\s+0x(\\w{2}),\\s*[01]\\s*;([ABS])\\s+(\\w+)\\s+\\#\\w+\\s+\\((\\d+)\\)\\s+\\[([FP])\\]\\s+(\\d+)(.+)","ECHO \%FNM_\\5\%-\\6.MDT\\T[\\5] \\6\\7>>\"\%LOG_\\5\%\\nbincut2 -s \\3 -l \\100 -o %DST_\\5%-\\6.MDT RuneWorth_\\2.DSK",eeReplaceAll | eeFindReplaceRegExp,0);
document.selection.Replace("^;(.+)","ECHO \\1\\n",eeReplaceAll | eeFindReplaceRegExp,0);
:SKIP_EMEDITOR_MACRO

ECHO +08c00-0a400 (01800 bytes) START DISK OPENING MUSIC

ECHO %FNM_F%-01.MDT[F] 01. サリスの滅亡>>"%LOG_F%
bincut2 -s 08c00 -l 0200 -o %DST_F%-01.MDT RuneWorth_S.DSK
ECHO %FNM_P%-01.MDT[P] 01. サリスの滅亡>>"%LOG_P%
bincut2 -s 08e00 -l 0400 -o %DST_P%-01.MDT RuneWorth_S.DSK
ECHO %FNM_F%-02.MDT[F] 02. ルーンワースのテーマ>>"%LOG_F%
bincut2 -s 09200 -l 0A00 -o %DST_F%-02.MDT RuneWorth_S.DSK
ECHO %FNM_P%-02.MDT[P] 02. ルーンワースのテーマ>>"%LOG_P%
bincut2 -s 09C00 -l 0800 -o %DST_P%-02.MDT RuneWorth_S.DSK

ECHO +3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC

ECHO %FNM_F%-03.MDT[F] 03. 旅立ち>>"%LOG_F%
bincut2 -s 3b800 -l 0200 -o %DST_F%-03.MDT RuneWorth_A.DSK
ECHO %FNM_P%-03.MDT[P] 03. 旅立ち>>"%LOG_P%
bincut2 -s 3ba00 -l 0200 -o %DST_P%-03.MDT RuneWorth_A.DSK
ECHO %FNM_F%-14.MDT[F] 14. 死んでしまった>>"%LOG_F%
bincut2 -s 3bc00 -l 0400 -o %DST_F%-14.MDT RuneWorth_A.DSK
ECHO %FNM_P%-14.MDT[P] 14. 死んでしまった>>"%LOG_P%
bincut2 -s 3c000 -l 0400 -o %DST_P%-14.MDT RuneWorth_A.DSK
ECHO %FNM_F%-06.MDT[F] 06. ウェイデニッツ公国>>"%LOG_F%
bincut2 -s 3c400 -l 0800 -o %DST_F%-06.MDT RuneWorth_A.DSK
ECHO %FNM_P%-06.MDT[P] 06. ウェイデニッツ公国>>"%LOG_P%
bincut2 -s 3cc00 -l 0600 -o %DST_P%-06.MDT RuneWorth_A.DSK
ECHO %FNM_F%-12.MDT[F] 12. もったいない>>"%LOG_F%
bincut2 -s 3d200 -l 0400 -o %DST_F%-12.MDT RuneWorth_A.DSK
ECHO %FNM_P%-12.MDT[P] 12. もったいない>>"%LOG_P%
bincut2 -s 3d600 -l 0400 -o %DST_P%-12.MDT RuneWorth_A.DSK
ECHO %FNM_F%-11.MDT[F] 11. 祈り>>"%LOG_F%
bincut2 -s 3da00 -l 0600 -o %DST_F%-11.MDT RuneWorth_A.DSK
ECHO %FNM_P%-11.MDT[P] 11. 祈り>>"%LOG_P%
bincut2 -s 3e000 -l 0400 -o %DST_P%-11.MDT RuneWorth_A.DSK
ECHO %FNM_F%-13.MDT[F] 13. 5時からの男のために>>"%LOG_F%
bincut2 -s 3e400 -l 0600 -o %DST_F%-13.MDT RuneWorth_A.DSK
ECHO %FNM_P%-13.MDT[P] 13. 5時からの男のために>>"%LOG_P%
bincut2 -s 3ea00 -l 0400 -o %DST_P%-13.MDT RuneWorth_A.DSK
ECHO %FNM_F%-17.MDT[F] 17. URE-P>>"%LOG_F%
bincut2 -s 3ee00 -l 0600 -o %DST_F%-17.MDT RuneWorth_A.DSK
ECHO %FNM_P%-17.MDT[P] 17. URE-P>>"%LOG_P%
bincut2 -s 3f400 -l 0600 -o %DST_P%-17.MDT RuneWorth_A.DSK
ECHO %FNM_F%-15.MDT[F] 15. KANA-P>>"%LOG_F%
bincut2 -s 3fa00 -l 0400 -o %DST_F%-15.MDT RuneWorth_A.DSK
ECHO %FNM_P%-15.MDT[P] 15. KANA-P>>"%LOG_P%
bincut2 -s 3fe00 -l 0200 -o %DST_P%-15.MDT RuneWorth_A.DSK
ECHO %FNM_F%-36.MDT[F] 36. * GAME OVER>>"%LOG_F%
bincut2 -s 40000 -l 0200 -o %DST_F%-36.MDT RuneWorth_A.DSK
ECHO %FNM_P%-36.MDT[P] 36. * GAME OVER>>"%LOG_P%
bincut2 -s 40200 -l 0200 -o %DST_P%-36.MDT RuneWorth_A.DSK
ECHO %FNM_F%-16.MDT[F] 16. もっと KANA-P>>"%LOG_F%
bincut2 -s 40400 -l 0200 -o %DST_F%-16.MDT RuneWorth_A.DSK
ECHO %FNM_P%-16.MDT[P] 16. もっと KANA-P>>"%LOG_P%
bincut2 -s 40600 -l 0200 -o %DST_P%-16.MDT RuneWorth_A.DSK
ECHO %FNM_F%-19.MDT[F] 19. うろわば！>>"%LOG_F%
bincut2 -s 40800 -l 0400 -o %DST_F%-19.MDT RuneWorth_A.DSK
ECHO %FNM_P%-19.MDT[P] 19. うろわば！>>"%LOG_P%
bincut2 -s 40c00 -l 0400 -o %DST_P%-19.MDT RuneWorth_A.DSK
ECHO %FNM_F%-20.MDT[F] 20. 神々のガミガミ>>"%LOG_F%
bincut2 -s 41000 -l 0400 -o %DST_F%-20.MDT RuneWorth_A.DSK
ECHO %FNM_P%-20.MDT[P] 20. 神々のガミガミ>>"%LOG_P%
bincut2 -s 41400 -l 0400 -o %DST_P%-20.MDT RuneWorth_A.DSK
ECHO %FNM_F%-32.MDT[F] 32. 限りなき戦い>>"%LOG_F%
bincut2 -s 41800 -l 0400 -o %DST_F%-32.MDT RuneWorth_A.DSK
ECHO %FNM_P%-32.MDT[P] 32. 限りなき戦い>>"%LOG_P%
bincut2 -s 41c00 -l 0400 -o %DST_P%-32.MDT RuneWorth_A.DSK
ECHO %FNM_F%-38.MDT[F] 38. * ファンファーレ>>"%LOG_F%
bincut2 -s 42000 -l 0200 -o %DST_F%-38.MDT RuneWorth_A.DSK
ECHO %FNM_P%-38.MDT[P] 38. * ファンファーレ>>"%LOG_P%
bincut2 -s 42200 -l 0200 -o %DST_P%-38.MDT RuneWorth_A.DSK
ECHO %FNM_F%-39.MDT[F] 39. * リカルトの竪琴>>"%LOG_F%
bincut2 -s 42400 -l 0200 -o %DST_F%-39.MDT RuneWorth_A.DSK
ECHO %FNM_P%-39.MDT[P] 39. * リカルトの竪琴>>"%LOG_P%
bincut2 -s 42600 -l 0200 -o %DST_P%-39.MDT RuneWorth_A.DSK

ECHO +00200-00500 (00300 bytes) GAME DISK A/B COMMON MUSIC 2

ECHO %FNM_F%-37.MDT[F] 37. * 宝箱ゲット>>"%LOG_F%
bincut2 -s 00400 -l 0100 -o %DST_F%-37.MDT RuneWorth_A.DSK
ECHO %FNM_F%-21.MDT[F] 21. 危険がアブナイ>>"%LOG_F%
bincut2 -s 00500 -l 0100 -o %DST_F%-21.MDT RuneWorth_A.DSK
ECHO %FNM_P%-37.MDT[P] 37. * 宝箱ゲット>>"%LOG_P%
bincut2 -s 00600 -l 0100 -o %DST_P%-37.MDT RuneWorth_A.DSK
ECHO %FNM_P%-21.MDT[P] 21. 危険がアブナイ>>"%LOG_P%
bincut2 -s 00700 -l 0100 -o %DST_P%-21.MDT RuneWorth_A.DSK

ECHO +55A00-5A000 (04600 bytes) GAME DISK A MUSIC

ECHO %FNM_F%-04.MDT[F] 04. ザノバ砦>>"%LOG_F%
bincut2 -s 55a00 -l 0800 -o %DST_F%-04.MDT RuneWorth_A.DSK
ECHO %FNM_P%-04.MDT[P] 04. ザノバ砦>>"%LOG_P%
bincut2 -s 56200 -l 0600 -o %DST_P%-04.MDT RuneWorth_A.DSK
ECHO %FNM_F%-05.MDT[F] 05. 神聖サイア王国>>"%LOG_F%
bincut2 -s 56800 -l 0600 -o %DST_F%-05.MDT RuneWorth_A.DSK
ECHO %FNM_P%-05.MDT[P] 05. 神聖サイア王国>>"%LOG_P%
bincut2 -s 56e00 -l 0400 -o %DST_P%-05.MDT RuneWorth_A.DSK
ECHO %FNM_F%-08.MDT[F] 08. シャタパーサ連邦>>"%LOG_F%
bincut2 -s 57200 -l 0200 -o %DST_F%-08.MDT RuneWorth_A.DSK
ECHO %FNM_P%-08.MDT[P] 08. シャタパーサ連邦>>"%LOG_P%
bincut2 -s 57400 -l 0200 -o %DST_P%-08.MDT RuneWorth_A.DSK
ECHO %FNM_F%-18.MDT[F] 18. ミリムはオ・ト・ナ>>"%LOG_F%
bincut2 -s 57600 -l 0400 -o %DST_F%-18.MDT RuneWorth_A.DSK
ECHO %FNM_P%-18.MDT[P] 18. ミリムはオ・ト・ナ>>"%LOG_P%
bincut2 -s 57a00 -l 0400 -o %DST_P%-18.MDT RuneWorth_A.DSK
ECHO %FNM_F%-10.MDT[F] 10. おーたま>>"%LOG_F%
bincut2 -s 57e00 -l 0400 -o %DST_F%-10.MDT RuneWorth_A.DSK
ECHO %FNM_P%-10.MDT[P] 10. おーたま>>"%LOG_P%
bincut2 -s 58200 -l 0200 -o %DST_P%-10.MDT RuneWorth_A.DSK
ECHO %FNM_F%-26.MDT[F] 26. サータルスの導き>>"%LOG_F%
bincut2 -s 58400 -l 0400 -o %DST_F%-26.MDT RuneWorth_A.DSK
ECHO %FNM_P%-26.MDT[P] 26. サータルスの導き>>"%LOG_P%
bincut2 -s 58800 -l 0400 -o %DST_P%-26.MDT RuneWorth_A.DSK
ECHO %FNM_F%-27.MDT[F] 27. 無法都市>>"%LOG_F%
bincut2 -s 58c00 -l 0400 -o %DST_F%-27.MDT RuneWorth_A.DSK
ECHO %FNM_P%-27.MDT[P] 27. 無法都市>>"%LOG_P%
bincut2 -s 59000 -l 0400 -o %DST_P%-27.MDT RuneWorth_A.DSK
ECHO %FNM_F%-28.MDT[F] 28. ラマスカエル燃ゆ>>"%LOG_F%
bincut2 -s 59400 -l 0400 -o %DST_F%-28.MDT RuneWorth_A.DSK
ECHO %FNM_P%-28.MDT[P] 28. ラマスカエル燃ゆ>>"%LOG_P%
bincut2 -s 59800 -l 0400 -o %DST_P%-28.MDT RuneWorth_A.DSK

ECHO +4CA00-52000 (05600 bytes) GAME DISK B MUSIC

ECHO %FNM_F%-07.MDT[F] 07. バハマーン神国>>"%LOG_F%
bincut2 -s 4ca00 -l 0400 -o %DST_F%-07.MDT RuneWorth_B.DSK
ECHO %FNM_P%-07.MDT[P] 07. バハマーン神国>>"%LOG_P%
bincut2 -s 4ce00 -l 0400 -o %DST_P%-07.MDT RuneWorth_B.DSK
ECHO %FNM_F%-09.MDT[F] 09. ウェーデル山脈>>"%LOG_F%
bincut2 -s 4d200 -l 0200 -o %DST_F%-09.MDT RuneWorth_B.DSK
ECHO %FNM_P%-09.MDT[P] 09. ウェーデル山脈>>"%LOG_P%
bincut2 -s 4d400 -l 0200 -o %DST_P%-09.MDT RuneWorth_B.DSK
ECHO %FNM_F%-22.MDT[F] 22. 永久凍土>>"%LOG_F%
bincut2 -s 4d600 -l 0400 -o %DST_F%-22.MDT RuneWorth_B.DSK
ECHO %FNM_P%-22.MDT[P] 22. 永久凍土>>"%LOG_P%
bincut2 -s 4da00 -l 0400 -o %DST_P%-22.MDT RuneWorth_B.DSK
ECHO %FNM_F%-23.MDT[F] 23. オールマムの野望>>"%LOG_F%
bincut2 -s 4de00 -l 0400 -o %DST_F%-23.MDT RuneWorth_B.DSK
ECHO %FNM_P%-23.MDT[P] 23. オールマムの野望>>"%LOG_P%
bincut2 -s 4e200 -l 0400 -o %DST_P%-23.MDT RuneWorth_B.DSK
ECHO %FNM_F%-24.MDT[F] 24. 戦慄の魔導士>>"%LOG_F%
bincut2 -s 4e600 -l 0600 -o %DST_F%-24.MDT RuneWorth_B.DSK
ECHO %FNM_P%-24.MDT[P] 24. 戦慄の魔導士>>"%LOG_P%
bincut2 -s 4ec00 -l 0400 -o %DST_P%-24.MDT RuneWorth_B.DSK
ECHO %FNM_F%-25.MDT[F] 25. あやかしの塔>>"%LOG_F%
bincut2 -s 4f000 -l 0400 -o %DST_F%-25.MDT RuneWorth_B.DSK
ECHO %FNM_P%-25.MDT[P] 25. あやかしの塔>>"%LOG_P%
bincut2 -s 4f400 -l 0400 -o %DST_P%-25.MDT RuneWorth_B.DSK
ECHO %FNM_F%-29.MDT[F] 29. エリースの涙>>"%LOG_F%
bincut2 -s 4f800 -l 0400 -o %DST_F%-29.MDT RuneWorth_B.DSK
ECHO %FNM_P%-29.MDT[P] 29. エリースの涙>>"%LOG_P%
bincut2 -s 4fc00 -l 0400 -o %DST_P%-29.MDT RuneWorth_B.DSK
ECHO %FNM_F%-30.MDT[F] 30. 暗殺魔術団ヴィーフォ>>"%LOG_F%
bincut2 -s 50000 -l 0600 -o %DST_F%-30.MDT RuneWorth_B.DSK
ECHO %FNM_P%-30.MDT[P] 30. 暗殺魔術団ヴィーフォ>>"%LOG_P%
bincut2 -s 50600 -l 0400 -o %DST_P%-30.MDT RuneWorth_B.DSK
ECHO %FNM_F%-31.MDT[F] 31. 暗黒からの脱出>>"%LOG_F%
bincut2 -s 50a00 -l 0600 -o %DST_F%-31.MDT RuneWorth_B.DSK
ECHO %FNM_P%-31.MDT[P] 31. 暗黒からの脱出>>"%LOG_P%
bincut2 -s 51000 -l 0600 -o %DST_P%-31.MDT RuneWorth_B.DSK
ECHO %FNM_F%-33.MDT[F] 33. 邪神復活>>"%LOG_F%
bincut2 -s 51600 -l 0600 -o %DST_F%-33.MDT RuneWorth_B.DSK
ECHO %FNM_P%-33.MDT[P] 33. 邪神復活>>"%LOG_P%
bincut2 -s 51c00 -l 0400 -o %DST_P%-33.MDT RuneWorth_B.DSK

ECHO +22000-23800 (01800 bytes) START DISK ENDING MUSIC

ECHO %FNM_F%-34.MDT[F] 34. やすらぎ>>"%LOG_F%
bincut2 -s 22000 -l 0800 -o %DST_F%-34.MDT RuneWorth_S.DSK
ECHO %FNM_P%-34.MDT[P] 34. やすらぎ>>"%LOG_P%
bincut2 -s 22800 -l 0600 -o %DST_P%-34.MDT RuneWorth_S.DSK
ECHO %FNM_F%-35.MDT[F] 35. 明日がふり返る>>"%LOG_F%
bincut2 -s 22E00 -l 0600 -o %DST_F%-35.MDT RuneWorth_S.DSK
ECHO %FNM_P%-35.MDT[P] 35. 明日がふり返る>>"%LOG_P%
bincut2 -s 23400 -l 0400 -o %DST_P%-35.MDT RuneWorth_S.DSK

ECHO.
REM *****************************************************************
ECHO ** 一括再生用バッチファイルを作成します。
REM *****************************************************************
ECHO    OPLL: %DIR_P%\
ECHO          PLAY-P.BAT
ECHO          ファイルリスト: %LOG_NAME%
ECHO    PSG : %DIR_F%\
ECHO          PLAY-O.BAT
ECHO          ファイルリスト: %LOG_NAME%

IF EXIST %DIR_P%\PLAY-P.BAT (DEL /F %DIR_P%\PLAY-P.BAT)
FOR %%I IN (%DIR_P%\*.MDT) DO (
  ECHO PSG %%~NXI >> %DIR_P%\PLAY-P.BAT
)

IF EXIST %DIR_F%\PLAY-O.BAT (DEL /F %DIR_F%\PLAY-O.BAT)
FOR %%I IN (%DIR_F%\*.MDT) DO (
  ECHO OPLL %%~NXI >> %DIR_F%\PLAY-O.BAT
)

ECHO.
ECHO *****************************************************************
ECHO * 演奏は T^&E SOFT提供の OPLL.COM / PSG.COM を使用してください
ECHO * 収録先 ^> MSXFAN 1995年6月号付録のアンデッドラインBGMツール一式
ECHO *****************************************************************

IF EXIST "MSXDOS*.SYS" (
COPY "MSXDOS*.SYS" "%DIR_F%\">nul
COPY "MSXDOS*.SYS" "%DIR_P%\">nul
)
IF EXIST "COMMAND*.COM" (
COPY "COMMAND*.COM" "%DIR_F%\">nul
COPY "COMMAND*.COM" "%DIR_P%\">nul
)
IF EXIST "CHGCPU.COM" (
COPY "CHGCPU.COM" "%DIR_F%\">nul
)
IF EXIST "OPLL.COM" (
COPY "OPLL.COM" "%DIR_F%\">nul
)
IF EXIST "PSG.COM" (
COPY "PSG.COM" "%DIR_P%\">nul
)

REM ********************************
ECHO * 終了ました。
REM ********************************
:WAIT
PAUSE
GOTO :EXIT_B

:EXIT_B