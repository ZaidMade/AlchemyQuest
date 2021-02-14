IF      !DEF(DATA_ASM)
DATA_ASM  SET  1

SECTION "Data", ROM0

Font:
INCBIN "font.2bpp"                                  	; font image data
FontEnd:

URL:
  db $06, $19, $21, $1c, $0a, $1f, $19, $25, $1d, $2b	; "zaid.games"
URLEnd:

Logo:
INCBIN "zaid.2bpp"        								; my logo image data
LogoEnd:

LogoMap:
INCBIN "zaid.tilemap"     								; my logo tile map
LogoMapEnd:

Tiles:
INCBIN "tiles.2bpp"       								; game tiles
TilesEnd:

Title:
INCBIN "logo.2bpp"        								; game logo tiles
TitleEnd:

TitleMap:
INCBIN "logo.tilemap"     								; game logo tile map
TitleMapEnd:

TitleScreen:
INCBIN "titlescreen.tilemap"    			; Title screen whole-screen tilemap
TitleScreenEnd:

BoardScreen:
INCBIN "board.tilemap"						; Board screen whole-screen tilemap
BoardScreenEnd:

ENDC	; END DATA_ASM