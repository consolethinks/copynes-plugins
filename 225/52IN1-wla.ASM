; 52 in 1 Reader Plugin


;10/29/2000 
;Written by KH
;Version 1.0

;06/09/2020
;rewritten for wla_dx by consolethinks

             ;vectors for standard system calls

.define send_byte   0200h
.define baton       0203h
.define chk_vram    0206h
.define chk_wram    0209h
.define wr_ppu      020ch
.define read_byte   020fh
.define init_crc    0212h
.define do_crc      0215h
.define finish_crc  0218h
                   
.define crc0        0080h
.define crc1        0081h
.define crc2        0082h
.define crc3        0083h
                   
.define temp1       00e0h
.define temp1_lo    00e0h
.define temp1_hi    00e1h
.define temp2       00e2h
.define temp2_lo    00e2h
.define temp2_hi    00e3h
                   
.define temp3       00e4h
.define temp3_lo    00e4h
.define temp3_hi    00e5h
                   
.define temp4       00e6h   ;for wr_bank
.define temp4_lo    00e6h
.define temp4_hi    00e7h
.define temp5       00e8h
.define temp5_lo    00e8h
.define temp5_hi    00e9h
.define x_temp      00eah
.define y_temp      00ebh
                   
.define temp_crc    00ech

.ROMBANKMAP
BANKSTOTAL 2
BANKSIZE $0080
BANKS 1
BANKSIZE $0400
BANKS 1
.ENDRO

.MEMORYMAP
DEFAULTSLOT 0
SLOTSIZE $0080
SLOT 0 $0380
SLOTSIZE $0400
SLOT 1 $0400
.ENDME

.EMPTYFILL $FF

;plugin header that describes what it does
.BANK 0 SLOT 0
.org $00
 .SECTION "header"
    .db "52 in 1"
    .db 0
    .dsb $78,$00
 .ENDS

; plugins have to reside at $0400
.BANK 1 SLOT 1
.org $00

             lda #04h
             jsr send_byte   ;send byte
             
             lda #000h
             jsr send_byte
             lda #010h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
             lda #0
             sta temp2_lo    ;bankswitch ctr
             ldx #32         ;32 32K pages

dump_it2:    lda temp2_lo
             jsr wr_pbank
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi

dump_it:     lda (temp1),y
             jsr send_byte
             iny
             bne dump_it
             jsr baton
             inc temp1_hi
             bne dump_it
             inc temp2_lo
             dex
             bne dump_it2


;determine CHR ROM size (128K)

chronly:             
             lda #000h
             jsr send_byte
             lda #008h
             jsr send_byte
             lda #002h
             jsr send_byte  ;send chr block

             lda #0
             sta temp2_lo    ;bankswitch ctr
             ldx #040h

dump_it3:    lda temp2_lo
             jsr wr_cbank
             lda #020h
             sta temp1_hi
             ldy #0
             sty 2006h
             sty 2006h
             lda 2007h

dump_it4:    lda 2007h
             jsr send_byte
             iny
             bne dump_it4
             jsr baton
             dec temp1_hi
             bne dump_it4
             inc temp2_lo
             dex
             bne dump_it3
             
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte
             lda #000h
             jsr send_byte  ;send end block
             rts

;6000h - a0-a2 = prg, a3/a4 = chr 2,3
;8000h wr d0,1 = chr 0,1


wr_pbank:    lsr a
             ora #080h
             sta temp4_hi
             lda #0
             ror a
             sta temp4_lo
             ldy #0
             sta (temp4),y
             rts

wr_cbank:    sta temp4_lo
             lda #080h
             sta temp4_hi
             ldy #0
             sta (temp4),y
             rts





             ;.fill 0800h-*,0ffh   ;fill rest to get 1K of data

             ;.end
