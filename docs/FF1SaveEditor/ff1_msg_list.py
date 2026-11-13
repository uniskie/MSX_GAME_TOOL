#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
MSX版 ファイナルファンタジー メッセージリスト出力スクリプト

対応入力:
  1. DSKイメージ (.dsk)
     python ff1_msg_list.py FF1.dsk
  2. 生バイナリ (MESSAGE.VEC と MESSAGE.MSG)
     python ff1_msg_list.py MESSAGE.VEC MESSAGE.MSG
  3. MESSAGE.MSG 単体 (同ディレクトリに MESSAGE.VEC があれば自動参照、なければ 0x00 区切りで展開)
     python ff1_msg_list.py MESSAGE.MSG
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# FF1.def 文字コード対応表 (0x48 - 0xFF)
# ---------------------------------------------------------------------------
CHAR_ROWS: dict[int, str] = {
    0x48: "がぎぐげござじず",
    0x50: "ぜぞだぢづでどばびぶべぼガギグゲ",
    0x60: "ゴザジズゼゾダヂヅデドバビブベボ",
    0x70: "ぱぴぷぺぽパピプペポ／をっゃゅょ",
    0x80: "０１２３４５６７８９あいうえおか",
    0x90: "きくけこさしすせそたちつてとなに",
    0xA0: "ぬねのはひふへほまみむめもやゆよ",
    0xB0: "らりるれろわんァィ。ェォッャュョ",
    0xC0: "゛゜ー‥！？ＬＥＨＰアイウエオカ",
    0xD0: "キクケコサシスセソタチツテトナニ",
    0xE0: "ヌネノハヒフヘホマミムメモヤユヨ",
    0xF0: "ラリルレロワン┏━┓┃│┗─┛　",
}

CHAR_TABLE: dict[int, str] = {}
for _base, _chars in CHAR_ROWS.items():
    for _i, _ch in enumerate(_chars):
        CHAR_TABLE[_base + _i] = _ch

# ---------------------------------------------------------------------------
# DSKイメージ内の既知オフセット (ff1_msx_memo.md より / 1セクタ = 512 Byte)
# ---------------------------------------------------------------------------
DSK_MESSAGE_VEC_OFFSET = 0x6A400  # セクタ 0x0352 (850), 1セクタ
DSK_MESSAGE_VEC_SIZE = 512
DSK_MESSAGE_MSG_OFFSET = 0x6A600  # セクタ 0x0353 (851) - 0x036C (876), 26セクタ
DSK_MESSAGE_MSG_SIZE = 13312

DEFAULT_VEC_BASE_ADDR = 0x8200

# 制御コード表示名 (MAIN.COM: 0x69F8 - 0x6B32)
CONTROL_CODES: dict[int, str] = {
    0x02: "<NAME>",
    0x04: "<NUM>",
    0x05: "<GIL>",
    0x06: "<VAL>",
    0x10: "<MEMBER0>",
    0x11: "<MEMBER1>",
    0x12: "<MEMBER2>",
    0x13: "<MEMBER3>",
    0x14: "<LF>",
}


def decode_message(data: bytes, start_offset: int, raw_ctrl: bool = False) -> tuple[str, int]:
    """
    start_offset から終端コード (0x00) までをデコードし、(文字列, 次のオフセット) を返す。
    """
    out: list[str] = []
    i = start_offset
    length = len(data)

    while i < length:
        b = data[i]
        i += 1

        if b == 0x00:
            break
        elif b == 0x01:
            out.append("\n")
        elif b >= 0x48:
            out.append(CHAR_TABLE[b])
        elif b == 0x03:
            # 0x03: アイテム名展開 (直後1バイトがアイテムID)
            if i < length:
                item_id = data[i]
                i += 1
                out.append(f"<03:{item_id:02X}>" if raw_ctrl else f"<ITEM:{item_id:02X}>")
            else:
                out.append("<03>" if raw_ctrl else "<ITEM>")
        else:
            if raw_ctrl:
                out.append(f"<{b:02X}>")
            else:
                out.append(CONTROL_CODES.get(b, f"<{b:02X}>"))

    return "".join(out), i


