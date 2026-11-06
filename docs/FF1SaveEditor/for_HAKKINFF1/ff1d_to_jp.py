import argparse
import os
import re
import shutil
import sys

# セクション別に置換辞書を定義
SECTION_REPLACEMENTS = {
    # 大見出しセクション
    'LabelTitles': {
        '"DialogueText": "Dialogue Text"': '"DialogueText": "会話テキスト"',
        '"WepMag": "Weapon/Magic Graphics"': '"WepMag": "武器・魔法グラフィック"',
        '"AI": "AI"': '"AI": "敵AIルーチン"',
        '"Shop": "Shop"': '"Shop": "ショップ"',
        '"Battle": "Battle"': '"Battle": "戦闘グループ"',
        '"BattlePatternTable": "Battle Pattern Table"': '"BattlePatternTable": "戦闘パターンテーブル"',
        '"Backdrop": "Backdrop"': '"Backdrop": "戦闘背景"',
        '"ONTeleport": "Overworld Teleport"': '"ONTeleport": "マップ進入テレポート"',
        '"NNTeleport": "Local Teleport (NN)"': '"NNTeleport": "マップ間テレポート"',
        '"NOTeleport": "Local Teleport (NO)"': '"NOTeleport": "マップ脱出テレポート"',
        '"TreasureChest": "Treasure Chest"': '"TreasureChest": "宝箱"',
        '"Map": "Map"': '"Map": "マップ"',
        '"Tileset": "Tileset"': '"Tileset": "タイルセット"',
        '"Sprite": "Sprite"': '"Sprite": "配置スプライト"',
        '"SpriteGraphic": "Sprite Graphic"': '"SpriteGraphic": "スプライト画像"',
        '"ArmorTypes": "Armor Types"': '"ArmorTypes": "防具種別"',
        '"EnemyCategories": "Enemy Categories"': '"EnemyCategories": "敵タイプ"',
        '"SpecialTile": "Special Tile"': '"SpecialTile": "特殊タイル"',
        '"Ailments": "Ailments"': '"Ailments": "状態異常"',
    },
    # タイルセット
    'Tileset': {
        '"Town"': '"町"',
        '"Castle"': '"城"',
        '"Earth Cave"': '"洞窟 (アース・火山)"',
        '"Ice Cave"': '"洞窟 (マトーヤ・氷)"',
        '"Tower"': '"遺跡・塔"',
        '"Shrine"': '"神殿 (海底・カオス)"',
        '"Sky Castle"': '"浮遊城"',
        '"ToF"': '"過去のカオスの神殿"',
    },
    # 防具部位
    'ArmorTypes': {
        '"Body"': '"体装備"',
        '"Shield"': '"盾装備"',
        '"Head"': '"頭装備"',
        '"Arms"': '"腕装備"',
    },
    # 敵タイプ
    'EnemyCategories': {
        '"Special"': '"特殊"',
        '"Dragon"': '"竜"',
        '"Giant"': '"巨人"',
        '"Undead"': '"不死"',
        '"Were"': '"魔獣"',
        '"Water"': '"水棲"',
        '"Mage"': '"魔導"',
        '"Regenerative"': '"再生"',
    },
    # 状態異常
    'Ailments': {
        '"Death"': '"死亡"',
        '"Stone"': '"石化"',
        '"Poison"': '"毒"',
        '"Dark"': '"暗闇"',
        '"Stun"': '"麻痺"',
        '"Sleep"': '"睡眠"',
        '"Mute"': '"沈黙"',
        '"Conf"': '"混乱"',
    },
    # 特殊タイル
    'SpecialTile': {
        '"Door - Open Rooms"': '"扉 - 部屋を開く"',
        '"Door - Close Rooms"': '"扉 - 部屋を閉じる"',
        '"Door - Locked Door"': '"扉 - 鍵のかかった扉"',
        '"Move - Need Crown"': '"進入 - クラウンが必要"',
        '"Move - Need Cube"': '"進入 - キューブが必要"',
        '"Move - Need 4 Orbs"': '"進入 - 4つのオーブが必要"',
        '"Orb - Earth Orb"': '"祭壇 - 土のクリスタル"',
        '"Orb - Fire Orb"': '"祭壇 - 火のクリスタル"',
        '"Orb - Water Orb"': '"祭壇 - 水のクリスタル"',
        '"Orb - Air Orb"': '"祭壇 - 風のクリスタル"',
        '"Misc - Lower HP"': '"その他 - ダメージ床"',
        '"Misc - Use Lute"': '"その他 - リュートを弾く"',
        '"Misc - Use Rod"': '"その他 - つちのつえを使う"',
    },
    # 戦闘背景
    'Backdrop': {
        '"Grass"': '"平原"',
        '"Marsh Cave"': '"沼の洞窟"',
        '"Cave"': '"洞窟"',
        '"Water"': '"水辺"',
        '"Forest"': '"森林"',
        '"ToF"': '"カオスの神殿"',
        '"Desert"': '"砂漠"',
        '"Marsh"': '"湿地"',
        '"Earth Cave"': '"アースの洞窟"',
        '"Castle"': '"城"',
        '"River"': '"川"',
        '"Tower"': '"ミラージュの塔"',
        '"Sea Shrine"': '"海底神殿"',
        '"Ice Cave"': '"氷の洞窟"',
        '"Volcano"': '"グルグ火山"',
        '"Waterfall"': '"滝の裏の洞窟"',
    },
    # サブマップ名（全61件）
    'Map': {
        '"Coneria"': '"コーネリアの町"',
        '"Provoka"': '"プラボカ"',
        '"Elfland"': '"エルフの町"',
        '"Melmond"': '"メルモンド"',
        '"Cresent Lake"': '"クレセントレイク"',
        '"Gaia"': '"ガイア"',
        '"Onrac"': '"オンラク"',
        '"Leifen"': '"ルフェイン人の町"',
        '"Coneria Castle 1F"': '"コーネリア城 1F"',
        '"Elfland Castle"': '"エルフ城"',
        '"Northwest Castle"': '"西の城"',
        '"Castle of Ordeals 1F"': '"試練の城 1F"',
        '"Temple of Fiends"': '"カオスの神殿"',
        '"Earth Cave B1"': '"アースの洞窟 B1F"',
        '"Gurgu Volcano B1"': '"グルグ火山 B1F"',
        '"Ice Cave B1"': '"氷の洞窟 B1F"',
        '"Cardia"': '"ドラゴンの洞窟 (空洞1)"',
        '"Bahamut\'s Room B1"': '"バハムートの部屋 B1F"',
        '"Waterfall"': '"滝の裏の洞窟"',
        '"Dwarf Cave"': '"ドワーフの洞窟"',
        '"Matoya\'s Cave"': '"マトーヤの洞窟"',
        '"Sarda\'s Cave"': '"サーダの洞窟"',
        '"Marsh Cave B1"': '"沼の洞窟 B1F"',
        '"Mirage Tower 1F"': '"ミラージュの塔 1F"',
        '"Coneria Castle 2F"': '"コーネリア城 2F"',
        '"Castle of Ordeal 2F"': '"試練の城 2F"',
        '"Castle of Ordeal 3F"': '"試練の城 3F"',
        '"Marsh Cave B2"': '"沼の洞窟 B2F"',
        '"Marsh Cave B3"': '"沼の洞窟 B3F"',
        '"Earth Cave B2"': '"アースの洞窟 B2F"',
        '"Earth Cave B3"': '"アースの洞窟 B3F"',
        '"Earth Cave B4"': '"アースの洞窟 B4F"',
        '"Earth Cave B5"': '"アースの洞窟 B5F"',
        '"Gurgu Volcano B2"': '"グルグ火山 B2F"',
        '"Gurgu Volcano B3"': '"グルグ火山 B3F"',
        '"Gurgu Volcano B4"': '"グルグ火山 B4F"',
        '"Gurgu Volcano B5"': '"グルグ火山 B5F"',
        '"Ice Cave B2"': '"氷の洞窟 B2F"',
        '"Ice Cave B3"': '"氷の洞窟 B3F"',
        '"Bahamut\'s Room B2"': '"バハムートの部屋 B2F"',
        '"Mirage Tower 2F"': '"ミラージュの塔 2F"',
        '"Mirage Tower 3F"': '"ミラージュの塔 3F"',
        '"Sea Shrine B5"': '"海底神殿 1F"',
        '"Sea Shrine B4"': '"海底神殿 2F"',
        '"Sea Shrine B3"': '"海底神殿 3F"',
        '"Sea Shrine B2"': '"海底神殿 4F"',
        '"Sea Shrine B1"': '"海底神殿 5F"',
        '"Sky Palace 1F"': '"浮遊城 1F"',
        '"Sky Palace 2F"': '"浮遊城 2F"',
        '"Sky Palace 3F"': '"浮遊城 3F"',
        '"Sky Palace 4F"': '"浮遊城 4F"',
        '"Sky Palace 5F"': '"浮遊城 5F"',
        '"Temple of Fiends 1F"': '"過去のカオスの神殿 1F"',
        '"Temple of Fiends 2F"': '"過去のカオスの神殿 2F"',
        '"Temple Fiends 3F"': '"過去のカオスの神殿 3F"',
        '"Temple Fiends-Earth"': '"過去のカオスの神殿 B1F (土)"',
        '"Temple Fiends-Fire"': '"過去のカオスの神殿 B2F (火)"',
        '"Temple Fiends-Water"': '"過去のカオスの神殿 B3F (水)"',
        '"Temple Fiends-Air"': '"過去のカオスの神殿 B4F (風)"',
        '"Temple Fiends-Chaos"': '"過去のカオスの神殿 B5F (カオス)"',
        '"Titan\'s Tunnel"': '"巨人の洞窟"',
    },
    # 地上進入テレポート（全32件）
    'ONTeleport': {
        '"Enter: Cardia - 1"': '"進入: ドラゴンの洞窟 1"',
        '"Enter: Coneria"': '"進入: コーネリア"',
        '"Enter: Provoka"': '"進入: プラボカ"',
        '"Enter: Elfland"': '"進入: エルフの町"',
        '"Enter: Melmond"': '"進入: メルモンド"',
        '"Enter: Crescent Lake"': '"進入: クレセントレイク"',
        '"Enter: Gaia"': '"進入: ガイア"',
        '"Enter: Onrac"': '"進入: オンラク"',
        '"Enter: Leifen"': '"進入: ルフェイン人の町"',
        '"Enter: Coneria Castle"': '"進入: コーネリア城"',
        '"Enter: Elfland Castle"': '"進入: エルフ城"',
        '"Enter: Northwest Castle"': '"進入: 西の城"',
        '"Enter: Castle of Ordeals"': '"進入: 試練の城"',
        '"Enter: Temple of Fiends"': '"進入: カオスの神殿"',
        '"Enter: Earth Cave"': '"進入: アースの洞窟"',
        '"Enter: Gurgu Volcano"': '"進入: グルグ火山"',
        '"Enter: Ice Cave"': '"進入: 氷の洞窟"',
        '"Enter: Cardia - 2"': '"進入: ドラゴンの洞窟 2"',
        '"Enter: Bahamut\'s Room"': '"進入: バハムートの部屋"',
        '"Enter: Waterfall"': '"進入: 滝の裏の洞窟"',
        '"Enter: Dwarf Cave"': '"進入: ドワーフの洞窟"',
        '"Enter: Matoya\'s Cave"': '"進入: マトーヤの洞窟"',
        '"Enter: Sarda\'s Cave"': '"進入: サーダの洞窟"',
        '"Enter: Marsh Cave"': '"進入: 沼の洞窟"',
        '"Enter: Mirage Tower"': '"進入: ミラージュの塔"',
        '"Enter: Titan\'s Tunnel - E"': '"進入: 巨人の洞窟 東"',
        '"Enter: Titan\'s Tunnel - W"': '"進入: 巨人の洞窟 西"',
        '"Enter: Cardia - 3"': '"進入: ドラゴンの洞窟 3"',
        '"Enter: Cardia - 4"': '"進入: ドラゴンの洞窟 4"',
        '"Enter: Cardia - 5"': '"進入: ドラゴンの洞窟 5"',
        '"Enter: Not Used"': '"進入: 未使用"',
    },
    # 地上脱出テレポート（全16件）
    'NOTeleport': {
        '"Exit: Titan E"': '"脱出: 巨人の洞窟 東"',
        '"Exit: Titan W"': '"脱出: 巨人の洞窟 西"',
        '"Exit: Ice Cave"': '"脱出: 氷の洞窟"',
        '"Exit: Castle Ordeals"': '"脱出: 試練の城"',
        '"Exit: Castle Coneria"': '"脱出: コーネリア城"',
        '"Exit: Earth Cave"': '"脱出: アースの洞窟"',
        '"Exit: Gurgu Volcano"': '"脱出: グルグ火山"',
        '"Exit: Sea Shrine"': '"脱出: 海底神殿"',
        '"Exit: Sky Castle"': '"脱出: 浮遊城"',
        '"Exit: Not used"': '"脱出: 未使用"',
    },
    # マップ間テレポート（全64件）
    'NNTeleport': {
        '"Coneria Castle 1"': '"コーネリア城 2Fへ"',
        '"Time Warp"': '"過去のカオスの神殿へ (タイムトリップ)"',
        '"Marsh Cave 1"': '"沼の洞窟 B1F->B2F"',
        '"Marsh Cave 2"': '"沼の洞窟 B2F->B3F"',
        '"Marsh Cave 3"': '"沼の洞窟 B3F->B2F"',
        '"Earth Cave 1"': '"アースの洞窟 B1F->B2F"',
        '"Earth Cave 2"': '"アースの洞窟 B2F->B3F"',
        '"Earth Cave 3"': '"アースの洞窟 B3F->B4F"',
        '"Earth Cave 4"': '"アースの洞窟 B4F->B5F"',
        '"Gurgu 1"': '"グルグ火山 B1F->B2F"',
        '"Gurgu 2"': '"グルグ火山 B2F->B3F"',
        '"Gurgu 3"': '"グルグ火山 B3F->B4F"',
        '"Gurgu 4"': '"グルグ火山 B4F->B5F"',
        '"Gurgu 5"': '"グルグ火山 階段A"',
        '"Gurgu 6"': '"グルグ火山 階段B"',
        '"Ice Cave 1"': '"氷の洞窟 B1F->B2F"',
        '"Ice Cave 2"': '"氷の洞窟 B2F->B3F"',
        '"Ice Cave 3"': '"氷の洞窟 B3F->B1F"',
        '"Ice Cave 4"': '"氷の洞窟 落とし穴A"',
        '"Ice Cave 5"': '"氷の洞窟 落とし穴B"',
        '"Ice Cave 6"': '"氷の洞窟 階段A"',
        '"Ice Cave 7"': '"氷の洞窟 階段B"',
        '"Castle Ordeals 1"': '"試練の城 1F->2F"',
        '"Castle Ordeals 2"': '"試練の城 2F->3F"',
        '"Castle Ordeals 3"': '"試練の城 3F->1F脱出"',
        '"Bahamut\'s Room"': '"バハムートの部屋 B1F->B2F"',
        '"Castle Ordeal 4"': '"試練の城 ワープ01"',
        '"Castle Ordeal 5"': '"試練の城 ワープ02"',
        '"Castle Ordeal 6"': '"試練の城 ワープ03"',
        '"Castle Ordeal 7"': '"試練の城 ワープ04"',
        '"Castle Ordeal 8"': '"試練の城 ワープ05"',
        '"Castle Ordeal 9"': '"試練の城 ワープ06"',
        '"Sea Shrine 1"': '"海底神殿 3F(入口)->4F"',
        '"Sea Shrine 2"': '"海底神殿 4F->5F(人魚)"',
        '"Sea Shrine 3"': '"海底神殿 5F->4F"',
        '"Sea Shrine 4"': '"海底神殿 4F->3F"',
        '"Sea Shrine 5"': '"海底神殿 3F->2F"',
        '"Sea Shrine 6"': '"海底神殿 2F->3F"',
        '"Sea Shrine 7"': '"海底神殿 2F->1F(クラーケン)"',
        '"Sea Shrine 8"': '"海底神殿 階段A"',
        '"Sea Shrine 9"': '"海底神殿 階段B"',
        '"Mirage Tower 1"': '"ミラージュの塔 1F->2F"',
        '"Mirage Tower 2"': '"ミラージュの塔 2F->3F"',
        '"Sky Palace 1"': '"浮遊城 1F->2F"',
        '"Sky Palace 2"': '"浮遊城 2F->3F"',
        '"Sky Palace 3"': '"浮遊城 3F->4F"',
        '"Sky Palace 4"': '"浮遊城 4F->5F(ティアマット)"',
        '"Sky Palace 5"': '"浮遊城 階段"',
        '"ToF 1"': '"過去のカオスの神殿 1F->2F"',
        '"ToF 2"': '"過去のカオスの神殿 2F->3F"',
        '"ToF 3"': '"過去のカオスの神殿 3F->B1F(土)"',
        '"ToF 4"': '"過去のカオスの神殿 B1F->B2F(火)"',
        '"ToF 5"': '"過去のカオスの神殿 B2F->B3F(水)"',
        '"ToF 6"': '"過去のカオスの神殿 B3F->B4F(風)"',
        '"ToF 7"': '"過去のカオスの神殿 B4F->B5F(カオス)"',
        '"ToF 8"': '"過去のカオスの神殿 階段A"',
        '"ToF 9"': '"過去のカオスの神殿 階段B"',
        '"ToF 10"': '"過去のカオスの神殿 階段C"',
        '"Castle Ordeal 10"': '"試練の城 ワープ07"',
        '"Castle Ordeal 11"': '"試練の城 ワープ08"',
        '"Castle Ordeal 12"': '"試練の城 ワープ09"',
        '"Castle Ordeal 13"': '"試練の城 ワープ10"',
        '"Coneria Castle"': '"コーネリア城 1Fへ"',
        '"Rescue Princess"': '"セーラ姫救出ワープ"',
    },
    # 敵AIルーチン名（全44件）
    'AI': {
        '"FrWolf"': '"フロストウルフ"',
        '"Agama"': '"アガマ"',
        '"Medusa"': '"メデューサ"',
        '"Oddeye"': '"オッドアイ"',
        '"Bigeye"': '"ビッグアイ"',
        '"Cerebus"': '"ケルベロス"',
        '"WzOgre"': '"オーガメイジ"',
        '"Sand W"': '"サンドウォーム"',
        '"Eye"': '"アイ"',
        '"Phantom"': '"ファントム"',
        '"Mancat"': '"マンキャット"',
        '"Vampire"': '"バンパイア"',
        '"WzVamp"': '"バンパイアロード"',
        '"R.Goyle"': '"レッドゴイル"',
        '"Frost D"': '"ホワイトドラゴン"',
        '"Red D"': '"レッドドラゴン"',
        '"Perelisk"': '"ピロリスク"',
        '"R. Hydra"': '"ファイアヒドラ"',
        '"Naga"': '"ナーガ"',
        '"GrNaga"': '"グリーンナーガ"',
        '"Chimera"': '"キマイラ"',
        '"Jimera"': '"ジメラ"',
        '"Sorcerer"': '"ソーサラー"',
        '"Gas D"': '"グリーンドラゴン"',
        '"Blue D"': '"ブルードラゴン"',
        '"MudGol"': '"マッドゴーレム"',
        '"RockGol"': '"ロックゴーレム"',
        '"IronGol"': '"アイアンゴーレム"',
        '"Evilman"': '"イビルアイ"',
        '"Mage"': '"メイジ"',
        '"Fighter"': '"ファイター"',
        '"Nitemare"': '"ナイトメア"',
        '"WarMech"': '"デスマシーン"',
        '"Manticor"': '"マンティコア"',
        '"Lich"': '"リッチ"',
        '"Lich 2"': '"リッチ (過去)"',
        '"Kary"': '"マリリス"',
        '"Kary 2"': '"マリリス (過去)"',
        '"Kraken"': '"クラーケン"',
        '"Kraken 2"': '"クラーケン (過去)"',
        '"Tiamat"': '"ティアマット"',
        '"Tiamat 2"': '"ティアマット (過去)"',
        '"Chaos"': '"カオス"',
        '"Astos"': '"アストス"',
    },
    # 武器・魔法グラフィック（全28件）
    'WepMag': {
        '"Sword 1"': '"剣 1"',
        '"Sword 2"': '"剣 2"',
        '"Sword 3"': '"剣 3"',
        '"Sword 4"': '"剣 4"',
        '"Sword 5"': '"剣 5"',
        '"Hammer"': '"ハンマー"',
        '"Knife"': '"ナイフ"',
        '"Axe"': '"斧"',
        '"Staff 1"': '"杖 1"',
        '"Staff 2"': '"杖 2"',
        '"Nunchuck"': '"ヌンチャク"',
        '"Bl Belt Hands"': '"鉄拳"',
        '"Bar of Light"': '"光の柱"',
        '"Bar of Light-2"': '"光の柱 2"',
        '"4 Sparkles"': '"4連スパーク"',
        '"4 Sparkles-2"': '"4連スパーク2"',
        '"Stars"': '"星"',
        '"Stars-2"': '"星 2"',
        '"Energy Beam"': '"ビーム"',
        '"Energy Beam-2"': '"ビーム 2"',
        '"Energy Flare"': '"波動ビーム"',
        '"Energy Flare-2"': '"波動ビーム 2"',
        '"Glowing Ball"': '"光球"',
        '"Glowing Ball-2"': '"光球 2"',
        '"Large Sparkle"': '"大スパーク"',
        '"Large Sparkle-2"': '"大スパーク 2"',
        '"Sparkling Hand"': '"波動掌"',
        '"Sparkling Hand-2"': '"波動掌 2"',
    },
    # ショップ（全70件）
    'Shop': {
        '"Wep-Coneria"': '"武器屋: コーネリア"',
        '"Wep-Provoka"': '"武器屋: プラボカ"',
        '"Wep-Elfland"': '"武器屋: エルフの町"',
        '"Wep-Melmond"': '"武器屋: メルモンド"',
        '"Wep-Crescent Lake"': '"武器屋: クレセントレイク"',
        '"Wep-Gaia"': '"武器屋: ガイア"',
        '"Wep-1"': '"武器屋: 未使用1"',
        '"Wep-2"': '"武器屋: 未使用2"',
        '"Wep-3"': '"武器屋: 未使用3"',
        '"Wep-4"': '"武器屋: 未使用4"',
        '"Arm-Coneria"': '"防具屋: コーネリア"',
        '"Arm-Provoka"': '"防具屋: プラボカ"',
        '"Arm-Elfland"': '"防具屋: エルフの町"',
        '"Arm-Melmond"': '"防具屋: メルモンド"',
        '"Arm-Crescent Lake"': '"防具屋: クレセントレイク"',
        '"Arm-Gaia"': '"防具屋: ガイア"',
        '"Arm-1"': '"防具屋: 未使用1"',
        '"Arm-2"': '"防具屋: 未使用2"',
        '"Arm-3"': '"防具屋: 未使用3"',
        '"Arm-4"': '"防具屋: 未使用4"',
        '"Wht-Coneria"': '"白魔法屋: コーネリア (Lv1)"',
        '"Wht-Provoka"': '"白魔法屋: プラボカ (Lv2)"',
        '"Wht-Elfland"': '"白魔法屋: エルフの町 (Lv3)"',
        '"Wht-Melmond"': '"白魔法屋: メルモンド (Lv5)"',
        '"Wht-Crescent Lake"': '"白魔法屋: クレセントレイク (Lv6)"',
        '"Wht-Elfland 2"': '"白魔法屋: エルフの町 (Lv4)"',
        '"Wht-Gaia"': '"白魔法屋: ガイア (Lv7)"',
        '"Wht-Gaia 2"': '"白魔法屋: ガイア (Lv8)"',
        '"Wht-Onrac"': '"白魔法屋: オンラク (Lv7)"',
        '"Wht-Lefein"': '"白魔法屋: ルフェイン (Lv8)"',
        '"Blk-Coneria"': '"黒魔法屋: コーネリア (Lv1)"',
        '"Blk-Provoka"': '"黒魔法屋: プラボカ (Lv2)"',
        '"Blk-Elfland"': '"黒魔法屋: エルフの町 (Lv3)"',
        '"Blk-Melmond"': '"黒魔法屋: メルモンド (Lv5)"',
        '"Blk-Crescent Lake"': '"黒魔法屋: クレセントレイク (Lv6)"',
        '"Blk-Elfland 2"': '"黒魔法屋: エルフの町 (Lv4)"',
        '"Blk-Gaia"': '"黒魔法屋: ガイア (Lv7)"',
        '"Blk-Gaia 2"': '"黒魔法屋: ガイア (Lv8)"',
        '"Blk-Onrac"': '"黒魔法屋: オンラク (Lv7)"',
        '"Blk-Lefein"': '"黒魔法屋: ルフェイン (Lv8)"',
        '"Cnc-Coneria"': '"教会: コーネリア"',
        '"Cnc-Elfland"': '"教会: エルフの町"',
        '"Cnc-Crescent Lake"': '"教会: クレセントレイク"',
        '"Cnc-Gaia"': '"教会: ガイア"',
        '"Cnc-Onrac"': '"教会: オンラク"',
        '"Cnc-Provoka"': '"教会: プラボカ"',
        '"Cnc-1"': '"教会: 未使用1"',
        '"Cnc-2"': '"教会: 未使用2"',
        '"Cnc-3"': '"教会: 未使用3"',
        '"Cnc-4"': '"教会: 未使用4"',
        '"Inn-Coneria"': '"宿屋: コーネリア"',
        '"Inn-Provoka"': '"宿屋: プラボカ"',
        '"Inn-Elfland"': '"宿屋: エルフの町"',
        '"Inn-Melmond"': '"宿屋: メルモンド"',
        '"Inn-Crescent Lake"': '"宿屋: クレセントレイク"',
        '"Inn-Gaia"': '"宿屋: ガイア"',
        '"Inn-Onrac"': '"宿屋: オンラク"',
        '"Inn-1"': '"宿屋: 未使用1"',
        '"Inn-2"': '"宿屋: 未使用2"',
        '"Inn-3"': '"宿屋: 未使用3"',
        '"Itm-Coneria"': '"道具屋: コーネリア"',
        '"Itm-Provoka"': '"道具屋: プラボカ"',
        '"Itm-Elfland"': '"道具屋: エルフの町"',
        '"Itm-Crescent Lake"': '"道具屋: クレセントレイク"',
        '"Itm-Gaia"': '"道具屋: ガイア"',
        '"Itm-Onrac"': '"道具屋: オンラク"',
        '"Itm-1"': '"道具屋: 未使用1"',
        '"Itm-2"': '"道具屋: 未使用2"',
        '"Itm-3"': '"道具屋: 未使用3"',
        '"Caravan"': '"キャラバン"',
    },
    # 戦闘パターンテーブル（全16件）
    'BattlePatternTable': {
        '"Imp - Wolf - Iguana - Giant"': '"ゴブリン・オオカミ・リザード・ギガース"',
        '"Sahag - Pirate - Shark - BigEye"': '"サハギン・海賊・サメ・ビッグアイ"',
        '"Bone - Creep - Hyena - Ogre"': '"スケルトン・クローラー・ハイエナ・オーガ"',
        '"Asp - Lobster - Bull - Troll"': '"コブラ・シーロブスター・ミノタウロス・トロル"',
        '"Image - Geist - Worm - Eye"': '"レイス・ワイト・サンドウォーム・アイ"',
        '"Medusa - Catman - Pede - Tiger"': '"メデューサ・ウェアタイガー・アンクヘッグ・サーベルタイガー"',
        '"Vamp - Gargoyle - Earth - Dragon 1"': '"バンパイア・ガーゴイル・土エレメント・ドラゴン1"',
        '"Slime - Spider - Manticor - Ankylo"': '"スライム・クモ・マンティコア・アンキロ"',
        '"Mummy - Coctric - Wyvern - Tyro"': '"マミー・コカトリス・ワイバーン・ティラノサウルス"',
        '"Caribe - Gator - Ocho - Hydra"': '"ピラニア・ワニ・オチュー・ヒドラ"',
        '"Sentry - Water - Naga - Chimera"': '"ガーディアン・水エレメント・ナーガ・キマイラ"',
        '"Wizard - Garland - Dragon 2 - Golem"': '"ピスコディーモン・ガーランド・ドラゴン2・ゴーレム"',
        '"Badman - Astos - Madpony - Warmech"': '"ブラックナイト・アストス・ホース・デスマシーン"',
        '"Kary -- Lich"': '"マリリス -- リッチ"',
        '"Kraken -- Tiamat"': '"クラーケン -- ティアマット"',
        '" ---- Chaos ----"': '" ---- カオス ----"',
    },
    # スプライトグラフィック種別（全30件）
    'SpriteGraphic': {
        '"Princess"': '"王女"',
        '"Woman"': '"町人 (女性)"',
        '"Fatty"': '"町人 (太身)"',
        '"Dancer"': '"踊り子"',
        '"Orb"': '"クリスタル"',
        '"Witch"': '"魔女マトーヤ"',
        '"Prince"': '"王子"',
        '"Soldier"': '"兵士"',
        '"Scholar"': '"学者 (ウネ)"',
        '"Mohawk"': '"町人 (モヒカン)"',
        '"Boy"': '"男の子"',
        '"Sage"': '"ルカーンの賢者"',
        '"Dwarf"': '"ドワーフ"',
        '"Mermaid"': '"人魚"',
        '"Lefein"': '"ルフェイン人"',
        '"King"': '"コーネリア王"',
        '"Broom"': '"ほうき"',
        '"Bat"': '"コウモリ"',
        '"Garland"': '"ガーランド"',
        '"Pirate"': '"海賊ビッケ"',
        '"Fairy"': '"妖精"',
        '"Robot"': '"ロボット"',
        '"Dragon"': '"竜"',
        '"Bahamut"': '"竜王バハムート"',
        '"Female Elf"': '"エルフの女性"',
        '"Elf"': '"エルフの男性"',
        '"Elf Prince"': '"エルフの王子"',
        '"Plate"': '"石板"',
        '"Titan"': '"巨人"',
        '"Vampire"': '"バンパイア"',
    },
    # 配置スプライト（主要NPC・オブジェクト）
    'Sprite': {
        '"No Sprite"': '"スプライトなし"',
        '"King of Coneria"': '"コーネリア王"',
        '"Garland"': '"ガーランド"',
        '"Kidnapped Princess"': '"セーラ姫 (誘拐)"',
        '"Bikke the Pirate"': '"海賊ビッケ"',
        '"Elf Prince\'s Doctor"': '"エルフの侍医"',
        '"Elf Prince"': '"エルフの王子"',
        '"Astos"': '"アストス"',
        '"Nerrick"': '"ネリク (運河)"',
        '"Dwarven Blacksmith"': '"鍛冶屋スミス"',
        '"Matoya"': '"マトーヤ"',
        '"Dr. Unne"': '"学者ウネ"',
        '"Vampire"': '"バンパイア"',
        '"Sarda"': '"賢者サーダ"',
        '"Bahamut"': '"竜王バハムート"',
        '"Unknown"': '"妖精 (未使用)"',
        '"Submarine Engineer"': '"潜水艇の技師"',
        '"Waterfall Robot"': '"滝のロボット"',
        '"Rescued Princess"': '"セーラ姫 (救出後)"',
        '"Fairy in Bottle"': '"ビンの妖精"',
        '"Titan"': '"巨人タイタン"',
        '"Canoe Sage"': '"カヌーの賢者"',
        '"Earth Plate"': '"つちのいた (アース)"',
        '"Fiends\' Plate"': '"石板 (カオスの神殿)"',
        '"Garland 1"': '"過去のガーランド 1"',
        '"Garland 2"': '"過去のガーランド 2"',
        '"Garland 3"': '"過去のガーランド 3"',
        '"ORB of the Earth"': '"土のクリスタル"',
        '"ORB of Fire"': '"火のクリスタル"',
        '"ORB of Water"': '"水のクリスタル"',
        '"ORB of Wind"': '"風のクリスタル"',
        '"Castle of Ordeals 1F"': '"試練の城 1F"',
        '"Black ORB!"': '"黒のクリスタル!"',
        '"Bat"': '"コウモリ"',
    },
    # 宝箱（基本）
    'TreasureChest': {
        '"Unused"': '"未使用"',
    },
    # RAM定義（乗り物・重要アイテム・クリスタル・消耗品・フラグ）
    'RamValues': {
        # 乗り物・マップフラグ
        '"DisplayName": "Ship"': '"DisplayName": "船"',
        '"DisplayName": "Airship"': '"DisplayName": "飛空艇"',
        '"DisplayName": "Bridge"': '"DisplayName": "橋"',
        '"DisplayName": "Canal"': '"DisplayName": "運河"',
        '"DisplayName": "Has Canoe"': '"DisplayName": "カヌー所持"',
        # 重要アイテム（イベントアイテム）
        '"DisplayName": "Lute"': '"DisplayName": "リュート"',
        '"DisplayName": "item_crown"': '"DisplayName": "クラウン"',
        '"DisplayName": "item_crystal"': '"DisplayName": "すいしょうのめ"',
        '"DisplayName": "Herb"': '"DisplayName": "めざめのくすり"',
        '"DisplayName": "item_mystickey"': '"DisplayName": "しんぴのかぎ"',
        '"DisplayName": "item_tnt"': '"DisplayName": "ニトロのかみなり"',
        '"DisplayName": "item_adamant"': '"DisplayName": "アダマンタイト"',
        '"DisplayName": "item_slab"': '"DisplayName": "ロゼッタいし"',
        '"DisplayName": "item_ruby"': '"DisplayName": "スタールビー"',
        '"DisplayName": "item_rod"': '"DisplayName": "つちのつえ"',
        '"DisplayName": "item_floater"': '"DisplayName": "ふゆうせき"',
        '"DisplayName": "item_chime"': '"DisplayName": "チャイム"',
        '"DisplayName": "item_tail"': '"DisplayName": "ねずみのしっぽ"',
        '"DisplayName": "item_cube"': '"DisplayName": "ワープキューブ"',
        '"DisplayName": "item_bottle"': '"DisplayName": "ようせいのビン"',
        '"DisplayName": "item_oxyale"': '"DisplayName": "くうきのみず"',
        '"DisplayName": "Canoe (item)"': '"DisplayName": "カヌー (アイテム)"',
        # クリスタル（オーブ）
        '"DisplayName": "orb_fire"': '"DisplayName": "火のクリスタル"',
        '"DisplayName": "orb_water"': '"DisplayName": "水のクリスタル"',
        '"DisplayName": "orb_air"': '"DisplayName": "風のクリスタル"',
        '"DisplayName": "orb_earth"': '"DisplayName": "土のクリスタル"',
        # 消耗品アイテム（FC版基準）
        '"DisplayName": "Tent"': '"DisplayName": "ねぶくろ"',
        '"DisplayName": "Cabin"': '"DisplayName": "テント"',
        '"DisplayName": "House"': '"DisplayName": "コテージ"',
        '"DisplayName": "Heal Potion"': '"DisplayName": "ポーション"',
        '"DisplayName": "Pure Potion"': '"DisplayName": "どくけし"',
        '"DisplayName": "Soft Potion"': '"DisplayName": "きんのはり"',
        # システム・アドレス系表示
        '"DisplayName": "unsram"': '"DisplayName": "ワークRAM"',
        '"DisplayName": "bridgescene"': '"DisplayName": "橋OPデモ"',
        '"DisplayName": "gold"': '"DisplayName": "所持金"',
        '"DisplayName": "items"': '"DisplayName": "アイテム領域"',
        '"DisplayName": "item_orb_start"': '"DisplayName": "クリスタル開始アドレス"',
        '"DisplayName": "item_orb_last"': '"DisplayName": "クリスタル終了アドレス"',
        '"DisplayName": "item_qty_start"': '"DisplayName": "消費アイテム個数開始アドレス"',
        '"DisplayName": "item_qty_last"': '"DisplayName": "消費アイテム個数終了アドレス"',
        '"DisplayName": "item_last"': '"DisplayName": "有効アイテム末尾アドレス"',
        '"DisplayName": "item_stop"': '"DisplayName": "アイテム停止アドレス"',
    },
    'Battle': {},
    'DialogueText': {},
}

