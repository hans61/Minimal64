#org 0x430c ViewPort:
#org 0x551f leftUpperCorner:

#org 0x8000
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
begin:    LDI 0xfe STB 0xffff ; SP initialize
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
        JPS checkArray        ; there are still free fields
        CPI 0x00              ; 0 = no free field
        BEQ gNoField
        LDB flagM
        CPI 0x00
        BEQ gNoAdd
        JPS addNum
        JPS checkArray        ; there are still free fields
        CPI 0x00              ; 0 = no free field
        BEQ gNoField
gNoAdd:    CLB flagM
        JPA gameL1
gNoField:
        JPS chkMove           ; no space left, is there still a way to push?
        CPI 0x00              ; <>0 Move is possible
        BEQ gameOver          ; Pushing not possible
gameL1:    LDB gameWin        ; Flag game won
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
        LDI 4 STB delta
        LDI 0 STB idxA JPS chkField
        LDI 1 STB idxA JPS chkField
        LDI 2 STB idxA JPS chkField
        LDI 3 STB idxA JPS chkField
        JPA gameLoop
key_down:
        LDI -4 STB delta
        LDI 12 STB idxA JPS chkField
        LDI 13 STB idxA JPS chkField
        LDI 14 STB idxA JPS chkField
        LDI 15 STB idxA JPS chkField
        JPA gameLoop
key_right:
        LDI -1 STB delta
        LDI 3 STB idxA JPS chkField
        LDI 7 STB idxA JPS chkField
        LDI 11 STB idxA JPS chkField
        LDI 15 STB idxA JPS chkField
        JPA gameLoop
key_left:
        LDI 1 STB delta
        LDI 0 STB idxA JPS chkField
        LDI 4 STB idxA JPS chkField
        LDI 8 STB idxA JPS chkField
        LDI 12 STB idxA JPS chkField
        JPA gameLoop
    
gameOver:
        LDI 13 STB _XPos LDI 3 STB _YPos
        JPS printLine
        ' *********** ', 0x00,
        LDB gameWin
        CPI 0x00
        BNE winner
        LDI 13 STB _XPos INB _YPos
        JPS printLine
        '* GAME OVER *', 0x00,
        JPA gameOv1
winner:    LDI 13 STB _XPos INB _YPos
        JPS printLine
        '*  YOU WIN  *', 0x00,
gameOv1:
        LDI 13 STB _XPos INB _YPos
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

        LDI 3 STB _XPos INB _YPos INB _YPos INB _YPos
        JPS printLine
        'USE CURSOR KEYS OR I,J,K,M TO MOVE', 0x00,
        LDI 10 STB _XPos INB _YPos INB _YPos
        JPS printLine
        'N RESTARTS THE GAME', 0x00,
        LDI 12 STB _XPos INB _YPos INB _YPos
        JPS printLine
        'Q QUIT THE GAME', 0x00,

        LDI 9 STB _XPos INB _YPos INB _YPos INB _YPos
        JPS printLine
        'PRESS ANY KEY TO PLAY', 0x00,
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printTitle:
        LDI 12 STB _XPos LDI 2 STB _YPos
        JPS printLine
        '2048 PUZZLE GAME', 0x00,
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
; Output A=1 Move possible A=0 no move possible
chkMove:
        LDI 1 STB delta
        LDI 0 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 4 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 8 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 12 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 4 STB delta
        LDI 0 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 1 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 2 STB idxA JPS chkLine
        CPI 0x00 BNE retTrue
        LDI 3 STB idxA JPS chkLine
        RTS
chkLine:                      ; 
        LDB idxA STB idxL STB idxB
        LDB delta AD.B idxB   ; idxB is the successor of idxA
        LDB delta LL1 ADB delta AD.B idxL ; idxL is last index
chkL1:    LDB idxA PHS JPS loadArray PLS ; array(idxA)
        STB tmp01
        LDB idxB PHS JPS loadArray PLS ; array(idxB)
        CPB tmp01             ; CMP array(idxB), array(idxA)
        BEQ retTrue           ; if equal, then done Move is possible
        LDB delta AD.B idxB   ; 
        LDB delta AD.B idxA
        LDB idxA
        CPB idxL
        BNE chkL1
        LDI 0
        RTS
