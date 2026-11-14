#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FF1_MSX_BugFix.py

MSX2版『ファイナルファンタジー』(マイクロキャビン移植)のDSKイメージに対し、
戦闘関連およびフィールド・マップ関連の不具合修正を適用するスクリプト。

処理フロー:
  1. インラインパッチ適用 (固定アドレスの修正およびフック配置先余剰枠の00初期化)
  2. マップパッチ適用 (SUB05.MAPを展開し、ガイアの泉タイルを置換して再圧縮格納)
  3. フックコード配置 (配置先が00であることを検証し、各配置アドレスを自動解決)
  4. フック元書き換え (解決されたアドレスに基づき CALL/JP 命令等を生成して書き込み)
"""

import argparse
import os
import struct
import sys
import unicodedata
from typing import Dict, List, NamedTuple, Optional, Tuple

SECTOR_SIZE = 512
ROOT_DIR_START_SECTOR = 10
ROOT_DIR_END_SECTOR = 100
ROOT_DIR_ENTRY_SIZE = 16
STANDARD_DSK_SIZE = 720 * 1024


# -----------------------------------------------------------------------------
# データ構造定義
# -----------------------------------------------------------------------------

class InlinePatch(NamedTuple):
    """固定アドレスのバイナリ書き換え定義"""
    target_file: str
    file_offset: int
    expected_bytes: bytes
    patch_bytes: bytes
    description: str


class HookCode(NamedTuple):
    """追加コード実体の定義"""
    code_id: str
    target_file: str
    code_bytes: bytes
    area_type: str          # "FIXED", "RESIDENT_A", "RESIDENT_B"
    fixed_offset: Optional[int]
    fixed_addr: Optional[int]
    description: str


class HookCall(NamedTuple):
    """フック呼び出し元の定義"""
    target_file: str
    file_offset: int
    expected_bytes: bytes
    target_code_id: str
    call_mode: str          # "CALL", "JP", "POISON_CALL", "LOAD_JP", "P07_CALL", "P11S_CALL", "P13_CALL", "ATK_HOOK", "MAG_HOOK"
    nop_count: int
    description: str


# -----------------------------------------------------------------------------
# ユーティリティ関数
# -----------------------------------------------------------------------------

def hex_to_bytes(hex_str: str) -> bytes:
    """空白区切りの16進数文字列をバイト列へ変換"""
    return bytes.fromhex(hex_str.replace(" ", ""))


def get_display_width(text: str) -> int:
    """全角文字を表示幅2、半角文字を表示幅1として文字列の幅を算出"""
    return sum(2 if unicodedata.east_asian_width(c) in ("F", "W", "A") else 1 for c in text)


def pad_str(text: str, target_width: int, align: str = "<") -> str:
    """表示幅を考慮して空白パディングを行う"""
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
        raise ValueError(f"ファイルサイズが小さすぎます ({file_size} バイト)。")

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
            f"  上書きする場合は --force (-f) を指定してください。"
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


# -----------------------------------------------------------------------------
# サブマップ展開・圧縮ルーチン (FC/MSX共通RLE形式)
# -----------------------------------------------------------------------------

def decompress_submap(compressed_data: bytes) -> bytearray:
    """
    サブマップ（64×64 = 4096タイル）のRLE圧縮ストリームを展開する。

    フォーマット仕様:
      - 最上位bit = 0 (0x00 - 0x7F): 単一タイルID
      - 最上位bit = 1 (0x80 - 0xFE): タイルID = (b & 0x7F)、次バイト = 連続数 (0なら256)
      - 0xFF: 終端マーカー
    """
    decompressed = bytearray()
    i = 0
    data_len = len(compressed_data)
    while len(decompressed) < 4096 and i < data_len:
        b = compressed_data[i]
        i += 1
        if b == 0xFF:
            break
        if b & 0x80:
            tile_id = b & 0x7F
            if i >= data_len:
                break
            count = compressed_data[i]
            i += 1
            if count == 0:
                count = 256
            decompressed.extend([tile_id] * count)
        else:
            decompressed.append(b)

    if len(decompressed) < 4096:
        decompressed.extend([0] * (4096 - len(decompressed)))
    elif len(decompressed) > 4096:
        decompressed = decompressed[:4096]

    return decompressed


def compress_submap(decompressed: bytes) -> bytes:
    """
    4096バイトの平文タイル配列をRLE圧縮ストリームへ変換する。
    末尾に終端マーカー (0xFF) を付加する。
    """
    assert len(decompressed) == 4096, "サブマップのサイズは4096バイトである必要があります。"
    out = bytearray()
    co = 0
    while co < 4096:
        this_run = decompressed[co]
        run_length = 0

        if this_run != 0x7F:
            while co < 4096 and decompressed[co] == this_run and run_length < 256:
                co += 1
                run_length += 1
        else:
            co += 1
            run_length = 1

        if run_length == 1:
            out.append(this_run)
        elif run_length == 255:
            out.append(this_run)
            out.append(this_run | 0x80)
            out.append(254)
        else:
            out.append(this_run | 0x80)
            out.append(0 if run_length == 256 else run_length)

    out.append(0xFF)
    return bytes(out)


def patch_gaia_fairy_spring(disk_data: bytearray, file_map: Dict[str, Tuple[int, int]]) -> None:
    """
    SUB05.MAP (ガイアの町) を展開し、妖精の泉の南側水際マス (X=45〜50, Y=19) を
    会話判定タイル 0x3B (59) に書き換えて再圧縮・格納する。
    """
    target_file = "SUB05.MAP"
    if target_file not in file_map:
        print(f"[エラー] ファイル '{target_file}' が見つかりません。", file=sys.stderr)
        sys.exit(1)

    start_sec, end_sec = file_map[target_file]
    sec_count = end_sec - start_sec + 1
    max_bytes = sec_count * SECTOR_SIZE
    dsk_offset = start_sec * SECTOR_SIZE

    raw_data = bytes(disk_data[dsk_offset : dsk_offset + max_bytes])
    decompressed = decompress_submap(raw_data)

    target_y = 19
    target_x_range = range(45, 51)  # X=45〜50 (6マス)
    patch_tile_id = 0x3B           # 会話判定タイルID (59)

    already_patched = all(
        decompressed[target_y * 64 + x] == patch_tile_id for x in target_x_range
    )
    if already_patched:
        print("  [適用済み] マップタイル: ガイアの妖精の泉タイル復元 (SUB05.MAP X=45〜50, Y=19)")
        return

    for x in target_x_range:
        decompressed[target_y * 64 + x] = patch_tile_id

    recompressed = compress_submap(decompressed)
    if len(recompressed) > max_bytes:
        print(
            f"[エラー] 再圧縮後のサイズ ({len(recompressed)} バイト) が "
            f"割り当て容量 ({max_bytes} バイト) を超過しました。",
            file=sys.stderr,
        )
        sys.exit(1)

    padded = recompressed + b"\x00" * (max_bytes - len(recompressed))
    disk_data[dsk_offset : dsk_offset + max_bytes] = padded
    print(
        f"  [適用] マップタイル: ガイアの妖精の泉タイル復元 "
        f"(SUB05.MAP 展開 -> X=45〜50, Y=19 をタイル0x3Bへ置換 -> 再圧縮 {len(recompressed)}/{max_bytes} バイト)"
    )


# -----------------------------------------------------------------------------
# パッチ計画の構築
# -----------------------------------------------------------------------------

def build_inline_patches() -> List[InlinePatch]:
    """Step 1: インラインパッチ群の定義"""
    p: List[InlinePatch] = []

    # 1. 外部テーブル修正 (BDATA.TBL)
    p.append(InlinePatch("BDATA.TBL", 0x0254, hex_to_bytes("0D"), hex_to_bytes("0B"), "パッチ11: ストライ効果ルーチン修正 (攻撃力UPのみ)"))
    p.append(InlinePatch("BDATA.TBL", 0x0390, hex_to_bytes("00"), hex_to_bytes("0A"), "パッチ11: セーバー基礎命中率上昇値設定 (0 -> 10)"))
    p.append(InlinePatch("BDATA.TBL", 0x02F9, hex_to_bytes("30"), hex_to_bytes("18"), "パッチ08: ヒーラ効果値適正化 (48 -> 24)"))
    p.append(InlinePatch("BDATA.TBL", 0x029C, hex_to_bytes("10"), hex_to_bytes("0E"), "パッチ09: シェイラ効果ルーチン番号修正 (回避低下)"))

    # 2. BATTLE.COM インライン修正
    p.append(InlinePatch("BATTLE.COM", 0x33B9, hex_to_bytes("DD"), hex_to_bytes("FD"), "パッチ01: 逃走判定Lv参照ポインタ修正 (IX -> IY)"))
    p.append(InlinePatch("BATTLE.COM", 0x33C2, hex_to_bytes("DD"), hex_to_bytes("FD"), "パッチ01: 逃走判定運参照ポインタ修正 (IX -> IY)"))
    p.append(InlinePatch("BATTLE.COM", 0x1B5C, hex_to_bytes("28 2A"), hex_to_bytes("00 00"), "パッチ02: 敵全体魔法で詠唱者自身を除外する分岐の解除"))
    p.append(InlinePatch("BATTLE.COM", 0x0A4E, hex_to_bytes("FE 00"), hex_to_bytes("E6 03"), "パッチ03: 隊列ソート生存判定マスク修正 (比較対象2)"))
    p.append(InlinePatch("BATTLE.COM", 0x0A58, hex_to_bytes("FE 00"), hex_to_bytes("E6 03"), "パッチ03: 隊列ソート生存判定マスク修正 (比較対象1)"))
    p.append(InlinePatch("BATTLE.COM", 0x0322, hex_to_bytes("11"), hex_to_bytes("40"), "パッチ04: 行動順シャッフル回数増加 (17回 -> 64回)"))

    # パッチ05: 武器データの+04H(属性)/+05H(特効)を戦闘バッファ+43H/+44Hへ格納し、攻撃読込側は元の+43H/+44Hを使用
    p.append(InlinePatch(
        "BATTLE.COM",
        0x1200,
        hex_to_bytes("DD 7E 07 FD 77 47 DD 7E 06 FD 77 46"),
        hex_to_bytes("DD 7E 05 FD 77 44 DD 7E 04 FD 77 43"),
        "パッチ05: 武器属性(+04H)・特効(+05H)を戦闘バッファ(+43H/+44H)へ格納",
    ))
    p.append(InlinePatch("BATTLE.COM", 0x13A5, hex_to_bytes("10"), hex_to_bytes("12"), "パッチ05: 敵弱点属性のロード先修正 (+10H -> +12H)"))
    p.append(InlinePatch("BATTLE.COM", 0x13AB, hex_to_bytes("12"), hex_to_bytes("13"), "パッチ05: 敵種族属性のロード先修正 (+12H -> +13H)"))
    p.append(InlinePatch("BATTLE.COM", 0x1537, hex_to_bytes("0C"), hex_to_bytes("0D"), "パッチ05: 暗闇時の特効判定ジャンプ先を調整"))
    p.append(InlinePatch("BATTLE.COM", 0x1544, hex_to_bytes("C9"), hex_to_bytes("00"), "パッチ05: 特効判定到達不能原因のRETを削除"))
    p.append(InlinePatch("BATTLE.COM", 0x1C52, hex_to_bytes("DD 7E 13 32 16 A2"), hex_to_bytes("00 00 00 00 00 00"), "パッチ05: 敵弱点属性の種族属性による上書き解除"))

    # モンク素手処理: 誤ってIX+46Hを参照していた箇所をIY+45H(クリティカル率: 武器あり>=1, 素手==0)参照へ修正
    p.append(InlinePatch("BATTLE.COM", 0x1228, hex_to_bytes("DD 7E 46"), hex_to_bytes("FD 7E 45"), "パッチ16: モンク素手判定を戦闘バッファクリティカル率(IY+45H)参照へ修正"))

    p.append(InlinePatch("BATTLE.COM", 0x0826, hex_to_bytes("46 DD 86 25 80"), hex_to_bytes("7E DD 86 25 00"), "パッチ12: 魔法防御上昇時のジョブID加算バグ修正"))
    p.append(InlinePatch("BATTLE.COM", 0x0835, hex_to_bytes("03 02 04 02 02 02 03 02 04 02 02 02"), hex_to_bytes("02 02 01 02 03 03 02 02 04 02 03 03"), "パッチ12: ジョブ別魔法防御成長テーブル更新"))

    # パッチ10: 睡眠麻痺時回避率0化＆攻撃力1.25倍計算 (27バイト枠インライン)
    patch10_orig = hex_to_bytes("3A 54 98 E6 30 28 14 2A 6B 98 54 5D CB 3C CB 1D CB 3C CB 1D CD E9 80 32 6B 98 C9")
    patch10_new  = hex_to_bytes("3A 54 98 E6 30 28 14 AF 32 57 98 2A 6B 98 EB CB 3A CB 1B CB 3A CB 1B 19 22 6B 98")
    p.append(InlinePatch("BATTLE.COM", 0x1571, patch10_orig, patch10_new, "パッチ10: 睡眠麻痺時回避率0化＆攻撃力1.25倍計算"))

    # パッチ07-W: 敵睡眠解除判定 (19バイト枠: 目覚めない場合はBA23Hへ、目覚める場合はBA1BHへ直行。余剰10Bを00初期化)
    p07w_orig = hex_to_bytes("3E 50 CD CF 80 16 00 5F DD 6E 1B DD 66 1C CD E0 80 38 08")
    p07w_new  = hex_to_bytes("CD 85 50 FE 19 30 14 18 0A 00 00 00 00 00 00 00 00 00 00")
    p.append(InlinePatch("BATTLE.COM", 0x3A08, p07w_orig, p07w_new, "パッチ07-W: 敵睡眠解除判定の固定確率化 (余剰枠00初期化)"))

    # 戦闘パラメータワーク初期化範囲縮小 (0x362E〜0x36FFを保護)
    p.append(InlinePatch("BATTLE.COM", 0x0C67, hex_to_bytes("FF"), hex_to_bytes("2D"), "戦闘バッファ初期化範囲縮小 (0x362E〜0x36FF保護)"))

    # 3. SMAP.COM
    # オンラクの老人(0x97EE)、クレセント湖の賢者(0x96EF)、4大祭壇の調査判定(0x8077)は
    # MSX2版移植時点で修正済みであるため、パッチ対象外とする。

    return p


def build_hook_codes(auto_target: bool = False) -> List[HookCode]:
    """Step 3: 追加コード実体（フックコード）の定義"""
    codes: List[HookCode] = []

    # -------------------------------------------------------------------------
    # タイプ1: 固定アドレス配置 (BATTLE.COM インライン余剰枠 0xBA11〜0xBA1A, 10バイト枠)
    # -------------------------------------------------------------------------
    # パッチ06: アイテム沈黙チェック回避 (8バイト)
    patch06_code = hex_to_bytes("3A C8 BC B7 C0 C3 BC 9A")
    assert len(patch06_code) == 8
    codes.append(HookCode("P06_MUTE", "BATTLE.COM", patch06_code, "FIXED", 0x3A11, 0xBA11, "パッチ06: アイテム沈黙チェック回避 (8B)"))

    # -------------------------------------------------------------------------
    # タイプ1-B: 固定アドレス配置 (MAIN.COM 末尾空き領域 0x7FA9〜0x7FFF, 87バイト枠)
    # ※ 0x7FA4〜0x7FA8 は OPLL 検出ワークのため保護し、0x7FA9 以降を使用する
    # -------------------------------------------------------------------------
    # 開始・ロード後補正ラッパー: CALL 7FB5H; JP 5591H (6バイト)
    main_init_wrap = hex_to_bytes("CD B5 7F C3 91 55")
    assert len(main_init_wrap) == 6
    codes.append(HookCode("MAIN_INIT_W", "MAIN.COM", main_init_wrap, "FIXED", 0x3FA9, 0x7FA9, "パッチ16: 開始後モンク補正ラッパー (6B)"))

    # 戦闘復帰後補正ラッパー: CALL 7FB5H; JP 4E9CH (6バイト)
    main_btl_wrap = hex_to_bytes("CD B5 7F C3 9C 4E")
    assert len(main_btl_wrap) == 6
    codes.append(HookCode("MAIN_BTL_W", "MAIN.COM", main_btl_wrap, "FIXED", 0x3FAF, 0x7FAF, "パッチ16: 戦闘後モンク補正ラッパー (6B)"))

    # モンク素手攻撃力(Lv*2)＆無防具防御力(Lv) 4人分補正サブルーチン (66バイト)
    # 0x7FB5〜0x7FF6: 装備4枠(+18H..+1BH, +1CH..+1FH)のbit7がすべて0なら素手/無防具として補正
    main_monk_code = hex_to_bytes(
        "DD 21 00 C0 06 04 DD 7E 00 FE 02 28 04 FE 08 20 20 "
        "C5 DD E5 E1 11 18 00 19 CD EE 7F 38 07 DD 7E 26 87 DD 77 20 "
        "CD EE 7F 38 06 DD 7E 26 DD 77 22 C1 "
        "11 40 00 DD 19 10 CE C9 "
        "06 04 AF B6 23 10 FC 07 C9"
    )
    assert len(main_monk_code) == 66
    codes.append(HookCode("MAIN_MONK", "MAIN.COM", main_monk_code, "FIXED", 0x3FB5, 0x7FB5, "パッチ16: MAIN側モンク素手・無防具補正 (66B)"))

    # -------------------------------------------------------------------------
    # タイプ1-C: 固定アドレス配置 (MENU.COM 末尾空き領域 0xADBA〜0xADFF, 70バイト枠)
    # -------------------------------------------------------------------------
    # メニュー攻撃力再計算: 武器合計0(0x8D44==0)かつモンク/スパモンなら Lv*2 (31バイト)
    menu_atk_code = hex_to_bytes(
        "3A 44 8D B7 20 0C DD 7E 00 FE 02 28 0C FE 08 28 08 "
        "AF DD 86 28 DD 77 20 C9 DD 7E 26 87 18 F6"
    )
    assert len(menu_atk_code) == 31
    codes.append(HookCode("MENU_ATK", "MENU.COM", menu_atk_code, "FIXED", 0x2DBA, 0xADBA, "パッチ16: MENU側モンク素手攻撃力 (31B)"))

    # メニュー防御力再計算: 防具合計0(0x8D44==0)かつモンク/スパモンなら Lv (27バイト)
    menu_def_code = hex_to_bytes(
        "3A 44 8D B7 20 0C DD 7E 00 FE 02 28 09 FE 08 28 05 "
        "AF DD 77 22 C9 DD 7E 26 18 F7"
    )
    assert len(menu_def_code) == 27
    codes.append(HookCode("MENU_DEF", "MENU.COM", menu_def_code, "FIXED", 0x2DD9, 0xADD9, "パッチ16: MENU側モンク無防具防御力 (27B)"))

    # -------------------------------------------------------------------------
    # タイプ2: 常駐領域A (BATTLE.COM 0xBCDD〜0xBCFF, 35バイト枠)
    # -------------------------------------------------------------------------
    # パッチ07: 敵耐性・命中率保存 (16バイト)
    patch07_code = hex_to_bytes("3A 17 A2 DD 77 10 3A 09 A2 DD 77 0B 3A 1B A2 C9")
    assert len(patch07_code) == 16
    codes.append(HookCode("P07_DISPEL", "BATTLE.COM", patch07_code, "RESIDENT_A", None, None, "パッチ07: 敵耐性・命中率保存 (16B)"))

    # パッチ11: 味方攻撃力・命中率保存 (16バイト)
    patch11_save = hex_to_bytes("3A 1B A2 DD 77 20 3A 09 A2 DD 77 21 3A 15 A2 C9")
    assert len(patch11_save) == 16
    codes.append(HookCode("P11_SAVE", "BATTLE.COM", patch11_save, "RESIDENT_A", None, None, "パッチ11: 味方攻撃力・命中率保存 (16B)"))

    # -------------------------------------------------------------------------
    # タイプ3: 常駐領域B (BATTLE.COM 0x362E〜0x36FF, 210バイト枠)
    # -------------------------------------------------------------------------
    # プレイヤー毒2ダメージ計算サブルーチン (11バイト)
    ply_poison_code = hex_to_bytes("2B 7C B5 37 C8 2B 7C B5 C8 23 C9")
    assert len(ply_poison_code) == 11
    codes.append(HookCode("P_POISON", "BATTLE.COM", ply_poison_code, "RESIDENT_B", None, None, "プレイヤー毒2ダメージ計算 (11B)"))

    # パッチ11: 味方攻撃力・命中率読込 (16バイト)
    patch11_load = hex_to_bytes("32 1A A2 DD 7E 20 32 1B A2 DD 7E 21 32 09 A2 C9")
    assert len(patch11_load) == 16
    codes.append(HookCode("P11_LOAD", "BATTLE.COM", patch11_load, "RESIDENT_B", None, None, "パッチ11: 味方攻撃力・命中率読込 (16B)"))

    # パッチ13: 複数レベルアップ連続ループ (12バイト)
    patch13_code = hex_to_bytes("CD 7B 86 CD 1B 86 CD 4F 86 30 F5 C9")
    assert len(patch13_code) == 12
    codes.append(HookCode("P13_LVUP", "BATTLE.COM", patch13_code, "RESIDENT_B", None, None, "パッチ13: 複数レベルアップループ (12B)"))

    # パッチ14: 知性反映・ディア系＆回復2倍 (40バイト)
    patch14_code = hex_to_bytes(
        "FD 7E 07 32 06 A2 3A C8 BC B7 C0 3A D5 BC D6 80 D8 "
        "DD 46 12 3A 03 A2 21 00 A2 FE 07 28 06 3D FE 02 D0 "
        "CB 38 7E 80 77 C9"
    )
    assert len(patch14_code) == 40
    codes.append(HookCode("P14_INTEL", "BATTLE.COM", patch14_code, "RESIDENT_B", None, None, "パッチ14: 知性威力反映 (40B)"))

    # パッチ15: 敵リジェネ単体版 (54バイト)
    regen_code = hex_to_bytes(
        "DD 21 20 35 06 09 DD 7E 13 07 30 1E DD 6E 04 DD 66 "
        "05 7C B5 28 14 23 23 DD 5E 1B DD 56 1C CD F0 80 38 "
        "01 EB DD 75 04 DD 74 05 11 1E 00 DD 19 10 D5 FD E1 "
        "DD E1 C9"
    )
    assert len(regen_code) == 54
    codes.append(HookCode("P15_REGEN", "BATTLE.COM", regen_code, "RESIDENT_B", None, None, "パッチ15: 敵リジェネレーション処理 (54B)"))

    if auto_target:
        # オートターゲット本体 (52バイト)
        auto_target_core = hex_to_bytes(
            "C5 D5 E5 3A D6 BC FE 09 30 25 5F 16 00 21 66 BC 19 "
            "7E FE FF 20 19 21 66 BC 06 09 0E 00 7E FE FF 20 09 "
            "23 0C 10 F7 E1 D1 C1 37 C9 79 32 D6 BC E1 D1 C1 B7 C9"
        )
        assert len(auto_target_core) == 52
        codes.append(HookCode("AUTO_TARGET", "BATTLE.COM", auto_target_core, "RESIDENT_B", None, None, "オートターゲット本体処理 (52B)"))

    return codes


def build_hook_calls(auto_target: bool = False) -> List[HookCall]:
    """Step 4: 呼び出し元フック（JP/CALL）の定義"""
    calls: List[HookCall] = []

    # プレイヤー毒2ダメージ呼出フック (0x04EA 〜 0x04EE, 5B枠: CALL P_POISON; JR C, 0x84FE)
    calls.append(HookCall("BATTLE.COM", 0x04EA, hex_to_bytes("2B 7C B5 28 0F"), "P_POISON", "POISON_CALL", 0, "プレイヤー毒2ダメージ呼出フック"))

    # パッチ06: アイテム沈黙チェック回避フック (0x187D, 3B枠: CALL P06_MUTE)
    calls.append(HookCall("BATTLE.COM", 0x187D, hex_to_bytes("CD BC 9A"), "P06_MUTE", "CALL", 0, "パッチ06: アイテム沈黙回避フック"))

    # パッチ07: 敵耐性・命中率保存フック (0x1CA7, 7B枠: CALL P07_DISPEL; LD (IX+0CH), A; RET)
    calls.append(HookCall("BATTLE.COM", 0x1CA7, hex_to_bytes("3A 1B A2 DD 77 0C C9"), "P07_DISPEL", "P07_CALL", 0, "パッチ07: 敵耐性・命中保存フック"))

    # パッチ11: 味方攻撃力・命中率保存フック (0x1D00, 7B枠: CALL P11_SAVE; LD (IX+23H), A; RET)
    calls.append(HookCall("BATTLE.COM", 0x1D00, hex_to_bytes("3A 15 A2 DD 77 23 C9"), "P11_SAVE", "P11S_CALL", 0, "パッチ11: 味方保存フック"))

    # パッチ11: 味方攻撃力・命中率読込フック (0x1C0D, 6B枠: LD A, 00H; JP P11_LOAD; NOP)
    calls.append(HookCall("BATTLE.COM", 0x1C0D, hex_to_bytes("3E 00 32 1A A2 C9"), "P11_LOAD", "LOAD_JP", 0, "パッチ11: 味方読込フック"))

    # パッチ13: 複数レベルアップフック (0x0538, 8B枠: CALL 864FH; JR C, 8540H; CALL P13_LVUP)
    calls.append(HookCall("BATTLE.COM", 0x0538, hex_to_bytes("CD 4F 86 38 03 CD 7B 86"), "P13_LVUP", "P13_CALL", 0, "パッチ13: 複数Lvアップフック"))

    # パッチ14: 知性反映フック (0x1AB5, 7B枠: JP P14_INTEL + NOP 4個)
    calls.append(HookCall("BATTLE.COM", 0x1AB5, hex_to_bytes("FD 7E 07 32 06 A2 C9"), "P14_INTEL", "JP", 4, "パッチ14: 知性反映フック"))

    # パッチ15: 敵リジェネフック (0x0504, 5B枠: JP P15_REGEN + NOP 2個)
    calls.append(HookCall("BATTLE.COM", 0x0504, hex_to_bytes("FD E1 DD E1 C9"), "P15_REGEN", "JP", 2, "パッチ15: 敵リジェネフック"))

    # パッチ16: MAIN.COM 開始後・戦闘後モンク補正フック
    calls.append(HookCall("MAIN.COM", 0x0069, hex_to_bytes("CD 91 55"), "MAIN_INIT_W", "JP", 0, "パッチ16: 開始・ロード後モンク補正フック"))
    calls.append(HookCall("MAIN.COM", 0x0422, hex_to_bytes("CD 9C 4E"), "MAIN_BTL_W", "JP", 0, "パッチ16: 戦闘復帰後モンク補正フック"))

    # パッチ16: MENU.COM 武器・防具メニュー後モンク補正フック
    calls.append(HookCall("MENU.COM", 0x0D59, hex_to_bytes("3A 44 8D DD 86 28 DD 77 20 C9"), "MENU_ATK", "JP", 7, "パッチ16: メニュー攻撃力再計算フック"))
    calls.append(HookCall("MENU.COM", 0x0D95, hex_to_bytes("3A 44 8D DD 77 22 C9"), "MENU_DEF", "JP", 4, "パッチ16: メニュー防御力再計算フック"))

    if auto_target:
        # オートターゲット: 味方「たたかう」前フック (0x32F5, 16バイト枠)
        calls.append(HookCall("BATTLE.COM", 0x32F5, hex_to_bytes("3A CB BC FE 00 C0 FD 7E 01 32 D6 BC CD 1E 93 C9"), "AUTO_TARGET", "ATK_HOOK", 0, "オートターゲット: 物理前フック"))
        # オートターゲット: 味方単体魔法前フック (0x1931, 29バイト枠)
        calls.append(HookCall(
            "BATTLE.COM",
            0x1931,
            hex_to_bytes("CD EE 83 3A D6 BC 16 00 5F 21 66 BC 19 7E FE FF CA D0 9D CD 13 9C CD 07 9D CD 71 9C C9"),
            "AUTO_TARGET",
            "MAG_HOOK",
            0,
            "オートターゲット: 魔法前フック",
        ))

    return calls


# -----------------------------------------------------------------------------
# メイン処理
# -----------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="MSX2版『ファイナルファンタジー』DSKパッチツール",
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
    parser.add_argument(
        "--auto-target",
        action="store_true",
        help="味方の攻撃・単体魔法時に死亡した敵が対象の場合ターゲットを自動変更する",
    )

    args = parser.parse_args()

    input_path = args.input_dsk
    if args.output_dsk:
        output_path = args.output_dsk
    else:
        root, ext = os.path.splitext(input_path)
        tag = "_autotarget" if args.auto_target else "_patched"
        output_path = f"{root}{tag}{ext}"

    try:
        validate_input_file(input_path)
        validate_output_path(input_path, output_path, force=args.force)
    except Exception as e:
        print(f"[エラー] {e}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(input_path, "rb") as f:
            disk_data = bytearray(f.read())
    except OSError as e:
        print(f"[エラー] 入力ファイルの読み込みに失敗しました: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"ディスクイメージ読み込み: {input_path} ({len(disk_data)} バイト)")

    file_map = parse_saydos_directory(disk_data)
    if not file_map:
        print("[エラー] ディレクトリ領域の解析に失敗しました。", file=sys.stderr)
        sys.exit(1)

    print(f"検出ファイル数: {len(file_map)} 件")

    # -------------------------------------------------------------------------
    # Step 1: インラインパッチの検証と適用 (固定オフセット書き換え)
    # -------------------------------------------------------------------------
    inline_patches = build_inline_patches()
    print(f"\n[Step 1] インラインパッチの適用 ({len(inline_patches)} 箇所)...")

    for patch in inline_patches:
        if patch.target_file not in file_map:
            print(f"[エラー] ファイル '{patch.target_file}' が見つかりません。", file=sys.stderr)
            sys.exit(1)

        start_sec, _ = file_map[patch.target_file]
        dsk_offset = (start_sec * SECTOR_SIZE) + patch.file_offset
        actual = bytes(disk_data[dsk_offset : dsk_offset + len(patch.expected_bytes)])

        if actual != patch.expected_bytes:
            if actual == patch.patch_bytes:
                print(f"  [適用済み] {patch.description}")
            else:
                print(
                    f"  [値不一致] {patch.description}\n"
                    f"    ファイル: {patch.target_file} + 0x{patch.file_offset:04X} (DSK: 0x{dsk_offset:06X})\n"
                    f"    期待値: {patch.expected_bytes.hex(' ').upper()}\n"
                    f"    実際値: {actual.hex(' ').upper()}",
                    file=sys.stderr,
                )
                sys.exit(1)
        else:
            disk_data[dsk_offset : dsk_offset + len(patch.patch_bytes)] = patch.patch_bytes
            print(f"  [適用] {patch.description}")

    # -------------------------------------------------------------------------
    # Step 2: マップパッチの適用 (ガイアの妖精の泉タイル復元)
    # -------------------------------------------------------------------------
    print("\n[Step 2] マップパッチの適用 (ガイアの妖精の泉)...")
    patch_gaia_fairy_spring(disk_data, file_map)

    # -------------------------------------------------------------------------
    # Step 3: フックコードの配置とアドレス自動解決
    # -------------------------------------------------------------------------
    hook_codes = build_hook_codes(auto_target=args.auto_target)
    symbol_table: Dict[str, int] = {}

    # 常駐領域A: BATTLE.COM メモリアドレス 0xBCDD〜0xBCFF (最大35B)
    resident_a_cur_addr = 0xBCDD
    resident_a_cur_offset = 0x3CDD
    resident_a_limit_addr = 0xBD00

    # 常駐領域B: BATTLE.COM メモリアドレス 0x362E〜0x36FF (最大210B)
    resident_b_cur_addr = 0x362E
    resident_b_payload = bytearray()
    resident_b_limit_addr = 0x3700

    print(f"\n[Step 3] フックコードの配置とアドレス解決 ({len(hook_codes)} ブロック)...")

    for code in hook_codes:
        if code.target_file not in file_map:
            print(f"[エラー] ファイル '{code.target_file}' が見つかりません。", file=sys.stderr)
            sys.exit(1)

        start_sec, _ = file_map[code.target_file]

        if code.area_type == "FIXED":
            assert code.fixed_offset is not None and code.fixed_addr is not None
            target_dsk_offset = (start_sec * SECTOR_SIZE) + code.fixed_offset
            dest_bytes = disk_data[target_dsk_offset : target_dsk_offset + len(code.code_bytes)]
            if not all(b == 0x00 for b in dest_bytes):
                print(f"[エラー] 固定配置先が 00 ではありません: {code.description}", file=sys.stderr)
                sys.exit(1)

            disk_data[target_dsk_offset : target_dsk_offset + len(code.code_bytes)] = code.code_bytes
            symbol_table[code.code_id] = code.fixed_addr
            print(f"  [配置:固定] {code.code_id:<12} -> 0x{code.fixed_addr:04X} [{len(code.code_bytes):2d}B] ({code.description})")

        elif code.area_type == "RESIDENT_A":
            code_len = len(code.code_bytes)
            if resident_a_cur_addr + code_len > resident_a_limit_addr:
                print(f"[エラー] 常駐領域Aの容量(35B)を超過しました: {code.description}", file=sys.stderr)
                sys.exit(1)

            target_dsk_offset = (start_sec * SECTOR_SIZE) + resident_a_cur_offset
            dest_bytes = disk_data[target_dsk_offset : target_dsk_offset + code_len]
            if not all(b == 0x00 for b in dest_bytes):
                print(f"[エラー] 常駐領域A配置先が 00 ではありません: {code.description}", file=sys.stderr)
                sys.exit(1)

            disk_data[target_dsk_offset : target_dsk_offset + code_len] = code.code_bytes
            symbol_table[code.code_id] = resident_a_cur_addr
            print(f"  [配置:常駐A] {code.code_id:<12} -> 0x{resident_a_cur_addr:04X} [{code_len:2d}B] ({code.description})")

            resident_a_cur_addr += code_len
            resident_a_cur_offset += code_len

        elif code.area_type == "RESIDENT_B":
            code_len = len(code.code_bytes)
            if resident_b_cur_addr + code_len > resident_b_limit_addr:
                print(f"[エラー] 常駐領域Bの容量(210B)を超過しました: {code.description}", file=sys.stderr)
                sys.exit(1)

            symbol_table[code.code_id] = resident_b_cur_addr
            resident_b_payload.extend(code.code_bytes)
            print(f"  [配置:常駐B] {code.code_id:<12} -> 0x{resident_b_cur_addr:04X} [{code_len:2d}B] ({code.description})")

            resident_b_cur_addr += code_len

    pad_a_len = resident_a_limit_addr - resident_a_cur_addr
    print(f"  -> 常駐領域A 使用量: {35 - pad_a_len}/35 バイト (空き: {pad_a_len} バイト)")

    pad_b_len = 210 - len(resident_b_payload)
    resident_b_payload.extend(b"\x00" * pad_b_len)
    print(f"  -> 常駐領域B 使用量: {210 - pad_b_len}/210 バイト (空き: {pad_b_len} バイト)")

    # 起動時転送ローダーの書き込み (BATTLE.COM 0x3D00〜, メモリ 0xBD00〜)
    start_sec, _ = file_map["BATTLE.COM"]
    hook_8004_dsk = (start_sec * SECTOR_SIZE) + 0x0004
    disk_data[hook_8004_dsk : hook_8004_dsk + 3] = hex_to_bytes("CD 00 BD")

    loader_bytes = hex_to_bytes("21 10 BD 11 2E 36 01 D2 00 ED B0 C3 94 73 00 00")
    full_loader_block = loader_bytes + resident_b_payload

    loader_dsk_offset = (start_sec * SECTOR_SIZE) + 0x3D00
    dest_loader = disk_data[loader_dsk_offset : loader_dsk_offset + len(full_loader_block)]
    if not all(b == 0x00 for b in dest_loader):
        print("[エラー] ローダー配置先 (0x3D00) が 00 ではありません。", file=sys.stderr)
        sys.exit(1)

    disk_data[loader_dsk_offset : loader_dsk_offset + len(full_loader_block)] = full_loader_block
    print(f"  [配置:ローダー] 起動時転送ブロック格納 (0xBD00〜, 計 {len(full_loader_block)} バイト)")

    # -------------------------------------------------------------------------
    # Step 4: フック元（呼び出し元）の書き換え
    # -------------------------------------------------------------------------
    hook_calls = build_hook_calls(auto_target=args.auto_target)
    print(f"\n[Step 4] フック元呼び出し命令の生成と書き込み ({len(hook_calls)} 箇所)...")

    for call in hook_calls:
        if call.target_file not in file_map:
            print(f"[エラー] ファイル '{call.target_file}' が見つかりません。", file=sys.stderr)
            sys.exit(1)

        if call.target_code_id not in symbol_table:
            print(f"[エラー] シンボル '{call.target_code_id}' が解決されていません。", file=sys.stderr)
            sys.exit(1)

        target_addr = symbol_table[call.target_code_id]

        if call.call_mode == "CALL":
            call_bytes = bytes([0xCD, target_addr & 0xFF, (target_addr >> 8) & 0xFF]) + (b"\x00" * call.nop_count)
        elif call.call_mode == "JP":
            call_bytes = bytes([0xC3, target_addr & 0xFF, (target_addr >> 8) & 0xFF]) + (b"\x00" * call.nop_count)
        elif call.call_mode == "POISON_CALL":
            call_bytes = bytes([0xCD, target_addr & 0xFF, (target_addr >> 8) & 0xFF, 0x38, 0x0F])
        elif call.call_mode == "P07_CALL":
            call_bytes = bytes([0xCD, target_addr & 0xFF, (target_addr >> 8) & 0xFF, 0xDD, 0x77, 0x0C, 0xC9])
        elif call.call_mode == "P11S_CALL":
            call_bytes = bytes([0xCD, target_addr & 0xFF, (target_addr >> 8) & 0xFF, 0xDD, 0x77, 0x23, 0xC9])
        elif call.call_mode == "LOAD_JP":
            call_bytes = bytes([0x3E, 0x00, 0xC3, target_addr & 0xFF, (target_addr >> 8) & 0xFF, 0x00])
        elif call.call_mode == "P13_CALL":
            call_bytes = bytes([0xCD, 0x4F, 0x86, 0x38, 0x03, 0xCD, target_addr & 0xFF, (target_addr >> 8) & 0xFF])
        elif call.call_mode == "ATK_HOOK":
            call_bytes = (
                hex_to_bytes("B7 C0 FD 7E 01 32 D6 BC CD")
                + struct.pack("<H", target_addr)
                + hex_to_bytes("CD 1E 93 C9 00")
            )
        elif call.call_mode == "MAG_HOOK":
            call_bytes = (
                hex_to_bytes("CD")
                + struct.pack("<H", target_addr)
                + hex_to_bytes("DA D0 9D CD EE 83 CD 13 9C CD 07 9D CD 71 9C C9")
                + (b"\x00" * 10)
            )
        else:
            raise ValueError(f"未定義の呼出種別: {call.call_mode}")

        assert len(call_bytes) == len(call.expected_bytes), (
            f"サイズ不整合: {call.description} "
            f"({len(call_bytes)} != {len(call.expected_bytes)})"
        )

        start_sec, _ = file_map[call.target_file]
        dsk_offset = (start_sec * SECTOR_SIZE) + call.file_offset

        actual = bytes(disk_data[dsk_offset : dsk_offset + len(call.expected_bytes)])
        if actual != call.expected_bytes:
            print(
                f"[エラー] フック元期待値不一致: {call.description}\n"
                f"  期待値: {call.expected_bytes.hex(' ').upper()}\n"
                f"  実際値: {actual.hex(' ').upper()}",
                file=sys.stderr,
            )
            sys.exit(1)

        disk_data[dsk_offset : dsk_offset + len(call_bytes)] = call_bytes
        print(f"  [フック] {call.description} -> 0x{target_addr:04X} [{len(call_bytes):2d}B]")

    # -------------------------------------------------------------------------
    # 出力
    # -------------------------------------------------------------------------
    try:
        with open(output_path, "wb") as f:
            f.write(disk_data)
        print(f"\n書き換え完了: パッチ適用済みディスクイメージを出力しました -> {output_path}")
    except OSError as e:
        print(f"[エラー] 出力ファイルの書き込みに失敗しました: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
