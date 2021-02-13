INCLUDE "gbhw.asm"
INCLUDE "memory.asm"
INCLUDE "joypad.asm"
INCLUDE "display.asm"

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
.copyLogoMap_load
    ld a, [de]                         ; Load tile key from LogoMap
    add a, ((FontEnd - Font) / 16) + 1 ; Fix tile key to map after the font
    ld [hli], a                        ; Set _SCRN0++ to the tile key
    inc de                             ; increment the data pointer
    dec bc                             ; decrement the chunk byte counter

    ld a, b
    or c                               ; check if chunk if fully loaded
    jr nz, .copyLogoMap_load           ; load more

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
.logoHold
; fade the logo out if there's user input
    call jpad_GetKeys
    cp 0
    jr nz, .logoEnd

    dec e
    jr nz, .logoHold
    dec d
    jr nz, .logoHold
.logoEnd
    call display_fadeOut

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the game tiles and graphics into VRAM:                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; turn the lcd off
    call display_waitVBlank
    xor a
    ld [rLCDC], a

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
; Clears the logo from the tilemap                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ld hl, $98b2
    ld bc, $99af - $98b2
.clearLogo
    xor a
    ld [hli], a
    dec bc
    ld a, b
    or c
    jr nz, .clearLogo

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copy the title screen to the tilemap                                         ;
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



    ;ld hl, $9862
    ;ld de, TitleMap
    ;ld bc, TitleMapEnd - TitleMap
;.loadTitleMap
    ;REPT 16
    ;ld a, [de]
    ;add a, ((FontEnd - Font) / 16) + ((TilesEnd - Tiles) / 16) + 1
    ;ld [hli], a
    ;inc de
    ;dec bc
    ;ENDR

    ;ld a, l
    ;add a, 16
    ;ld l, a
    ;ld a, h
    ;adc a, 0
    ;ld h, a

    ;ld a, b
    ;or c
    ;jr nz, .loadTitleMap

; Turn screen on, display background
    ld  a, %10010001
    ld  [rLCDC], a
; Fade it in
    call display_fadeIn
; lockup at the end
.lockup
    call display_waitVBlank
    xor a
    jr .lockup

SECTION "Data", ROM0

Font:
INCBIN "dat/font.2bpp"                                  ; font image data
FontEnd:

URL:
  db $06, $19, $21, $1c, $0a, $1f, $19, $25, $1d, $2b   ; "zaid.games"
URLEnd:

Logo:
INCBIN "zaid.2bpp"        ; my logo image data
LogoEnd:

LogoMap:
INCBIN "zaid.tilemap"     ; my logo tile map
LogoMapEnd:

Tiles:
INCBIN "tiles.2bpp"       ; game tiles
TilesEnd:

Title:
INCBIN "logo.2bpp"        ; game logo tiles
TitleEnd:

TitleMap:
INCBIN "logo.tilemap"     ; game logo tile map
TitleMapEnd:

TitleScreen:
INCBIN "board.tilemap"    ; ti
TitleScreenEnd:
