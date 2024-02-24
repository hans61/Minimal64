#org 0xc30c ViewPort:
#org 0xd51f leftUpperCorner:

#org 0x2000
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
begin:	LDI 0xfe STA 0xffff ; SP initialize
		JPS printHelp
		JPS _WaitInput
		CPI 'q'
		BEQ _Start
		CPI 'Q'
		BEQ _Start
newGame:
		JPS _Clear
		JPS clrArray
		CLB gameWin
		CLB flagM
		JPS addNum
		JPS addNum
		JPS printTitle
gameLoop:
		JPS printArray
		JPS checkArray			; there are still free fields
		CPI 0x00				; 0 = no free field
		BEQ gNoField
		LDA flagM
		CPI 0x00
		BEQ gNoAdd
		JPS addNum
		JPS checkArray			; there are still free fields
		CPI 0x00				; 0 = no free field
		BEQ gNoField
gNoAdd:	CLB flagM
		JPA gameL1
gNoField:
		JPS chkMove				; no space left, is there still a way to push?
		CPI 0x00				; <>0 Move is possible
		BEQ gameOver			; Pushing not possible
gameL1:	LDA gameWin				; Flag game won
		CPI 0x00
		BNE gameOver
		JPS _WaitInput
		CPI 'n'
		BEQ newGame
		CPI 'N'
		BEQ newGame

		CPI 'q'
		BEQ _Start
		CPI 'Q'
		BEQ _Start

		CPI 0xe1
		BEQ key_up
		CPI 'i'
		BEQ key_up
		CPI 'I'
		BEQ key_up

		CPI 0xe2
		BEQ key_down
		CPI 'm'
		BEQ key_down
		CPI 'M'
		BEQ key_down

		CPI 0xe3
		BEQ key_left
		CPI 'j'
		BEQ key_left
		CPI 'J'
		BEQ key_left

		CPI 0xe4
		BEQ key_right
		CPI 'k'
		BEQ key_right
		CPI 'K'
		BEQ key_right

		JPA gNoAdd
key_up:	
		LDI 4 STA delta
		LDI 0 STA idxA JPS chkField
		LDI 1 STA idxA JPS chkField
		LDI 2 STA idxA JPS chkField
		LDI 3 STA idxA JPS chkField
		JPA gameLoop
key_down:
		LDI -4 STA delta
		LDI 12 STA idxA JPS chkField
		LDI 13 STA idxA JPS chkField
		LDI 14 STA idxA JPS chkField
		LDI 15 STA idxA JPS chkField
		JPA gameLoop
key_right:
		LDI -1 STA delta
		LDI 3 STA idxA JPS chkField
		LDI 7 STA idxA JPS chkField
		LDI 11 STA idxA JPS chkField
		LDI 15 STA idxA JPS chkField
		JPA gameLoop
key_left:
		LDI 1 STA delta
		LDI 0 STA idxA JPS chkField
		LDI 4 STA idxA JPS chkField
		LDI 8 STA idxA JPS chkField
		LDI 12 STA idxA JPS chkField
		JPA gameLoop
	
gameOver:
		LDI 13 STA _XPos LDI 3 STA _YPos
		JPS printLine
		' *********** ', 0x00,
		LDA gameWin
		CPI 0x00
		BNE winner
		LDI 13 STA _XPos INB _YPos
		JPS printLine
		'* GAME OVER *', 0x00,
		JPA gameOv1
winner:	LDI 13 STA _XPos INB _YPos
		JPS printLine
		'*  YOU WIN  *', 0x00,
gameOv1:
		LDI 13 STA _XPos INB _YPos
		JPS printLine
		' *********** ', 0x00,
		JPS _WaitInput
		CPI 'q'
		BEQ _Start
		CPI 'Q'
		BEQ _Start
		JPA newGame
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printHelp:
		JPS _Clear
		JPS printTitle

		LDI 3 STA _XPos INB _YPos INB _YPos INB _YPos
		JPS printLine
		'USE CURSOR KEYS OR I,J,K,M TO MOVE', 0x00,
		LDI 10 STA _XPos INB _YPos INB _YPos
		JPS printLine
		'N RESTARTS THE GAME', 0x00,
		LDI 12 STA _XPos INB _YPos INB _YPos
		JPS printLine
		'Q QUIT THE GAME', 0x00,

		LDI 9 STA _XPos INB _YPos INB _YPos INB _YPos
		JPS printLine
		'PRESS ANY KEY TO PLAY', 0x00,
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printTitle:
		LDI 12 STA _XPos LDI 2 STA _YPos
		JPS printLine
		'2048 PUZZLE GAME', 0x00,
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
; Output A=1 Move possible A=0 no move possible
chkMove:
		LDI 1 STA delta
		LDI 0 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 4 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 8 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 12 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 4 STA delta
		LDI 0 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 1 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 2 STA idxA JPS chkLine
		CPI 0x00 BNE retTrue
		LDI 3 STA idxA JPS chkLine
		RTS
