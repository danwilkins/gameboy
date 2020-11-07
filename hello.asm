INCLUDE "hardware.inc"

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
inc a	; Increment the scroll
reti	; Return and reset the interrupt flag

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

ld hl, $9800			; This will print the string at the top-left corner of the screen
ld de, HelloWorldStr	; Load the address of the HelloWorldStr data into de

.copyString
	ld a, [de]			; Load value at memory pointed to by de pair into a
	ld [hli], a			; Load a into the memory pointed to by hl pair and increment hl
	inc de				; Decrement the address of de
	and a				; Check if the byte we just copied is zero '\0'
	jr nz, .copyString	; Loop if not null string terminator ('\0')

ld a, %11100100			; Pick a background color
ld [rBGP], a			; Set the background color

xor a					; Zero out a register
ld [rSCY], a			; Set scroll y to 0
ld [rSCX], a			; Set scroll x to 0
ld [rNR52], a			; Turn off sound (a is still 0)

ld a, %10000001			; Bit 7 = screen on, bit 0 = background on
ld [rLCDC], a			; Set LCD flags

.lockup
	ld [rSCX], a		; Set scroll x
jr .lockup				; Game lockup loop

SECTION "Font", ROM0	; No need to declare where to put this code, let assembler pick
FontTiles:
INCBIN "font.chr"		; Copy contents of file to right here
FontTilesEnd:

SECTION "Hello World string", ROM0	; No need to declare where to put this code, let assembler pick
HelloWorldStr:
    db "Hello World!", 0	; Define byte (ascii string) 0 is string null terminator