retTrue: LDI 1
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
; input: idxA = start; delta= delta
chkField:
        LDB idxA STB idxL
        LDB delta LL1 ADB delta AD.B idxL ; indL is last index
chkLoop:
        LDB idxA STB idxB
        CPB idxL              ; last index reached?
        BEQ chkRTS            ; idxA at the end
        LDB delta AD.B idxB   ; idxB is the successor of idxA
chk01:    LDB idxA PHS JPS loadArray PLS ; A = array(idxA)
        CPI 0x00
        BNE chk04
        ; array(idxA) = leer
chk01a:    LDB idxB PHS JPS loadArray PLS ; A = array(idxB)
        CPI 0x00
        BNE chk01b            ; Content there to be moved
        ; array(idxB) = leer
        LDB idxB
        CPB idxL
        BEQ chkRTS            ; nothing more until the end
        LDB delta AD.B idxB   ; idxB one field further
        JPA chk01a

chk01b:    PHS LDB idxA PHS JPS storeArray PLS PLS ; Move to empty field array(idxA) = array(idxB)
chk02:    INB flagM
        LDI 0x00
        PHS LDB idxB PHS JPS storeArray PLS PLS ; array(idxB) = 0
        JPA chkLoop
        ; array(idxA) = Value
chk04:    STB tmp01           ; array(idxA) remember 
chk05:    LDB idxB PHS JPS loadArray PLS ; A = array(idxB)
        CPI 0x00
        BNE chk06
        LDB idxB
        CPB idxL
        BEQ chkRTS
        LDB delta AD.B idxB
        JPA chk05
        
chk06:    CPB tmp01
        BNE chk07
        LDB idxA PHS JPS incArray PLS
        CPI 11
        BEQ chk09             ; 2048 reached
        LDB delta AD.B idxA
        JPA chk02
chk07:    LDB delta AD.B idxA
        JPA chkLoop
chk09:    LDI 0x01            ; Game Over Winner
        STB gameWin
		LDI 0x00 PHS
		LDB idxB PHS
		JPS storeArray PLS PLS		; array(idxB) = 0

chkRTS:    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
; input: PHS arrayValue; PHS arrayIndex
storeArray:
        LDI <array STB storeA1+1
        LDI >array STB storeA1+2
        LDS 3
        ADW storeA1+1
        LDS 4
storeA1:
        STB 0xffff
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
; input: PHS = arrayIndex output: A = arrayValue
loadArray:
        LDI <array STB loadA1+1
        LDI >array STB loadA1+2
        LDS 3
        ADW loadA1+1
loadA1:    LDB 0xffff
        STS 3
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
; input: PHS = arrayIndex
incArray:
        LDI <array STB incA1+1
        LDI >array STB incA1+2
        LDS 3
        ADW incA1+1
incA1:    INB 0xffff
        STS 3
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
addNum:    
addN1:    JPS _Random
        ANI 0x0f
        STB fieldId
        LAB array
        CPI 0x00
        BNE addN1
        LDI <array
        STB addN3+1
        LDI >array
        STB addN3+2
        LDB fieldId
        ADW addN3+1
        JPS _Random
        ANI 0x03
        CPI 0x03
        BNE addN2
        LDI 0x02
        JPA addN3
addN2:    LDI 0x01
addN3:    STB 0xffff
        STB sprId
        JPS print24x24
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
; output: A = Number of empty fields
checkArray:
        LDI 15
        STB fieldId
        CLB count2
        LDI <array STB checkA1+1
        LDI >array STB checkA1+2
checkA1:
        LDB 0xffff
        CPI 0x00
        BNE checkA2
        INB count2
checkA2:
        INW checkA1+1
        DEB fieldId
        BPL checkA1
        LDB count2
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~        
printArray:
        LDI 15
        STB fieldId
beg1:    LDB fieldId
        LAB array
        STB sprId
        JPS print24x24
        DEB fieldId
        BPL beg1
        RTS

clrArray:
        LDI <array
        STB clrAr1+1
        LDI >array
        STB clrAr1+2
        LDI 16
        STB count1
clrAr1:    CLB 0xffff
        INW clrAr1+1
        DEB count1
        BNE clrAr1
        RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; 24x24 Output pixel graphics in the playing field, aligned with a byte boundary
