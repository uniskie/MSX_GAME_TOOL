# ==============================================================================
# openMSX Script: MSX2版 FF1 戦闘OSDオーバーレイ
# ==============================================================================

# 前回のループとOSDを強制破棄
catch { after cancel $::ff1_overlay::after_id }
catch { osd destroy ff1_osd }

namespace eval ::ff1_overlay {
    variable active 1
    variable created 0
    variable after_id ""
    variable inactive_count 0

    # 指定フォントパス（未設定または存在しない場合はopenMSXデフォルトフォントを使用）
    variable font_path ""
    if {[info exists ::env(OPENMSX_USER_DATA)]} {
        #set font_path [file join $::env(OPENMSX_USER_DATA) skins osaka.mono.ttf]
        #set font_path [file join $::env(OPENMSX_USER_DATA) skins misaki_gothic.ttf]
        #set font_path [file join $::env(OPENMSX_USER_DATA) skins HackGen-Regular.ttf]
        set font_path [file join $::env(OPENMSX_USER_DATA) skins BIZUDGothic-Regular.ttf]
    }
    variable font_size 5

    # 敵フレームのオフセット設定（微調整用）
    variable enemy_offset_x -18   ;# キャラクタの左端に合わせるXオフセット
    variable enemy_offset_y -22   ;# 頭上に表示するYオフセット

    # 差分更新用キャッシュ
    variable cache_text
    variable cache_color
    variable cache_rect_vis
    variable cache_rect_x
    variable cache_rect_y

    # ジョブ名テーブル
    variable jobs {
        0 "戦士"  1 "盗賊"  2 "モンク"    3 "赤魔術師"  4 "白魔術師"  5 "黒魔術師"
        6 "騎士"  7 "忍者"  8 "ｽｰﾊﾟｰﾓﾝｸ"  9 "赤魔導士" 10 "白魔導士" 11 "黒魔導士"
    }

    # 16bit リトルエンディアン取得
    proc peek16_le {addr} {
        expr {[peek $addr] | ([peek [expr {$addr + 1}]] << 8)}
    }

    # 戦闘状態の検出
    proc is_battle_active {} {
        if {[catch {
            expr {[peek 0x8000] == 0xED && [peek 0x8001] == 0x73 &&
                  [peek 0x8002] == 0xC2 && [peek 0x8003] == 0x80}
        } ok] || !$ok} {
            return 0
        }
        set maxhp [peek16_le 0x340C]
        if {$maxhp <= 0 || $maxhp > 999} {
            return 0
        }
        return 1
    }

    # 状態異常の表示名
    proc decode_status {sts} {
        if {$sts == 0} { return "OK" }
        set s ""
        if {$sts & 0x01} { append s "死" } ;# 死亡
        if {$sts & 0x02} { append s "石" } ;# 石化
        if {$sts & 0x04} { append s "毒" } ;# 毒  
        if {$sts & 0x08} { append s "暗" } ;# 暗闇
        if {$sts & 0x10} { append s "痺" } ;# 麻痺
        if {$sts & 0x20} { append s "眠" } ;# 睡眠
        if {$sts & 0x40} { append s "沈" } ;# 沈黙
        if {$sts & 0x80} { append s "混" } ;# 混乱
        return [string trim $s]
    }

    # HP割合に応じた色設定
    proc get_hp_color {cur max} {
        if {$max <= 0} { return "0xffffffff" }
        set r [expr {double($cur) / $max}]
        if {$cur <= 0} {
            return "0x888888ff" ;# 死亡: 灰
        } elseif {$r < 0.25} {
            return "0xff4040ff" ;# 瀕死: 赤
        } elseif {$r < 0.50} {
            return "0xffff40ff" ;# 警告: 黄
        } else {
            return "0x80ff80ff" ;# 安全: 緑
        }
    }

    # キャッシュクリア
    proc clear_cache {} {
        variable cache_text;     array unset cache_text
        variable cache_color;    array unset cache_color
        variable cache_rect_vis; array unset cache_rect_vis
        variable cache_rect_x;   array unset cache_rect_x
        variable cache_rect_y;   array unset cache_rect_y
    }

    # 差分更新テキスト
    proc set_text_cached {w text color} {
        variable cache_text
        variable cache_color
        set update 0
        if {![info exists cache_text($w)] || $cache_text($w) ne $text} {
            set cache_text($w) $text
            set update 1
        }
        if {![info exists cache_color($w)] || $cache_color($w) ne $color} {
            set cache_color($w) $color
            set update 1
        }
        if {$update} {
            osd configure $w -text $text -rgba $color
        }
    }

