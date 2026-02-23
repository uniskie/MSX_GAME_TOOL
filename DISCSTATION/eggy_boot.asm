    ORG $7FF0
START_PPINT:
    DI
    LD   HL,$4010
    LD   DE,$8010
    LD   BC,$3F00
    LDIR
    JP  $8010
    NOP
