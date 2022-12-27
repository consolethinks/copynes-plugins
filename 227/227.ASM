;Written by YW
;Version 1.0
;This is an OVERDUMPER for Mapper 227. You must modify the final NES file to
;remove the extraneous banks, if there are any.
             
             ;vectors for standard system calls

.define send_byte       0200h
.define baton           0203h
.define chk_vram        0206h
.define chk_wram        0209h
.define wr_ppu          020ch
.define read_byte       020fh
.define init_crc        0212h
.define do_crc          0215h
.define finish_crc      0218h
.define crc0            0080h
.define crc1            0081h
.define crc2            0082h
.define crc3            0083h


.define temp1           0000h
.define temp1_lo        0000h
.define temp1_hi        0001h
.define temp2           06e2h
.define temp2_lo        06e2h
.define temp2_hi        06e3h
.define temp3           06e4h
.define temp3_lo        06e4h
.define temp3_hi        06e5h

             ;memory mapping
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

.BANK 0 SLOT 0
.org $00

    .SECTION "header"
    ;plugin header that describes what it does
             
             
             
        .db "Mapper 227 overdumper " 
        .db "YW",0

        .dsb $67,$00 ;
    .ENDS

.BANK 1 SLOT 1
.org $00
;mirroring is mapper-controlled
             lda #0
             jsr send_byte   ;send byte


;dump PRG data
             lda #000h
             jsr send_byte
             lda #010h       ;send size
             jsr send_byte
             lda #001h
             jsr send_byte   ;send PRG 
             
;init
             lda #0
             sta temp2
             tay
             sta 08083h,y

prg_loop_a:
             jsr prg
             lda #8
             clc
             adc temp2
             cmp #80h
             beq prg_done_a
             sta temp2
             tay
             sta 08083h,y
             jmp prg_loop_a
prg_done_a:

             lda #0
             sta temp2
             tay
             sta 08183h,y

prg_loop_b:
             jsr prg
             lda #8
             clc
             adc temp2
             cmp #80h
             beq prg_done_b
             sta temp2
             tay
             sta 08183h,y
             jmp prg_loop_b
prg_done_b:
             
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done 


prg:
             ldy #0
             sty temp1_lo
             lda #080h
             sta temp1_hi    ;set pointer to 08000h
             
             ldx #080h       ;080h pages
             
dump_it:     lda (temp1),y    ;dump 1 byte to the PC
             jsr send_byte
             iny
             bne dump_it
             inc temp1_hi    ;dump 1 page
             dex
             bne dump_it
                             ;all pages dumped
             rts


chr:
             ldx #020h
             lda #000h
             sta 02006h
             lda #000h
             sta 02006h     ;set PPU address to 0000h
             lda 02007h     ;read garbage byte
             ldy #0
             
dump_chr:    lda 02007h     ;send 1 byte to the PC
             jsr send_byte
             iny
             bne dump_chr
             jsr baton      ;send 1 page
             dex
             bne dump_chr   ;dump 8K of CHR
             rts
