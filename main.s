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

SECTION "Interrupts", ROM0[$40]
  ; VBlank
  push af ; It's crucial to presrve registers, otherwise main code will screw up
  ldh a, [hLCDC]
  ldh [rLCDC], a
  jr VBlankHandler ; This space is too cramped, move out!
  ds 1

  ; LCD
  reti
  ds 7

  ; Timer
  reti
  ds 7

  ; Serial
  reti
  ds 7

  ; Joypad
  reti

VBlankHandler:
  ldh a, [hBGP]
  ldh [rBGP], a
  ldh a, [hOBP0]
  ldh [rOBP0], a
  ldh a, [hOBP1]
  ldh [rOBP1], a
  ldh a, [hSCY]
  ldh [rSCY], a
  ldh a, [hSCX]
  ldh [rSCX], a
  ldh a, [hWY]
  ldh [rWY], a
  ldh a, [hWX]
  ldh [rWX], a

  ; Now, begin operations that can be interrupted
  ; (this is interesting if other interrupts start being used)
  ei

  ; Check if the VBlank handler is being waited for,
  ; or if this is a lag frame
  ldh a, [hVBlankFlag]
  and a
  jr nz, .notLagFrame
  pop af
  ret

.notLagFrame
  ; Perform operations that could break if done in the middle of processing
  push bc

  ; Update joypad
  ld c, LOW(rP1)
  ld a, $20 ; Select directions
  ldh [c], a
REPT 6 ; Read several times in a row because Nintendo's manual says so. The amount is empirical... :|
  ldh a, [c]
ENDR
  or $F0 ; Set the top 4 bits (purpose made clear later)
  swap a ; Put the key's bits in the top 4 bits, as is the de-facto standard
  ld b, a
  ld a, $10
  ldh [c], a
REPT 6
  ldh a, [c]
ENDR
  or $F0 ; Set the top 4 bits again
  xor b ; Mix with the 4 keys in B, and invert all bits at the same time
  ld b, a ; Store this to compute pressed keys

  ldh a, [hHeldButtons] ; Get buttons held on previous frame
  xor b ; Get buttons that changed state since previous frame
  and b ; Changed state + held now => just pressed!
  ldh [hPressedButtons], a

  ld a, b
  ldh [hHeldButtons], a

  pop bc
  pop af
  xor a
  ldh [hVBlankFlag], a
  pop af ; Remove the top entry on the stack to return from `WaitVBlank`
  ret

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
  di ; Disable interrupts so they won't screw up init
  ld sp, wStackBottom


  ; Init video stuff

  ; Turn off LCD
  ; Wait for VBlank without interrupts
.waitVBlank
  ldh a, [rLY]
  cp SCRN_Y
  jr nz, .waitVBlank
  xor a
  ldh [rLCDC],a ; Turn off LCD

  ld a, %11100100 ; Load a normal palette up 11 10 01 00 - dark->light
  ldh [hBGP], a

  ld hl, TileLabel
  ld de, _VRAM ; $8000
  ld bc, TileLabelEnd - TileLabel
  call Memcpy

  ld hl, map
  ld de, _SCRN0 ; $9800
  ld bc, mapEnd - map
  call Memcpy

  ; Turn on LCD again
  ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BGON
  ldh [rLCDC], a
  ldh [hLCDC], a
  ; First frame is fully blank, so do something else in the meantime


  ; Init non-video memory

  ld c, LOW(hClearStart)
  xor a
.clearHRAM
  ldh [c], a
  inc c ; Clear until $FFFF, which is rIE, but we'll overwrite it below
  jr nz, .clearHRAM


  ; Init interrupts

  ; Enable only the VBlank interrupt
  ld a, IEF_VBLANK
  ldh [rIE], a

  ; Finish by re-enabling interrupts and going to the meat of the program

  ; Clear any interrupts that might have accumulated while disabled
  xor a
  ei ; Enable interrupts *after* next instruction
  ldh [rIF], a ; Clear pending interrupts, we don't want any interrupt to misfire


Loop::
  call WaitVBlank ; Wait for v-blank

  ldh a, [hHeldButtons]
  bit PADB_UP, a
  jr z, .dontMoveScreen
  ld hl, hSCX
  inc [hl]
.dontMoveScreen

  jp Loop

;**********************************************************
;* Subroutines
;**********************************************************

SECTION "Support Routines",ROM0

WaitVBlank::
  ld a, 1
  ldh [hVBlankFlag], a
.wait
  halt
  jr .wait

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