chkLine:											; 
		LDA idxA STA idxL STA idxB
		LDA delta ADB idxB							; idxB is the successor of idxA
		LDA delta LSL ADA delta ADB idxL			; idxL is last index
chkL1:	LDA idxA PHS JPS loadArray PLS				; array(idxA)
		STA tmp01
		LDA idxB PHS JPS loadArray PLS				; array(idxB)
		CPA tmp01									; CMP array(idxB), array(idxA)
		BEQ retTrue									; if equal, then done Move is possible
		LDA delta ADB idxB							; 
		LDA delta ADB idxA
		LDA idxA
		CPA idxL
		BNE chkL1
		LDI 0
		RTS
retTrue: LDI 1
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
; input: idxA = start; delta= delta
chkField:
		LDA idxA STA idxL
		LDA delta LSL ADA delta ADB idxL			; indL is last index
chkLoop:
		LDA idxA STA idxB
		CPA idxL									; last index reached?
		BEQ chkRTS									; idxA at the end
		LDA delta ADB idxB							; idxB is the successor of idxA
chk01:	LDA idxA PHS JPS loadArray PLS				; A = array(idxA)
		CPI 0x00
		BNE chk04
		; array(idxA) = leer
chk01a:	LDA idxB PHS JPS loadArray PLS				; A = array(idxB)
		CPI 0x00
		BNE chk01b									; Content there to be moved
		; array(idxB) = leer
		LDA idxB
		CPA idxL
		BEQ chkRTS									; nothing more until the end
		LDA delta ADB idxB							; idxB one field further
		JPA chk01a

chk01b:	PHS LDA idxA PHS JPS storeArray PLS PLS		; Move to empty field array(idxA) = array(idxB)
chk02:	INB flagM
		LDI 0x00
		PHS LDA idxB PHS JPS storeArray PLS PLS		; array(idxB) = 0
		JPA chkLoop
		; array(idxA) = Value
chk04:	STA tmp01									; array(idxA) remember 
chk05:	LDA idxB PHS JPS loadArray PLS				; A = array(idxB)
		CPI 0x00
		BNE chk06
		LDA idxB
		CPA idxL
		BEQ chkRTS
		LDA delta ADB idxB
		JPA chk05
		
chk06:	CPA tmp01
		BNE chk07
		LDA idxA PHS JPS incArray PLS
		CPI 11
		BEQ chk09									; 2048 reached
		LDA delta ADB idxA
		JPA chk02
chk07:	LDA delta ADB idxA
		JPA chkLoop
chk09:	LDI 0x01									; Game Over Winner
		STA gameWin
		LDI 0x00 PHS
		LDA idxB PHS
		JPS storeArray PLS PLS		; array(idxB) = 0
chkRTS:	RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
; input: PHS arrayValue; PHS arrayIndex
storeArray:
		LDI <array STA storeA1+1
		LDI >array STA storeA1+2
		LDS 3
		ADW storeA1+1
		LDS 4
storeA1:
		STA 0xffff
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
; input: PHS = arrayIndex output: A = arrayValue
loadArray:
		LDI <array STA loadA1+1
		LDI >array STA loadA1+2
		LDS 3
		ADW loadA1+1
loadA1:	LDA 0xffff
		STS 3
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
; input: PHS = arrayIndex
incArray:
		LDI <array STA incA1+1
		LDI >array STA incA1+2
		LDS 3
		ADW incA1+1
incA1:	INB 0xffff
		STS 3
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
addNum:	
addN1:	JPS _Random
		ANI 0x0f
		STA fieldId
		LTA array
		CPI 0x00
		BNE addN1
		LDI <array
		STA addN3+1
		LDI >array
		STA addN3+2
		LDA fieldId
		ADW addN3+1
		JPS _Random
		ANI 0x03
		CPI 0x03
		BNE addN2
		LDI 0x02
		JPA addN3
