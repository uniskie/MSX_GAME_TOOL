#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ハイドライド3 MSX1版(前期ROM)を、MSX2後期ロット相当に改造するパッチプログラム。

入力ROM(512KB)を読み込み、MSX2版後期ロットで確認された修正点を MSX1版側の
アドレス・サブルーチン配置に合わせて適用し、新しいファイルとして出力する。
入力ファイル自体は書き換えない。

適用する修正内容:
  1. スタッフロール修正
     "The Space Memoris" -> "The Space Memories" ('e' を1バイト挿入)
  2. メッセージ修正およびポインタテーブル補正 (2件)
     - 会話269番(日本語): "予想誤差!３以内。" -> "予想誤差+-３以内。" (+1バイト)
     - システム72番(英語): "Can't throw away ..." -> "Can't throw ..." (-5バイト)
     - これらに伴って文字列の配置がずれる分、メッセージテーブルのポインタを補正する。
     - また、会話269番の+1バイト増加で英語会話テーブルの開始位置がずれるため、
       テーブルを参照している命令のアドレス即値を 59F8H -> 59F9H に補正する。
  3. バンク9のアイテム入手・イベント判定処理の修正
     - 銀製の剣と光の剣を分岐させるため、剣入手処理にフラグ D093H の判定を追加する
       (フラグが立っていれば光の剣、立っていなければ銀製の剣を渡す)。
     - 湖の宮殿メモリバンク(コンピュータ)処理の最初の判定を、隣接処理と同様の
       「マップチップ取得サブルーチンを呼び出して BIT 6 を判定する」形式に置換する
       (暴走バグ修正)。呼び出し先はMSX2版では BD91H、MSX1版では対応する処理の
       B978H である(MSX1版の BD91H は 00H で埋められた空き領域)。
     - 挿入により後続コードのアドレスがずれるため、バンク9+10の連続領域内の
       該当する参照アドレスを 14 / 13 加算し、増加分13バイトをバンク10の空き領域で吸収する。
  4. バンク15のキー入力ルーチンを後期ロットのロジックに書き換える
     - MSX1版では後続サブルーチン(A985H)のアドレスを動かさないよう、
       余剰バイトを 00H でパディングする。
  5. バンク13の初期化処理にスタック再設定(LD SP,0F000H)を追加し、末尾の JP xxxxH
     (MSX2版では 4EAFH) を CALL xxxxH + JP 4022H の形式に変更する (+6バイト)
     - スタックリセットにより呼び出し元への戻りアドレスが失われるため、元の処理先を
       CALL で実行させた上で確実に 4022H へ遷移させる。
     - 挿入により後続がずれるため、バンク13内の該当する参照アドレスに 6 を加算する。
  6. ウェイトループのカウンタ値変更 (6箇所)
     - 3000H->0C00H (2箇所)、0800H->0200H (2箇所)、0200H->0400H (1箇所)、
       ループ回数 4回->8回 (1箇所)

バンク14(イベントテーブル)について:
  MSX2後期ROMにおけるバンク14の差分は、バンク14自体のロジック変更ではない。
  バンク13末尾にあるディスパッチテーブル(33エントリ、各4バイト)の終端部は
  バンク14の先頭にかかっている。バンク13へ6バイト挿入すると、バンク14側へ
  はみ出す部分が6バイト増えるため、MSX2版ではバンク14の中身全体が6バイト後ろへずれている。
  ディスパッチテーブルの1エントリは2つのアドレス(計4バイト)で構成され、
  最初のアドレスは「件数とキー配列の先頭」を、次のアドレスは「ジャンプテーブルの先頭」を指す。
  ジャンプテーブルには、キー配列と同じ順序でハンドラ(処理)のアドレスが件数分並んでいる。
  MSX1版ではディスパッチテーブル自体がバンク13内に収まっているため、バンク14は動かさない。
  その代わり、バンク14に配置されているジャンプテーブル内のアドレスのうち、
  バンク13の挿入でずれる範囲を指すものに 6 を加算する。
  ただし、最初のエントリ(エントリ0)が指すレコードデータ(レコード0)だけはバンク13と
  バンク14にまたがって配置されており、そのまま挿入するとデータ途中のバイトが欠損してしまう。
  そのため、このレコード0をバンク14末尾の空き領域へ退避(再配置)し、
  ディスパッチテーブルの先頭エントリを退避先のアドレスへ書き換える。

アドレス補正の方針について:
  配置がずれる範囲に一致する2バイト値を無差別に書き換えることはしない。命令のオペランドや
  ディスパッチテーブルとして参照されている箇所のみを対象とする。
  - バンク9+10: 対象箇所のオフセット一覧を使用する(MSX1版でも同じオフセットの値が
                想定アドレス範囲を指していることを確認した上で加算する)。
  - バンク13  : 直前のバイトが「16bit値をオペランドに取るZ80命令」のオペコードである
                箇所のみを対象とする。

任意のバグ修正について:
  --fix-window-bug を指定すると、後期ロット相当への改造とは別に、前期・後期の
  両ロットにあるバグを1件修正する。既定では適用しない。
  - 足元で品物を見つけたときに所持品がいっぱいだと表示されるウィンドウが
    画面左端にはみ出して表示が乱れるバグ。ウィンドウ描画ルーチンへ渡す
    左位置の指定 (バンク9、4446H の LD BC,055EH) を LD BC,045EH に変え、
    ウィンドウの左位置を 5 から 4 にする。幅は変えない。変更はこの
    1バイトのみで、適用すると出力は後期ROMとこの1バイトだけ異なる。

使い方:
  python3 make_msx1_late.py 入力.ROM [出力.ROM]
  python3 make_msx1_late.py 入力.ROM 出力.ROM --fix-window-bug
  python3 make_msx1_late.py --profile msx2 前期.ROM 出力.ROM --verify 後期.ROM
  (--profile msx2 は検証用。MSX2前期ROMに同じ手順を適用し、バンク14以外が
   後期ROMと一致するか確かめる。MSX2版ではキー入力ルーチン以降の領域全体も
   後期ROMと同様に 26Hバイト前に詰める)