; Input (fieldId)
print24x24:
        LDB fieldId
        LL1                   ; A = 2 * A
        STZ 0                 ; X = A
        LZB 0, coordinates
        STB adress+0          ;{{sprite addr lo}}
        INZ 0
        LZB 0, coordinates
        STB adress+1          ;{{sprite addr hi}}
        
        LDB sprId
        LL1                   ; A = 2 * A
        STZ 0                 ; X = A
        LZB 0, spriteAddr16
        STB spoint+0          ;{{sprite addr lo}}
        INZ 0
        LZB 0, spriteAddr16
        STB spoint+1          ;{{sprite addr hi}}
        
        LDI 24
        STB count1
        
p24x24:    LDR spoint
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
empty:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
        0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
        0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
        0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
        0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
        0x02,0x00,0x40,0x02,0x00,0x40,0x02,0x00,0x40,
        0x02,0x00,0x40,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr02:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0x0a,0x00,0x68,0xc6,0xff,0x43,0xe2,0xff,0x47,
        0x72,0x00,0x4e,0x02,0x00,0x4c,0x02,0x00,0x4c,
        0x02,0x00,0x4c,0xc2,0xff,0x4f,0xe2,0xff,0x47,
        0xf2,0xff,0x43,0x72,0x00,0x40,0x32,0x00,0x40,
        0x32,0x00,0x40,0x32,0x00,0x40,0x72,0x00,0x4e,
        0xf2,0xff,0x47,0xf6,0xff,0x43,0x0a,0x00,0x60,
        0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr04:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0x0a,0x80,0x6a,0x06,0x07,0x55,0x02,0x07,0x68,
        0x82,0x03,0x50,0x82,0x01,0x60,0xc2,0x01,0x50,
        0xc2,0x00,0x60,0xe2,0xc0,0x41,0x62,0xc0,0x41,
        0x72,0xc0,0x41,0x32,0xc0,0x41,0xf2,0xff,0x4f,
        0xf2,0xff,0x4f,0xe2,0xff,0x4f,0x02,0xc0,0x41,
        0x02,0xc0,0x41,0x06,0xc0,0x41,0x0a,0x00,0x60,
        0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr08:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0x0a,0x00,0x68,0xc6,0xff,0x53,0xe2,0xff,0x67,
        0x72,0x00,0x4e,0x32,0x00,0x6c,0x32,0x00,0x4c,
        0x62,0x00,0x4e,0xc2,0xff,0x47,0xc2,0xff,0x43,
        0xe2,0xff,0x43,0x72,0x00,0x46,0x32,0x00,0x4c,
        0x32,0x00,0x4c,0x32,0x00,0x4c,0x72,0x00,0x4e,
        0xe2,0xff,0x47,0xc6,0xff,0x43,0x0a,0x00,0x60,
        0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr16:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0x02,0x00,0x60,0xf2,0xf0,0x4f,
        0xf2,0x30,0x4c,0xc2,0x30,0x40,0xc2,0x30,0x40,
        0xc2,0xf0,0x4f,0xc2,0x30,0x4f,0xf2,0x33,0x4f,
        0xf2,0xf3,0x4f,0x02,0x00,0x60,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr32:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0x02,0x00,0x60,0xfa,0xe7,0x5f,
        0x1a,0x66,0x58,0x02,0x06,0x58,0xe2,0xe7,0x5f,
        0x02,0x66,0x40,0x02,0x66,0x40,0x1a,0x66,0x58,
        0xfa,0xe7,0x5f,0x02,0x00,0x60,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr64:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0x02,0x00,0x60,0xfa,0xe7,0x59,
        0x1a,0xe6,0x59,0x1a,0xe0,0x59,0x1a,0xe0,0x5f,
        0xfa,0x07,0x58,0x9a,0x07,0x58,0x9a,0x07,0x58,
        0xfa,0x07,0x58,0x02,0x00,0x60,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xfc,0xff,0x3f,0x00,0x00,0x00,    
spr128:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x02,0x00,0x40,
        0x22,0x1c,0x47,0x32,0xa2,0x48,0x2a,0xa0,0x48,
        0x22,0x1c,0x47,0x22,0x82,0x48,0x22,0x82,0x48,
        0xfa,0x3e,0x47,0x02,0x00,0x40,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,    