# --- 街・ダンジョンごとのスプライト連番自動生成 ---
sprite_groups = {
    'Coneria Castle 1F': ('コーネリア城 1F', 9),
    'Coneria Castle 2F': ('コーネリア城 2F', 2),
    'Coneria': ('コーネリア', 8),
    'Sky Warrior Bat': ('天空人のコウモリ', 5),
    'Provoka': ('プラボカ', 5),
    'Castle of Elf': ('エルフ城', 6),
    'Elfland': ('エルフの町', 8),
    'Dwarf Cave': ('ドワーフの洞窟', 11),
    "Matoya's Broom": ('マトーヤのホウキ', 4),
    'Melmond': ('メルモンド', 13),
    'Crescent Lake': ('クレセントレイク', 13),
    'Cardian Dragon': ('ドラゴンの洞窟の竜', 12),
    'Onrac': ('オンラク', 14),
    'Mermaid': ('人魚', 10),
    'Gaia': ('ガイア', 13),
    'Lefein': ('ルフェイン人の町', 14),
    'Robot': ('ロボット', 4),
}
for eng_pfx, (jp_pfx, max_idx) in sprite_groups.items():
    sep = ' ' if eng_pfx == 'Robot' else ' - '
    for idx in range(1, max_idx + 1):
        SECTION_REPLACEMENTS['Sprite'][f'"{eng_pfx}{sep}{idx}"'] = f'"{jp_pfx} {idx}"'

