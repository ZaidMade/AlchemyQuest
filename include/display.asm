IF      !DEF(DISPLAY_ASM)
DISPLAY_ASM  SET  1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;                              !!!! TODO !!!!
;                              -Feb 11, 2021-
;
;   Figure out how to clean up this code and do the fade in/out algorithmically
; instead of jumping around like a glorified switch statement.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

display_fadeIn::
  xor a                       ; make sure a is set to 0
  ld [rBGP], a                ; set the background palette to all zeros

  ld d, 3

.start
  ld bc, $4F00

.wait
  dec c                       ; increment the count
  jr nz, .wait                ; if count is not zero, skip the fade effect
  dec b
  jr nz, .wait

  ld a, [rBGP]                ; load the current palette into a
  cp %11100100                ; compare it with the desired palette
  ret z                       ; if it is as desired, return this function

  dec d
  jr z, .third
  dec d
  jr z, .second

  inc d
  ld a, %01000000
  jr .deposit
.second
  inc d
  ld a, %10010000
  jr .deposit
.third
  ld a, %11100100
.deposit
  ld [rBGP], a                ; load the palette back into VRAM
  jr .start

display_fadeOut::
  ld d, 3
.start
  ld bc, $4F00

.wait
  dec c                       ; increment the counter
  jr nz, .wait                ; if counter is not zero, skip the fade effect
  dec b
  jr nz, .wait

  ld a, [rBGP]                ; load register a with current BG palette
  cp 0                        ; compare it with zero
  ret z

  dec d
  jr z, .third
  dec d
  jr z, .second

  inc d
  ld a, %10010000
  jr .deposit
.second
  inc d
  ld a, %01000000
  jr .deposit
.third
  ld a, %00000000
.deposit
  ld [rBGP], a                ; load the palette back into VRAM
  jr .start


display_waitVBlank::
.dw_wait
  ld  a, [rLY]
  cp  144                     ; Check if LCD is past VBlank
  jr  c, .dw_wait
  ret

ENDC
