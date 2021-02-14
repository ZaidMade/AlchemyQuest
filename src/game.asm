IF      !DEF(GAME_ASM)
GAME_ASM  SET  1

WindowScrollRight:
	ld a, [rSCX]				; check if scroll x == 160
	cp 160
	jr z, .firstScreen			; if it is, start writing to $9800
	ld hl, $9814				; or else write to $9814
	jr .scroll_start
.firstScreen
	ld hl, $9800

.scroll_start
;push everything to the stack
	push bc
	push hl
	push de

; set a counter
	ld de, $0000
.scroll_hold
; keep decrementing de until a full rollover occurs
	dec e
	jr nz, .scroll_hold
	;dec d
	;jr nz, .scroll_hold

; reset de to before being used as a counter
	pop de
	push de

.scroll_continue
	ld bc, 18						; ld bc with the chunk amount to load

	call display_waitVBlank			; wait for vBlank
.scroll_load
; load [de] into [hl]
	ld a, [de]
	ld [hl], a
	
; increment hl by 32 tiles (y++)
	ld a, l
	add $20
	ld l, a
	ld a, h
	adc 0
	ld h, a

; increment de by 20 tiles (y++)
	ld a, e
	add 20
	ld e, a
	ld a, d
	adc 0
	ld d, a

; decrement the byte counter
	dec bc

; check if the byte counter has reached zero
	ld a, b
	or c
	jr nz, .scroll_load	; if not, load another byte

; revert de back to it's original state and increment it
	pop de
	inc de

	ld a, l
	cp $5f
	jr nz, .scroll_inc_hl
	ld a, h
	cp $9a
	jr z, .scroll_wrap_hl
.scroll_inc_hl
; revert hl back to it's original state and increment it
	pop hl
	inc hl
	jr .scroll_hl_end
.scroll_wrap_hl
	pop hl
	ld hl, $9800
.scroll_hl_end

; revert bc back to it's original state and decrement the chunk amount from it
	pop bc
	ld a, c
	sub 18
	ld c, a
	ld a, b
	sbc 0
	ld b, a

.scroll_skip
; scroll the screen
	ld a, [rSCX]
	inc a
	ld [rSCX], a

; return if the scroll.x == 160
	cp 160
	ret z
	
; check if the byte counter is at zero
	ld a, b
	or c
	jr nz, .scroll_start	; if it's not, load another chunk
	jr .scroll_skip			; otherwise just keep scrolling

ENDC	; END GAME_ASM