KSSファイル名毎に同名のプレイリストが用意されているケースではどのKSS対応プレイヤーでも問題ないのですが、
KSSファイルと違うファイル名の場合や、一つのプレイリストに複数のKSSファイルを指定している場合は問題が起きます。

kssファイルと別名のプレイリストや、1つのプレイリストで複数のKSSファイルを扱う場合はWinAMP一択になります。

# ■WinAMP向けプレイリストの作り方

WinAmp向けの日本語を含むm3uプレイリストは以下の条件で作成してください。

## m3uファイル

1. m3u8 UTF-8 BOM付き（これ以外は日本語文字化け）
2. 1行目はコメント（BOMありの時に1行目が無効なエントリになる問題の対策）

## plsファイル

また、WinAMP専用であれば、plsファイルを作成する方法もあります。

1. m3u シフトJISで作成
2. 作成したm3uを [Playlist converter m3u2pls](https://www.purose.net/befis/download/nezplug/oldsite.shtml)でplsファイルに変換

※ plsはシフトJISで。UTF-8だと逆に文字化けします。

※ 直接plsファイルを書いても良いと思います。

# ■kssファイルと別名のプレイリスト

1. kbMediaPlayer：NG
　（一見対応しているように見えて、演奏時にタイトルと時間指定が無効化される）
　（KSSファイル毎に同名のプレイリストを用意する場合は、in_msxが正常処理してくれる）

2. foobar2000：NG
　（プレイリストをドロップしても無効。kssをドロップした時に同じファイル名のプレイリストを読み込む仕様）
　（KSSファイル毎に同名のプレイリストを用意する場合は、in_msxが正常処理してくれる）

3. WinAMP：対応
　プレイリストの名前の一致に関係なく、タイトルも時間指定も正常動作
　ただし、文字コード関連の問題で制限アリ

# ■文字コード、m3u、m3u8の関係

1. kbMediaPlayer：
   - m3u、m3u8 ともに文字コードはシフトJIS、UTF-8(BOMなし)、UTF-8(BOMあり)いずれでもOK
   - m3u8のコメントOK

2. foobar2000：
   - m3u、m3u8 ともに文字コードはシフトJIS、UTF-8(BOMなし)、UTF-8(BOMあり)いずれでもOK
   - m3u8のコメントOK

3. WinAMP：
   - u3u8はコメント非対応
     コメント行もプレイリストに表示され、クリックした場合はスキップされる
   - 文字コードの認識がバグり気味
     - m3u：どのエンコードでも日本語文字化け
     - m3u8 UTF-8(BOMなし）：日本語文字化け
     - m3u8 UTF-8(BOMあり）：日本語の文字化けなし。 
       ただし、1行目はBOMヘッダが邪魔をするのか演奏がスキップされる
       → 一行目に#コメントでダミーを入れる

※ KSSファイル毎に同名のプレイリストを用意する場合は、kbMediaPlayerやfoobar2000の方が扱いが楽。  
　 （ただし、プレイリストファイル数が凄い事になる。）

# プレイリストKSS拡張書式

```
Extended Playlist
-----------------

    NEZplug/MSXplug extend M3U playlist format(v0.9) for Winamp

    filename::NSF,[1 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]
    filename::KSS,[0 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]
    filename::GBR,[0 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]
    filename::GBS,[0 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]
    filename::HES,[0 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]
    filename::AY ,[0 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]
    filename::NEZ,[0 based songno|$songno],[title],[time(h:m:s)],[loop(h:m:s)][-],[fade(h:m:s)],[loopcount]

    filename 曲ファイルの相対パス (*.zip;*.nsf;*.kss;...)

    songno   0開始の曲番号 (::NSFプレイリストは歴史的理由により1開始の曲番号のみを持ちます。)
    $songno  0開始の16進数曲番号

    title    曲のタイトル

    time     曲の再生時間 h * 3600 + m * 60 + s (秒)
             時間が指定されていない場合はデフォルトの時間 (5 分) が使用されます。

    loop(h:m:s)
             ループの長さ h * 3600 + m * 60 + s (秒)
    loop(h:m:s-)
             ループの開始時間 h * 3600 + m * 60 + s (秒)
    loop(-)
             ループの長さは再生時間と同じです。
             ループが指定されていない場合、曲はループしません。

    fade     フェードアウトの長さ h * 3600 + m * 60 + s (秒)
             時間が指定されていない場合はデフォルトのフェードアウトの長さ (5 秒) が使用されます。

    loopcount
             ループカウント時間が指定されていない場合はデフォルトのループカウントが使用されます。

     Winamp 2.6x のバグにより、拡張 M3U の再生に失敗する場合があります。
     その場合はM3U2PLS コンバータを試してください。
```

## Playlist converter m3u2pls

ダウンロード： 
https://www.purose.net/befis/download/nezplug/oldsite.shtml
