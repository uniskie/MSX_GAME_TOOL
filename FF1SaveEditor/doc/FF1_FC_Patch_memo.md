# ファミコン版ファイナルファンタジー用 パッチ メモ

## Chaos Rush氏らによるファイナルファンタジー翻訳版 v1.3用 Final Fantasy J バグ修正パッチ

[FF1J BugFixes](https://www.romhacking.net/hacks/5597/)

[FF1J_FC_Bugfixes_jp.md](FF1J_FC_Bugfixes_jp.md)

IPSファイル： `FF1J_BugFixes.ips`

日本語版ドキュメント：  [FF1J_FC_Bugfixes_jp.md](FF1J_FC_Bugfixes_jp.md)

英語翻訳パッチを使用したROM向けのバグフィックス集パッチのうち、
日本版そのままのROMに当てても問題ない物だけ集めたパッチ。

日本版で問題が起きる修正パッチは除外してあるため、いくつか未対応のバグもあります。


※ ROBOTチェックが通過できない場合は、FireFoxの組み込みVPNを使用すると通ることも。

## アキラナオル氏によるファイナルファンタジー用 各種修正&便利パッチ集

[アキラナオルの部屋](https://akiranaoru.web.fc2.com/#ff1)

FF2やDQなど他のゲームのパッチも。

EASY版、海と川のアニメ、コテージ修正、Bダッシュ、自動再ターゲット、メッセージ速度変更

| 内容                          | パッチファイル                       |
| :---------------------------- | :----------------------------------- |
| 総合版 [DOWNLOAD(ver20240914) | `FINAL_FANTASY1_KAI_ver20240914.zip` |

| 統合版憎まれる各機能のパッチ             | パッチファイル                                  | 補足                                         |
| :--------------------------------------- | :---------------------------------------------- | :------------------------------------------- |
| お店会話とデフォメッセージ速度修正       | `FINAL_FANTASY1_OMISE.zip`                      |                                              |
| 会話ウインド簡略化                       | `FINAL_FANTASY1_KAIWA.zip`                      |                                              |
| 敵への攻撃修正                           | `FINAL_FANTASY1_KOUGEKI.zip`                    |                                              |
| まほうのストライ修正                     | `FINAL_FANTASY1_MAHO.zip`                       |                                              |
| コテージ修正                             | `FINAL_FANTASY1_COTTAGE.zip`                    |                                              |
| ステータス左右追加                       | `FINAL_FANTASY1_STATUS.zip`                     |                                              |
| 海と川の流れ追加                         | `FINAL_FANTASY1_UMI.zip`                        |                                              |
| 文字フォント変更                         | `FINAL_FANTASY1_FONT.zip`                       |                                              |
| キャラをFF3のキャラに変更                | `FINAL_FANTASY1_CHARA_FF3.zip`                  |                                              |
| 町と城のBGデータを変更                   | `FINAL_FANTASY1_MACHICHARA.zip`                 |                                              |
| 戦闘画面変更                             | `FINAL_FANTASY1_SENTOU1.zip`                    |                                              |
| メニュ画面変更とセーブ追加               | `FINAL_FANTASY1_MENU.zip`                       |                                              |
| 戦闘のキャラの動き4倍に変更              | `FINAL_FANTASY1_SENTOUSPEEDx4.zip`              |                                              |
| Ｂダッシュとエンカウント無しの追加       | `FINAL_FANTASY1_B_DASH.zip`                     | Bボタンで早歩き、B+Aボタンでエンカウント無し |
| コーネリア城にいるお化けを実体化します。 | `FINAL_FANTASY1_Cornelia_Castle_Ghost_View.zip` |                                              |

| 統合版に含まれないパッチ   | パッチファイル                     | 補足                                                  |
| :------------------------- | :--------------------------------- | :---------------------------------------------------- |
| イージー化します。         | `FINAL_FANTASY1_easy.zip`          | レベルアップの経験値を低めに設定。                    |
| 名前にカタカナ追加         | `FINAL_FANTASY1_KANA.zip`          |                                                       |
| ポーションテスト           | `FINAL_FANTASY1_PORTION.zip`       | ポーションでMPも回復。きんのはりで蘇生。              |
|                            |                                    | ※ ポーションテストはストライ修正パッチに上書き専用。 |
| 文字フォントを元に戻す     | `FINAL_FANTASY1_FONT_ORG.zip`      |                                                       |
| キャラを元のFF1に戻す      | `FINAL_FANTASY1_CHARA_FF1.zip`     |                                                       |
| 町と城のBGデータを元に戻す | `FINAL_FANTASY1_MACHICHRA_ORG.zip` |                                                       |

ただ、統合版はFF3っぽくなりすぎてしまうので、
オリジナルの雰囲気を重視する場合は個別に必要なパッチを当てていくのがお勧めです。

FF1J_BugFixesに含まれていないパッチが盛りだくさんですが、
逆に FF1J_BugFixes にしかない修正もあるので、やはり組み合わせがお勧めです。

## パッチ組み合わせのお勧め

FF1J_BugFixesとアキラナオル氏のパッチのうち、競合するパッチを除外した組み合わせをご紹介します。

ipsファイルははROMファイルに当てて使用しても良いですが、NestopiaやRetroFreakなど、実行時にipsファイルを指定して使用することもできます。

### [ips_manager.py](../ips_manager.py)

[ips_manager.py](../ips_manager.py) は
ROMに複数のパッチをまとめて当てたり、パッチを合成したりできます。

複数のIPSを順番に合成する場合、
重複時は警告+上書き［後行優先］となっています。

```text
usage: ips_manager.py [-h] -o OUTPUT [-t TARGET] [--on-conflict {overwrite,keep,abort}] [--no-warn] [--strict-same]
                      patches [patches ...]

IPSファイルの合成・複数適用ツール

複数のIPSパッチを指定した順番で1つのIPSファイルへ合成、
またはベースファイル（ROM等）へ直接適用します。
重複箇所の検知・警告の有無・競合時の動作（重複時上書き［後行優先］／
重複時無視［先行優先］／エラー中断）を制御できます。

仕様・注意事項:
  - 標準IPS形式（PATCHヘッダ / RLE圧縮 / EOF / 切り詰めサイズ拡張）に対応
  - デフォルトでは「同じオフセットに同じ値」を書く重複は無視し、
    「異なる値」を書こうとする競合のみを警告します（--strict-same で変更可）

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

### EASYパッチ について

セーブデータはROMファイル名で区別されれます。

通常版とEASY版でセーブデータを共用したくない場合は、  
EASYパッチだけを当てた
`ファイナルファンタジーEASY.NES`
を作っておくと良いかもしれません。

### FF1J_BugFixes+MinFixPlus

バグ修正を網羅。
オリジナルの雰囲気重視。
かつ便利。

- FF1J_BugFixes+MinFix
  - FF1J_BugFixes （[FF1J_FC_Bugfixes_jp.md](FF1J_FC_Bugfixes_jp.md)）
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
python ips_manager.py F1J_BugFixes.ips FINAL_FANTASY1_COTTAGE.ips FINAL_FANTASY1_OMISE.ips FINAL_FANTASY1_KOUGEKI.ips FINAL_FANTASY1_UMI.ips FINAL_FANTASY1_KAIWA.ips FINAL_FANTASY1_STATUS.ips FINAL_FANTASY1_MENU.ips FINAL_FANTASY1_B_DASH.ips FINAL_FANTASY1_SENTOUSPEEDx4.ips -o FF1J_BugFixes+MinFixPlus.ips
````

#### `FF1J_BugFixes+MinFix.NES` の作成

`FInalFantasy1.NES` に  
`FF1J_BugFixes+MinFixPlus.ips` パッチを当てます。

````text
python ips_manager.py -t FinalFantasy1.NES FF1J_BugFixes+MinFix.ips -o FF1J_BugFixes+MinFix.NES
````

### FF1J_BugFixes+MinFix

バグ修正を網羅。
オリジナルの雰囲気重視。
便利追加機能は無し。

- FF1J_BugFixes （[FF1J_FC_Bugfixes_jp.md](FF1J_FC_Bugfixes_jp.md)）
- FINAL_FANTASY1_COTTAGE
- FINAL_FANTASY1_OMISE
- FINAL_FANTASY1_KOUGEKI

硬派な人向けです。

`FF1J_BugFixes+MinFix.ips` の作成：

````text
python ips_manager.py FF1J_BugFixes.ips FINAL_FANTASY1_COTTAGE.ips FINAL_FANTASY1_OMISE.ips FINAL_FANTASY1_KOUGEKI.ips -o FF1J_BugFixes+MinFix.ips
````

`FInalFantasy1.NES` に  
`FF1J_BugFixes+MinFixPlus.ips` パッチを当てた  
`FF1J_BugFixes+MinFix.NES` の作成：

````text
python ips_manager.py -t FinalFantasy1.NES FF1J_BugFixes+MinFixPlus.ips -o FF1J_BugFixes+MinFixPlus.NES
````

## アキラナオル氏のパッチ FF1オリジナル重視版

アキラナオル氏のパッチのみで構成した、FF1の見た目を維持することを重視した組み合わせです。

### FINAL_FANTASY1_MinFix

- FINAL_FANTASY1_Cornelia_Castle_Ghost_View
- FINAL_FANTASY1_COTTAGE
- FINAL_FANTASY1_KOUGEKI
- FINAL_FANTASY1_MAHO
- FINAL_FANTASY1_OMISE

### FINAL_FANTASY1_MinfixPlus

- FINAL_FANTASY1_MinFix
  - FINAL_FANTASY1_Cornelia_Castle_Ghost_View
  - FINAL_FANTASY1_COTTAGE
  - FINAL_FANTASY1_KOUGEKI
  - FINAL_FANTASY1_MAHO
  - FINAL_FANTASY1_OMISE
- FINAL_FANTASY1_UMI
- FINAL_FANTASY1_KAIWA
- FINAL_FANTASY1_STATUS
- FINAL_FANTASY1_MENU
- FINAL_FANTASY1_B_DASH
- FINAL_FANTASY1_SENTOUSPEEDx4
