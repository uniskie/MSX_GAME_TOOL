# ファイナルファンタジーⅠ セーブデータエディタ（FC版/MSX2版 両対応）

オンラインから実行：  
<https://uniskie.github.io/MSX_GAME_TOOL/FF1SaveEditor/ff1_editor.html>

- **MSX2版** : ユーザーディスクイメージ（`*.DSK`）をエディタウィンドウにドロップしてください。
- **ファミコン版（FC版）**  : `*.SAV`ファイルをエディタウィンドウにドロップしてください。

  - ※注）  
   **RetroFreak**のSAVファイルなどの、**特殊なヘッダ**がついたセーブデータの場合は、**ヘッダを除去したもの**をドロップしてください。
  
    （気が向いたらRetroFreak用セーブデータの読み書き対応をするかもしれません。） 

編集が終わったら**SAVを保存**ボタンをおすとダウンロードフォルダに編集後のセーブデータが保存されます。

![screenshot](screenshot.png)

## ファイル構成

- [ff1_editor.html](ff1_editor.html)
- [ff1_editor_world_map.js](ff1_editor_world_map.js)
- [ff1_editor_world_sprites.png](ff1_editor_world_sprites.png)

補足：

- ※ [ff1_editor_world_map.js](ff1_editor_world_map.js) はローカル環境用の画像データです。  
  ローカル環境ではjsコードから画像のピクセル情報を参照できない為、base64エンコードで用意した画像ファイルです。  
  [ff1_editor_world_map.bmp](ff1_editor_world_map.bmp) を [bmp16_to_js.py](bmp16_to_js.py) で変換しています。

- オンライン環境（サーバ経由）であれば、
  [ff1_editor_world_map.js](ff1_editor_world_map.js) の代わりに [ff1_editor_world_map.png](ff1_editor_world_map.png) があれば問題ありません。

- ジョブ画像
  [ff1_editor_class_icon.png](ff1_editor_class_icon.png) 相当の画像を自分で用意して、`ff1_editor_class_chr.png` として配置しておくと、ジョブ画像として使用されます。  
  デフォルトのアイコンは [ff1_editor_class_icon.png](ff1_editor_class_icon.png) を [class_icon_to_js.py](class_icon_to_js.py) で jsソースに変換して `ff1_editor.html` に組み込んでいます。

## 簡易ガイド

### 名前入力

ゲーム中のフォントで使用できる文字を受け付けます。

カタカナも使えますが、カタカナの小さい「ゥ」はゲーム中にフォントが存在しないので「ウ」に強制変更されます。

アルファベットは`L`、`E`、`H`、`P`のみ受け付けます。

### [地図]

![map_screenshot](map_screenshot.png)

おまけ的な機能です。

初期状態では簡易的なマップ表示ですが、ROMを読み込ませると正確なマップが表示できます。

簡易表示の場合

- [ff1_editor_world_map.js](ff1_editor_world_map.js) または、 [ff1_editor_world_map.png](ff1_editor_world_map.png)
- [ff1_editor_world_sprites.png](ff1_editor_world_sprites.png)

を使用して表示します。

### パラメータ自動計算

レベル変更時、成長テーブルに従ってパラメータを自動計算します。

テーブルはLV50までなので、上限制限を無効にしても自動計算が有効な時はLV上限が50までとなります。

### FC版ROMイメージ or MSX2版ディスクイメージ をドロップすると？

ちょっとした機能が強化されます。

ゲーム中の雰囲気を味わいたい人向けの機能です。

- グラフィックがROM/DSKから読み込んだゲーム中グラフィックに変わります。
- 成長テーブルやアイテムテーブルがROM/DSKから読み込んだものに変わります。
- [地図]ボタンで表示されるワールドマップROM/DSKから読み込んだものに変わり、
  拡大ビューがブロック塗りつぶしタイルではなくゲーム中のような表示になります。

- FC版ROMはUS版/JP版両対応（自動判定）です。

## 参考資料

### 参考：FC版 ファイナルファンタジー 解析資料

- Data Crystal - Final Fantasy  
  <https://datacrystal.tcrf.net/wiki/Final_Fantasy>