spr256:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x02,0x00,0x40,
        0x72,0x3e,0x47,0x8a,0x82,0x40,0x82,0x9e,0x40,
        0x72,0xa0,0x47,0x0a,0xa0,0x48,0x0a,0xa2,0x48,
        0xfa,0x1c,0x47,0x02,0x00,0x40,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr512:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x02,0x00,0x40,
        0xf2,0x11,0x4e,0x12,0x18,0x51,0xf2,0x14,0x50,
        0x02,0x11,0x4e,0x02,0x11,0x41,0x12,0x11,0x41,
        0xe2,0x7c,0x5f,0x02,0x00,0x40,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr1024:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
        0xaa,0xaa,0x6a,0x56,0x55,0x55,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x06,0x00,0x50,
        0x02,0x00,0x40,0x22,0x32,0x45,0x32,0x45,0x45,
        0x22,0x25,0x47,0x22,0x15,0x44,0x72,0x72,0x44,
        0x02,0x00,0x40,0x06,0x00,0x50,0xaa,0xaa,0x6a,
        0x56,0x55,0x55,0xaa,0xaa,0x6a,0x56,0x55,0x55,
        0xaa,0xaa,0x6a,0xfc,0xff,0x3f,0x00,0x00,0x00,
spr2048:    0x00,0x00,0x00,0x00,0x00,0x00,0xfc,0xff,0x3f,
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
        STB ptr1+1
        LDS 2
        STB ptr1+0
        INW ptr1
        INW ptr1
pL1:    LDR ptr1
        CPI 0x00
        BNE pL2
        DEW ptr1
        LDB ptr1+0
        STS 2
        LDB ptr1+1
        STS 1
        RTS
pL2:    PHS JPS printCharXY PLS
        INW ptr1
        JPA pL1
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; PHS Char
; outputs a character at the position _XPos(0..39), _YPos (0..23) grid 10x10 pixel
; _XPos and _YPos are updated, there is no scrolling
printCharXY:
        CLB    xpos16+1
        LDB _XPos
        LL1
        STB xpos16+0          ; xpos16 = _XPos * 2
        PHS                   ; memorize _XPos * 2
        LLW    xpos16         ; xpos16 = _XPos * 4
        LLW    xpos16         ; xpos16 = _XPos * 8
        PLS                   ; Restore _XPos * 2
        ADW xpos16            ; xpos16 = _XPos * 8 + _XPos * 2 = _XPos * 10
        LDB xpos16+0x00
        PHS                   ; XPos low
        LDB xpos16+0x01
        PHS                   ; XPos hight
        LDB _YPos
        LL1
        STB ypos8
        LL2
        ADB ypos8
        PHS                   ; yPos = _YPos* 10
        LDS 6                 ; Char is LDS 3+3
        PHS
        JPS printChar
        PLS PLS PLS PLS
        INB _XPos
        LDB _XPos
        CPI 40
        BCC pCxy1
        CLB _XPos
        INB _YPos
        LDB _YPos
        CPI 24
        BCC pCxy1
        CLB _YPos
pCxy1:    RTS
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; print char 0x20..0x5f
; PHS: xLow, xHiht, y, char
printChar:
        LDS 4                 ; Y
        LL6 STB vAddr+0       ;
        LDS 4                 ; Y
        RL7 ANI 63 ADI >ViewPort STB vAddr+1
        LDS 5                 ; Xhight
        DEC
        LDS 6                 ; Xlow
        RL6 ANI 63 ADI 12 OR.B vAddr+0
        LDS 6 ANI 7 STB shift ; Xlow
        LDI 10 STB lineCnt    ; scnt loop counter 8 byte + 2 byte space
        LDS 3                 ; char
        CPI 0x60
        BCS rPCrts            ; char > 0x5f
        SUI 0x20
        BCC rPCrts            ; char < 0x20
        STB spritePtr+0
        CLB spritePtr+1       ; spritePtr=(char-' ')
        LLW spritePtr         ; *2
        LLW spritePtr         ; *4
        LLW spritePtr         ; *8 8 bytes per character
        LDI <alphaNumSprites  ; Sprite data low
        ADW spritePtr         ; Add to pointer
        LDI >alphaNumSprites
        AD.B spritePtr+1
        DEW spritePtr
