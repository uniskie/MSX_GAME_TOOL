	org	42A2h
CHKMUS:                   ;# MSX-MUSIC����
        xor    a          ; �X���b�g0����
        ld     ($f007),a  ; ���������t���O�N���A
BASCLP:                   ;# ��{�X���b�g�`�F�b�N�擪
        ld     e,a        
        ld     hl,$fcc1   
        ld     c,a        
        ld     b,$00      
        add    hl,bc      
        ld     a,(hl)     ;�iEXPTBL+��{�X���b�g�ԍ��j�̃`�F�b�N
        cp     $80        ; �g������Ă��邩�H
        ld     a,e        
        jr     nz,CMPOPL  ; �g������Ă��Ȃ���΁A�X���b�g�ԍ���bit7�𗧂ĂȂ�
        set    7,a        ; �g������Ă���΁A�X���b�g�ԍ���bit7�𗧂Ă�
CMPOPL:                   ;# ������v�`�F�b�N
        push   af         
        ld     hl,$401c   ; �����`�F�b�N�J�n�A�h���X
        call   $000c      ; RDSLT�iA���W�X�^�Ŏw�肵���X���b�g����ꕶ���ǂݍ��݁j
        cp     'O'        
        jr     nz,NXTSLT  ; ��v���Ȃ������玟�̃X���b�g��
        inc    hl         
        pop    af         
        push   af         
        call   $000c      ; RDSLT�iA���W�X�^�Ŏw�肵���X���b�g����ꕶ���ǂݍ��݁j
        cp     'P'        
        jr     nz,NXTSLT  ; ��v���Ȃ������玟�̃X���b�g��
        inc    hl         
        pop    af         
        push   af         
        call   $000c      ; RDSLT�iA���W�X�^�Ŏw�肵���X���b�g����ꕶ���ǂݍ��݁j
        cp     'L'        
        jr     nz,NXTSLT  ; ��v���Ȃ������玟�̃X���b�g��
        inc    hl         
        pop    af         
        push   af         
        call   $000c      ; RDSLT�iA���W�X�^�Ŏw�肵���X���b�g����ꕶ���ǂݍ��݁j
        cp     'L'        
        jr     nz,NXTSLT  ; ��v���Ȃ������玟�̃X���b�g��
                          ;# ���ׂĈ�v
        pop    af         
        ld     hl,$f009   
        ld     (hl),a     
        xor    a          
        dec    hl         
        ld     (hl),a     
        inc    a          
        ld     ($f007),a  ; ���������t���O�Z�b�g
        ret               ; ��������END
NXTSLT:                   ;# ���̃X���b�g��
        pop    af         
        bit    7,a        ; �g���X���b�g�t���O����
        jr     z,NXTBAS   ; �g���X���b�g�ł͂Ȃ�����{�X���b�g�ԍ����Z��
        add    a,$04      ; �g���X���b�g�ԍ�+=1
        bit    4,a        
        jr     z,CMPOPL   ; �g���X���b�g�ԍ���4�����Ȃ當���`�F�b�N�擪�ցi���[�v�j
        res    7,a        
        res    4,a        
NXTBAS:
        inc    a          
        bit    2,a        
        jr     z,BASCLP   ; ��{�X���b�g�ԍ���4�����Ȃ當���`�F�b�N�擪�ցi���[�v�j
        xor    a          
        ret               ; ���������Ȃ�����END
        nop               ; �ȉ��A�]�����̂Ŗ��߂Ă���
        nop               
        nop               
        nop               
