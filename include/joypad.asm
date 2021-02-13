IF      !DEF(JOYPAD_ASM)
JOYPAD_ASM  SET  1

jpad_GetKeys::
; Uses AF, B
; get currently pressed keys. Register A will hold keys in the following
; order: MSB --> LSB (Most Significant Bit --> Least Significant Bit)
; Down, Up, Left, Right, Start, Select, B, A
; This works by writing
  	; get action buttons: A, B, Start / Select
  	ld	a, JOYPAD_BUTTONS; choose bit that'll give us action button info
  	ld	[rJOYPAD], a; write to joypad, telling it we'd like button info
  	ld	a, [rJOYPAD]; gameboy will write (back in address) joypad info
  	ld	a, [rJOYPAD]
  	cpl		; take compliment
  	and	$0f	; look at first 4 bits only  (lower nibble)
  	swap	a	; place lower nibble into upper nibble
  	ld	b, a	; store keys in b
  	; get directional keys
  	ld	a, JOYPAD_ARROWS
  	ld	[rJOYPAD], a ; write to joypad, selecting direction keys
  	ld	a, [rJOYPAD]
  	ld	a, [rJOYPAD]
  	ld	a, [rJOYPAD]	; delay to reliably read keys
  	ld	a, [rJOYPAD]	; since we've just swapped from reading
  	ld	a, [rJOYPAD]	; buttons to arrow keys
  	ld	a, [rJOYPAD]
  	cpl			; take compliment
  	and	$0f		; keep lower nibble
  	or	b		; combine action & direction keys (result in a)
  	ld	b, a

  	ld	a, JOYPAD_BUTTONS | JOYPAD_ARROWS
  	ld	[rJOYPAD], a		; reset joypad

  	ld	a, b	; register A holds result. Each bit represents a key
  	ret

ENDC    ;JOYPAD_ASM
