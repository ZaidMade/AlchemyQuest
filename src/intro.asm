IF      !DEF(INTRO_ASM)
INTRO_ASM  SET  1

INCLUDE "gbhw.asm"
INCLUDE "memory.asm"
INCLUDE "joypad.asm"
INCLUDE "display.asm"

INCLUDE "data.asm"

SECTION "Intro_Code", ROM0
Intro:
; turn off the LCD
	xor a
	ld  [rLCDC], a

; load the font into VRAM
	ld hl, Font
	ld de, _VRAM + 16
	ld bc, FontEnd - Font
	call mem_Copy

; load the logo into VRAM
	ld  hl, Logo
	ld  de, _VRAM + 16 + (FontEnd - Font)
	ld  bc, LogoEnd - Logo
	call mem_Copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the logo tiles into the background tile map at _SCRN0:                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, $9881
	ld de, LogoMap
	ld bc, LogoMapEnd - LogoMap
.copyLogoMap
	push bc                            ; push the byte count to the stack
	ld bc, 18                          ; set the byte count to a hChunk (18)
.copyLogoMap_loop
	ld a, [de]                         ; Load tile key from LogoMap
	add a, ((FontEnd - Font) / 16) + 1 ; Fix tile key to map after the font
	ld [hli], a                        ; Set _SCRN0++ to the tile key
	inc de                             ; increment the data pointer
	dec bc                             ; decrement the chunk byte counter

	ld a, b
	or c                               ; check if chunk if fully loaded
	jr nz, .copyLogoMap_loop           ; load more

	ld a, l
	add a, 14                          ; skip over off screen tile space
	ld l, a
	ld a, h
	adc a, 0                           ; add the carry
	ld h, a

	pop bc                             ; pop total byte count from stack
	ld a, c
	sub 18                             ; subtract 18 from the lower byte
	ld c, a
	ld a, b
	sbc 0                              ; subtract the carry from the higher byte
	ld b, a
	or c                               ; check if zero
	jr nz, .copyLogoMap                ; if not zero, reset value and restart

; load the URL tiles into the tilemap at _SCRN0
	ld hl, URL
	ld de, $99a5
	ld bc, URLEnd - URL
	call mem_Copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Initialize the device to display the logo:                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.device_init
; set background palette to 0
	xor a
	ld  [rBGP], a

; set the view window to 0, 0
	xor a
	ld  [rSCY], a
	ld  [rSCX], a
; turn sound off
	ld  [rNR52], a

; turn lcd on, display background
	ld  a, %10010001
	ld  [rLCDC], a

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Display the logo and hold it:                                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	call display_fadeIn
	ld de, $0000
.hold
; fade the logo out if there's user input
	call jpad_GetKeys
	cp 0
	jr nz, .end

	dec e
	jr nz, .hold
	dec d
	jr nz, .hold
.end
	call display_fadeOut

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clears the logo from the tilemap                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; turn the lcd off
	call display_waitVBlank
	xor a
	ld [rLCDC], a

	ld hl, $98b2
	ld bc, $99af - $98b2
.clear
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .clear

	ret		; RETURN!!!
ENDC	; END START_ASM