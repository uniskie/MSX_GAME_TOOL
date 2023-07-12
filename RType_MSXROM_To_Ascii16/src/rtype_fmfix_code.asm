	org	42A2h
CHKMUS:                   ;# MSX-MUSIC検索
        xor    a          ; スロット0から
        ld     ($f007),a  ; 発見したフラグクリア
BASCLP:                   ;# 基本スロットチェック先頭
        ld     e,a        
        ld     hl,$fcc1   
        ld     c,a        
        ld     b,$00      
        add    hl,bc      
        ld     a,(hl)     ;（EXPTBL+基本スロット番号）のチェック
        cp     $80        ; 拡張されているか？
        ld     a,e        
        jr     nz,CMPOPL  ; 拡張されていなければ、スロット番号のbit7を立てない
        set    7,a        ; 拡張されていれば、スロット番号のbit7を立てる
CMPOPL:                   ;# 文字一致チェック
        push   af         
        ld     hl,$401c   ; 文字チェック開始アドレス
        call   $000c      ; RDSLT（Aレジスタで指定したスロットから一文字読み込み）
        cp     'O'        
        jr     nz,NXTSLT  ; 一致しなかったら次のスロットへ
        inc    hl         
        pop    af         
        push   af         
        call   $000c      ; RDSLT（Aレジスタで指定したスロットから一文字読み込み）
        cp     'P'        
        jr     nz,NXTSLT  ; 一致しなかったら次のスロットへ
        inc    hl         
        pop    af         
        push   af         
        call   $000c      ; RDSLT（Aレジスタで指定したスロットから一文字読み込み）
        cp     'L'        
        jr     nz,NXTSLT  ; 一致しなかったら次のスロットへ
        inc    hl         
        pop    af         
        push   af         
        call   $000c      ; RDSLT（Aレジスタで指定したスロットから一文字読み込み）
        cp     'L'        
        jr     nz,NXTSLT  ; 一致しなかったら次のスロットへ
                          ;# すべて一致
        pop    af         
        ld     hl,$f009   
        ld     (hl),a     
        xor    a          
        dec    hl         
        ld     (hl),a     
        inc    a          
        ld     ($f007),a  ; 発見したフラグセット
        ret               ; 発見したEND
NXTSLT:                   ;# 次のスロットへ
        pop    af         
        bit    7,a        ; 拡張スロットフラグ検査
        jr     z,NXTBAS   ; 拡張スロットではない→基本スロット番号加算へ
        add    a,$04      ; 拡張スロット番号+=1
        bit    4,a        
        jr     z,CMPOPL   ; 拡張スロット番号が4未満なら文字チェック先頭へ（ループ）
        res    7,a        
        res    4,a        
NXTBAS:
        inc    a          
        bit    2,a        
        jr     z,BASCLP   ; 基本スロット番号が4未満なら文字チェック先頭へ（ループ）
        xor    a          
        ret               ; 一つも見つからなかったEND
        nop               ; 以下、余ったので埋めておく
        nop               
        nop               
        nop               
