#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MSX2版『ファイナルファンタジー』PICファイル操作ツール (FFPicTool)
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import os
import re
import struct
import sys
import zlib

# Pillowが利用可能な場合は画像読み込みのフォールバックとして使用
try:
    from PIL import Image
    HAS_PILLOW = True
except ImportError:
    HAS_PILLOW = False


# ==============================================================================
# コアデータ構造の定義 (ヘッダ・パレット・ピクセルの分離)
# ==============================================================================

@dataclass
class PaletteEntry:
    """MSX2 (V9938) パレットエントリ"""
    raw: int      # 16bit V9938生値: 0RRR0BBB 00000GGG
    r3: int       # 3bit 赤 (0-7)
    g3: int       # 3bit 緑 (0-7)
    b3: int       # 3bit 青 (0-7)
    r: int        # 8bit 赤 (0-255)
    g: int        # 8bit 緑 (0-255)
    b: int        # 8bit 青 (0-255)


@dataclass
class PicHeader:
    """制御ヘッダ (16バイト)"""
    screen_mode: int   # 画面モード (通常 0x0005: SCREEN 5)
    dest_x: int        # 転送先VRAM X座標 (DX: 通常 0)
    dest_y: int        # 転送先VRAM Y走査線番号 (DY: 0-255)
    width_bytes: int   # 1行の転送バイト幅 (NX: ピクセル幅 = NX * 2)
    height_lines: int  # 転送ライン数 (NY)
    reserved: bytes    # 予約領域 (6バイト)


@dataclass
class PicAsset:
    """PICアセット統合オブジェクト (制御ヘッダ・パレット・ピクセルデータの3要素を独立管理)"""
    header: PicHeader
    palette: list[PaletteEntry]  # 16色パレット配列
    pixels: bytearray            # 幅(バイト) * 高さ(ライン) の非圧縮ピクセルデータ (4bpp packed)


# ==============================================================================
# MSX2 (V9938) パレット変換ユーティリティ
# ==============================================================================

def v9938_to_rgb(b0: int, b1: int) -> tuple[int, int, int]:
    """V9938の2バイトパレットレジスタ値を24bit RGB (0-255) に変換する"""
    r3 = (b0 >> 4) & 0x07
    b3 = b0 & 0x07
    g3 = b1 & 0x07
    r8 = round(r3 * 255 / 7)
    g8 = round(g3 * 255 / 7)
    b8 = round(b3 * 255 / 7)
    return (r8, g8, b8)


def rgb_to_v9938(r: int, g: int, b: int) -> tuple[int, int]:
    """24bit RGB (0-255) をV9938パレットレジスタ形式の2バイト (b0, b1) に変換する"""
    r3 = max(0, min(7, round(r * 7 / 255)))
    g3 = max(0, min(7, round(g * 7 / 255)))
    b3 = max(0, min(7, round(b * 7 / 255)))
    b0 = ((r3 & 0x07) << 4) | (b3 & 0x07)
    b1 = g3 & 0x07
    return (b0, b1)


def make_palette_entry_from_raw(raw_val: int) -> PaletteEntry:
    """16bit V9938生値からPaletteEntryを生成する"""
    b0 = raw_val & 0xFF
    b1 = (raw_val >> 8) & 0xFF
    r3 = (b0 >> 4) & 0x07
    b3 = b0 & 0x07
    g3 = b1 & 0x07
    r8, g8, b8 = v9938_to_rgb(b0, b1)
    return PaletteEntry(raw=raw_val, r3=r3, g3=g3, b3=b3, r=r8, g=g8, b=b8)


def make_palette_entry_from_rgb333(r3: int, g3: int, b3: int) -> PaletteEntry:
    """3bit RGB (0-7) からPaletteEntryを生成する"""
    r3_clamped = max(0, min(7, r3))
    g3_clamped = max(0, min(7, g3))
    b3_clamped = max(0, min(7, b3))
    b0 = ((r3_clamped & 0x07) << 4) | (b3_clamped & 0x07)
    b1 = g3_clamped & 0x07
    raw_val = b0 | (b1 << 8)
    r8, g8, b8 = v9938_to_rgb(b0, b1)
    return PaletteEntry(raw=raw_val, r3=r3_clamped, g3=g3_clamped, b3=b3_clamped, r=r8, g=g8, b=b8)


def make_palette_entry_from_rgb888(r: int, g: int, b: int) -> PaletteEntry:
    """24bit RGB (0-255) からPaletteEntryを生成する"""
    b0, b1 = rgb_to_v9938(r, g, b)
    raw_val = b0 | (b1 << 8)
    r3 = (b0 >> 4) & 0x07
    b3 = b0 & 0x07
    g3 = b1 & 0x07
    r8, g8, b8 = v9938_to_rgb(b0, b1)
    return PaletteEntry(raw=raw_val, r3=r3, g3=g3, b3=b3, r=r8, g=g8, b=b8)


