#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import struct
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# 文字変換テーブル (README_HYDLIDE3.md 準拠)
# ---------------------------------------------------------------------------

# 0x20 .. 0xFD (222文字)
HALFWIDTH_CHARS = (
    " !\"#$%&'()*+,-./0123456789:;<=>?" # 0x20 - 0x3F
    "@ABCDEFGHIJKLMNOPQRSTUVWXYZ[¥]^_"  # 0x40 - 0x5F
    "`abcdefghijklmnopqrstuvwxyz{|}~-"  # 0x60 - 0x7F
    "♠♥♣♦○●をぁぃぅぇぉゃゅょっ"  # 0x80 - 0x8F
    "❼あいうえおかきくけこさしすせそ"  # 0x90 - 0x9F
    "Ⅲ。「」、・ヲァィゥェォャュョッ"  # 0xA0 - 0xAF
    "ーアイウエオカキクケコサシスセソ"  # 0xB0 - 0xBF
    "タチツテトナニヌネノハヒフヘホマ"  # 0xC0 - 0xCF
    "ミムメモヤユヨラリルレロワン゛゜"  # 0xD0 - 0xDF
    "たちつてとなにぬねのはひふへほま"  # 0xE0 - 0xEF
    "みむめもやゆよらりるれろわん"      # 0xF0 - 0xFD
)

# 0xFE + 0x00..0xFF (256文字)
KANJI_FE = (
    "悪宿扱安暗闇以偉慰異移敵一印飲院"  # 0x00 - 0x0F
    "隠宇噂運雲栄英衛越炎奥応王屋俺下"  # 0x10 - 0x1F
    "何加可家果架貨過我牙会解回怪界開"  # 0x20 - 0x2F
    "階外街覚角革楽■割活巻完感慣換敢"  # 0x30 - 0x3F
    "■管間関館危器棄機帰気記■議休宮"  # 0x40 - 0x4F
    "弓急求許強恐教響驚業近金銀具空偶"  # 0x50 - 0x5F
    "窟係刑兄型形経計撃剣堅建見険験元"  # 0x60 - 0x6F
    "幻現言古呼己庫湖御語誤光功効口好"  # 0x70 - 0x7F
    "幸広攻更航行貢鋼■高合告込今困差"  # 0x80 - 0x8F
    "査鎖座再最裁際剤在罪作参残■使士"  # 0x90 - 0x9F
    "姿子師思支止死私事字寺持時次治示"  # 0xA0 - 0xAF
    "自郎失室■実捨者邪主取守手■酒受"  # 0xB0 - 0xBF
    "呪授修終住十重銃出準盾■所緒書助"  # 0xC0 - 0xCF
    "商唱小少招消証上丈城場常状飾職食"  # 0xD0 - 0xDF
    "信寝心振新森深真神身針人吹水睡酔"  # 0xE0 - 0xEF
    "世制成星正生精聖声製西昔石積切接"  # 0xF0 - 0xFF
)

# 0xFF + 0x00..0xFF (256文字)
KANJI_FF = (
    "説先戦線船選前然全素僧創倉想早総"  # 0x00 - 0x0F
    "草装送像造側足速賊続存他太駄体■"  # 0x10 - 0x1F
    "待態替代大択達脱誰探短弾段■値知"  # 0x20 - 0x2F
    "地置遅築■中宙懲聴調超長直沈珍追"  # 0x30 - 0x3F
    "通清底笛天店転伝殿田電登途都度奴"  # 0x40 - 0x4F
    "倒塔盗当■到闘動洞道得■毒読内■"  # 0x50 - 0x5F
    "南二日入任熱■能波破引■敗杯配培"  # 0x60 - 0x6F
    "買売泊爆箱発飯疲皮■飛備美必標■"  # 0x70 - 0x7F
    "表■敏不夫怖普浮武部封風復服物分"  # 0x80 - 0x8F
    "文聞平閉別変■保捕歩墓暮報宝放方"  # 0x90 - 0x9F
    "法棒冒防北本魔埋毎抹慢味未魅■眠"  # 0xA0 - 0xAF
    "務夢無名命明滅面目戻■夜役薬勇友"  # 0xB0 - 0xBF
    "由遊雄予与預妖様用要陽養欲来頼落"  # 0xC0 - 0xCF
    "理■立■侶旅了両料量力礼霊裂録和"  # 0xD0 - 0xDF
    "話惑腕木…々湧岩跡拾騎殺巨軍隊吸"  # 0xE0 - 0xEF
    "０１２３４５６７８９血護影獄樹鬼"  # 0xF0 - 0xFF
)

