;Mapper for 820401-C board (WLA-DX assembler)
;04/03/2021 - by Consolethinks
;No size measuring, it can overdump (unlikely though)

             ;standard system calls

.define send_byte   $0200
.define baton       $0203
.define chk_vram    $0206
.define chk_wram    $0209
.define wr_ppu      $020c
.define read_byte   $020f

.define init_crc    $0212
.define do_crc      $0215
.define finish_crc  $0218
.define crc0        $0080
.define crc1        $0081
.define crc2        $0082
.define crc3        $0083

             ;variables

.define temp1       $00e0
.define temp1_lo    $00e0
.define temp1_hi    $00e1
.define temp2       $00e2
.define temp2_lo    $00e2
.define temp2_hi    $00e3
.define temp3       $00e4
.define temp3_lo    $00e4
.define temp3_hi    $00e5
.define temp4       $00e6
.define romsiz      $00e7
.define curr_bank   $00e8
.define out_curr_bank   $00e9

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
             ;plugin header that describes what it does

.BANK 0 SLOT 0
.org $00

    .SECTION "header"
             
        .db "Mapper 820401-C \n\r"  
        .db "512/512k dumper\n\r"
        .db "by Consolethinks\n\r",0
        .dsb $44,$00 ; 
    .ENDS


             ;all plugins must reside at 400h
.BANK 1 SLOT 1
.org $00

;mapper sets mirroring -> 0
             lda #$00       ;set mirroring
             jsr send_byte
;send PRG data
             lda #$00       ;prg size middle byte
             jsr send_byte
             lda #$08       ;prg size high byte (low is always $00)
             jsr send_byte
             lda #$01       ;send prg
             jsr send_byte
; PRG dumping
             lda #$80           ; prg init
             sta $A001
             
             lda #$00
             sta out_curr_bank
             lda #$01
             tay
             sta $6800,y
             
prgb_init:   ldx #$06           ; inner bank switch
             ldy #$00
             stx $8000
             sty $8001
             sty curr_bank
             inx
             iny
             stx $8000
             sty $8001
             
prg_loop:    jsr prg
             inc curr_bank
             
             ldx #$06
             lda curr_bank
             clc
             rol
             tay
             stx $8000
             sty $8001
             inx
             iny
             stx $8000
             sty $8001
             lda curr_bank
             cmp #$08
             bne prg_loop
             
             inc out_curr_bank  ; outer bank switch
             lda out_curr_bank
             clc
             rol
             rol
             rol
             rol
             rol
             rol
             ora #$01
             tay
             sta $6800,y
             lda out_curr_bank
             cmp #$04
             bne prgb_init
             
             
             lda #$00
             jsr send_byte
             lda #$08
             jsr send_byte
             lda #$02
             jsr send_byte  ; send chr
             
             lda #$00           ; chr init
             sta out_curr_bank
             lda #$01
             tay
             sta $6800,y
             
chrb_init:   lda #$00           ; inner bank switch
             sta curr_bank
             jsr chr_set_8k

chr_loop:    jsr chr
             inc curr_bank
             lda curr_bank
             jsr chr_set_8k
             lda curr_bank
             cmp #$10
             bne chr_loop
             
             inc out_curr_bank  ; outer bank switch
             lda out_curr_bank
             clc
             rol
             rol
             rol
             rol
             rol
             rol
             ora #$01
             tay
             sta $6800,y
             lda out_curr_bank
             cmp #$04
             bne chrb_init
             
             
             lda #$00           ; finished
             jsr send_byte
             lda #$00
             jsr send_byte
             lda #$00
             jsr send_byte
             
             rts
             
chr_set_8k:  ; reg A contains the 8k bank
             clc
             rol
             rol
             rol
             ldx #$00
             tay
             stx $8000
             sty $8001
             inx
             iny
             iny
             stx $8000
             sty $8001
             iny
    inloop:  inx
             iny
             stx $8000
             sty $8001
             txa
             cmp #$05
             bne inloop
             rts
;bank dumpers
             ;dump one 16KiB prg bank
prg:
             ldy #0
             sty temp1_lo
             ldx #$80       
             stx temp1_hi   ;set pointer to $8000
             ldx #$40       ;40 pages (16k)
             
             
dump_prg:    lda (temp1),y  ;send 1 byte
             jsr send_byte
             iny
             bne dump_prg
             jsr baton      ;sent 256bytes (1 page) (I think it's just for the unused LCD routine)
             inc temp1_hi   ;dumped xx## range, increase higher part of pointer
             dex
             bne dump_prg
                            ;$8000-$ffff dumped
             rts

             ;dump one 8KiB chr bank
chr:
             ldx #$20       ; 256B*32=8192B=8K
             ldy #$00
             sty $2006
             sty $2006      ;set PPU address to 0000h
             lda $2007      ;read garbage byte
             
dump_chr:    lda $2007      ;send 1 byte
             jsr send_byte
             iny
             bne dump_chr
             jsr baton      ;sent 256bytes (1 page) (I think it's just for the unused LCD routine)
             dex
             bne dump_chr   ;loop until dump'd full CHR bank (8k)
             rts