# ==============================================================================
# ヘッダ解析・構築ルーチン
# ==============================================================================

def parse_pic_header(header_bytes: bytes) -> PicHeader:
    """先頭16バイトのバイナリからPicHeaderオブジェクトを生成する"""
    if len(header_bytes) < 16:
        raise ValueError(f"制御ヘッダ長が不足しています (必要: 16バイト, 入力: {len(header_bytes)}バイト)")

    screen_mode, dx, dy, nx, ny, reserved = struct.unpack_from('<HHHHH6s', header_bytes, 0)

    return PicHeader(
        screen_mode=screen_mode,
        dest_x=dx,
        dest_y=dy,
        width_bytes=nx,
        height_lines=ny,
        reserved=reserved
    )


def build_pic_header(header: PicHeader) -> bytes:
    """PicHeaderオブジェクトから16バイトの制御ヘッダバイナリを構築する"""
    reserved = header.reserved
    if len(reserved) < 6:
        reserved = reserved.ljust(6, b'\x00')
    elif len(reserved) > 6:
        reserved = reserved[:6]

    return struct.pack(
        '<HHHHH6s',
        header.screen_mode,
        header.dest_x,
        header.dest_y,
        header.width_bytes,
        header.height_lines,
        reserved
    )


def parse_pic_palette(palette_bytes: bytes) -> list[PaletteEntry]:
    """32バイトのバイナリから16色のPaletteEntry配列を生成する"""
    if len(palette_bytes) < 32:
        raise ValueError(f"パレットデータ長が不足しています (必要: 32バイト, 入力: {len(palette_bytes)}バイト)")

    palette: list[PaletteEntry] = []
    for i in range(16):
        b0 = palette_bytes[i * 2]
        b1 = palette_bytes[i * 2 + 1]
        raw_val = b0 | (b1 << 8)
        palette.append(make_palette_entry_from_raw(raw_val))
    return palette


def build_pic_palette(palette: list[PaletteEntry]) -> bytes:
    """16色のPaletteEntry配列から32バイトのパレットバイナリを構築する"""
    pal_bytes = bytearray(32)
    for i in range(16):
        if i < len(palette):
            entry = palette[i]
            b0 = entry.raw & 0xFF
            b1 = (entry.raw >> 8) & 0xFF
        else:
            b0, b1 = 0, 0
        pal_bytes[i * 2] = b0
        pal_bytes[i * 2 + 1] = b1
    return bytes(pal_bytes)


# ==============================================================================
# 走査線単位 RLE展開・圧縮アルゴリズム
# ==============================================================================

def decompress_rle(data: bytes, offset: int, width_bytes: int, height_lines: int) -> bytearray:
    """
    走査線（1行＝NXバイト）単位で完結する同値2バイト連続検出型RLE伸長を行う。
    行末で必ずラン判定をリセットし、走査線境界を跨いだ誤結合を防止する。
    """
    output = bytearray()
    pos = offset
    data_len = len(data)

    for _ in range(height_lines):
        row_bytes = 0
        while row_bytes < width_bytes and pos < data_len:
            b1 = data[pos]
            pos += 1
            output.append(b1)
            row_bytes += 1

            if row_bytes >= width_bytes or pos >= data_len:
                break

            b2 = data[pos]
            if b1 == b2:
                # 同一値が連続したためランモードへ移行
                pos += 1  # 2バイト目を消費
                if pos >= data_len:
                    break
                count = data[pos]
                pos += 1

                # すでに1バイトは出力済みのため残り (count - 1) 回出力
                remaining_run = count - 1
                if remaining_run > 0:
                    needed = width_bytes - row_bytes
                    to_write = min(remaining_run, needed)
                    output.extend([b1] * to_write)
                    row_bytes += to_write
            else:
                # b2 != b1 の場合、b1 は単独バイトとして確定
                # 次のループで b2 が Byte1 として処理されるよう pos は進めない
                pass

    return output


def compress_rle(data: bytes | bytearray, width_bytes: int, height_lines: int, max_run: int = 0x6B) -> bytearray:
    """
    走査線（1行＝NXバイト）単位で完結する同値2バイト連続検出型RLE圧縮を行う。
    走査線境界を跨いでランを継続させず、行末で必ず完結させる。
    """
    output = bytearray()
    total_len = len(data)

    for line in range(height_lines):
        line_start = line * width_bytes
        line_end = min(line_start + width_bytes, total_len)
        i = line_start

        while i < line_end:
            val = data[i]
            if i + 1 < line_end and data[i + 1] == val:
                # 連続長を計測
                run_len = 2
                while (i + run_len < line_end and
                       data[i + run_len] == val and
                       run_len < max_run):
                    run_len += 1

                output.append(val)
                output.append(val)
                output.append(run_len)
                i += run_len
            else:
                output.append(val)
                i += 1

    return output


