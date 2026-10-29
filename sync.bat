@echo off
setlocal

rem 通常の呼び出し。標準出力（Write-Output）ならエラーレベルは汚されません
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync.ps1"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 同期処理中にエラーが発生しました。
    pause
    exit /b %errorlevel%
)

echo.
echo 同期処理が正常に完了しました。
rem キー入力でいつでもスキップして閉じられる、通常のtimeoutに戻します
timeout /t 10
