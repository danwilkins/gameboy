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
ld bc, $1A				; Sudoku board is 5 sprites width so this is 32-5 (for line wrap)
ld de, SudokuBoard		; Load the sudoku board sprite order address
.copyBoard
	ld a, [de]			; Get the current sudoku board sprite index value
	inc de				; Go to the next sprite index
	cp a, $FE			; If this is a new line (Randomly selected $FE to denote this)
	jr z, .nextLine		; 	then go to next line logic
	cp a, $FF			; If this is the end of the sudoku board
	jr z, .bgSet		;	then go to setting the background color
	ld [hli], a			; Otherwise, copy the sprite into VRAM to display it and increment
	jr .copyBoard		; Continue to copy the rest of the board
.nextLine
	add hl, bc			; Add the line offset (32-5) to our current address counter
	jr .copyBoard		; Continue to copy the rest of the board

.bgSet
	ld a, %11100100		; Pick a background color
	ld [rBGP], a		; Set the background color

xor a					; Zero out a register
ld [rSCY], a			; Set scroll y to 0
ld [rSCX], a			; Set scroll x to 0
ld [rNR52], a			; Turn off sound (a is still 0)

ld a, %10000001			; Bit 7 = screen on, bit 0 = background on
ld [rLCDC], a			; Set LCD flags

xor a
.lockup
	cp a, $00			; Check to see if v-blank has happened (a is 0 on vblank)
	jr nz, .lockup		; If not, then return to waiting for v-blank
	di					; Disable interrupts so v-blank doesn't bother us
	call .joy_con		; Get the value of the joy-con and store it into a
	call .read			; Use the value of a to print out the inputs to the screen
	ei					; Enable interrupts again
	ld a, %00000001		; We only want the v-blank interrupt
	ld [rIE], a			; Set the interrupts flags
jr .lockup				; Game lockup loop

.joy_con
	ld a, $20			; Set the flag for checking the d-pad
	ld [rP1], a			; Tell the device we want to read the d-pad
	ld a, [rP1]			; Read the d-pad
	cpl 				; Complement a
	and $0F				; Only get first 4 bits
	swap a				; Swap the low 4 bits with the high 4 bits
	ld b, a				; Copy the d-pad inputs to b for now
	ld a, $10			; Set the flag for checking the other buttons
	ld [rP1], a			; Tell the device we want to read the other buttons
	ld a, [rP1]			; Read the other buttons
	cpl					; Complement a
	and $0F				; Only get first 4 bits
	or b				; Combine d-pad and other buttons into single byte
	ret					; Return to caller

.read
	ld b, a				; Get a backup of current pressed buttons
	xor a				; Set a to 0
	ld [rLCDC], a		; Turn off the LCD by writing 0
	ld hl, _SCRN0
	ld de, Inputs
	; Going to do this the dumb way for testing
		ld a, b					; Restore inputs back into a
		and JOY_LEFT			; Check if the left button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_UP				; Check if the up button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_RIGHT			; Check if the right button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_DOWN			; Check if the down button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_A				; Check if the a button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_B				; Check if the b button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_START			; Check if the start button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
		inc de					; Go to the next letter to write
		ld a, b					; Restore inputs back into a
		and JOY_SELECT			; Check if the select button was pressed
		call z, .erase_sprite	; If not erase the sprite
		call nz, .write_sprite	; If so write the corresponding letter
	; End of dumb
	ld a, %10000001			; Bit 7 = screen on, bit 0 = background on
	ld [rLCDC], a			; Set LCD flags
	ret						; Return to caller
.erase_sprite
	ld a, $00				; Set a blank sprite index
	ld [hli], a				; Write the blank sprite to VRAM
	ret						; Return to caller
.write_sprite
	ld a, [de]				; Set the current input sprite index
	ld [hli], a				; Write the current input sprite to VRAM
	ret						; Return to caller

SECTION "Font", ROM0			; No need to declare where to put this code, let assembler pick
FontTiles:
INCBIN "font.chr"				; Copy contents of file to right here
FontTilesEnd:

SECTION "Strings", ROM0			; No need to declare where to put this code, let assembler pick
Inputs:
    db "LURDABSE"				; Define byte (ascii string) 0 is string null terminator

SECTION "Sudoku Board", ROM0	; No need to declare where to put this code, let assembler pick
SudokuBoard:
	; $00 = blank, $01 = cross, $02 = vertical, $03 = horizontal
	db $00, $02, $00, $02, $00, $FE,
	db $03, $01, $03, $01, $03, $FE,
	db $00, $02, $00, $02, $00, $FE,
	db $03, $01, $03, $01, $03, $FE,
	db $00, $02, $00, $02, $00, $FE,
	db $FF