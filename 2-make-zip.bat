@echo off
chcp 65001 > nul
setlocal

:: ============================================================
:: [Settings] 設定値
:: ============================================================
set "LIST_FILE=.\archive-files.txt"
set "BASE_DIR=.\"
set "OUTPUT_DIR=.\_Release"
set "ZIP_NAME=MSX_GAME_TOOL.zip"
:: ============================================================

echo === [2/2] Creating ZIP from %LIST_FILE% ===

:: -Command を使い、バッチの変数をスクリプト内の変数として直接セットして実行
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ListFile='%LIST_FILE%'; $BaseDir='%BASE_DIR%'; $OutputDir='%OUTPUT_DIR%'; $ZipName='%ZIP_NAME%'; & '.\zip-worker.ps1'"

:: エラー時は一時停止
if %errorlevel% neq 0 (
    echo.
    echo  [31m[ERROR] ZIP creation failed. Please check the error message above. [0m
    pause
    exit /b %errorlevel%
)

:: 成功時は10秒後に自動クローズ
echo.
echo  [32m[SUCCESS] All processes completed successfully! [0m
timeout /t 10
