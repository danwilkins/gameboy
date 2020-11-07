INCLUDE "hardware.inc"

CURSOR		EQU $04
JOY_LEFT	EQU $20
JOY_UP		EQU $40
JOY_RIGHT	EQU $10
JOY_DOWN	EQU $80
JOY_A		EQU $01
JOY_B		EQU $02
JOY_START	EQU $08
JOY_SELECT	EQU $04

; Helpful section name
SECTION "Header", ROM0[$100]	; Program starts at $100
EntryPoint: ; This is where execution begins
	ei				; Enable interrupts
	jp Start		; Leave this tiny space

; Dump $4C (76) 0s in memory starting from $104 (current location)
REPT $150 - $104
	db 0
ENDR

SECTION "V Blank", ROM0[$0040]	; The address for V-Blank interrupt routine
ld a, $00
;inc a		; Increment the scroll
reti		; Return and reset the interrupt flag

SECTION "Game code", ROM0	; No need to declare where to put this code, let assembler pick
Start:
	ld a, %00000001		; We only want the v-blank interrupt
	ld [rIE], a			; Set the interrupts flags
.waitVBlank				; Turn off the LCD
	ld a, [rLY]			; Read the LCD's drawing status
	cp 144				; Check if the LCD is past VBlank
	jr c, .waitVBlank	; Jump if clear is set to wait for v-blank

xor a					; Set a to 0
ld [rLCDC], a			; Turn off the LCD by writing 0
ld hl, $9000			; Tile location to write to ($8000-$9FFF is VRAM)
ld de, FontTiles		; Start address for font tiles
ld bc, FontTilesEnd - FontTiles	; Length of font tiles

.copyFont
	ld a, [de]			; Grab 1 byte from the source
	ld [hli], a			; Place it at the destination, incrementing hl
	inc de				; Move to next byte
	dec bc				; Decrement count
	ld a, b				; Check if count is 0, since `dec bc` doesn't update flags
	or c				; a OR c (should be 0 if both are 0)
	jr nz, .copyFont	; Loop if not done yet

ld hl, _SCRN0+$20		; This will print the string at the top-left corner of the screen
ld bc, $1A
ld de, SudokuBoard
.copyBoard
	ld a, [de]
	inc de
	cp a, $FE
	jr z, .nextLine
	cp a, $FF
	jr z, .bgSet
	ld [hli], a
	jr .copyBoard
.nextLine
	add hl, bc
	jr .copyBoard

.bgSet
	ld a, %11100100		; Pick a background color
	ld [rBGP], a		; Set the background color

.drawCursor
	ld a, $04
	ld [_SCRN0], a		; Cursor value is 4

xor a					; Zero out a register
ld [rSCY], a			; Set scroll y to 0
ld [rSCX], a			; Set scroll x to 0
ld [rNR52], a			; Turn off sound (a is still 0)

ld a, %10000001			; Bit 7 = screen on, bit 0 = background on
ld [rLCDC], a			; Set LCD flags

xor a
.lockup
	cp a, $00
	jr nz, .lockup
	di
	call .joy_con
	call .read
	xor a
	ei
	ld a, %00000001		; We only want the v-blank interrupt
	ld [rIE], a			; Set the interrupts flags
jr .lockup				; Game lockup loop

.joy_con
	ld a, $20
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]		; Wait a few cycles
	cpl 			; Complement a
	and $0f			; Only get first 4 bits
	swap a
	ld b, a
	ld a, $10
	ld [rP1], a
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	ld a, [rP1]
	cpl
	and $0f
	or b
	ret

.read
	ld b, a
	xor a					; Set a to 0
	ld [rLCDC], a			; Turn off the LCD by writing 0
	ld a, b
	ld hl, _SCRN0
	; Going to do this the dumb way for testing
		ld de, Inputs
		and JOY_LEFT
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_UP
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_RIGHT
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_DOWN
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_A
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_B
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_START
		call z, .erase_sprite
		call nz, .write_sprite
		inc de
		ld a, b
		and JOY_SELECT
		call z, .erase_sprite
		call nz, .write_sprite
	; End of dumb
	ld a, %10000001			; Bit 7 = screen on, bit 0 = background on
	ld [rLCDC], a			; Set LCD flags
	ret

.erase_sprite
	ld a, $00
	ld [hli], a
	ret
.write_sprite
	ld a, [de]
	ld [hli], a
	ret

SECTION "Font", ROM0	; No need to declare where to put this code, let assembler pick
FontTiles:
INCBIN "font.chr"		; Copy contents of file to right here
FontTilesEnd:

SECTION "Strings", ROM0	; No need to declare where to put this code, let assembler pick
Inputs:
    db "LURDABSE"		; Define byte (ascii string) 0 is string null terminator

SECTION "Sudoku Board", rom0
SudokuBoard:
	; $00 = blank, $01 = cross, $02 = vertical, $03 = horizontal
	db $00, $02, $00, $02, $00, $FE,
	db $03, $01, $03, $01, $03, $FE,
	db $00, $02, $00, $02, $00, $FE,
	db $03, $01, $03, $01, $03, $FE,
	db $00, $02, $00, $02, $00, $FE,
	db $FF