clineloop:
        LDB lineCnt
        CPI 10
        BEQ cl1
        CPI 1
        BEQ cl1
        INW spritePtr
        LDR spritePtr
        JPA cl2
cl1:    LDI 0x00
cl2:    STB buffer+0
        CLB buffer+1
        CLB buffer+2
        CLB mask+0
        LDI 0xfc
        STB mask+1
        LDI 0xff
        STB mask+2
        MBZ shift,1           ; shift counter
        DEZ 1                 ; X coordinate
        BCC cshiftdone
cshiftloop:
        LLW buffer+0          ; logical shift to the left word absolute vAddress
        RLB buffer+2          ; rotate shift left byte absolute vAddress
        SEC
        RLW mask+0
        RLB mask+2
        DEZ 1
        BCS cshiftloop        ; branch on carry Set
cshiftdone:
        LDB mask+0
        ANR vAddr
        STR vAddr
        LDB buffer+0
        ORR vAddr
        STR vAddr
        INW vAddr
        LDB mask+1
        ANR vAddr
        STR vAddr
        LDB buffer+1
        ORR vAddr
        STR vAddr
        INW vAddr
        LDB mask+2
        ANR vAddr
        STR vAddr
        LDB buffer+2
        ORR vAddr
        STR vAddr
ccommon:    LDI 62
        ADW vAddr
        DEB lineCnt
        BNE clineloop