def pad_to_sector(data: bytes | bytearray, sector_size: int = 512) -> bytearray:
    """512バイト境界まで 0x00 でパディングする"""
    out = bytearray(data)
    remainder = len(out) % sector_size
    if remainder != 0:
        out.extend(b'\x00' * (sector_size - remainder))
    return out


# ==============================================================================
# 自前 4bpp BMP エンコード / デコード
# ==============================================================================

def save_bmp_4bpp(filepath: str, width: int, height: int, palette_rgb: list[tuple[int, int, int]], pixel_bytes: bytes) -> None:
    """MSX SCREEN 5形式のピクセルバイト列を4bpp Windows BMPとして保存する"""
    row_bytes = width // 2
    stride = (row_bytes + 3) & ~3
    padding_len = stride - row_bytes
    padding = b'\x00' * padding_len

    image_size = stride * height
    bf_off_bits = 14 + 40 + 16 * 4  # 118バイト
    bf_size = bf_off_bits + image_size

    file_header = struct.pack('<2sIHHI', b'BM', bf_size, 0, 0, bf_off_bits)
    info_header = struct.pack(
        '<IIIHHIIIIII',
        40, width, height, 1, 4, 0, image_size, 0, 0, 16, 16
    )

    palette_data = bytearray()
    for i in range(16):
        if i < len(palette_rgb):
            r, g, b = palette_rgb[i]
        else:
            r, g, b = (0, 0, 0)
        palette_data.extend([b, g, r, 0])

    pixel_data = bytearray()
    for y in range(height - 1, -1, -1):
        start = y * row_bytes
        pixel_data.extend(pixel_bytes[start:start + row_bytes])
        if padding_len > 0:
            pixel_data.extend(padding)

    with open(filepath, 'wb') as f:
        f.write(file_header + info_header + bytes(palette_data) + bytes(pixel_data))


def load_bmp_4bpp(filepath: str) -> tuple[int, int, list[tuple[int, int, int]], bytes]:
    """4bpp BMPファイルを読み込み、(幅, 高さ, パレットRGBリスト, SCREEN 5バイト列) を返す"""
    with open(filepath, 'rb') as f:
        data = f.read()

    if len(data) < 54 or data[:2] != b'BM':
        raise ValueError("有効なBMPファイルではありません。")

    bf_off_bits = struct.unpack_from('<I', data, 10)[0]
    bi_size = struct.unpack_from('<I', data, 14)[0]
    width = struct.unpack_from('<i', data, 18)[0]
    height_raw = struct.unpack_from('<i', data, 22)[0]
    bit_count = struct.unpack_from('<H', data, 28)[0]
    compression = struct.unpack_from('<I', data, 30)[0]
    clr_used = struct.unpack_from('<I', data, 46)[0]

    if bit_count != 4:
        raise ValueError(f"4bpp (16色) インデックスカラーBMPのみ対応しています。(入力: {bit_count}bpp)")
    if compression != 0:
        raise ValueError("非圧縮 (BI_RGB) BMPのみ対応しています。")

    height = abs(height_raw)
    is_bottom_up = (height_raw > 0)

    palette_rgb: list[tuple[int, int, int]] = []
    pal_offset = 14 + bi_size
    num_colors = clr_used if clr_used > 0 else 16
    for i in range(16):
        if i < num_colors and pal_offset + i * 4 + 3 <= len(data):
            b = data[pal_offset + i * 4]
            g = data[pal_offset + i * 4 + 1]
            r = data[pal_offset + i * 4 + 2]
            palette_rgb.append((r, g, b))
        else:
            palette_rgb.append((0, 0, 0))

    row_bytes = (width + 1) // 2
    stride = (row_bytes + 3) & ~3

    rows: list[bytes] = []
    pos = bf_off_bits
    for _ in range(height):
        rows.append(data[pos:pos + row_bytes])
        pos += stride

    if is_bottom_up:
        rows.reverse()

    return (width, height, palette_rgb, b''.join(rows))


# ==============================================================================
# 自前 4bpp/8bpp PNG エンコード / デコード (外部ライブラリ非依存)
# ==============================================================================

def _make_png_chunk(chunk_type: bytes, data: bytes) -> bytes:
    """PNGチャンク (長さ + タイプ + データ + CRC32) を生成する"""
    length = len(data)
    crc = zlib.crc32(chunk_type + data) & 0xFFFFFFFF
    return struct.pack('>I', length) + chunk_type + data + struct.pack('>I', crc)


def _paeth_predictor(a: int, b: int, c: int) -> int:
    """PNG仕様に基づくPaeth予測関数"""
    p = a + b - c
    pa = abs(p - a)
    pb = abs(p - b)
    pc = abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    elif pb <= pc:
        return b
    return c