    # 差分更新矩形（敵用）
    proc set_rect_cached {w x y visible} {
        variable cache_rect_vis
        variable cache_rect_x
        variable cache_rect_y

        set cur_v [expr {[info exists cache_rect_vis($w)] ? $cache_rect_vis($w) : -1}]
        set cur_x [expr {[info exists cache_rect_x($w)] ? $cache_rect_x($w) : -999}]
        set cur_y [expr {[info exists cache_rect_y($w)] ? $cache_rect_y($w) : -999}]

        if {$visible} {
            if {$cur_v != 1 || $cur_x != $x || $cur_y != $y} {
                osd configure $w -x $x -y $y -rgba 0x380808cc -borderrgba 0xff5050b0
                set cache_rect_vis($w) 1
                set cache_rect_x($w) $x
                set cache_rect_y($w) $y
            }
        } else {
            if {$cur_v != 0} {
                osd configure $w -rgba 0x00000000 -borderrgba 0x00000000
                set cache_rect_vis($w) 0
            }
        }
    }

    # OSDテキストウィジェット作成ヘルパー（指定フォントが存在しない場合はデフォルトフォントを使用）
    proc create_text_widget {name x y color {text ""}} {
        variable font_path
        variable font_size
        set cmd [list osd create text $name -x $x -y $y]
        if {[info exists font_path] && $font_path ne "" && [file exists $font_path]} {
            lappend cmd -font $font_path
        }
        lappend cmd -size $font_size -rgba $color -text $text
        eval $cmd
    }

    # OSD完全破棄
    proc destroy_widgets {} {
        variable created
        clear_cache
        catch { osd destroy ff1_osd }
        set created 0
    }

    # OSDウィジェット作成
    proc create_widgets {} {
        variable created
        if {$created} { return }

        destroy_widgets

        # ルート矩形 (MSX 320x240 全画面スケーリング)
        osd create rectangle ff1_osd -scaled true -x 0 -y 0 -w 320 -h 240 -rgba 0x00000000

        # 味方用ウィジェット (4人分)
        # MSX画面のステータスウィンドウ（Y=19開始、ピッチ51px、高さ49px）に完全一致
        for {set i 0} {$i < 4} {incr i} {
            set y [expr {22 + $i * 50}]
            set wname "ff1_osd.p$i"
            osd create rectangle $wname \
                -x 246 -y $y -w 54 -h 35 \
                -rgba 0x081848E0 -borderrgba 0x5080ffa0 -bordersize 1

            create_text_widget "$wname.l1" 3 3  0xa0e0ffff ""
            create_text_widget "$wname.l2" 3 9 0x80ff80ff ""
            create_text_widget "$wname.l3" 3 15 0xffffffff ""
            create_text_widget "$wname.l4" 3 21 0xffffffff ""
            create_text_widget "$wname.l5" 3 27 0xffd080ff ""
        }

        # 敵用ウィジェット (最大9体分: HP, ATK/DEF, ACC/EVA の3行構成)
        # 横幅 48px、行間ピッチ(6-7px)で高さ 24px
        for {set i 0} {$i < 9} {incr i} {
            set wname "ff1_osd.e$i"
            osd create rectangle $wname \
                -x 0 -y 0 -w 41 -h 28 \
                -rgba 0x00000000 -borderrgba 0x00000000 -bordersize 1

            # 行1: HP
            create_text_widget "$wname.l1" 3 2  0x80ff80ff ""
            # 行2: 攻撃力・防御力
            create_text_widget "$wname.l2" 3 8  0xffffffff ""
            # 行3: 命中率・回避率
            create_text_widget "$wname.l3" 3 14 0xffffffff ""
            # 行4: 魔法防御・状態異常
            create_text_widget "$wname.l4" 3 20 0xffd080ff ""
        }

        set created 1
    }

