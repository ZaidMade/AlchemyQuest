INCLUDE "gbhw.asm"
INCLUDE "memory.asm"
INCLUDE "joypad.asm"
INCLUDE "display.asm"

INCLUDE "data.asm"
INCLUDE "intro.asm"

SECTION "VBlank_Interrupt", ROM0[$40]
  nop
  ret

SECTION "Header", ROM0[$100]

EntryPoint:
    ei          ; Enable interrupts
    jp  Start   ; Jump to code start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; THE EVERDRIVE NEEDS TO WAIT FOR VBLANK & HANDLE VBLANK INTERRUPT ROUTINE TO
; TRIGGER THE MENU... (supposedly)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

REPT $150 - $104
    db  0
ENDR

SECTION "Code", ROM0

Start:
	call Intro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the game tiles and graphics into VRAM:                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load tiles into VRAM after the font
    ld hl, Tiles
    ld de, _VRAM + 16 + (FontEnd - Font)
    ld bc, TilesEnd - Tiles
    call mem_Copy

; load game title into VRAM after the tile
    ld hl, Title
    ld de, _VRAM + 16 + (FontEnd - Font) + (TilesEnd - Tiles)
    ld bc, TitleEnd - Title
    call mem_Copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copy the title screen to the tilemap                                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ld hl, $9800
    ld de, TitleScreen
    ld bc, TitleScreenEnd - TitleScreen
.copyTitleScreen
    push bc
    ld bc, 20
.copyTitleScreen_load
    ld a, [de]
    ld [hli], a
    inc de
    dec bc

    ld a, b
    or c                                ; check if chunk is fully loaded
    jr nz, .copyTitleScreen_load        ; if not, jump back and load more

    ld a, l
    add a, 12                           ; skip over off screen tile space
    ld l, a
    ld a, h
    adc a, 0                            ; add the carry
    ld h, a

    pop bc                              ; pop total byte count from stack
    ld a, c
    sub 20                              ; subtract 20 from the lower byte
    ld c, a
    ld a, b
    sbc 0                               ; subtract the carry from the higher byte
    ld b, a
    or c                                ; check if zero
    jr nz, .copyTitleScreen             ; if not zero, reset value and restart

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copy the title to the tilemap                                      		  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ld hl, $9862
    ld de, TitleMap
    ld bc, TitleMapEnd - TitleMap
.loadTitleMap
    REPT 16
    ld a, [de]
    add a, ((FontEnd - Font) / 16) + ((TilesEnd - Tiles) / 16) + 1
    ld [hli], a
    inc de
    dec bc
    ENDR

    ld a, l
    add a, 16
    ld l, a
    ld a, h
    adc a, 0
    ld h, a

    ld a, b
    or c
    jr nz, .loadTitleMap

; Turn screen on, display background
    ld  a, %10010001
    ld  [rLCDC], a
; Fade it in
    call display_fadeIn

; scroll to the next screen at the end
	ld hl, $9814
	ld de, BoardScreen
	ld bc, BoardScreenEnd - BoardScreen
.loop
	push bc
	push de

	ld de, $0000
.hold
; trigger the window scroll
    ;call jpad_GetKeys
    ;cp 0
    ;jr nz, .logoEnd

	dec e
	jr nz, .hold
	dec d
	jr nz, .hold

	pop de

;$9a34
	ld a, e
	cp $34
	jr nz, .continue
	ld a, d
	cp $9a
	jr z, .skip
.continue

	ld bc, 18
	call display_waitVBlank
.load_board
	ld a, [de]
	ld [hli], a
	inc h
	inc h
	; TODO implement to where it increments l if at bottom of screen
	inc d
	inc d
	dec bc

	ld a, b
	or c
	jr nz, .load_board

	pop bc
	ld a, c
	sub 18
	ld c, a
	ld a, b
	adc 0
	ld b, a

.skip

	ld a, [rSCX]
	inc a
	ld [rSCX], a
	cp 160
    jr nz, .loop

.lock
	xor a
	jr .lock

	call display_waitVBlank