assert len(HALFWIDTH_CHARS) == 0xFE - 0x20
assert len(KANJI_FE) == 256
assert len(KANJI_FF) == 256

# ---------------------------------------------------------------------------
# ROM領域定義
# ---------------------------------------------------------------------------

BANK_SIZE = 0x2000
BLOCK_SIZE = 0x4000
CPU_BASE = 0x4000


@dataclass(frozen=True)
class RegionSpec:
    key: str
    title: str
    base_rom: int
    count: int


MESSAGE_SPEC = RegionSpec(
    key="message_strings",
    title="メッセージ文字列リスト (会話文字列)",
    base_rom=0x4C000,  # Bank $26 - $27
    count=0x140,       # ID $000 - $13F (320)
)

SYSTEM_SPEC = RegionSpec(
    key="system_strings",
    title="システム文字列リスト",
    base_rom=0x50000,  # Bank $28 - $29
    count=0x148,       # ID $000 - $147 (328)
)


@dataclass
class DecodedEntry:
    idx: int
    table_rom: int
    body_rom: int
    text: str


@dataclass
class TableCandidate:
    table_off: int
    table_size: int
    count: int
    min_ptr_gap: int
    max_end_off: int
    prev_null_ratio: float
    coverage_ratio: float
    jp_char_ratio: float
    ptrs: Tuple[int, ...]
    decoded_map: Dict[int, Tuple[str, int]]  # cpu_addr -> (text, end_off)

    @property
    def score(self) -> Tuple[int, float, float, int]:
        # min_ptr_gap == 0 を最優先し、次に直前0x00率、カバー率を優先
        return (
            1 if self.min_ptr_gap == 0 else 0,
            round(self.prev_null_ratio, 6),
            round(self.coverage_ratio, 6),
            -self.min_ptr_gap,
        )


def fmt_rom(addr: int) -> str:
    return f"0x{addr:05X}"


def fmt_cpu(addr: int) -> str:
    return f"0x{addr:04X}"


def fmt_bank(rom_addr: int) -> str:
    return f"0x{rom_addr // BANK_SIZE:02X}"


def fmt_id(idx: int) -> str:
    return f"0x{idx:03X}"


def detect_rom_version(rom: bytes) -> str:
    # Bank $0F + $0080 (0x1E080) のバンク切り替えワーク書き込み先で MSX1 / MSX2 を判別
    sig_msx1 = bytes.fromhex("F3 32 00 60 32 BA DE FB C9")
    sig_msx2 = bytes.fromhex("F3 32 00 60 32 BB DE FB C9")
    if len(rom) >= 0x1E089:
        chunk = rom[0x1E080:0x1E089]
        if chunk == sig_msx1:
            return "MSX1"
        if chunk == sig_msx2:
            return "MSX2"
    return "Unknown"


def decode_string(
    block: bytes,
    start_off: int,
    include_null: bool = False,
) -> Optional[Tuple[str, int, int, int]]:
    """
    start_off から 0x00 終端まで文字列をデコードする。
    戻り値: (text, end_off, jp_chars, total_chars) または終端不可時は None
    """
    pos = start_off
    limit = len(block)
    out: List[str] = []
    jp_chars = 0
    total_chars = 0

    while pos < limit:
        b = block[pos]
        pos += 1
        if b == 0x00:
            if include_null:
                out.append("\\00")
            return "".join(out), pos, jp_chars, total_chars
        elif b < 0x20:
            out.append(f"\\{b:02X}")
            total_chars += 1
        elif b in (0xFE, 0xFF):
            if pos >= limit:
                return None
            b2 = block[pos]
            pos += 1
            table = KANJI_FE if b == 0xFE else KANJI_FF
            out.append(table[b2])
            jp_chars += 1
            total_chars += 1
        else:
            out.append(HALFWIDTH_CHARS[b - 0x20])
            if b >= 0x80:
                jp_chars += 1
            total_chars += 1

    return None