# --- 宝箱連番自動生成（全256件） ---
chest_groups = {
    'Coneria': ('コーネリア城', 6),
    'Temple of Fiends': ('カオスの神殿', 6),
    'Elfland': ('エルフ城', 4),
    'NorthWest Castle': ('西の城', 3),
    'Marsh Cave': ('沼の洞窟', 13),
    'Dwarf Cave': ('ドワーフの洞窟', 10),
    "Matoya's Cave": ('マトーヤの洞窟', 3),
    'Earth Cave': ('アースの洞窟', 24),
    "Titan's Tunnel": ('巨人の洞窟', 4),
    'Gurgu Volcano': ('グルグ火山', 33),
    'Ice Cave': ('氷の洞窟', 16),
    'Castle of Ordeal': ('試練の城', 9),
    'Cardia': ('ドラゴンの洞窟', 13),
    'Not Used': ('未使用', 13),
    'Sea Shrine': ('海底神殿', 32),
    'Waterfall': ('滝の裏の洞窟', 6),
    'Mirage Tower': ('ミラージュの塔', 18),
    'Sky Palace': ('浮遊城', 34),
    'ToF Revisited': ('過去のカオスの神殿', 7),
}
for eng_pfx, (jp_pfx, max_idx) in chest_groups.items():
    for idx in range(1, max_idx + 1):
        SECTION_REPLACEMENTS['TreasureChest'][f'"{eng_pfx} {idx}"'] = f'"{jp_pfx} {idx}"'

