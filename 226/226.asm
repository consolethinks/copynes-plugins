;Mapper 226 dumper (WLA-DX assembler)
;21/03/2021 - by Consolethinks
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
        .db "Mapper 226 \n\r"  
        .db "by Consolethinks\n\r",0
        .dsb $5C,$00 ; 
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
             lda #$20       ;prg size high byte (low is always $00)
             jsr send_byte
             lda #$01       ;send prg
             jsr send_byte
;init mapper
             lda #$00       ;NROM-256
             sta $8000
             sta $8000
             sta curr_bank  ;storing PRG bank no.
;dump PRG-ROM
prg_loop:
             jsr prg        ;dump bank
             inc curr_bank  ;set next bank
             lda curr_bank
             clc
             rol
             and #$1E
             sta temp3
             lda curr_bank
             and #$10
             clc
             rol
             rol
             rol
             ora temp3
             sta $8000
             lda curr_bank
             and #$20
             cmp #$01
             rol $8001
             lda curr_bank
             cmp #$40       ;1MB, if not over max bank -> loop
             bne prg_loop
;finalize
             lda #$00       ;indicate to copynes that we're done
             jsr send_byte  ;send end flag
             lda #$00
             jsr send_byte  ;send end flag
             lda #$00
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