addN2:	LDI 0x01
addN3:	STA 0xffff
		STA sprId
		JPS print24x24
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
; output: A = Number of empty fields
checkArray:
		LDI 15
		STA fieldId
		CLB count2
		LDI <array STA checkA1+1
		LDI >array STA checkA1+2
checkA1:
		LDA 0xffff
		CPI 0x00
		BNE checkA2
		INB count2
checkA2:
		INW checkA1+1
		DEB fieldId
		BPL checkA1
		LDA count2
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~		
printArray:
		LDI 15
		STA fieldId
beg1:	LDA fieldId
		LTA array
		STA sprId
		JPS print24x24
		DEB fieldId
		BPL beg1
		RTS

clrArray:
		LDI <array
		STA clrAr1+1
		LDI >array
		STA clrAr1+2
		LDI 16
		STA count1
clrAr1:	CLB 0xffff
		INW clrAr1+1
		DEB count1
		BNE clrAr1
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; 24x24 Output pixel graphics in the playing field, aligned with a byte boundary
; Input (fieldId)
print24x24:
		LDA fieldId
		LSL					; A = 2 * A
		TAX					; X = A
		LTX coordinates
		STA adress+0		;{{sprite addr lo}}
		INX
		LTX coordinates
		STA adress+1		;{{sprite addr hi}}
		
		LDA sprId
		LSL					; A = 2 * A
		TAX					; X = A
		LTX spriteAddr16
		STA spoint+0		;{{sprite addr lo}}
		INX
		LTX spriteAddr16
		STA spoint+1		;{{sprite addr hi}}
		
		LDI 24
		STA count1
		
p24x24:	LDR spoint
		STR adress
		INW spoint
		INW adress
		LDR spoint
		STR adress
		INW spoint
		INW adress
		LDR spoint
		STR adress
		INW spoint
		LDI 62
		ADW adress
		DEB count1
		BNE p24x24
		RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Top left corner of each 4x4 playing field tile
coordinates:
	leftUpperCorner, leftUpperCorner+3, leftUpperCorner+6, leftUpperCorner+9,
	leftUpperCorner+1536, leftUpperCorner+1536+3, leftUpperCorner+1536+6, leftUpperCorner+1536+9,
	leftUpperCorner+3072, leftUpperCorner+3072+3, leftUpperCorner+3072+6, leftUpperCorner+3072+9,
	leftUpperCorner+4608, leftUpperCorner+4608+3, leftUpperCorner+4608+6, leftUpperCorner+4608+9,
; Table for faster sprite access
spriteAddr16:
	empty,
	spr02,
	spr04,
	spr08,
	spr16,
	spr32,
	spr64,
	spr128,
	spr256,
	spr512,
	spr1024,
	spr2048,
; Sprite Daten
empty:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
		0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
		0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
		0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
		0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
		0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
		0x02,0x00,0x40,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr02:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0x0a,0x00,0x68,0xc6,0xff,0x43,0xe2,0xff,0x47,
		0x72,0x00,0x4e,0x02,0x00,0x4c,0x02,0x00,0x4c,
		0x02,0x00,0x4c,0xc2,0xff,0x4f,0xe2,0xff,0x47,
		0xf2,0xff,0x43,0x72,0x00,0x40,0x32,0x00,0x40,
		0x32,0x00,0x40,0x32,0x00,0x40,0x72,0x00,0x4e,
		0xf2,0xff,0x47,0xf6,0xff,0x43,0x0a,0x00,0x60,
		0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr04:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0x0a,0x80,0x6a,0x06,0x07,0x55,0x02,0x07,0x68,
		0x82,0x03,0x50,0x82,0x01,0x60,0xc2,0x01,0x50,
		0xc2,0x00,0x60,0xe2,0xc0,0x41,0x62,0xc0,0x41,
		0x72,0xc0,0x41,0x32,0xc0,0x41,0xf2,0xff,0x4f,
		0xf2,0xff,0x4f,0xe2,0xff,0x4f,0x02,0xc0,0x41,
		0x02,0xc0,0x41,0x06,0xc0,0x41,0x0a,0x00,0x60,
		0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr08:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0x0a,0x00,0x68,0xc6,0xff,0x53,0xe2,0xff,0x67,
		0x72,0x00,0x4e,0x32,0x00,0x6c,0x32,0x00,0x4c,
		0x62,0x00,0x4e,0xc2,0xff,0x47,0xc2,0xff,0x43,
		0xe2,0xff,0x43,0x72,0x00,0x46,0x32,0x00,0x4c,
		0x32,0x00,0x4c,0x32,0x00,0x4c,0x72,0x00,0x4e,
		0xe2,0xff,0x47,0xc6,0xff,0x43,0x0a,0x00,0x60,
		0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr16:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0x02,0x00,0x60,0xf2,0xf0,0x4f,
		0xf2,0x30,0x4c,0xc2,0x30,0x40,0xc2,0x30,0x40,
		0xc2,0xf0,0x4f,0xc2,0x30,0x4f,0xf2,0x33,0x4f,
		0xf2,0xf3,0x4f,0x02,0x00,0x60,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr32:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0x02,0x00,0x60,0xfa,0xe7,0x5f,
		0x1a,0x66,0x58,0x02,0x06,0x58,0xe2,0xe7,0x5f,
		0x02,0x66,0x40,0x02,0x66,0x40,0x1a,0x66,0x58,
		0xfa,0xe7,0x5f,0x02,0x00,0x60,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr64:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0x02,0x00,0x60,0xfa,0xe7,0x59,
		0x1a,0xe6,0x59,0x1a,0xe0,0x59,0x1a,0xe0,0x5f,
		0xfa,0x07,0x58,0x9a,0x07,0x58,0x9a,0x07,0x58,
		0xfa,0x07,0x58,0x02,0x00,0x60,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,	
