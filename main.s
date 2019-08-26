; System includes
INCLUDE "hardware.inc"


SECTION "Org $00", ROM0[$00]
RST_00:
  jp $100

SECTION "Org $08", ROM0[$08]
RST_08:
  jp $100

SECTION "Org $10", ROM0[$10]
RST_10:
  jp $100

SECTION "Org $18", ROM0[$18]
RST_18:
  jp $100

SECTION "Org $20", ROM0[$20]
RST_20:
  jp $100

SECTION "Org $28", ROM0[$28]
RST_28:
  jp $100

SECTION "Org $30", ROM0[$30]
RST_30:
  jp $100

SECTION "Org $38", ROM0[$38]
RST_38:
  jp $100

SECTION "V-Blank IRQ Vector", ROM0[$40]
VBL_VECT:
  reti

SECTION "LCD IRQ Vector", ROM0[$48]
LCD_VECT:
  reti

SECTION "Timer IRQ Vector", ROM0[$50]
TIMER_VECT:
  reti

SECTION "Serial IRQ Vector", ROM0[$58]
SERIAL_VECT:
  reti

SECTION "Joypad IRQ Vector", ROM0[$60]
JOYPAD_VECT:
  reti

SECTION "Header", ROM0[$100]
  nop
  jp Start

; Allocate space for header, which is filled by RGBFIX
  ds $150 - $104


;********************************************************
;*Program Start
;********************************************************

SECTION "Program Start",ROM0[$0150]
Start::
  di ; Disable interrupts
  ld sp, wStackBottom

  call WaitVBlank ; Wait for v-blank
  xor a
  ldh [rLCDC],a ; Turn off LCD

  ld a, %11100100 ; Load a normal palette up 11 10 01 00 - dark->light
  ldh [rBGP], a

  ld hl, TileLabel
  ld de, _VRAM ; $8000
  ld bc, TileLabelEnd - TileLabel
  call Memcpy

  ld hl, map
  ld de, _SCRN0 ; $9800
  ld bc, mapEnd - map
  call Memcpy

  ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON
  ldh [rLCDC],a

Loop::
  call WaitVBlank ; Wait for v-blank

  ; Read joypad
  ld c, LOW(rP1)
  ld a, $20 ; Reset bit 4 to get directional input
  ldh [c], a
  ; Read several times because we think it's needed
REPT 6
  ldh a, [c]
ENDR

  bit 2, a ; Check if Up is held
  jr nz, .dontMoveScreen
  ld hl, rSCX
  inc [hl]
.dontMoveScreen

  jp Loop

;**********************************************************
;* Subroutines
;**********************************************************

SECTION "Support Routines",ROM0

WaitVBlank::
  ldh a, [rLY] ; Get current scanline
  cp SCRN_Y ; Are we in v-blank yet?
  jr nz, WaitVBlank ; If A-91 != 0 then loop
  ret

Memcpy::
  inc b
  inc c
  jr .firstLoop
.copy
  ld a, [hl+]
  ld [de], a
  inc de
.firstLoop
  dec c
  jr nz,.copy
  dec b
  jr nz,.copy
  ret

TileLabel::
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $00,$00,$00,$00,$00,$00,$00,$00
DB $7D,$C2,$BF,$C0,$7F,$C0,$B7,$C8
DB $7F,$C0,$BD,$C2,$7F,$C0,$BF,$C0
DB $55,$FF,$AA,$FF,$7F,$C0,$BF,$C0
DB $7F,$C0,$BF,$C0,$7F,$C0,$BF,$C0
DB $55,$FF,$AA,$FF,$FF,$00,$FD,$02
DB $DF,$20,$FF,$00,$FB,$04,$FF,$00
DB $55,$FF,$AA,$FF,$FF,$00,$7F,$80
DB $FD,$02,$FF,$00,$BF,$40,$FF,$00
DB $55,$FF,$AA,$FF,$FD,$03,$FE,$03
DB $BD,$43,$EE,$13,$FD,$03,$FE,$03
DB $FF,$AA,$FF,$55,$FF,$AA,$FF,$55
DB $FF,$AA,$FF,$55,$FF,$AA,$FF,$55
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
DB $FF,$00,$FB,$04,$FF,$00,$FF,$00
DB $DF,$20,$FF,$00,$FD,$02,$FF,$00
DB $FF,$00,$FD,$42,$FF,$00,$FF,$00
DB $FF,$00,$FF,$02,$FF,$00,$FF,$00
DB $00,$AA,$00,$55,$00,$AA,$00,$55
DB $00,$AA,$00,$55,$00,$AA,$00,$55
DB $00,$FF,$81,$7E,$C3,$3C,$E7,$18
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00
DB $E7,$18,$C3,$3C,$81,$7E,$00,$FF
DB $BD,$C3,$81,$FF,$BD,$C3,$81,$FF
DB $BD,$C3,$81,$FF,$BD,$C3,$FF,$FF
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00
DB $FF,$00,$FF,$00,$FF,$00,$FF,$00
DB $FF,$FF,$FF,$22,$FF,$22,$FF,$FF
DB $FF,$44,$FF,$44,$FF,$FF,$FF,$00
DB $FF,$FF,$FF,$42,$FF,$42,$FF,$42
DB $FF,$FF,$FF,$24,$FF,$24,$FF,$FF
DB $FF,$24,$FF,$FF,$FF,$42,$FF,$42
DB $FF,$FF,$FF,$24,$FF,$24,$FF,$FF
DB $FF,$FF,$FF,$81,$FF,$81,$FF,$FF
DB $FF,$42,$FF,$42,$FF,$42,$FF,$FF
DB $FF,$FF,$FF,$40,$FF,$40,$FF,$FF
DB $FF,$08,$FF,$08,$FF,$FF,$FF,$24
DB $FF,$FF,$FF,$24,$FF,$24,$FF,$FF
DB $FF,$42,$FF,$42,$FF,$FF,$FF,$24
TileLabelEnd::

