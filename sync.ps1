# 設定ファイル（.github/sync-config.json）の絶対パスを組み立てて存在検証
$configPath = Join-Path $PSScriptRoot ".github\sync-config.json"
if (-not (Test-Path $configPath)) {
    Write-Error "Configuration file not found at $configPath"
    exit 1
}

# JSONファイルから設定配列をデコードしてオブジェクトとして取得
$syncMap = Get-Content $configPath -Raw | ConvertFrom-Json

# 設定されたコピー元とコピー先のペアを順次ループ処理
foreach ($item in $syncMap) {
    # 監視元（from）の相対パスを絶対パスへ変換
    $srcFullPath = Resolve-Path (Join-Path $PSScriptRoot $item.from) -ErrorAction SilentlyContinue
    if (-not $srcFullPath) {
        Write-Warning "Source path not found: $($item.from)"
        continue
    }

    # コピー先（to）の絶対パスを組み立て
    $destFullPath = Join-Path $PSScriptRoot $item.to

    # コピー先ディレクトリが存在しない場合は自動的に階層を作成
    if (-not (Test-Path $destFullPath)) {
        New-Item -ItemType Directory -Force -Path $destFullPath | Out-Null
    }

    # 対象アイテムの属性（ファイルかディレクトリか）を判定してコピーを実行
    if (Test-Path $srcFullPath -PathType Leaf) {
        # ファイル単体を指定ディレクトリへ上書きコピー
        Copy-Item -Path $srcFullPath -Destination $destFullPath -Force
        Write-Host "➔ File copied: $($item.from) to $($item.to)"
    } else {
        # ディレクトリ配下のすべての構成要素を再帰的に上書きコピー
        Copy-Item -Path "$srcFullPath\*" -Destination $destFullPath -Recurse -Force
        Write-Host "➔ Directory synced: $($item.from) to $($item.to)"
    }
}