spr128:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x02,0x00,0x40,
		0x22,0x1c,0x47,0x32,0xa2,0x48,0x2a,0xa0,0x48,
		0x22,0x1c,0x47,0x22,0x82,0x48,0x22,0x82,0x48,
		0xfa,0x3e,0x47,0x02,0x00,0x40,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,	
spr256:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x02,0x00,0x40,
		0x72,0x3e,0x47,0x8a,0x82,0x40,0x82,0x9e,0x40,
		0x72,0xa0,0x47,0x0a,0xa0,0x48,0x0a,0xa2,0x48,
		0xfa,0x1c,0x47,0x02,0x00,0x40,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr512:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x02,0x00,0x40,
		0xf2,0x11,0x4e,0x12,0x18,0x51,0xf2,0x14,0x50,
		0x02,0x11,0x4e,0x02,0x11,0x41,0x12,0x11,0x41,
		0xe2,0x7c,0x5f,0x02,0x00,0x40,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr1024:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x06,0x00,0x50,
		0x02,0x00,0x40,0x22,0x32,0x45,0x32,0x45,0x45,
		0x22,0x25,0x47,0x22,0x15,0x44,0x72,0x72,0x44,
		0x02,0x00,0x40,0x06,0x00,0x50,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr2048:	0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
		0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x06,0x00,0x50,
		0x02,0x00,0x40,0x32,0x52,0x47,0x42,0x55,0x45,
		0x22,0x75,0x47,0x12,0x45,0x45,0x72,0x42,0x47,
		0x02,0x00,0x40,0x06,0x00,0x50,0xaa,0xaa,0x6a,
		0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
		0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Outputs the text immediately after JPS
; must be terminated 0
printLine:
		LDS 1
		STA ptr1+1
		LDS 2
		STA ptr1+0
		INW ptr1
		INW ptr1
pL1:	LDR ptr1
		CPI 0x00
		BNE pL2
		DEW ptr1
		LDA ptr1+0
		STS 2
		LDA ptr1+1
		STS 1
		RTS
pL2:	PHS JPS printCharXY PLS
		INW ptr1
		JPA pL1
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; PHS Char
; outputs a character at the position _XPos(0..39), _YPos (0..23) grid 10x10 pixel
; _XPos and _YPos are updated, there is no scrolling
printCharXY:
		CLB	xpos16+1
		LDA _XPos
		LSL
		STA xpos16+0	; xpos16 = _XPos * 2
		PHS				; memorize _XPos * 2
		LLW	xpos16		; xpos16 = _XPos * 4
		LLW	xpos16		; xpos16 = _XPos * 8
		PLS				; Restore _XPos * 2
		ADW xpos16		; xpos16 = _XPos * 8 + _XPos * 2 = _XPos * 10
		LDA xpos16+0x00
		PHS				; XPos low
		LDA xpos16+0x01
		PHS				; XPos hight
		LDA _YPos
		LSL
		STA ypos8
		LL2
		ADA ypos8
		PHS				; yPos = _YPos* 10
		LDS 6			; Char is LDS 3+3
		PHS
		JPS printChar
		PLS PLS PLS PLS
		INB _XPos
		LDA _XPos
		CPI 40
		BCC pCxy1
		CLB _XPos
		INB _YPos
		LDA _YPos
		CPI 24
		BCC pCxy1
		CLB _YPos