map::
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0E,$0D,$0E,$0D,$0E,$0D
DB $0D,$0D,$08,$0E,$0E,$0E,$0E,$0E,$09,$0E
DB $0E,$08,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E
DB $0E,$0D,$0D,$0D,$0E,$0E,$0E,$08,$0E,$0D
DB $0D,$0E,$0E,$0E,$0D,$0D,$08,$0E,$0E,$09
DB $0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E
DB $0D,$0D,$0D,$0D,$0E,$09,$0D,$0D,$0E,$0E
DB $0D,$0D,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$08
DB $0E,$0E,$0E,$0D,$0D,$0E,$0E,$0E,$0D,$0D
DB $0E,$0D,$0D,$0D,$0D,$0E,$09,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0E,$0E,$0E,$09,$0E,$0E,$0E,$0E,$08,$0E
DB $0D,$0D,$09,$0D,$0D,$0D,$0D,$0E,$0E,$0D
DB $0D,$08,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0E,$0D,$0D,$0D,$0E,$0E
DB $0E,$08,$0E,$0E,$0E,$0E,$09,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0E,$08,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0E,$09,$0E,$0E
DB $0E,$09,$0E,$0E,$0E,$09,$0E,$0E,$0E,$0D
DB $0D,$0D,$08,$0E,$0E,$0E,$0E,$0E,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E
DB $0E,$08,$0E,$0E,$0E,$0E,$0E,$08,$0E,$0E
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0E,$0E,$0E,$0E,$0E,$08,$0E,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$09,$0E,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0E,$0E,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0E,$0E,$0E,$0E,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E
DB $08,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0E,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0D,$0E
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0E,$09,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0D,$0E
DB $0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$08,$0E,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0D
DB $0D,$0D,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0E,$0E,$0E,$0D,$0D,$0E,$0D,$0D,$0D,$0D
DB $09,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$0E,$08
DB $0E,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E,$0D,$0D
DB $0D,$0D,$0E,$09,$0E,$0E,$0E,$0E,$08,$0E
DB $0E,$0E,$0E,$0E,$08,$0E,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0E,$0E,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$09,$0E,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0E
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0E,$0E,$08,$0E,$0E,$0E,$0E,$0E,$0E,$0E
DB $08,$0E,$0E,$09,$0D,$0D,$0E,$0E,$0E,$0E
DB $0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$09,$0E,$0E,$0E,$08,$0E,$0E,$0E
DB $0E,$0E,$0E,$0E,$0E,$0E,$0D,$0D,$0E,$08
DB $0D,$0E,$08,$0E,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0E,$08,$0E,$0E,$0D,$0E,$0E,$0D,$0D
DB $0E,$0D,$0D,$0D,$0E,$0E,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0E,$0D,$0D,$0D,$0D,$0E,$0E
DB $0D,$0D,$0E,$0D,$0D,$0D,$0D,$0E,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0E,$0D,$0D,$0D,$08
DB $0E,$08,$0D,$0D,$09,$0E,$0E,$08,$0D,$0E
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$08,$0D
DB $0D,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0E
DB $0E,$08,$0D,$0D,$0D,$0D,$0E,$0E,$0E,$0E
DB $0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D,$0D,$0E
DB $0E,$0E,$0E,$0E,$0E,$0E,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0E,$0D
DB $0D,$0D,$0E,$0E,$0E,$0D,$0D,$0D,$0D,$0D
DB $0D,$08,$0E,$0E,$0E,$08,$0E,$0E,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0E,$0E,$0E,$0E,$0D,$0D,$0E,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0E,$0D,$0E,$0E,$0D,$0D,$0E,$0D
DB $0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D,$0D
DB $0D,$0D,$0D,$0D
mapEnd::

;*** End Of File ***
;_SCRN0
