#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FFHackSterEX Project JP Patcher

日本版FF1 ROM向けに FFHackSterEX プロジェクト設定ファイル群
(.values, .std.tbl, .dte.tbl) のオフセット補正値および日本語文字テーブルを適用する。
古いプログラム向けに出力エンコーディングは Shift_JIS (CP932 / CRLF) で行います。
"""

import os
import re
import shutil
import sys

# 古いWin32環境・ツール互換のエンコーディング定義
FILE_ENCODING = "cp932"  # Windows標準のShift_JIS

# ==============================================================================
# 1. 日本版 文字コードテーブル定義 (0x48 - 0xFF)
#    +XX 行ごとに文字を並べる見やすいフォーマットで宣言
# ==============================================================================
JP_CHARS_MAP_DEFINITION = """
+48	がぎぐげござじず
+50	ぜぞだぢづでどばびぶべぼガギグゲ
+60	ゴザジズゼゾダヂヅデドバビブベボ
+70	ぱぴぷぺぽパピプペポ／をっゃゅょ
+80	０１２３４５６７８９あいうえおか
+90	きくけこさしすせそたちつてとなに
+A0	ぬねのはひふへほまみむめもやゆよ
+B0	らりるれろわんァィ。ェォッャュョ
+C0	゛゜ー‥！？ＬＥＨＰアイウエオカ
+D0	キクケコサシスセソタチツテトナニ
+E0	ヌネノハヒフヘホマミムメモヤユヨ
+F0	ラリルレロワン┏━┓┃│┗─┛　
"""


def build_tbl_lines(definition_text):
    """宣言テキストをパースし、'XX=文字' 形式の行リスト（Thingyテーブル形式）を生成する。"""
    tbl_lines = []
    for line in definition_text.splitlines():
        line = line.lstrip(" \t")
        if not line or line.startswith("#"):
            continue

        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue

        hex_str, chars = parts
        start_code = int(hex_str.lstrip("+").strip(), 16)

        for i, char in enumerate(chars):
            code = start_code + i
            tbl_lines.append(f"{code:02X}={char}")

    return tbl_lines

# ==============================================================================
# 2. 日本版 ROM 補正アドレス定義 (FFHackSterEX .values セクション名)
# ==============================================================================
VALUES_PATCHES = {
    # Bank 0F: キャラクター戦闘パレット
    "CHARBATTLEPALETTE_OFFSET": "0x3EC44",  # US: 0x3EBB5
    "CHARBATTLEPALETTE_ASSIGNMENT2": "0x3ED43",  # US: 0x3ECB4
    # Bank 0F: モンク/スーパーモンクの装備解除・再調整ルーチン
    "BBMACLASS1UNADJ_OFFSET": "0x3EF62",  # US: 0x3EED3
    "BBMACLASS2UNADJ_OFFSET": "0x3EF66",  # US: 0x3EED7
    "BBMACLASS1READJ_OFFSET": "0x3EF80",  # US: 0x3EEF1
    "BBMACLASS2READJ_OFFSET": "0x3EF84",  # US: 0x3EEF5
    # Bank 0F: ウィンドウカラー / パレット (エディタ定義に存在する場合)
    "MENUWINDOWCOLOR_OFFSET": "0x3EBC9",
    "BATTLEWINDOWCOLOR_OFFSET": "0x3EBCD",
    "WINDOWGREYCOLOR_OFFSET": "0x3EBD7",
    "WINDOWWHITECOLOR_OFFSET": "0x3EBDC",
    "SHOPBOXPALETTE_OFFSET": "0x3EC13",
    # Bank 0E: 防具部位 / 習得制限
    "ARMORTYPE_OFFSET": "0x3BCF4",  # US: 0x3BCE1
    "MAGICPERMISSIONS_OFFSET": "0x3AD3B",  # US: 0x3AD28
    # Bank 0E: 移動中 (Out-of-Battle) 魔法判定ルーチン
    "MG_CURE": "0x3AF1D",  # US: 0x3AF0A
    "MG_CUR2": "0x3AF24",  # US: 0x3AF11
    "MG_CUR3": "0x3AF2B",  # US: 0x3AF18
    "MG_CUR4": "0x3AF32",  # US: 0x3AF1F
    "MG_HEAL": "0x3AF39",  # US: 0x3AF26
    "MG_HEL2": "0x3AF40",  # US: 0x3AF2D
    "MG_HEL3": "0x3AF47",  # US: 0x3AF34
    "MG_PURE": "0x3AF4E",  # US: 0x3AF3B
    "MG_LIFE": "0x3AF55",  # US: 0x3AF42
    "MG_LIF2": "0x3AF5C",  # US: 0x3AF49
    "MG_WARP": "0x3AF63",  # US: 0x3AF50
    "MG_SOFT": "0x3AF6A",  # US: 0x3AF57
    "MG_EXIT": "0x3AF71",  # US: 0x3AF5E
}


# ==============================================================================
# 3. ファイル操作ユーティリティ
# ==============================================================================
def create_backup(file_path):
  """既存ファイルのバックアップ (.bak) を作成する"""
  if not os.path.exists(file_path):
    return None
  backup_path = file_path + ".bak"
  counter = 1
  while os.path.exists(backup_path):
    backup_path = f"{file_path}({counter}).bak"
    counter += 1
  shutil.copy2(file_path, backup_path)
  print(f"  [バックアップ作成] {os.path.basename(backup_path)}")
  return backup_path


def patch_values_file(values_path):
  """INIライクな .values ファイルの書式・コメント・順序を完全保持したまま対象オフセットを更新する"""
  print(f"\n--- [処理中] Values設定: {os.path.basename(values_path)} ---")
  create_backup(values_path)

  # newline="" で読み込み、改行を勝手に変換させない
  with open(
      values_path, "r", encoding=FILE_ENCODING, newline="", errors="replace"
  ) as f:
    lines = f.readlines()

  new_lines = []
  current_section = None
  patched_count = 0

  for raw_line in lines:
    # 既存の改行 (\r, \n) を完全に除去して純粋なテキストにする
    clean_line = raw_line.rstrip("\r\n")
    stripped = clean_line.strip()

    # セクション検出 [SECTION_NAME]
    if stripped.startswith("[") and stripped.endswith("]"):
      current_section = stripped[1:-1].strip()
      new_lines.append(clean_line)
      continue

    # 対象セクション内の value= 行を書き換え
    if current_section and current_section in VALUES_PATCHES:
      match = re.match(
          r"^(\s*value\s*=\s*)([^\s#;]+)(.*)$", clean_line, re.IGNORECASE
      )
      if match:
        prefix, old_val, suffix = match.groups()
        new_val = VALUES_PATCHES[current_section]

        if old_val.lower() != new_val.lower():
          clean_line = f"{prefix}{new_val}{suffix}"
          patched_count += 1
          print(f"  [更新] {current_section:<32}: {old_val} -> {new_val}")

    new_lines.append(clean_line)

  # すべて純粋な CRLF (\r\n) で結合し、newline="" を指定して余計な自動変換を防ぐ
  output_content = "\r\n".join(new_lines) + "\r\n"
  with open(
      values_path, "w", encoding=FILE_ENCODING, newline="", errors="replace"
  ) as f:
    f.write(output_content)

  print(
      f"  -> {patched_count} 件のオフセットを日本版アドレスに更新しました。"
  )
  return patched_count


def write_tbl_file(tbl_path, tbl_lines):
  """テーブルファイル (.std.tbl / .dte.tbl) を Shift_JIS (CRLF) で書き出す"""
  file_name = os.path.basename(tbl_path)
  print(f"\n--- [処理中] 文字テーブル: {file_name} ---")
  if os.path.exists(tbl_path):
    create_backup(tbl_path)

  # 各要素に改行は含まれていないので、\r\n で結合
  output_content = "\r\n".join(tbl_lines) + "\r\n"

  # newline="" を指定して Python による二重変換 (\r\r\n) を防止
  with open(
      tbl_path, "w", encoding=FILE_ENCODING, newline="", errors="replace"
  ) as f:
    f.write(output_content)

  print(f"  [書き込み完了] {file_name} ({len(tbl_lines)} 文字要素 / SJIS)")


# ==============================================================================
# 4. メイン処理
# ==============================================================================
def resolve_project_targets(target_path):
  """プロジェクトフォルダまたは特定ファイルから対象ファイル群のパスを解決する"""
  target_path = os.path.abspath(target_path)

  if os.path.isdir(target_path):
    project_dir = target_path
    dir_name = os.path.basename(project_dir.rstrip(os.sep))
    expected_values = os.path.join(project_dir, f"{dir_name}.values")

    if os.path.exists(expected_values):
      base_name = dir_name
    else:
      values_files = [
          f for f in os.listdir(project_dir) if f.endswith(".values")
      ]
      if not values_files:
        raise FileNotFoundError(
            f"エラー: フォルダ内に .values ファイルが見つかりません: {project_dir}"
        )
      base_name = os.path.splitext(values_files[0])[0]

  elif os.path.isfile(target_path):
    project_dir = os.path.dirname(target_path)
    base_name = os.path.splitext(os.path.basename(target_path))[0]
    if base_name.endswith(".std") or base_name.endswith(".dte"):
      base_name = os.path.splitext(base_name)[0]
  else:
    raise FileNotFoundError(
        f"エラー: 指定されたパスが存在しません: {target_path}"
    )

  values_file = os.path.join(project_dir, f"{base_name}.values")
  std_tbl_file = os.path.join(project_dir, f"{base_name}.std.tbl")
  dte_tbl_file = os.path.join(project_dir, f"{base_name}.dte.tbl")

  return values_file, std_tbl_file, dte_tbl_file


def main():
  if len(sys.argv) < 2:
    print("使用法:")
    print(
        "  python patch_ffhacksterex_proj.py <プロジェクトフォルダパス または"
        " .valuesファイル>"
    )
    print("例:")
    print("  python patch_ffhacksterex_proj.py ./FinalFantasy1")
    print(
        "  python patch_ffhacksterex_proj.py ./FinalFantasy1/FinalFantasy1.values"
    )
    sys.exit(1)

  target_input = sys.argv[1]

  try:
    values_path, std_path, dte_path = resolve_project_targets(target_input)
  except Exception as e:
    print(e)
    sys.exit(1)

  print("=" * 60)
  print(" FFHackSterEX プロジェクト 日本語ROM対応パッチャー (SJIS)")
  print("=" * 60)
  print(f"対象フォルダ: {os.path.dirname(values_path)}")

  # 1. Values ファイルのパッチ適用
  if os.path.exists(values_path):
    patch_values_file(values_path)
  else:
    print(f"\n[警告] Valuesファイルが見つかりません: {values_path}")

  # 2. 文字テーブルデータの生成
  tbl_lines = build_tbl_lines(JP_CHARS_MAP_DEFINITION)

  # 3. .std.tbl / .dte.tbl の書き込み (Shift_JIS / CRLF / 二重改行なし)
  write_tbl_file(std_path, tbl_lines)
  write_tbl_file(dte_path, tbl_lines)

  print("\n" + "=" * 60)
  print("すべてのパッチ適用処理が完了しました。")
  print("=" * 60)


if __name__ == "__main__":
  main()