pCxy1:	RTS
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; print char 0x20..0x5f
; PHS: xLow, xHiht, y, char
printChar:
		LDS 4               	; Y
		LL6 STA vAddr+0      	;
		LDS 4               	; Y
		RL7 ANI 63 ADI >ViewPort STA vAddr+1
		LDS 5               	; Xhight
		DEC
		LDS 6               	; Xlow
		RL6 ANI 63 ADI 12 ORB vAddr+0
		LDS 6 ANI 7 STA shift	; Xlow
		LDI 10 STA lineCnt		; scnt loop counter 8 byte + 2 byte space
		LDS 3					; char
		CPI 0x60
		BCS rPCrts				; char > 0x5f
		SBI 0x20
		BCC rPCrts				; char < 0x20
		STA spritePtr+0
		CLB spritePtr+1			; spritePtr=(char-' ')
		LLW spritePtr			; *2
		LLW spritePtr			; *4
		LLW spritePtr			; *8 8 bytes per character
		LDI <alphaNumSprites	; Sprite data low
		ADW spritePtr			; Add to pointer
		LDI >alphaNumSprites
		ADB spritePtr+1
		DEW spritePtr
clineloop:
		LDA lineCnt
		CPI 10
		BEQ cl1
		CPI 1
		BEQ cl1
		INW spritePtr
		LDR spritePtr
		JPA cl2
cl1:	LDI 0x00
cl2:	STA buffer+0
		CLB buffer+1
		CLB buffer+2
		CLB mask+0
		LDI 0xfc
		STA mask+1
		LDI 0xff
		STA mask+2
		LYA shift      		; shift counter
		DEY					; X coordinate
		BCC cshiftdone
cshiftloop:
		LLW buffer+0        ; logical shift to the left word absolute vAddress
		RLB buffer+2        ; rotate shift left byte absolute vAddress
		SEC
		RLW mask+0
		RLB mask+2
		DEY
		BCS cshiftloop		; branch on carry Set
cshiftdone:
		LDA mask+0
		ANR vAddr
		STR vAddr
		LDA buffer+0
		ORR vAddr
		STR vAddr
		INW vAddr
		LDA mask+1
		ANR vAddr
		STR vAddr
		LDA buffer+1
		ORR vAddr
		STR vAddr
		INW vAddr
		LDA mask+2
		ANR vAddr
		STR vAddr
		LDA buffer+2
		ORR vAddr
		STR vAddr
ccommon:	LDI 62
		ADW vAddr
		DEB lineCnt
		BNE clineloop
