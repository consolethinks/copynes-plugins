;Mapper 250 dumper plugin, based on TXROM1.ASM by KH and BootGod

;06/11/00 
;Written by KH
;Version 1.0

;12/17/05
;Bugfix by BootGod
;Fixed dumping of 32K PRG ROM

;08/12/2020
;rewritten for wla-dx by Consolethinks

;27/12/2022
;Adapted the script to Mapper 250 (NITRA) by Consolethinks

;If the PRG is 32K, the var romsiz = 1 (# of 32K banks), when it calcs the size to send
;back to client, it LSR's romsiz making it 0. After telling the client, it does a series of
;ASL's to get the # of 8K banks, but in this case, it's not doing anything because it's 0.
;So to fix, it checks if it's 0 and sets it to 4 if so (4 x 8K = 32K)
             
             ;vectors for standard system calls

.define send_byte   0200h
.define baton       0203h
.define chk_vram    0206h
.define chk_wram    0209h
.define wr_ppu      020ch
                    
.define temp1       00e0h
.define temp1_lo    00e0h
.define temp1_hi    00e1h
.define temp2       00e2h
.define temp2_lo    00e2h
.define temp2_hi    00e3h
.define temp3       00e4h
.define temp3_lo    00e4h
.define temp3_hi    00e5h
.define temp4       00e6h
.define romsiz      00e7h
.define curr_bank   00e8h
.define regadr_lo   00e9h
.define regadr_hi   00eah

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
        .db "Mapper 250 "
        .db "Nitra \n\r"
        .db "32K-512K PRG, "
        .db "32K-256K CHR\n\r",0
        .dsb $3C,$00
    .ENDS
;all plugins must reside at 400h
.BANK 1 SLOT 1
.org $00

             lda #00h
             sta 0a000h

             ldx #02fh
             
ddloop:      txa
             jsr wr_ppu
             lda #0
             sta 2007h
             dex
             cpx #01fh
             bne ddloop   ;load first byte of 2000, 2400, 2800, 2c00 w/ 00h
             ldx #0       ;H mirroring
             lda #020h
             jsr wr_ppu
             lda #055h
             sta 2007h
             lda #028h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             beq mirrord
             inx          ;V mirroring
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             beq mirrord
             inx          ;4 screen
             bne got_mir
             
mirrord:     lda #01h
             sta 0a000h
             lda #024h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne got_mir
             lda #00h
             sta 0a000h
             lda #028h
             jsr wr_ppu
             lda 2007h
             lda 2007h
             cmp #055h
             bne got_mir  ;test for MMC3 mirror control
             ldx #04h

got_mir:     txa
             jsr send_byte
             
             lda #1
             sta romsiz
             ldy #004h
             jsr comp_bank
             beq gotit
             asl romsiz
             ldy #008h
             jsr comp_bank
             beq gotit
             asl romsiz
             ldy #010h
             jsr comp_bank
             beq gotit
             asl romsiz
             ldy #020h
             jsr comp_bank
             beq gotit
             asl romsiz

gotit:       lsr romsiz
             lda #0
             ror a
             sta temp3_hi
             jsr send_byte
             lda romsiz
             jsr send_byte
             lda romsiz
             asl a
             asl a
             asl a
             sta temp3_lo    ;# 8K banks

             cmp #0          ;if PRG is 32K, fix # 8K banks
             bne send_hdr
             lda #4
             sta temp3_lo

send_hdr:    lda #01h
             jsr send_byte

send_plp:    ldy #$00
             lda #6
             sta 08006h
             lda #$84
             sta regadr_hi
             lda temp3_hi
             sta regadr_lo
             sta (regadr_lo),Y
             inc temp3_hi
             lda #0
             sta temp1_lo
             lda #080h
             sta temp1_hi
             ldx #020h

send_plp2:   lda (temp1),y
             jsr send_byte
             iny
             bne send_plp2
             inc temp1_hi
             jsr baton
             dex
             bne send_plp2    ;send 8K bank
             dec temp3_lo
             bne send_plp
             

;read CHR stuff             
;try VRAM
             lda #01h
             sta 0a000h   ;I don't know why, but it doesn't work without this

             lda #82h
             sta 08082h
             lda #00h
             sta 08400h

             jsr chk_vram
             bne no_ram3
             jmp no_chr
             
             
no_ram3:     lda #1
             sta romsiz
             ldy #020h
             jsr comp_bank2
             beq gotit2
             asl romsiz
             ldy #040h
             jsr comp_bank2
             beq gotit2
             asl romsiz
             ldy #080h
             jsr comp_bank2
             beq gotit2
             asl romsiz
             
gotit2:      lda romsiz
             pha
             lsr romsiz
             lda #0
             sta temp3_hi    ;start out at 0
             ror a
             jsr send_byte
             lda romsiz
             jsr send_byte
             lda #02h
             jsr send_byte
             pla
             asl a
             asl a
             asl a
             asl a
             asl a  ;1,2,4,8 == 20,40,80,00
             sta temp3_lo

send_plp3:   lda #$82
             sta $8082
             lda #$84
             sta regadr_hi
             lda temp3_hi
             sta regadr_lo
             ldy #$00
             sta (regadr_lo),Y  ;current bank
             lda #00h
             jsr wr_ppu
             lda 2007h          ;set up PPU
             ldx #4

send_plp4:   lda 2007h
             jsr send_byte
             iny
             bne send_plp4
             jsr baton
             dex
             bne send_plp4
             inc temp3_hi
             dec temp3_lo
             bne send_plp3
             
;check for save-game RAM and back it up if it exists             

no_chr:      lda #080h
             sta 0A400h
             
             jsr chk_wram
             bne no_ram2
             lda #020h
             tax
             jsr send_byte
             lda #0
             jsr send_byte
             lda #3
             jsr send_byte
             lda #0
             sta temp1_lo
             tay
             lda #060h
             sta temp1_hi
            
sr_lp:       lda (temp1),y
             jsr send_byte
             iny
             bne sr_lp
             inc temp1_hi
             jsr baton
             dex
             bne sr_lp
             lda #000h
             sta 0A400h
             

no_ram2:     lda #0
             jsr send_byte
             lda #0
             jsr send_byte
             lda #0
             jsr send_byte

             rts


;y = bank to compare
;z=same
comp_bank:   ldx #0
             stx temp3_lo    ;lower pointer
             sty temp3_hi    ;upper pointer
             sty temp4       ;# blocks to compare

cb_loop:     lda #000h       ;init pointers
             sta temp1_lo
             sta temp2_lo
             lda #080h
             sta temp1_hi
             lda #0a0h
             sta temp2_hi    ;pointers 1,2 to 8000/a000
             lda #$06
             sta $8006
             lda #$84
             sta regadr_hi
             lda temp3_lo
             sta regadr_lo
             ldy #$00
             sta (regadr_lo),y
             lda #$07
             sta $8007
             lda temp3_hi
             sta regadr_lo
             sta (regadr_lo),y      ;write in current banks
             ldx #020h

cb_loop2:    lda (temp1),y
             cmp (temp2),y
             bne diff
             iny
             bne cb_loop2
             inc temp1_hi
             inc temp2_hi
             dex
             bne cb_loop2
             inc temp3_lo
             inc temp3_hi
             dec temp4
             bne cb_loop

diff:        rts

;y = bank to compare
;z=same
;for CHR
comp_bank2:  ldx #0
             stx temp3_lo    ;lower pointer
             sty temp3_hi    ;upper pointer
             sty temp4       ;# blocks to compare

cc_loop:     ldy #$00
             lda #$82
             sta $8082
             lda #$84
             sta regadr_hi
             lda temp3_lo
             sta regadr_lo
             sta (regadr_lo),y
             lda #$83
             sta $8083
             lda temp3_hi
             sta regadr_lo
             sta (regadr_lo),y      ;write in current banks
             ldx #004h
             lda #000h
             sta curr_bank   ;reset current bank

cc_loop2:    ldy #0
             lda curr_bank
             sta 2006h       ;pointer =000h
             sty 2006h
             lda 2007h       ;garbage read

ql:          lda 2007h
             sta 0300h,y
             iny
             bne ql          ;load 256 bytes for testing
             lda curr_bank
             clc
             adc #4
             inc curr_bank
             sta 2006h       ;pointer =400h
             sty 2006h
             lda 2007h       ;garbage read

cc_loop3:    lda 2007h
             cmp 0300h,y
             bne diff2
             iny
             bne cc_loop3
             dex
             bne cc_loop2
             inc temp3_lo
             inc temp3_hi
             dec temp4
             bne cc_loop

diff2:       rts


             ;.fill 0800h-*,0ffh   ;fill rest to get 1K of data

             ;.end