"""

import struct
import sys

ROM_SIZE = 512 * 1024
BANK = 0x2000


def u16(d, o):
    return d[o] | (d[o + 1] << 8)


def w16(d, o, v):
    d[o] = v & 0xFF
    d[o + 1] = (v >> 8) & 0xFF


def find_all(d, pat, lo=0, hi=None):
    if hi is None:
        hi = len(d)
    hits = []
    i = d.find(pat, lo, hi)
    while i >= 0:
        hits.append(i)
        i = d.find(pat, i + 1, hi)
    return hits


def find_one(d, pat, lo=0, hi=None, what="パターン"):
    hits = find_all(d, pat, lo, hi)
    if len(hits) != 1:
        raise SystemExit(
            f"エラー: {what} が {len(hits)} 件検出されました (1件である必要があります): "
            + ", ".join(hex(h) for h in hits)
        )
    return hits[0]


# ================================================================
# バンク9+10の連続領域で、配置がずれる範囲を指す参照アドレスのオフセット一覧
# (バンク9先頭からのオフセット)
# ================================================================
T3_PLUS14 = [0x198, 0x19a, 0x19c, 0x19e, 0x1a0, 0x1a2, 0x1a4, 0x1a9, 0x1ab,
             0x1b0, 0x1b2, 0x1b9, 0x1bb, 0x1bd, 0x1bf, 0x1c4, 0x1c6, 0x1ca,
             0x1cf]
T3_PLUS13 = [0x40, 0x42, 0x44, 0x46, 0x1d1, 0x1d5, 0x1d9, 0x1dd, 0x99c,
             0xa0f, 0xa38, 0xa4d, 0xa69, 0xb20, 0xb45, 0xb55, 0xb73, 0xba8,
             0xbaa, 0xbac, 0xbae, 0xbb0, 0xbb2, 0xbb4, 0xbb6, 0xbb8, 0xbba,
             0xbbc, 0xbbe, 0xbd5, 0xbf4, 0xc8b, 0xe1b, 0xf2e, 0xf96, 0xf9d,
             0xff5, 0x102d, 0x1047, 0x1100, 0x1114, 0x114e, 0x115c, 0x115e,
             0x1160, 0x1162, 0x1164, 0x1166, 0x1168, 0x116a, 0x116c, 0x116e,
             0x1170, 0x1172, 0x1174, 0x1176, 0x1178, 0x117a, 0x117c, 0x117e,
             0x1180, 0x1182, 0x1184, 0x1186, 0x1188, 0x118a, 0x118c, 0x118e,
             0x1190, 0x1192, 0x1194, 0x1196, 0x1198, 0x119a, 0x119c, 0x119e,
             0x11a0, 0x11a2, 0x11a4, 0x11a6, 0x11a8, 0x11aa, 0x11ac, 0x11ae,
             0x11b0, 0x11b2, 0x11b4, 0x11b6, 0x11b8, 0x11ba, 0x11bc, 0x11be,
             0x11c0, 0x11c2, 0x11c4, 0x11c6, 0x11c8, 0x11ca, 0x11cc, 0x11ce,
             0x11d0, 0x11d2, 0x11d4, 0x11d6, 0x11d8, 0x11da, 0x11dc, 0x11de,
             0x11e0, 0x11e2, 0x11e4, 0x11e8, 0x11ec, 0x11fc, 0x1204, 0x1229,
             0x1231, 0x1238, 0x123b, 0x129f, 0x130a, 0x1386, 0x13bf, 0x13f9,
             0x1404, 0x1407, 0x140a, 0x141e, 0x1463, 0x1468, 0x146d, 0x1472,
             0x1478, 0x14ce, 0x14d2, 0x14e2, 0x14ea, 0x1518, 0x1520, 0x1524,
             0x1528, 0x1538, 0x1540, 0x1547, 0x1575, 0x157d, 0x1581, 0x1585,
             0x1595, 0x159d, 0x15a4, 0x15d2, 0x15da, 0x15de, 0x15e2, 0x15e7,
             0x15f2, 0x1604, 0x162d, 0x1631, 0x1634, 0x1637, 0x1647, 0x164b,
             0x1650, 0x1653, 0x1683, 0x1687, 0x168c, 0x168f, 0x1693, 0x1697,
             0x169c, 0x169f, 0x16a3, 0x16a7, 0x16ba, 0x16cd, 0x16d1, 0x16de,
             0x16e5, 0x16e9, 0x16ed, 0x1700, 0x1704, 0x1708, 0x170b, 0x170e,
             0x173f, 0x1743, 0x1750, 0x1753, 0x175a, 0x175d, 0x1761, 0x1765,
             0x1775, 0x1778, 0x1787, 0x178a, 0x1791, 0x179d, 0x17a1, 0x17a5,
             0x17be, 0x17c3, 0x17da, 0x1804, 0x180d, 0x1866, 0x189a, 0x189e,
             0x18c2, 0x18c6, 0x18ca, 0x18e9, 0x18ed, 0x18f1, 0x18f6, 0x1903,
             0x1924, 0x1945, 0x1964, 0x1968, 0x196c, 0x1974, 0x1977, 0x1994,
             0x1998, 0x199c, 0x199f, 0x19a7, 0x19b4, 0x19ea, 0x1a00, 0x1a05,
             0x1a0c, 0x1a14, 0x1a18, 0x1a1c, 0x1a24, 0x1a2c, 0x1a3b, 0x1a5a,
             0x1a5e, 0x1a62, 0x1aab, 0x1aaf, 0x1ab3, 0x1ab9, 0x1abd, 0x1ac1,
             0x1ac7, 0x1acb, 0x1acf, 0x1ae9, 0x1aed, 0x1af1, 0x1af7, 0x1afb,
             0x1aff,
             0x1b05, 0x1b09, 0x1b0d, 0x1b13, 0x1b17, 0x1b1b, 0x1b3a, 0x1b3e,
             0x1b42, 0x1b71, 0x1b75, 0x1b7c, 0x1b84, 0x1b92, 0x1ba3, 0x1ba7,
             0x1bb7, 0x1bc7, 0x1bcb, 0x1bcf, 0x1bd6, 0x1bde, 0x1be1, 0x1bec,
             0x1bef, 0x1c11, 0x1c15, 0x1c1c, 0x1c24, 0x1c32, 0x1c3a, 0x1c6b,
             0x1c6f, 0x1c73, 0x1c7b, 0x1c83, 0x1c99, 0x1c9d, 0x1ca5, 0x1cf2,
             0x1cf6, 0x1cfa, 0x1d10, 0x1d18, 0x1d3f, 0x1d47, 0x1d4b, 0x1d4f,
             0x1d81, 0x1d88, 0x1da7, 0x1dab, 0x1daf, 0x1dfe, 0x1e01, 0x1e04,
             0x1e23, 0x1e26, 0x1ea6, 0x1f27, 0x1f35, 0x1f61, 0x2169, 0x2173,
             0x217e, 0x2180, 0x2182, 0x2185, 0x21e3, 0x2248, 0x2250, 0x2258,
             0x225d, 0x2277, 0x227f, 0x2284, 0x22a0, 0x22ab, 0x22bc, 0x22db,
             0x2317]

# MSX2検証用: バンク15のキー入力処理より後ろ(ACD5H以降)を指す参照アドレスを 26H 減算する箇所の一覧
# (各領域先頭からのオフセット: T4B_STREAM=バンク9+10連続領域、T4B_BANK11/13/15=各バンク)
T4B_STREAM = [0x6, 0x14, 0x279, 0x2dd, 0x308, 0x396, 0x39e, 0x4b8, 0x4d1,
              0x4ed, 0x517, 0x578, 0x57d, 0x5a3, 0x5a8, 0x5e3, 0x5f7, 0x5fc,
              0x622, 0x627, 0x64a, 0x666, 0x6e3, 0x714, 0x725, 0x72f, 0x777,
              0x80b, 0x842, 0x847, 0x8dc, 0x932, 0x9c8, 0x9eb, 0xa12, 0xa26,
              0xa6f, 0xa97, 0xa9f, 0xad0, 0xad9, 0xaf7, 0xafa, 0xb69, 0xb6e,
              0x10a0, 0x10f9, 0x1201, 0x122e, 0x1286, 0x1368, 0x1376, 0x13b6,
              0x13b9, 0x13fe, 0x1401, 0x140f, 0x1412, 0x1415, 0x1418, 0x141b,
              0x14e7, 0x151d, 0x153d, 0x157a, 0x159a, 0x15d7, 0x15ef, 0x1601,
              0x160a, 0x1620, 0x1640, 0x1643, 0x165f, 0x1676, 0x16ac, 0x16c2,
              0x16fd, 0x1717, 0x1728, 0x173b, 0x17c6, 0x1815, 0x18a5, 0x18b1,
              0x1942, 0x1a09, 0x1a11, 0x1a34, 0x1ae3, 0x1b54, 0x1b6a, 0x1b8c,
              0x1b9c, 0x1bc4, 0x1bf4, 0x1bfe, 0x1c08, 0x1c2c, 0x1c3f, 0x1c8d,
              0x1cea, 0x1d15, 0x1d44, 0x1d71, 0x1dc4, 0x1de1, 0x1de8, 0x1eba,
              0x1ec3, 0x1ecf, 0x1f7b, 0x1f96, 0x216c, 0x21e6, 0x21ee, 0x2229,
              0x223b, 0x2253, 0x228d, 0x22fe, 0x2344, 0x2347, 0x234a, 0x234d,
              0x2350, 0x2355, 0x238d, 0x2441, 0x244a, 0x2461, 0x24a7, 0x24b0,
              0x24e2, 0x2510, 0x253c, 0x2541, 0x254e, 0x265b, 0x265e, 0x2661,
              0x2664, 0x2667, 0x266c, 0x26a4, 0x28c8, 0x28e3, 0x2b29, 0x2b4a,
              0x2b55, 0x2b5f, 0x2b73, 0x2b7e, 0x2b8f, 0x2b9a, 0x2ba5, 0x2bd2,
              0x2be4, 0x2bef, 0x2c3e, 0x2c46, 0x2d02, 0x2d7c, 0x2e55, 0x2f37,
              0x2f45, 0x2fd5, 0x2fed, 0x300a, 0x3071, 0x307b, 0x3083, 0x30ce,
              0x30df, 0x310b, 0x3126, 0x3141, 0x319d, 0x31a3, 0x31b5, 0x31c0,
              0x31cd, 0x31d0, 0x31d3, 0x31d6, 0x31d9, 0x3205, 0x3227, 0x3241,
              0x324c, 0x3266, 0x327e, 0x3298, 0x32a1, 0x32cf, 0x33b8, 0x33f9,
              0x342d, 0x3435, 0x344b, 0x348c, 0x3492, 0x34b0, 0x34d4, 0x34e0,
              0x34e9, 0x34f5, 0x3535, 0x3538, 0x3778, 0x37ab, 0x38d7, 0x3925,
              0x397c, 0x3a1e, 0x3a24, 0x3a2c, 0x3a33, 0x3a41, 0x3a93, 0x3aa1,
              0x3ad1, 0x3ae5, 0x3ae8, 0x3aeb, 0x3aee, 0x3b57, 0x3b67, 0x3b82,
              0x3b8e, 0x3b94, 0x3bb1, 0x3c21, 0x3c4b, 0x3c4e, 0x3c6f, 0x3c7f,
              0x3c8e, 0x3ca2, 0x3cb2, 0x3ccb, 0x3cf1, 0x3d09, 0x3d1e, 0x3d63,
              0x3d7b, 0x3d85, 0x3d8e, 0x3d97, 0x3da5, 0x3e31, 0x3e49, 0x3e7c,
              0x3e82, 0x3eb5]
T4B_BANK11 = [0x38, 0x5b, 0xb0, 0xba, 0xc1, 0xc8, 0xd3, 0xdb, 0xe9, 0xec,
              0x103, 0x118, 0x11e, 0x121, 0x134, 0x1b7, 0x213, 0x238, 0x243,
              0x248, 0x24e, 0x262, 0x269, 0x26c, 0x273, 0x27a, 0x293, 0x296,
              0x2a6, 0x2bc, 0x309, 0x313, 0x316, 0x329, 0x33c, 0x351, 0x366,
              0x36a, 0x435, 0x456, 0x46e, 0x491, 0x4c7, 0x4f7, 0x54d, 0x587,
              0x5bb, 0x5ca, 0x5fb, 0x625, 0x668, 0x6c1, 0x70d, 0x757, 0x760,
              0x78c, 0x7a5, 0x7be, 0x7d0, 0x7d8, 0x7e0, 0x7e3, 0x80b, 0x810,
              0x81c, 0x8f8, 0x8fd, 0x923, 0x93b, 0x953, 0x97b, 0x986, 0x9e3,
              0x9f8, 0xa0c, 0xa1f, 0xa33, 0xa50, 0xa7e, 0xade, 0xb73, 0xb98,
              0xba6, 0xbc5, 0xbd8, 0xbf5, 0xc1a, 0xc43, 0xc80, 0xc94, 0xc99,
              0xcb5, 0xcca, 0xcde, 0xcf3, 0xd09, 0xd22, 0xd5b, 0xd94, 0xda5,
              0xdc9, 0xddc, 0xdec, 0xdf6, 0xe06, 0xe68, 0xecc, 0xee1, 0xf0f,
              0xf50, 0xf57, 0xf63, 0xf7d, 0xf9b, 0xfb4, 0xfbe, 0xfc3, 0xfcf,
              0xff9, 0x1007, 0x1013, 0x1018, 0x102c, 0x103b, 0x1050, 0x1068,
              0x108f, 0x109c, 0x10bb, 0x10ca, 0x10ef, 0x10fb, 0x112a, 0x1165,
              0x118a, 0x1196, 0x11b0, 0x11c1, 0x11c8, 0x11d8, 0x11f3, 0x120e,
              0x1215, 0x122f, 0x1248, 0x1263, 0x126a, 0x1284, 0x129a, 0x12b4]
T4B_BANK13 = [0x12, 0x17, 0x3c, 0x50, 0x5c, 0x5f, 0x66, 0x6d, 0x106, 0x17f,
              0x1a0, 0x1b8, 0x1db, 0x274, 0x279, 0x281, 0x2b0, 0x2e3, 0x2e9,
              0x308, 0x315, 0x320, 0x32b, 0x341, 0x34c, 0x374, 0x381, 0x394,
              0x400, 0x46e, 0x4a8, 0x4dc, 0x4eb, 0x52b, 0x53f, 0x55b, 0x59e,
              0x604, 0x614, 0x680, 0x6ea, 0x6f3, 0x71f, 0x738, 0x742, 0x75a,
              0x76c, 0x774, 0x77c, 0x77f, 0x7b8, 0x7bd, 0x7c9, 0x8a5, 0x8aa,
              0x8b1, 0x93f, 0x97b, 0x980, 0x983, 0x989, 0x991, 0x99a, 0x9af,
              0x9ca, 0xa05, 0xa34, 0xa4d, 0xa56, 0xa59, 0xa65, 0xaf3, 0xb08,
              0xb1c, 0xc52, 0xc71, 0xc85, 0xd81, 0xd88, 0xe7a, 0xe85, 0xee1,
              0xf00, 0xf0c, 0x100a, 0x1014, 0x107a, 0x1085, 0x10c5, 0x10ca,
              0x10da, 0x1107, 0x112d, 0x113b, 0x1161, 0x117e, 0x1189, 0x119b,
              0x11a9, 0x11b9, 0x11c4, 0x11de, 0x11fe, 0x1209, 0x1223, 0x1226,
              0x12d5, 0x12f2, 0x132b, 0x1342, 0x1363, 0x136b, 0x138f, 0x139a,
              0x13a8, 0x13d5, 0x1415, 0x1421, 0x1449, 0x1461, 0x148f, 0x14c9,
              0x14e2, 0x14ef, 0x1502, 0x150b, 0x1527, 0x152f, 0x1535, 0x153e,
              0x1593, 0x15a2, 0x161a, 0x169f, 0x16c3, 0x16c7, 0x16e5, 0x16fa,
              0x1703, 0x1735, 0x1752, 0x175a, 0x1768, 0x1781, 0x178a, 0x179b,
              0x17af, 0x1870, 0x1898, 0x18ad, 0x18b0, 0x18c0, 0x18c3, 0x18de,
              0x18ea, 0x18ed, 0x18f6, 0x1998, 0x19e8, 0x1ab6, 0x1b94, 0x1bbb,
              0x1bc3, 0x1bd7, 0x1bfb, 0x1c17, 0x1c1f, 0x1c28, 0x1c2e, 0x1d0d,
              0x1d18, 0x1d32, 0x1d4b, 0x1d6b, 0x1d87, 0x1dc9, 0x1dcc, 0x1ddc,
              0x1de2, 0x1e35, 0x1e45, 0x1e58, 0x1e5f, 0x1f68]
T4B_BANK15 = [0x686, 0x74c, 0xb1c, 0xd1d, 0xd2a, 0xd6d, 0xdfa, 0xe08, 0xe0f,
              0xe13, 0xe2a, 0xe2e, 0xe32, 0xe36, 0xe59, 0xe61, 0xe64, 0xe6c,
              0xe6f, 0xe72, 0xec4, 0xecf, 0xed2, 0xf56, 0xf5b, 0xf61, 0xf64,
              0xf71, 0xffe, 0x100b, 0x1032, 0x1077, 0x10d8, 0x1144, 0x1184,
              0x118a, 0x11a4, 0x11ae, 0x11b4, 0x11ce, 0x1211, 0x124f, 0x126f,
              0x137c, 0x1399, 0x1423, 0x1426, 0x142b, 0x1434, 0x143a, 0x1447,
              0x1463, 0x148b, 0x1492, 0x14e1, 0x1503, 0x150a, 0x1512, 0x152e,
              0x156f, 0x1591, 0x15a6, 0x15c0, 0x15c3, 0x15e5, 0x162b, 0x162f,
              0x1633, 0x1636, 0x163b, 0x163e, 0x1673, 0x1676, 0x167a, 0x1681,
              0x1687, 0x168a, 0x16d5, 0x171f, 0x173e, 0x175a, 0x1780, 0x1796,
              0x1799, 0x17a1, 0x17a5, 0x17a8, 0x17b7, 0x17d5, 0x17db, 0x17e3,
              0x17e7, 0x17ea, 0x17fa, 0x17fe, 0x1801, 0x1804, 0x1809, 0x197b,
              0x1983, 0x1986, 0x198f, 0x199a, 0x19a5, 0x19b1, 0x19dd, 0x1a95,
              0x1aa4, 0x1aac, 0x1ac8, 0x1ad1, 0x1ada, 0x1ae3, 0x1aec, 0x1af5,
              0x1afe, 0x1b07, 0x1b49, 0x1b92, 0x1b95, 0x1bd9, 0x1c49, 0x1c4e,
              0x1c54, 0x1c57, 0x1c60, 0x1c63, 0x1c85, 0x1cf2, 0x1d08, 0x1d0f,
              0x1d28, 0x1d5c, 0x1d62, 0x1d6a, 0x1d96, 0x1dad, 0x1dbd, 0x1dc4,
              0x1dd5, 0x1df2, 0x1e01, 0x1e0c, 0x1e24, 0x1e2f, 0x1e3e, 0x1ec1,
              0x1ee7, 0x1eea, 0x1f50, 0x1f6e]


# ================================================================
# アドレス補正 (コード挿入前に、元のアドレス配置のまま実行する)
# ================================================================
def adjust_stream_values(rom):
    """バンク9+10の連続領域で、配置がずれる範囲を指す参照アドレスに 14 / 13 を加算する。"""
    S = 9 * BANK
    st = rom[S:11 * BANK]
    for off in T3_PLUS14:
        v = u16(st, off)
        assert 0x48F0 <= v < 0x49EB, (
            f"バンク9+10 オフセット {hex(off)} の参照アドレス {v:04X}H が想定範囲外です"
        )
        w16(st, off, v + 14)
    for off in T3_PLUS13:
        v = u16(st, off)
        assert 0x49EB <= v < 0x63AD, (
            f"バンク9+10 オフセット {hex(off)} の参照アドレス {v:04X}H が想定範囲外です"
        )
        w16(st, off, v + 13)
    rom[S:11 * BANK] = st
    print(f"\n  [アドレス補正: バンク9+10]\n"
          f"    剣・メモリバンク処理の変更による配置ずれに伴い、参照アドレス {len(T3_PLUS14) + len(T3_PLUS13)} 件を補正:\n"
          f"      - 14 加算: {len(T3_PLUS14)} 件\n"
          f"      - 13 加算: {len(T3_PLUS13)} 件")


def adjust_bank15_refs(rom):
    """MSX2検証用: バンク15のキー入力処理より後ろ(ACD5H以降)を指す参照アドレスから 26H を減算する。"""
    targets = [(9 * BANK, T4B_STREAM), (11 * BANK, T4B_BANK11),
               (13 * BANK, T4B_BANK13), (15 * BANK, T4B_BANK15)]
    n = 0
    for base, offs in targets:
        for off in offs:
            v = u16(rom, base + off)
            assert 0xACD5 <= v < 0xC000, (
                f"ROM {hex(base + off)} の参照アドレス {v:04X}H が想定範囲外です"
            )
            w16(rom, base + off, v - 0x26)
            n += 1
    print(f"\n  [アドレス補正 (検証用): バンク15 (ACD5H以降) への参照]\n"
          f"    - キー入力処理の短縮(26Hバイト減)による配置ずれに伴い、各領域からの参照アドレス {n} 件を 26H 減算")


# MSX2検証用: バンク13内にある、バンク14(6000H〜7FFFHにマップされる)を指す
# 参照アドレスのオフセット一覧。MSX2検証モードではバンク14の本体を動かさない一方、
# バンク13の挿入によりバンク14側が6バイト後ろへずれた状態を再現するため、
# コード内の63件に加えてディスパッチテーブル内の61件(0x1F81以降)も含めた計124件に 6 を加算する。
# MSX1版パッチではバンク14を動かさないため、本補正は検証用(msx2)でのみ実行する。
T_B14_IN_BANK13 = [0x1d, 0x2d, 0x36, 0x98, 0x9f, 0x176, 0x2a9, 0x2e6,
                   0x397, 0x3c0, 0x61a, 0x63c, 0x649, 0x67b, 0x6dc, 0x936,
                   0x986, 0x9a3, 0xc66, 0xd54, 0xef4, 0xefb, 0xf86, 0xfc5,
                   0xfcd, 0xfd5, 0xfdf, 0xfe7, 0xfef, 0xff7, 0x1020, 0x10cd,
                   0x10dd, 0x1198, 0x11e1, 0x1201, 0x121e, 0x12d8, 0x1326,
                   0x1351, 0x1396, 0x1467, 0x146a, 0x1495, 0x14ea, 0x152a,
                   0x1652, 0x167b, 0x1706, 0x1760, 0x1784, 0x18b8, 0x18f0,
                   0x1b65, 0x1bb2, 0x1bda, 0x1c0e, 0x1d1b, 0x1d80, 0x1dc1,
                   0x1de5, 0x1e62, 0x1f70, 0x1f81, 0x1f83, 0x1f85, 0x1f87,
                   0x1f89, 0x1f8b, 0x1f8d, 0x1f8f, 0x1f91, 0x1f93, 0x1f95,
                   0x1f97, 0x1f99, 0x1f9b, 0x1f9d, 0x1f9f, 0x1fa1, 0x1fa3,
                   0x1fa5, 0x1fa7, 0x1fa9, 0x1fab, 0x1fad, 0x1faf, 0x1fb1,
                   0x1fb3, 0x1fb5, 0x1fb7, 0x1fb9, 0x1fbb, 0x1fbd, 0x1fbf,
                   0x1fc1, 0x1fc3, 0x1fc5, 0x1fc7, 0x1fc9, 0x1fcb, 0x1fcd,
                   0x1fcf, 0x1fd1, 0x1fd3, 0x1fd5, 0x1fd7, 0x1fd9, 0x1fdb,
                   0x1fdd, 0x1fdf, 0x1fe1, 0x1fe3, 0x1fe5, 0x1fe7, 0x1fe9,
                   0x1feb, 0x1fed, 0x1fef, 0x1ff1, 0x1ff3, 0x1ff5, 0x1ff7,
                   0x1ff9]


def adjust_bank14_refs_in_bank13(rom):
    """MSX2検証用: バンク13からバンク14を指す参照アドレスに 6 を加算する。"""
    base = 13 * BANK
    for off in T_B14_IN_BANK13:
        v = u16(rom, base + off)
        assert 0x6000 <= v < 0x8000, (
            f"バンク13 オフセット {hex(off)} の参照アドレス {v:04X}H が想定範囲外です"
        )
        w16(rom, base + off, v + 6)
    print(f"\n  [アドレス補正 (検証用): バンク13 -> バンク14]\n"
          f"    - バンク14全体の+6バイトずれに伴い、バンク13内の参照アドレス {len(T_B14_IN_BANK13)} 件を 6 加算")


# 16bit即値/絶対アドレスをオペランドに取るZ80命令のオペコード
NN_OPS = {0xCD, 0xC3, 0x01, 0x11, 0x21, 0x31, 0x22, 0x32, 0x3A, 0x2A,
          0xC2, 0xCA, 0xD2, 0xDA, 0xE2, 0xEA, 0xF2, 0xFA,
          0xC4, 0xCC, 0xD4, 0xDC, 0xE4, 0xEC, 0xF4, 0xFC}
NN_OPS2 = {0x4B, 0x5B, 0x43, 0x53, 0x21, 0x22, 0x2A}  # ED/DD/FD プリフィクス後続バイト


def adjust_bank13_values(rom, threshold):
    """バンク13: Z80命令のオペランドとして使われている参照アドレスにのみ 6 を加算する。
    対象は元のバイト列から先にすべて抽出し、その後でまとめて書き換える
    (書き換えながら走査すると、書き換えたバイトが次の値の一部として誤検出され、
    対象外の箇所まで拾ってしまうため)。"""
    base = 13 * BANK
    b = rom[base:base + BANK]
    targets = []
    for i in range(BANK - 1):
        v = u16(b, i)
        if not (threshold <= v < 0x6000):
            continue
        operand = (i >= 1 and b[i - 1] in NN_OPS) or \
                  (i >= 2 and b[i - 2] in (0xED, 0xDD, 0xFD)
                   and b[i - 1] in NN_OPS2)
        if operand:
            targets.append((i, v + 6))
    b = bytearray(b)
    for i, nv in targets:
        w16(b, i, nv)
    rom[base:base + BANK] = b
    print(f"\n  [アドレス補正: バンク13内]\n"
          f"    - 初期化処理への+6バイト挿入による配置ずれに伴い、16bitオペランドの参照アドレス {len(targets)} 件を 6 加算")
    return len(targets)


# ================================================================
# 1. スタッフロール修正
# ================================================================
def patch_credits(rom, bank_no):
    base = bank_no * BANK
    b = bytearray(rom[base:base + BANK])
    pat = b"The Space Memori"
    i = find_one(b, pat, what="スタッフロール文字列")
    ins = i + len(pat)
    assert b[ins:ins + 1] == b"s", "'s' の位置が想定と一致しません"
    assert b[-1] == 0, "バンク末尾が 00H でないため、1バイト挿入できません"
    nb = (bytes(b[:ins]) + b"e" + bytes(b[ins:]))[:BANK]
    rom[base:base + BANK] = nb
    print(f"\n  [スタッフロール (バンク{bank_no})]\n"
          f"    - ROM {hex(base + ins)} に 'e' を挿入しスペルを修正 (\"Memoris\" -> \"Memories\")")


# ================================================================
# 2. メッセージ修正およびポインタテーブル補正
# ================================================================
def patch_messages_conv(rom):
    S, E = 0x4C000, 0x50000
    st = bytearray(rom[S:E])
    old = bytes.fromhex(
        "05" + "20" * 20 + "ffc3ff0dfe7afe8f" + "21" + "fff3fe06ff5ea1a3")
    new = bytes.fromhex(
        "05" + "20" * 20 + "ffc3ff0dfe7afe8f" + "2b2d" + "fff3fe06ff5ea1a3")
    i = find_one(st, old, what="会話メッセージ269番(日本語)")
    saddr = 0x4000 + i
    st = st[:i] + new + st[i + len(old):]
    assert st[-1] == 0, "会話メッセージ領域の末尾が 00H でないため、1バイト挿入できません"
    st = st[:E - S]
    for k in range(320):
        v = u16(st, 2 * k)
        if v > saddr:
            struct.pack_into("<H", st, 2 * k, v + 1)
    en_off = 0x19F8 + 1
    for k in range(320):
        v = u16(st, en_off + 2 * k)
        if v > saddr:
            struct.pack_into("<H", st, en_off + 2 * k, v + 1)
    rom[S:E] = st
    print("\n  [会話メッセージ269番 (日本語)]\n"
          "    - \"予想誤差!３以内。\" -> \"予想誤差+-３以内。\" (+1バイト)\n"
          "    - 1バイト増加に伴いメッセージテーブルのポインタを補正")


def patch_messages_sys(rom):
    S, E = 0x50000, 0x54000
    st = bytearray(rom[S:E])
    en_off = 0xF1D
    v72 = u16(st, en_off + 2 * 72)
    soff = v72 - 0x4000
    old = b"Can't throw away for be too good"
    new = b"Can't throw for be too good"
    assert bytes(st[soff:soff + len(old)]) == old, "システムメッセージ72番(英語)が想定と一致しません"
    assert st[soff + len(old)] == 0
    END = 0x2215
    st = (st[:soff] + new + st[soff + len(old):END]
          + b"\x00" * 5 + st[END:])
    assert len(st) == E - S
    for k in range(328):
        v = u16(st, en_off + 2 * k)
        if v > v72:
            struct.pack_into("<H", st, en_off + 2 * k, v - 5)
    rom[S:E] = st
    print("\n  [システムメッセージ72番 (英語)]\n"
          "    - \"Can't throw away ...\" -> \"Can't throw ...\" (-5バイト)\n"
          "    - 5バイト削減に伴い英語メッセージテーブルのポインタを補正")


def patch_message_table_ref(rom):
    pat = bytes.fromhex("11f8593a01d0fe02")   # LD DE,59F8H; LD A,(D001H); CP 2
    i = find_one(rom, pat, 15 * BANK, 16 * BANK, "英語会話メッセージテーブル参照命令")
    rom[i + 1] = 0xF9
    print(f"\n  [英語会話メッセージテーブル参照]\n"
          f"    - 会話269番の+1バイト増加による開始位置ずれに伴い、ROM {hex(i)} のアドレス即値を 59F8H -> 59F9H に補正")


# ================================================================
# 6. ウェイトループのカウンタ値変更
# ================================================================
def patch_wait_counters(rom, wait_call):
    pat = bytes.fromhex("2100082b7cb5280f")   # LD HL,0800H; DEC HL; ...; JR Z
    hits = find_all(rom, pat)
    assert len(hits) == 2, f"0800H ウェイトループの検出数が想定外です ({len(hits)} 件)"
    for h in hits:
        rom[h + 2] = 0x02
    pat = wait_call + bytes.fromhex("210030") + wait_call
    hits = find_all(rom, pat)
    assert len(hits) == 2, f"3000H ウェイトループの検出数が想定外です ({len(hits)} 件)"
    for h in hits:
        rom[h + 5] = 0x0C
    pat = bytes.fromhex("042100022b7cb520fb")
    h = find_one(rom, pat, 13 * BANK, 14 * BANK, "0200H ディレイループ")
    rom[h + 3] = 0x04
    pat = bytes.fromhex("06042180002b7cb520")  # LD B,4; LD HL,0080H; ...
    h = find_one(rom, pat, what="0080H ウェイトループ")
    rom[h + 1] = 0x08
    print("\n  [ウェイトループ]\n"
          "    カウンタ値およびループ回数を変更:\n"
          "      - 0800H -> 0200H (2箇所)\n"
          "      - 3000H -> 0C00H (2箇所)\n"
          "      - 0200H -> 0400H (1箇所)\n"
          "      - ループ回数 4回 -> 8回 (1箇所)")


# ================================================================
# 3. バンク9+10のコード挿入と置換
# ================================================================
def patch_bank9_10_splices(rom, bef5_call, bd91_call):
    S, E = 9 * BANK, 11 * BANK
    st = bytearray(rom[S:E])
    pat = bytes.fromhex("c24841") + bytes.fromhex("21dad03e06c31748")
    p = find_one(st, pat, what="剣入手処理")
    sword_off = p + 3
    new_seq = (bytes.fromhex("3a93d0b7" "2808")
               + bytes.fromhex("21dad03e06c31748")
               + bytes.fromhex("21dad03e04c31748"))
    st = st[:sword_off] + new_seq + st[sword_off + 8:]
    pat2 = (bytes.fromhex("01010d") + bef5_call
            + bytes.fromhex("2aa5d02cb7ed42c8"))
    q = find_one(st, pat2, what="メモリバンク判定処理")
    stage1_new = (bytes.fromhex("ed4ba5d00c") + bd91_call
                  + bytes.fromhex("cb76" "ca4841"))
    st = st[:q] + stage1_new + st[q + 14:]
    ABS = 0x2000 + 0x3AD
    assert all(x == 0 for x in st[ABS:ABS + 13]), "バンク10の空き領域(00H×13)が不足しています"
    st = st[:ABS] + st[ABS + 13:]
    assert len(st) == E - S
    rom[S:E] = st
    print("\n  [コード変更: バンク9+10]\n"
          "    - 銀製の剣/光の剣の分岐追加のため、剣入手処理に D093H フラグ判定を挿入 (+14バイト)\n"
          "    - 湖の宮殿コンピュータ暴走バグ修正のため、判定をチップBit6確認へ置換 (-1バイト)\n"
          "    - 増加した13バイト分をバンク10の空き領域で吸収 (-13バイト)")


# ================================================================
# 5b. MSX1用: バンク14のジャンプテーブル補正とレコード0の退避
# ================================================================
def fix_bank14_items_msx1(rom, threshold):
    """バンク13とバンク14にまたがるイベントテーブルの補正(MSX1用)。

    ディスパッチテーブルを参照している命令のコードからテーブル(33エントリ)を
    たどり、バンク14に配置されているジャンプテーブル内のアドレスのうち、
    バンク13の挿入で後ろへずれる範囲を指すものに 6 を加算する。
    最初のエントリ(エントリ0)が指すレコードデータ(レコード0)だけはバンク13と
    バンク14にまたがって配置されており、挿入によって途中のバイトが欠損してしまう。
    そのため、このレコード0をバンク14末尾の空き領域へ丸ごと退避(再配置)し、
    ディスパッチテーブルの先頭エントリを退避先のアドレスへ書き換える。
    (バンク14自体は動かさないため、バンク14を指すアドレスの補正は不要)
    """
    pat = bytes.fromhex("3a9fd087876f260011")
    # LD A,(D09FH); ADD A,A; ADD A,A; LD L,A; LD H,0; LD DE,ディスパッチテーブル
    i = find_one(rom, pat, 13 * BANK, 14 * BANK, "ディスパッチテーブル参照処理")
    table_base = u16(rom, i + 9)

    entries = []
    for k in range(33):
        eo = 13 * BANK + (table_base - 0x4000) + 4 * k
        st = u16(rom, eo)
        ps = u16(rom, eo + 2)
        n = rom[13 * BANK + (st - 0x4000)]
        assert ps == st + 1 + n and 1 <= n <= 40, \
            f"ディスパッチテーブルのエントリ{k} の構造が想定と一致しません"
        entries.append((eo, st, ps, n))

    # エントリ1以降のジャンプテーブル内のアドレスのうち、バンク13の配置ずれ範囲を指すものに 6 を加算
    cnt = 0
    for eo, st, ps, n in entries[1:]:
        for j in range(n):
            fo = 13 * BANK + (ps - 0x4000) + 2 * j
            v = u16(rom, fo)
            assert 0x4000 <= v < 0x6000, (
                f"ジャンプテーブルのジャンプ先アドレス {v:04X}H が想定範囲外です"
            )
            if threshold <= v:
                w16(rom, fo, v + 6)
                cnt += 1

    # バンク境界を跨ぐレコード0の退避(再配置)
    eo0, st, ps, n = entries[0]
    ln = 1 + n + 2 * n
    rec_off = 13 * BANK + (st - 0x4000)
    rec = bytearray(rom[rec_off:rec_off + ln])
    for j in range(n):
        off = 1 + n + 2 * j
        v = u16(rec, off)
        if threshold <= v < 0x6000:
            w16(rec, off, v + 6)
    dst = BANK - ln   # バンク14末尾の空き領域を使用
    assert all(x == 0 for x in rom[14 * BANK + dst:14 * BANK + dst + ln]), \
        "バンク14末尾の空き領域が不足しています"
    rom[14 * BANK + dst:14 * BANK + dst + ln] = rec
    new_addr = 0x6000 + dst
    w16(rom, eo0, new_addr)
    w16(rom, eo0 + 2, new_addr + 1 + n)

    print(f"\n  [アドレス補正・退避: バンク14 イベントテーブル]\n"
          f"    - バンク13の+6バイト挿入による配置ずれに伴い、イベントジャンプテーブル内のジャンプ先アドレス {cnt} 件を 6 加算\n"
          f"    - バンク13の+6バイト挿入によるデータ欠損を防ぐため、境界跨ぎのレコード0を末尾空き領域({new_addr:04X}H)へ退避\n"
          f"    - 退避に伴いディスパッチテーブルの先頭エントリを更新 ({new_addr:04X}H)")


# ================================================================
# 5. バンク13のコード挿入
# ================================================================
def patch_bank13_splice(rom):
    base = 13 * BANK
    b = bytearray(rom[base:base + BANK])
    pat = bytes.fromhex("3a8cd0b7c032c1da")
    cand = [i for i in find_all(b, pat)
            if bytes(b[i + 0x10:i + 0x15]) == bytes.fromhex("3e01328cd0")]
    assert len(cand) == 1, f"バンク13の対象処理が一意に特定できません ({len(cand)} 件)"
    tail_off = cand[0] + 0x10
    old_tail = bytes(b[tail_off:tail_off + 11])
    assert old_tail[5] == 0xCD and old_tail[8] == 0xC3, "対象処理末尾の命令列が想定と一致しません"
    jp_target = u16(old_tail, 9)
    new_tail = (bytes.fromhex("3100f0") + old_tail[:8]
                + b"\xcd" + old_tail[9:11] + bytes.fromhex("c32240"))
    assert len(new_tail) == 17
    b = b[:tail_off] + new_tail + b[tail_off + 11:]
    b = b[:BANK]
    rom[base:base + BANK] = b
    print(f"\n  [コード変更: バンク13]\n"
          f"    - 初期化処理にスタック再設定 (LD SP,0F000H) を追加 (+3バイト)\n"
          f"    - 戻り先消失による暴走を防ぐため、末尾を JP {jp_target:04X}H から CALL {jp_target:04X}H + JP 4022H に変更 (+3バイト)")


# ================================================================
# 4. バンク15のキー入力ルーチン置換
# ================================================================
LATE_KB = bytearray(bytes.fromhex(
    "e5cd0000"      # PUSH HL; CALL kb_reader (アドレスは後で設定)
    "67"            # LD H,A
    "3a8edc" "bc" "201b"          # LD A,(DC8EH); CP H; JR NZ,+1BH
    "7c" "e6f0" "feb0" "2007"     # LD A,H; AND 0F0H; CP 0B0H; JR NZ,+7
    "7c" "218fdc" "35" "2804" "e1" "3ebf" "c9"
    #   LD A,H; LD HL,DC8FH; DEC (HL); JR Z,+4; POP HL; LD A,0BFH; RET
    "67" "3e32" "328fdc" "7c" "e1" "c9"
    #   LD H,A; LD A,32H; LD (DC8FH),A; LD A,H; POP HL; RET
    "3efa" "328fdc" "7c" "328edc" "e1" "c9"))
    #   LD A,0FAH; LD (DC8FH),A; LD A,H; LD (DC8EH),A; POP HL; RET


def patch_bank15(rom, kb_entry, kb_reader, kb_call_target, shift):
    base = 15 * BANK
    b = bytearray(rom[base:base + BANK])
    eoff = kb_entry - 0xA000
    roff = kb_reader - 0xA000
    routine = bytearray(LATE_KB)
    routine[2] = kb_call_target & 0xFF
    routine[3] = kb_call_target >> 8
    assert len(routine) == 49
    if shift:
        nb = bytes(b[:eoff]) + bytes(routine) + bytes(b[roff:])
        nb = nb + b"\x00" * (BANK - len(nb))
        assert len(nb) == BANK
        rom[base:base + BANK] = nb
        print("\n  [コード変更: バンク15]\n"
              "    - キー入力ルーチンを後期版へ置換\n"
              "    - 短縮された38バイト(26Hバイト)分だけ後続領域を前に詰める")
    else:
        pad = roff - (eoff + len(routine))
        assert pad >= 0, "後期版キー入力ルーチンが元の領域サイズに収まりません"
        nb = (bytes(b[:eoff]) + bytes(routine)
              + b"\x00" * pad + bytes(b[roff:]))
        assert len(nb) == BANK
        rom[base:base + BANK] = nb
        print(f"\n  [コード変更: バンク15]\n"
              f"    - キー入力ルーチンを後期版へ置換\n"
              f"    - 後続サブルーチンのアドレスを維持するため、余剰 {pad} バイトを 00H でパディング")


# ================================================================
# 任意のバグ修正: 足元イベントのウィンドウはみ出し (--fix-window-bug)
# ================================================================
def fix_window_bug(rom):
    """所持品がいっぱいのときに足元で品物を見つけたときの表示で使うウィンドウの左位置を補正する。

    バンク9の 4446H にある LD BC,055EH の即値が、ウィンドウ描画ルーチン
    (MSX1版: A7FEH、MSX2版: AB61H) へ渡す「左位置 5、上位置 5EH」を指定している。
    幅はバンク9の 4449H にある LD DE,1326H で 19 が指定されている。左位置 5 と
    幅 19 の組み合わせではウィンドウの右端が 22 列目になり、1 行 22 列 (0〜21 列) で
    アドレスを計算する画面描画の範囲をはみ出すため、右端の列が次の行の先頭列と
    同じアドレスへ描かれ、画面左端が乱れる。
    幅を 18 に変えても右端は 21 列目に収まるが、幅は変えない。表示する文字は、
    アイテム名 (最大8文字) とシステムメッセージ $EF (9文字) を合わせた 1 行目が
    最大で 17 文字あり、ウィンドウの内側は幅 19 で 17 列のため、幅を減らすと
    文字がウィンドウからはみ出す。左位置を 4 に変えると、積み重ねできるアイテムを
    表示する処理 (4491H) のウィンドウと同じ左位置と幅の組み合わせになる。
    このバグは前期・後期の両ロットにあるため、後期ロット相当への改造とは別に、
    オプション指定時のみ適用する。
    """
    off = 9 * BANK + 0x448
    assert rom[off] == 0x05, "ウィンドウの左位置の指定 (LD BC,055EH の即値) が想定と一致しません"
    rom[off] = 0x04
    print("\n  [バグ修正: 足元イベントのウィンドウ左位置]\n"
          "    - LD BC,055EH -> LD BC,045EH (ウィンドウの左位置 5 -> 4)")


# ================================================================
# 実行プロファイル・メイン処理
# ================================================================
PROFILES = {
    "msx1": dict(
        credits_bank=5,
        wait_call=bytes.fromhex("cd30a9"),        # CALL A930H (キー入力ルーチン)
        bef5_call=bytes.fromhex("cddcba"),        # CALL BADCH
        bd91_call=bytes.fromhex("cd78b9"),        # CALL B978H (MSX2前期の BD91H に相当する処理。MSX1の BD91H は空き領域)
        kb_entry=0xA930, kb_reader=0xA985, kb_call_target=0xA985,
        bank13_threshold=0x5B57,
        shift_bank15=False,
    ),
    "msx2": dict(
        credits_bank=7,
        wait_call=bytes.fromhex("cd7eac"),        # CALL AC7EH (キー入力ルーチン)
        bef5_call=bytes.fromhex("cdf5be"),        # CALL BEF5H
        bd91_call=bytes.fromhex("cd6bbd"),        # CALL BD6BH (バンク15を 26Hバイト前に詰めた後の BD91H)
        kb_entry=0xAC7E, kb_reader=0xACD5, kb_call_target=0xACAF,
        bank13_threshold=0x5B6C,
        shift_bank15=True,
    ),
}


def run(profile_name, data, fix_window=False):
    p = PROFILES[profile_name]
    rom = bytearray(data)
    assert len(rom) == ROM_SIZE, "512KBのROMイメージではありません"
    print(f"[{profile_name}] パッチを適用します")
    patch_credits(rom, p["credits_bank"])
    patch_wait_counters(rom, p["wait_call"])
    # アドレス補正 (コード挿入によって配置がずれる前に実行)
    adjust_stream_values(rom)
    if p["shift_bank15"]:
        adjust_bank13_values(rom, p["bank13_threshold"])
        adjust_bank14_refs_in_bank13(rom)
        adjust_bank15_refs(rom)
    else:
        fix_bank14_items_msx1(rom, p["bank13_threshold"])
        adjust_bank13_values(rom, p["bank13_threshold"])
    # メッセージ関連パッチ
    patch_messages_conv(rom)
    patch_messages_sys(rom)
    patch_message_table_ref(rom)
    # コード挿入・置換
    patch_bank9_10_splices(rom, p["bef5_call"], p["bd91_call"])
    patch_bank13_splice(rom)
    patch_bank15(rom, p["kb_entry"], p["kb_reader"],
                 p["kb_call_target"], p["shift_bank15"])
    if fix_window:
        fix_window_bug(rom)
    return bytes(rom)


def main(argv):
    profile = "msx1"
    verify_path = None
    fix_window = False
    rest = argv[1:]
    pos = []
    i = 0
    while i < len(rest):
        a = rest[i]
        if a == "--profile":
            profile = rest[i + 1]
            i += 2
        elif a == "--verify":
            verify_path = rest[i + 1]
            i += 2
        elif a == "--fix-window-bug":
            fix_window = True
            i += 1
        else:
            pos.append(a)
            i += 1
    if not pos:
        print(__doc__)
        return 1
    src = open(pos[0], "rb").read()
    out = run(profile, src, fix_window)
    if len(pos) >= 2:
        open(pos[1], "wb").write(out)
        print(f"\n出力完了: {pos[1]}")
    if verify_path:
        late = open(verify_path, "rb").read()
        print(f"\n[検証] 後期ROM ({verify_path}) と比較します")
        total = 0
        total14 = 0
        for bank_no in range(64):
            d = sum(1 for x, y in zip(out[bank_no * BANK:(bank_no + 1) * BANK],
                                      late[bank_no * BANK:(bank_no + 1) * BANK])
                    if x != y)
            if d:
                print(f"  - バンク{bank_no}: {d} バイト不一致"
                      + (" (バンク14は境界跨ぎ配置ずれのため比較対象外)" if bank_no == 14 else ""))
            total += d
            if bank_no == 14:
                total14 = d
        print(f"  合計差分: {total} バイト (バンク14除外時: {total - total14} バイト)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