def parse_with_vec(
    vec_data: bytes,
    msg_data: bytes,
    base_addr: int = DEFAULT_VEC_BASE_ADDR,
    raw_ctrl: bool = False,
) -> list[dict]:
    """
    MESSAGE.VEC (16bit LE ポインタテーブル) を参照して MESSAGE.MSG をデコードする。
    """
    count = len(vec_data) // 2
    ptrs = struct.unpack(f"<{count}H", vec_data[: count * 2])
    results: list[dict] = []

    for idx, ptr in enumerate(ptrs):
        offset = ptr - base_addr
        if offset < 0 or offset >= len(msg_data):
            results.append(
                {
                    "id": idx,
                    "ptr": ptr,
                    "offset": offset,
                    "text": "",
                    "error": f"範囲外オフセット (ptr=0x{ptr:04X}, offset=0x{offset:X})",
                }
            )
            continue

        text, _ = decode_message(msg_data, offset, raw_ctrl=raw_ctrl)
        results.append(
            {
                "id": idx,
                "ptr": ptr,
                "offset": offset,
                "text": text,
            }
        )

    return results


def parse_sequential(msg_data: bytes, raw_ctrl: bool = False) -> list[dict]:
    """
    VEC なしで先頭から 0x00 区切りで順次デコードする (補助モード)。
    """
    results: list[dict] = []
    offset = 0
    idx = 0
    length = len(msg_data)

    while offset < length:
        # 末尾の 0x00 パディングが連続したら終了
        if msg_data[offset] == 0x00 and all(b == 0x00 for b in msg_data[offset:]):
            break
        text, next_offset = decode_message(msg_data, offset, raw_ctrl=raw_ctrl)
        results.append(
            {
                "id": idx,
                "ptr": None,
                "offset": offset,
                "text": text,
            }
        )
        offset = next_offset
        idx += 1

    return results


def is_dsk_file(path: Path) -> bool:
    if path.suffix.lower() == ".dsk":
        return True
    # 拡張子が .dsk 以外でも、メッセージ領域を含む十分なサイズのディスクイメージなら DSK とみなす
    try:
        size = path.stat().st_size
        return size >= DSK_MESSAGE_MSG_OFFSET + DSK_MESSAGE_MSG_SIZE and size not in (512, 13312)
    except OSError:
        return False


def load_inputs(args: argparse.Namespace) -> tuple[bytes | None, bytes]:
    files = [Path(p) for p in args.inputs]

    if len(files) == 1:
        p = files[0]
        if is_dsk_file(p):
            data = p.read_bytes()
            vec_end = args.vec_offset + DSK_MESSAGE_VEC_SIZE
            msg_end = args.msg_offset + args.msg_size
            if len(data) < max(vec_end, msg_end):
                raise ValueError(f"DSKファイルサイズが不足しています: {p} ({len(data)} bytes)")
            vec_data = data[args.vec_offset : vec_end]
            msg_data = data[args.msg_offset : msg_end]
            return vec_data, msg_data

        # 単一ファイル指定: .MSG の場合
        msg_data = p.read_bytes()
        if not args.no_vec:
            # 同ディレクトリの MESSAGE.VEC を自動探索
            for cand_name in ("MESSAGE.VEC", "message.vec", p.with_suffix(".VEC").name, p.with_suffix(".vec").name):
                cand = p.parent / cand_name
                if cand.is_file() and cand != p:
                    return cand.read_bytes(), msg_data
        return None, msg_data

    if len(files) == 2:
        p1, p2 = files
        d1, d2 = p1.read_bytes(), p2.read_bytes()

        # 拡張子またはサイズ (VEC=512B) で自動判別
        if p1.suffix.lower() == ".vec" or p2.suffix.lower() == ".msg":
            return d1, d2
        if p2.suffix.lower() == ".vec" or p1.suffix.lower() == ".msg":
            return d2, d1
        if len(d1) == 512 and len(d2) != 512:
            return d1, d2
        if len(d2) == 512 and len(d1) != 512:
            return d2, d1
        return d1, d2

    raise ValueError("入力ファイルは 1つ (DSK または .MSG) か 2つ (VEC と MSG) を指定してください。")


