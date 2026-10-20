@echo off
chcp 65001 > nul
setlocal

:: 出力するリスト名
set "LIST_FILE=archive-files.txt"

echo === [1/2] Exporting list of files to archive ===
:: git archive --list HEAD ではなく、正しい一覧取得コマンドに修正
git ls-tree -r --name-only HEAD > "%LIST_FILE%"

if %errorlevel% equ 0 (
    echo [OK] Saved to %LIST_FILE%
    timeout /t 10
) else (
    echo [ERROR] Git command failed. Are you in a git repository?
    pause
)