- FFHacksterEX  
  <https://ffhacksterex.digitaldreamers.org/>  
  <https://github.com/ffhacksterex/FFHacksterEx/tree/v0.9.8.2-beta>
- HakkinFF1  
  <https://hakkinff1.digitaldreamers.org/index.html>

### 参考：MSX2版ファイナルファンタジー 解析資料

- Final Fantasy MSX Performance Patch  
  <https://github.com/abekermsx/Final-Fantasy-MSX-Performance-Patch>
- Final Fantasy MSX2 Gfx De-Compressor  
  <https://github.com/romh-acking/final-fantasy-msx2-de-compressor>
- Final Fantasy MSX2 SayDos tool  
  <https://github.com/romh-acking/final-fantasy-msx2-say-dos-tool/tree/master>

## 更新履歴

### ff1_editor.html

- 2026/11/17  
  FC版のカヌー所持フラグを設定し忘れていたので修正。  
  （MSX2版と違い、FC版はカヌーアイテムフラグと所持フラグが別になっている）

- 2026/11/14  
  MSX2版セーブデータ保存時、装備画面での再計算時に参照される素パラメータ（`+0x28`: 力/2、`+0x29`: 素の命中率、`+0x2A`: 素の回避率）を同期して書き込むように修正。
- パラメータ自動計算時のジョブ別命中率計算（初期値およびレベルアップごとの成長値）を実機仕様に準拠した式へ修正。

---

# MSX2版ファイナルファンタジー推奨パッチ

## MSX2版ファイナルファンタジー パフォーマンス改善パッチ