def validate_candidate(
    block: bytes,
    off: int,
    count: int,
    include_null: bool,
) -> Optional[TableCandidate]:
    table_size = count * 2
    table_cpu = CPU_BASE + off
    body_min_cpu = table_cpu + table_size

    ptrs = struct.unpack_from(f"<{count}H", block, off)
    min_ptr = min(ptrs)
    if min_ptr < body_min_cpu or max(ptrs) >= CPU_BASE + len(block):
        return None

    min_ptr_gap = min_ptr - body_min_cpu
    unique_ptrs = sorted(set(ptrs))

    decoded_map: Dict[int, Tuple[str, int]] = {}
    intervals: List[Tuple[int, int]] = []
    prev_null_hits = 0
    total_jp = 0
    total_ch = 0

    for p in unique_ptrs:
        p_off = p - CPU_BASE
        res = decode_string(block, p_off, include_null=include_null)
        if res is None:
            return None
        text, end_off, jp_c, tot_c = res
        decoded_map[p] = (text, end_off)
        intervals.append((p_off, end_off))
        total_jp += jp_c
        total_ch += tot_c

        if p > min_ptr and p_off > 0 and block[p_off - 1] == 0x00:
            prev_null_hits += 1

    # 区間の不正な部分交差チェック（別文字列の途中から始まり途中で終わらない）
    # ※ サブ文字列共有(tail sharing)の場合は end_off が一致する
    for i in range(len(intervals) - 1):
        s1, e1 = intervals[i]
        s2, e2 = intervals[i + 1]
        if s2 < e1 and e2 != e1:
            return None

    # 直前が 0x00 である割合
    denom_null = max(1, len(unique_ptrs) - 1)
    prev_null_ratio = prev_null_hits / denom_null

    # カバー率の計算（マージ区間長 / 全体スパン長）
    merged_len = 0
    cur_s, cur_e = intervals[0]
    for s, e in intervals[1:]:
        if s <= cur_e:
            if e > cur_e:
                cur_e = e
        else:
            merged_len += cur_e - cur_s
            cur_s, cur_e = s, e
    merged_len += cur_e - cur_s

    max_end_off = max(e for _, e in intervals)
    span_len = max_end_off - (body_min_cpu - CPU_BASE)
    coverage_ratio = (merged_len / span_len) if span_len > 0 else 0.0

    # 偽陽性フィルタ
    if prev_null_ratio < 0.85 or coverage_ratio < 0.85:
        return None

    jp_char_ratio = (total_jp / total_ch) if total_ch > 0 else 0.0

    return TableCandidate(
        table_off=off,
        table_size=table_size,
        count=count,
        min_ptr_gap=min_ptr_gap,
        max_end_off=max_end_off,
        prev_null_ratio=prev_null_ratio,
        coverage_ratio=coverage_ratio,
        jp_char_ratio=jp_char_ratio,
        ptrs=ptrs,
        decoded_map=decoded_map,
    )


def find_jp_en_tables(
    block: bytes,
    spec: RegionSpec,
    include_null: bool,
) -> Tuple[TableCandidate, TableCandidate]:
    table_size = spec.count * 2
    max_off = len(block) - table_size
    candidates: List[TableCandidate] = []

    for off in range(max_off + 1):
        body_min_cpu = CPU_BASE + off + table_size
        min_hi = body_min_cpu >> 8

        # 高速プレフィルタ：全エントリの上位バイトが [min_hi .. 0x7F] か確認
        valid_hi = True
        for i in range(off + 1, off + table_size, 2):
            hi = block[i]
            if hi < min_hi or hi >= 0x80:
                valid_hi = False
                break
        if not valid_hi:
            continue

        cand = validate_candidate(block, off, spec.count, include_null)
        if cand is not None:
            candidates.append(cand)

    if len(candidates) < 2:
        raise ValueError(
            f"{spec.title}: 有効な日英アドレステーブルの組を検出できませんでした "
            f"(候補数={len(candidates)}, 領域=0x{spec.base_rom:05X})"
        )

    # 非重複ペア (jp, en) を探索し、最も整合性の高い組を選択する
    best_pair: Optional[Tuple[TableCandidate, TableCandidate]] = None
    best_pair_score: Optional[Tuple[int, int, float, int]] = None

    for jp in candidates:
        for en in candidates:
            if jp.max_end_off > en.table_off:
                continue
            gap_between = en.table_off - jp.max_end_off
            # 理想は:
            # 1) jp側が日本語文字を含み、en側が英語中心(jp_char_ratio が jp > en)
            # 2) gap_between == 0 (日本語データ直後から英語テーブルが開始)
            # 3) 両候補とも min_ptr_gap == 0 かつ高い整合性スコア
            lang_order_ok = 1 if jp.jp_char_ratio > en.jp_char_ratio else 0
            exact_boundary = 1 if gap_between == 0 else 0
            exact_min = 1 if (jp.min_ptr_gap == 0 and en.min_ptr_gap == 0) else 0
            combined_quality = (
                jp.prev_null_ratio
                + en.prev_null_ratio
                + jp.coverage_ratio
                + en.coverage_ratio
            )
            pair_score = (
                lang_order_ok,
                exact_min,
                exact_boundary,
                round(combined_quality, 6),
                -gap_between,
            )
            if best_pair_score is None or pair_score > best_pair_score:
                best_pair_score = pair_score
                best_pair = (jp, en)

    if best_pair is None:
        raise ValueError(
            f"{spec.title}: 日本語テーブルと英語テーブルの非重複ペアが見つかりませんでした。"
        )

    return best_pair