rPCrts:    RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
alphaNumSprites:
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, ; 0x20   space
    0x38,0x38,0x38,0x38,0x20,0x20,0x00,0x30, ; 0x21   !
    0x00,0x36,0x36,0x24,0x00,0x00,0x00,0x00, ; 0x22   "
    0x66,0xff,0xff,0x66,0x66,0xff,0xff,0x66, ; 0x23   #
    0x18,0x7e,0x03,0x7e,0xe0,0xe0,0x7e,0x18, ; 0x24   $
    0xc7,0xe5,0x77,0x38,0x1c,0xee,0xa7,0xe3, ; 0x25   %
    0x06,0x09,0x09,0x46,0x6d,0x11,0x71,0xce, ; 0x26   &
    0x00,0x0c,0x0c,0x08,0x00,0x00,0x00,0x00, ; 0x27   '
    0x38,0x1c,0x0e,0x0e,0x0e,0x0e,0x1c,0x38, ; 0x28   (
    0x1c,0x38,0x70,0x70,0x70,0x70,0x38,0x1c, ; 0x29   )
    0x99,0x5a,0x3c,0xff,0xff,0x3c,0x5a,0x99, ; 0x2a   *
    0x18,0x18,0x18,0xff,0xff,0x18,0x18,0x18, ; 0x2b   +
    0x00,0x00,0x00,0x00,0x0c,0x0c,0x08,0x04, ; 0x2c   ,
    0x00,0x00,0x00,0xff,0xff,0x00,0x00,0x00, ; 0x2d   -
    0x00,0x00,0x00,0x00,0x00,0x0c,0x0c,0x00, ; 0x2e   .
    0xc0,0xe0,0x70,0x38,0x1c,0x0e,0x07,0x03, ; 0x2f   /
    0xff,0xc3,0xc3,0xc3,0xf3,0xf3,0xf3,0xff, ; 0x30   0
    0x1e,0x1e,0x18,0x18,0x18,0x18,0x7e,0x7e, ; 0x31   1
    0xff,0xc3,0xc0,0xff,0x03,0x03,0xf3,0xff, ; 0x32   2
    0xff,0xc3,0xc0,0xfc,0xc0,0xc0,0xc3,0xff, ; 0x33   3
    0xcf,0xcf,0xcf,0xff,0xc0,0xc0,0xc0,0xc0, ; 0x34   4
    0xff,0x03,0x03,0xff,0xf0,0xf0,0xf0,0xff, ; 0x35   5
    0xff,0xc3,0x03,0xff,0xe3,0xe3,0xe3,0xff, ; 0x36   6
    0xff,0xf0,0xf0,0xf0,0x3c,0x0c,0x0c,0x0c, ; 0x37   7
    0xfc,0xcc,0xcc,0xff,0xc3,0xc3,0xc3,0xff, ; 0x38   8
    0xff,0xc3,0xc3,0xff,0xf0,0xf0,0xf0,0xf0, ; 0x39   9
    0x00,0x0c,0x0c,0x00,0x00,0x0c,0x0c,0x00, ; 0x3a   :
    0x00,0x18,0x18,0x00,0x18,0x18,0x10,0x08, ; 0x3b   ;
    0x06,0x06,0x00,0x0c,0x1c,0xd8,0xc0,0x00, ; 0x3c   < ;other use
    0x00,0x00,0x00,0x00,0x00,0xdb,0xdb,0x00, ; 0x3d   = ;other use
    0x60,0x60,0x00,0x30,0x38,0x1b,0x03,0x00, ; 0x3e   > ;other use
    0x3c,0x62,0x70,0x38,0x18,0x18,0x00,0x18, ; 0x3f   ?
    0x3c,0x42,0x99,0xa5,0x45,0x39,0x02,0x7c, ; 0x40   @
    0xfc,0xcc,0xcc,0xff,0xc3,0xc3,0xf3,0xf3, ; 0x41   A
    0x3f,0x33,0x33,0xff,0xc3,0xc3,0xc3,0xff, ; 0x42   B
    0xff,0xc3,0x03,0x03,0x0f,0x0f,0xcf,0xff, ; 0x43   C
    0x3f,0xc3,0xc3,0xc3,0xcf,0xcf,0xcf,0x3f, ; 0x44   D
    0xff,0x0f,0x0f,0x3f,0x03,0x03,0x03,0xff, ; 0x45   E
    0xff,0x0f,0x0f,0x3f,0x03,0x03,0x03,0x03, ; 0x46   F
    0xff,0xc3,0x03,0x03,0xf3,0xf3,0xc3,0xff, ; 0x47   G
    0xc3,0xc3,0xc3,0xff,0xcf,0xcf,0xcf,0xcf, ; 0x48   H
    0x08,0x08,0x08,0x38,0x38,0x38,0x38,0x38, ; 0x49   I
    0x20,0x20,0x20,0xe0,0xe0,0xe0,0xe3,0xff, ; 0x4a   J
    0xc3,0xe3,0x73,0x3f,0xff,0xcf,0xcf,0xcf, ; 0x4b   K
    0x03,0x03,0x03,0x0f,0x0f,0x0f,0x0f,0xff, ; 0x4c   L
    0xc3,0xcf,0xff,0xff,0xc3,0xc3,0xc3,0xc3, ; 0x4d   M
    0xc3,0xc3,0xcf,0xff,0xff,0xf3,0xc3,0xc3, ; 0x4e   N
    0xff,0xf3,0xf3,0xf3,0xc3,0xc3,0xc3,0xff, ; 0x4f   O
    0xff,0xc3,0xc3,0xff,0x0f,0x0f,0x0f,0x0f, ; 0x50   P
    0xff,0xf3,0xf3,0xc3,0xc3,0x23,0x63,0xdf, ; 0x51   Q
    0xff,0xc3,0xc3,0xff,0x3f,0x3f,0xcf,0xcf, ; 0x52   R
    0xff,0xc3,0x03,0xff,0xf0,0xf0,0xf3,0xff, ; 0x53   S
    0xff,0x0c,0x0c,0x3c,0x3c,0x3c,0x3c,0x3c, ; 0x54   T
    0xc3,0xc3,0xc3,0xcf,0xcf,0xcf,0xcf,0xff, ; 0x55   U
    0xcf,0xcf,0xcf,0xcf,0xcf,0xff,0x3c,0x0c, ; 0x56   V
    0xc3,0xc3,0xc3,0xc3,0xff,0xff,0xcf,0xc3, ; 0x57   W
    0xc3,0xc3,0xc3,0x3c,0x3c,0xc3,0xc3,0xc3, ; 0x58   X
    0xf3,0xf3,0xf3,0xff,0x3c,0x3c,0x3c,0x3c, ; 0x59   Y
    0xff,0x81,0x80,0xf8,0x3f,0x01,0xc1,0xff, ; 0x5a   Z
    0x00,0xc0,0xd8,0x1c,0x0c,0x00,0x06,0x06, ; 0x5b   [ ;other use
    0x00,0xdb,0xdb,0x00,0x00,0x00,0x00,0x00, ; 0x5c   \ ;other use
    0x00,0x03,0x1b,0x38,0x30,0x00,0x60,0x60, ; 0x5d   ] ;other use
    0x06,0x06,0x00,0x18,0x18,0x00,0x06,0x06, ; 0x5e   ^ ;other use
    0x60,0x60,0x00,0x18,0x18,0x00,0x60,0x60, ; 0x5f   _ ;other use
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#mute
array:    0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        0x00,0x00,0x00,0x00,
        