[Final Fantasy MSX Performance Patch](https://github.com/abekermsx/Final-Fantasy-MSX-Performance-Patch)

フレームレート制限の解除と速度最適化により、移動が快適になるパッチです。  

MSX2/2+でも大きな効果がありますが、MSX turboRではさらに快適になります。
場所によっては速すぎて困るケースも？

メッセージの表示速度まで高速になるので、会話ウィンドウ開閉時の音に違和感は出たり、戦闘のメッセージ速度が速くなりすぎたりはしますが、基本的に全体が快適になります。

MSX2版はVDPの処理がボトルネックなので、もともと処理落ちするところはやっぱり処理落ちします。（無改造よりマシですが）

---

## MSX2版ファイナルファンタジー向け自作パッチ

作成したパッチを合成した各種 ips ファイルです。お好みの物を選んで使用してみてください。

| パッチファイル（ipsファイル）                              | 内容                                                   |
| :--------------------------------------------------------- | :----------------------------------------------------- |
| [FF1-1-BGM_Fix.ips](FF1-1-BGM_Fix.ips)                     | BGM割り当て修正                                        |
| [FF1-1-BugFix.ips](FF1-1-BugFix.ips)                       | 戦闘&マップバグ修正                                    |
| [FF1-1-BugFix_at.ips](FF1-1-BugFix_at.ips)                 | 戦闘&マップバグ修正 + 自動ターゲット                   |
| [FF1-1-BGM_and_BugFix.ips](FF1-1-BGM_and_BugFix.ips)       | BGM割り当て修正 + 戦闘&マップバグ修正                  |
| [FF1-1-BGM_and_BugFix_at.ips](FF1-1-BGM_and_BugFix_at.ips) | BGM割り当て修正 + 戦闘&マップバグ修正 + 自動ターゲット |

[WinIPS](https://smblabo.web.fc2.com/) や [ips_manager.py](ips_manager.py) を使用してパッチを当ててください。

### MSX2版ファイナルファンタジー BGM割り当て修正パッチ

[FF1-1-BGM_Fix.ips](FF1-1-BGM_Fix.ips)

MSX2版ファイナルファンタジーは
ダンジョンのBGMがFC版と異なる曲が鳴る場所がいくつかあります。

FC版を遊んだ人は、それなりに違和感を感じると思うので、
FC版準拠のBGM割り当てに修正するパッチを作りました。

| マップ         | MSX2版      | FC版        |
| :------------- | :---------- | :---------- |
| カオスの神殿   | KAITEI.BGM  | KAOSS.BGM   |
| 沼の洞窟       | MATOOYA.BGM | RANCHON.BGM |
| ミラージュの塔 | GURUGU.BGM  | RANCHON.BGM |
| 海底神殿       | KAITEI.BGM  | KAOSS.BGM   |
| ラスダン       | KAOSS.BGM   | KAITEI.BGM  |
| 巨人の洞窟     | KAOSS.BGM   | GURUGU.BGM  |

解析の詳細を知りたい物好きは [doc/ff1_msx_bgm_memo.md](doc/ff1_msx_bgm_memo.md) をどうぞ。

---

### MSX2版ファイナルファンタジー バグ修正パッチ

[FF1_MSX_BugFix.py](FF1_MSX_BugFix.py)

※ 実行はpython3.14.6推奨。

```text
py FF1_MSX_BugFix.py 元DSKパス パッチ後DSKパス
```

※ Performance Patch と併用する場合の注意：  
Performance Patch も起動時の判定（ブートブロック `0x8019`）を、ログインベクタで有効な論理ドライブが1台かを見る判定へ置き換えています。本パッチのフリーエリア判定は同じ場所を置き換えるため、併用する場合は Performance Patch を先に当ててから本パッチを実行してください。Performance Patch の IPS を後から当てると、元のバイトを確認せずに上書きされるため、フリーエリア判定が消えて論理ドライブ数判定に戻ります。（つまり、フリーエリアが十分な通常環境でもCTRLを押しながら起動する以前の動作に戻ります。）

**[FC版 FF1J_BugFixes](doc/FF1J_FC_Bugfixes_jp.md)**相当のパッチを作成。

此方はデバッグ検証のためにチェックや検査をしながらパッチを当てるために作ったものなので、ipsファイルを利用してもパッチは当てられます。

> [!NOTE]
> FC版 FF1J_BugFixes -> <https://www.romhacking.net/hacks/5597/>  
> (アクセスできない時はFireFoxの組み込みVPNを使うといけたりします。)

MSX2版では既に製品版で対応済みのバグがいくつかあるのと、動作が変更になっている部分もあるので、出来るだけ FC版 FF1J_BugFixes に近い動作になるようなパッチとしてみました。

### MSX2版とFC版の主な仕様・バグ状況の違い

移植元であるFC版の既知バグのうち、MSX2版で既に解消されている項目および仕様差の比較です。

| 項目                   | FC版                                                              | MSX2版                                                                                       | 本パッチでの対応                             |
| :--------------------- | :---------------------------------------------------------------- | :------------------------------------------------------------------------------------------- | :------------------------------------------- |
| プロテス（敵使用時）   | 敵プロテス時にROMの初期値を参照し、効果が正しく機能しない         | RAMの敵バッファから正しく参照しており、防御力が正常に上昇                                    | 修正不要（元から解消済）                     |
| 追加効果（ミス時）     | 物理攻撃が0ヒット（ミス）でも状態異常などの追加効果が発生する     | ヒット数0判定が実装されており、0ヒット時は追加効果不発                                       | 修正不要（元から解消済）                     |
| カヌーのアイテム表示   | カヌー入手後も重要アイテム一覧にカヌーが表示されない              | フラグ管理が一元化されており、アイテム一覧に正常表示                                         | 修正不要（元から解消済）                     |
| 宿・テントのMPセーブ   | セーブ処理の後にMP回復が行われるため、回復分がセーブされない      | セーブ前にMP全回復処理が完了しており、回復状態でセーブされる（コテージの文言のみFC版のまま） | 処理は修正不要（コテージ文言のみパッチ対応） |
| NPC初期配置ミス        | 城の女性NPCが室内フラグ誤りで非表示、滝の洞窟のコウモリが壁内埋没 | 城の女性NPCは常時正常表示、滝の洞窟にはコウモリ未配置（ロボットのみ）                        | 修正不要（元から解消済）                     |
| NPCの台詞変化条件      | オンラク老人が土オーブ参照、クレセント湖賢者の全点灯判定に不備    | オンラク老人は水オーブ参照、賢者は4オーブ全点灯判定が実装済                                  | 修正不要（元から解消済）                     |
| 4大祭壇の調査判定      | 判定処理の誤りにより、火・風の祭壇を調べてもメッセージが出ない    | 調査不可タイプのみ除外する処理に修正済で、4祭壇すべて調査可能                                | 修正不要（元から解消済）                     |
| 敵パレットの不整合     | 3種類目の敵グループのカラーパレットが正しく反映されない           | MSX2（V9938）のグラフィック仕様により、パレット不整合は発生しない                            | 修正不要（ハード仕様差）                     |
| キャラバン着陸         | 砂漠のオアシス（キャラバン）に飛空艇が着陸できる                  | 同様にオアシスに着陸可能（進行停止等の実害なし）                                             | 仕様として維持（対象外）                     |
| アイテム・魔法のID管理 | 武器・防具・各Lv魔法が独立したID体系で管理される                  | 全アイテム（1〜107）および魔法（0xB0〜0xEF）が一元化通しIDで管理                             | 仕様差（パッチ動作に反映）                   |
| 数値エンディアン       | 所持金・経験値がリトルエンディアン                                | 所持金・経験値がビッグエンディアン（HPは両機種リトルエンディアン）                           | 仕様差（パッチ動作に反映）                   |
| 運河開通フラグ         | 封鎖フラグ（封鎖中が1、開通時に0クリア）                          | 開通フラグ（未開通が0、開通時に1セット）                                                     | 仕様差（論理反転）                           |

### 修正・調整項目一覧

| 項目                           | 内容                                                                                             |
| :----------------------------- | :----------------------------------------------------------------------------------------------- |
| 行動順の偏り改善               | シャッフル回数を増やし（17回→64回）、初期配置による敵先制の偏りを緩和                           |
| 敵全体魔法の対象修正           | 敵の味方全体魔法（ケアルラ等）が詠唱者自身にも適用されるように修正                               |
| 戦闘後ソート修正               | 毒状態のキャラクターが戦闘後に隊列の末尾へ送られないように修正                                   |
| 武器特効・弱点判定             | 武器の属性・特効判定ルーチンの不具合を解消し、特効効果を正常化                                   |
| サイレス時のアイテム使用       | 沈黙状態でもアイテム（ポーションや装備品等）が使用できるように修正                               |
| 敵耐性・命中率保存             | デスペルによる敵耐性解除およびスロウ等の命中率低下が敵バッファへ保存されるように修正             |
| 敵の睡眠解除判定               | 最大HP依存（80以上は毎ターン確実に目覚める）を排し、固定確率（約10%）で目覚める判定に修正        |
| 睡眠・麻痺時の回避率           | 防御側の回避率を0にし、攻撃力1.25倍の命中判定が機能するように修正                                |
| ヒーラ効果値                   | 基礎効果値を適正値（48→24）に修正                                                               |
| シェイラ効果ルーチン           | 敵全体の回避率を低下させるルーチンに修正                                                         |
| ストライ・セーバー             | ストライの効果を攻撃力UPのみに修正し、味方対象時も攻撃力・命中率が反映されるように修正           |
| 魔法防御の成長値               | ジョブID混入による過剰加算バグを解消し、ジョブごとの魔法防御成長率を適正化                       |
| 複数レベルアップ対応           | 累積経験値に応じて1回の戦闘で連続してレベルアップするように修正                                  |
| 知性の魔法威力反映             | 知性ステータスが攻撃・ディア系・回復魔法の基礎威力に反映されるように修正                         |
| 毒ダメージ・敵リジェネ         | プレイヤー毒ダメージを2に正常化（最低1残る仕様は維持）し、再生持ち敵のターン回復処理を追加       |
| モンクの素手・無防具仕様       | 素手時の攻撃力（Lv×2）・ヒット数2倍・クリティカル（Lv×2）、無防具防御力（Lv）を実装            |
| 逃走判定                       | 逃走を選択したキャラクター自身のレベルと運で逃走判定を行うように修正                             |
| ガイアの妖精の泉               | 泉南側の水際（X=45〜50, Y=19）を調べた際にメッセージが出るようマップタイル（0x3B）を復元         |
| コテージのメッセージ           | MP回復後にセーブ確認を行うMSX2版の実動作に合わせ、表示文言を実態に沿う内容へ修正                 |
| オートターゲット（オプション） | `--auto-target` 指定時、味方の攻撃・単体魔法で対象が死亡している場合に生存敵を自動選択           |
| 起動時フリーエリア判定         | 起動時の CTRL キー判定を、フリーエリアの上限 HIMEM (`0xFC4A`) が `0xDE86` 以上かを見る判定へ置換 |

過去にその辺の検証をされた方もおられるとは思うので、詳しい情報があったら教えて頂けると嬉しいです。

解析の詳細を知りたい物好きは [doc/FF1_MSX_BugFix.md](doc/FF1_MSX_BugFix.md) をどうぞ。

### パッチ更新履歴

- 2026/11/19 (`FF1_MSX_BugFix.py`)  
  起動時の CTRL キー判定をフリーエリア判定へ置換するパッチを追加。フリーエリアの上限 HIMEM (`0xFC4A`) が `0xDE86` 以上かを確認し、不足時は元のメッセージを表示して停止する（ブートブロック）。

- 2026/11/15 (`FF1_MSX_BugFix.py` / バグ修正IPSパッチ)  
  コテージ使用時のメッセージがFC版仕様のまま（「ＨＰかいふく！セーブしてまほうかいふくもする？」）となっていたため、MP回復後にセーブ確認を行うMSX2版の実動作に合わせて「ＨＰとまほうをかいふくしました！セーブもする？」へ変更（`MENU.COM` / `MENU.MSG`）。

### おまけ：openMSX用 バトルOSDスクリプト

[_ff1_battle_overlay.tcl](_ff1_battle_overlay.tcl)  
デバッグ用に作成した戦闘パラメータリアルタイム表示OSDスクリプト

#### 使用方法

ユーザーフォルダ（Windowsであればマイドキュメント/openMSX）の
`share/scripts` に `_ff1_battle_overlay.tcl` 配置 して、openMSXを起動。

`F10`などで出るtcl コンソールから制御します。

頭に`_`(アンダースコア)がついたファイルは自動で読み込まれないので、まず読み込ませます。

````tcl
source $::env(OPENMSX_USER_DATA)/scripts/_ff1_battle_overlay.tcl
````

読み込むとコマンドが使えるようになるので、

- 表示 `ff1_battle_overlay on`
- 消去 `ff1_battle_overlay off`
- 表示切替 `ff1_battle_overlay toggle`

で制御します。

実行中にスクリプトを弄って再読み込みさせたい場合は、再度

````tcl
source $::env(OPENMSX_USER_DATA)/scripts/_ff1_battle_overlay.tcl
````

を実行してください。  
再読み込みされます。

※ 再読み込みをしてもグローバルな変数などは残ったままなので注意

---

# MSX2版ファイナルファンタジー用ツール

## FFSayDosファイルマネージャ

`FFSayDosTool.py`はMSX2版FFゲームディスクに収められているファイルの取り出し＆格納ツールです。

MSX2版ファイナルファンタジーはSayDosというファイル管理システムでのファイル操作と、戦闘用敵キャラクタの直接セクタアクセスを行っています。

ゲーム中ではファイルIDに対しての開始・終了セクタリストをメモリにキャッシュしていて、それを参照してセクタアクセスしているようです。

敵キャラグラフィックに関してはファイルIDで管理できる数を超えてしまうため、BATTLE.COM内に独自に敵キャラIDに対応するセクタリストを持っているようです。

- [FFSayDosTool.py](FFSayDosTool.py)
- [doc/FFSayDosTool_specification.md](doc/FFSayDosTool_specification.md)

## 画像圧縮展開ツール

[FFPicTool.py](FFPicTool.py) は、MSX2版FFのPICファイルを展開・圧縮するツールです。

SayDosToolで取り出したファイルの中にあるPICファイルはRLE圧縮画像ファイルです。  
そのPICファイルを解凍したり圧縮したりするためのツールです。

- [FFPicTool.py](FFPicTool.py)
- [doc/FFPicTool_specification.md](doc/FFPicTool_specification.md)

## スプライトプレビューツール

[FFSprPreview.html](FFSprPreview.html) はMSX2版ファイナルファンタジーのスプライトデータを表示閲覧するお遊び＆確認用ツールです。  
画像書き出しにも対応しています。

SayDosToolで取り出したファイルの中にあるSPRファイルはスプライトデータです。

また、BDATA.TBLの末尾にもSPRファイル相当のデータが埋め込まれています。

- [FFSprPreview.html](FFSprPreview.html)
- オンラインから実行 <https://uniskie.github.io/MSX_GAME_TOOL/FF1SaveEditor/FFSprPreview.html>

`*.SPR` か `BDATA.TBL` かでパレットを自動的に切り替えます。

## メッセージ抽出ツール

[ff1_msg_list.py](ff1_msg_list.py) は、
DSKやMESSAVE.VEC+MESSAGE.MSGから会話メッセージの一覧を出力するお遊び&確認用ツールです。

- [ff1_msg_list.py](ff1_msg_list.py)

```text
usage: ff1_msg_list.py [-h] [-o OUTPUT] [-f {text,tsv,json}] [--oneline] [--raw-ctrl] [--base-addr BASE_ADDR]
                       [--vec-offset VEC_OFFSET] [--msg-offset MSG_OFFSET] [--msg-size MSG_SIZE] [--no-vec]
                       inputs [inputs ...]
```

詳細は`-h` オプションのヘルプを参照ください。

---

### IPSパッチツール

[ips_manager.py](ips_manager.py) は
ROMに複数のパッチをまとめて当てたり、パッチを合成したりできます。

複数のIPSを順番に合成する場合、
重複時は警告+上書き［後行優先］となっています。

- [ips_manager.py](ips_manager.py)

```text
usage: ips_manager.py [-h] -o OUTPUT [-t TARGET] [--on-conflict {overwrite,keep,abort}] [--no-warn] [--strict-same]
                      patches [patches ...]

positional arguments:
  patches               適用・合成するIPSファイル（指定順に処理）

options:
  -h, --help            show this help message and exit
  -o, --output OUTPUT   出力ファイルパス
  -t, --target TARGET   指定時はベースファイルに直接適用して出力（未指定時はIPSとして合成出力）
  --on-conflict {overwrite,keep,abort}
                        重複時の動作: overwrite(重複時上書き: 後行優先), keep(重複時無視: 先行優先), abort(エラー中断)
  --no-warn             重複時の警告メッセージを表示しない
  --strict-same         同じバイト値の上書きも重複として扱う
````

詳細は `-h` オプションのヘルプを参照ください。

---

# Binary Editor Bz - MSX Custom 向け エンコード定義ファイル

**Binary Editor Bz - MSX Custom**  
<https://github.com/uniskie/MSX_MISC_TOOLS/tree/main/BinaryEditorBz_for_MSX>

「ツール」→「カスタムエンコードの編集」でフォルダが開くので、
そこへ

[for_BzEditor_MSX_Custom/](for_BzEditor_MSX_Custom/) の中にあるファイル

- FF1.def
- FF1_oped_FC.def
- FF1_oped_MSX.def

をコピー。

---

# FC版ファイナルファンタジー推奨パッチ

詳細は [doc/FF1_FC_Patch_memo.md](doc/FF1_FC_Patch_memo.md)

## FC版ファイナルファンタジー バグ修正パッチ
Chaos Rush氏らによるファイナルファンタジー翻訳版 v1.3用 Final Fantasy J バグ修正パッチ

配布サイト： [FF1J BugFixes](https://www.romhacking.net/hacks/5597/)  
IPSファイル： `FF1J_BugFixes.ips`  
ドキュメント日本語訳：  [FF1J_FC_Bugfixes_jp.md](doc/FF1J_FC_Bugfixes_jp.md)

海外の有志が製作された、無改造日本版ROMに当てても問題ない物を集めたパッチ。  
日本版で問題が起きる修正パッチは除外してあるため、いくつか未対応のバグもあります。

※ 配布サイトのRobotチェックが通過できない場合は、プライベートモードやFireFoxの組み込みVPNを試してみてください。

## FC版ファイナルファンタジー 利便化パッチ集（高速化・自動ターゲット・海川アニメ等）

アキラナオル氏によるファイナルファンタジー用 各種修正&便利パッチ集

配布サイト： [アキラナオルの部屋](https://akiranaoru.web.fc2.com/#ff1)  

EASY版パッチ、海と川のアニメ、コテージ修正、Bダッシュ、自動再ターゲット、メッセージ速度変更など、嬉しいパッチが揃っています。

統合版は見た目がファイナルファンタジー3に寄っているので、オリジナルの雰囲気を重視する場合は自分で個別パッチを組み合わせて使用するのがお勧めです。

`FF1J_BugFixes` にあって、こちらに含まれていない修正もあるので、
`FF1J_BugFixes` とも組み合わせるのがお勧めです。

## パッチ組み合わせのお勧め

FF1J_BugFixesとアキラナオル氏のパッチのうち、競合するパッチを除外した組み合わせをご紹介します。

ipsファイルはROMファイルに当てて使用しても良いですが、**Nestopia** や **RetroFreak** など、実行時に ipsファイルを指定して使用することもできます。

### EASYパッチ について

セーブデータはROMファイル名で区別されます。

通常版とEASY版でセーブデータを共用したくない場合は、  
EASYパッチだけを当てた
`ファイナルファンタジーEASY.NES`
を作っておくと良いかもしれません。

### FF1J_BugFixes+MinFixPlus

バグ修正を網羅。
オリジナルの雰囲気重視。
かつ便利。

- FF1J_BugFixes+MinFix
  - FF1J_BugFixes （[FF1J_FC_Bugfixes_jp.md](doc/FF1J_FC_Bugfixes_jp.md)）
  - FINAL_FANTASY1_COTTAGE
  - FINAL_FANTASY1_OMISE
  - FINAL_FANTASY1_KOUGEKI
- FINAL_FANTASY1_UMI
- FINAL_FANTASY1_KAIWA
- FINAL_FANTASY1_STATUS
- FINAL_FANTASY1_MENU
- FINAL_FANTASY1_B_DASH
- FINAL_FANTASY1_SENTOUSPEEDx4

これをEASYパッチと組み合わせて使っています。

#### `FF1J_BugFixes+MinFixPlus.ips` の作成

````text
python ips_manager.py FF1J_BugFixes.ips FINAL_FANTASY1_COTTAGE.ips FINAL_FANTASY1_OMISE.ips FINAL_FANTASY1_KOUGEKI.ips FINAL_FANTASY1_UMI.ips FINAL_FANTASY1_KAIWA.ips FINAL_FANTASY1_STATUS.ips FINAL_FANTASY1_MENU.ips FINAL_FANTASY1_B_DASH.ips FINAL_FANTASY1_SENTOUSPEEDx4.ips -o FF1J_BugFixes+MinFixPlus.ips
````

#### `FF1J_BugFixes+MinFix.NES` の作成

`ファイナルファンタジー.NES` に  
`FF1J_BugFixes+MinFixPlus.ips` パッチを当てる。

````text
python ips_manager.py -t ファイナルファンタジー.NES FF1J_BugFixes+MinFix.ips -o "ファイナルファンタジー_BugFixes+MinFix.NES"
````

### Nestopiaでの使用例

1. イージー+FixPlus：  
   `ファイナルファンタジーEASY.NES` 読込 → `FF1J_BugFixes+MinFix.ips` 読込

2. 通常+FixPlus：  
   `ファイナルファンタジー.NES` 読込 → `FF1J_BugFixes+MinFix.ips` 読込

※ ROMファイル名でSAVファイルが分かれるので、EASYとノーマルのNESファイルを使用して、IPSを実行時適用にしています。

---

# FC版ファイナルファンタジーROMエディタの紹介

## HakkinFF1

**HakkinFF1** は **FFHackSterEX** にインスパイアされたROMエディタです。  
**FFHackSterEX** では動かないマップ系機能がこちらでは動きます。

サイト： <https://HakkinFF1.digitaldreamers.org/index.html>  
日本版用ファイル： [for_HakkinFF1/](for_HakkinFF1/)

> US版と一部データのアドレスが違うため、そのままでは**Armor**、**Weapon**、**Magic**が**日本語版ROMではエラー**になり開くことができませんが、**日本語ROM用の設定ファイル**に置き換えれば日本版ROMでも使用することができます。

### 日本版ROM用 文字定義 & アドレス設定

ROMを読み込んで作成されたプロジェクトフォルダにある
 `(プロジェクト名).ff1d` に、文字定義やアドレス設定が入っています。

- [for_HakkinFF1/FinalFantasy1.ff1d](for_HakkinFF1/FinalFantasy1.ff1d)

を、プロジェクト名に合わせてリネームし、
プロジェクトフォルダに上書きしてください。

プロジェクトで文字やパラメータが正常に表示されるようになり、**Armor**、**Weapon**、**Magic** エディタを開けるようになります。

どういった修正がされているのか、詳細を知りたい場合は、[for_HakkinFF1/HakkinFF1_for_JP_ROM.md](for_HakkinFF1/HakkinFF1_for_JP_ROM.md) を参照ください。

## FFHackSterEX (※非推奨)

**FFHackSterEX** は 古の **FFHackSter** を復活させることを目指したものだそうです。

サイト： <https://ffhacksterex.digitaldreamers.org/>  
日本版用ファイル： [for_FFHackSterEX/](for_FFHackSterEX/)

こちらはWindowsXP世代に開発途中で止まっており、マップのスクロールがスクロールボタン非対応など、UIや操作性は **HakkinFF1** より古いものとなっています。

また、ローカルマップ系機能や幾つかの機能がエラーで落ちます。  

ランタイムの互換性問題に関しては、[github](https://github.com/ffhacksterex/FFHacksterEx/tree/v0.9.8.2-beta) にあるソースコードを [Visual C++2019 + プラットフォームツールセット Visual Studio 2017 - Windows XP(v141_xp) でビルド](for_FFHackSterEX/ffhacksterex-0.9.8.2-win64-x64-v141_xp_vs2019.zip)すれば落ちにくくなります。

古いプラットフォームツールセットをVS2022以降でビルドすると発生する問題が関係するようですが、英語版ROMだと問題が無かったりするので、良く分かりません。

### 日本版ROM用 文字定義ファイル

US版向けに作られたツールなので、文字コードに対する文字の割り当てがJP版と異なります。

New ProjectからROMを読み込んで作成されたプロジェクトフォルダにある  
`(プロジェクト名).dte.tbl`  
`(プロジェクト名).std.tbl`  
が、文字コードに対する文字リストです。

- [for_FFHackSterEX/FinalFantasy1.dte.tbl](for_FFHackSterEX/FinalFantasy1.dte.tbl)
- [for_FFHackSterEX/FinalFantasy1.std.tbl](for_FFHackSterEX/FinalFantasy1.std.tbl)

をプロジェクト名に合わせてリネームしてプロジェクトフォルダに上書きしてください。

プロジェクトで文字が正常に表示されるようになります。  
（`●●.dte.tbl` と `●●.std.tbl` は、UTF-8ではなくSJISテキストファイルです。）

### 日本版ROM用 アドレス設定ファイル

Bank `0x0E` ～ `0x0F` がUS版とJP版では異なるため、アドレス設定を修正しないと不正なデータを読み込んでしまいます。

New ProjectからROMを読み込んで作成されたプロジェクトフォルダにある  
`(プロジェクト名).values` に、各データのアドレス設定などが書かれています。

- [for_FFHackSterEX/FinalFantasy1.values](for_FFHackSterEX/FinalFantasy1.values)

をプロジェクト名に合わせてリネームしてプロジェクトフォルダに上書きしてください。

### 注意事項

ROMファイル名やパスには日本語を使わないでください。エラーになります。