def build_language_section(
    spec: RegionSpec,
    cand: TableCandidate,
) -> dict:
    table_start_rom = spec.base_rom + cand.table_off
    body_start_rom = spec.base_rom + (min(cand.ptrs) - CPU_BASE)
    body_end_rom = spec.base_rom + cand.max_end_off - 1

    items = []
    for idx, ptr_cpu in enumerate(cand.ptrs):
        tbl_rom = table_start_rom + idx * 2
        tbl_cpu = CPU_BASE + cand.table_off + idx * 2
        body_rom = spec.base_rom + (ptr_cpu - CPU_BASE)
        text, _ = cand.decoded_map[ptr_cpu]

        items.append(
            {
                "id": fmt_id(idx),
                "address_table": {
                    "rom_address": fmt_rom(tbl_rom),
                    "bank": fmt_bank(tbl_rom),
                    "cpu_address": fmt_cpu(tbl_cpu),
                },
                "string_body": {
                    "rom_address": fmt_rom(body_rom),
                    "bank": fmt_bank(body_rom),
                    "cpu_address": fmt_cpu(ptr_cpu),
                },
                "text": text,
            }
        )

    return {
        "table_start": {
            "rom_address": fmt_rom(table_start_rom),
            "bank": fmt_bank(table_start_rom),
            "cpu_address": fmt_cpu(CPU_BASE + cand.table_off),
        },
        "body_range": {
            "start_rom_address": fmt_rom(body_start_rom),
            "end_rom_address": fmt_rom(body_end_rom),
        },
        "validation": {
            "count": cand.count,
            "min_ptr_matches_table_end": cand.min_ptr_gap == 0,
            "prev_null_ratio": round(cand.prev_null_ratio, 6),
            "coverage_ratio": round(cand.coverage_ratio, 6),
        },
        "items": items,
    }


def md_code_cell(text: str) -> str:
    """Markdown テーブルセル内で安全に表示できるコードスパン文字列を生成する。"""
    if text == "":
        return ""
    # GFMテーブルではインラインコード内のパイプもセル区切り扱いになるためエスケープ
    escaped = text.replace("|", "\\|")
    # 含まれる連続バッククォートの最大長より1つ多いバッククォートで囲む
    max_ticks = 0
    cur_ticks = 0
    for ch in escaped:
        if ch == "`":
            cur_ticks += 1
            if cur_ticks > max_ticks:
                max_ticks = cur_ticks
        else:
            cur_ticks = 0
    fence = "`" * (max_ticks + 1)
    if escaped.startswith("`") or escaped.endswith("`"):
        return f"{fence} {escaped} {fence}"
    return f"{fence}{escaped}{fence}"