rPCrts:	RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alphaNumSprites:
	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,	; 0x20   space
	0x38,0x38,0x38,0x38,0x20,0x20,0x00,0x30,	; 0x21   !
	0x00,0x36,0x36,0x24,0x00,0x00,0x00,0x00,	; 0x22   "
	0x66,0xff,0xff,0x66,0x66,0xff,0xff,0x66,	; 0x23   #
	0x18,0x7e,0x03,0x7e,0xe0,0xe0,0x7e,0x18,	; 0x24   $
	0xc7,0xe5,0x77,0x38,0x1c,0xee,0xa7,0xe3,	; 0x25   %
	0x06,0x09,0x09,0x46,0x6d,0x11,0x71,0xce,	; 0x26   &
	0x00,0x0c,0x0c,0x08,0x00,0x00,0x00,0x00,	; 0x27   '
	0x38,0x1c,0x0e,0x0e,0x0e,0x0e,0x1c,0x38,	; 0x28   (
	0x1c,0x38,0x70,0x70,0x70,0x70,0x38,0x1c,	; 0x29   )
	0x99,0x5a,0x3c,0xff,0xff,0x3c,0x5a,0x99,	; 0x2a   *
	0x18,0x18,0x18,0xff,0xff,0x18,0x18,0x18,	; 0x2b   +
	0x00,0x00,0x00,0x00,0x0c,0x0c,0x08,0x04,	; 0x2c   ,
	0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00,	; 0x2d   -
	0x00,0x00,0x00,0x00,0x00,0x0c,0x0c,0x00,	; 0x2e   .
	0xc0,0xe0,0x70,0x38,0x1c,0x0e,0x07,0x03,	; 0x2f   /
	0xff,0xc3,0xc3,0xc3,0xf3,0xf3,0xf3,0xff,	; 0x30   0
	0x1e,0x1e,0x18,0x18,0x18,0x18,0x7e,0x7e,	; 0x31   1
	0xff,0xc3,0xc0,0xff,0x03,0x03,0xf3,0xff,	; 0x32   2
	0xff,0xc3,0xc0,0xfc,0xc0,0xc0,0xc3,0xff,	; 0x33   3
	0xcf,0xcf,0xcf,0xff,0xc0,0xc0,0xc0,0xc0,	; 0x34   4
	0xff,0x03,0x03,0xff,0xf0,0xf0,0xf0,0xff,	; 0x35   5
	0xff,0xc3,0x03,0xff,0xe3,0xe3,0xe3,0xff,	; 0x36   6
	0xff,0xf0,0xf0,0xf0,0x3c,0x0c,0x0c,0x0c,	; 0x37   7
	0xfc,0xcc,0xcc,0xff,0xc3,0xc3,0xc3,0xff,	; 0x38   8
	0xff,0xc3,0xc3,0xff,0xf0,0xf0,0xf0,0xf0,	; 0x39   9
	0x00,0x0c,0x0c,0x00,0x00,0x0c,0x0c,0x00,	; 0x3a   :
	0x00,0x18,0x18,0x00,0x18,0x18,0x10,0x08,	; 0x3b   ;
	0x06,0x06,0x00,0x0c,0x1c,0xd8,0xc0,0x00,	; 0x3c   < ;other use
	0x00,0x00,0x00,0x00,0x00,0xdb,0xdb,0x00,	; 0x3d   = ;other use
	0x60,0x60,0x00,0x30,0x38,0x1b,0x03,0x00, 	; 0x3e   > ;other use
	0x3c,0x62,0x70,0x38,0x18,0x18,0x00,0x18,	; 0x3f   ?
	0x3c,0x42,0x99,0xa5,0x45,0x39,0x02,0x7c,	; 0x40   @
	0xfc,0xcc,0xcc,0xff,0xc3,0xc3,0xf3,0xf3,	; 0x41   A
	0x3f,0x33,0x33,0xff,0xc3,0xc3,0xc3,0xff,	; 0x42   B
	0xff,0xc3,0x03,0x03,0x0f,0x0f,0xcf,0xff,	; 0x43   C
	0x3f,0xc3,0xc3,0xc3,0xcf,0xcf,0xcf,0x3f,	; 0x44   D
	0xff,0x0f,0x0f,0x3f,0x03,0x03,0x03,0xff,	; 0x45   E
	0xff,0x0f,0x0f,0x3f,0x03,0x03,0x03,0x03,	; 0x46   F
	0xff,0xc3,0x03,0x03,0xf3,0xf3,0xc3,0xff,	; 0x47   G
	0xc3,0xc3,0xc3,0xff,0xcf,0xcf,0xcf,0xcf,	; 0x48   H
	0x08,0x08,0x08,0x38,0x38,0x38,0x38,0x38,	; 0x49   I
	0x20,0x20,0x20,0xe0,0xe0,0xe0,0xe3,0xff,	; 0x4a   J
	0xc3,0xe3,0x73,0x3f,0xff,0xcf,0xcf,0xcf,	; 0x4b   K
	0x03,0x03,0x03,0x0f,0x0f,0x0f,0x0f,0xff,	; 0x4c   L
	0xc3,0xcf,0xff,0xff,0xc3,0xc3,0xc3,0xc3,	; 0x4d   M
	0xc3,0xc3,0xcf,0xff,0xff,0xf3,0xc3,0xc3,	; 0x4e   N
	0xff,0xf3,0xf3,0xf3,0xc3,0xc3,0xc3,0xff,	; 0x4f   O
	0xff,0xc3,0xc3,0xff,0x0f,0x0f,0x0f,0x0f,	; 0x50   P
	0xff,0xf3,0xf3,0xc3,0xc3,0x23,0x63,0xdf,	; 0x51   Q
	0xff,0xc3,0xc3,0xff,0x3f,0x3f,0xcf,0xcf,	; 0x52   R
	0xff,0xc3,0x03,0xff,0xf0,0xf0,0xf3,0xff,	; 0x53   S
	0xff,0x0c,0x0c,0x3c,0x3c,0x3c,0x3c,0x3c,	; 0x54   T
	0xc3,0xc3,0xc3,0xcf,0xcf,0xcf,0xcf,0xff,	; 0x55   U
	0xcf,0xcf,0xcf,0xcf,0xcf,0xff,0x3c,0x0c,	; 0x56   V
	0xc3,0xc3,0xc3,0xc3,0xff,0xff,0xcf,0xc3,	; 0x57   W
	0xc3,0xc3,0xc3,0x3c,0x3c,0xc3,0xc3,0xc3,	; 0x58   X
	0xf3,0xf3,0xf3,0xff,0x3c,0x3c,0x3c,0x3c,	; 0x59   Y
	0xff,0x81,0x80,0xf8,0x3f,0x01,0xc1,0xff,	; 0x5a   Z
	0x00,0xc0,0xd8,0x1c,0x0c,0x00,0x06,0x06,	; 0x5b   [ ;other use
	0x00,0xdb,0xdb,0x00,0x00,0x00,0x00,0x00,	; 0x5c   \ ;other use
	0x00,0x03,0x1b,0x38,0x30,0x00,0x60,0x60,	; 0x5d   ] ;other use
	0x06,0x06,0x00,0x18,0x18,0x00,0x06,0x06,	; 0x5e   ^ ;other use
	0x60,0x60,0x00,0x18,0x18,0x00,0x60,0x60,	; 0x5f   _ ;other use
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#mute
; #org 0x3000						; only for debug
array:	0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		0x00,0x00,0x00,0x00,
		
