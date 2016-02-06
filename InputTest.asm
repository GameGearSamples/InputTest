; A Z80 assembler program to test D-pad, Start and other Buttons on a Sega Game Gear
;
; See https://github.com/GameGearSamples/InputTest for details


;--( ROM Setup )---------------------------------------------------------------
;
; see http://www.villehelin.com/wla.txt for WLA-DX directives starting with "."

; SDSC tag and GG rom header
.sdsctag 1.2,"InputTestGameGear","Simple Input Demo","SZR"

; WLA-DX banking setup
.memorymap
defaultslot 0
slotsize $8000
slot 0 $0000
.endme

.rombankmap
bankstotal 1
banksize $8000
banks 1
.endro

.bank 0 slot 0
.org $0000

;--( main )--------------------------------------------------------------------

main:
    di    ; disable interrupts
    im 1  ; interrupt mode 1

    ld sp, $dff0

    call setUpVdpRegisters
    call clearVram
    call initSpriteAttributeTable

    call loadColorPalettes
    call loadTiles
    call printBackgroundTiles

    call turnOnScreen
    
loop4ever:
    jp loop4ever


;--( Subroutines )-------------------------------------------------------------


; setUpVdpRegisters
;

; VDP initialisation data
VdpData:
.db %00000110 ; Reg  0, display and interrupt mode.
.db $80       ; Reg  1, display and interrupt mode.
.db $ff       ; Reg  2, screen map base adress, $ff => $3800
.db $ff       ; Reg  3, n.a., should always be set to $ff
.db $ff       ; Reg  4, n.a., should always be set to $ff
.db $82       ; Reg  5, base adress for sprite attribute table (!!)
.db $ff       ; Reg  6, base adress for sprite patterns
.db $85       ; Reg  7
.db $ff       ; Reg  8
.db $86       ; Reg  9
.db $ff       ; Reg 10
VdpDataEnd:

setUpVdpRegisters:
    ld hl,VdpData
    ld b,VdpDataEnd-VdpData
    ld c,$bf
    otir
    ret


; clearVram
;
; fill Video RAM with 0s
;
clearVram:
    ; set VRAM write address to 0 by outputting $4000 ORed with $0000
    ld hl, $4000
    call prepareVram

    ; output 16KB of zeroes
    ld bc, $4000    ; Counter for 16KB of VRAM
    clearVramLoop:
        ld a,0      ; Value to write
        out ($be),a ; Output to VRAM address, which is auto-incremented after each write
        dec bc
        ld a,b
        or c
        jp nz,clearVramLoop
    ret


; initSpriteAttributeTable

SpriteAttributeTableInit:

; vpos #0 -- #63
.db 60, 50, $d0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0

; 64 unused bytes
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; hpos #0, char code #0 ...
.db 175, 0
.db 185, 0

SpriteAttributeTableInitEnd:

initSpriteAttributeTable:
    ld hl, $3f00
    call prepareVram
    ld hl,SpriteAttributeTableInit ; source of data
    ld bc,SpriteAttributeTableInitEnd-SpriteAttributeTableInit  ; Counter for number of bytes to write
    call writeToVram
    ret

; printBackgroundTiles
;
; write background tiles to VRAM
;

backgroundTilemap: .include "assets/backgroundTilemap.inc"
backgroundTilemapEnd:

printBackgroundTiles:
    ld hl, $38cc ; Game Gear Screen has 102 empty cells on top, 204 words, 204 = $cc
                 ; 3 lines, 6 + 20 + 6 tiles, 3*(6+20+6)+6
    call prepareVram
    ld hl,backgroundTilemap
    ld bc,backgroundTilemapEnd-backgroundTilemap
    call writeToVram
    ret


; loadColorPalettes
;
; load color palettes for background image and sprites from assets to memory
; background palette : $c000
; sprites palette    : $c020
;

backgroundPalette: .include "assets/backgroundPalette.inc"
backgroundPaletteEnd:

spritesPalette: .include "assets/spritesPalette.inc"
spritesPaletteEnd:

loadColorPalettes:

    ld hl, $c000 ; background palette => $c000
    call prepareVram
    ld hl,backgroundPalette ; HL: source of data
    ld bc,backgroundPaletteEnd-backgroundPalette  ; BC: counter for number of bytes to write
    call writeToVram

    ld hl, $c020 ; sprites palette => $c020
    call prepareVram
    ld hl,spritesPalette ; HL: source of data
    ld bc,spritesPaletteEnd-spritesPalette  ; BC: Counter for number of bytes to write
    call writeToVram

    ret

; loadTiles
;
; load tiles for background image and sprites from assets to memory
; background tiles : $4000
; sprite tiles     : $6000

backgroundTiles: .include "assets/backgroundTiles.inc"
backgroundTilesEnd:

spriteTiles: .include "assets/spriteTiles.inc"
spriteTilesEnd:

loadTiles:
    ld hl, $4000 ; background tiles => $4000
    call prepareVram
    ld hl,backgroundTiles ; source of data
    ld bc,backgroundTilesEnd-backgroundTiles ; Counter for number of bytes to write
    call writeToVram

    ld hl, $6000 ; sprite tiles => $6000
    call prepareVram
    ld hl,spriteTiles ; source of data
    ld bc,spriteTilesEnd-spriteTiles ; Counter for number of bytes to write
    call writeToVram
    ret

; turnOnScreen
;
turnOnScreen:
    ld a,%11000000
    out ($bf),a
    ld a,$81
    out ($bf),a
    ret

; prepareVram
;
; Set up vdp to receive data at vram address in HL.
;
prepareVram:
    push af
    ld a,l
    out ($bf),a
    ld a,h
    or $40
    out ($bf),a
    pop af
    ret

; writeToVram
;
; Write BC amount of bytes from data source pointed to by HL.
; Tip: Use prepareVram before calling.
;
writeToVram:
    ld a,(hl)
    out ($be),a
    inc hl
    dec bc
    ld a,c
    or b
    jp nz, writeToVram
    ret