def render_markdown(data: dict) -> str:
    lines: List[str] = []
    lines.append(f"# {data['rom_file']} 文字列リスト")
    lines.append("")
    lines.append(f"- **ROMファイル**: `{data['rom_file']}` (`{data['rom_size']}` bytes)")
    lines.append(f"- **検出バージョン**: `{data['rom_version']}`")
    lines.append(f"- **終端`\\00`出力**: `{data['include_null_terminator']}`")
    lines.append("")

    sections = [
        ("メッセージ文字列リスト (会話文字列)", data["message_strings"]),
        ("システム文字列リスト", data["system_strings"]),
    ]

    for sec_title, sec_data in sections:
        lines.append(f"## {sec_title}")
        lines.append("")
        for lang_key, lang_label in [("japanese", "日本語"), ("english", "英語")]:
            lang_data = sec_data[lang_key]
            tbl = lang_data["table_start"]
            rng = lang_data["body_range"]
            val = lang_data["validation"]

            lines.append(f"### {lang_label}")
            lines.append("")
            lines.append(
                f"- **アドレステーブル開始**: `{tbl['rom_address']}` "
                f"(バンク `{tbl['bank']}`, CPU `{tbl['cpu_address']}`)"
            )
            lines.append(
                f"- **文字列本体範囲**: `{rng['start_rom_address']}` ～ `{rng['end_rom_address']}`"
            )
            lines.append(
                f"- **妥当性検査**: 件数={val['count']}, "
                f"最小ポインタ一致={val['min_ptr_matches_table_end']}, "
                f"直前0x00率={val['prev_null_ratio']:.4f}, "
                f"カバー率={val['coverage_ratio']:.4f}"
            )
            lines.append("")
            lines.append(
                "| ID | アドレステーブル ROMアドレス (バンク, CPU空間アドレス) "
                "| 文字本体 ROMアドレス (バンク, CPU空間アドレス) | 文字列本体 |"
            )
            lines.append("| :--- | :--- | :--- | :--- |")

            for item in lang_data["items"]:
                at = item["address_table"]
                sb = item["string_body"]
                lines.append(
                    f"| `{item['id']}` "
                    f"| `{at['rom_address']}` (`{at['bank']}`, `{at['cpu_address']}`) "
                    f"| `{sb['rom_address']}` (`{sb['bank']}`, `{sb['cpu_address']}`) "
                    f"| {md_code_cell(item['text'])} |"
                )
            lines.append("")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="ハイドライド3 ROM からメッセージ文字列・システム文字列を抽出します。"
    )
    parser.add_argument("rom_path", type=Path, help="ハイドライド3のROMファイルパス")
    parser.add_argument(
        "--out-dir",
        type=Path,
        default=Path("."),
        help="出力先ディレクトリ (既定: カレントディレクトリ)",
    )
    parser.add_argument(
        "--include-null",
        action="store_true",
        help="終端の 0x00 を文字列本体末尾に \\00 として含める",
    )
    args = parser.parse_args()

    rom_path: Path = args.rom_path
    if not rom_path.is_file():
        print(f"エラー: ROMファイルが見つかりません: {rom_path}", file=sys.stderr)
        return 1

    rom = rom_path.read_bytes()
    required_end = SYSTEM_SPEC.base_rom + BLOCK_SIZE
    if len(rom) < required_end:
        print(
            f"エラー: ROMサイズが小さすぎます ({len(rom)} bytes < {required_end} bytes)",
            file=sys.stderr,
        )
        return 1
    if len(rom) != 0x80000:
        print(
            f"警告: ROMサイズが標準の512KB (524288 bytes) と異なります ({len(rom)} bytes)",
            file=sys.stderr,
        )

    msg_block = rom[MESSAGE_SPEC.base_rom : MESSAGE_SPEC.base_rom + BLOCK_SIZE]
    sys_block = rom[SYSTEM_SPEC.base_rom : SYSTEM_SPEC.base_rom + BLOCK_SIZE]

    try:
        msg_jp, msg_en = find_jp_en_tables(msg_block, MESSAGE_SPEC, args.include_null)
        sys_jp, sys_en = find_jp_en_tables(sys_block, SYSTEM_SPEC, args.include_null)
    except ValueError as e:
        print(f"エラー: {e}", file=sys.stderr)
        return 1

    output_data = {
        "rom_file": rom_path.name,
        "rom_size": len(rom),
        "rom_version": detect_rom_version(rom),
        "include_null_terminator": args.include_null,
        "message_strings": {
            "japanese": build_language_section(MESSAGE_SPEC, msg_jp),
            "english": build_language_section(MESSAGE_SPEC, msg_en),
        },
        "system_strings": {
            "japanese": build_language_section(SYSTEM_SPEC, sys_jp),
            "english": build_language_section(SYSTEM_SPEC, sys_en),
        },
    }

    args.out_dir.mkdir(parents=True, exist_ok=True)
    base_name = rom_path.stem
    json_path = args.out_dir / f"{base_name}.json"
    md_path = args.out_dir / f"{base_name}.md"

    json_path.write_text(
        json.dumps(output_data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    md_path.write_text(render_markdown(output_data), encoding="utf-8")

    print(f"ROMバージョン推定: {output_data['rom_version']}")
    print(
        f"メッセージ文字列 - 日本語テーブル: {fmt_rom(MESSAGE_SPEC.base_rom + msg_jp.table_off)}, "
        f"英語テーブル: {fmt_rom(MESSAGE_SPEC.base_rom + msg_en.table_off)}"
    )
    print(
        f"システム文字列   - 日本語テーブル: {fmt_rom(SYSTEM_SPEC.base_rom + sys_jp.table_off)}, "
        f"英語テーブル: {fmt_rom(SYSTEM_SPEC.base_rom + sys_en.table_off)}"
    )
    print(f"出力完了: {json_path}")
    print(f"出力完了: {md_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
