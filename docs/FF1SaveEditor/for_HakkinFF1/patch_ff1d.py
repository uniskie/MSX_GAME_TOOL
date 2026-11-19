#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""HakkinFF1 Project (.ff1d) JP Patcher

日本版FF1 ROM向けに ff1d のオフセット値および日本語文字テーブルを適用する。
"""

import json
import os
import shutil
import sys

# ==============================================================================
# 1. 日本版 文字コードテーブル定義 (0x00 - 0xFF: 計256要素)
# ==============================================================================
JP_CONTROL_EMPTY_COUNT = 0x48  # 0x00 - 0x47 (72要素)

JP_CHARS_DEFINITION = (
    # 0x48 - 0x74: 濁音・半濁音
    "がぎぐげござじずぜぞだぢづでどばびぶべぼ"
    "ガギグゲゴザジズゼゾダヂヅデドバビブベボ"
    "ぱぴぷぺぽパピプペポ"
    # 0x75 - 0x84: 記号・小文字ひらがな・全角数字
    "／をっゃゅょ０１２３４５６７８９"
    # 0x85 - 0xAF: ひらがな
    "あいうえおかきくけこさしすせそたちつてと"
    "なにぬねのはひふへほまみむめもやゆよらりるれろわん"
    # 0xB0 - 0xC2: 記号・小文字カナ・アルファベット
    "ァィ。ェォッャュョ゛゜ー‥！？ＬＥＨＰ"
    # 0xC3 - 0xED: カタカナ
    "アイウエオカキクケコサシスセソタチツテト"
    "ナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン"
    # 0xEE - 0xFF: 枠線・空白
    "┏━┓┃│┗─┛　"
)


def build_jp_text_table():
  table = [""] * JP_CONTROL_EMPTY_COUNT + list(JP_CHARS_DEFINITION)
  if len(table) != 256:
    raise ValueError(
        f"文字テーブル要素数異常: {len(table)} (期待値: 256)"
    )
  return table


# ==============================================================================
# 2. 日本版 ROM 補正アドレス定義
# ==============================================================================
ROM_VALUE_PATCHES = {
    # Bank 0F: パレット / 描画領域 (+143 bytes / +0x8F)
    "CharBattlePaletteAssignment2": "$3ED43",
    "BattlePaletteOffset": "$3EC44",
    "MenuWindowColorOffset": "$3EBC9",
    "BattleWindowColorOffset": "$3EBCD",
    "WindowGreyColorOffset": "$3EBD7",
    "WindowWhiteColorOffset": "$3EBDC",
    "ShopBoxPaletteOffset": "$3EC13",
    "BbmaClass1UnadjOffset": "$3EF62",
    "BbmaClass2UnadjOffset": "$3EF66",
    "BbmaClass1ReadjOffset": "$3EF80",
    "BbmaClass2ReadjOffset": "$3EF84",
    # Bank 0E: 防具部位 / 習得制限 (+19 bytes / +0x13)
    "ArmorTypeOffset": "$3BCF4",
    "MagicPermissionsOffset": "$3AD3B",
    # Bank 0E: 移動中魔法判定ルーチン (+19 bytes / +0x13)
    "MgCure": "$3AF1D",
    "MgCur2": "$3AF24",
    "MgCur3": "$3AF2B",
    "MgCur4": "$3AF32",
    "MgHeal": "$3AF39",
    "MgHel2": "$3AF40",
    "MgHel3": "$3AF47",
    "MgPure": "$3AF4E",
    "MgLife": "$3AF55",
    "MgLif2": "$3AF5C",
    "MgWarp": "$3AF63",
    "MgSoft": "$3AF6A",
    "MgExit": "$3AF71",
}


# ==============================================================================
# 3. メイン処理
# ==============================================================================
def patch_ff1d(input_path, output_path=None):
  if not os.path.exists(input_path):
    print(f"エラー: 指定されたファイルが存在しません: {input_path}")
    sys.exit(1)

  print(f"対象ファイル: {input_path}")

  # バックアップ作成
  if output_path is None:
    output_path = input_path
    backup_path = input_path + ".bak"
    counter = 1
    while os.path.exists(backup_path):
      backup_path = f"{input_path}({counter}).bak"
      counter += 1
    shutil.copy2(input_path, backup_path)
    print(f"バックアップ作成: {backup_path}")

  # 読み込み
  with open(input_path, "r", encoding="utf-8") as f:
    try:
      data = json.load(f)
    except Exception as e:
      print(f"エラー: JSON解析失敗: {e}")
      sys.exit(1)

  # RomValues の更新
  patched_offsets = 0
  if "RomValues" in data and isinstance(data["RomValues"], list):
    for entry in data["RomValues"]:
      name = entry.get("Name")
      if name in ROM_VALUE_PATCHES:
        kind = entry.get("Kind")
        # Kind が Offset であることを確認
        if kind != "Offset":
          print(
              f"スキップ: {name} の Kind が 'Offset' ではありません (Kind: {kind})"
          )
          continue

        old_val = entry.get("Value")
        new_val = ROM_VALUE_PATCHES[name]
        if old_val != new_val:
          entry["Value"] = new_val
          patched_offsets += 1
          print(f"  [更新] {name:<30}: {old_val} -> {new_val}")
  else:
    print("エラー: RomValues セクションが存在しません。")
    sys.exit(1)

  # TextTables の更新
  jp_table = build_jp_text_table()
  if "TextTables" not in data:
    data["TextTables"] = {}

  data["TextTables"]["StdTable"] = jp_table
  data["TextTables"]["DteTable"] = jp_table
  print(f"  [更新] StdTable / DteTable を日本語文字マップ (256要素) に置換")

  # 書き込み
  with open(output_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

  print("-" * 50)
  print(f"処理終了: {patched_offsets} 件のオフセットを更新しました。")
  print("-" * 50)


if __name__ == "__main__":
  if len(sys.argv) < 2:
    print("使用法: python patch_ff1d.py <ff1dファイルパス> [出力ファイルパス]")
    sys.exit(1)

  output_file = sys.argv[2] if len(sys.argv) > 2 else None
  patch_ff1d(sys.argv[1], output_file)