    # リアルタイム更新
    proc update {} {
        variable active
        variable created
        variable inactive_count
        variable jobs
        variable enemy_offset_x
        variable enemy_offset_y

        # 非戦闘判定（15フレーム猶予でチラつき防止）
        if {!$active || ![is_battle_active]} {
            incr inactive_count
            if {$inactive_count > 15 && $created} {
                destroy_widgets
            }
            return
        }
        set inactive_count 0

        if {!$created} {
            create_widgets
        }

        # --- 味方更新（差分更新） ---
        for {set i 0} {$i < 4} {incr i} {
            set base [expr {0x3400 + $i * 72}]
            set wname "ff1_osd.p$i"

            set jid   [peek $base]
            set sts   [peek [expr {$base + 0x01}]]
            set hp    [peek16_le [expr {$base + 0x0A}]]
            set maxhp [peek16_le [expr {$base + 0x0C}]]
            set atk   [peek [expr {$base + 0x20}]]
            set acc   [peek [expr {$base + 0x21}]]
            set def   [peek [expr {$base + 0x22}]]
            set eva   [peek [expr {$base + 0x23}]]
            set mdef  [peek [expr {$base + 0x25}]]
            set lv    [peek [expr {$base + 0x26}]]
            set hits  [peek [expr {$base + 0x42}]]

            if {[dict exists $jobs $jid]} {
                set jname [dict get $jobs $jid]
            } else {
                set jname "JOB$jid"
            }

            set sts_str [decode_status $sts]
            set hp_color [get_hp_color $hp $maxhp]

            # ジョブとレベル表記
            set_text_cached "$wname.l1" [format "P%d \[%-4s\] Lv%2d" [expr {$i+1}] $jname $lv] 0xa0e0ffff
            set_text_cached "$wname.l2" [format "HP:%3d / %3d" $hp $maxhp] $hp_color
            set_text_cached "$wname.l3" [format "攻:%2d  防:%2d" $atk $def] 0xffffffff
            set_text_cached "$wname.l4" [format "命:%2d(%dH) 避:%2d" $acc $hits $eva] 0xffffffff
            set_text_cached "$wname.l5" [format "魔防:%2d  \[%s\]" $mdef $sts_str] 0xffd080ff
        }

        # --- 敵更新 ---
        for {set i 0} {$i < 9} {incr i} {
            set wname "ff1_osd.e$i"
            set mid [peek [expr {0xBC66 + $i}]]

            # 未出現または無効スロット
            if {$mid == 0xFF || $mid > 127} {
                set_rect_cached $wname 0 0 0
                set_text_cached "$wname.l1" "" 0xffffffff
                set_text_cached "$wname.l2" "" 0xffffffff
                set_text_cached "$wname.l3" "" 0xffffffff
                set_text_cached "$wname.l4" "" 0xffffffff
                continue
            }

            set ebase [expr {0x3520 + $i * 30}]
            set ehp   [peek16_le [expr {$ebase + 0x04}]]
            set emax  [peek16_le [expr {$ebase + 0x1B}]]
            set ests  [peek [expr {$ebase + 0x17}]]
            set eeva  [peek [expr {$ebase + 0x08}]]
            set edef  [peek [expr {$ebase + 0x09}]]
            set emdef [peek [expr {$ebase + 0x11}]]
            set eacc  [peek [expr {$ebase + 0x0B}]]
            set eatk  [peek [expr {$ebase + 0x0C}]]

            # 死亡時非表示
            if {$ehp <= 0 || ($ests & 0x01) != 0} {
                set_rect_cached $wname 0 0 0
                set_text_cached "$wname.l1" "" 0xffffffff
                set_text_cached "$wname.l2" "" 0xffffffff
                set_text_cached "$wname.l3" "" 0xffffffff
                continue
            }

            # 描画座標 (MSX 256x212 -> OSD 320x240: X+32, Y+14)
            set msx_x [peek [expr {0xBC87 + $i * 2}]]
            set msx_y [peek [expr {0xBC87 + $i * 2 + 1}]]

            # X: キャラクタの左端に合わせて左へオフセット
            set osd_x [expr {$msx_x + 40 + $enemy_offset_x}]

            # Y: 敵キャラの頭上に配置（画面上端からはみ出る場合のみ上部に重ねる）
            set osd_y [expr {$msx_y + 14 + $enemy_offset_y}]
            if {$osd_y < 14} { set osd_y [expr {$msx_y + 14 + 2}] }

            set ests_str [decode_status $ests]
            set ehp_color [get_hp_color $ehp $emax]

            set_rect_cached $wname $osd_x $osd_y 1

            # 行1: HP / 最大HP
            if {$ests_str ne "OK"} {
                set_text_cached "$wname.l1" [format "HP:%d/%d" $ehp $emax] $ehp_color
            } else {
                set_text_cached "$wname.l1" [format "HP:%d/%d" $ehp $emax] $ehp_color
            }

            # 行2: 攻撃力・防御力
            set_text_cached "$wname.l2" [format "攻%d 防%d" $eatk $edef] 0xffffffff

            # 行3: 命中率・回避率
            set_text_cached "$wname.l3" [format "命%d 避%d" $eacc $eeva] 0xffffffff

            # 行4: 魔法防御 [状態]
            set_text_cached "$wname.l4" [format "魔防%d \[%s\]" $emdef $ests_str] 0xffd080ff
        }
    }

    # フレーム監視ループ
    proc loop {} {
        variable after_id
        update
        set after_id [after frame ::ff1_overlay::loop]
    }

    proc start {} {
        variable after_id
        catch { after cancel $after_id }
        loop
    }
}

# コンソール用トグルコマンド
proc ff1_overlay {{cmd "toggle"}} {
    switch -- $cmd {
        "on" {
            set ::ff1_overlay::active 1
            puts "FF1 Battle Overlay: ON"
        }
        "off" {
            set ::ff1_overlay::active 0
            ::ff1_overlay::destroy_widgets
            puts "FF1 Battle Overlay: OFF"
        }
        "toggle" - default {
            if {$::ff1_overlay::active} {
                ff1_overlay off
            } else {
                ff1_overlay on
            }
        }
    }
}

::ff1_overlay::start
puts "======================================================="
puts " MSX2 Final Fantasy Battle OSD Overlay Loaded!"
puts { コマンド: ff1_overlay [on | off | toggle]}
puts "======================================================="