def save_png_4bpp(filepath: str, width: int, height: int, palette_rgb: list[tuple[int, int, int]], pixel_bytes: bytes) -> None:
    """MSX SCREEN 5形式のピクセルバイト列を4bppインデックスカラーPNGとして保存する"""
    sig = b'\x89PNG\r\n\x1a\n'

    ihdr_data = struct.pack('>IIBBBBB', width, height, 4, 3, 0, 0, 0)
    ihdr = _make_png_chunk(b'IHDR', ihdr_data)

    plte_data = bytearray()
    for i in range(16):
        if i < len(palette_rgb):
            r, g, b = palette_rgb[i]
        else:
            r, g, b = (0, 0, 0)
        plte_data.extend([r, g, b])
    plte = _make_png_chunk(b'PLTE', bytes(plte_data))

    row_bytes = width // 2
    raw_scanlines = bytearray()
    for y in range(height):
        raw_scanlines.append(0)  # Filter: None
        start = y * row_bytes
        raw_scanlines.extend(pixel_bytes[start:start + row_bytes])

    compressed = zlib.compress(bytes(raw_scanlines), level=9)
    idat = _make_png_chunk(b'IDAT', compressed)
    iend = _make_png_chunk(b'IEND', b'')

    with open(filepath, 'wb') as f:
        f.write(sig + ihdr + plte + idat + iend)


def load_png_indexed(filepath: str) -> tuple[int, int, list[tuple[int, int, int]], bytes]:
    """PNGファイルを解析し、(幅, 高さ, パレットRGBリスト, SCREEN 5バイト列) を返す"""
    with open(filepath, 'rb') as f:
        data = f.read()

    if len(data) < 8 or data[:8] != b'\x89PNG\r\n\x1a\n':
        raise ValueError("有効なPNGファイルではありません。")

    pos = 8
    ihdr_found = False
    plte_found = False
    width = 0
    height = 0
    bit_depth = 0
    color_type = 0
    palette_rgb: list[tuple[int, int, int]] = []
    idat_chunks: list[bytes] = []

    while pos < len(data):
        if pos + 8 > len(data):
            break
        chunk_len = struct.unpack_from('>I', data, pos)[0]
        chunk_type = data[pos + 4:pos + 8]
        pos += 8
        chunk_data = data[pos:pos + chunk_len]
        pos += chunk_len + 4

        if chunk_type == b'IHDR':
            width, height, bit_depth, color_type, _, _, inter = struct.unpack('>IIBBBBB', chunk_data)
            ihdr_found = True
            if inter != 0:
                raise ValueError("インタレースPNGには未対応です。ノンインタレース形式で保存してください。")
        elif chunk_type == b'PLTE':
            plte_found = True
            num_colors = len(chunk_data) // 3
            for i in range(16):
                if i < num_colors:
                    r = chunk_data[i * 3]
                    g = chunk_data[i * 3 + 1]
                    b = chunk_data[i * 3 + 2]
                    palette_rgb.append((r, g, b))
                else:
                    palette_rgb.append((0, 0, 0))
        elif chunk_type == b'IDAT':
            idat_chunks.append(chunk_data)
        elif chunk_type == b'IEND':
            break

    if not ihdr_found:
        raise ValueError("PNG IHDRチャンクが見つかりません。")

    if color_type != 3 or bit_depth not in (4, 8):
        if HAS_PILLOW:
            return load_image_with_pillow(filepath)
        raise ValueError(
            f"インデックスカラー (4bppまたは8bpp) のPNGのみ対応しています。(color_type={color_type}, bit_depth={bit_depth})"
        )

    if not plte_found:
        raise ValueError("PNG PLTEチャンクが見つかりません。")

    decompressed = zlib.decompress(b''.join(idat_chunks))

    stride = (width * bit_depth + 7) // 8
    expected_len = height * (1 + stride)
    if len(decompressed) < expected_len:
        raise ValueError("PNG画像ストリームのサイズが不足しています。")

    raw_rows: list[bytes] = []
    dpos = 0
    prev_row = bytearray(stride)
    bpp = 1

    for _ in range(height):
        filter_type = decompressed[dpos]
        dpos += 1
        scanline = decompressed[dpos:dpos + stride]
        dpos += stride

        current_row = bytearray(stride)
        for i in range(stride):
            x = scanline[i]
            a = current_row[i - bpp] if i >= bpp else 0
            b = prev_row[i]
            c = prev_row[i - bpp] if i >= bpp else 0

            if filter_type == 0:
                val = x
            elif filter_type == 1:
                val = (x + a) & 0xFF
            elif filter_type == 2:
                val = (x + b) & 0xFF
            elif filter_type == 3:
                val = (x + ((a + b) >> 1)) & 0xFF
            elif filter_type == 4:
                val = (x + _paeth_predictor(a, b, c)) & 0xFF
            else:
                raise ValueError(f"未対応のPNGフィルタタイプです: {filter_type}")

            current_row[i] = val

        raw_rows.append(bytes(current_row))
        prev_row = current_row

    if bit_depth == 4:
        row_bytes = (width + 1) // 2
        pixel_bytes = b''.join(r[:row_bytes] for r in raw_rows)
    else:
        packed_rows = bytearray()
        for r in raw_rows:
            for x in range(0, width, 2):
                idx0 = r[x] & 0x0F
                idx1 = (r[x + 1] & 0x0F) if x + 1 < width else 0
                packed_rows.append((idx0 << 4) | idx1)
        pixel_bytes = bytes(packed_rows)

    return (width, height, palette_rgb, pixel_bytes)


