; system includes
INCLUDE	"hardware.inc"


;*	cartridge header
	SECTION	"Org $00",ROM0[$00]
RST_00:	
	jp	$100

	SECTION	"Org $08",ROM0[$08]
RST_08:	
	jp	$100

	SECTION	"Org $10",ROM0[$10]
RST_10:
	jp	$100

	SECTION	"Org $18",ROM0[$18]
RST_18:
	jp	$100

	SECTION	"Org $20",ROM0[$20]
RST_20:
	jp	$100

	SECTION	"Org $28",ROM0[$28]
RST_28:
	jp	$100

	SECTION	"Org $30",ROM0[$30]
RST_30:
	jp	$100

	SECTION	"Org $38",ROM0[$38]
RST_38:
	jp	$100

	SECTION	"V-Blank IRQ Vector",ROM0[$40]
VBL_VECT:
	reti
	
	SECTION	"LCD IRQ Vector",ROM0[$48]
LCD_VECT:
	reti

	SECTION	"Timer IRQ Vector",ROM0[$50]
TIMER_VECT:
	reti

	SECTION	"Serial IRQ Vector",ROM0[$58]
SERIAL_VECT:
	reti

	SECTION	"Joypad IRQ Vector",ROM0[$60]
JOYPAD_VECT:
	reti
	
	SECTION	"Start",ROM0[$100]
	nop
	jp	Start

	; $0104-$0133 (Nintendo logo - do _not_ modify the logo data here or the GB will not run the program)
	DB	$CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
	DB	$00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
	DB	$BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

	; $0134-$013E (Game title - up to 11 upper case ASCII characters; pad with $00)
	DB	"HELLO WORLD"
		;0123456789A

	; $013F-$0142 (Product code - 4 ASCII characters, assigned by Nintendo, just leave blank)
	DB	"    "
		;0123

	; $0143 (Color GameBoy compatibility code)
	DB	$00	; $00 - DMG 
			; $80 - DMG/GBC
			; $C0 - GBC Only cartridge

	; $0144 (High-nibble of license code - normally $00 if $014B != $33)
	DB	$00

	; $0145 (Low-nibble of license code - normally $00 if $014B != $33)
	DB	$00

	; $0146 (GameBoy/Super GameBoy indicator)
	DB	$00	; $00 - GameBoy

	; $0147 (Cartridge type - all Color GameBoy cartridges are at least $19)
	DB	$00	; $00 - ROM Only

	; $0148 (ROM size)
	DB	$00	; $00 - 256Kbit = 32Kbyte = 2 banks

	; $0149 (RAM size)
	DB	$00	; $00 - None

	; $014A (Destination code)
	DB	$00	; $01 - All others
			; $00 - Japan

	; $014B (Licensee code - this _must_ be $33)
	DB	$33	; $33 - Check $0144/$0145 for Licensee code.

	; $014C (Mask ROM version - handled by RGBFIX)
	DB	$00

	; $014D (Complement check - handled by RGBFIX)
	DB	$00

	; $014E-$014F (Cartridge checksum - handled by RGBFIX)
	DW	$00


;********************************************************
;*	Program Start
;********************************************************

	SECTION "Program Start",ROM0[$0150]
Start::
	di			          ;disable interrupts
	ld	sp,$FFFE	    ;set the stack to $FFFE
	call WaitVBlank	  ;wait for v-blank

	ld	a,0
	ldh	[rLCDC],a	    ;turn off LCD 

	ld	a,%11100100	  ;load a normal palette up 11 10 01 00 - dark->light
	ldh	[rBGP],a	    ;load the palette

  call ClearMap	    ;clear screen

	call ClearVRAM    ;wipe VRAM

	ld hl, TileLabel
	ld de, _VRAM ;$8000
	ld bc, TileLabelEnd - TileLabel
  call copy

	ld hl, map
	ld de, _SCRN0 ;$9800
	ld bc, mapEnd - map
  call copy

	ld	a,%10010001		;  =$91 
	ldh	[rLCDC],a	    ;turn on the LCD, BG, etc

Loop::
  call WaitVBlank	  ;wait for v-blank

	ld hl, $FF00      ; I/O address for controls
	ld [hl], $20      ; set bit 5 to get joypad input
	
  bit 2, [hl]       ; check if up on the joypad is pressed
  bit 2, [hl]       ; check if up on the joypad is pressed
  bit 2, [hl]       ; check if up on the joypad is pressed
  bit 2, [hl]       ; check if up on the joypad is pressed
	
	jp z, MoveScreen  ; if 0(pressed) jump to label

	jp Loop

;***************************************************************
;* Subroutines
;***************************************************************

	SECTION "Support Routines",ROM0

WaitVBlank::
	ldh	a,[rLY]		      ;get current scanline
	cp	$91			        ;Are we in v-blank yet?
	jr	nz,WaitVBlank	  ;if A-91 != 0 then loop
	ret				          ;done
	
ClearMap::
  ld hl, _SCRN0
  ld bc, SCRN_Y_B * SCRN_VX_B  ; Only clear a screen's worth of VRAM
  call ClearLoop
  ret

ClearVRAM::
	ld hl, _VRAM
	ld bc, 32 * 32
  call ClearLoop
	ret

ClearLoop::
  xor a ; A is trashed on every loop iteration, restore it
  ld [hli], a
  dec bc ; This doesn't affect flags
  ld a, b
  or c
  jr nz, ClearLoop	
	ret
	
copy::
	inc	b
	inc	c
	jr	.skip
.copy
	ld	a,[hl+]
	ld	[de],a
	inc	de
.skip
	dec	c
	jr	nz,.copy
	dec	b
	jr	nz,.copy
	ret

MoveScreen::
  ld a, [rSCX]
	inc a  	
  ld hl, rSCX
  ld [hl], a
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