ptr1:	0x00,0x00,
ptrA:	0x00,0x00,
ptrB:	0x00,0x00,
adress:	0x00,0x00,
spoint:	0x00,0x00,
count1:	0x00,
count2:	0x00,
sprId:	0x00,
tmp01:	0x00,
fieldId:	0x00,
Xidx:	0x00,
Yidx:	0x00,
idxA:	0x00,
idxB:	0x00,
idxL:	0x00,
delta:	0x00,
flagM:	0x00,
gameWin:	0x00,
; variable printLine, printCharXY, printChar
xpos16:			0x0000,
ypos8:			0x00,
vAddr:			0x0000,
shift:			0x00,
buffer:			0xff, 0xff, 0xff	; move buffer
mask:			0xff, 0xff, 0xff,
lineCnt:		0x00,
spritePtr:		0x0000,



#org 0xb000 _Start:
#org 0xb003 _Prompt:
#org 0xb006 _ReadLine:
#org 0xb009 _ReadSpace:
#org 0xb00c _ReadHex:
#org 0xb00f _SerialWait:
#org 0xb012 _SerialPrint:
#org 0xb015 _FindFile:
#org 0xb018 _LoadFile:
#org 0xb01b _SaveFile:
#org 0xb01e _MemMove:
#org 0xb021 _Random:
#org 0xb024 _ScanPS2:
#org 0xb027 _ReadInput:
#org 0xb02a _WaitInput:
#org 0xb02d _ClearVRAM:
#org 0xb030 _Clear:
#org 0xb033 _ClearRow:
#org 0xb036 _SetPixel:
#org 0xb039 _ClrPixel:
#org 0xb03c _GetPixel:
#org 0xb03f _Char:
#org 0xb042 _Line:
#org 0xb045 _Rect:
#org 0xb048 _Print:
#org 0xb04b _PrintChar:
#org 0xb04e _PrintHex:
#org 0xb051 _ScrollUp:
#org 0xb054 _ScrollDn:
#org 0xb057 _ResetPS2:

#org 0xbcb0 _ReadPtr:
#org 0xbcb2 _ReadNum:
#org 0xbcb5 PtrA:                        ; lokaler pointer (3 bytes) used for FLASH addr and bank
#org 0xbcb8 PtrB:                        ; lokaler pointer (3 bytes)
#org 0xbcbb PtrC:                        ; lokaler pointer (3 bytes)
#org 0xbcc4 _RandomState:
#org 0xbccc _XPos:
#org 0xbccd _YPos:
#org 0xbcce _ReadBuffer: