                charmap @MZ700, "mz700-alt.json"

#if exists PUBLIC
                include "color.inc"
                include "chars.inc"
                include "defs.inc"

                charmap @MAP, "mz700-alt.json"
clear_work_top10 equ $233C
init_display     equ $2364
disp_message     equ $2347
game_main        equ $2A2B
game_over        equ $2A83
CD_DBC4          equ $24D4
pattern_data     equ $2EAC

#endif
            
                org     $1200
start:          
                call    patch_program
                call    mz_setup_pcg_pattern
                call    mz_init_8253
clear_top10:    call    clear_work_top10
show_help:      call    init_display

                ld      hl, xy2attr(0, 23)
                ld      (blink_msg + 1), hl
blink_msg:      ld      hl, xy2attr(0, 23) ; 自己書き換え対象
                push    hl
                pop     de
                inc     de
                ld      bc, 39

                ld      a, ($e002)
                bit     6, a
                jr      z, .disp_on
                ld      (hl), ATTR_BLACK
                jr      .disp
.disp_on        ld      (hl), ATTR_GREEN
.disp           ldir

                ld      a, 0
                call    scan_key
                bit     0, a        ; CR
                jr      z, .key_ret
                ;
                ld      a, 3
                call    scan_key
                bit     3, a        ; key M
                jr      z, .key_ret
                ;
                ld      a, 4
                call    scan_key
                bit     6, a        ; key B
                jr      z, show_help
                ;
                bit     3, a        ; key E
                jr      z, clear_top10
                ;
                bit     5, a        ; key C
                jr      nz, blink_msg
                ; reset
                ld      a, $71 ; FG=白, BG=青
                ld      (mz_rom_cls.attr + 1), a
                call    mz_rom_cls
                ; 次回起動用にシアンをセットしておく
                ld      a, ATTR_CYAN
                ld      (mz_rom_cls.attr + 1), a
                jp      0
                ;

.key_ret       
                call    mz_rom_cls
                ld      hl, mz_msg_stage0
                call    disp_message
                ;
                call    game_main
                call    game_over

                ld      hl, xy2attr(0, 18)
                ld      (blink_msg + 1), hl

                jr      blink_msg

; -------------------------------------------------------
mz_enter_name:  push    hl
                push    de
                push    ix
                ld      de, (EX_WK_YPOS_EA63)
                dec     e
                ld      d, 0
                push    de
                pop     hl
                add     hl, hl
                add     hl, hl
                add     hl, de
                add     hl, hl
                add     hl, hl
                add     hl, hl
                ld      a, (EX_WK_XPOS_EA64)
                ld      e, a
                inc     e
                ld      d, 0
                add     hl, de
                ld      de, vram_addr
                add     hl, de
                ld      (.cursor_addr), hl
                ;
.enter_loop
                call    mz_get_key
                cp      $ff ; キー入力なし
                jr      z, .blink
                ;
                cp      $3d ; CR
                jp      z, .return
                ;
                cp      $3e ; BS
                jr      nz, .char_entered
                ; BS 処理
                call    blink_cursor.normal
                call    wait_key_release
                ld      a, (EX_WK_XPOS_EA64)
                cp      $08
                jr      z, .blink
                dec     a
                ld      (EX_WK_XPOS_EA64), a
                ld      hl, (mz_enter_name.cursor_addr)
                dec     hl
                ld      (mz_enter_name.cursor_addr), hl
                jr      .blink

.char_entered   call    mz_putc
                call    wait_key_release
                ;
                ld      a, (EX_WK_XPOS_EA64)
                cp      $18
                jr      nz, .blink
                ;
.return         ; 全てのキーが離されるのを待つ
                call    wait_key_release
                pop     ix
                pop     de
                pop     hl
                ret
.blink          call    blink_cursor
                jr      .enter_loop

.cursor_addr    dw      0

blink_cursor:   ld      a, ($e002)
                bit     6, a
                jr      z, .reverse
.normal         ld      hl, xy2attr(0, 18)
                ld      de, xy2attr(1, 18)
                ld      (hl), ATTR_GREEN
                ld      bc, 39
                ldir
                ;
                ld      a, (EX_WK_NUL_ATTR_EA5B)
                jr      .write_attr
.reverse        ld      hl, xy2attr(0, 18)
                ld      de, xy2attr(1, 18)
                ld      (hl), ATTR_BLACK
                ld      bc, 39
                ldir
                ;
                ld      a, (EX_WK_NUL_ATTR_EA5B)
                rlca
                rlca
                rlca
                rlca
.write_attr     ld      hl, (mz_enter_name.cursor_addr)
                ld      de, $0800
                add     hl, de
                ld      (hl), a
                ret

wait_key_release:
                call   mz_get_key
                cp     $ff
                ret    z
                jr     wait_key_release

mz_get_key:     ld     a, 0
                call   scan_key
                bit    0, a
                jr     nz, .not_CR
                ld     a, $3d ; CR
                ret
.not_CR         ld     a, 7
                call   scan_key
                bit    2, a
                jr     nz, .char_key
                ld     a, $3e ; BS
                ret
.char_key       ld     a, 1
                ld     ix, scan_line_2
                ld     b, 6
                ;
.loop           push   af
                push   bc
                call   scan_key
                call   bit2num
                ld     a, c
                cp     $ff
                jr     z, .no_key_pressed
                ld     (.index + 2), a
                pop    bc
                pop     af
.index          ld     a, (ix + 1)
                ret
                ;
.no_key_pressed ld     de, 8
                add    ix, de
                pop    bc
                pop    af
                inc    a
                djnz   .loop
                ld     a, $ff
                ret

mz_putc:        ld     hl, (mz_enter_name.cursor_addr)
                ld     (hl), a
                ld     a, (EX_WK_NUL_ATTR_EA5B)
                ld     de, $0800
                add    hl, de
                ld     (hl), a
                ;
                ld     de, -$07ff
                add    hl, de
                ld     (mz_enter_name.cursor_addr), hl
                ld     hl, EX_WK_XPOS_EA64
                inc    (hl)
                ret

scan_line_2:    db     @MZ700:"YZ@()   "
                db     @MZ700:"QRSTUVWX"
                db     @MZ700:"IJKLMNOP"
                db     @MZ700:"ABCDEFGH"
                db     @MZ700:"12345678"
                db     @MZ700:"*+- 09,."

; in A: strobe number
; out A: scan data
scan_key:       ld     ($e000), a
                ld     a, ($e001)
                ret
; in A: scan data
; out C: number 0-7, $FF: no key
bit2num:        ld     b, 8
                ld     c, 0
.loop           bit    7, a
                ret    z
                inc    c
                sla    a
                djnz   .loop
                ld     c, $ff
                ret


; -------------------------------------------------------
mz_stop_sound:  ld      a, 0
                ld      ($e008), a
                ret

mz_msg_stage0:  db      $01,$01,ATTR_CYAN,@MZ700:" DEBT:$000", 0
                db      0
                

; 
; -------------------------------------------------------
mz_init_8253:   ; ch0 mode 3
                ld      a, $36
                ld      ($e007), a
                ; stop beep
                xor     a
                ld      ($e008), a ; stop beep
                ret
; -------------------------------------------------------
mz_play_sound:  ld      c, (hl) ; 音数

.each_sound     inc     hl
                ld      a, (hl)
                ld      (wk_counter), a
                inc     hl
                or      (hl)
                jr      nz, .write_ch0 ; .jr_db48
                ; 分周比が0の場合は音を止める
                ; ld      a, 0
                ; ld      ($e008), a
                jr      .next
                ; 分周比が0以外の場合、音を出す
.write_ch0      ld      a, 1
                ld      ($e008), a

.JR_DB48        ld      a, (hl)
                ld      (wk_counter + 1), a
                ; 分周比書き込み
                call    mz_set_ch0
.next
                inc     hl
                ld      b, (hl)
.JR_DB4D        ; LD      DE,$1D00                        ; [db4d] 11 00 1d
                ; ld      de, $3000
                ld      de, $2800
.JR_DB50        dec     de
                ld      a, d
                or      e
                jr      nz, .jr_db50
                ;
                djnz    .jr_db4d

                ; 音を止める
                ld      a, 0
                ld      ($e008), a

                dec     c
                jr      nz, .each_sound
                ret

mz_set_ch0:     push    hl
                ld      hl, (wk_counter)
                ; 値は1/4 にする
                srl     h
                rr      l
                srl     h
                rr      l
                ld      a, l
                ld      ($e004), a
                ld      a, h
                ld      ($e004), a
                ;
                ld      a, 1
                ld      ($e008), a
                pop     hl
                ld      a, h
                ret
wk_counter:     dw      0

mz_play_money_sound:
                push    hl
                srl     h
                rr      l
                srl     h
                rr      l
                ld      a, l
                ld      ($e004), a
                ld      a, h
                ld      ($e004), a
                ;
                ld      a, 1
                ld      ($e008), a
                pop     hl
                ld      a, h
                ret
; -------------------------------------------------------
mz_check_ESC:   ld      a, 8
                ld      ($e000), a
                ld      a, ($e001)
                and     $80  ; ESC を BREAK で代替
                ret     nz              
                ;
.loop           ; -6-4-2-8 の並びでキー入力を得る
                ld      a, 5
                ld      ($e000), a
                ld      a, ($e001)
                rlca
                and     $55
                jr      z, .loop
                ret
; -------------------------------------------------------
mz_check_key:   ld      a, 5
                ld      ($e000), a
                ld      a, ($e001)
                ld      b, 0
                bit     0, a ; key 8 => B=0
                ret     z
                inc     b
                bit     6, a ; key 2 => B=1
                ret     z
                inc     b
                bit     4, a ; key 4 => B=2
                ret     z  
                inc     b
                bit     2, a ; key 6 => B=3
                ret     z
                ;
                ld      a, 7
                ld      ($e000), a
                ld      a, ($e001)
                ld      b, 0
                bit     5, a
                ret     z
                inc     b
                bit     4, a
                ret     z
                inc     b
                bit     2, a
                ret     z
                inc     b
                bit     3, a
                ret
; -------------------------------------------------------
mz_copy_support:
                sub     3
                ld      e, a
.loop           ldi
                ret     po
                jr      .loop
; -------------------------------------------------------
mz_beep_on:     ld      a, 1
                ld      ($e008) , a
                ret
mz_beep_off:    ld      a, 0
                ld      ($e008) , a
                ret

mz_beep_off_support:
                call    mz_beep_off
                dec     e
                ret

mz_beep_off_support2:
                call    mz_beep_off
                call    CD_DBC4
                ret
mz_tick_sound_support:
                dec     hl
                ld      a, h
                or      l
                jr      nz, mz_tick_sound_support
                jr      mz_beep_off
                
; =======================================================
; ROM ルーチン
; =======================================================
mz_rom_fkey_color:
                ret
mz_rom_width:
                ld      a, b
                ld      (mz_wk_width), a
                ret

 
mz_rom_cls:     ld      hl, $d000
                ld      de, $d001
                ld      bc, 999
                ld      (hl), 0
                ldir
                ;
                ld      hl, $d800
                ld      de, $d801
                ld      bc, 999
.attr           ld      a, ATTR_CYAN ; (EX_WK_NUL_ATTR_EA5B)
                ld      (hl), a
                ldir
                ;
                ret

; 
mz_rom_putc:    push    hl
                push    de
                push    af
                ;
                ld      de, (EX_WK_YPOS_EA63)
                ld      d, 0
                dec     e
                push    de
                pop     hl
                or      a
                ; hl = y * 5
                adc     hl, hl
                adc     hl, hl
                adc     hl, de
                ;
                adc     hl, hl
                adc     hl, hl
                adc     hl, hl
                ; hl = y * 40
                ld      de, (EX_WK_XPOS_EA64)
                ld      d, 0
                ; dec     e
                add     hl, de
                ld      de, $d000
                add     hl, de
                ;
                cp      $f0
                jr      nz, .next
                ld      a, 0
.next
                ld      (hl), a
                ld      de, $0800
                add     hl, de
                ld      a, (EX_WK_NUL_ATTR_EA5B)
                ld      (hl), a
                ;
                ld      a, (EX_WK_XPOS_EA64)
                inc     a
                ld      (EX_WK_XPOS_EA64), a
                ;
                pop     af
                pop     de
                pop     hl
                ret

; -------------------------------------------------------
mz_wk_width:    db      0       ; 画面横幅 36, 40

; -------------------------------------------------------
EX_WK_NUL_CHAR_EA5A:    db      0
EX_WK_NUL_ATTR_EA5B:    db      0       ; 描画カラー
EX_WK_CURSOR_EA5F:      db      0
EX_WK_YPOS_EA63:        db      0
EX_WK_XPOS_EA64:        db      0
; =======================================================
; PCG 初期化
; =======================================================

mz_setup_pcg_pattern:   
                call    .copy_all_cgrom_to_pcg
                call    .write_pcg_pattern
                ret

                ; 一旦全パターンをCGROMの内容で初期化する
.copy_all_cgrom_to_pcg
                ld      de, 0
                ld      bc, 128 * 8
.copy_all_loop
                ld      a, e
                ld      ($e011), a
                ld      a, d
                or      $30
                ld      ($e012), a
                xor     a
                ld      ($e012), a
                inc     de
                dec     bc
                ld      a, b
                or      c
                jr      nz, .copy_all_loop

                ; 元ゲームのデータをPCGに設定する
.write_pcg_pattern
                ld      ix, .pattern_table
                ; pcg addr
.write_char_loop
                ld      e, (ix + 0)
                ld      d, (ix + 1)
                ld      a, e
                or      d
                ret     z
                ; pattern data addr
                ld      l, (ix + 2)
                ld      h, (ix + 3)
                ld      b, 8
.write_pattern_loop
                ld      a, (hl)
                ld      ($e010), a
                ld      a, e
                ld      ($e011), a
                ld      a, d
                or      $10
                ld      ($e012), a
                xor     a
                ld      ($e012), a
                ; next
                inc     de
                inc     hl
                djnz    .write_pattern_loop
                
                ld      de, 4
                add     ix, de
                jr      .write_char_loop

.pattern_table
                dw      ($c0 - $80) * 8, pattern_data + $10  ; $80
                dw      ($c7 - $80) * 8, pattern_data + $18  ; $87
                dw      ($c8 - $80) * 8, pattern_data + $20  ; $88
                ;
                dw      ($d0 - $80) * 8, pattern_data + $28  ; $90
                dw      ($d1 - $80) * 8, pattern_data + $30  ; $91
                dw      ($d2 - $80) * 8, pattern_data + $38  ; $92
                dw      ($d3 - $80) * 8, pattern_data + $40  ; $93
                dw      ($d4 - $80) * 8, pattern_data + $48  ; $94
                dw      ($d5 - $80) * 8, pattern_data + $50  ; $95
                dw      ($d6 - $80) * 8, pattern_data + $58  ; $96
                dw      ($d7 - $80) * 8, pattern_data + $60  ; $97
                dw      ($d8 - $80) * 8, pattern_data + $68  ; $98
                dw      ($d9 - $80) * 8, pattern_data + $70  ; $99
                dw      ($da - $80) * 8, pattern_data + $78  ; $9a
                dw      ($db - $80) * 8, pattern_data + $80  ; $9b
                ;
                dw      ($ce - $80) * 8, pattern_data + $88  ; $ea
                dw      ($cc - $80) * 8, pattern_data + $90  ; $f0
                ;
                dw      ($dc - $80) * 8, pattern_data + $98  ; $f8
                dw      ($dd - $80) * 8, pattern_data + $a0  ; $f9
                dw      ($de - $80) * 8, pattern_data + $a8  ; $fa
                dw      ($df - $80) * 8, pattern_data + $b0  ; $fb
                ; 追加パターン（$c4）を追加
                dw      ($c4 - $80) * 8, .double_cross_pattern
                ; エンドマーカ
                dw      0

.double_cross_pattern
                db      $00, $00, $ff, $00, $00, $ff, $00, $00

#if exists PUBLIC
                include "patch.asm"

                org     $2310
                include "machine.bin", B
#else
patch_program:  ret
                include "src.asm"
#endif

                end     start
