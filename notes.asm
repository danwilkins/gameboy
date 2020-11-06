; Registers:
; a = accumulator
; f = flags
; b,c = general (paird for 16-bit)
; d,e = general (paird for 16-bit)
; h,l = (high, low) general (paird for 16-bit)
; Addressing is done through square brackets [$FF00]
; $FF00 is just a value
; Can not load from memory into any register other than a
; little endian storage
; ADC will be +1 if the carry flag is set
; Carry flag is set in underflow from SUB
; SBC will be -1 if the carry flag is set
; jp, jr, call, rst and ret (arguments nz, z, nc, c [z = zero, c = carry])
; ldh a, [rLY] = Read the LCD's drawing status
; ldh is faster if reading from $FF00-$FFFF memory
; v-blank is between 144 and 153 (read from rLY)
; $FF41 = stat register | 0 = HBlank, 1 = VBlank, 2 = OAM search, 3 = Rendering
; VRAM is between $8000 and $9FFF
; CPU and PPU can't access VRAM at the same time
; Tiles are stored between $8000 and $97FF
; 8 * 8 pixels * 2 bpp / 8 bits-per-byte = 16 bytes per tile
; There are 2 (32 * 32 tiles [256 * 256 pixels]) tile maps at $9800-$9BFF and $9C00-$9FFF
; SCY and SCX are for scrolling ($FF42 and $FF43)
; Increasing SCY scrolls up (tilemap down)
; Increasing SCX scrolls left (tilemap right)
; The tilemap automatically wraps around
; BGP = background palette (4 groups, 2 bits each)
; %00 = white, %01 = light gray, %10 = dark gray, %11 = black
; Example of BGP:
;        BGP:  %33 22 11 00
; Program starts at $100
; DI = Disable interrupts
; EI = Enable interrupts

;============= Memory Map ==============;
;	$0000		$7FFF		ROM			;
;	$8000		$9FFF		VRAM		;
;	$A000		$BFFF		SRAM		;
;	$C000		$DFFF		WRAM		;
;	$E000		$FDFF		Echo RAM	;
;	$FE00		$FE9F		OAM			;
;	$FEA0		$FEFF		"FEXX"		;
;	$FF00		$FF7F		IO			;
;	$FF80		$FFFE		HRAM		;
;=======================================;

;=============== Interrupts ================;
;	$01	VBlank	$0040	highest priority	;
;	$02	STAT	$0048	LCD					;
;	$04	Timer	$0050	highest priority	;
;	$08	Serial	$0058	highest priority	;
;	$10	Joypad	$0060	lowest priority;	;
;===========================================;

; Tons of info:  https://github.com/gbdev/awesome-gbdev
