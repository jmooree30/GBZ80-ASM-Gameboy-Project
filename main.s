; System includes
INCLUDE "hardware.inc"
INCLUDE "defines.inc"
INCLUDE "assets/tiles.z80"
INCLUDE "assets/map.z80"


SECTION "Rst $00", ROM0[$00]
RST_00:
  jp $100

SECTION "Rst $08", ROM0[$08]
WaitVBlank:
  ld a, 1
  ldh [hVBlankFlag], a
.wait
  halt
  jr .wait

SECTION "Rst $10", ROM0[$10]
RST_10:
  jp $100

SECTION "Rst $18", ROM0[$18]
RST_18:
  jp $100

SECTION "Rst $20", ROM0[$20]
RST_20:
  jp $100

SECTION "Rst $28", ROM0[$28]
RST_28:
  jp $100

SECTION "Rst $30", ROM0[$30]
RST_30:
  jp $100

SECTION "Rst $38", ROM0[$38]
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
  ; Copies values from shadow registers into their corresponding copies
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

  ld a, HIGH(wShadowOAM)
  call hOAMDMA

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

  ld hl, Map
  ld de, _SCRN0 ; $9800
  ld bc, MapEnd - Map
  call Memcpy

  ; Turn on LCD again
  ld a, LCDCF_ON | LCDCF_BG8000 |LCDCF_OBJON | LCDCF_BGON
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

  ld hl, OAMDMA
  ld bc, (OAMDMAEnd - OAMDMA) << 8 | LOW(hOAMDMA)
.copyDMARoutine
  ld a, [hli]
  ldh [c], a
  inc c
  dec b
  jr nz, .copyDMARoutine

  ; Clear shadow OAM, so we won't get garbage sprites until we init all of it
  ; Clearing Y positions is enough, assuming the rest of the code will init sprites wholly
  ld hl, wShadowOAM + $A0
.clearOAM
  ld a, l
  sub 4
  ld l, a
  ld [hl], 0
  jr nz, .clearOAM

  ; Counter for animations
  ld a, 30
  ld [wCounter], a

  ; Init interrupts

  ; Enable only the VBlank interrupt
  ld a, IEF_VBLANK
  ldh [rIE], a

  ; Finish by re-enabling interrupts and going to the meat of the program

  ; Clear any interrupts that might have accumulated while disabled
  xor a
  ei ; Enable interrupts *after* next instruction
  ldh [rIF], a ; Clear pending interrupts, we don't want any interrupt to misfire
  
  ; Byte 0 is the Y position
  ld a, 24
  ld [wShadowOAM], a
  ; Byte 1 is the X position
  ld a, 32
  ld [wShadowOAM+1], a
  ; Byte 2 is the tile ID
  ld a, $15
  ld [wShadowOAM+2], a
  ; Byte 3 are the attributes
  xor a
  ld [wShadowOAM+3], a

Loop::
  rst wait_vblank
  call UpdateMovements
  call Animate
  call Camera
  jp Loop

;**********************************************************
;* Subroutines
;**********************************************************

SECTION "Support Routines", ROM0

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

OAMDMA:
  ldh [rDMA], a ; DMA $FF46
  ld a, 40
.wait
  dec a
  jr nz, .wait
  ret
OAMDMAEnd:

UpdateMovements:
  ldh a, [hHeldButtons]
.moveUp
  bit PADB_UP, a
  jr z, .moveDown
  ld hl, wShadowOAM
  dec [hl]
.moveDown
  bit PADB_DOWN, a
  jr z, .moveRight
  ld hl, wShadowOAM
  inc [hl]
.moveRight
  bit PADB_RIGHT, a
  jr z, .moveLeft
  ld hl, wShadowOAM+1
  inc [hl]
.moveLeft
  bit PADB_LEFT, a
  jr z, .dontMoveScreen
  ld hl, wShadowOAM+1
  dec [hl]
.dontMoveScreen
ret

Animate:
  ; wCounter is set to 30 on init
  ; We will only perform an animation every 30 frames
  ld a, [wCounter]
  cp 0
  ; If not 0, skip animation logic
  jp nz, .waitForCounter 
  ; If counter was 0, reset counter and perform animation logic
  ld a, 30
  ld [wCounter], a
  ; Logic to switch out the current sprite tile
  ld hl, wShadowOAM+2
  ld a, [hl]
  cp $15
  jr z, .switchTile
  ld [hl], $15
  ret 
.switchTile
  ld [hl], $16
  ret
; Decrement counter by 1 and return
.waitForCounter
  ld a, [wCounter]
  dec a
  ld [wCounter], a
  ret

Camera:
  ld a, [wShadowOAM+1]
  cp 152
  jr nc, .moveCamera
  ret 
.moveCamera
  ld hl, hSCX
  ld [hl], 144
  ld hl, wShadowOAM+1
  ld [hl], 1
  ret

;*** End Of File ***
;_SCRN0
