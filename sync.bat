@echo off
setlocal enabledelayedexpansion

rem PowerShellの終了コードをバッチの %errorlevel% に確実に引き継ぐため、-Command 経由で実行
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0sync.ps1'; exit $LASTEXITCODE"

rem エラーコードが0以外（異常終了）だった場合の判定
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 同期処理中にエラーが発生しました。(ErrorLevel: %errorlevel%)
    pause
    exit /b %errorlevel%
)

echo.
echo 同期処理が正常に完了しました。
timeout /t 10