def format_output(entries: list[dict], fmt: str, oneline: bool) -> str:
    if fmt == "json":
        return json.dumps(entries, ensure_ascii=False, indent=2)

    lines: list[str] = []
    if fmt == "tsv":
        lines.append("ID\tPTR\tOFFSET\tTEXT")
        for e in entries:
            ptr_s = f"0x{e['ptr']:04X}" if e["ptr"] is not None else "-"
            off_s = f"0x{e['offset']:04X}"
            txt = e["text"].replace("\n", "\\n")
            lines.append(f"0x{e['id']:02X}\t{ptr_s}\t{off_s}\t{txt}")
        return "\n".join(lines)

    # text 形式
    for e in entries:
        ptr_s = f" ptr=0x{e['ptr']:04X}" if e["ptr"] is not None else ""
        header = f"[0x{e['id']:02X} ({e['id']:3d}) | offset=0x{e['offset']:04X}{ptr_s}]"
        if "error" in e:
            lines.append(f"{header} {e['error']}")
            continue
        txt = e["text"].replace("\n", "\\n") if oneline else e["text"]
        if oneline:
            lines.append(f"{header} {txt}")
        else:
            lines.append(header)
            lines.append(txt)
            lines.append("")
    return "\n".join(lines)


def main() -> int:
    if hasattr(sys.stdout, "reconfigure") and not sys.stdout.isatty():
        sys.stdout.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="MSX版ファイナルファンタジー メッセージリスト出力ツール"
    )
    parser.add_argument(
        "inputs",
        nargs="+",
        help="DSKファイル、または MESSAGE.VEC と MESSAGE.MSG の生バイナリ",
    )
    parser.add_argument(
        "-o", "--output",
        type=Path,
        help="出力ファイルパス (UTF-8)。省略時は標準出力",
    )
    parser.add_argument(
        "-f", "--format",
        choices=("text", "tsv", "json"),
        default="text",
        help="出力形式 (デフォルト: text)",
    )
    parser.add_argument(
        "--oneline",
        action="store_true",
        help="text形式でメッセージ内の改行を \\n として1行で表示",
    )
    parser.add_argument(
        "--raw-ctrl",
        action="store_true",
        help="制御コードを <NAME> 等ではなく <02> のような16進表記にする",
    )
    parser.add_argument(
        "--base-addr",
        type=lambda x: int(x, 0),
        default=DEFAULT_VEC_BASE_ADDR,
        help=f"MESSAGE.VEC の基準アドレス (デフォルト: 0x{DEFAULT_VEC_BASE_ADDR:04X})",
    )
    parser.add_argument(
        "--vec-offset",
        type=lambda x: int(x, 0),
        default=DSK_MESSAGE_VEC_OFFSET,
        help=f"DSK内の MESSAGE.VEC オフセット (デフォルト: 0x{DSK_MESSAGE_VEC_OFFSET:X})",
    )
    parser.add_argument(
        "--msg-offset",
        type=lambda x: int(x, 0),
        default=DSK_MESSAGE_MSG_OFFSET,
        help=f"DSK内の MESSAGE.MSG オフセット (デフォルト: 0x{DSK_MESSAGE_MSG_OFFSET:X})",
    )
    parser.add_argument(
        "--msg-size",
        type=lambda x: int(x, 0),
        default=DSK_MESSAGE_MSG_SIZE,
        help=f"DSK内の MESSAGE.MSG サイズ (デフォルト: {DSK_MESSAGE_MSG_SIZE})",
    )
    parser.add_argument(
        "--no-vec",
        action="store_true",
        help="MESSAGE.MSG 単体指定時に同ディレクトリの MESSAGE.VEC を自動参照しない",
    )

    args = parser.parse_args()

    try:
        vec_data, msg_data = load_inputs(args)
        if vec_data is not None:
            entries = parse_with_vec(
                vec_data, msg_data, base_addr=args.base_addr, raw_ctrl=args.raw_ctrl
            )
        else:
            entries = parse_sequential(msg_data, raw_ctrl=args.raw_ctrl)
    except Exception as exc:
        print(f"エラー: {exc}", file=sys.stderr)
        return 1

    result = format_output(entries, fmt=args.format, oneline=args.oneline)

    if args.output:
        args.output.write_text(result + "\n", encoding="utf-8")
    else:
        print(result)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
