#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ff1_msx_bugfix_btl.py

MSX2版『ファイナルファンタジー』（マイクロキャビン移植）のDSKイメージに対し、
戦闘関連およびフィールド・マップ関連の不具合修正（FF1J_Bugfixes 相当）を適用するパッチスクリプト。

-------------------------------------------------------------------------------
メモリマップとパッチ配置構成
-------------------------------------------------------------------------------
BATTLE.COM 実行時におけるメインRAMの配置:

  0x3400 - 0x351F: 戦闘時 味方実効バッファ（4人 × 72バイト）
  0x3520 - 0x362D: 戦闘時 敵実効バッファ（最大9体 × 30バイト）
  0x362E - 0x36FF: 戦闘バッファ直後領域 (210バイト枠)
                   -> 常駐領域B (210バイト使用: パッチ11L, 11S, 13, 14, 16, 15)
  0x3700 - 0x3FFF: メッセージベクタ・魔法名バッファ (上書き不可)
  0x8000 - 0xBC5F: BATTLE.COM プログラムコードおよび固定データ領域
  0xBC60 - 0xBCDC: 戦闘制御ワークエリア（戦闘中常時更新）
  0xBCDD - 0xBCFF: 未使用パディング領域 (35バイト枠)
                   -> 常駐領域A (31バイト使用: パッチ06, 07)
  0xBD00 - 0xBFFF: MAIN.COM 常駐PSG演奏ドライバ ワークエリア (戦闘BGM開始後に更新)
  0xBE00         : BATTLE.COM ファイル末尾境界 (31セクタ = 15,872バイト)

配置方針:
1. 常駐領域A (0xBCDD〜0xBCFB, 31バイト / 35バイト枠):
   BATTLE.COM のファイル内空きパディング領域に直接格納（実行時転送なし）。
   ・パッチ06: アイテム使用時の沈黙判定回避 (12バイト)
   ・パッチ07: 敵対象魔法後の耐性・命中率保存 (19バイト)

2. 常駐領域B (0x362E〜0x36FF, 210バイト / 210バイト枠):
   ディスク上のファイル末尾（0xBD10〜）に格納し、0x8004 実行時に 0x362E へ LDIR 転送。
   エンカウント時のディスクアクセス前にBGMは停止されるため、ロード直後のデータは保持されます。
   ・パッチ11: 味方攻撃力・命中率読込 (18バイト: 0x362E〜0x363F)
   ・パッチ11: 味方攻撃力・命中率保存 (19バイト: 0x3640〜0x3652)
   ・パッチ13: 複数レベルアップループ (16バイト: 0x3653〜0x3662)
   ・パッチ14: 知性魔法威力反映・ディア系＆回復2倍対応 (50バイト: 0x3663〜0x3694)
   ・パッチ16: モンク素手防御力計算 (27バイト: 0x3695〜0x36AF)
   ・パッチ15: 敵毒ダメージ(2HP)＆リジェネレーション (80バイト: 0x36B0〜0x36FF)

3. バッファ初期化クリア範囲の縮小:
   0x8C66（ファイルオフセット 0x0C67）のクリア長を 0x02FF から 0x022D に縮小し、
   味方・敵バッファ（0x3400〜0x362D）のみを初期化対象とすることで 0x362E 以降を保護。

4. インライン修正 (BATTLE.COM):
   ・パッチ10: 睡眠麻痺時回避率0化＆攻撃力1.25倍計算 (0x9571〜0x958B, 27バイト枠)
   ・パッチ07: 敵睡眠起床判定の固定確率化 (0xBA08〜0xBA1A, 19バイト枠)
   ・パッチ05: 敵弱点属性の種族属性による上書き解除 (0x9C52〜0x9C57, 6バイト枠)

5. フィールド・会話・調査修正 (SMAP.COM):
   ・オンラク潜水艇老人のオーブ参照修正 (0x9448: 風0xC214 -> 水0xC213)
   ・クレセント湖12賢者の土オーブ判定修正 (0x9726: 00H -> 01H)
   ・4大祭壇の調査メッセージ判定修正 (0x8077〜0x808C: 22バイト枠内ロジック再構成)

6. 配置・マップデータ修正 (EXDATA1.COM / SUB05.MAP / BDATA.TBL):
   ・コーネリア城1F女性NPCの部屋属性修正 (EXDATA1.COM: 室内01 -> 室外00)
   ・滝の洞窟コウモリNPC初期Y座標修正 (EXDATA1.COM: 壁Y=3 -> 通路Y=4)
   ・ガイアの妖精の泉タイル復元 (SUB05.MAP: 38H -> BBH)
   ・ヒーラ効果値正常化 (BDATA.TBL: 0x02F9)
   ・シェイラ効果ルーチン正常化 (BDATA.TBL: 0x029C)
   ・ストライ効果ルーチン正常化 (BDATA.TBL: 0x0254)
