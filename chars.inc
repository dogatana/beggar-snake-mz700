#if exists PC8001
CH_BODY   equ $87
CH_WALL_TOP     equ $80
CH_WALL_RIGHT     equ $88
CH_HEAD_U equ $90
CH_HEAD_D equ $91
CH_HEAD_L equ $92
CH_HEAD_R equ $93
CH_DIA    equ $EA
CH_WALL_UL     equ $F8
CH_WALL_UR     equ $F9
CH_WALL_LL     equ $FA
CH_WALL_LR     equ $FB
CH_WALL_BOTTOM     equ $94
CH_WALL_LEFT     equ $97
CH_CROSS  equ $f0
CH_DOUBLE equ $e0
CH_BAR    equ $b0
#elif exists MZ700
CH_BODY   equ $c7 ; $87
CH_WALL_TOP     equ $c0 ; $80
CH_WALL_RIGHT     equ $c8 ; $88
CH_HEAD_U equ $d0 ; $90
CH_HEAD_D equ $d1 ; $91
CH_HEAD_L equ $d2 ; $92
CH_HEAD_R equ $d3 ; $93
CH_DIA    equ $ce ; $EA
CH_WALL_UL     equ $dc ; $F8
CH_WALL_UR     equ $dd ; $F9
CH_WALL_LL     equ $de ; $FA
CH_WALL_LR     equ $df ; $FB
CH_WALL_BOTTOM     equ $d4 ; $94
CH_WALL_LEFT     equ $d7 ; $97
CH_CROSS  equ $cc ; $f0
CH_DOUBLE equ $c4 ; e0
CH_BAR    equ @MAP:"-"
#endif