ptr1:    0x00,0x00,
ptrA:    0x00,0x00,
ptrB:    0x00,0x00,
adress:    0x00,0x00,
spoint:    0x00,0x00,
count1:    0x00,
count2:    0x00,
sprId:    0x00,
tmp01:    0x00,
fieldId:    0x00,
Xidx:    0x00,
Yidx:    0x00,
idxA:    0x00,
idxB:    0x00,
idxL:    0x00,
delta:    0x00,
flagM:    0x00,
gameWin:    0x00,
; variable printLine, printCharXY, printChar
xpos16:            0x0000,
ypos8:            0x00,
vAddr:            0x0000,
shift:            0x00,
buffer:            0xff, 0xff, 0xff ; move buffer
mask:            0xff, 0xff, 0xff,
lineCnt:        0x00,
spritePtr:        0x0000,



#org 0xf000 _Start:
#org 0xf003 _Prompt:
#org 0xf006 _MemMove:
#org 0xf009 _Random:
#org 0xf00c _ScanPS2:
#org 0xf00f _ResetPS2:
#org 0xf012 _ReadInput:
#org 0xf015 _WaitInput:
#org 0xf018 _ReadLine:
#org 0xf01b _SkipSpace:
#org 0xf01e _ReadHex:
#org 0xf021 _SerialWait:
#org 0xf024 _SerialPrint:
#org 0xf027 _FindFile:
#org 0xf02a _LoadFile:
#org 0xf02d _SaveFile:
#org 0xf030 _ClearVRAM:
#org 0xf033 _Clear:
#org 0xf036 _ClearRow:
#org 0xf039 _ScrollUp:
#org 0xf03c _ScrollDn:
#org 0xf03f _Char:
#org 0xf042 _PrintChar:
#org 0xf045 _Print:
#org 0xf048 _PrintHex:
#org 0xf04b _Pixel:
#org 0xf04e _Line:
#org 0xf051 _Rect:

#org 0x0080     PtrA:                                         ; lokaler pointer (3 bytes) used for FLASH addr and bank
#org 0x0083     PtrB:                                         ; lokaler pointer (3 bytes)
#org 0x0086     PtrC:                                         ; lokaler pointer (3 bytes)
#org 0x0089     PtrD:                                         ; lokaler pointer (3 bytes)
#org 0x008c     PtrE:                                         ; lokaler pointer (2 bytes)
#org 0x008e     PtrF:                                         ; lokaler pointer (2 bytes)
#org 0x0090     Z0:                                           ; OS zero-page multi-purpose registers
#org 0x0091     Z1:
#org 0x0092     Z2:
#org 0x0093     Z3:
#org 0x0094     Z4:

#org 0x00c0     _XPos:                                        ; current VGA cursor col position (x: 0..Width-1)
#org 0x00c1     _YPos:                                        ; current VGA cursor row position (y: 0..Height-1)
#org 0x00c2     _RandomState:                                 ; 4-byte storage (x, a, b, c) state of the pseudo-random generator
#org 0x00c6     _ReadNum:                                     ; 3-byte storage for parsed 16-bit number, MSB: 0xf0=invalid, 0x00=valid
#org 0x00c9     _ReadPtr:                                     ; Zeiger (2 bytes) auf das letzte eingelesene Zeichen (to be reset at startup)
#org 0x00cb                                                   ; 2 bytes unused
#org 0x00cd     _ReadBuffer:                                  ; <Width> bytes of OS line input buffer
#org 0x00fe     ReadLast:                                     ; last byte of read buffer
#org 0x00ff     SystemReg:                                    ; Don't use it unless you know what you're doing.