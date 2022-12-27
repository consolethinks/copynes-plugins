;Mapper UNKNOWN 12-in-1 dumper (WLA-DX assembler)
;27/08/2021 - by Consolethinks
;No size measuring, it can overdump

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
             
        .db "UNKNOWN12-in-1MAP\n\r"
        .db "Mapper --- \n\r"  
        .db "by Consolethinks\n\r",0
        .dsb $47,$00 ; 
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
             lda #$02       ;prg size high byte (low is always $00)
             jsr send_byte
             lda #$01       ;send prg
             jsr send_byte
;init mapper
             lda #$00
             sta $8000      ;set to first NROM bank
             sta curr_bank  ;storing PRG bank no.
;dump PRG-ROM
prg_loop:
             jsr prg        ;dump bank
             inc curr_bank  ;set next bank
             lda curr_bank
             asl
             ora #$06
             sta $8000
             lda curr_bank
             cmp #$04       ;if not over max bank -> loop
             bne prg_loop
;send CHR data
             lda #$80       ;chr size middle byte
             jsr send_byte
             lda #$00       ;chr size high byte
             jsr send_byte
             lda #$02       ;send chr
             jsr send_byte
;init mapper
             lda #$00
             sta $8000      ;CHR bank 0
             sta curr_bank  ;storing CHR bank no.
;dump CHR-ROM
chr_loop:
             jsr chr        ;dump bank
             inc curr_bank  ;set next bank
             lda curr_bank
             ;asl
             sta $8000      
             lda curr_bank
             cmp #$04       ;if not over max bank -> loop
             bne chr_loop
;finalize
             lda #000h      ;indicate to copynes that we're done
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             lda #000h
             jsr send_byte  ;send end flag
             rts            ;done


;bank dumpers
             ;dump one 32KiB prg bank
prg:
             ldy #0
             sty temp1_lo
             ldx #$80       ;$80 pages (and for pointer)
             stx temp1_hi   ;set pointer to $8000
             
             
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