# --- 会話テキスト連番自動生成（Text: 00 - Text: FF） ---
for i in range(256):
    hex_str = f'{i:02X}'
    SECTION_REPLACEMENTS['DialogueText'][f'"Text: {hex_str}"'] = f'"テキスト: {hex_str}"'

# --- 戦闘グループ連番自動生成（Battle: 00 - Battle: 7F） ---
for i in range(128):
    hex_str = f'{i:02X}'
    SECTION_REPLACEMENTS['Battle'][f'"Battle: {hex_str}"'] = f'"戦闘グループ: {hex_str}"'


def process_file(input_path, output_path=None):
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f'エラー: 入力ファイルが見つかりません: {input_path}')
        sys.exit(1)

    # 上書き保存（出力先未指定）の場合は事前にバックアップを作成
    if output_path is None:
        target_path = input_path
        bak_path = f'{input_path}.bak'
        if os.path.exists(bak_path):
            i = 1
            while os.path.exists(f'{input_path}({i}).bak'):
                i += 1
            bak_path = f'{input_path}({i}).bak'

        try:
            shutil.copy2(input_path, bak_path)
            print(f'バックアップを作成しました: {bak_path}')
        except IOError as e:
            print(f'エラー: バックアップの作成に失敗しました: {e}')
            sys.exit(1)
    else:
        target_path = output_path

    new_lines = []
    count = 0
    current_section = None
    current_section_indent = 0

    # セクション開始検知パターン: "キー名": [ または "キー名": {
    section_start_pattern = re.compile(r'^\s*"([A-Za-z0-9_]+)":\s*[\[\{]')
    # セクション終了検知パターン
    section_end_pattern = re.compile(r'^\s*[\]\}],?')

    for line in lines:
        stripped_line = line.rstrip('\r\n')
        indent_len = len(stripped_line) - len(stripped_line.lstrip())
        indent = stripped_line[:indent_len]
        content = stripped_line[indent_len:]

        # セクション開始の検知
        match_start = section_start_pattern.match(line)
        if match_start:
            current_section = match_start.group(1)
            current_section_indent = indent_len

        has_comma = content.endswith(',')
        core = content[:-1].strip() if has_comma else content.strip()

        replaced = False
        # 現在のセクション専用の置換辞書があればそれを適用
        if current_section and current_section in SECTION_REPLACEMENTS:
            repl_dict = SECTION_REPLACEMENTS[current_section]
            if core in repl_dict:
                new_core = repl_dict[core]
                new_content = new_core + (',' if has_comma else '')
                new_lines.append(indent + new_content + '\n')
                count += 1
                replaced = True

        if not replaced:
            new_lines.append(line)

        # セクション終了の検知（セクション開始と同じインデントの閉じ括弧が来たらリセット）
        if current_section and indent_len == current_section_indent and section_end_pattern.match(content):
            if content.strip() in [']', '],', '}', '},']:
                current_section = None

    try:
        with open(target_path, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
    except IOError as e:
        print(f'エラー: 出力ファイルの書き込みに失敗しました: {e}')
        sys.exit(1)

    print(f'完了: {count} 箇所を置換しました。 -> {target_path}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='ff1dファイルの定義ラベルをセクションごとに安全に置換します。'
    )
    parser.add_argument('input_file', help='変換元のff1dファイルパス')
    parser.add_argument(
        'output_file',
        nargs='?',
        default=None,
        help='変換後の出力先ファイルパス（省略時はバックアップを作成して上書き）',
    )

    args = parser.parse_args()
    process_file(args.input_file, args.output_file)
