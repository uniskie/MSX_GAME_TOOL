#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
FFSayDosTool: MSX2版『ファイナルファンタジー』Say DOS ディスクイメージ操作ツール

MSX2版『ファイナルファンタジー』（マイクロキャビン移植）の独自ファイルシステム
「Say DOS」形式のディスクイメージ（DSK: 2DD 720KB）から、ファイル抽出・解析、
および編集後リソースからのDSK再構築を行います。
"""

import argparse
import json
import os
import struct
import sys
import unicodedata
from typing import Dict, List, Optional, Tuple

# MSX 2DD ディスクおよび Say DOS 関連定数
SECTOR_SIZE = 0x200                 # セクタサイズ: 512バイト
TOTAL_SECTORS_2DD = 1440            # 2DD 720KB 総セクタ数 (80シリンダ×2面×9セクタ)
DISK_SIZE_2DD = 0xB4000             # 2DD 720KB 総容量 (1440セクタ × 512B = 737,280バイト)

ROOT_DIR_ENTRY_SIZE = 0x10          # ルートディレクトリエントリ長: 16バイト
ROOT_DIR_START_SECTOR = 10          # ルートディレクトリ開始セクタ (セクタ 10 = 0x000A)
SECTOR_FILE_START = 0x64            # ファイルデータ配置開始セクタ (セクタ 100 = 0x0064)
TOTAL_ROOT_DIR_ENTRIES = 2880       # ディレクトリエントリ総数 (90セクタ × 32エントリ)

# システムブート領域 (固定配置)
SYSTEM_BOOT_START = 0x0000          # IPL / ブートローダー開始セクタ
SYSTEM_BOOT_END = 0x000A            # IPL / ブートローダー終了セクタ (排他: 0x0000〜0x0009 / 10セクタ / 5,120B)
SYSTEM_BOOT_FILENAME = "SYSTEM_BOOT.BIN"

# 戦闘システム用固定データ領域のデフォルトパラメータ
DEFAULT_BATTLE_DATA_START = 0x044C  # オリジナル版の戦闘データ開始セクタ (セクタ 1100 = 0x044C)
DEFAULT_BATTLE_DATA_SECTORS = 245   # 戦闘データセクタ数 (125,440バイト ÷ 512 = 245セクタ)
DEFAULT_BATTLE_POINTER_OFFSET = 0x0F6C  # BATTLE.COM 内の戦闘セクタ番号格納オフセット
BATTLE_DATA_FILENAME = "BATTLE_DATA.BIN"

# 敵キャラ画像読み込みルーチンの検証用シグネチャ (BATTLE.COM +0x0F56 / 実行アドレス 0x8F56)
# AND #7F (E6 7F), SLA A (CB 27), LD IX, nn (DD 21), LD E, (IX+0) (DD 5E 00), LD HL, nn (21), LD B, (IX+1) (DD 46 01)
BATTLE_ROUTINE_OFFSET = 0x0F56
BATTLE_ROUTINE_SIG_HEAD = bytes([
    0xE5, 0xDD, 0xE5, 0xFD, 0xE5,  # PUSH HL, PUSH IX, PUSH IY
    0xE6, 0x7F,                    # AND #7F (0x00〜0x7F / 128体マスク)
    0xCB, 0x27,                    # SLA A   (1エントリ2バイト)
    0x16, 0x00, 0x5F,              # LD D, 0 / LD E, A
    0xDD, 0x21,                    # LD IX, table_addr
])
BATTLE_ROUTINE_SIG_MID = bytes([
    0xDD, 0x19,                    # ADD IX, DE
    0xDD, 0x5E, 0x00,              # LD E, (IX+#00)
    0x21,                          # LD HL, start_sector
])
BATTLE_ROUTINE_SIG_TAIL = bytes([
    0x19,                          # ADD HL, DE
    0xEB,                          # EX DE, HL
    0xDD, 0x46, 0x01,              # LD B, (IX+#01)
])

ENEMY_COUNT = 128                   # 敵キャラ総数 (0x00〜0x7F)
MAX_RELATIVE_SECTORS = 255          # 8bitセクタオフセットの上限

ROOT_DIRECTORY_FILE = "root_directory.json"
SECTOR_MAP_FILE = "sector_map.json"
BATTLE_TABLE_FILE = "battle_table.json"
FOLDER_FILES = "files"
FOLDER_SECTORS = "sectors"
FOLDER_UNALLOCATED = "unallocated"
FOLDER_BATTLE = "battle"


def parse_hex_or_int(val) -> int:
    """10進数値または16進数文字列（0x..., $...）を整数値へ変換"""
    if isinstance(val, int):
        return val
    if isinstance(val, str):
        val = val.strip()
        if val.startswith(("0x", "0X")):
            return int(val, 16)
        if val.startswith("$"):
            return int(val[1:], 16)
        return int(val)
    return 0


class SayDosRootDirectory:
    """Say DOS ルートディレクトリエントリ (16バイト)"""

    def __init__(
        self,
        file_id: int = 0,
        file_name: str = "",
        file_ext: str = "",
        start_sector: int = 0,
        end_sector: int = 0,
        is_empty: bool = True,
        byte_fill: int = 0x00,
    ):
        self.file_id = file_id
        self.file_name = file_name
        self.file_ext = file_ext
        self.start_sector = start_sector
        self.end_sector = end_sector
        self.is_empty = is_empty
        self.byte_fill = byte_fill

    @property
    def file(self) -> str:
        return self.file_name + self.file_ext

    @property
    def size_in_sectors(self) -> int:
        if self.is_empty:
            return 1
        return (self.end_sector - self.start_sector) + 1

    @classmethod
    def from_bytes(cls, entry_bytes: bytes, file_id: int = 0) -> "SayDosRootDirectory":
        """16バイトの生データからディレクトリエントリを解析"""
        if len(entry_bytes) != ROOT_DIR_ENTRY_SIZE:
            raise ValueError(f"ディレクトリエントリ長が不正です: {len(entry_bytes)}バイト (規定: 16バイト)")

        first_byte = entry_bytes[0]
        # 全16バイトが同一値の場合は空エントリ（未使用領域）
        is_empty = all(b == first_byte for b in entry_bytes)

        if is_empty:
            return cls(file_id=file_id, is_empty=True, byte_fill=first_byte)

        # ファイル名 (8バイト) + 拡張子 (4バイト: 通常 '.' を含む)
        file_name = entry_bytes[0x0:0x8].decode("ascii", errors="replace").rstrip(" ")
        file_ext = entry_bytes[0x8:0xC].decode("ascii", errors="replace").rstrip(" ")
        start_sector = struct.unpack("<H", entry_bytes[0xC:0xE])[0]
        end_sector = struct.unpack("<H", entry_bytes[0xE:0x10])[0]

        return cls(
            file_id=file_id,
            file_name=file_name,
            file_ext=file_ext,
            start_sector=start_sector,
            end_sector=end_sector,
            is_empty=False,
            byte_fill=0x00,
        )

    def to_bytes(self) -> bytes:
        """16バイトの生ディレクトリエントリを生成"""
        if self.is_empty:
            return bytes([self.byte_fill]) * ROOT_DIR_ENTRY_SIZE

        # ファイル名幹 (8バイト・空白パディング)
        name_bytes = self.file_name.encode("ascii", errors="replace").ljust(8, b" ")[:8]
        # 拡張子 (4バイト・空白パディング)
        ext_str = self.file_ext
        if ext_str and not ext_str.startswith("."):
            ext_str = "." + ext_str
        ext_bytes = ext_str.encode("ascii", errors="replace").ljust(4, b" ")[:4]

        start_bytes = struct.pack("<H", self.start_sector)
        end_bytes = struct.pack("<H", self.end_sector)

        return name_bytes + ext_bytes + start_bytes + end_bytes

    def to_dict(self) -> dict:
        """JSONシリアライズ用の辞書を作成"""
        return {
            "FileId": self.file_id,
            "FileIdHex": f"0x{self.file_id:02X}",
            "FileName": self.file_name if not self.is_empty else None,
            "FileExt": self.file_ext if not self.is_empty else None,
            "StartSector": f"0x{self.start_sector:04X}",
            "EndSector": f"0x{self.end_sector:04X}",
            "SizeInSectors": f"0x{self.size_in_sectors:02X}",
            "IsEmpty": self.is_empty,
            "ByteFill": f"0x{self.byte_fill:02X}",
        }

    @classmethod
    def from_dict(cls, data: dict, default_id: int = 0) -> "SayDosRootDirectory":
        """JSON辞書データからインスタンスを復元"""
        is_empty = data.get("IsEmpty", False)

        file_id_val = data.get("FileId")
        if file_id_val is None:
            file_id_val = data.get("FileIdHex", default_id)
        file_id = parse_hex_or_int(file_id_val)

        byte_fill = parse_hex_or_int(data.get("ByteFill", "0x00"))
        if is_empty:
            return cls(file_id=file_id, is_empty=True, byte_fill=byte_fill)

        file_name = data.get("FileName") or ""
        file_ext = data.get("FileExt") or ""
        start_sector = parse_hex_or_int(data.get("StartSector", 0))
        end_sector = parse_hex_or_int(data.get("EndSector", 0))

        return cls(
            file_id=file_id,
            file_name=file_name,
            file_ext=file_ext,
            start_sector=start_sector,
            end_sector=end_sector,
            is_empty=False,
            byte_fill=byte_fill,
        )


def verify_and_parse_battle_routine(
    com_bytes: bytes,
) -> Tuple[bool, Optional[int], Optional[int]]:
    """
    BATTLE.COM の敵画像読み込みルーチンのマシン語コードを照合・検証し、
    先頭セクタ番号とテーブルのファイル内オフセットを取得する。
    戻り値: (検証成功フラグ, 先頭セクタ番号, テーブルオフセット)
    """
    if len(com_bytes) < BATTLE_ROUTINE_OFFSET + 0x30:
        return False, None, None

    ptr = BATTLE_ROUTINE_OFFSET
    # 先頭シグネチャの照合 (AND #7F, SLA A, LD IX 等)
    if com_bytes[ptr : ptr + len(BATTLE_ROUTINE_SIG_HEAD)] != BATTLE_ROUTINE_SIG_HEAD:
        return False, None, None
    ptr += len(BATTLE_ROUTINE_SIG_HEAD)

    # テーブルアドレス (16bit) の取得
    table_vaddr = struct.unpack("<H", com_bytes[ptr : ptr + 2])[0]
    ptr += 2

    # 中間シグネチャの照合 (LD E, (IX+0), LD HL 等)
    if com_bytes[ptr : ptr + len(BATTLE_ROUTINE_SIG_MID)] != BATTLE_ROUTINE_SIG_MID:
        return False, None, None
    ptr += len(BATTLE_ROUTINE_SIG_MID)

    # 先頭セクタ番号 (16bit) の取得
    start_sector = struct.unpack("<H", com_bytes[ptr : ptr + 2])[0]
    ptr += 2

    # 末尾シグネチャの照合 (LD B, (IX+1) 等)
    if com_bytes[ptr : ptr + len(BATTLE_ROUTINE_SIG_TAIL)] != BATTLE_ROUTINE_SIG_TAIL:
        return False, None, None

    # ロードアドレス 0x8000 に基づいてファイル内オフセットを算出
    # (実行アドレス 0x8F56 - ファイルオフセット 0x0F56 = 0x8000)
    table_offset = table_vaddr - 0x8000

    if not (0 <= table_offset <= len(com_bytes) - (ENEMY_COUNT * 2)):
        return False, None, None

    return True, start_sector, table_offset


def build_sector_map(
    sectors: List[bytes],
    rd_table: List[SayDosRootDirectory],
    battle_start: int,
    battle_end: int,
) -> Tuple[List[str], List[dict], List[Tuple[int, int]]]:
    """全セクタの占有状況を解析し、セクタマップおよび未割り当て区間リストを生成"""
    total_sectors = len(sectors)
    sector_occupancy = ["FREE"] * total_sectors

    # システムブート領域 (セクタ 0x0000 - 0x0009)
    for s in range(min(SYSTEM_BOOT_START, total_sectors), min(SYSTEM_BOOT_END, total_sectors)):
        sector_occupancy[s] = "SYSTEM_BOOT"

    # ディレクトリ領域 (セクタ 0x000A - 0x0063)
    for s in range(min(ROOT_DIR_START_SECTOR, total_sectors), min(SECTOR_FILE_START, total_sectors)):
        sector_occupancy[s] = "ROOT_DIRECTORY"

    # ルートディレクトリ登録ファイル
    for entry in rd_table:
        if not entry.is_empty:
            start = entry.start_sector
            end = entry.end_sector
            for s in range(start, min(end + 1, total_sectors)):
                sector_occupancy[s] = f"FILE:{entry.file}"

    # 戦闘システム領域 (指定または自動検出されたセクタ範囲)
    for s in range(min(battle_start, total_sectors), min(battle_end, total_sectors)):
        if sector_occupancy[s] == "FREE":
            sector_occupancy[s] = "BATTLE_DATA"

    ranges = []
    unallocated_ranges: List[Tuple[int, int]] = []

    cur_type = sector_occupancy[0]
    cur_start = 0

    for s in range(1, total_sectors):
        if sector_occupancy[s] != cur_type:
            cur_end = s - 1
            sec_count = cur_end - cur_start + 1

            raw_chunk = b"".join(sectors[cur_start : cur_end + 1])
            is_blank = all(b == raw_chunk[0] for b in raw_chunk) and (raw_chunk[0] in (0x00, 0xFF))

            range_info = {
                "start_sector": f"0x{cur_start:04X}",
                "end_sector": f"0x{cur_end:04X}",
                "sector_count": sec_count,
                "type": cur_type,
                "is_blank": is_blank,
            }
            ranges.append(range_info)

            if cur_type == "FREE":
                unallocated_ranges.append((cur_start, cur_end))

            cur_type = sector_occupancy[s]
            cur_start = s

    cur_end = total_sectors - 1
    sec_count = cur_end - cur_start + 1
    raw_chunk = b"".join(sectors[cur_start : cur_end + 1])
    is_blank = all(b == raw_chunk[0] for b in raw_chunk) and (raw_chunk[0] in (0x00, 0xFF))
    range_info = {
        "start_sector": f"0x{cur_start:04X}",
        "end_sector": f"0x{cur_end:04X}",
        "sector_count": sec_count,
        "type": cur_type,
        "is_blank": is_blank,
    }
    ranges.append(range_info)
    if cur_type == "FREE":
        unallocated_ranges.append((cur_start, cur_end))

    return sector_occupancy, ranges, unallocated_ranges


def get_display_width(text: str) -> int:
    """全角文字（East Asian Width）を考慮した端末表示幅を算出"""
    width = 0
    for ch in text:
        w = unicodedata.east_asian_width(ch)
        if w in ("F", "W", "A"):
            width += 2
        else:
            width += 1
    return width


def pad_display_width(text: str, width: int, align: str = "<") -> str:
    """表示幅に基づいて空白パディングを行う"""
    disp_w = get_display_width(text)
    pad_len = max(0, width - disp_w)
    if align == ">":
        return (" " * pad_len) + text
    return text + (" " * pad_len)


def show_progress_bar(current: int, total: int, prefix: str = "", bar_length: int = 30) -> None:
    """復帰制御コード (\r) を用いて同一行に進捗バーを表示"""
    percent = (current / total) * 100.0 if total > 0 else 100.0
    filled = int(bar_length * current // total) if total > 0 else bar_length
    bar = "=" * filled + "-" * (bar_length - filled)
    sys.stdout.write(f"\r{prefix} [{bar}] {current:4d}/{total:4d} ({percent:5.1f}%)")
    sys.stdout.flush()
    if current >= total:
        sys.stdout.write("\n")
        sys.stdout.flush()


def cmd_dump(
    disk_image_path: str,
    out_folder: str,
    dump_files: bool = True,
    dump_sectors: bool = False,
    dump_unallocated: bool = False,
    skip_blank_unallocated: bool = False,
    battle_start: Optional[int] = None,
    battle_sectors: int = DEFAULT_BATTLE_DATA_SECTORS,
    battle_pointer: int = DEFAULT_BATTLE_POINTER_OFFSET,
) -> None:
    """仕様書第7章に準拠した一括ダンプ処理"""
    if not os.path.exists(disk_image_path):
        raise FileNotFoundError(f"ディスクイメージが存在しません: {disk_image_path}")

    with open(disk_image_path, "rb") as f:
        source = f.read()

    if len(source) % SECTOR_SIZE != 0:
        print(f"[警告] ディスクイメージのサイズ ({len(source)} バイト) がセクタ境界の倍数ではありません。")

    sectors: List[bytes] = []
    for i in range(0, len(source), SECTOR_SIZE):
        sectors.append(source[i : i + SECTOR_SIZE])

    total_sectors = len(sectors)
    print(f"ディスクイメージ読み込み: {disk_image_path} (セクタ数: {total_sectors})")

    os.makedirs(out_folder, exist_ok=True)

    # ルートディレクトリエントリの解析 (セクタ 10 〜 99、計90セクタ = 2,880エントリ)
    rd_table: List[SayDosRootDirectory] = []
    max_rd_sector = min(SECTOR_FILE_START, total_sectors)
    current_file_id = 0
    for s in range(ROOT_DIR_START_SECTOR, max_rd_sector):
        sec_data = sectors[s]
        entries_per_sector = len(sec_data) // ROOT_DIR_ENTRY_SIZE
        for e in range(entries_per_sector):
            entry_bytes = sec_data[e * ROOT_DIR_ENTRY_SIZE : (e + 1) * ROOT_DIR_ENTRY_SIZE]
            rd_table.append(SayDosRootDirectory.from_bytes(entry_bytes, file_id=current_file_id))
            current_file_id += 1

    # ルートディレクトリ情報の保存
    json_path = os.path.join(out_folder, ROOT_DIRECTORY_FILE)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump([entry.to_dict() for entry in rd_table], f, indent=2)
    print(f"ディレクトリ情報保存完了: '{ROOT_DIRECTORY_FILE}' (全 {len(rd_table)} エントリ)")

    # 戦闘データ配置セクタの決定 (指定値 -> BATTLE.COM コード検証による自動検出 -> デフォルト値)
    detected_sec = None
    b_com_bytes = None
    battle_entry = next((e for e in rd_table if not e.is_empty and e.file == "BATTLE.COM"), None)
    if battle_entry and battle_entry.start_sector < total_sectors:
        b_com_bytes = b"".join(sectors[battle_entry.start_sector : battle_entry.end_sector + 1])
        verified, detected_sec, _ = verify_and_parse_battle_routine(b_com_bytes)

    if battle_start is not None:
        actual_battle_start = battle_start
        print(f"戦闘データ開始セクタ: 0x{actual_battle_start:04X} (CLIオプション指定値)")
    elif detected_sec is not None:
        actual_battle_start = detected_sec
        print(f"戦闘データ開始セクタ: 0x{actual_battle_start:04X} (BATTLE.COM ルーチン検証より自動検出)")
    else:
        actual_battle_start = DEFAULT_BATTLE_DATA_START
        print(f"戦闘データ開始セクタ: 0x{actual_battle_start:04X} (既定値)")

    actual_battle_end = actual_battle_start + battle_sectors

    # セクタ占有状況および未割り当てセクタの解析
    _, ranges, unallocated_ranges = build_sector_map(
        sectors, rd_table, battle_start=actual_battle_start, battle_end=actual_battle_end
    )

    # セクタマップ情報の保存
    sector_map_path = os.path.join(out_folder, SECTOR_MAP_FILE)
    with open(sector_map_path, "w", encoding="utf-8") as f:
        json.dump(
            {
                "disk_image": os.path.basename(disk_image_path),
                "total_sectors": total_sectors,
                "sector_size": SECTOR_SIZE,
                "battle_system": {
                    "start_sector": f"0x{actual_battle_start:04X}",
                    "end_sector": f"0x{actual_battle_end - 1:04X}",
                    "sector_count": battle_sectors,
                    "pointer_offset": f"0x{battle_pointer:04X}",
                },
                "ranges": ranges,
            },
            f,
            indent=2,
        )
    print(f"セクタマップ保存完了: '{SECTOR_MAP_FILE}'")

    # 通常ファイルおよび集約システム領域のダンプ (--dump-files: 既定値 True)
    if dump_files:
        files_dir = os.path.join(out_folder, FOLDER_FILES)
        os.makedirs(files_dir, exist_ok=True)

        # システムブート領域の出力 (セクタ 0x0000 - 0x0009 / 5,120B)
        if total_sectors >= SYSTEM_BOOT_END:
            boot_bytes = b"".join(sectors[SYSTEM_BOOT_START:SYSTEM_BOOT_END])
            boot_path = os.path.join(files_dir, SYSTEM_BOOT_FILENAME)
            with open(boot_path, "wb") as f:
                f.write(boot_bytes)
            print(f"  出力: {SYSTEM_BOOT_FILENAME:<16} (セクタ 0x0000 - 0x0009 / {len(boot_bytes)} バイト)")

        # 戦闘システム領域の集約出力
        if total_sectors >= actual_battle_end:
            battle_bytes = b"".join(sectors[actual_battle_start:actual_battle_end])
            battle_path = os.path.join(files_dir, BATTLE_DATA_FILENAME)
            with open(battle_path, "wb") as f:
                f.write(battle_bytes)
            print(
                f"  出力: {BATTLE_DATA_FILENAME:<16} (セクタ 0x{actual_battle_start:04X} - "
                f"0x{actual_battle_end - 1:04X} / {len(battle_bytes)} バイト)"
            )

            # BATTLE.COM のコード保証検査および敵キャラ個別PIC展開
            if b_com_bytes:
                verified, _, tbl_off = verify_and_parse_battle_routine(b_com_bytes)
                if verified and tbl_off is not None:
                    battle_dir = os.path.join(out_folder, FOLDER_BATTLE)
                    os.makedirs(battle_dir, exist_ok=True)
                    print(f"敵キャラ画像ルーチンのコード検証に成功しました。'{battle_dir}' に個別PICを展開します...")

                    battle_table_meta = []
                    for enemy_id in range(ENEMY_COUNT):
                        entry_pos = tbl_off + (enemy_id * 2)
                        rel_sec = b_com_bytes[entry_pos]
                        sec_cnt = b_com_bytes[entry_pos + 1]

                        abs_start = actual_battle_start + rel_sec
                        abs_end = abs_start + sec_cnt
                        fname = f"ENEMY_{enemy_id:02X}.PIC"

                        battle_table_meta.append({
                            "id": enemy_id,
                            "file": fname,
                            "sector_offset": rel_sec,
                            "sector_count": sec_cnt,
                        })

                        if abs_end <= total_sectors:
                            enemy_bytes = b"".join(sectors[abs_start:abs_end])
                            enemy_path = os.path.join(battle_dir, fname)
                            with open(enemy_path, "wb") as ef:
                                ef.write(enemy_bytes)
                        show_progress_bar(enemy_id + 1, ENEMY_COUNT, prefix="  敵画像展開:")

                    # 敵キャラの元オフセット・元サイズ情報をメタデータとして保存
                    battle_table_path = os.path.join(battle_dir, BATTLE_TABLE_FILE)
                    with open(battle_table_path, "w", encoding="utf-8") as btf:
                        json.dump(battle_table_meta, btf, indent=2)

                    print(f"  個別展開完了: ENEMY_00.PIC 〜 ENEMY_{ENEMY_COUNT - 1:02X}.PIC (メタデータ: '{BATTLE_TABLE_FILE}')")
                else:
                    print("[警告] BATTLE.COM 内の敵画像読み込みルーチンのコード検証に失敗しました。個別PICの展開をスキップします。")
        else:
            print(f"  [警告] 戦闘データの終端セクタ (0x{actual_battle_end:04X}) がディスク終端を超えています。")

        # ルートディレクトリ登録ファイルの抽出
        file_count = 0
        for entry in rd_table:
            if not entry.is_empty:
                if entry.end_sector >= total_sectors:
                    print(f"  [警告] {entry.file}: 終了セクタ (0x{entry.end_sector:04X}) がディスク終端を超えています。")
                    continue

                file_bytes = b"".join(sectors[entry.start_sector : entry.end_sector + 1])
                out_path = os.path.join(files_dir, entry.file)
                with open(out_path, "wb") as f:
                    f.write(file_bytes)

                print(
                    f"  出力: {entry.file:<16} (開始: 0x{entry.start_sector:04X}, "
                    f"終了: 0x{entry.end_sector:04X}, セクタ数: {entry.size_in_sectors:2d}, "
                    f"サイズ: {len(file_bytes):6d} バイト)"
                )
                file_count += 1
        print(f"リソース抽出完了: '{files_dir}' 配下に {file_count} 個のファイルを保存しました。")

    # 未割り当てセクタの抽出 (--dump-unallocated: 既定値 False)
    if dump_unallocated:
        unalloc_dir = os.path.join(out_folder, FOLDER_UNALLOCATED)
        os.makedirs(unalloc_dir, exist_ok=True)
        unalloc_count = 0

        for start_sec, end_sec in unallocated_ranges:
            block_bytes = b"".join(sectors[start_sec : end_sec + 1])
            is_blank = all(b == block_bytes[0] for b in block_bytes) and (block_bytes[0] in (0x00, 0xFF))

            if skip_blank_unallocated and is_blank:
                continue

            fname = f"UNALLOC_{start_sec:04X}_{end_sec:04X}.BIN"
            fpath = os.path.join(unalloc_dir, fname)
            with open(fpath, "wb") as f:
                f.write(block_bytes)

            print(
                f"  未割当セクタ抽出: {fname:<24} (0x{start_sec:04X} - 0x{end_sec:04X}, "
                f"{len(block_bytes)} バイト, ブランク: {is_blank})"
            )
            unalloc_count += 1

        print(f"未割り当てセクタ抽出完了: '{unalloc_dir}' 配下に {unalloc_count} ブロックを出力しました。")

    # 全1,440セクタの個別生バイナリ出力 (--dump-sectors: 既定値 False)
    if dump_sectors:
        sectors_dir = os.path.join(out_folder, FOLDER_SECTORS)
        os.makedirs(sectors_dir, exist_ok=True)
        print("生セクタ書き出し中...")
        for idx, sec in enumerate(sectors, start=1):
            sec_path = os.path.join(sectors_dir, f"{idx - 1:04d}.bin")
            with open(sec_path, "wb") as f:
                f.write(sec)
            show_progress_bar(idx, total_sectors, prefix="  セクタ保存:")
        print(f"生セクタ完全保全ダンプ完了: '{sectors_dir}' 配下に {total_sectors} 個のセクタを出力しました。")


def build_battle_data_with_slot_management(
    battle_dir: str,
    default_table_bytes: Optional[bytes] = None,
    auto_pad: bool = False,
) -> Tuple[bytearray, bytearray]:
    """
    敵キャラ画像の元サイズ・元配置を管理し、元サイズに収まる場合はオフセットを変更せず、
    超過したキャラのみ後続をずらすスライド配置アルゴリズムを実行する。
    戻り値: (戦闘データバイナリ, 新しい256バイトのオフセットテーブル)
    """
    table_json_path = os.path.join(battle_dir, BATTLE_TABLE_FILE)
    orig_meta: Dict[int, Tuple[int, int]] = {}

    # 1. 元のオフセットおよびセクタ長メタデータの読み込み
    if os.path.exists(table_json_path):
        with open(table_json_path, "r", encoding="utf-8") as btf:
            raw_meta = json.load(btf)
            for item in raw_meta:
                orig_meta[item["id"]] = (item["sector_offset"], item["sector_count"])
    elif default_table_bytes and len(default_table_bytes) >= ENEMY_COUNT * 2:
        for i in range(ENEMY_COUNT):
            orig_meta[i] = (default_table_bytes[i * 2], default_table_bytes[i * 2 + 1])
    else:
        # メタデータもテーブルもない場合の安全な初期連番算出
        cur_off = 0
        for i in range(ENEMY_COUNT):
            orig_meta[i] = (cur_off, 1)
            cur_off += 1

    # 2. 各敵キャラの画像データ読み込みと必要セクタ数の計算
    enemy_files: Dict[int, bytes] = {}
    curr_sec_cnt: Dict[int, int] = {}

    for enemy_id in range(ENEMY_COUNT):
        pic_path = os.path.join(battle_dir, f"ENEMY_{enemy_id:02X}.PIC")
        if not os.path.exists(pic_path):
            raise FileNotFoundError(f"敵画像ファイルが見つかりません: {pic_path}")

        with open(pic_path, "rb") as pf:
            p_bytes = pf.read()

        if len(p_bytes) % SECTOR_SIZE != 0:
            if auto_pad:
                p_bytes += b"\x00" * (SECTOR_SIZE - (len(p_bytes) % SECTOR_SIZE))
            else:
                raise ValueError(f"'{pic_path}' のサイズが512バイト境界ではありません。(--auto-pad で調整可能)")

        enemy_files[enemy_id] = p_bytes
        curr_sec_cnt[enemy_id] = len(p_bytes) // SECTOR_SIZE

    # 3. オリジナルのユニークスロット (同一オフセットを共有するグループ) を特定
    unique_orig_offsets = sorted(list(set(orig_meta[i][0] for i in range(ENEMY_COUNT))))

    # 各スロットに属する敵キャラリストと、元スロット長を収集
    slot_enemies: Dict[int, List[int]] = {}
    orig_slot_len: Dict[int, int] = {}

    for u_off in unique_orig_offsets:
        members = [i for i in range(ENEMY_COUNT) if orig_meta[i][0] == u_off]
        slot_enemies[u_off] = members
        orig_slot_len[u_off] = max(orig_meta[i][1] for i in members)

    # 4. 各スロットの必要サイズ判定と後続スライド配置計算
    new_slot_offsets: Dict[int, int] = {}
    new_slot_allocated_len: Dict[int, int] = {}
    shift_offset = 0

    for u_off in unique_orig_offsets:
        members = slot_enemies[u_off]
        # このスロット内の敵キャラたちが必要とする最大セクタ数
        needed_len = max(curr_sec_cnt[i] for i in members)
        orig_len = orig_slot_len[u_off]

        # 元のサイズに収まるのであれば元長を維持 (後ろをずらさない)
        # 超過した場合のみスロットを拡張し、差分をシフト量に加算
        if needed_len <= orig_len:
            actual_len = orig_len
        else:
            actual_len = needed_len
            shift_offset += (actual_len - orig_len)

        new_slot_offsets[u_off] = u_off + (shift_offset - (actual_len - orig_len))
        new_slot_allocated_len[u_off] = actual_len

    # 5. 新しいオフセットテーブル (256バイト) の生成
    new_table = bytearray(ENEMY_COUNT * 2)
    max_used_rel = 0

    for enemy_id in range(ENEMY_COUNT):
        u_off = orig_meta[enemy_id][0]
        assigned_rel = new_slot_offsets[u_off]
        assigned_cnt = curr_sec_cnt[enemy_id]

        if assigned_rel > MAX_RELATIVE_SECTORS:
            raise ValueError(
                f"相対セクタオフセット (0x{assigned_rel:X}) が "
                f"Z80ルーチンの上限 (0x{MAX_RELATIVE_SECTORS:X} セクタ) を超過しました。"
            )

        new_table[enemy_id * 2] = assigned_rel
        new_table[enemy_id * 2 + 1] = assigned_cnt

        slot_end = assigned_rel + new_slot_allocated_len[u_off]
        if slot_end > max_used_rel:
            max_used_rel = slot_end

    # 6. 戦闘データバイナリの構築 (元スロット位置へ配置し余白はパディング)
    battle_data_bytes = bytearray(max_used_rel * SECTOR_SIZE)

    for u_off in unique_orig_offsets:
        members = slot_enemies[u_off]
        rep_enemy = members[0]  # スロット代表データ
        p_bytes = enemy_files[rep_enemy]
        assigned_rel = new_slot_offsets[u_off]
        target_byte_pos = assigned_rel * SECTOR_SIZE
        battle_data_bytes[target_byte_pos : target_byte_pos + len(p_bytes)] = p_bytes

    return battle_data_bytes, new_table


def cmd_write(
    in_folder: str,
    disk_image_path: str,
    auto_pad: bool = False,
    compact: bool = False,
    battle_pointer: int = DEFAULT_BATTLE_POINTER_OFFSET,
) -> None:
    """編集後のファイル群およびメタデータからDSKイメージを再構築"""
    json_path = os.path.join(in_folder, ROOT_DIRECTORY_FILE)
    files_dir = os.path.join(in_folder, FOLDER_FILES)
    sectors_dir = os.path.join(in_folder, FOLDER_SECTORS)
    unalloc_dir = os.path.join(in_folder, FOLDER_UNALLOCATED)
    battle_dir = os.path.join(in_folder, FOLDER_BATTLE)

    if not os.path.exists(in_folder):
        raise FileNotFoundError(f"入力フォルダが存在しません: {in_folder}")
    if not os.path.exists(json_path):
        raise FileNotFoundError(f"ルートディレクトリ定義ファイルが見つかりません: {json_path}")
    if not os.path.exists(files_dir):
        raise FileNotFoundError(f"ファイルリソースフォルダが見つかりません: {files_dir}")

    with open(json_path, "r", encoding="utf-8") as f:
        raw_rd_data = json.load(f)
    rd_table = [SayDosRootDirectory.from_dict(d, default_id=idx) for idx, d in enumerate(raw_rd_data)]

    # ルートディレクトリ領域 (セクタ 10 〜 99、計90セクタ = 2,880エントリ = 46,080バイト) のサイズ保証
    if len(rd_table) > TOTAL_ROOT_DIR_ENTRIES:
        raise ValueError(
            f"ルートディレクトリエントリ数 ({len(rd_table)}) が最大許容数 "
            f"({TOTAL_ROOT_DIR_ENTRIES}) を超過しています。"
        )

    # 2,880エントリに満たない場合は末尾を空エントリで補完
    while len(rd_table) < TOTAL_ROOT_DIR_ENTRIES:
        rd_table.append(SayDosRootDirectory(file_id=len(rd_table), is_empty=True, byte_fill=0x00))

    # システムブート領域 (セクタ 0x0000 - 0x0009: 5,120バイト) の読み込み
    boot_path = os.path.join(files_dir, SYSTEM_BOOT_FILENAME)
    if os.path.exists(boot_path):
        with open(boot_path, "rb") as f:
            system_boot_bytes = f.read()
    elif os.path.exists(sectors_dir):
        system_sectors = []
        for s in range(ROOT_DIR_START_SECTOR):
            sec_p = os.path.join(sectors_dir, f"{s:04d}.bin")
            with open(sec_p, "rb") as f:
                system_sectors.append(f.read())
        system_boot_bytes = b"".join(system_sectors)
    else:
        raise FileNotFoundError(
            f"システムブート領域が見つかりません ('{boot_path}' または '{sectors_dir}' が必要です)"
        )

    if len(system_boot_bytes) != (SYSTEM_BOOT_END - SYSTEM_BOOT_START) * SECTOR_SIZE:
        raise ValueError(f"システムブート領域のサイズが不正です: {len(system_boot_bytes)} バイト (規定: 5,120バイト)")

    # ディスクイメージバッファの初期化 (720KB: 0xB4000 バイト)
    final_disk_image = bytearray([0xFF] * DISK_SIZE_2DD)

    battle_sector = 0x0000
    battle_found = False
    max_used_file_sector = 0

    if not compact:
        # 【モードA: ギャップ維持モード (完全再現)】
        print("【モードA: ギャップ維持モード】オリジナルのセクタ配置とギャップを維持して構築します...")

        # 未割り当てギャップセクタ群 (0x40 埋めブランク領域等) の復元
        if os.path.exists(unalloc_dir):
            for fname in os.listdir(unalloc_dir):
                if fname.startswith("UNALLOC_") and fname.endswith(".BIN"):
                    parts = fname[len("UNALLOC_"):-len(".BIN")].split("_")
                    if len(parts) == 2:
                        u_start = int(parts[0], 16)
                        u_path = os.path.join(unalloc_dir, fname)
                        with open(u_path, "rb") as uf:
                            u_bytes = uf.read()
                        byte_offset = u_start * SECTOR_SIZE
                        final_disk_image[byte_offset : byte_offset + len(u_bytes)] = u_bytes
                        sec_end = u_start + (len(u_bytes) // SECTOR_SIZE) - 1
                        if sec_end < DEFAULT_BATTLE_DATA_START and sec_end > max_used_file_sector:
                            max_used_file_sector = sec_end

        for rd_entry in rd_table:
            if not rd_entry.is_empty:
                file_path = os.path.join(files_dir, rd_entry.file)
                if not os.path.exists(file_path):
                    raise FileNotFoundError(f"登録対象ファイルが存在しません: {file_path}")

                with open(file_path, "rb") as f:
                    file_bytes = f.read()

                if len(file_bytes) % SECTOR_SIZE != 0:
                    if auto_pad:
                        pad_len = SECTOR_SIZE - (len(file_bytes) % SECTOR_SIZE)
                        file_bytes += b"\x00" * pad_len
                    else:
                        raise ValueError(f"ファイル '{rd_entry.file}' のサイズが512バイト境界に合致していません。")

                num_sectors = len(file_bytes) // SECTOR_SIZE
                orig_sectors = rd_entry.size_in_sectors

                if num_sectors > orig_sectors:
                    raise ValueError(
                        f"ファイル '{rd_entry.file}' のサイズ ({num_sectors} セクタ) が "
                        f"元の割り当て容量 ({orig_sectors} セクタ) を超過しています。"
                        f"間詰め再配置を行う場合は --compact を指定してください。"
                    )

                # オリジナルの StartSector の位置へ直接配置 (余白は 0x00 パディング)
                padded_bytes = file_bytes.ljust(orig_sectors * SECTOR_SIZE, b"\x00")
                byte_offset = rd_entry.start_sector * SECTOR_SIZE
                final_disk_image[byte_offset : byte_offset + len(padded_bytes)] = padded_bytes

                if rd_entry.end_sector > max_used_file_sector:
                    max_used_file_sector = rd_entry.end_sector

                print(
                    f"  配置: {rd_entry.file:<16} (セクタ 0x{rd_entry.start_sector:04X} - "
                    f"0x{rd_entry.end_sector:04X}, セクタ数: {orig_sectors:2d})"
                )

                if rd_entry.file == "BATTLE.COM":
                    battle_sector = rd_entry.start_sector
                    battle_found = True

        # システムブート領域およびディレクトリ領域の書き込み
        final_disk_image[0 : SYSTEM_BOOT_END * SECTOR_SIZE] = system_boot_bytes
        rd_bytes = b"".join(e.to_bytes() for e in rd_table)
        final_disk_image[ROOT_DIR_START_SECTOR * SECTOR_SIZE : ROOT_DIR_START_SECTOR * SECTOR_SIZE + len(rd_bytes)] = rd_bytes

    else:
        # 【モードB: 最適化モード (ギャップを再現せず全ファイル間詰め配置)】
        print("【モードB: 最適化モード】ギャップを排除してファイルを間詰め配置します...")
        file_sector = SECTOR_FILE_START
        rd_entry_bytes_list: List[bytes] = []
        file_sectors_list: List[bytes] = []

        for rd_entry in rd_table:
            if not rd_entry.is_empty:
                file_path = os.path.join(files_dir, rd_entry.file)
                if not os.path.exists(file_path):
                    raise FileNotFoundError(f"登録対象ファイルが存在しません: {file_path}")

                with open(file_path, "rb") as f:
                    file_bytes = f.read()

                if len(file_bytes) % SECTOR_SIZE != 0:
                    if auto_pad:
                        pad_len = SECTOR_SIZE - (len(file_bytes) % SECTOR_SIZE)
                        file_bytes += b"\x00" * pad_len
                    else:
                        raise ValueError(f"ファイル '{rd_entry.file}' のサイズが512バイト境界に合致していません。")

                for offset in range(0, len(file_bytes), SECTOR_SIZE):
                    file_sectors_list.append(file_bytes[offset : offset + SECTOR_SIZE])

                num_sectors = len(file_bytes) // SECTOR_SIZE
                rd_entry.start_sector = file_sector
                rd_entry.end_sector = file_sector + num_sectors - 1
                file_sector += num_sectors

                print(
                    f"  配置: {rd_entry.file:<16} (開始: 0x{rd_entry.start_sector:04X}, "
                    f"終了: 0x{rd_entry.end_sector:04X}, セクタ数: {num_sectors:2d})"
                )

                if rd_entry.file == "BATTLE.COM":
                    battle_sector = rd_entry.start_sector
                    battle_found = True

            rd_entry_bytes_list.append(rd_entry.to_bytes())

        max_used_file_sector = file_sector - 1

        # システムセクタ + ルートディレクトリ + ファイルデータ を配置
        merged_data = bytearray()
        merged_data.extend(system_boot_bytes)
        for entry_raw in rd_entry_bytes_list:
            merged_data.extend(entry_raw)
        for sec in file_sectors_list:
            merged_data.extend(sec)
        final_disk_image[0 : len(merged_data)] = merged_data

    # 戦闘データバイナリおよび新テーブルの構築
    battle_data_bytes = bytearray()
    new_table_bytes: Optional[bytearray] = None

    if os.path.exists(battle_dir) and battle_found:
        print("battle/ 内の個別PICから元サイズ・スライド配置を評価して最適化パックします...")
        # 既存 BATTLE.COM 内のテーブル生データを参照用に抽出
        target_com_pos = battle_sector * SECTOR_SIZE
        com_entry = next(e for e in rd_table if not e.is_empty and e.file == "BATTLE.COM")
        current_com_bytes = final_disk_image[target_com_pos : target_com_pos + (com_entry.size_in_sectors * SECTOR_SIZE)]

        default_table_raw = None
        verified, _, tbl_off = verify_and_parse_battle_routine(current_com_bytes)
        if verified and tbl_off is not None:
            default_table_raw = current_com_bytes[tbl_off : tbl_off + (ENEMY_COUNT * 2)]

        battle_data_bytes, new_table_bytes = build_battle_data_with_slot_management(
            battle_dir=battle_dir,
            default_table_bytes=default_table_raw,
            auto_pad=auto_pad,
        )
    else:
        # 単一 BATTLE_DATA.BIN から読み込み
        battle_data_path = os.path.join(files_dir, BATTLE_DATA_FILENAME)
        if os.path.exists(battle_data_path):
            with open(battle_data_path, "rb") as f:
                battle_data_bytes = bytearray(f.read())
        elif os.path.exists(sectors_dir):
            battle_sec_list = []
            for s in range(DEFAULT_BATTLE_DATA_START, DEFAULT_BATTLE_DATA_START + DEFAULT_BATTLE_DATA_SECTORS):
                sec_p = os.path.join(sectors_dir, f"{s:04d}.bin")
                with open(sec_p, "rb") as f:
                    battle_sec_list.append(f.read())
            battle_data_bytes = bytearray(b"".join(battle_sec_list))
        else:
            raise FileNotFoundError(
                f"戦闘システムデータが見つかりません ('{battle_dir}', '{battle_data_path}', '{sectors_dir}' のいずれかが必要)"
            )

    if len(battle_data_bytes) % SECTOR_SIZE != 0:
        raise ValueError(f"戦闘データのサイズが512バイト境界に合致していません: {len(battle_data_bytes)} バイト")

    # 全ファイルを配置した後の「空きエリア」へ戦闘データを配置
    if not compact:
        # 再現モード: 基本はデフォルトの 0x044C。万一ファイルが食い込んでいる場合は直後の空きへ退避
        if max_used_file_sector < DEFAULT_BATTLE_DATA_START:
            dest_battle_sector = DEFAULT_BATTLE_DATA_START
        else:
            dest_battle_sector = max_used_file_sector + 1
            print(f"[注意] 通常ファイル群が 0x044C を超えたため、空きセクタ 0x{dest_battle_sector:04X} へ退避配置します。")
    else:
        # 最適化モード: 全ファイルを配置した直後の空きセクタへ配置
        dest_battle_sector = max_used_file_sector + 1

    battle_dest_pos = dest_battle_sector * SECTOR_SIZE
    if battle_dest_pos + len(battle_data_bytes) > DISK_SIZE_2DD:
        raise ValueError(
            f"戦闘データ配置位置 (0x{battle_dest_pos + len(battle_data_bytes):X} バイト) が "
            f"ディスク総容量 (0x{DISK_SIZE_2DD:X} バイト) を超過しました。"
        )

    final_disk_image[battle_dest_pos : battle_dest_pos + len(battle_data_bytes)] = battle_data_bytes

    print(
        f"戦闘システム領域 ({len(battle_data_bytes)} バイト / {len(battle_data_bytes) // SECTOR_SIZE} セクタ) を "
        f"セクタ 0x{dest_battle_sector:04X} へ配置しました。"
    )

    # 記憶しておいた BATTLE.COM の格納先へ戻り、テーブルおよび開始セクタポインタを書き換え
    if battle_found:
        target_com_pos = battle_sector * SECTOR_SIZE
        com_entry = next(e for e in rd_table if not e.is_empty and e.file == "BATTLE.COM")
        current_com_bytes = final_disk_image[target_com_pos : target_com_pos + (com_entry.size_in_sectors * SECTOR_SIZE)]

        verified, _, tbl_off = verify_and_parse_battle_routine(current_com_bytes)
        if verified and tbl_off is not None:
            # 1. オフセットテーブル (256バイト) の更新
            if new_table_bytes:
                final_disk_image[target_com_pos + tbl_off : target_com_pos + tbl_off + len(new_table_bytes)] = new_table_bytes
                print(f"BATTLE.COM 内の敵キャラ画像オフセットテーブル (+0x{tbl_off:04X}) を更新しました。")

            # 2. 戦闘データ先頭セクタポインタ (+0x0F6C) の更新
            pointer_pos = target_com_pos + battle_pointer
            pointer_val = struct.pack("<H", dest_battle_sector)
            final_disk_image[pointer_pos : pointer_pos + len(pointer_val)] = pointer_val
            print(
                f"BATTLE.COM 内の戦闘先頭セクタポインタ (+0x{battle_pointer:04X}) を "
                f"セクタ番号 0x{dest_battle_sector:04X} で更新しました。"
            )
        else:
            print("[警告] BATTLE.COM のコード検証に失敗したため、内部ポインタの更新をスキップしました。")
    else:
        print("[注意] BATTLE.COM が見つからないため、セクタポインタの更新をスキップしました。")

    out_dir = os.path.dirname(disk_image_path)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    print("ディスクイメージ書き込み中...")
    total_write_sectors = len(final_disk_image) // SECTOR_SIZE
    with open(disk_image_path, "wb") as f:
        for s in range(total_write_sectors):
            offset = s * SECTOR_SIZE
            f.write(final_disk_image[offset : offset + SECTOR_SIZE])
            show_progress_bar(s + 1, total_write_sectors, prefix="  セクタ書き込み:")

    print(f"ディスクイメージ構築完了: {disk_image_path} (総容量: {len(final_disk_image)} バイト)")


def cmd_list(
    disk_image_path: str,
    battle_pointer: int = DEFAULT_BATTLE_POINTER_OFFSET,
    battle_sectors: int = DEFAULT_BATTLE_DATA_SECTORS,
) -> None:
    """DSKイメージ内のファイル一覧とセクタ配置情報を表示"""
    if not os.path.exists(disk_image_path):
        raise FileNotFoundError(f"ディスクイメージが存在しません: {disk_image_path}")

    with open(disk_image_path, "rb") as f:
        source = f.read()

    total_sectors = len(source) // SECTOR_SIZE
    print(f"ディスクイメージ: {disk_image_path} (総セクタ数: {total_sectors})")

    len_id = 11
    len_name = 16
    len_start = 14
    len_end = 14
    len_sec = 10
    len_size = 14

    hdr_id = pad_display_width("ファイルID", len_id)
    hdr_name = pad_display_width("ファイル名", len_name)
    hdr_start = pad_display_width("開始セクタ", len_start)
    hdr_end = pad_display_width("終了セクタ", len_end)
    hdr_sec = pad_display_width("セクタ数", len_sec)
    hdr_size = pad_display_width("サイズ (bytes)", len_size)
    sep_line = "-" * (len_id + len_name + len_start + len_end + len_sec + len_size + 5)

    print(sep_line)
    print(f"{hdr_id} {hdr_name} {hdr_start} {hdr_end} {hdr_sec} {hdr_size}")
    print(sep_line)

    # システム領域の表示
    if total_sectors >= SYSTEM_BOOT_END:
        col_id = pad_display_width("---", len_id)
        col_name = pad_display_width(SYSTEM_BOOT_FILENAME, len_name)
        col_start = pad_display_width(f"0x{SYSTEM_BOOT_START:04X} ({SYSTEM_BOOT_START:4d})", len_start)
        col_end = pad_display_width(f"0x{SYSTEM_BOOT_END - 1:04X} ({SYSTEM_BOOT_END - 1:4d})", len_end)
        col_sec = pad_display_width(f"{SYSTEM_BOOT_END - SYSTEM_BOOT_START:4d}", len_sec)
        col_size = pad_display_width(f"{(SYSTEM_BOOT_END - SYSTEM_BOOT_START) * SECTOR_SIZE:6d}", len_size)
        print(f"{col_id} {col_name} {col_start} {col_end} {col_sec} {col_size}")

    # 通常ファイルの解析と表示
    count = 0
    current_file_id = 0
    rd_table: List[SayDosRootDirectory] = []
    max_rd_sector = min(SECTOR_FILE_START, total_sectors)
    sectors = [source[i : i + SECTOR_SIZE] for i in range(0, len(source), SECTOR_SIZE)]

    for s in range(ROOT_DIR_START_SECTOR, max_rd_sector):
        sec_offset = s * SECTOR_SIZE
        sec_data = source[sec_offset : sec_offset + SECTOR_SIZE]
        entries_per_sector = len(sec_data) // ROOT_DIR_ENTRY_SIZE

        for e in range(entries_per_sector):
            entry_bytes = sec_data[e * ROOT_DIR_ENTRY_SIZE : (e + 1) * ROOT_DIR_ENTRY_SIZE]
            entry = SayDosRootDirectory.from_bytes(entry_bytes, file_id=current_file_id)
            rd_table.append(entry)
            if not entry.is_empty:
                size_bytes = entry.size_in_sectors * SECTOR_SIZE
                id_str = f"0x{entry.file_id:02X} ({entry.file_id:3d})"
                col_id = pad_display_width(id_str, len_id)
                col_name = pad_display_width(entry.file, len_name)
                col_start = pad_display_width(f"0x{entry.start_sector:04X} ({entry.start_sector:4d})", len_start)
                col_end = pad_display_width(f"0x{entry.end_sector:04X} ({entry.end_sector:4d})", len_end)
                col_sec = pad_display_width(f"{entry.size_in_sectors:4d}", len_sec)
                col_size = pad_display_width(f"{size_bytes:6d}", len_size)
                print(f"{col_id} {col_name} {col_start} {col_end} {col_sec} {col_size}")
                count += 1
            current_file_id += 1

    # 戦闘データ配置セクタの特定と表示 (BATTLE.COM コード検証による自動検出またはデフォルト値)
    detected_sec = None
    battle_entry = next((e for e in rd_table if not e.is_empty and e.file == "BATTLE.COM"), None)
    if battle_entry and battle_entry.start_sector < total_sectors:
        b_com = b"".join(sectors[battle_entry.start_sector : battle_entry.end_sector + 1])
        verified, detected_sec, _ = verify_and_parse_battle_routine(b_com)

    actual_battle_start = detected_sec if detected_sec is not None else DEFAULT_BATTLE_DATA_START
    actual_battle_end = actual_battle_start + battle_sectors

    if total_sectors >= actual_battle_end:
        col_id = pad_display_width("---", len_id)
        col_name = pad_display_width(BATTLE_DATA_FILENAME, len_name)
        col_start = pad_display_width(f"0x{actual_battle_start:04X} ({actual_battle_start:4d})", len_start)
        col_end = pad_display_width(f"0x{actual_battle_end - 1:04X} ({actual_battle_end - 1:4d})", len_end)
        col_sec = pad_display_width(f"{battle_sectors:4d}", len_sec)
        col_size = pad_display_width(f"{battle_sectors * SECTOR_SIZE:6d}", len_size)
        print(f"{col_id} {col_name} {col_start} {col_end} {col_sec} {col_size}")

    print(sep_line)
    print(f"登録ファイル数: {count} 個 (システム領域・戦闘領域を除く)")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="FFSayDosTool",
        description="MSX2版『ファイナルファンタジー』Say DOS ディスクイメージ操作ツール",
        epilog=(
            "仕様書第7章に準拠したダンプオプション例:\n"
            "  1. 基本ダンプ (files/ 配下にリソース集約、battle/ に敵画像個別展開):\n"
            "     python FFSayDosTool.py dump ff_msx.dsk work_dir\n\n"
            "  2. 未割り当てセクタ抽出を追加 (空セクタはスキップ):\n"
            "     python FFSayDosTool.py dump ff_msx.dsk work_dir --dump-unallocated --skip-blank-unallocated\n\n"
            "  3. 編集後ファイル群からDSK再構築 (再現モード: オリジナル配置・ギャップ維持):\n"
            "     python FFSayDosTool.py write work_dir new_ff_msx.dsk --auto-pad\n\n"
            "  4. 編集後ファイル群からDSK再構築 (最適化モード: ギャップ排除・全ファイル間詰め):\n"
            "     python FFSayDosTool.py write work_dir new_ff_msx.dsk --compact --auto-pad\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    subparsers = parser.add_subparsers(dest="command", help="実行するコマンド")

    # dump サブコマンド
    parser_dump = subparsers.add_parser("dump", help="DSKイメージからファイル・メタデータを展開")
    parser_dump.add_argument("disk_image", help="入力DSKイメージファイルパス")
    parser_dump.add_argument("out_folder", help="展開先出力フォルダパス")
    parser_dump.add_argument(
        "--dump-files",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="通常ファイル、システム領域、戦闘データを files/ 配下に集約出力 (既定値: True)",
    )
    parser_dump.add_argument(
        "--dump-sectors",
        action="store_true",
        default=False,
        help="全1,440セクタを512バイト個別の生バイナリとして sectors/ 配下に出力 (既定値: False)",
    )
    parser_dump.add_argument(
        "--dump-unallocated",
        action="store_true",
        default=False,
        help="ファイル非占有セクタを検出し unallocated/ 配下に出力 (既定値: False)",
    )
    parser_dump.add_argument(
        "--skip-blank-unallocated",
        action="store_true",
        default=False,
        help="未割り当てセクタのうち全バイトが 0xFF または 0x00 の空ブロック出力をスキップする",
    )
    parser_dump.add_argument(
        "--battle-start",
        type=lambda x: parse_hex_or_int(x),
        default=None,
        help="戦闘データの開始セクタ番号 (未指定時は BATTLE.COM より自動検出、検出不能時は 0x044C)",
    )
    parser_dump.add_argument(
        "--battle-sectors",
        type=lambda x: parse_hex_or_int(x),
        default=DEFAULT_BATTLE_DATA_SECTORS,
        help=f"戦闘データのセクタ数 (既定値: {DEFAULT_BATTLE_DATA_SECTORS})",
    )
    parser_dump.add_argument(
        "--battle-pointer",
        type=lambda x: parse_hex_or_int(x),
        default=DEFAULT_BATTLE_POINTER_OFFSET,
        help=f"BATTLE.COM 内の戦闘セクタ番号オフセット (既定値: 0x{DEFAULT_BATTLE_POINTER_OFFSET:04X})",
    )

    # write サブコマンド
    parser_write = subparsers.add_parser("write", help="ファイル群からDSKイメージを再構築")
    parser_write.add_argument("in_folder", help="入力フォルダパス (root_directory.json, files を含む)")
    parser_write.add_argument("disk_image", help="出力先DSKイメージファイルパス")
    parser_write.add_argument(
        "--auto-pad",
        action="store_true",
        default=False,
        help="ファイルサイズが512バイト境界に達していない場合、自動的に 0x00 でパディングする",
    )
    parser_write.add_argument(
        "--compact",
        action="store_true",
        default=False,
        help="【最適化モード】ギャップを排除してファイルを間詰め配置し、直後の空きセクタへ戦闘データを配置する (既定値: 偽 / 再現モード: オリジナル配置・ギャップ維持)",
    )
    parser_write.add_argument(
        "--battle-pointer",
        type=lambda x: parse_hex_or_int(x),
        default=DEFAULT_BATTLE_POINTER_OFFSET,
        help=f"BATTLE.COM 内の戦闘セクタ番号オフセット (既定値: 0x{DEFAULT_BATTLE_POINTER_OFFSET:04X})",
    )

    # list サブコマンド
    parser_list = subparsers.add_parser("list", help="DSKイメージ内のファイル一覧・配置を表示")
    parser_list.add_argument("disk_image", help="対象DSKイメージファイルパス")
    parser_list.add_argument(
        "--battle-pointer",
        type=lambda x: parse_hex_or_int(x),
        default=DEFAULT_BATTLE_POINTER_OFFSET,
        help=f"BATTLE.COM 内の戦闘セクタ番号オフセット (既定値: 0x{DEFAULT_BATTLE_POINTER_OFFSET:04X})",
    )
    parser_list.add_argument(
        "--battle-sectors",
        type=lambda x: parse_hex_or_int(x),
        default=DEFAULT_BATTLE_DATA_SECTORS,
        help=f"戦闘データのセクタ数 (既定値: {DEFAULT_BATTLE_DATA_SECTORS})",
    )

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    try:
        cmd = args.command.lower()
        if cmd == "dump":
            cmd_dump(
                disk_image_path=args.disk_image,
                out_folder=args.out_folder,
                dump_files=args.dump_files,
                dump_sectors=args.dump_sectors,
                dump_unallocated=args.dump_unallocated,
                skip_blank_unallocated=args.skip_blank_unallocated,
                battle_start=args.battle_start,
                battle_sectors=args.battle_sectors,
                battle_pointer=args.battle_pointer,
            )
        elif cmd == "write":
            cmd_write(
                in_folder=args.in_folder,
                disk_image_path=args.disk_image,
                auto_pad=args.auto_pad,
                compact=args.compact,
                battle_pointer=args.battle_pointer,
            )
        elif cmd == "list":
            cmd_list(
                disk_image_path=args.disk_image,
                battle_pointer=args.battle_pointer,
                battle_sectors=args.battle_sectors,
            )
        else:
            parser.print_help()
            sys.exit(1)
    except Exception as ex:
        print(f"[エラー] {ex}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