def load_image_with_pillow(filepath: str) -> tuple[int, int, list[tuple[int, int, int]], bytes]:
    """Pillowを用いた一般的な画像ファイルの読み込みフォールバック"""
    img = Image.open(filepath)
    width, height = img.size

    if img.mode != 'P':
        img = img.convert('P', palette=Image.Palette.ADAPTIVE, colors=16)

    raw_pal = img.getpalette()
    palette_rgb: list[tuple[int, int, int]] = []
    for i in range(16):
        if raw_pal and i * 3 + 2 < len(raw_pal):
            palette_rgb.append((raw_pal[i * 3], raw_pal[i * 3 + 1], raw_pal[i * 3 + 2]))
        else:
            palette_rgb.append((0, 0, 0))

    pixels = list(img.getdata())
    packed = bytearray()
    for y in range(height):
        row_start = y * width
        for x in range(0, width, 2):
            idx0 = pixels[row_start + x] & 0x0F
            idx1 = (pixels[row_start + x + 1] & 0x0F) if x + 1 < width else 0
            packed.append((idx0 << 4) | idx1)

    return (width, height, palette_rgb, bytes(packed))


def load_image_auto(filepath: str) -> tuple[int, int, list[tuple[int, int, int]], bytes]:
    """拡張子に応じてBMPまたはPNGを読み込む"""
    ext = os.path.splitext(filepath)[1].lower()
    if ext == '.bmp':
        return load_bmp_4bpp(filepath)
    elif ext == '.png':
        return load_png_indexed(filepath)
    else:
        if HAS_PILLOW:
            return load_image_with_pillow(filepath)
        raise ValueError(f"未対応の拡張子です: {ext} (.png または .bmp を指定してください)")


def save_image_auto(filepath: str, width: int, height: int, palette_rgb: list[tuple[int, int, int]], pixel_bytes: bytes, fmt: str = 'png') -> None:
    """指定されたフォーマットで画像を保存する"""
    fmt_lower = fmt.lower()
    if fmt_lower == 'bmp':
        save_bmp_4bpp(filepath, width, height, palette_rgb, pixel_bytes)
    elif fmt_lower == 'png':
        save_png_4bpp(filepath, width, height, palette_rgb, pixel_bytes)
    else:
        raise ValueError(f"未対応の出力フォーマットです: {fmt}")


# ==============================================================================
# JSONメタデータ入出力 (インライン整形)
# ==============================================================================

