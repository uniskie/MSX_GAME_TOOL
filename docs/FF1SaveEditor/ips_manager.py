#!/usr/bin/env python3
"""
IPSファイルの合成・複数適用ツール

複数のIPSパッチを指定した順番で1つのIPSファイルへ合成、
またはベースファイル（ROM等）へ直接適用します。
重複箇所の検知・警告の有無・競合時の動作（重複時上書き［後行優先］／
重複時無視［先行優先］／エラー中断）を制御できます。

仕様・注意事項:
  - 標準IPS形式（PATCHヘッダ / RLE圧縮 / EOF / 切り詰めサイズ拡張）に対応
  - デフォルトでは「同じオフセットに同じ値」を書く重複は無視し、
    「異なる値」を書こうとする競合のみを警告します（--strict-same で変更可）
"""

# Python 3.7〜3.9 の古い環境でも「int | None」などの新しい型ヒント記法で
# エラーにならないよう、型ヒントの即時評価をスキップする設定
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def parse_ips(filepath: Path) -> tuple[dict[int, int], int | None]:
    """IPSファイルを解析し、{オフセット: バイト値} の辞書と切り詰めサイズ(あれば)を返す"""
    data = filepath.read_bytes()
    if not data.startswith(b"PATCH"):
        raise ValueError(f"{filepath}: 有効なIPSファイルではありません (PATCHヘッダなし)")

    pos = 5
    length = len(data)
    writes: dict[int, int] = {}
    truncate_size: int | None = None

    while pos < length:
        if pos + 3 > length:
            raise ValueError(f"{filepath}: ファイルが途中で切れています")

        header_offset = data[pos : pos + 3]
        # 開始オフセットの3バイトが "EOF" (0x45, 0x4F, 0x46) なら終端とみなす
        if header_offset == b"EOF":
            pos += 3
            if pos + 3 == length:
                truncate_size = int.from_bytes(data[pos : pos + 3], "big")
            break

        offset = int.from_bytes(header_offset, "big")
        pos += 3

        if pos + 2 > length:
            raise ValueError(f"{filepath}: サイズ情報が見つかりません")
        size = int.from_bytes(data[pos : pos + 2], "big")
        pos += 2

        if size == 0:
            # RLEレコード（同じバイト値の連続書き込み）
            if pos + 3 > length:
                raise ValueError(f"{filepath}: RLEデータが不正です")
            rle_size = int.from_bytes(data[pos : pos + 2], "big")
            rle_val = data[pos + 2]
            pos += 3
            for i in range(rle_size):
                writes[offset + i] = rle_val
        else:
            # 通常レコード
            if pos + size > length:
                raise ValueError(f"{filepath}: パッチデータが不足しています")
            chunk = data[pos : pos + size]
            pos += size
            for i, b in enumerate(chunk):
                writes[offset + i] = b

    return writes, truncate_size


def format_ranges(offsets: list[int]) -> list[str]:
    """連続したオフセットを見やすい範囲表記 (例: 0x001000-0x00100F) にまとめる"""
    if not offsets:
        return []
    offsets.sort()
    ranges = []
    start = prev = offsets[0]
    for off in offsets[1:]:
        if off == prev + 1:
            prev = off
        else:
            ranges.append(f"0x{start:06X}" if start == prev else f"0x{start:06X}-0x{prev:06X}")
            start = prev = off
    ranges.append(f"0x{start:06X}" if start == prev else f"0x{start:06X}-0x{prev:06X}")
    return ranges


def merge_patches(
    patch_paths: list[Path],
    on_conflict: str,
    warn: bool,
    ignore_same_value: bool,
) -> tuple[dict[int, int], int | None]:
    """複数のIPSを順番に統合し、重複チェック・上書き制御を行う"""
    merged: dict[int, int] = {}
    final_truncate: int | None = None

    for idx, path in enumerate(patch_paths, 1):
        writes, trunc = parse_ips(path)
        if trunc is not None:
            final_truncate = trunc

        conflict_offsets: list[int] = []

        for addr, new_val in writes.items():
            if addr in merged:
                if merged[addr] == new_val:
                    if not ignore_same_value:
                        conflict_offsets.append(addr)
                else:
                    conflict_offsets.append(addr)

                if on_conflict == "overwrite":
                    merged[addr] = new_val
                elif on_conflict == "keep":
                    pass  # 先行優先（重複時無視）
            else:
                merged[addr] = new_val

        if conflict_offsets:
            if on_conflict == "abort":
                ranges = ", ".join(format_ranges(conflict_offsets)[:10])
                raise RuntimeError(
                    f"[エラー] パッチ{idx} ({path.name}) で重複が検出されたため中断しました: {ranges}"
                )
            elif warn:
                action = "上書き(後行優先)" if on_conflict == "overwrite" else "無視(先行優先)"
                ranges = format_ranges(conflict_offsets)
                preview = ", ".join(ranges[:10]) + (f" ...他 {len(ranges)-10} 箇所" if len(ranges) > 10 else "")
                print(
                    f"[警告] パッチ{idx} ({path.name}) で {len(conflict_offsets)} バイトの重複あり -> {action}: {preview}",
                    file=sys.stderr,
                )

    return merged, final_truncate