-------------------------------------------------------------------------------
"""

import argparse
import os
import struct
import sys
import unicodedata
from typing import Dict, List, NamedTuple, Tuple

# MSX / Say DOS 関連定数
SECTOR_SIZE = 512
ROOT_DIR_START_SECTOR = 10
ROOT_DIR_END_SECTOR = 100
ROOT_DIR_ENTRY_SIZE = 16
STANDARD_DSK_SIZE = 720 * 1024  # 737,280 バイト (2DD 720KB)

# BATTLE.COM 実行時基準アドレス
BATTLE_LOAD_ADDR = 0x8000


class PatchEntry(NamedTuple):
    target_file: str
    file_offset: int
    expected_bytes: bytes
    patch_bytes: bytes
    description: str


def hex_to_bytes(hex_str: str) -> bytes:
    """空白区切りの16進数文字列をバイト列へ変換"""
    return bytes.fromhex(hex_str.replace(" ", ""))


def get_display_width(text: str) -> int:
    """全角文字を表示幅2、半角文字を表示幅1として文字列の視覚的な幅を算出"""
    return sum(2 if unicodedata.east_asian_width(c) in ("F", "W", "A") else 1 for c in text)


def pad_str(text: str, target_width: int, align: str = "<") -> str:
    """全角文字の表示幅を考慮して空白パディングを行う"""
    w = get_display_width(text)
    pad = max(0, target_width - w)
    if align == ">":
        return " " * pad + text
    return text + " " * pad


def is_same_path(path1: str, path2: str) -> bool:
    """2つのパスが同一ファイルを指しているかを判定"""
    if os.path.exists(path1) and os.path.exists(path2):
        try:
            return os.path.samefile(path1, path2)
        except (OSError, AttributeError):
            pass
    return os.path.normcase(os.path.abspath(path1)) == os.path.normcase(os.path.abspath(path2))


def validate_input_file(path: str) -> None:
    """入力ファイルの存在・属性・サイズ・権限を検証"""
    if not os.path.exists(path):
        raise FileNotFoundError(f"入力ファイルが見つかりません: {path}")

    if not os.path.isfile(path):
        raise IsADirectoryError(f"入力パスが通常ファイルではありません: {path}")

    if not os.access(path, os.R_OK):
        raise PermissionError(f"入力ファイルに対する読み取り権限がありません: {path}")

    file_size = os.path.getsize(path)
    if file_size == 0:
        raise ValueError(f"入力ファイルが空です (0 バイト): {path}")

    min_required_size = ROOT_DIR_END_SECTOR * SECTOR_SIZE
    if file_size < min_required_size:
        raise ValueError(
            f"ファイルサイズが小さすぎます ({file_size} バイト)。\n"
            f"  Say DOS のディレクトリ領域（セクタ100 / {min_required_size} バイト）を満たしていません。"
        )

    if file_size != STANDARD_DSK_SIZE:
        print(
            f"[警告] ファイルサイズ ({file_size} バイト) が標準的な MSX 2DD DSK イメージ "
            f"({STANDARD_DSK_SIZE} バイト) と異なります。",
            file=sys.stderr,
        )


def validate_output_path(input_path: str, output_path: str, force: bool = False) -> None:
    """出力先パスの妥当性・重複・書き込み権限を検証"""
    if os.path.isdir(output_path):
        raise IsADirectoryError(f"出力先パスが既存のディレクトリです: {output_path}")

    out_dir = os.path.dirname(os.path.abspath(output_path))
    if not os.path.exists(out_dir):
        raise FileNotFoundError(f"出力先ディレクトリが存在しません: {out_dir}")

    if not os.path.isdir(out_dir):
        raise NotADirectoryError(f"出力先の親パスがディレクトリではありません: {out_dir}")

    if not os.access(out_dir, os.W_OK):
        raise PermissionError(f"出力先ディレクトリに対する書き込み権限がありません: {out_dir}")

    if is_same_path(input_path, output_path) and not force:
        raise FileExistsError(
            f"入力ファイルと出力先ファイルが同一です: {output_path}\n"
            f"  誤操作による元イメージの破壊を防ぐため中断しました。\n"
            f"  別の出力先を指定するか、上書きしたい場合は --force (-f) オプションを指定してください。"
        )


def parse_saydos_directory(disk_bytes: bytes) -> Dict[str, Tuple[int, int]]:
    """Say DOS のルートディレクトリ（セクタ10〜99）を解析"""
    file_map: Dict[str, Tuple[int, int]] = {}

    for sector in range(ROOT_DIR_START_SECTOR, ROOT_DIR_END_SECTOR):
        sec_offset = sector * SECTOR_SIZE
        sec_data = disk_bytes[sec_offset : sec_offset + SECTOR_SIZE]
        entries_per_sector = len(sec_data) // ROOT_DIR_ENTRY_SIZE

        for e in range(entries_per_sector):
            entry_offset = e * ROOT_DIR_ENTRY_SIZE
            entry = sec_data[entry_offset : entry_offset + ROOT_DIR_ENTRY_SIZE]

            if all(b == entry[0] for b in entry):
                continue

            name = entry[0x0:0x8].decode("ascii", errors="replace").rstrip(" ")
            ext = entry[0x8:0xC].decode("ascii", errors="replace").rstrip(" ")
            full_name = name + ext

            start_sector = struct.unpack("<H", entry[0xC:0xE])[0]
            end_sector = struct.unpack("<H", entry[0xE:0x10])[0]

            file_map[full_name] = (start_sector, end_sector)

    return file_map


def build_patch_plan() -> List[PatchEntry]:
    """全パッチ定義を構築して返す"""
    patches: List[PatchEntry] = []

    # =========================================================================
    # 1. 外部テーブル修正 (BDATA.TBL)
    # =========================================================================

    # パッチ11: ストライ効果ルーチン番号の修正 (Temper Bug)
    # BDATA.TBL オフセット 0x0254: 攻撃力+命中率上昇(0DH) から 攻撃力上昇のみ(0BH) へ修正
    patches.append(
        PatchEntry(
            "BDATA.TBL",
            0x0254,
            hex_to_bytes("0D"),
            hex_to_bytes("0B"),
            "パッチ11: ストライ効果ルーチン修正 (攻撃力+命中率UP -> 攻撃力UPのみ)",
        )
    )
    
    # パッチ11: セーバー基礎命中率上昇値の修正 (SABR Accuracy Bug)
    # BDATA.TBL オフセット 0x0390: 命中上昇値 0(00H) から 10(0AH) へ修正
    patches.append(
        PatchEntry(
            "BDATA.TBL",
            0x0390,
            hex_to_bytes("00"),
            hex_to_bytes("0A"),
            "パッチ11: セーバー基礎命中率上昇値設定 (0 -> 10)",
        )
    )

    # パッチ08: ヒーラ効果値の適正化 (Healara Effectivity Bug)
    # BDATA.TBL オフセット 0x02F9: ヒーラ（HEL2）の効果値を 48(30H) から 24(18H) へ修正
    patches.append(
        PatchEntry(
            "BDATA.TBL",
            0x02F9,
            hex_to_bytes("30"),
            hex_to_bytes("18"),
            "パッチ08: ヒーラ（HEL2）効果値適正化 (48 -> 24)",
        )
    )

    # パッチ09: シェイラ効果ルーチン番号の修正 (LOK2 Effect Routine Bug)
    # BDATA.TBL オフセット 0x029C: 回避上昇ルーチン(10H) から 回避低下ルーチン(0EH) へ修正
    patches.append(
        PatchEntry(
            "BDATA.TBL",
            0x029C,
            hex_to_bytes("10"),
            hex_to_bytes("0E"),
            "パッチ09: シェイラ効果ルーチン番号修正 (回避上昇 -> 回避低下)",
        )
    )

    # =========================================================================
    # 2. BATTLE.COM インライン修正
    # =========================================================================

    # パッチ01: 逃走判定の対象キャラ参照修正 (Running Bug)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x33B9,
            hex_to_bytes("DD"),
            hex_to_bytes("FD"),
            "パッチ01: 逃走判定Lv参照ポインタ修正 (IX -> IY)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x33C2,
            hex_to_bytes("DD"),
            hex_to_bytes("FD"),
            "パッチ01: 逃走判定運参照ポインタ修正 (IX -> IY)",
        )
    )

    # パッチ02: 敵の味方全体魔法で自身を除外する判定の解除 (Enemy Magic All Allies Bug)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1B5C,
            hex_to_bytes("28 2A"),
            hex_to_bytes("00 00"),
            "パッチ02: 敵全体魔法で詠唱者自身を除外する分岐の解除",
        )
    )

    # パッチ03: 戦闘後ソート処理の生存判定修正 (Sort Bug)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0A4E,
            hex_to_bytes("FE 00"),
            hex_to_bytes("E6 03"),
            "パッチ03: 隊列ソート生存判定マスク修正 (比較対象2)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0A58,
            hex_to_bytes("FE 00"),
            hex_to_bytes("E6 03"),
            "パッチ03: 隊列ソート生存判定マスク修正 (比較対象1)",
        )
    )

    # パッチ04: 行動順シャッフル回数の増加 (Battle Order Bug)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0322,
            hex_to_bytes("11"),
            hex_to_bytes("40"),
            "パッチ04: 行動順シャッフル回数増加 (17回 -> 64回)",
        )
    )

    # パッチ05: 武器の属性・特効判定修正 (Weapon Data Bug)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1359,
            hex_to_bytes("43"),
            hex_to_bytes("46"),
            "パッチ05: 味方攻撃時の武器属性バッファ参照修正 (+43H -> +46H)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x135F,
            hex_to_bytes("44"),
            hex_to_bytes("47"),
            "パッチ05: 味方攻撃時の武器特効バッファ参照修正 (+44H -> +47H)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x13A5,
            hex_to_bytes("10"),
            hex_to_bytes("12"),
            "パッチ05: 敵弱点属性のロード先修正 (+10H -> +12H)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x13AB,
            hex_to_bytes("12"),
            hex_to_bytes("13"),
            "パッチ05: 敵種族属性のロード先修正 (+12H -> +13H)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1537,
            hex_to_bytes("0C"),
            hex_to_bytes("0D"),
            "パッチ05: 暗闇時の特効判定ジャンプ先調整",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1544,
            hex_to_bytes("C9"),
            hex_to_bytes("00"),
            "パッチ05: 特効判定手前の到達不能RETをNOP化",
        )
    )

    # パッチ05: 敵弱点属性の種族属性による上書き解除 (0x9C52〜0x9C57)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1C52,
            hex_to_bytes("DD 7E 13 32 16 A2"),
            hex_to_bytes("00 00 00 00 00 00"),
            "パッチ05: 敵弱点属性の種族属性による上書き解除 (NOP化)",
        )
    )

    # パッチ07: 敵睡眠起床判定の固定確率化 (Enemy Waking Bug / 0xBA08〜0xBA1A, 19B枠)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x3A08,
            hex_to_bytes("3E 50 CD CF 80 16 00 5F DD 6E 1B DD 66 1C CD E0 80 38 08"),
            hex_to_bytes("CD 85 50 FE 19 30 14 00 00 00 00 00 00 00 00 00 00 00 00"),
            "パッチ07: 敵睡眠起床判定の固定確率化 (HP依存廃止、約10%で起床)",
        )
    )

    # パッチ12: 魔法防御成長率の適正化 (Magic Defense Bug)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x07F9,
            hex_to_bytes("04"),
            hex_to_bytes("05"),
            "パッチ12: 魔法防御上昇値上限判定緩和 (4 -> 5)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0810,
            hex_to_bytes("03 02 03 02 01 01 03 02 03 02 01 01"),
            hex_to_bytes("02 02 01 02 03 03 02 02 04 02 03 03"),
            "パッチ12: ジョブ別魔法防御成長テーブル更新",
        )
    )

    # 戦闘バッファ初期化クリア範囲の縮小 (0x362E〜0x36FF 保護)
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0C67,
            hex_to_bytes("FF"),
            hex_to_bytes("2D"),
            "戦闘バッファ初期化クリア範囲縮小 (0x02FF -> 0x022D, 0x362E〜 保護)",
        )
    )

    # パッチ10: 睡眠麻痺時回避率0化＆攻撃力1.25倍計算 (27B枠インライン実装)
    inlined_patch10_bytes = hex_to_bytes(
        "3A 54 98 E6 30 28 14 AF 32 57 98 2A 6B 98 EB CB 3A CB 1B CB 3A CB 1B 19 22 6B 98"
    )
    patch10_orig_bytes = hex_to_bytes(
        "3A 54 98 E6 30 28 14 2A 6B 98 54 5D CB 3C CB 1D CB 3C CB 1D CD E9 80 32 6B 98 C9"
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1571,
            patch10_orig_bytes,
            inlined_patch10_bytes,
            "パッチ10: 睡眠麻痺時回避率0化＆攻撃力1.25倍計算 (27B枠インライン実装)",
        )
    )

    # =========================================================================
    # 3. 常駐領域A (0xBCDD〜0xBCFB, 31バイト / 35バイト枠)
    # =========================================================================

    patch06_code = hex_to_bytes("3A C8 BC B7 20 04 CD BC 9A C9 B7 C9")  # 12バイト
    patch07_code = hex_to_bytes("3A 1B A2 DD 77 0C 3A 17 A2 DD 77 10 3A 09 A2 DD 77 0B C9")  # 19バイト

    resident_a_block = patch06_code + patch07_code  # 31バイト
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x3CDD,
            b"\x00" * len(resident_a_block),
            resident_a_block,
            "常駐領域A直接配置: パッチ06 (12B) ＋ パッチ07 (19B) -> 0xBCDD〜0xBCFB",
        )
    )

    # 常駐領域Aへのフック
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x187D,
            hex_to_bytes("CD BC 9A"),
            hex_to_bytes("CD DD BC"),
            "パッチ06: アイテム沈黙チェック回避フック (0x987D -> 0xBCDD)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1CA7,
            hex_to_bytes("3A 1B A2 DD 77 0C C9"),
            hex_to_bytes("C3 E9 BC 00 00 00 00"),
            "パッチ07: 敵耐性＆命中率保存フック (0x9CA7 -> 0xBCE9)",
        )
    )

    # =========================================================================
    # 4. 常駐領域B (0x362E〜0x36FF, 210バイト / 210バイト枠)
    # =========================================================================

    # パッチ11 読込: 味方攻撃力・命中率読込 (18バイト: 0x362E〜0x363F)
    patch11_load_code = hex_to_bytes("3E 00 32 1A A2 DD 7E 20 32 1B A2 DD 7E 21 32 09 A2 C9")

    # パッチ11 保存: 味方攻撃力・命中率保存 (19バイト: 0x3640〜0x3652)
    patch11_save_code = hex_to_bytes("3A 15 A2 DD 77 23 3A 1B A2 DD 77 20 3A 09 A2 DD 77 21 C9")

    # パッチ13: 複数レベルアップループ (16バイト: 0x3653〜0x3662)
    patch13_code = hex_to_bytes("CD 1B 86 CD 4F 86 38 05 CD 7B 86 18 F3 C3 40 85")

    # パッチ14: 知性魔法威力反映・改定版 (50バイト: 0x3663〜0x3694)
    patch14_code = hex_to_bytes(
        "FD 7E 07 32 06 A2 3A D5 BC D6 80 38 24 47 3A C8 BC B7 20 1D "
        "78 0F 0F C6 12 6F 26 C0 46 3A 03 A2 FE 07 28 07 3D FE 02 30 "
        "08 CB 38 78 21 00 A2 86 77 C9"
    )

    # パッチ16: モンク素手防御力計算 (27バイト: 0x3695〜0x36AF)
    patch16_code = hex_to_bytes(
        "3A 13 89 B7 20 11 DD 7E 00 FE 02 28 07 FE 08 28 03 AF 18 03 DD 7E 26 DD 77 22 C9"
    )

    # パッチ15: 敵毒ダメージ(2HP)＆リジェネレーション処理 (80バイト: 0x36B0〜0x36FF)
    patch15_code = hex_to_bytes(
        "DD 21 20 35 01 00 09 DD 6E 04 DD 66 05 7C B5 28 2F DD CB 13 7E "
        "28 0B 23 23 DD 5E 1B DD 56 1C CD F0 80 38 01 EB DD CB 17 56 28 "
        "10 2B 2B 7C B7 FA E5 36 B5 20 06 C5 79 CD 89 BB C1 18 06 DD 75 "
        "04 DD 74 05 11 1E 00 DD 19 0C 10 BC FD E1 DD E1 C9"
    )

    # 常駐領域B用データブロック連結 (計210バイト == 210バイト枠)
    payload_362e = (
        patch11_load_code
        + patch11_save_code
        + patch13_code
        + patch14_code
        + patch16_code
        + patch15_code
    )
    assert len(payload_362e) == 210, f"常駐Bサイズ不整合: {len(payload_362e)} != 210"

    # 常駐領域Bへのフック
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1C0D,
            hex_to_bytes("3E 00 32 1A A2 C9"),
            hex_to_bytes("C3 2E 36 00 00 00"),
            "パッチ11: 味方攻撃力・命中率読込フック (0x9C0D -> 0x362E)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1D00,
            hex_to_bytes("3A 15 A2 DD 77 23 C9"),
            hex_to_bytes("C3 40 36 00 00 00 00"),
            "パッチ11: 味方攻撃力・命中率保存フック (0x9D00 -> 0x3640)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0538,
            hex_to_bytes("CD 4F 86 38 03 CD 7B 86"),
            hex_to_bytes("C3 53 36 00 00 00 00 00"),
            "パッチ13: 複数レベルアップ判定ループフック (0x8538 -> 0x3653)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x1AB5,
            hex_to_bytes("FD 7E 07 32 06 A2 C9"),
            hex_to_bytes("C3 63 36 00 00 00 00"),
            "パッチ14: 知性反映フック・ディア系＆回復2倍対応 (0x9AB5 -> 0x3663)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0964,
            hex_to_bytes("3A 13 89 DD 77 22 C9"),
            hex_to_bytes("C3 95 36 00 00 00 00"),
            "パッチ16: モンク素手防御力計算フック (0x8964 -> 0x3695)",
        )
    )
    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0504,
            hex_to_bytes("FD E1 DD E1 C9"),
            hex_to_bytes("C3 B0 36 00 00"),
            "パッチ15: 敵毒(2HP)＆リジェネ処理フック (0x8504 -> 0x36B0)",
        )
    )

    # =========================================================================
    # 5. 起動時転送処理 (0x8004 フック & 0xBD00 ローダー)
    # =========================================================================

    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x0004,
            hex_to_bytes("CD 94 73"),
            hex_to_bytes("CD 00 BD"),
            "起動時転送呼出 (0x8004: CALL 7394H -> CALL 0BD00H)",
        )
    )

    loader_bytes = hex_to_bytes("21 10 BD 11 2E 36 01 D2 00 ED B0 C3 94 73 00 00")  # 16バイト
    loader_and_payload = loader_bytes + payload_362e  # 計 226バイト

    patches.append(
        PatchEntry(
            "BATTLE.COM",
            0x3D00,
            b"\x00" * len(loader_and_payload),
            loader_and_payload,
            f"起動時転送ローダー＆パッチ実体ブロック格納 (0xBD00〜, 計 {len(loader_and_payload)}バイト)",
        )
    )

    # =========================================================================
    # 6. SMAP.COM 会話・フラグ・調査判定修正
    # =========================================================================

    # オンラク潜水艇前の老人のオーブ参照修正 (Dialogue Bug)
    # RAMアドレス 0x9448 (オフセット 0x1448): 0xC214(風) -> 0xC213(水)
    patches.append(
        PatchEntry(
            "SMAP.COM",
            0x1448,
            hex_to_bytes("3A 14 C2"),
            hex_to_bytes("3A 13 C2"),
            "会話フラグ: オンラク潜水艇前の老人のオーブ参照修正 (風0xC214 -> 水0xC213)",
        )
    )

    # クレセント湖12賢者の土オーブ判定修正 (Circle of Sages Bug)
    # RAMアドレス 0x9726 (オフセット 0x1726): CP 00H -> CP 01H
    patches.append(
        PatchEntry(
            "SMAP.COM",
            0x1726,
            hex_to_bytes("FE 00"),
            hex_to_bytes("FE 01"),
            "会話フラグ: クレセント湖12賢者の土オーブ判定修正 (未点灯00H -> 点灯01H)",
        )
    )

    # 4大祭壇の調査メッセージ不発の修正 (Nondescript Altars Bug)
    # RAMアドレス 0x8077〜0x808C (オフセット 0x0077〜0x008C, 22バイト枠)
    # 火・風の祭壇タイルの固定敵ビット(0x40)による除外を緩和
    patches.append(
        PatchEntry(
            "SMAP.COM",
            0x0077,
            hex_to_bytes("3A 59 C2 E6 C0 C0 3A 59 C2 E6 1E FE 0A C8 3A 59 C2 E6 1E FE 02 C8"),
            hex_to_bytes("3A 59 C2 E6 1E FE 18 30 08 B7 C0 3A 59 C2 E6 C0 C0 00 00 00 00 00"),
            "調査判定: 4大祭壇の調査メッセージ判定修正 (火・風祭壇の調査判定緩和)",
        )
    )

    # =========================================================================
    # 7. EXDATA1.COM NPC初期配置修正
    # =========================================================================

    # コーネリア城1Fの見えない女性 (Invisible Lady)
    # マップID 0x08, エントリ7: オフセット 0x0878 (部屋属性フラグ +0x08)
    patches.append(
        PatchEntry(
            "EXDATA1.COM",
            0x0878,
            hex_to_bytes("01"),
            hex_to_bytes("00"),
            "NPC配置: コーネリア城1F女性NPCの部屋属性修正 (室内01 -> 室外00)",
        )
    )

    # 滝の洞窟の壁コウモリ (Wall Bat)
    # マップID 0x12, エントリ1: コウモリNPCの初期Y座標修正 (Y=3 -> Y=4)
    patches.append(
        PatchEntry(
            "EXDATA1.COM",
            0x1213,
            hex_to_bytes("06"),
            hex_to_bytes("08"),
            "NPC配置: 滝の洞窟コウモリNPC初期ピクセルY座標修正 (Y=6 -> Y=8)",
        )
    )
    patches.append(
        PatchEntry(
            "EXDATA1.COM",
            0x121B,
            hex_to_bytes("03"),
            hex_to_bytes("04"),
            "NPC配置: 滝の洞窟コウモリNPC初期タイルY座標修正 (壁Y=3 -> 通路Y=4)",
        )
    )

    # =========================================================================
    # 8. SUB05.MAP マップタイル修正
    # =========================================================================

    # ガイアの泉タイルの復元 (Gaia Fairy Spring Tile)
    # 南側から話しかける正面タイル: オフセット 0x00B2 を水際タイル 0x38 から 泉タイル 0xBB へ変更
    patches.append(
        PatchEntry(
            "SUB05.MAP",
            0x00B2,
            hex_to_bytes("38"),
            hex_to_bytes("BB"),
            "マップタイル: ガイアの妖精の泉タイル復元 (通常タイル38 -> 会話可能泉タイルBB)",
        )
    )

    return patches


def print_memory_map() -> None:
    """メモリマップおよびパッチ対応表を表示"""
    print("=" * 78)
    print("【MSX2版 FF1 不具合修正 メモリ配置・パッチ構成】")
    print("=" * 78)
    print("1. BATTLE.COM 実行時メモリ設計:")
    print("  ・常駐領域A       : 0xBCDD - 0xBCFB (31バイト / 35バイト枠)")
    print("                       戦闘ワーク直後の空き領域。BATTLE.COM 内に直接格納。")
    print("  ・常駐領域B       : 0x362E - 0x36FF (210バイト / 210バイト枠)")
    print("                       戦闘バッファ直後の領域。0x8C66 のクリア長縮小により保護。")
    print("  ・インライン領域   : 0x9571 - 0x958B (27バイト枠: パッチ10 回避0化＆1.25倍)")
    print("                       0xBA08 - 0xBA1A (19バイト枠: パッチ07 敵睡眠起床判定)")
    print("                       0x9C52 - 0x9C57 (6バイト枠 : パッチ05 敵弱点属性保護)")
    print("  ・一時格納領域     : 0xBD00 - 0xBDE1 (226バイト)")
    print("                       BATTLE.COM 末尾。ロード直後 0x8004 から 0x362E へ転送。")
    print("-" * 78)
    print("2. 追加ルーチン・フック対応表 (BATTLE.COM):")
    print("  " + pad_str("フック元", 18) + " " + pad_str("分岐先", 10) + " " + pad_str("種別", 6) + " 対象処理")
    print(f"  {'-'*18} {'-'*10} {'-'*6} {'-'*40}")
    print(f"  {pad_str('0x987D (BATTLE)', 18)} {pad_str('0xBCDD', 10)} {pad_str('CALL', 6)} パッチ06: アイテム沈黙チェック回避")
    print(f"  {pad_str('0x9CA7 (BATTLE)', 18)} {pad_str('0xBCE9', 10)} {pad_str('JP', 6)} パッチ07: 敵耐性・命中率保存")
    print(f"  {pad_str('0x9C0D (BATTLE)', 18)} {pad_str('0x362E', 10)} {pad_str('JP', 6)} パッチ11: 味方攻撃力・命中率読込")
    print(f"  {pad_str('0x9D00 (BATTLE)', 18)} {pad_str('0x3640', 10)} {pad_str('JP', 6)} パッチ11: 味方攻撃力・命中率保存")
    print(f"  {pad_str('0x8538 (BATTLE)', 18)} {pad_str('0x3653', 10)} {pad_str('JP', 6)} パッチ13: 複数レベルアップループ")
    print(f"  {pad_str('0x9AB5 (BATTLE)', 18)} {pad_str('0x3663', 10)} {pad_str('JP', 6)} パッチ14: 知性反映 (ディア・回復2倍)")
    print(f"  {pad_str('0x8964 (BATTLE)', 18)} {pad_str('0x3695', 10)} {pad_str('JP', 6)} パッチ16: モンク素手防御力計算")
    print(f"  {pad_str('0x8504 (BATTLE)', 18)} {pad_str('0x36B0', 10)} {pad_str('JP', 6)} パッチ15: 敵毒＆リジェネ処理")
    print(f"  {pad_str('0x8004 (BATTLE)', 18)} {pad_str('0xBD00', 10)} {pad_str('CALL', 6)} 起動時転送ローダー呼出 (SP退避後)")
    print("-" * 78)
    print("3. フィールド・会話・マップ・配置修正一覧:")
    print("  " + pad_str("対象ファイル", 14) + " " + pad_str("オフセット", 12) + " 修正内容")
    print(f"  {'-'*14} {'-'*12} {'-'*48}")
    print(f"  {pad_str('SMAP.COM', 14)} {pad_str('0x1448', 12)} オンラク潜水艇前の老人のオーブ参照修正 (風 -> 水)")
    print(f"  {pad_str('SMAP.COM', 14)} {pad_str('0x1726', 12)} クレセント湖12賢者の土オーブ判定修正 (00H -> 01H)")
    print(f"  {pad_str('SMAP.COM', 14)} {pad_str('0x0077', 12)} 4大祭壇の調査メッセージ判定修正 (火・風祭壇)")
    print(f"  {pad_str('EXDATA1.COM', 14)} {pad_str('0x0878', 12)} コーネリア城1F女性NPCの部屋属性修正 (室内 -> 室外)")
    print(f"  {pad_str('EXDATA1.COM', 14)} {pad_str('0x1213/1B', 12)} 滝の洞窟コウモリNPC初期Y座標修正 (Y=3 -> Y=4)")
    print(f"  {pad_str('SUB05.MAP', 14)} {pad_str('0x00B2', 12)} ガイアの妖精の泉タイル復元 (通常水際 -> 泉タイル)")
    print(f"  {pad_str('BDATA.TBL', 14)} {pad_str('0x0254', 12)} ストライ効果ルーチン修正 (攻撃力UPのみ)")
    print(f"  {pad_str('BDATA.TBL', 14)} {pad_str('0x029C', 12)} シェイラ効果ルーチン修正 (回避低下)")
    print(f"  {pad_str('BDATA.TBL', 14)} {pad_str('0x02F9', 12)} ヒーラ効果値適正化 (48 -> 24)")
    print("=" * 78)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MSX2版『ファイナルファンタジー』DSKパッチツール (FF1J_Bugfixes 相当)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("input_dsk", help="入力DSKイメージファイルパス")
    parser.add_argument(
        "output_dsk",
        nargs="?",
        default=None,
        help="出力DSKイメージファイルパス（省略時は <元ファイル名>_patched.dsk）",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="出力ファイルが入力ファイルと同名の場合でも強制的に上書きする",
    )

    args = parser.parse_args()

    input_path = args.input_dsk
    if args.output_dsk:
        output_path = args.output_dsk
    else:
        root, ext = os.path.splitext(input_path)
        output_path = f"{root}_patched{ext}"

    # ファイル周りの検証
    try:
        validate_input_file(input_path)
        validate_output_path(input_path, output_path, force=args.force)
    except (
        FileNotFoundError,
        IsADirectoryError,
        NotADirectoryError,
        PermissionError,
        ValueError,
        FileExistsError,
    ) as e:
        print(f"[エラー] {e}", file=sys.stderr)
        sys.exit(1)

    # ディスクイメージ読み込み
    try:
        with open(input_path, "rb") as f:
            disk_data = bytearray(f.read())
    except OSError as e:
        print(
            f"[エラー] 入力ファイルの読み込みに失敗しました: {input_path}\n  詳細: {e}",
            file=sys.stderr,
        )
        sys.exit(1)

    print(f"ディスクイメージ読み込み: {input_path} ({len(disk_data)} バイト)")

    # ルートディレクトリ解析
    try:
        file_map = parse_saydos_directory(disk_data)
    except Exception as e:
        print(
            f"[エラー] Say DOS ディレクトリ領域の解析中に問題が発生しました: {e}",
            file=sys.stderr,
        )
        sys.exit(1)

    if not file_map:
        print(
            f"[エラー] ディスクイメージ内にファイルが1件も検出されませんでした。\n"
            f"  Say DOS 形式（MSX2版 FF1）のディスクイメージではないか、イメージが破損しています。",
            file=sys.stderr,
        )
        sys.exit(1)

    print(f"検出ファイル数: {len(file_map)} 件")

    # メモリマップ・修正概要表示
    print("\n")
    print_memory_map()
    print("\n")

    # パッチプランの構築
    patches = build_patch_plan()

    # 必要な対象ファイルの存在・セクタ整合性確認
    needed_files = set(entry.target_file for entry in patches)
    for fname in needed_files:
        if fname not in file_map:
            print(f"[エラー] ディスク内に必要なファイル '{fname}' が見つかりません。", file=sys.stderr)
            sys.exit(1)

        start_sec, _ = file_map[fname]
        file_dsk_offset = start_sec * SECTOR_SIZE
        if file_dsk_offset >= len(disk_data):
            print(
                f"[エラー] ファイル '{fname}' の開始位置 (セクタ: 0x{start_sec:04X}, オフセット: 0x{file_dsk_offset:06X}) が\n"
                f"  ディスクイメージの末尾 (0x{len(disk_data):06X}) を超えています。",
                file=sys.stderr,
            )
            sys.exit(1)

        print(f"  {fname:<12} 開始セクタ: 0x{start_sec:04X} (オフセット: 0x{file_dsk_offset:06X})")

    # 事前検証
    has_error = False
    resolved_patches: List[Tuple[int, bytes, str]] = []

    print("\nパッチ箇所の事前検証を実行中...")
    for idx, entry in enumerate(patches, start=1):
        start_sec, _ = file_map[entry.target_file]
        dsk_offset = (start_sec * SECTOR_SIZE) + entry.file_offset

        if len(entry.expected_bytes) != len(entry.patch_bytes):
            print(
                f"[エラー] パッチ定義サイズ不整合: #{idx} ({entry.description})\n"
                f"  期待サイズ: {len(entry.expected_bytes)}バイト, 生成サイズ: {len(entry.patch_bytes)}バイト",
                file=sys.stderr,
            )
            has_error = True
            continue

        if dsk_offset + len(entry.expected_bytes) > len(disk_data):
            print(
                f"[エラー] パッチ適用位置がディスク範囲を超過: #{idx} (DSKオフセット 0x{dsk_offset:06X})",
                file=sys.stderr,
            )
            has_error = True
            continue

        actual_bytes = bytes(disk_data[dsk_offset : dsk_offset + len(entry.expected_bytes)])

        if actual_bytes != entry.expected_bytes:
            if actual_bytes == entry.patch_bytes:
                status = "適用済み"
            else:
                status = "値不一致"
                has_error = True

            print(
                f"[{status}] #{idx:02d}: {entry.description}\n"
                f"  ファイル: {entry.target_file} + 0x{entry.file_offset:04X} (DSK: 0x{dsk_offset:06X})\n"
                f"  期待値: {entry.expected_bytes.hex(' ').upper()[:48]}\n"
                f"  実際値: {actual_bytes.hex(' ').upper()[:48]}",
                file=sys.stderr,
            )
        else:
            resolved_patches.append((dsk_offset, entry.patch_bytes, entry.description))

    if has_error:
        print("\n[中断] 変更前の値に不一致があったため、パッチ適用を中止しました。", file=sys.stderr)
        sys.exit(1)

    # パッチ書き込み（オンメモリ）
    print(f"\n検証が完了しました。書き換えを実行します... ({len(resolved_patches)} 件)")
    for dsk_offset, patch_bytes, desc in resolved_patches:
        disk_data[dsk_offset : dsk_offset + len(patch_bytes)] = patch_bytes
        print(f"  適用: 0x{dsk_offset:06X} [{len(patch_bytes):3d}バイト] - {desc}")

    # 出力ファイル保存
    is_same_file = is_same_path(input_path, output_path)

    try:
        with open(output_path, "wb") as f:
            f.write(disk_data)
        print(f"\n出力完了: パッチ適用済みディスクイメージを出力しました -> {output_path}")
    except OSError as e:
        print(
            f"[エラー] 出力ファイルの書き込みに失敗しました: {output_path}\n  詳細: {e}",
            file=sys.stderr,
        )
        if not is_same_file and os.path.exists(output_path):
            try:
                os.remove(output_path)
                print(f"  不完全な出力ファイルを削除しました: {output_path}", file=sys.stderr)
            except OSError:
                pass
        sys.exit(1)


if __name__ == "__main__":
    main()