def save_metadata_json(filepath: str, asset: PicAsset) -> None:
    """アセットの制御パラメータとパレットをJSONに出力する"""
    pal_data = []
    for i, entry in enumerate(asset.palette):
        pal_data.append({
            "index": i,
            "raw": f"0x{entry.raw:04X}",
            "rgb333": [entry.r3, entry.g3, entry.b3],
            "rgb888": [entry.r, entry.g, entry.b]
        })

    meta = {
        "screen_mode": asset.header.screen_mode,
        "dx": asset.header.dest_x,
        "dy": asset.header.dest_y,
        "nx_bytes": asset.header.width_bytes,
        "ny_lines": asset.header.height_lines,
        "width_pixels": asset.header.width_bytes * 2,
        "height_pixels": asset.header.height_lines,
        "reserved_hex": asset.header.reserved.hex().upper(),
        "palette": pal_data
    }

    json_text = json.dumps(meta, indent=2, ensure_ascii=False)
    # rgb333 / rgb888 の短い数値配列を1行に整形
    json_text = re.sub(
        r'("rgb(?:333|888)":\s*)\[\s*(\d+),\s*(\d+),\s*(\d+)\s*\]',
        r'\1[\2, \3, \4]',
        json_text
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(json_text + "\n")


def load_metadata_json(filepath: str) -> dict:
    """JSONファイルからメタデータを読み込む"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


# ==============================================================================
# PICおよびBINの展開・構築ロジック (コア処理)
# ==============================================================================

def decode_pic_data(pic_bytes: bytes, offset: int = 0) -> PicAsset:
    """PICバイナリからPicAssetを復元する"""
    if len(pic_bytes) < offset + 48:
        raise ValueError("指定オフセット以降のデータ長がヘッダサイズ (48バイト) 未満です。")

    header = parse_pic_header(pic_bytes[offset:offset + 16])
    palette = parse_pic_palette(pic_bytes[offset + 16:offset + 48])
    target_size = header.width_bytes * header.height_lines
    pixels = decompress_rle(pic_bytes, offset + 48, header.width_bytes, header.height_lines)

    if len(pixels) < target_size:
        print(f"警告: 展開データサイズが不足しています (展開: {len(pixels)}バイト, 規定: {target_size}バイト)", file=sys.stderr)

    return PicAsset(header=header, palette=palette, pixels=pixels)


def encode_pic_asset(asset: PicAsset, max_run: int = 0x6B, pad_sector: bool = True) -> bytes:
    """PicAssetから圧縮PICバイナリを生成する"""
    header_bytes = build_pic_header(asset.header)
    palette_bytes = build_pic_palette(asset.palette)
    compressed_pixels = compress_rle(asset.pixels, asset.header.width_bytes, asset.header.height_lines, max_run=max_run)

    raw_output = bytearray(header_bytes + palette_bytes + compressed_pixels)
    if pad_sector:
        return bytes(pad_to_sector(raw_output, 512))
    return bytes(raw_output)


def decode_bin_data(bin_bytes: bytes) -> PicAsset:
    """完全な非圧縮PICバイナリ (制御ヘッダ16バイト + パレット32バイト + 非圧縮ピクセルデータ) からPicAssetを生成する"""
    if len(bin_bytes) < 48:
        raise ValueError("バイナリサイズがヘッダサイズ (48バイト) 未満です。")

    header = parse_pic_header(bin_bytes[:16])
    palette = parse_pic_palette(bin_bytes[16:48])
    pixels = bytearray(bin_bytes[48:])
    expected_size = header.width_bytes * header.height_lines

    if len(pixels) != expected_size:
        print(f"警告: BINピクセルサイズがヘッダ規定と異なります (実測: {len(pixels)}バイト, 規定: {expected_size}バイト)", file=sys.stderr)

    return PicAsset(header=header, palette=palette, pixels=pixels)


def encode_bin_asset(asset: PicAsset) -> bytes:
    """PicAssetから完全な非圧縮PICバイナリ (制御ヘッダ16バイト + パレット32バイト + 非圧縮ピクセルデータ) を構築する"""
    header_bytes = build_pic_header(asset.header)
    palette_bytes = build_pic_palette(asset.palette)
    return header_bytes + palette_bytes + bytes(asset.pixels)


# ==============================================================================
# コマンドラインハンドラ
# ==============================================================================

def parse_int_auto(val_str: str) -> int:
    """10進数または16進数 (0xプレフィックス) の文字列を整数へ変換する"""
    val_str = val_str.strip()
    if val_str.lower().startswith('0x'):
        return int(val_str, 16)
    return int(val_str, 10)


def cmd_decode(args: argparse.Namespace) -> None:
    """PICファイル展開コマンド"""
    input_path = args.input
    if not os.path.exists(input_path):
        print(f"エラー: 入力ファイルが存在しません: {input_path}", file=sys.stderr)
        sys.exit(1)

    with open(input_path, 'rb') as f:
        data = f.read()

    is_offset_specified = args.offset is not None
    offset = parse_int_auto(args.offset) if is_offset_specified else 0
    asset = decode_pic_data(data, offset=offset)

    base_name = os.path.splitext(os.path.basename(input_path))[0]
    if is_offset_specified:
        base_name += f"_0x{offset:05X}"

    out_dir = args.out_dir if args.out_dir else "."
    os.makedirs(out_dir, exist_ok=True)

    target_base = os.path.join(out_dir, base_name)

    # 1. 画像出力 (パレット + ピクセルデータ)
    if not args.no_image:
        img_ext = f".{args.format.lower()}"
        img_path = target_base + img_ext
        palette_rgb = [(e.r, e.g, e.b) for e in asset.palette]
        width_pixels = asset.header.width_bytes * 2
        height_pixels = asset.header.height_lines
        save_image_auto(img_path, width_pixels, height_pixels, palette_rgb, asset.pixels, fmt=args.format)
        print(f"画像出力完了: {img_path} ({width_pixels}x{height_pixels})")

    # 2. メタデータJSON出力 (制御ヘッダ + パレット)
    if not args.no_json:
        json_path = target_base + ".json"
        save_metadata_json(json_path, asset)
        print(f"メタデータ出力完了: {json_path}")

    # 3. 非圧縮BIN出力 (制御ヘッダ16バイト + パレット32バイト + 非圧縮ピクセルデータ)
    if not args.no_bin:
        bin_path = target_base + ".bin"
        bin_bytes = encode_bin_asset(asset)
        with open(bin_path, 'wb') as f:
            f.write(bin_bytes)
        print(f"非圧縮PICバイナリ出力完了: {bin_path} ({len(bin_bytes)} バイト)")


def cmd_encode(args: argparse.Namespace) -> None:
    """PICファイル圧縮生成コマンド"""
    input_path = args.input
    if not os.path.exists(input_path):
        print(f"エラー: 入力ファイルが存在しません: {input_path}", file=sys.stderr)
        sys.exit(1)

    output_path = args.output if args.output else os.path.splitext(input_path)[0] + ".PIC"
    ext = os.path.splitext(input_path)[1].lower()

    dx: int | None = parse_int_auto(args.dx) if args.dx is not None else None
    dy: int | None = parse_int_auto(args.dy) if args.dy is not None else None
    reserved = b'\x00' * 6
    palette_entries: list[PaletteEntry] = []

    # メタデータJSONの探索と読み込み
    json_path = args.json if args.json else os.path.splitext(input_path)[0] + ".json"
    meta_json = None
    if os.path.exists(json_path):
        try:
            meta_json = load_metadata_json(json_path)
            if dx is None and "dx" in meta_json:
                dx = meta_json["dx"]
            if dy is None and "dy" in meta_json:
                dy = meta_json["dy"]
            if "reserved_hex" in meta_json:
                reserved = bytes.fromhex(meta_json["reserved_hex"])
            if "palette" in meta_json and isinstance(meta_json["palette"], list):
                palette_entries = []
                for item in meta_json["palette"]:
                    if "rgb333" in item:
                        r3, g3, b3 = item["rgb333"]
                        palette_entries.append(make_palette_entry_from_rgb333(r3, g3, b3))
                    elif "raw" in item:
                        raw_val = parse_int_auto(str(item["raw"]))
                        palette_entries.append(make_palette_entry_from_raw(raw_val))
                    elif "rgb888" in item:
                        r8, g8, b8 = item["rgb888"]
                        palette_entries.append(make_palette_entry_from_rgb888(r8, g8, b8))
        except Exception as e:
            print(f"メタデータJSON読み込み警告: {e}", file=sys.stderr)

    # 既存PIC/BINからのヘッダ引継ぎ
    if args.keep_header:
        if not os.path.exists(args.keep_header):
            print(f"エラー: 引継ぎ元ファイルが存在しません: {args.keep_header}", file=sys.stderr)
            sys.exit(1)
        with open(args.keep_header, 'rb') as f:
            raw_keep = f.read(48)
        base_hdr = parse_pic_header(raw_keep[:16])
        base_pal = parse_pic_palette(raw_keep[16:48])
        if dx is None:
            dx = base_hdr.dest_x
        if dy is None:
            dy = base_hdr.dest_y
        reserved = base_hdr.reserved
        if not palette_entries:
            palette_entries = base_pal

    # 入力ファイル形式に応じたアセット構築
    if ext in ('.png', '.bmp'):
        width, height, pal_rgb, pixel_bytes = load_image_auto(input_path)
        if width % 2 != 0:
            print(f"エラー: 画像幅 ({width}) が奇数です。MSX SCREEN 5形式では偶数ピクセル幅である必要があります。", file=sys.stderr)
            sys.exit(1)

        nx = width // 2
        ny = height

        # JSON等でパレットが未定義の場合は画像パレットを採用
        if not palette_entries:
            for r, g, b in pal_rgb:
                palette_entries.append(make_palette_entry_from_rgb888(r, g, b))

    elif ext == '.bin':
        # 48バイトヘッダ付き非圧縮PICバイナリからの読み込み
        with open(input_path, 'rb') as f:
            bin_data = f.read()

        bin_asset = decode_bin_data(bin_data)
        nx = bin_asset.header.width_bytes
        ny = bin_asset.header.height_lines
        pixel_bytes = bin_asset.pixels

        if dx is None:
            dx = bin_asset.header.dest_x
        if dy is None:
            dy = bin_asset.header.dest_y
        if reserved == b'\x00' * 6:
            reserved = bin_asset.header.reserved
        if not palette_entries:
            palette_entries = bin_asset.palette
    else:
        print(f"エラー: 未対応の入力ファイル形式です: {ext}", file=sys.stderr)
        sys.exit(1)

    # パラメータのデフォルト値補正
    final_dx = dx if dx is not None else 0
    final_dy = dy if dy is not None else 0

    while len(palette_entries) < 16:
        palette_entries.append(make_palette_entry_from_rgb888(0, 0, 0))
    if len(palette_entries) > 16:
        palette_entries = palette_entries[:16]

    header = PicHeader(
        screen_mode=0x0005,
        dest_x=final_dx,
        dest_y=final_dy,
        width_bytes=nx,
        height_lines=ny,
        reserved=reserved
    )

    asset = PicAsset(header=header, palette=palette_entries, pixels=bytearray(pixel_bytes))

    max_run = 255 if args.unlimited_run else 0x6B
    pad_sector = not args.no_pad

    output_bytes = encode_pic_asset(asset, max_run=max_run, pad_sector=pad_sector)

    with open(output_path, 'wb') as f:
        f.write(output_bytes)

    print(f"PICファイル生成完了: {output_path}")
    print(f"  サイズ: {len(output_bytes)} バイト (セクタ数: {len(output_bytes) // 512})")
    print(f"  配置設定: DX={final_dx}, DY={final_dy}, 幅={nx}バイト ({nx * 2}ピクセル), 高さ={ny}行")


def cmd_info(args: argparse.Namespace) -> None:
    """PICファイル構造解析・情報表示コマンド"""
    input_path = args.input
    if not os.path.exists(input_path):
        print(f"エラー: 入力ファイルが存在しません: {input_path}", file=sys.stderr)
        sys.exit(1)

    with open(input_path, 'rb') as f:
        data = f.read()

    offset = parse_int_auto(args.offset)
    if len(data) < offset + 48:
        print("エラー: 指定オフセット以降のデータ長がヘッダサイズ未満です。", file=sys.stderr)
        sys.exit(1)

    hdr = parse_pic_header(data[offset:offset + 16])
    pal = parse_pic_palette(data[offset + 16:offset + 48])
    width_px = hdr.width_bytes * 2
    raw_size = hdr.width_bytes * hdr.height_lines

    print("=" * 64)
    print(f"PICヘッダ情報: {input_path} (開始オフセット: 0x{offset:06X})")
    print("=" * 64)
    print(f"画面モード (ScreenMode) : 0x{hdr.screen_mode:04X} (SCREEN 5: 256x212 16色)")
    print(f"転送先座標 (DX, DY)     : ({hdr.dest_x}, {hdr.dest_y})")
    print(f"転送サイズ (NX, NY)     : 幅 {hdr.width_bytes} バイト ({width_px} ピクセル), 高さ {hdr.height_lines} 行")
    print(f"展開後データ総サイズ    : {raw_size:,} バイト")
    print(f"予約領域 (Reserved)     : {hdr.reserved.hex().upper()}")
    print("-" * 64)
    print("パレットデータ (V9938形式 / RGB888換算):")
    for i, e in enumerate(pal):
        print(f"  [{i:02d}] Raw: 0x{e.raw:04X} | rgb333: [{e.r3}, {e.g3}, {e.b3}] -> rgb888: [{e.r:3d}, {e.g:3d}, {e.b:3d}]")
    print("=" * 64)


# ==============================================================================
# メインエントリーポイント
# ==============================================================================

def main() -> None:
    parser = argparse.ArgumentParser(
        prog="FFPicTool",
        description="MSX2版『ファイナルファンタジー』PICファイル操作ツール"
    )
    subparsers = parser.add_subparsers(dest="subcommand", help="実行コマンド")

    # decode サブコマンド
    p_dec = subparsers.add_parser("decode", aliases=["d", "unpack", "extract"], help="PICファイルを展開する")
    p_dec.add_argument("input", help="入力PICファイルパス")
    p_dec.add_argument("-d", "--out-dir", default="", help="出力先ディレクトリ")
    p_dec.add_argument("-a", "--address", "--offset", dest="offset", default=None, help="開始オフセット (10進数または 0x1000 形式)")
    p_dec.add_argument("-f", "--format", choices=["png", "bmp"], default="png", help="出力画像形式 (デフォルト: png)")
    p_dec.add_argument("--no-image", action="store_true", help="画像の出力を抑止する")
    p_dec.add_argument("--no-bin", action="store_true", help="非圧縮PICバイナリ(.bin)の出力を抑止する")
    p_dec.add_argument("--no-json", action="store_true", help="メタデータJSONの出力を抑止する")
    p_dec.set_defaults(func=cmd_decode)

    # encode サブコマンド
    p_enc = subparsers.add_parser("encode", aliases=["e", "pack", "compress"], help="画像または非圧縮データからPICファイルを生成する")
    p_enc.add_argument("input", help="入力ファイルパス (.png, .bmp, .bin)")
    p_enc.add_argument("-o", "--output", help="出力PICファイルパス (未指定時は入力名.PIC)")
    p_enc.add_argument("-x", "--dx", help="転送先VRAM X座標 (ドット位置)")
    p_enc.add_argument("-y", "--dy", help="転送先VRAM Y走査線番号 (0-255)")
    p_enc.add_argument("--json", help="パラメータ記述JSONファイルの明示指定")
    p_enc.add_argument("--keep-header", help="既存PIC/BINファイルを指定し、配置座標や予約領域を引き継ぐ")
    p_enc.add_argument("--unlimited-run", action="store_true", help="連続長上限 (0x6B / 107) を撤廃し255まで使用する")
    p_enc.add_argument("--no-pad", action="store_true", help="512バイト境界への0x00セクタパディングを抑止する")
    p_enc.set_defaults(func=cmd_encode)

    # info サブコマンド
    p_info = subparsers.add_parser("info", aliases=["dump"], help="PICファイルのヘッダ情報を表示する")
    p_info.add_argument("input", help="解析対象のPICファイルパス")
    p_info.add_argument("-a", "--address", "--offset", dest="offset", default="0", help="開始オフセット (10進数または 0x1000 形式)")
    p_info.set_defaults(func=cmd_info)

    args = parser.parse_args()
    if not hasattr(args, "func"):
        parser.print_help()
        sys.exit(1)

    args.func(args)


if __name__ == "__main__":
    main()
