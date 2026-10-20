$ZipPath = Join-Path $OutputDir $ZipName
$TempDir = Join-Path $env:TEMP "zip_work_$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "--- Start ---" -ForegroundColor Cyan

# 1. リストファイルの存在チェック
if (-not (Test-Path $ListFile)) {
    Write-Error "Error: [$ListFile] not found. Please run '1-export-archive-list.bat' first."
    exit 1
}

# 2. 保存先ディレクトリが無ければ作成
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "Created output directory: $OutputDir" -ForegroundColor Yellow
}

# 3. 作業用の一時フォルダを作成
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    # 4. リストに書かれたファイルを構造を維持して一時フォルダへコピー
    $files = Get-Content -Path $ListFile -Encoding utf8
    foreach ($line in $files) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrEmpty($trimmed) -or $trimmed.StartsWith("#")) { continue }

        # - 除外ファイルフィルタ --------
        # ファイル名またはフォルダ名が .git で始まる場合はアーカイブから除外
        if ($trimmed -match '(^|\\|/)\.git') { continue }
        # -------------------------------

        $srcPath  = Resolve-Path (Join-Path $BaseDir $trimmed) -ErrorAction SilentlyContinue
        $destPath = Join-Path $TempDir $trimmed

        if ($srcPath -and (Test-Path $srcPath.Path) -and (-not (Test-Path $srcPath.Path -PathType Container))) {
            $parentDir = Split-Path $destPath -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }
            Copy-Item -Path $srcPath.Path -Destination $destPath -Force
        }
    }

    # 5. 既存の同名アーカイブがあれば上書き削除
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

    # 6. アーカイブ圧縮を実行
    Compress-Archive -Path "$TempDir\*" -DestinationPath $ZipPath -Force
    
    Write-Host "`n[SUCCESS] Saved to: $ZipPath" -ForegroundColor Green

} catch {
    Write-Error "Error: $_"
    exit 1
} finally {
    # 7. 後片付け
    if (Test-Path $TempDir) { Remove-Item -Recurse -Force $TempDir }
}
