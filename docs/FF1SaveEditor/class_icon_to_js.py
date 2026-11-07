import os
import sys
from PIL import Image

# ジョブ定義名
JOB_NAMES = [
    "0: 戦士 (Fighter)",
    "1: シーフ (Thief)",
    "2: モンク (Monk)",
    "3: 赤魔術士 (Red Mage)",
    "4: 白魔術士 (White Mage)",
    "5: 黒魔術士 (Black Mage)",
    "6: ナイト (Knight)",
    "7: 忍者 (Ninja)",
    "8: スーパーモンク (Master)",
    "9: 赤魔道士 (Red Wizard)",
    "10: 白魔道士 (White Wizard)",
    "11: 黒魔道士 (Black Wizard)"
]

# タイルの基準座標オフセット (X, Y)
TILE_OFFSETS = [
    (0, 0),   # 左上
    (8, 0),   # 右上
    (0, 8),   # 左中
    (8, 8),   # 右中
    (0, 16),  # 左下
    (8, 16),  # 右下
]


def extract_character_silhouette(img, base_x, base_y):
    """
    指定座標(base_x, base_y)から16x24ピクセルのキャラクタを切り出し、
    48バイトの1bppマスク配列を生成する。
    """
    byte_array = []
    for ox, oy in TILE_OFFSETS:
        for y in range(8):
            row_byte = 0
            for x in range(8):
                px = base_x + ox + x
                py = base_y + oy + y
                r, g, b, a = img.getpixel((px, py))
                # アルファ値が0より大きければ不透明(1)と判定
                if a > 0:
                    row_byte |= (1 << (7 - x))
            byte_array.append(row_byte)
    return byte_array


def main():
    # 入力ファイル名の取得（指定がなければデフォルト名）
    input_file = sys.argv[1] if len(sys.argv) > 1 else "ff1_editor_class_chr.png"

    if not os.path.exists(input_file):
        print(f"エラー: 画像ファイルが見つかりません: {input_file}", file=sys.stderr)
        sys.exit(1)

    try:
        img = Image.open(input_file).convert("RGBA")
    except Exception as e:
        print(f"エラー: 画像の読み込みに失敗しました: {e}", file=sys.stderr)
        sys.exit(1)

    char_width = 16
    char_height = 24
    num_jobs = 12

    if img.width < char_width * num_jobs or img.height < char_height:
        print(f"エラー: 画像サイズが不足しています。(現在: {img.width}x{img.height}, 必要: {char_width * num_jobs}x{char_height})", file=sys.stderr)
        sys.exit(1)

    print("  static DEFAULT_SILHOUETTES = [")
    for job_idx in range(num_jobs):
        char_x = job_idx * char_width
        char_y = 0
        mask_bytes = extract_character_silhouette(img, char_x, char_y)

        job_label = JOB_NAMES[job_idx] if job_idx < len(JOB_NAMES) else f"{job_idx}: 不明"
        print(f"    // {job_label} - 48 bytes")
        print("    new Uint8Array([")

        # 8バイト（1タイル）ごとに1行でフォーマット
        for t in range(6):
            tile_bytes = mask_bytes[t * 8:(t + 1) * 8]
            hex_str = ",".join(f"0x{b:02X}" for b in tile_bytes)
            comma = "," if t < 5 else ""
            print(f"      {hex_str}{comma}")

        end_comma = "," if job_idx < num_jobs - 1 else ""
        print(f"    ]){end_comma}")
    print("  ];")


if __name__ == "__main__":
    main()