def build_ips(writes: dict[int, int], truncate_size: int | None) -> bytes:
    """統合された書き込みマップからIPSバイナリを生成する"""
    out = bytearray(b"PATCH")
    if writes:
        addrs = sorted(writes.keys())
        start = prev = addrs[0]
        buf = bytearray([writes[start]])

        def flush_chunk(chunk_start: int, chunk_data: bytearray) -> None:
            offset = 0
            total_len = len(chunk_data)

            while offset < total_len:
                part_start = chunk_start + offset
                max_part_len = 0xFFFF  # IPSの1レコード最大サイズは65535バイト

                # 【EOF衝突の回避（分割時）】
                # 65535バイト超の連続データを分割するとき、次の分割先頭がちょうど 0x454F46 ("EOF") に
                # なってしまう場合のみ、1バイト手前 (0xFFFE = 65534バイト) で区切る。
                # これにより次のレコードを 0x454F45 開始に逃がせる（0x454F45 の値も手元にあるため安全）。
                if total_len - offset > max_part_len and part_start + max_part_len == 0x454F46:
                    max_part_len = 0xFFFE

                if part_start == 0x454F46:
                    # 【IPS仕様上の制約：0x454F46 と "EOF" の衝突について】
                    # IPSの終端マーク "EOF" の文字コードは 16進数で 45 4F 46 (= 0x454F46) 。
                    # そのため「0x454F46番地から始まるレコード」をそのまま書き出すと、
                    # パッチャーが「ファイルの終わり」と誤認してそこで処理を打ち切ってしまう。
                    #
                    # 通常、元ファイルが手元にある場合は「1バイト手前の 0x454F45 にある元々の値」を
                    # 先頭にくっつけて 0x454F45 開始にズラすことで回避できるが、
                    # IPS同士の合成時は元ファイルがなく 0x454F45 の元の値を知り得ないため
                    # （勝手に 0x00 等で埋めると元ファイルを壊すため）合成だけでは解決できない。
                    # ※ -t で元ファイルを直接指定する場合はIPS出力を介さないため問題なく適用できる。
                    print(
                        "[警告] 書き込み開始位置 0x454F46 ('EOF') が単独で存在します。"
                        "IPS仕様上終端と誤認されるため、対象ファイルへの直接適用(-t)を推奨します。",
                        file=sys.stderr,
                    )

                part = chunk_data[offset : offset + max_part_len]
                out.extend(part_start.to_bytes(3, "big"))
                out.extend(len(part).to_bytes(2, "big"))
                out.extend(part)
                offset += len(part)

        for addr in addrs[1:]:
            if addr == prev + 1:
                buf.append(writes[addr])
                prev = addr
            else:
                flush_chunk(start, buf)
                start = prev = addr
                buf = bytearray([writes[addr]])
        flush_chunk(start, buf)

    out.extend(b"EOF")
    if truncate_size is not None:
        out.extend(truncate_size.to_bytes(3, "big"))
    return bytes(out)


def apply_to_target(target_path: Path, writes: dict[int, int], truncate_size: int | None) -> bytes:
    """統合した変更内容をベースファイルに直接適用する"""
    rom = bytearray(target_path.read_bytes())
    if writes:
        max_addr = max(writes.keys())
        if max_addr >= len(rom):
            rom.extend(b"\x00" * (max_addr + 1 - len(rom)))
        for addr, val in writes.items():
            rom[addr] = val
    if truncate_size is not None and truncate_size < len(rom):
        rom = rom[:truncate_size]
    return bytes(rom)


def main():
    # %(prog)s は実行時のスクリプトファイル名に自動置換される
    epilog_text = """使用例:
  # 1. 複数のIPSを順番に合成（重複時は警告を出し、重複時上書き［後行優先］）
  python %(prog)s patch1.ips patch2.ips patch3.ips -o merged.ips

  # 2. 警告を消し、重複時無視（先行優先）で合成
  python %(prog)s patch1.ips patch2.ips -o merged.ips --on-conflict keep --no-warn

  # 3. 重複が1バイトでもあればエラーで中断
  python %(prog)s patch1.ips patch2.ips -o merged.ips --on-conflict abort

  # 4. 元のファイルに直接順番に適用
  python %(prog)s patch1.ips patch2.ips -t original.bin -o patched.bin --on-conflict overwrite
"""

    parser = argparse.ArgumentParser(
        description=(__doc__ or "").strip(),
        epilog=epilog_text,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("patches", nargs="+", type=Path, help="適用・合成するIPSファイル（指定順に処理）")
    parser.add_argument("-o", "--output", required=True, type=Path, help="出力ファイルパス")
    parser.add_argument("-t", "--target", type=Path, help="指定時はベースファイルに直接適用して出力（未指定時はIPSとして合成出力）")
    parser.add_argument(
        "--on-conflict",
        choices=["overwrite", "keep", "abort"],
        default="overwrite",
        help="重複時の動作: overwrite(重複時上書き: 後行優先), keep(重複時無視: 先行優先), abort(エラー中断)",
    )
    parser.add_argument("--no-warn", action="store_true", help="重複時の警告メッセージを表示しない")
    parser.add_argument("--strict-same", action="store_true", help="同じバイト値の上書きも重複として扱う")

    # 引数なしで実行された場合は使用例付きのヘルプ全体を表示
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()

    try:
        merged, trunc = merge_patches(
            args.patches,
            on_conflict=args.on_conflict,
            warn=not args.no_warn,
            ignore_same_value=not args.strict_same,
        )

        if args.target:
            result = apply_to_target(args.target, merged, trunc)
            args.output.write_bytes(result)
            print(f"適用完了: {args.output}")
        else:
            result = build_ips(merged, trunc)
            args.output.write_bytes(result)
            print(f"合成完了: {args.output}")

    except Exception as e:
        print(e, file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
