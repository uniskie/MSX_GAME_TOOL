#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
256x256 4bit BMP を Windows標準 BI_RLE4 形式に圧縮し、
JavaScript埋め込み用のBase64文字列を出力するツール
"""

import sys
import os
import struct
import base64

def convert_bmp_to_rle4(input_path, output_bmp_path=None, output_js_path=None):
    if not os.path.exists(input_path):
        print(f"エラー: 入力ファイルが見つかりません: {input_path}", file=sys.stderr)
        return False

    with open(input_path, "rb") as f:
        data = f.read()

    # 1. BMPファイルヘッダ (14バイト) 解析
    if len(data) < 54 or data[0:2] != b"BM":
        print("エラー: 有効なBMPファイルではありません。", file=sys.stderr)
        return False

    # <IHHI : bfSize(4B), bfReserved1(2B), bfReserved2(2B), bfOffBits(4B)
    file_size, res1, res2, off_bits = struct.unpack_from("<IHHI", data, 2)

    # 2. BITMAPINFOHEADER (40バイト) 解析
    header_size, width, height, planes, bit_count, compression, size_image, x_ppm, y_ppm, clr_used, clr_important = struct.unpack_from(
        "<IiiHHIIiiII", data, 14
    )

    if width != 256 or abs(height) != 256 or bit_count != 4:
        print(f"エラー: 256x256 4bit BMP のみ対応しています (現在: {width}x{height}, {bit_count}bit)。", file=sys.stderr)
        return False

    is_bottom_up = (height > 0)
    abs_height = abs(height)

    # 3. パレット (16色 × 4バイト = 64バイト)
    palette_offset = 14 + header_size
    palette_data = data[palette_offset:off_bits]

    # 4. ピクセルデータの展開 (ボトムアップ順: Y=255からY=0の順に正規化)
    row_stride = ((width * 4 + 31) // 32) * 4 # 4バイト境界アライメント (128バイト)
    bottom_up_rows = []

    for y in range(abs_height):
        # y=0 が最下行、y=abs_height-1 が最上行
        src_y = y if is_bottom_up else (abs_height - 1 - y)
        row_offset = off_bits + src_y * row_stride

        row = [0] * width
        for col_idx in range(0, width, 2):
            b = data[row_offset + (col_idx // 2)]
            row[col_idx] = (b >> 4) & 0x0F
            row[col_idx + 1] = b & 0x0F
        bottom_up_rows.append(row)

    # 5. BI_RLE4 圧縮エンコード (ボトムアップ順)
    rle_data = bytearray()

    for row in bottom_up_rows:
        x = 0
        while x < width:
            color = row[x]
            run_len = 1
            # 同一色の連続長をカウント (最大長 255)
            while x + run_len < width and row[x + run_len] == color and run_len < 255:
                run_len += 1

            # エンコードモード: [連続ピクセル数, (色 << 4) | 色]
            rle_data.append(run_len)
            rle_data.append((color << 4) | color)
            x += run_len

        # 行末マーカー (End of Line: 0x00, 0x00)
        rle_data.append(0x00)
        rle_data.append(0x00)

    # ビットマップ終端マーカー (End of Bitmap: 0x00, 0x01)
    rle_data.append(0x00)
    rle_data.append(0x01)

    # 6. BI_RLE4 BMPバイナリの構築
    new_header_size = 40
    new_palette_size = len(palette_data)
    new_off_bits = 14 + new_header_size + new_palette_size
    new_file_size = new_off_bits + len(rle_data)

    new_file_header = struct.pack("<2sIHHI", b"BM", new_file_size, 0, 0, new_off_bits)
    new_info_header = struct.pack(
        "<IiiHHIIiiII",
        new_header_size,
        width,
        abs_height, # 正数 (ボトムアップ)
        1,          # planes
        4,          # 4bit
        2,          # BI_RLE4 (圧縮形式: 2)
        len(rle_data),
        x_ppm,
        y_ppm,
        16,         # clr_used
        0
    )

    full_rle_bmp = new_file_header + new_info_header + palette_data + bytes(rle_data)
    b64_str = base64.b64encode(full_rle_bmp).decode("ascii")

    # 7. ファイル保存・結果表示
    orig_size = len(data)
    comp_size = len(full_rle_bmp)
    ratio = (comp_size / orig_size) * 100

    print("==================================================")
    print("【BI_RLE4 BMP 変換結果】")
    print(f"入力ファイル: {input_path}")
    print(f"元サイズ    : {orig_size:,} bytes")
    print(f"圧縮サイズ  : {comp_size:,} bytes (圧縮率: {ratio:.1f}%)")
    print(f"Base64長    : {len(b64_str):,} 文字")
    print("==================================================")

    if output_bmp_path:
        with open(output_bmp_path, "wb") as f:
            f.write(full_rle_bmp)
        print(f"RLE4 BMPを出力しました: {output_bmp_path}")

    if output_js_path:
        with open(output_js_path, "w", encoding="utf-8") as f:
            f.write(f'// 256x256 16色ワールドマップ (BI_RLE4圧縮BMP Base64データ)\n')
            f.write(f'const FF1_WORLD_MAP_RLE4_BASE64 = "{b64_str}";\n')
        print(f"JS埋め込みコードを出力しました: {output_js_path}")

    return b64_str

if __name__ == "__main__":
    in_file = sys.argv[1] if len(sys.argv) > 1 else "ff1_world_map_256.bmp"
    out_bmp = sys.argv[2] if len(sys.argv) > 2 else "ff1_world_map_256_rle4.bmp"
    out_js = sys.argv[3] if len(sys.argv) > 3 else "preset_map_data.js"
    convert_bmp_to_rle4(in_file, out_bmp, out_js)
