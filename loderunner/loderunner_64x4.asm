#org 0x0070 delayValue:       ; to adjust the game speed (Minimal 64 40, Minimal 64x4 70)
#org 0x0096 _lastLevel:       ; &96 = 150 this must correspond to the loderunner.dat file
#org 0x430c ViewPort:
#org 0x8000
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Start Game ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
begin:        LDI 0xfe STB 0xffff ; SP initialisieren
            JPS initVariables
            JPS loadHighscore
            JPS _Clear
            JPS printHighscore
            LDI 80
            STB tmp00
startLoop:    JPS delayLong
            LDB pressed
            CPI 0x00
            BNE startGame
            DEB tmp00
            BNE startLoop
startGame:
            JPS _Clear
            LDI 0x05          ; A = 5
            STB lives         ; (lives) = A
            LDI 1             ;yes, start level 1 (quick play)
            STB level
            CLW score+0 CLW score+2
            JPS initFlashLevel
gameLoop:    JPS initVariables
            JPS drawLevel
checkKeys:    JPS KeyHandler
            JPS delayLong
            LDB gameRun
            CPI 0x00
            BNE checkKey1
            JPS updateEnemies
            JPS updateHoles
            LDB playerIsDead
            CPI 0x00
            BNE deathSound
            JPA checkEscapeKey
checkKey1:    LDB oldPlayerXPosLo
            STB tmpXPosLo
            LDB oldPlayerXPosHi
            STB tmpXPosHi
            LDB oldPlayerYPos
            STB tmpYPos
            LDB oldPlayerFrameNumber
            INC
            CPI 0x09
            BCC checkKey2
            LDI 0x07
checkKey2:    STB playerFrameNumber
            JPS delayLong
            JPA redrawPlayer
deathSound:
            CLB playerIsDead  ;mark player as alive
            DEB lives         ;but lose a life
            LDB lives
            CPI 0x00
            BEQ gameOver
            JPS clearScreen
            JPA gameLoop
gameOver:    LDI 10 STB _XPos
            LDI 9 STB _YPos
            JPS printLine
            '  ***********  ',0,
            LDI 10 STB _XPos
            LDI 10 STB _YPos
            JPS printLine
            ' * GAME OVER * ',0,
            LDI 10 STB _XPos
            LDI 11 STB _YPos
            JPS printLine
            '  ***********  ',0,
            JPS _WaitInput
gameOver0:    JPS clearScreen
            JPS loadHighscore
            JPS cmpHighscore
            CPI 0x00
            BEQ gameOver1
            JPS saveHighscore
gameOver1:    JPS printHighscore
            JPS _WaitInput
            JPS clearScreen
            JPA startGame
            JPA gameLoop
checkEscapeKey:
            LDB _escape
            CPI 1
            BEQ deathSound    ;restart level
            LDB _quit
            CPI 1
            BNE checkLevelComplete
            LDI 1 STB lives
            JPA deathSound
checkLevelComplete:
            LDB playerYBlockPos
            CPI 0x00
            BNE checkPlaySoundGold ;player must exit level at very top of the screen
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE checkPlaySoundGold ;and must be exactly vertically aligned to top block
            LDB allGoldCollected
            CPI 0x00
            BEQ checkPlaySoundGold ;and all gold ingots must have been collected first
            LDI 0x00
            STB allGoldCollected
            STB cntLevelComplete
loopLevelComplete:
            LDB cntLevelComplete
            CPI 0x0f
            STZ 0
            BNE playSoundAndScoreLevelComplete
            JPS clearScreen2
            INB lives         ;extra live for completing the level
            INB level         ;next level
            LDB level
            CPI <_lastLevel+1 ;reached level 40 (last)?
            BNE startLevel
            LDI 0x01
            STB level         ;reset to level 1
            JPS _Clear
                              ;JPS loadLevels
startLevel:    JPA gameLoop
playSoundAndScoreLevelComplete:
                              ;lda soundPitchValuesLevelComplete,x
                              ;sta pitch2
                              ;lda #$01
                              ;sta pitch2+2                        ;duration
                              ;lda #$07
                              ;ldx #<sound2
                              ;ldy #>sound2
                              ;jsr OSWORD                          ;SOUND
            JPS delayLevel
            INB cntLevelComplete
            MIZ 0x50,0
            MIZ 0x01,1
            JPS addYXtoScoreBCD ;score+=150
            JPA loopLevelComplete
checkPlaySoundGold:
            LDB soundIndexGold ;MBZ soundIndexGold,0 ???
            CPI 0x00
            BEQ checkPlaySoundAllGold ;done playing the sound for collecting a gold ingot
                              ;lda soundPitchValuesForGold,x
                              ;sta pitch3
                              ;lda #$07
                              ;ldx #<sound3
                              ;ldy #>sound3
                              ;jsr OSWORD                          ;SOUND
            DEB soundIndexGold
            JPA checkHoleDigging
checkPlaySoundAllGold:
            LDB playingSoundAllGold
            CPI 0x00
            BEQ checkHoleDigging ;done playing the sound for collecting all the gold ingots
                              ;ldx soundIndexAllGold
                              ;lda soundPitchValuesAllGold,x
                              ;sta pitch2
                              ;lda soundDurationValuesAllGold,x
                              ;sta pitch2+2                        ;duration
                              ;lda #$07
                              ;ldx #<sound2
                              ;ldy #>sound2
                              ;jsr OSWORD                          ;SOUND
            INB soundIndexAllGold
            LDB soundIndexAllGold
            CPI 0x06
            BNE checkHoleDigging
            LDI 0x00
            STB playingSoundAllGold
            STB soundIndexAllGold
checkHoleDigging:
            LDB oldPlayerXPosLo
            STB tmpXPosLo
            LDB oldPlayerXPosHi
            STB tmpXPosHi
            LDB oldPlayerYPos
            STB tmpYPos
            LDB diggingHole
            CPI 0x00
            BEQ checkPlayerFalling ;not digging a hole at the moment
; update animation of hole digging
                              ;lda #$13                            ; Wait for vertical sync (0..16.6833)ms
                              ;jsr OSBYTE                          ;*FX19
            JPS delay
            LDB indexAnimDigHole
            LAB spriteNumbersAnimDigHole
            STB spriteId
            LDB xPosDigHoleLo
            STB xpos16+0
            LDB xPosDigHoleHi
            STB xpos16+1
            LDB yPosDigHole
            STB ypos8
            JPS plotSprite14x14 ;erase old sprite for hole digging
                              ;lda #$07
                              ;ldx #<sound4
                              ;ldy #>sound4
                              ;jsr OSWORD                          ;SOUND: digging hole
            DEB indexAnimDigHole
            BEQ doneDigging
            LDB indexAnimDigHole
            LAB spriteNumbersAnimDigHole
            STB spriteId
            LDB xPosDigHoleLo
            STB xpos16+0
            LDB xPosDigHoleHi
            STB xpos16+1
            LDB yPosDigHole
            STB ypos8
            JPS plotSprite14x14 ;draw new sprite for hole digging
            JPA redrawPlayer
doneDigging:
            CLB diggingHole
            LDB playerDirection
            CPI 0x00
            BEQ playerFacingLeft ;player facing left
            LDI 0x07          ;first sprite frame of player facing right
            JPA setPlayerSpriteFrame ;jump always
playerFacingLeft:
            LDI 0x0a          ;first sprite frame of player facing left
setPlayerSpriteFrame:
            STB playerFrameNumber
            JPS addNewHole
            JPA redrawPlayer
checkPlayerFalling:
            LDB playerFalling
            CPI 0x00
            BEQ checkWhichKeysPressed ;not falling
                              ;INB soundCounterWhileFalling
                              ;LDA soundCounterWhileFalling
                              ;ANI 0x01
                              ;CPI 0x01
                              ;BNE skipSoundFalling                ;update falling sound every other 'tick'
                              ;;lda soundPitchWhileFalling
                              ;;sta pitch5
                              ;;lda #$07
                              ;;ldx #<sound5
                              ;;ldy #>sound5
                              ;;jsr OSWORD                          ;SOUND: falling
                              ;DEB soundPitchWhileFalling
skipSoundFalling:
            LDB tmpYPos
            ADI 0x02
            STB tmpYPos
            INB playerYBlkInternalDecimalOffset
            LDB playerYBlkInternalDecimalOffset
            CPI 0x07
            BNE skipS1
            CLB playerYBlkInternalDecimalOffset
skipS1:        LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE redrawPlayer
            INB playerYBlockPos ;adjust block ypos if needed
            LDI 0x1c
            ADW playerMapPtr  ; ($76,$77)
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ;inspect the tile where the player is at this very moment
            CPI 0x04          ;line
            BNE keepFalling
            JPA playerStopFalling ;encountered a line, so stop falling
keepFalling:
            LDB playerXBlockPos
            ADI 0x39
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly below the player
            CPI 0x01          ;brick
            BEQ playerStopFalling
            CPI 0x02          ;solid block
            BEQ playerStopFalling
            CPI 0x03          ;ladder
            BEQ playerStopFalling
            CPI 0x06          ;thick red bar
            BNE preRedrawPlayer2
playerStopFalling:
            CLB playerFalling ;found solid ground, so stop falling
preRedrawPlayer2:
            JPA redrawPlayer
checkWhichKeysPressed:
            LDB pressed
            CPI 0x00
            BNE checkKeyRight
            JPA redrawPlayer  ;no keys pressed
checkKeyRight:
            LDB _right
            CPI 1
            BNE checkKeyLeft
movePlayerRight:
            LDB playerXBlockPos
            ADI 0x1e
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly to the right of the player
            CPI 0x01          ;is it brick?
            BEQ cannotGoRight
            CPI 0x02          ;is it solid block?
            BEQ cannotGoRight
            CPI 0x31          ;is it trapdoor?
            BEQ cannotGoRight
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BEQ checkRightEdgeOfScreen ;vertically aligned to block, so no need to check extra tiles to the right
            LDB playerXBlockPos
            ADI 0x3a          ; ADI 0x1e+0x1c
            PHS JPS loadPlayerMapPtr PLS ;inspect floor tile directly to the bottom right of the player
            CPI 0x01          ;is it brick?
            BEQ cannotGoRight
            CPI 0x02          ;is it solid block?
            BEQ cannotGoRight
            CPI 0x31          ;is it trapdoor?
            BNE checkRightEdgeOfScreen
cannotGoRight:
            LDB playerXBlkInternalDecimalOffset
            CPI 0x01          ; cmp #$20
                              ;CPI 0x00
            BNE checkRightEdgeOfScreen
            JPA redrawPlayer  ;blocked, cannot go right
checkRightEdgeOfScreen:
            LDB playerXBlockPos
            CPI 0x1b
            BNE checkGoingRightOnLine
            LDB playerXBlkInternalDecimalOffset
            CPI 0x01          ; cmp #$20
            BNE checkGoingRightOnLine
            JPA redrawPlayer  ;at right edge of screen, cannot go right
checkGoingRightOnLine:
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ;inspect tile at the exact position of the player
            CPI 0x04          ;line
                              ;JPS _Clear ßßß
            BNE grSelectFrameWalking
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE grSelectFrameWalking
            LDB oldPlayerFrameNumber ; ldy oldPlayerFrameNumber
            CPI 0x10
            BCC grResetFrameWhileHanging
            CPI 0x12
            BCS grResetFrameWhileHanging
            JPA grSetFrameHanging
grResetFrameWhileHanging:
            LDI 0x12          ;ldy #$12 ;indicates frame 1 of player hanging on a line
grSetFrameHanging:
            LAB playerSpriteFrames ;lda playerSpriteFrames,y ;select correct player sprite frame when hanging from a line
            STB playerFrameNumber
            JPA grUpdatePos
grSelectFrameWalking:
            LDB oldPlayerFrameNumber ;ldy oldPlayerFrameNumber
            CPI 0x09          ;cpy #$09
            BCC grSetFrameWalking
            LDI 0x09          ;ldy #$09
grSetFrameWalking:
            LAB playerSpriteFrames ;lda playerSpriteFrames,y
            STB playerFrameNumber
grUpdatePos:
            LDI 0x02
            ADW tmpXPosLo
            INB playerXBlkInternalDecimalOffset
            LDB playerXBlkInternalDecimalOffset
            CPI 0x07
            BNE grUp1
            LDI 0x00
grUp1:        STB playerXBlkInternalDecimalOffset
            CPI 0x00
            BNE grUp2
            INB playerXBlockPos
grUp2:        LDI 0x01
            STB playerDirection ;i.e. player is facing right
            LDB playerXBlkInternalDecimalOffset
            CPI 0x00
            BEQ grInspectNewPos
            JPA redrawPlayer  ;done when player is not horizontally aligned to 10px block
grInspectNewPos:
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ; lta playerMapPtr    ;inspect tile exactly at the position of the player
            CPI 0x04          ;line
            BNE grInspectTileBelowNewPos
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE grInspectTileBelowNewPos
            JPA redrawPlayer  ;done when player is not vertically aligned to 10px block
grInspectTileBelowNewPos:
            LDB playerXBlockPos
            ADI 0x39          ; ADI 0x1d+0x1c
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly below the player
            CPI 0x00
            BEQ grNoSolidFloor
            CPI 0xff          ;hole
            BEQ grNoSolidFloor
            CPI 0x04          ;line
            BEQ grNoSolidFloor
            CPI 0x05          ;gold ingot
            BEQ grNoSolidFloor
            CPI 0x31          ;trapdoor
            BEQ grNoSolidFloor
            CPI 0x32          ;escape ladder
            BEQ grNoSolidFloor
            JPA redrawPlayer  ;done when there is a solid floor below the player
grNoSolidFloor:
            JPA checkIfPlayerShouldBeFalling
checkKeyLeft:
            LDB _left
            CPI 1
            BNE checkKeyDown
movePlayerLeft:
            LDB playerXBlockPos
            ADI 0x1c          ;30
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly to the left of the player
            CPI 0x01          ;is it brick?
            BEQ cannotGoLeft
            CPI 0x02          ;is it solid block?
            BEQ cannotGoLeft
            CPI 0x31          ;is it trapdoor?
            BEQ cannotGoLeft
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BEQ checkLeftEdgeOfScreen ;vertically aligned to block, so no need to check extra tiles to the left
            LDB playerXBlockPos
            ADI 0x38          ;ADI 0x1c+0x1c
            PHS JPS loadPlayerMapPtr PLS ;inspect floor tile directly to the left of the player
            CPI 0x01          ;is it brick?
            BEQ cannotGoLeft
            CPI 0x02          ;is it solid block?
            BEQ cannotGoLeft
            CPI 0x31          ;is it trapdoor?
            BNE checkLeftEdgeOfScreen
cannotGoLeft:
            LDB playerXBlkInternalDecimalOffset
            CPI 0x00
            BNE checkLeftEdgeOfScreen
            JPA redrawPlayer  ;blocked, cannot go Left
checkLeftEdgeOfScreen:
            LDB playerXBlockPos
            CPI 0x00
            BNE checkGoingLeftOnLine
            LDB playerXBlkInternalDecimalOffset
            CPI 0x00
            BNE checkGoingLeftOnLine
            JPA redrawPlayer  ;at right edge of screen, cannot go right
checkGoingLeftOnLine:
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ;inspect tile at the exact position of the player
            CPI 0x04          ;line
            BNE glSelectFrameWalking
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE glSelectFrameWalking
            LDB oldPlayerFrameNumber ; ldy oldPlayerFrameNumber
            CPI 0x13
            BCC glResetFrameWhileHanging
            CPI 0x15
            BCS glResetFrameWhileHanging
            JPA glSetFrameHanging
glResetFrameWhileHanging:
            LDI 0x15          ;ldy #$12 ;indicates frame 1 of player hanging on a line
glSetFrameHanging:
            LAB playerSpriteFrames ;lda playerSpriteFrames,y ;select correct player sprite frame when hanging from a line
            STB playerFrameNumber
            JPA glUpdatePos
glSelectFrameWalking:
            LDB oldPlayerFrameNumber ;ldy oldPlayerFrameNumber
            CPI 0x0a          ;cpy #$09
            BCC glResetFrameWalking
            CPI 0x0c
            BCS glResetFrameWalking
            JPA glSetFrameWalking
glResetFrameWalking:
            LDI 0x0c          ;ldy #$09
glSetFrameWalking:
            LAB playerSpriteFrames ;lda playerSpriteFrames,y
            STB playerFrameNumber
glUpdatePos:
            LDI 0x02
            SUW tmpXPosLo
            DEB playerXBlkInternalDecimalOffset
            LDB playerXBlkInternalDecimalOffset
            CPI 0xff
            BNE glUp1
            LDI 0x06
glUp1:        STB playerXBlkInternalDecimalOffset ;internal block offset-=20
            CPI 0x06
            BNE glUp2
            DEB playerXBlockPos
glUp2:        LDI 0x00
            STB playerDirection ;i.e. player is facing right
            LDB playerXBlkInternalDecimalOffset
            CPI 0x00
            BEQ glInspectNewPos
            JPA redrawPlayer  ;done when player is not horizontally aligned to 10px block
glInspectNewPos:
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ;lta playerMapPtr ;inspect tile exactly at the position of the player
            CPI 0x04          ;line
            BNE glInspectTileBelowNewPos
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE grInspectTileBelowNewPos
            JPA redrawPlayer  ;done when player is not vertically aligned to 10px block
glInspectTileBelowNewPos:
            LDB playerXBlockPos
            ADI 0x39          ; ADI 0x1d+0x1c
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly below the player
            CPI 0x00
            BEQ glNoSolidFloor
            CPI 0xff          ;hole
            BEQ glNoSolidFloor
            CPI 0x04          ;line
            BEQ glNoSolidFloor
            CPI 0x05          ;gold ingot
            BEQ glNoSolidFloor
            CPI 0x31          ;trapdoor
            BEQ glNoSolidFloor
            CPI 0x32          ;escape ladder
            BEQ glNoSolidFloor
            JPA redrawPlayer  ;done when there is a solid floor below the player
glNoSolidFloor:
            JPA checkIfPlayerShouldBeFalling
checkKeyDown:
            LDB _down
            CPI 1
            BNE checkKeyUp
movePlayerDown:
            LDB playerXBlockPos ;ldy playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ;inspect tile at the exact location of the player
            CPI 0x03          ;ladder
            BNE gdInspectTileBelowPlayer
; are we moving down on a ladder but standing on a solid floor?
            LDB playerXBlockPos
            ADI 0x39
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly below the player
            CPI 0x01          ;brick
            BEQ gdPreRedrawPlayer
            CPI 0x02          ;solid block
            BEQ gdPreRedrawPlayer
            CPI 0x06          ;red bar
            BEQ gdPreRedrawPlayer
            JPA gdUpdatePos   ;not standing on a solid floor so update the player position on the ladder
gdPreRedrawPlayer:
            JPA redrawPlayer  ;cannot move further down so just redraw player
gdInspectTileBelowPlayer:
            LDB playerXBlockPos ;want to move down but not on a ladder
            ADI 0x39
            PHS JPS loadPlayerMapPtr PLS
            CPI 0x00
            BEQ gdPreCheckIfFalling
            CPI 0x04          ;line
            BEQ gdPreCheckIfFalling
            CPI 0x05          ;gold ingot
            BEQ gdPreCheckIfFalling
            CPI 0x31          ;trapdoor
            BEQ gdPreCheckIfFalling
            CPI 0x32          ;escape ladder
            BEQ gdPreCheckIfFalling
            CPI 0x03          ;ladder
            BEQ gdUpdatePos   ;when moving to another ladder block then just update player pos
            JPA redrawPlayer  ;in all other cases cannot move down so just redraw player
gdPreCheckIfFalling:
            JPA checkIfPlayerShouldBeFalling
gdUpdatePos:
            LDB playerXBlockPos ;align player to 10px block horizontally
            STB mapX
            LDB playerYBlockPos
            STB mapY
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            LDB xpos16+0
            STB tmpXPosLo
            LDB xpos16+1
            STB tmpXPosHi
            LDI 0x00
            STB playerXBlkInternalDecimalOffset
            LDI 0x02
            AD.B tmpYPos
            INB playerYBlkInternalDecimalOffset
            LDB playerYBlkInternalDecimalOffset
            CPI 0x07
            BNE gdUp1
            LDI 0x00
            STB playerYBlkInternalDecimalOffset
gdUp1:        LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE noinc_L0DB7
            INB playerYBlockPos ;yblockpos-- if crossed block boundary
            LDI 0x1c
            ADW playerMapPtr
noinc_L0DB7:
        JPA selectNextUpDownPlayerFrame
checkKeyUp:
            LDB _up
            CPI 1
            BNE checkKeyDig
movePlayerUp:
            LDB playerXBlockPos ;ldy playerXBlockPos ##### player nach oben
            INC
            PHS JPS loadPlayerMapPtr PLS ;inspect tile directly above the player
            CPI 0x01          ;brick
            BEQ guPossiblyBlocked
            CPI 0x02          ;solid block
            BEQ guPossiblyBlocked
            CPI 0x31          ;trapdoor
            BNE guNotBlocked
guPossiblyBlocked:
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE guNotBlocked  ;not vertically aligned to block so still some pixel room above player
            JPA redrawPlayer  ;solid object directly above player so blocked, cannot move up
guNotBlocked:
            LDB playerXBlockPos
            ADI 0x1d          ; ADI 0x01+0x1c
            PHS JPS loadPlayerMapPtr PLS ;inspect the tile at the exact location of the player
            CPI 0x03          ;ladder
            BEQ guOnLadder
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE guPossiblyLadderBelow ;we could still be on a ladder tile (player can overlap 2 blocks)
            JPA redrawPlayer  ;definitely not on a ladder, cannot move up, just redraw player
guPossiblyLadderBelow:
            LDB playerXBlockPos
            ADI 0x39          ; ADI 0x01+0x1c+0x1c
            PHS JPS loadPlayerMapPtr PLS ;inspect the tile directly below the player
            CPI 0x03          ;ladder
            BEQ guOnLadder    ;yes, we're on a ladder after all
            JPA redrawPlayer  ;definitely not on a ladder, cannot move up, just redraw player
guOnLadder:
            LDB playerYBlockPos
            CPI 0x00
            BNE guUpdatePos
            LDB playerYBlkInternalDecimalOffset
            CPI 0x00
            BNE guUpdatePos
            JPA redrawPlayer  ;cannot move up if we have reached the very top edge of the screen, so just redraw player
guUpdatePos:
            LDB playerXBlockPos
            STB mapX
            LDB playerYBlockPos
            STB mapY
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            LDB xpos16+0
            STB tmpXPosLo
            LDB xpos16+1
            STB tmpXPosHi
            LDI 0x00
            STB playerXBlkInternalDecimalOffset
            LDI 0x02
            SU.B tmpYPos
            DEB playerYBlkInternalDecimalOffset
            LDB playerYBlkInternalDecimalOffset
            CPI 0xff
            BNE guUp1
            LDI 0x06
            STB playerYBlkInternalDecimalOffset
guUp1:        LDB playerYBlkInternalDecimalOffset
            CPI 0x06
            BNE nodec_L0E45
            DEB playerYBlockPos ;yblockpos-- if crossed block boundary
            LDI 0x1c
            SUW playerMapPtr  ;move tilemap pointer to previous row
nodec_L0E45:
            JPA selectNextUpDownPlayerFrame
updateHoles:
            LDI 0x0f          ;ldx #$0a ;start at last hole
            STB holeIndex
checkHole:
            JPS KeyHandler
            LDI <holeArray
            STB holeFillCounters+0
            LDI >holeArray
            STB holeFillCounters+1
            LDB holeIndex
            STZ 1
            LL1
            ADZ 1
            ADW holeFillCounters
            LDR holeFillCounters
            CPI 0xff
            BEQ nextHole      ;skip to next hole if current hole is not in use
            LDB holeFillCounters+0
            STB holeXBlockPos+0
            STB holeYBlockPos+0
            LDB holeFillCounters+1
            STB holeXBlockPos+1
            STB holeYBlockPos+1
            INW holeXBlockPos
            INW holeYBlockPos
            INW holeYBlockPos
            LDR holeFillCounters
            DEC
            STR holeFillCounters
            CPI 0x20          ;reached marker for first update to hole? &14=20
            BNE holeCheckSecondMarker
            LDI 0x1f          ;empty hole sprite (to erase)
            STB holeAnimFrame
            LDI 0x1d          ;first anim frame of hole filling up (to draw)
            JPA drawHole
holeCheckSecondMarker:
            CPI 0x10          ;reached marker for second update to hole? &0a=10
            BNE holeCheckThirdMarker
            LDI 0x1d          ;first anim frame of hole filling up (to erase)
            STB holeAnimFrame
            LDI 0x1e          ;second anim frame of hole filling up (to draw)
            JPA drawHole
holeCheckThirdMarker:
            CPI 0xff          ;reached marker for completing hole?
            BNE preNextHole
            LDR holeXBlockPos ; = holeXBlockPos
            STB mapX
            LDR holeYBlockPos ; = holeYBlockPos
            STB mapY
            JPS calcTileMapPtr ; Input: Koordinaten in Map mapX, mapY Output: ptrM ist Zeiger in MapArray
            LDI 0x01
            STR ptrM
            LDI 0x1e          ;second anim frame of hole filling up (to erase)
            STB holeAnimFrame
            LDI 0x01          ;brick (to draw)
            JPA drawHole
;
preNextHole:
            JPA nextHole
;
drawHole:    PHS
            LDR holeXBlockPos ; = holeYBlockPos
            STB mapX
            LDR holeYBlockPos ; = holeYBlockPos
            STB mapY
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            LDB holeAnimFrame
            STB spriteId
            JPS plotSprite14x14 ;erase
            PLS
            STB spriteId
            JPS plotSprite14x14 ;draw new hole sprite
nextHole:    DEB holeIndex
            BMI holesDone
            JPA checkHole     ;loop all over holes
holesDone:    RTS
checkKeyDig:
            LDB _digLeft
            CPI 1
            BEQ tryDiggingL
            LDB _digRight
            CPI 1
            BEQ tryDigging
            JPA preRedrawPlayer
tryDiggingL:
            LDI 0x00
tryDigging:
            STB playerDirection ; 0 = left 1 = right
            CLB _digLeft
            CLB _digRight
            LDB playerDirection
            CPI 0x00
            BEQ digPlayerFacingLeft
            LDB playerXBlockPos
            CPI 0x1b
            BEQ preRedrawPlayer
            LDI 0x1e          ;ldy #$1e    ;player is facing right, so first inspect tile directly to the right of player (not floor tile!)
            JPA digInspectTile ;jump always
digPlayerFacingLeft:
            LDB playerXBlockPos
            CPI 0x00
            BEQ preRedrawPlayer
            LDI 0x1c          ;ldy #$1c    ;player is facing left, so first inspect tile directly to the leftof player (not floor tile!)
            PHS
            LDB playerXBlkInternalDecimalOffset ;lda playerXBlkInternalDecimalOffset
            CPI 0x00
            PLS
            BEQ digInspectTile ;digInspectTile
                              ;INC                                    ;iny
digInspectTile:
                              ;tya
                              ;clc
            ADB playerXBlockPos ;adc playerXBlockPos
            STZ 1             ;tay
            PHS JPS loadPlayerMapPtr PLS ;lda ($76),y    ;first inspect tile directly to the left or right of player (not floor tile!)
            CPI 0x00
            BEQ digCheckBrick ;beq digCheckBrick
            CPI 0x32          ;cmp #$32    ;escape ladder
            BEQ digCheckBrick ;beq digCheckBrick
            CPI 0xff          ;cmp #$ff    ;hole
; can only dig brick under empty tile, under (invisible) escape ladder or under
; another hole
            BNE preRedrawPlayer ;in all other cases, don't dig, just redraw player
digCheckBrick:
            LDZ 1
            ADI 0x1c
            STZ 1
            PHS JPS loadPlayerMapPtr PLS ;lda ($76),y    ;inspect the floor tile directly to the left or right of player
            CPI 0x01          ;brick
            BNE preRedrawPlayer ;can only dig in brick, otherwise just redraw player
            MIZ 0xff,0
                              ;sta ($76),y                         ;mark as hole
            LDZ 1
            PHS JPS storePlayerMapPtrX PLS
            MIZ 0x16,0        ;assume standing player facing right
            LDB playerDirection
            CPI 0x00
            BNE digSetPlayerFrame ;hole right
            INZ 0             ;standing player facing left
digSetPlayerFrame:
            LDZ 0
            STB playerFrameNumber
            LDB playerDirection
            CPI 0x00
            BNE startDigging  ;hole right
            LDB playerXBlkInternalDecimalOffset ;hole is left
            CPI 0x00
            BEQ startDigging
                              ;INB playerXBlockPos                 ;adjust xblockpos
startDigging:
            LDB playerXBlockPos ;align to 10px block horizontally
            STB mapX
            LDB playerYBlockPos
            STB mapY
            JPS calcMapPtr2Pixel
            LDB xpos16+0
            STB tmpXPosLo
            LDB xpos16+1
            STB tmpXPosHi
            LDI 0x00
            STB playerXBlkInternalDecimalOffset
            LDI 0x05
            STB indexAnimDigHole ;first frame for digging a hole
            LDI 0x01
            STB diggingHole   ;busy digging a hole now
            MBZ playerXBlockPos,0
            LDB playerDirection
            CPI 0x00
            BEQ saveHolePosFacingLeft
            INZ 0
            JPA saveHolePos   ;facing right
saveHolePosFacingLeft:
            DEZ 0
saveHolePos:
            LDZ 0
            STB xBlockPosDigHole
            STB mapX
            LDB playerYBlockPos
            INC
            STB yBlockPosDigHole
            STB mapY
            JPS calcMapPtr2Pixel
            LDB xpos16+0
            STB xPosDigHoleLo
            LDB xpos16+1
            STB xPosDigHoleHi
            LDB ypos8
            STB yPosDigHole
; here we have saved the block and pixel position of the freshly dug hole
preRedrawPlayer:
            JPA redrawPlayer  ;and finally redraw player
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; A = (playerMapPtr),A = *(playerMapPtr+A)
loadPlayerMapPtr:
            LDB playerMapPtr+0
            STB lPaddr+0
            LDB playerMapPtr+1
            STB lPaddr+1
            LDS 3
            ADW lPaddr
            LDB
lPaddr:        0x0000
            STS 3
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; A = (ptrM),A = *(ptrM+A)
loadEnemyPtrM:
            LDB ptrM+0
            STB lEaddr+0
            LDB ptrM+1
            STB lEaddr+1
            LDS 3
            ADW lEaddr
            LDB
lEaddr:        0x0000
            STS 3
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; (ptrM),Y = A
saveEnemyPtrM:
            LDB ptrM+0
            STB sEaddr+0
            LDB ptrM+1
            STB sEaddr+1
            LDZ 1
            ADW sEaddr
            LDS 3
            STB
sEaddr:        0x0000
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Input: Y = Enemy Index A: Index Im Array Output: A = Inhalt
loadEnemyYidxA:
            LDI <enemyArray
            STB lEYA1+0
            LDI >enemyArray
            STB lEYA1+1
            LDZ 1             ; A = Index Enemy
            LL1               ; *2
            ADW lEYA1         ;
            LDR lEYA1
            PHS
            INW lEYA1
            LDR lEYA1
            STB lEYA1+1
            PLS
            STB lEYA1+0
            LDS 3
            ADW lEYA1
            LDB
lEYA1:        0x0000
            STS 3
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
storePlayerMapPtrX:
            LDB playerMapPtr+0
            STB sPaddr+0
            LDB playerMapPtr+1
            STB sPaddr+1
            LDS 3
            ADW sPaddr
            LDZ 0
            STB
sPaddr:        0x0000
            STS 3
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
delayLong:    MIZ <delayValue,1
            JPA delay1
delayLevel:    MIZ 0x00,1
            JPA delay1
delay:        MIZ 0x10,1      ; 8
delay1:        MIZ 0x00,0     ; 7
            JPS KeyHandler
delay2:        DEZ 0          ; 7
            BNE delay2        ; 5 12*256=3072*167ns=0,513024ms
            DEZ 1             ; 8
            BNE delay1        ; 5 (20+3072)*16=49472
            RTS               ; 12 smmed: 14+8+12+49472=49506*167ns=8,267502ms
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
addNewHole:
            LDI <holeArray
            STB ptr1+0
            LDI >holeArray
            STB ptr1+1
            MIZ 0x00,0        ; ldx #$00
findUnusedHole:
            LDR ptr1          ; lda holeFillCounters,x
            CPI 0xff          ;$ff means slot unused
            BEQ setHoleInfo   ;found unused hole slot
            LDI 3
            ADW ptr1
            INZ 0
            LDI 0x10          ; cpx #$0b ;max 11 holes -> expanded to 16
            CPZ 0
            BNE     findUnusedHole
                              ; issues at this point the 12 hole is used
setHoleInfo:
            LDZ 0
            STB holeIndex
            LDI 0xfe          ;LDI 0x82 (* 7/5 = 0xb6) ;initial counter value for a new hole (determines fill rate)
            STR ptr1          ; holeFillCounters = 0x82
            INW ptr1          ; Pointer to holeXBlockPos
            LDB xBlockPosDigHole
            STR ptr1          ; holeXBlockPos = xBlockPosDigHole
            INW ptr1          ; Pointer to holeYBlockPos
            LDB yBlockPosDigHole
            STR ptr1          ; holeYBlockPos = yBlockPosDigHole
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
selectNextUpDownPlayerFrame:
            LDB oldPlayerFrameNumber
            CPI 0x0d
            BEQ updownSetFrame
            CPI 0x0e
            BEQ updownSetFrame
            LDI 0x0d
updownSetFrame:
            LAB playerSpriteFrames
            STB playerFrameNumber
            JPA redrawPlayer
                              ;--------------------
checkIfPlayerShouldBeFalling:
            MBZ numberOfEnemies,1 ; ldy numberOfEnemies
            LDB playerYBlockPos ; ldy playerYBlockPos
            INC               ; iny ; tya            ;check for all enemies if they happen to be directly below the player
sbfNextEnemy:
            PHS
            LDI <_enemyYBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyYBlockPos,y
            STZ 0
            LDS 1
            CPZ 0             ;cmp enemyYBlockPos,y
            BNE sbfNoEnemyMatch
            LDB playerXBlockPos
            PHS
            LDI <_enemyXBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyXBlockPos,y
            STZ 0
            PLS
            CPZ 0             ;cmp enemyXBlockPos,y
            BNE sbfNoEnemyMatch
            PLS
            JPA redrawPlayer  ;yes, enemy below player. You can actually walk on enemies!
sbfNoEnemyMatch:
            DEZ 1
            PLS
            BPL sbfNextEnemy
; no solid floor (including enemies) below the player
; this means we should start falling
; unless we are on a ladder
            LDB playerXBlockPos
            STB mapX
            LDB playerYBlockPos
            STB mapY
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            LDB xpos16+0
            STB tmpXPosLo
            LDB xpos16+1
            STB tmpXPosHi
            CLB playerXBlkInternalDecimalOffset
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS ;inspect the tile at the exact location of the player
            CPI 0x03          ;ladder
            BEQ redrawPlayer  ;cannot fall when we are on a ladder, so we're done here - cannot fall when we are on a ladder, so we're done here
; prepare falling sequence (frames, sound)
            LDI 0x01
            STB playerFalling
;                lda     #$a0
;                sta     soundPitchWhileFalling
            LDI 0x0f
            STB playerFrameNumber
;.redrawPlayer   lda     #$13                            ; Wait for vertical sync (0..16.6833)ms
redrawPlayer:
            JPS drawOrErasePlayerSprite ; erase player
            LDB tmpXPosLo
            STB oldPlayerXPosLo
            LDB tmpXPosHi
            STB oldPlayerXPosHi
            LDB tmpYPos
            STB oldPlayerYPos
            LDB playerFrameNumber
            STB oldPlayerFrameNumber
            JPS drawOrErasePlayerSprite ; draw player
            LDB playerXBlockPos
            ADI 0x1d
            PHS JPS loadPlayerMapPtr PLS
            CPI 0x05          ;gold ingot
            BEQ collectGoldIngot
            CPI 0x01          ;brick
            BNE rpDone
            STB playerIsDead  ;permanently trapped in a hole, i.e. dead
rpDone:        JPA preCheckKeys
collectGoldIngot:
            LDB playerMapPtr+0 ;mark empty tile in tilemap where gold ingot was
            STB coll1+0
            LDB playerMapPtr+1
            STB coll1+1
            LDB playerXBlockPos
            ADI 0x1d
            ADW coll1
            CLB
coll1:        0x0000
            LDB playerXBlockPos
            STB mapX
                              ;JSR times14_16bit
            LDB playerYBlockPos
            STB mapY
                              ;JSR times14
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            LDI 0x05          ;gold ingot
            STB spriteId
            JPS plotSprite14x14 ;erase
            MIZ 0x50,0
            MIZ 0x02,1
            JPS addYXtoScoreBCD ;score+=250
            LDI 0x05
            STB soundIndexGold ;start sound for collecting a gold ingot
            DEB numberOfGoldIngots
            BNE preCheckKeys
; collected all gold ingots: replace all escape ladder blocks in the tilemap
; with regular ladder blocks so we can exit the level
            LDI 0x01
            STB allGoldCollected
            STB playingSoundAllGold
            LDI 0x00
            STB mapX
            STB mapY
            LDI <tileMap
            STB ptr1+0
            LDI >tileMap
            STB ptr1+1
replaceEscapeLadder:
            LDR ptr1          ;LDA ($74),y
            CPI 0x32          ;escape ladder
            BNE nextTileInRow
            LDI 0x03          ;ladder
            STR ptr1          ;replace escape ladder with regular ladder in tilemap
            STB spriteId
            JPS calcMapPtr2Pixel
            JPS plotSprite14x14 ;also draw ladder blocks on screen
nextTileInRow:
            INW ptr1
            INB mapX
            LDB mapX
            CPI 0x1c          ;28 blocks in a row
            BNE replaceEscapeLadder
            INB mapY
            LDB mapY
            CPI 0x11          ;16+1 rows
            BEQ preCheckKeys  ;done?
            CLB mapX
            JPA replaceEscapeLadder
preCheckKeys:
            JPA checkKeys
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
initVariables:
            LDI <holeArray
            STB ptr1+0
            LDI >holeArray
            STB ptr1+1
            MIZ 0x0f,0        ;ldx #$0a ;mark max 16 (11) holes as inactive
ivInitHoles:
            LDI 0xff
            STR ptr1
            LDI 3
            ADW ptr1
            DEZ 0
            BPL ivInitHoles
            LDI <enemyArray0
            STB ptr1+0
            LDI >enemyArray0
            STB ptr1+1
            MIZ 6,0           ;initialize enemy data (max 6 enemies)
ivInitEnemies:
            MIZ 14,1
ivInitEnemies1:
            LDI 0
            STR ptr1
            INW ptr1
            DEZ 1
            BNE ivInitEnemies1
                              ;LDI 1
                              ;STR ptr1
            DEZ 0
            BNE ivInitEnemies
            CLB playerFalling
            CLB allGoldCollected
            CLB diggingHole
            CLB released_cntr
            CLB _right
            CLB _left
            CLB _up
            CLB _down
            CLB _digLeft
            CLB _digRight
            CLB _escape
            CLB _quit
            CLB pressed
            LDI 1
            STB gameRun
            RTS
            NOP NOP
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
updateEnemies:
            LDI 0xff          ; ldx #$ff
            STB enemyIndex    ; stx enemyIndex
nextEnemy:
            INB enemyIndex    ; inc enemyIndex
            LDB enemyIndex    ; lda enemyIndex
            CPI 0x06          ; cmp #$06 enemyIndex=0..5 ;process 6 enemies but note that only max 5 are ever drawn
            BEQ waitVsyncAndReturn ; beq waitVsyncAndReturn
            JPS loadEnemyPointer
                              ; ldx enemyIndex
                              ; inc enemyCounter,x
            LDR enemyCounter
            INC
            STR enemyCounter
                              ; lda enemyCounter,x
            ANI 0x01          ; and #$01
            CPI 0x01
            BEQ nextEnemy     ;do not update this enemy if its counter is even
            LDB enemyIndex    ; cpx numberOfEnemies
            CPB numberOfEnemies
            BEQ updateEnemy
            BCS delayLoop     ; do a delay if this enemy is inactive // to keep a similar speed independent of number of active enemies
            JPA updateEnemy   ; update active (valid) enemies only
waitVsyncAndReturn:
                              ; lda #$13 ; Wait for vertical sync (0..16.6833)ms
                              ;jmp OSBYTE ;*FX19
            RTS
delayLoop:    MIZ 0x02,0      ;delay loop
            MIZ 0x40,1
delayLoop2:    JPS KeyHandler
            DEZ 1
            BNE delayLoop2
            DEZ 0
            BNE delayLoop2
            JPA nextEnemy
updateEnemy:
            LDR enemyXPosLo
            STB tmpXPosLo
            LDR enemyXPosHi
            STB tmpXPosHi     ;xpos 16-bit in pixels not blocks
            LDR enemyYPos
            STB tmpYPos       ;ypos in pixels not blocks
            LDR enemyFrames
            STB enemyFrameNumber
            LDR enemyFalling
            CPI 0x00
            BEQ ueNotFalling
; enemy is falling, update vertical position
            LDI 2
            AD.B tmpYPos      ;2 pixels down
            LDR enemyYBlkInternalDecimalOffset
            INC
            STR enemyYBlkInternalDecimalOffset ;internal block offset
            CPI 0x07
            BNE updE01
            LDI 0x00
            STR enemyYBlkInternalDecimalOffset
            LDR enemyYBlockPos
            INC
            STR enemyYBlockPos ;update block pos if needed
updE01:        LDR enemyYBlkInternalDecimalOffset
            CPI 0x00
            BNE preCheckSpecialCases
; enemy is vertically aligned to 10px block
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            LDR enemyXBlockPos
            STB mapX
            JPS calcTileMapPtr
            LDR ptrM          ;inspect tile at exact location of enemy
            CPI 0x04          ;cmp #$04 ;line
            BEQ ueStopFalling ;encountered a line so stop falling
            LDI 0x1c
            ADW ptrM
            LDR ptrM          ;inspect tile directly below enemy
            CPI 0x01          ;cmp #$01 ;brick
            BEQ ueStopFalling
            CPI 0x02          ;solid block
            BEQ ueStopFalling
            CPI 0x03          ;ladder
            BEQ ueStopFalling
            CPI 0x06          ;red bar
            BEQ ueStopFalling
            CPI 0xff          ;hole
            BNE preCheckSpecialCases
ueStopFalling:
            LDI 0x00
            STR enemyFalling  ;mark as no longer falling
preCheckSpecialCases:
            PHS JPS KeyHandler PLS
            JPA ueCheckSpecialCases
;
ueNotFalling:
            LDR enemyInHoleHeight
            CPI 0x00
            BEQ ueIsEnemyDoneInHole ;already at bottom of hole (or not in a hole?)
; busy dropping into a hole, so update ypos of enemy
            LDI 0x02
            AD.B tmpYPos
            LDR enemyYBlkInternalDecimalOffset
            INC
            STR enemyYBlkInternalDecimalOffset ;internal block offset
            CPI 0x07
            BNE ueNo01
            LDI 0x00
            STR enemyYBlkInternalDecimalOffset
            LDR enemyYBlockPos
            INC
            STR enemyYBlockPos ;update block pos if needed
ueNo01:        LDR enemyInHoleHeight
            DEC
            STR enemyInHoleHeight
            BNE preCheckEnemyTrapped ;haven't reached bottom of hole yet
            LDR enemyHoldsGoldIngot
            CPI 0x00
            BEQ ueEnemyReachedBottomOfHole ;no gold ingot to leave behind
; reached bottom of hole and possibly leave gold ingot behind just above it
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            DEC
            STB mapY
            LDR enemyXBlockPos
            STB mapX
            JPS calcTileMapPtr
            LDR ptrM          ;inspect tile directly above enemy
            CPI 0x00
            BNE ueEnemyReachedBottomOfHole ;already something there so cannot leave gold ingot behind
            LDI 0x05
            STR ptrM          ;STA ($80),y ;place gold ingot in tilemap directly above enemy
            STB spriteId
            LDI 0x00
            STR enemyHoldsGoldIngot ;no longer holding gold ingot
            JPS KeyHandler
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            JPS plotSprite14x14 ;tilemap was updated, now also draw the gold ingot
ueEnemyReachedBottomOfHole:
            LDI 0x32          ;LDI 0x1e *7/5 = 0x2a &1e=30
            STR enemyInHoleCountdown ;counts the time spent in a hole
            MIZ 0x75,0
            MIZ 0x00,1
            JPS addYXtoScoreBCD ;score+=75 for making an enemy fall into a hole
preCheckEnemyTrapped:
            JPA ueCheckEnemyTrapped
;
ueIsEnemyDoneInHole:
            LDR enemyInHoleCountdown
            CPI 0x00
            BNE ueUpdateHoleCounter ;not yet time to climb out of hole
            JPA ueIsEnemyRespawning ;at bottom of hole for a while, check if respawning is needed
;
ueUpdateHoleCounter:
            LDR enemyInHoleCountdown
            DEC
            STR enemyInHoleCountdown
;                lda     enemyInHoleCountdown,x
            BNE ueCheckAlmostOutOfHole ;still stuck in hole, but almost time to get out?
            JPA ueDoneClimbingOutOrRespawning ;done in hole, time to climb out (or respawn if trapped)
;
ueCheckAlmostOutOfHole:
            CPI 0x0b          ;CPI 0x09        ;almost time to climb out of hole, so jiggle the enemy left and right
            BEQ ueNudgeLeft
            CPI 0x0a          ;CPI 0x08
            BEQ ueNudgeRight
            CPI 0x09          ;CPI 0x07
            BEQ ueNudgeLeft
            CPI 0x08          ;CPI 0x06
            BEQ ueNudgeRight
            BCC ueClimbingOutOfHole ;use last few frames to climb up out of the hole
            JPA ueCheckEnemyTrapped ;not close to getting out of hole, so spend more time in hole
;
ueNudgeLeft:
            JPS KeyHandler
            LDI 1
            SUW tmpXPosLo
            JPA ueCheckEnemyTrapped
;
ueNudgeRight:
            JPS KeyHandler
            LDI 1
            ADW tmpXPosLo
            JPA ueCheckEnemyTrapped
;
ueClimbingOutOfHole:
            LDR enemyFrames   ;alternate between two up/down sprite frames for enemy
            CPI 0x26
            BEQ ueSelectOtherUpDownFrame
            LDI 0x26
            JPA ueSetUpDownFrame ;bne ueSetUpDownFrame    ;jump always
;
ueSelectOtherUpDownFrame:
            LDI 0x27
ueSetUpDownFrame:
            STB enemyFrameNumber ;enemy up/down sprite #1 or #2
            LDI 2
            SU.B tmpYPos      ;ypos-=2 because enemy is climbing out of a hole
            LDR enemyYBlkInternalDecimalOffset
            DEC
            STR enemyYBlkInternalDecimalOffset
            CPI 0xff
            BNE ueCheckEnemyTrapped
            LDI 0x06
            STR enemyYBlkInternalDecimalOffset
            LDR enemyYBlockPos
            DEC
            STR enemyYBlockPos
ueCheckEnemyTrapped:
            LDR enemyXBlkInternalDecimalOffset
            CPI 0x00
            BNE preCheckSpecialCases2
; enemy is horizontally aligned
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            LDR enemyXBlockPos
            STB mapX
            JPS KeyHandler
            JPS calcTileMapPtr ; Output: ptrM ist Zeiger in MapArray Input(mapX, mapY)
            LDR ptrM          ;inspect tile at exact location of enemy
            CPI 0x01          ;brick? i.e. got permanently stuck in hole
            BNE preCheckSpecialCases2
; enemy trapped in hole, make it respawn at top of screen
            LDI 0x00
            STR enemyXBlkInternalDecimalOffset
            STR enemyYBlkInternalDecimalOffset
            STR enemyInHoleHeight
            STR enemyInHoleCountdown
            STR enemyYBlockPos
            LDI <tileMap
            STB ptrM+0
            LDI >tileMap
            STB ptrM+1
            MBZ playerXBlockPos,1
ueFindHorizontalRespawnLocation:
            LDZ 1 PHS JPS loadEnemyPtrM PLS ;LDR ptrM ; A = (ptrM),A = *(ptrM+A) ;find a suitable horizontal location to respawn enemy
            CPI 0x00
            BEQ uePrepareToRespawnEnemy ;empty tile
            CPI 0x32          ;escape ladder
            BEQ uePrepareToRespawnEnemy
            INZ 1
            LDZ 1
            CPI 0x1c          ;inspect max 28 locations in this tilemap row
            BNE ueFindHorizontalRespawnLocation
; no suitable respawn location in this tilemap row, so move to the next row
            LDI 0x1c
            ADW ptrM
            LDR enemyYBlockPos
            INC
            STR enemyYBlockPos
            MIZ 0x00,1        ;start from beginning of tilemap row
            JPA ueFindHorizontalRespawnLocation ;keep looking for a respawn location
;
uePrepareToRespawnEnemy:
            LDZ 1
            STR enemyXBlockPos
            LDI 0x0a
            STR enemyRespawnCountdown ;wait a short while before actually respawning enemy
            LDI 0x1f
            STB enemyFrameNumber ;empty frame
            MIZ 0x75,0
            MIZ 0x00,1
            JPS addYXtoScoreBCD ;score+=75 for making the enemy respawn
preCheckSpecialCases2:
            JPA ueCheckSpecialCases
;
ueIsEnemyRespawning:
            LDR enemyRespawnCountdown
            CPI 0x00
            BEQ ueDoneClimbingOutOrRespawning ;at end of respawn countdown
; enemy is in the process of respawning
deb1:        CPI 0x09
            BNE ueNextRespawnFrame
; setup respawn at countdown==9
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            LDR enemyXBlockPos
            STB mapX
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
            LDB xpos16+0
            STB tmpXPosLo
            LDB xpos16+1
            STB tmpXPosHi
            LDB ypos8
            STB tmpYPos       ;calc enemy pixel xpos and ypos at respawn point
            LDI 0x2f
            STB enemyFrameNumber ;enemy respawn frame #1
            JPA ueCountdownRespawn
ueNextRespawnFrame:
            CPI 0x06
            BNE ueFinalRespawnFrame
            LDI 0x30
            STB enemyFrameNumber ;enemy respawn frame #2
            JPA ueCountdownRespawn
ueFinalRespawnFrame:
            CPI 0x03
            BNE ueCountdownRespawn
            LDI 0x28
            STB enemyFrameNumber ;enemy up/down #3 (falling)
ueCountdownRespawn:
            LDR enemyRespawnCountdown
            DEC
            STR enemyRespawnCountdown
            JPA ueCheckSpecialCases
ueDoneClimbingOutOrRespawning:
            JPS KeyHandler
            LDI 0x00
            STB distanceToPassageGoingLeft
            STB distanceToPassageGoingRight
; enemy is no longer either climbing out of a hole or respawning after getting
; trapped in a hole. So now we check for collision with the player and update
; the enemy position (moves enemy towards the player if possible)
;{{Der Feind klettert nicht mehr aus einem Loch oder erscheint wieder, nachdem er es erreicht hat
; in einem Loch gefangen. Jetzt pr√ºfen wir, ob eine Kollision mit dem Player vorliegt, und f√ºhren ein Update durch
; die Position des Feindes (bewegt den Feind, wenn m√∂glich, auf den Spieler zu)}}
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            CPB playerYBlockPos ;cmp playerYBlockPos
            BEQ ueEnemyAtSameBlockRowAsPlayer ;beq ueEnemyAtSameBlockRowAsPlayer
            BCC ueEnemyHigherThanPlayer ;bcc ueEnemyHigherThanPlayer
            JPA uePlayerHigherThanEnemy ;jmp uePlayerHigherThanEnemy
ueEnemyAtSameBlockRowAsPlayer:
            LDR enemyYBlkInternalDecimalOffset
            CPI 0x00
            BEQ uePreCheckEnemyXPos
            JPA ueEnemyStraightUp
uePreCheckEnemyXPos:
            JPA ueCheckEnemyXPos ;enemy vertically aligned to 10px block and at same height as player, now check xpos if collision or...
; enemy is higher up on screen than the player
; if we want the enemy to move down towards the player, there must be no
; obstruction
; first, check if another enemy is obstructing the current enemy by being
; directly below it
;{{Der Feind befindet sich weiter oben auf dem Bildschirm als der Spieler
; Wenn wir wollen, dass sich der Feind auf den Spieler zubewegt, darf es keins geben
; Obstruktion
; √úberpr√ºfen Sie zun√§chst, ob ein anderer Feind den aktuellen Feind behindert
; direkt darunter}}
ueEnemyHigherThanPlayer:
            STB mapY
            JPS KeyHandler
            JPS calcTileMapRowPtr ;jsr calcTileMapRowPtr ; input: A=tilemap row number, output: $81/$80=tilemap row ptr = tileMap+28*row
            MBZ numberOfEnemies,1 ;ldy numberOfEnemies
            LDR enemyXBlockPos ;lda enemyXBlockPos,x
ueCheckIfEnemyBelow:
            PHS               ;pha (enemyXBlockPos,x)
            LDI <_enemyXBlockPos PHS JPS loadEnemyYidxA PLS ;     A=enemyXBlockPos,y
            STZ 0
            LDS 1
            CPZ 0             ;cmp enemyXBlockPos,y
            BNE ueNextEnemy   ;bne ueNextEnemy
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            INC               ;clc ;adc #$01
            PHS
            LDI <_enemyYBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyYBlockPos,y
            STZ 0
            PLS
            CPZ 0             ;cmp enemyYBlockPos,y
            BNE ueNextEnemy
            PLS               ;pla
            JPA ueCheckSpecialCases ;jmp ueCheckSpecialCases ;yes another enemy is directly below the current enemy
ueNextEnemy:
            DEZ 1             ;dey
            PLS               ;pla
            BPL ueCheckIfEnemyBelow
; no enemy obstructing the way down towards the player, but maybe something else
; is? scan the tiles to the left of the enemy, in the current row and in the row
; directly beneath it. Kind of measuring the distance from enemy to a passage
; down towards the player for later checking which is better: going left versus
; going right
            LDR enemyXBlockPos ;ldx enemyIndex ;ldy enemyXBlockPos,x
            STZ 1
ueScanRowsLeftOfEnemy:
            LDZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x01          ;cmp #$01   ;brick
            BEQ ueMovingLeftAndDownImpossible
            CPI 0x02          ;solid block
            BEQ ueMovingLeftAndDownImpossible
            CPI 0x31          ;trapdoor
            BEQ ueMovingLeftAndDownImpossible
            LDZ 1             ;tya
            ADI 0x1c          ;clc ;adc #$1c
                              ;TAY                                ;tay
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly below enemy
            CPI 0x00
            BEQ ueStartScanningRowsRightOfEnemy ;empty tile
            CPI 0x03          ;ladder
            BEQ ueStartScanningRowsRightOfEnemy
            CPI 0x31          ;trapdoor
            BEQ ueStartScanningRowsRightOfEnemy
            CPI 0x32          ;escape ladder
            BEQ ueStartScanningRowsRightOfEnemy
            INB distanceToPassageGoingLeft ;increase distance to nearest passage of moving left and down to reach the player
            DEZ 1             ;tya ;sec ;sbc #$1c ;tay ;dey
            BPL ueScanRowsLeftOfEnemy ;scan until left edge of screen
ueMovingLeftAndDownImpossible:
            LDI 0xff          ;lda #$ff
falseLabel1:
            STB distanceToPassageGoingLeft ;$ff means there is no route going left // &&&& falseLabel1 generated because of self-modifying code referencing &1900
ueStartScanningRowsRightOfEnemy:
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x    -> A = X-Position F√§nger
            STZ 1             ; Y = A = X-Position F√§nger
ueScanRowsRightOfEnemy:
            LDZ 1
            PHS JPS loadEnemyPtrM PLS ; A = (ptrM),A = *(ptrM+A); inspect tile at exact location of enemy
            CPI 0x01          ;brick
            BEQ ueMovingRightAndDownImpossible
            CPI 0x02          ;solid block
            BEQ ueMovingRightAndDownImpossible
            CPI 0x31          ;trapdoor
            BEQ ueMovingRightAndDownImpossible
            LDZ 1             ;tya
                              ;clc
            ADI 0x1c          ;adc #$1c
                              ;tay
            PHS JPS loadEnemyPtrM PLS ; A = (ptrM),A = *(ptrM+A);inspect tile directly below enemy
            CPI 0x00
            BEQ ueDetermineEnemyDirection ;empty tile
            CPI 0x03          ;ladder
            BEQ ueDetermineEnemyDirection
            CPI 0x31          ;trapdoor
            BEQ ueDetermineEnemyDirection
            CPI 0x32          ;escape ladder
            BEQ ueDetermineEnemyDirection
            INB distanceToPassageGoingRight ;increase distance to nearest passage of moving right and down to reach the player
                              ;tya
                              ;sec
                              ;sbc #$1c
                              ;tay
            INZ 1             ; DEZ 1     ;iny
            LDZ 1
            CPI 0x1c          ;cpy #$1c
            BNE ueScanRowsRightOfEnemy ;scan until right edge of screen
ueMovingRightAndDownImpossible:
            LDI 0xff          ;lda #$ff
            STB distanceToPassageGoingRight ;$ff means there is no route going right
ueDetermineEnemyDirection:
            LDB distanceToPassageGoingLeft
            CPI 0x00
            BEQ ueEnemyStraightDown
            CPI 0xff
            BNE ueAtLeastOneRouteToPlayer
            LDB distanceToPassageGoingRight
            CPI 0xff
            BNE ueAtLeastOneRouteToPlayer
            JPA ueCheckSpecialCases ;no route from enemy to player in either direction!
ueAtLeastOneRouteToPlayer:
            LDB distanceToPassageGoingLeft
            CPB distanceToPassageGoingRight
            BCC uePre2EnemyMovesLeftToPlayer ; F√§nger nach linke
            JPA ueEnemyMovesRightToPlayer ; F√§nger nach rechts
uePre2EnemyMovesLeftToPlayer:
            JPA ueEnemyMovesLeftToPlayer
ueEnemyStraightDown:
                              ;ldx enemyIndex
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
            CPI 0x00
            BEQ ueEnemyMovesDown
            JPA ueEnemyMovesLeftToPlayer ;enemy is not aligned to passage straight down so move a little bit left first
ueEnemyMovesDown:
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
                              ;clc
            INC               ;adc #$01
            STB mapY
            JPS calcTileMapRowPtr ;jsr calcTileMapRowPtr
            LDR enemyXBlockPos ;ldx enemyIndex ;ldy enemyXBlockPos,x
            STZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly below enemy
            CPI 0x00
            BEQ ueEnemyStartsFalling ;empty tile
            CPI 0x32          ;escape ladder
            BEQ ueEnemyStartsFalling
            CPI 0x31          ;trapdoor
            BEQ ueEnemyStartsFalling
            CPI 0x04          ;line
            BNE ueEnemyMovingDownLadder
ueEnemyStartsFalling:
            LDI 0x01
            STR enemyFalling  ;sta enemyFalling,x                  ;no solid floor tile, so enemy starts falling
            LDI 0x28
            STB enemyFrameNumber ;sta enemyFrameNumber                ;select enemy up/down frame #3 (falling)
            JPA ueCheckSpecialCases
ueEnemyMovingDownLadder:
            LDR enemyFrames   ;LDA enemyFrames,x
            CPI 0x26
            BEQ ueSelectEnemyUpDownFrame
            LDI 0x26
            BNE ueSetEnemyUpDownFrame ;jump always
ueSelectEnemyUpDownFrame:
            LDI 0x27
ueSetEnemyUpDownFrame:
            STB enemyFrameNumber ;switch between enemy up/down frames
            LDI 0x02          ;lda tmpYPos ;clc ;adc #$02
            AD.B tmpYPos      ;sta tmpYPos ;move enemy down 2px (and adjust internal block offset and block ypos if needed)
            LDR enemyYBlkInternalDecimalOffset ;lda enemyYBlkInternalDecimalOffset,x
            INC
            CPI 0x07
            BNE ueSetEnemy1
            LDI 0x00
ueSetEnemy1:
            STR enemyYBlkInternalDecimalOffset ;sta enemyYBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueCheckSpecialCases
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            INC
            STR enemyYBlockPos ;sta enemyYBlockPos,x
            JPA ueCheckSpecialCases
; player is higher up on screen than the enemy
; if we want the enemy to move up towards the player, there must be no
; obstruction
; first, check if another enemy is obstructing the current enemy by being
; directly above it
uePlayerHigherThanEnemy:
            STB mapY
            JPS KeyHandler
            JPS calcTileMapRowPtr ;jsr calcTileMapRowPtr
            MBZ numberOfEnemies,1 ;ldy numberOfEnemies
            LDR enemyXBlockPos ;ldx enemyIndex ;lda enemyXBlockPos,x
ueCheckIfEnemyAbove:
            PHS               ;pha
            LDI <_enemyXBlockPos PHS JPS loadEnemyYidxA PLS ;     A=enemyYBlockPos,y
            STZ 0
            LDS 1
            CPZ 0             ;cmp enemyXBlockPos,y
            BNE ueNextEnemy2
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            DEC               ;sec ;sbc #$01
            PHS
            LDI <_enemyYBlockPos PHS JPS loadEnemyYidxA PLS ;     A=enemyYBlockPos,y
            STZ 0
            PLS
            CPZ 0             ;cmp enemyYBlockPos,y
            BNE ueNextEnemy2
            PLS
            JPA ueCheckSpecialCases ;yes another enemy is directly above the current enemy
;
ueNextEnemy2:
            DEZ 1
            PLS
            BPL ueCheckIfEnemyAbove
; no enemy obstructing the way up towards the player, but maybe something else
; is? scan the tiles to the left of the enemy, in the current row and in the row
; directly beneath it. Kind of measuring the distance from enemy to a passage up
; towards the player for later checking which is better: going left versus going
; right
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
            STZ 1
ueScanRowsLeftOfEnemy2:
            LDZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x04          ;line
            BEQ ueIncDistanceToLeft
			CPI 0x03                            ;hack2
			BEQ hack2a
			LDZ 1 									;tya
			ADI 0x1c							;clc ;adc #$1c
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly below enemy
            CPI 0x00
            BEQ ueMovingLeftAndUpImpossible ;empty tile
hack2a:		LDZ 1
            PHS JPS loadEnemyPtrM PLS ;sec ;sbc #$1c ;tay ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x03          ;ladder
            BEQ hack1a         ;ueStartScanningRowsRightOfEnemy2
            CPI 0x01          ;brick
            BEQ ueMovingLeftAndUpImpossible
            CPI 0x02          ;solid block
            BEQ ueMovingLeftAndUpImpossible
            CPI 0x31          ;trapdoor
            BEQ ueMovingLeftAndUpImpossible
ueIncDistanceToLeft:
            INB distanceToPassageGoingLeft ;increase distance to nearest passage of moving left and up to reach the player
            DEZ 1
            BPL ueScanRowsLeftOfEnemy2 ;scan until left edge of screen
            JPA ueMovingLeftAndUpImpossible
hack1a:     LDB ptrM+0      ;check box above the ladder
            STB lEaddr+0
            LDB ptrM+1
            STB lEaddr+1
            LDI 0x1c
            SUZ 1
            SUW lEaddr
            LDR lEaddr
            CPI 0x01
            BEQ ueIncDistanceToLeft
            CPI 0x02
            BEQ ueIncDistanceToLeft
            CPI 0x31
            BEQ ueIncDistanceToLeft
            JPA ueStartScanningRowsRightOfEnemy2 ; finished passage to the left found
ueMovingLeftAndUpImpossible:
            LDI 0xff
            STB distanceToPassageGoingLeft ;$ff means there is no route going left
ueStartScanningRowsRightOfEnemy2:
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
            STZ 1
ueScanRowsRightOfEnemy2:
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x04          ;line
            BEQ ueIncDistanceToRight
			CPI 0x03                            ;hack2
			BEQ hack2b
			LDZ 1
			ADI 0x1c							;clc ;adc #$1c ;tay
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly below enemy
            CPI 0x00
            BEQ ueMovingRightAndUpImpossible
hack2b:		LDZ 1
            PHS JPS loadEnemyPtrM PLS ;sec ;sbc #$1c ;tay ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x03          ;ladder
            BEQ hack1b         ;ueDetermineEnemyDirection2
            CPI 0x01          ;brick
            BEQ ueMovingRightAndUpImpossible
            CPI 0x02          ;solid block
            BEQ ueMovingRightAndUpImpossible
            CPI 0x31          ;trapdoor
            BEQ ueMovingRightAndUpImpossible
ueIncDistanceToRight:
            INB distanceToPassageGoingRight ;increase distance to nearest passage of moving right and up to reach the player
            INZ 1
            LDZ 1
            CPI 0x1c
            BNE ueScanRowsRightOfEnemy2 ;scan until right edge of screen
            JPA ueMovingRightAndUpImpossible
hack1b:		LDB ptrM+0      ;check box above the ladder
            STB lEaddr+0
            LDB ptrM+1
            STB lEaddr+1
            LDI 0x1c
            SUZ 1
            SUW lEaddr
            LDR lEaddr
            CPI 0x01          ;brick
            BEQ ueIncDistanceToRight
            CPI 0x02
            BEQ ueIncDistanceToRight
            CPI 0x31
            BEQ ueIncDistanceToRight
            JPA ueDetermineEnemyDirection2 ; finished passage to the right found
ueMovingRightAndUpImpossible:
            LDI 0xff
            STB distanceToPassageGoingRight ;$ff means there is no route going right
ueDetermineEnemyDirection2:
            LDB distanceToPassageGoingLeft
            CPI 0x00
            BEQ ueEnemyStraightUp
            LDB distanceToPassageGoingLeft
            CPI 0xff
            BNE ueAtLeastOneRouteToPlayer2
            LDB distanceToPassageGoingRight
            CPI 0xff
            BNE ueAtLeastOneRouteToPlayer2
            JPA ueCheckSpecialCases ;no route from enemy to player in either direction!
ueAtLeastOneRouteToPlayer2:
            LDR enemyYBlkInternalDecimalOffset ;lda enemyYBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueEnemyStraightUp
            LDB distanceToPassageGoingLeft
            CPB distanceToPassageGoingRight
            BCC uePre2EnemyMovesLeftToPlayer2
            JPA ueEnemyMovesRightToPlayer
uePre2EnemyMovesLeftToPlayer2:
            JPA ueEnemyMovesLeftToPlayer
ueEnemyStraightUp:
                              ;ldx enemyIndex
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
                              ;sec
            DEC               ;sbc #$01
            STB mapY
            JPS calcTileMapRowPtr ;jsr calcTileMapRowPtr
                              ;ldx enemyIndex
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
            STZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly above enemy
            CPI 0x01          ;brick
            BEQ ueCanOnlyMoveUpIfNotAligned
            CPI 0x02          ;solid block
            BEQ ueCanOnlyMoveUpIfNotAligned
            CPI 0x31          ;trapdoor
            BNE ueEnemyMovingUpLadder
ueCanOnlyMoveUpIfNotAligned:
            LDR enemyYBlkInternalDecimalOffset ;lda enemyYBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueEnemyMovingUpLadder ;not vertically aligned to 10px block so can still move up
            JPA ueCheckSpecialCases
;
ueEnemyMovingUpLadder:
            LDR enemyXBlockPos ;lda enemyXBlockPos,x
            STB mapX
                              ;jsr times10_16bit
            JPS calcMapPtr2Pixel ; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
                              ;ldx enemyIndex
            LDB xpos16+0      ;lda $70
            STB tmpXPosLo
            LDB xpos16+1      ;lda $71
            STB tmpXPosHi
            LDI 0x00          ;lda #$00
            STR enemyXBlkInternalDecimalOffset ;sta enemyXBlkInternalDecimalOffset,x ;align enemy horizontally (snap to ladder &&&& could be improved)
            LDR enemyFrames   ;lda enemyFrames,x
            CPI 0x26
            BEQ ueSelectEnemyUpDownFrame2
            LDI 0x26
            BNE ueSetEnemyUpDownFrame2 ;jump always
ueSelectEnemyUpDownFrame2:
            LDI 0x27
ueSetEnemyUpDownFrame2:
            STB enemyFrameNumber ;switch between enemy up/down frames
                              ;lda tmpYPos
                              ;sec
                              ;sbc #$02
            LDI 0x02
                              ;sta tmpYPos
            SU.B tmpYPos      ;move enemy up 2px (and adjust internal block offset and block ypos if needed)
            LDR enemyYBlkInternalDecimalOffset ;lda enemyYBlkInternalDecimalOffset,x
            DEC
                              ;sec
                              ;sed
                              ;sbc #$20
                              ;cld
            CPI 0xff
            BNE ueSetEnemy2
            LDR enemyYBlockPos
            DEC
            STR enemyYBlockPos
            LDI 0x06
ueSetEnemy2:
            STR enemyYBlkInternalDecimalOffset ;sta enemyYBlkInternalDecimalOffset,x
                              ;lda enemyYBlockPos,x
                              ;sbc #$00
                              ;sta enemyYBlockPos,x
            JPA ueCheckSpecialCases
ueCheckEnemyXPos:
            LDR enemyXBlockPos ;lda enemyXBlockPos,x ;we already know that enemy ypos equals player ypos (in blocks)
            CPB playerXBlockPos ;cmp playerXBlockPos
            BEQ uePlayerIsDead ;ypos and xpos are matching so enemy kills player
            BCS uePre1EnemyMovesLeftToPlayer
            BCC ueEnemyMovesRightToPlayer
uePlayerIsDead:
            LDI 0x01
            STB playerIsDead  ;enemy occupies same block pos as player so that kills the player instantly
            JPA ueCheckSpecialCases
uePre1EnemyMovesLeftToPlayer:
            JPA ueEnemyMovesLeftToPlayer
ueEnemyMovesRightToPlayer:
            JPS KeyHandler
            MBZ numberOfEnemies,1 ;ldy numberOfEnemies
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
ueCheckEnemyToTheRight:
            PHS               ;pha
            LDI <_enemyYBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyYBlockPos,y
            STZ 0
            LDS 1
            CPZ 0             ;cmp enemyYBlockPos,y
            BNE ueNextEnemyToTheRight
            LDR enemyXBlockPos ;lda enemyXBlockPos,x
                              ;clc
            INC               ;adc #$01
            PHS
            LDI <_enemyXBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyXBlockPos,y
            STZ 0
            PLS
                              ;clc
                              ;adc #$01
            CPZ 0             ;cmp enemyXBlockPos,y
            BNE ueNextEnemyToTheRight
                              ; von anderem Feind blockiert
            PLS
            JPA ueCheckSpecialCases ;another enemy is blocking this enemy from moving to the right
ueNextEnemyToTheRight:
            DEZ 1
            PLS
            BPL ueCheckEnemyToTheRight
; no enemy blocking this enemy to the right, but maybe something else?
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            JPS calcTileMapRowPtr ; input: A=tilemap row number, output: $81/$80=tilemap row ptr = tileMap+28*row
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
                              ;TAY
                              ;iny
            INC
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly to the right of enemy
            CPI 0x01          ;brick
            BEQ uePossiblyMoveRightIfAligned
            CPI 0x02          ;solid block
            BEQ uePossiblyMoveRightIfAligned
            CPI 0x31          ;trapdoor
            BNE ueCheckIfMoveRightOnLine
uePossiblyMoveRightIfAligned:
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
            CPI 0x01          ;cmp #$20
            BEQ ueCannotMoveRight
            JPA ueCheckIfMoveRightOnLine
;
ueCannotMoveRight:
            JPA ueCheckSpecialCases
;
ueCheckIfMoveRightOnLine:
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x A = X-Position Feind
            STZ 1             ; Y = A = X-Position Feind
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x04          ;line
            BNE ueWalkRight
            LDR enemyFrames   ;lda enemyFrames,x
            CPI 0x29
            BCC ueSetHangingOnLineFrameA
            CPI 0x2c
            BCS ueSetHangingOnLineFrameA
            JPA ueSetHangingOnLineFrameB
;
ueSetHangingOnLineFrameA:
            LDI 0x29
ueSetHangingOnLineFrameB:
                              ;sec
            SUI 0x29          ;sbc #$29
                              ;tay
            LAB enemyFrameOffset ;lda enemyFrameOffset,y
                              ;clc
            ADI 0x29          ;adc #$29
            STB enemyFrameNumber ;sta enemyFrameNumber ;select correct frame for hanging on a line
            JPA ueMoveRightUpdatePos
ueWalkRight:
            LDR enemyFrames   ;lda enemyFrames,x
            CPI 0x20
            BCC ueSetWalkingRightFrameA
            CPI 0x23
            BCS ueSetWalkingRightFrameA
            JPA ueSetWalkingRightFrameB
ueSetWalkingRightFrameA:
            LDI 0x20
ueSetWalkingRightFrameB:
                              ;sec
            SUI 0x20          ;sbc #$29
                              ;tay
            LAB enemyFrameOffset ;lda enemyFrameOffset,y
                              ;clc
            ADI 0x20          ;adc #$29
            STB enemyFrameNumber ;sta enemyFrameNumber ;select correct frame for hanging on a line
ueMoveRightUpdatePos:
                              ;lda tmpXPosLo
                              ;clc
                              ;adc #$02
                              ;sta tmpXPosLo
                              ;lda tmpXPosHi
            LDI 0x02          ;adc #$00
            ADW tmpXPosLo     ;sta tmpXPosHi ;xpos+=2 and also update block pos and internal block offset
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
                              ;clc
                              ;sed
            INC               ;adc #$20
                              ;cld
            CPI 0x07
            BNE ueMoveR1
            LDR enemyXBlockPos ;lda enemyXBlockPos,x
            INC               ;adc #$00 ;update 10px block pos when the decimal counter wraps to 0 (100) again
            STR enemyXBlockPos ;sta enemyXBlockPos,x
            LDI 0x00
ueMoveR1:    STR enemyXBlkInternalDecimalOffset ;sta enemyXBlkInternalDecimalOffset,x
            JPA ueCheckSpecialCases
ueEnemyMovesLeftToPlayer:
            JPS KeyHandler
            MBZ numberOfEnemies,1 ;ldy numberOfEnemies
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
ueCheckEnemyToTheLeft:
            PHS               ;pha ->
            LDI <_enemyYBlockPos PHS JPS loadEnemyYidxA PLS ;     A=enemyYBlockPos,y
            STZ 0
            LDS 1
            CPZ 0             ;cmp enemyYBlockPos,y
            BNE ueNextEnemyToTheLeft
                              ; F√§nger auf gleicher H√∂he
            LDR enemyXBlockPos ;lda enemyXBlockPos,x -> A = X-Position F√§nger
                              ;sec
            DEC               ;sbc #$01
            PHS
            LDI <_enemyXBlockPos PHS JPS loadEnemyYidxA PLS ;     A=enemyXBlockPos,y
            STZ 0
            PLS
            CPZ 0             ;cmp enemyXBlockPos,y
            BNE ueNextEnemyToTheLeft
            PLS               ;pla -> A = Y-Position F√§nger
            JPA ueCheckSpecialCases ;another enemy is blocking this enemy from moving to the left
ueNextEnemyToTheLeft:
            DEZ 1
            PLS
            BPL ueCheckEnemyToTheLeft
; no enemy blocking this enemy to the left, but maybe something else?
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            JPS calcTileMapRowPtr
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
            DEC               ;dey
            STZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly to the left of enemy
            CPI 0x01          ;brick
            BEQ uePossiblyMoveLeftIfAligned
            CPI 0x02          ;solid block
            BEQ uePossiblyMoveLeftIfAligned
            CPI 0x31          ;trapdoor
            BNE ueCheckIfMoveLeftOnLine
uePossiblyMoveLeftIfAligned:
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueCheckIfMoveLeftOnLine
            JPA ueCheckSpecialCases ;cannot move left
ueCheckIfMoveLeftOnLine:      ; hier gehts nur noch nach links Frame ausw√§hlen
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
            STZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x04          ;line
            BNE ueWalkLeft
            LDR enemyFrames   ;lda enemyFrames,x
            CPI 0x2c
            BCC ueSetHangingOnLineFrameA2
            CPI 0x2f
            BCS ueSetHangingOnLineFrameA2
            JPA ueSetHangingOnLineFrameB2
ueSetHangingOnLineFrameA2:
            LDI 0x2c
ueSetHangingOnLineFrameB2:
                              ;sec
            SUI 0x2c          ;sbc #$29
                              ;tay
            LAB enemyFrameOffset ;lda enemyFrameOffset,y
                              ;clc
            ADI 0x2c          ;adc #$29
            STB enemyFrameNumber ;select correct frame for hanging on a line
            JPA ueMoveLeftUpdatePos
ueWalkLeft:
            LDR enemyFrames   ;lda enemyFrames,x
            CPI 0x23
            BCC ueSetWalkingLeftFrameA
            CPI 0x26
            BCS ueSetWalkingLeftFrameA
            JPA ueSetWalkingLeftFrameB
ueSetWalkingLeftFrameA:
            LDI 0x23
ueSetWalkingLeftFrameB:
                              ;sec
            SUI 0x23          ;sbc #$29
                              ;tay
            LAB enemyFrameOffset ;lda enemyFrameOffset,y
                              ;clc
            ADI 0x23          ;adc #$29
            STB enemyFrameNumber ;select correct frame for walking left
ueMoveLeftUpdatePos:
                              ;lda tmpXPosLo
                              ;sec
                              ;sbc #$02
                              ;sta tmpXPosLo
                              ;lda tmpXPosHi
                              ;sbc #$00
                              ;sta tmpXPosHi
            LDI 0x02
            SUW tmpXPosLo     ;xpos-=2 and also update block pos and internal block offset
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
                              ;sec
                              ;sed
                              ;sbc #$20
                              ;cld
            DEC
            CPI 0xff
            BNE ueMoveLe1
            LDR enemyXBlockPos ;lda enemyXBlockPos,x
            DEC               ;sbc #$00
            STR enemyXBlockPos ;sta enemyXBlockPos,x
            LDI 0x06
ueMoveLe1:    STR enemyXBlkInternalDecimalOffset ;sta enemyXBlkInternalDecimalOffset,x
            JPA ueCheckSpecialCases ;&&&& unneeded
ueCheckSpecialCases:
            JPS KeyHandler
                              ;ldx enemyIndex
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueEnemyCheckGoldIngot
; enemy is horizontally aligned to 10px block
            LDR enemyInHoleHeight ;lda enemyInHoleHeight,x
            CPI 0x00
            BNE ueEnemyCheckGoldIngot
            LDR enemyInHoleCountdown ;lda enemyInHoleCountdown,x
            CPI 0x00
            BNE ueEnemyCheckGoldIngot
            LDR enemyRespawnCountdown ;lda enemyRespawnCountdown,x
            CPI 0x00
            BNE ueEnemyCheckGoldIngot
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            JPS calcTileMapRowPtr
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x -> A = X-Position F√§nger
            STZ 1             ; Y = A = X-Position F√§nger
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile at exact location of enemy
            CPI 0x04          ;line
            BEQ ueEnemyCheckGoldIngot
            CPI 0x03          ;ladder
            BEQ ueEnemyCheckGoldIngot
            LDZ 1             ;tya
                              ;clc
            ADI 0x1c          ;adc #$1c
            STZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ; A = (ptrM),A = *(ptrM+A) ;inspect tile directly below enemy
            CPI 0x00
            BEQ ueEnemyStartFalling ;empty tile
            CPI 0x32          ;escape ladder
            BEQ ueEnemyStartFalling
            CPI 0x31          ;trapdoor
            BEQ ueEnemyStartFalling
            CPI 0x04          ;line
            BEQ ueEnemyStartFalling
            CPI 0x05          ;gold ingot
            BEQ ueEnemyStartFalling
            CPI 0xff          ;hole
            BNE ueEnemyCheckGoldIngot
; enemy is directly above a hole. Start falling in only if there is no other
; enemy there yet
            MBZ numberOfEnemies,1
            LDR enemyYBlockPos ;ldy enemyYBlockPos,x ;iny ;tya
            INC
ueCheckEnemyBelow:
            PHS
            LDI <_enemyYBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyYBlockPos,y
            STZ 0
            LDS 1
            CPZ 0             ;cmp enemyYBlockPos,y
            BNE ueCheckNextEnemyBelow
            LDR enemyXBlockPos ;lda enemyXBlockPos,x
            PHS
            LDI <_enemyXBlockPos PHS JPS loadEnemyYidxA PLS ; A=enemyXBlockPos,y
            STZ 0
            PLS
            CPZ 0             ;cmp enemyXBlockPos,y
            BNE ueCheckNextEnemyBelow
            PLS
            JPA ueEnemyCheckGoldIngot ;another enemy is already in the hole below the current enemy
ueCheckNextEnemyBelow:
            DEZ 1
            PLS
            BPL ueCheckEnemyBelow
; hole is not occupied so enemy is about to fall into this hole
            LDI 0x07          ;lda #$05 -> 5 for 10x10 Sprite 7 for 14x14 Sprite
            STR enemyInHoleHeight ;sta enemyInHoleHeight,x ;at very top of hole
            JPA ueEnemyFallingInHole ;jump always ;bne ueEnemyFallingInHole
ueEnemyStartFalling:
            LDI 0x01
            STR enemyFalling  ;sta enemyFalling,x
ueEnemyFallingInHole:
            LDI 0x28
            STB enemyFrameNumber ;set falling enemy frame
            JPA ueRedrawEnemy
ueEnemyCheckGoldIngot:
            LDR enemyYBlockPos ;lda enemyYBlockPos,x
            STB mapY
            JPS calcTileMapRowPtr
            LDR enemyXBlockPos ;ldy enemyXBlockPos,x
            STZ 1
            LDR enemyHoldsGoldIngot ;lda enemyHoldsGoldIngot,x
            CPI 0x00
            BEQ uePossiblyPickupGoldIngot
            LDR enemyYBlkInternalDecimalOffset ;lda enemyYBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueRedrawEnemy
; enemy has gold ingot and is vertically aligned to 10px block
            LDZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ;inspect tile at exact location of enemy
            CPI 0x00
            BNE ueRedrawEnemy ;tile is not empty so cannot leave gold ingot here
            LDZ 1
            STB tmp02         ;remember current tile offset
                              ;clc
            ADI 0x1c          ;adc #$1c
                              ;tay
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y ;inspect tile directly below enemy
            CPI 0x03          ;ladder
            BNE ueRedrawEnemy
; enemy can leave the gold ingot on an empty tile directly above a ladder
            LDI 0x00          ;lda #$00
            STR enemyHoldsGoldIngot ;sta enemyHoldsGoldIngot,x
            MBZ tmp02,1       ;ldy tmp02
            LDI 0x05          ;lda #$05
            PHS JPS saveEnemyPtrM PLS ;sta ($80),y ;place gold ingot at exact location of enemy on tilemap
            JPA ueEraseOrDrawGoldIngot
uePossiblyPickupGoldIngot:
            LDR enemyXBlkInternalDecimalOffset ;lda enemyXBlkInternalDecimalOffset,x
            CPI 0x00
            BNE ueRedrawEnemy
            LDZ 1
            PHS JPS loadEnemyPtrM PLS ;lda ($80),y inspect tile at exact location of enemy
            CPI 0x05          ;gold ingot
            BNE ueRedrawEnemy
            LDI 0x01          ;lda #$01
            STR enemyHoldsGoldIngot ;sta enemyHoldsGoldIngot,x ;enemy now holds this gold ingot
            LDI 0x00          ;lda #$00
            PHS JPS saveEnemyPtrM PLS ;sta ($80),y ;remove gold ingot from tilemap
ueEraseOrDrawGoldIngot:
            LDR enemyXBlockPos
            STB mapX
            LDR enemyYBlockPos
            STB mapY
                              ;jsr    times10_16bit
                              ;ldx    enemyIndex
                              ;lda    enemyYBlockPos,x
                              ;jsr    times10
                              ;lda    #$05                            ;gold ingot
                              ;jsr    plotSprite10x10                 ;erase (when picking up) or draw (when leaving behind) the gold ingot
            LDI 0x05
            STB spriteId
            JPS calcMapPtr2Pixel ; xpos16, ypos8 = 14 * mapX, 14 * mapY
            JPS plotSprite14x14
ueRedrawEnemy:
            JPS uePlotEnemy   ;erase enemy at old pos
                              ;LDX enemyIndex
            LDB tmpXPosLo
            STR enemyXPosLo
            LDB tmpXPosHi
            STR enemyXPosHi
            LDB tmpYPos
            STR enemyYPos
            LDB enemyFrameNumber
            STR enemyFrames
            JPS uePlotEnemy   ;draw enemy at new pos
                              ;DEB enemyIndex
                              ;BMI ueDone
            JPA nextEnemy     ;repeat until all enemies are updates and redrawn
ueDone:
            RTS
uePlotEnemy:
                              ;LDX enemyIndex
            LDR enemyXPosLo
            STB xpos16+0
            LDR enemyXPosHi
            STB xpos16+1
            LDR enemyYPos
            STB ypos8
            LDR enemyFrames
            STB spriteId
            JPS plotSprite14x14
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drawLevel:    JPS _Clear
            CLB numberOfGoldIngots
            CLB playerFalling
            LDI 0xff
            STB numberOfEnemies
            JPS buildTileMap
            LDI <tileMap
            STB tileMapPtr+0
            LDI >tileMap
            STB tileMapPtr+1
            CLB mapX
            CLB mapY
dl01:        LDR tileMapPtr
            CPI 0x00
            BEQ dlNextTile
            CPI 0x32          ; escape ladder
            BEQ dlNextTile
            CPI 0x31          ; trapdoor
            BNE dl02
            LDI 0x01
            JPA dlPrintTile
dl02:        PHS
            JPS calcMapPtr2Pixel ; xpos16, ypos8 = 14 * mapX, 14 * mapY
            PLS
            CPI 0x07          ; player
            BNE dl03
            PHS
            STB playerFrameNumber
            STB oldPlayerFrameNumber
            LDB xpos16+0      ;$71/$70 = pixel xpos of tile
            STB oldPlayerXPosLo
            LDB xpos16+1
            STB oldPlayerXPosHi
            LDB ypos8         ;tya
            STB oldPlayerYPos
            LDB mapX          ;counts tiles in a row 0..27
            STB playerXBlockPos
            LDB mapY          ;counts tilemap rows 0..15
            STB playerYBlockPos
            CLB playerFalling
            CLB playerXBlkInternalDecimalOffset
            CLB playerYBlkInternalDecimalOffset
            JPS calcTileMapRowPtr ; Input: mapY Output: ptrM = (28 * mapY) + tileMap
            LDB ptrM+0
            STB playerMapPtr+0
            LDB ptrM+1
            STB playerMapPtr+1
            LDI 0x1d
            SUW playerMapPtr
            LDI 0x00
            STR tileMapPtr
            PLS
            JPA dlPrintTile
dl03:        CPI 0x23         ;enemy
            BNE dl04
bpEn:        PHS
            LDI 0x00          ;lda #$00
            STR tileMapPtr    ;sta ($74),y    ;erase this enemy tile, because there are too many
            INB numberOfEnemies ;inc numberOfEnemies
            LDB numberOfEnemies ;ldx numberOfEnemies ;$ff means 0 enemies, 0 means 1 enemy, and so on
            CPI 0x05          ;cpx #$05 ;&& this is why there is room for max 6 enemies but max 5 are used
            BNE dlStoreEnemyPos
            DEB numberOfEnemies ;don't allow more than max enemies
            PLS
            JPA dlNextTile
dlStoreEnemyPos:
            LDB numberOfEnemies
            STB enemyIndex
            PHS
            JPS loadEnemyPointer
            PLS
            STR enemyCounter
            LDI 0x23
            STR enemyFrames
            LDB xpos16+0      ;$71/$70 = pixel xpos of tile
            STR enemyXPosLo
            LDB xpos16+1
            STR enemyXPosHi
            LDB ypos8         ;tya
            STR enemyYPos
            LDB mapX          ;counts tiles in a row 0..27
            STR enemyXBlockPos
            LDB mapY          ;counts tilemap rows 0..15
            STR enemyYBlockPos
            LDI 0x00
            STR enemyXBlkInternalDecimalOffset
            STR enemyYBlkInternalDecimalOffset
            PLS
            JPA dlPrintTile
dl04:        CPI 0x05         ;gold ingot
            BNE dlPrintTile
            PHS INB numberOfGoldIngots PLS
dlPrintTile:
            STB spriteId
            JPS calcMapPtr2Pixel ; xpos16, ypos8 = 14 * mapX, 14 * mapY
            JPS plotSprite14x14
dlNextTile:    INW tileMapPtr
            INB mapX
            CPI 28
            BNE dl01
            CLB mapX
            INB mapY
            CPI 16
            BNE dl01
                              ; Spielfeld fertig
            JPS drawStrongLine
            LDI 23
            STB _YPos
                              ;  _     _           1   2      3     3
                              ; 0123456789012345678901234567890123456789
                              ;  SCORE 1234567     MEN 005    LEVEL 001
            LDI 1
            STB _XPos
            JPS printLine
            'SCORE',0,
            LDI 19
            STB _XPos
            JPS printLine
            'MEN',0,
            LDI 30
            STB _XPos
            JPS printLine
            'LEVEL',0,
            JPS printLives
            JPS printLevel
            JPS printScore
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
printHighscore:
            LDI 3 STB _YPos
            LDI 9 STB _XPos
            JPS printLine
            'CLASSIC LODE RUNNER',0,
            INB _YPos INB _YPos
            LDI 10 STB _XPos
            JPS printLine
            'LOCAL HIGH SCORES',0,
            INB _YPos INB _YPos
            LDI 5 STB _XPos
            JPS printLine
                              ;0123456789012345678901234567890123456789
            'NO   NAME       LEVEL SCORE',0,
            JPS drawLineScore
            LDI 9 STB _YPos
            LDI <Highscore STB ptrM+0
            LDI >Highscore STB ptrM+1
            MIZ 1,0
printHSloop:
            LDI 4 STB _XPos
            LDZ 0             ; consecutive number
            CPI 10
            BNE printHS1
            LDI '1' PHS JPS printCharXY PLS
            LDI '0' PHS JPS printCharXY PLS
            JPA printHS2
printHS1:    LDI '0' PHS JPS printCharXY PLS
            LDZ 0
            ADI 48 PHS JPS printCharXY PLS
printHS2:    LDI '.' PHS JPS printCharXY PLS
            LDI 3 ADW _XPos
            LDI 11 STB tmp05  ; name 11 characters
printHS3:    LDR ptrM PHS JPS printCharXY PLS ; write names
            INW ptrM
            DEB tmp05
            BNE printHS3
            LDR ptrM
            CPI 0x00
            BNE printHS4
debHS1:        LDI 5
            JPA printHS5
printHS4:    PHS INB _XPos JPS printThreeDigitNumber PLS
            LDI 2 ADW _XPos
            INW ptrM
            LDB ptrM+0 STB ptrScore+0
            LDB ptrM+1 STB ptrScore+1
            JPS printScoreXY
            LDI 4
printHS5:    ADW ptrM
            INB _YPos
            INZ 0
            LDZ 0
            CPI 11
            BNE printHSloop
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; compares the high score list with the current score and, if necessary, enters it into the list
cmpHighscore:
            LDI <Highscore STB ptrM+0
            LDI >Highscore STB ptrM+1
            LDI 15 ADW ptrM   ; to the high byte of the score in the list
            LDI 10 STB counterHGR ; 10 entries in the list
nxtHGR1:    MIZ 4,0           ; 4 bytes bcd for score
            LDB ptrM+0 STB ptr1+0
            LDB ptrM+1 STB ptr1+1 ; ptr1 -> high byte Liste[index]
            LDI <score+3 STB ptrE+0
            LDI >score+3 STB ptrE+1 ; ptrE -> current score high byte
nxtHGR2:    LDR ptr1          ; score byte
            STB tmp01         ; tmp01 = score byte
            LDR ptrE          ; liste byte
            CPB tmp01         ; list byte - score byte
            BEQ nxtHGR2a      ; decimal place is the same
            BCS nxtHGR3       ; Decimal place is larger in list
            LDI 16 ADW ptrM   ; to the next index in the list
            DEB counterHGR
            BEQ zuwenig
            JPA nxtHGR1
nxtHGR2a:    DEW ptrE         ; decimal place was the same, compare next place
            DEW ptr1
            DEZ 0
            BNE nxtHGR2
            DEB counterHGR
            BEQ zuwenig       ; Points have not reached the end of the list
            LDI 16 ADW ptrM   ; to the next entry in the list
            JPA nxtHGR1
nxtHGR3:    DEB counterHGR    ; Enter score in list
            BEQ  nxtHGR3a1    ; last entry in the list, nothing to move
            LDB counterHGR LL4 STB counterHGR ; Counter for moving the list 16 bytes per entry
            LDI 15 SUW ptrM   ; to the first byte of the entry in the list
            LDI <Highscore+160 STB ptr1+0 STB ptrE+0
            LDI >Highscore+160 STB ptr1+1 STB ptrE+1 ; ptr1 = ptrE -> letztes byte der Liste
            LDI 16 SUW ptr1   ; copy from STB ptr1 to STB ptrE
nxtHGR3a:    DEW ptr1 DEW ptrE
            LDR ptr1 STR ptrE
            DEB counterHGR
            BNE nxtHGR3a
            JPA nxtHGR3a2
nxtHGR3a1:
            LDI 15 SUW ptrM   ; to the first byte of the entry in the list
nxtHGR3a2:
            LDI 10 STB _XPos
            LDI 9 STB _YPos
            JPS printLine
            '  *******************  ',0,
            LDI 10 STB _XPos
            LDI 11 STB _YPos
            JPS printLine
            '  *******************  ',0,
            LDI 10 STB _XPos
            LDI 10 STB _YPos
            JPS printLine
            ' * NAME:             * ',0,
            MIZ 11,0
            LDI 19 STB _XPos
nxtHGR3b:    JPS _WaitInput
            CPI 8             ; BS
            BEQ nxtHGRbs
            CPI 10            ; LF
            BEQ nxtHGRcr
            CPI 13            ; CR
            BEQ nxtHGRcr
            CPI '0'
            BCC nxtHGR3b      ; invalid character
            CPI 'a'
            BCC nxtHGR3c
            SUI 0x20          ; lower case to upper case
nxtHGR3c:    CPI 0x5b         ; 'Z'+1 (It doesn't work that way, it's in the code 0x5a 0x01)
            BCS nxtHGR3b      ; invalid character
nxtHGR3d:    STR ptrM         ; valid character
            PHS
            INW ptrM
            JPS printCharXY PLS
            DEZ 0
            BNE nxtHGR3b
            DEW ptrM
            INZ 0
            DEB _XPos
            JPA nxtHGR3b
nxtHGRbs:    LDZ 0
            CPI 11
            BEQ nxtHGR3b
            DEW ptrM
            LDI ' ' STR ptrM
            INZ 0
            DEB _XPos
            LDI ' ' PHS JPS printCharXY PLS
            DEB _XPos
            JPA nxtHGR3b
nxtHGRcr:    LDZ 0 DEZ 0
            BCC nxtHGRcr1
            LDI ' ' STR ptrM INW ptrM
            JPA nxtHGRcr
nxtHGRcr1:    LDB level
            STR ptrM INW ptrM
            LDI <score STB ptrE+0
            LDI >score STB ptrE+1
            MIZ 4,0
nxtHGR5:    LDR ptrE STR ptrM
            INW ptrE INW ptrM
            DEZ 0
            BNE nxtHGR5
            JPS _Clear
            LDI 1             ; new entry in list
            RTS
zuwenig:    LDI 0             ; no new entry in the list
            RTS
counterHGR:    0x00,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
saveHighscore:
            LDI <fileNameHGS
            STB _ReadPtr+0
            LDI >fileNameHGS
            STB _ReadPtr+1
            JPS _FindFile
			CPI 0
            BEQ loadHighscore
			LDI 0xaa WDB 0x0555,0x05                  ; INIT FLASH WRITE PROGRAM
			LDI 0x55 WDB 0x0aaa,0x02
			LDI 0xa0 WDB 0x0555,0x05
			LDI 0 WDR PtrA                            ; START WRITE PROCESS
			MIZ 20,Z0                                 ; re-read a maximum times
de_delcheck: DEZ Z0 BCC saveHighRTS                    ; write took too long => ERROR!!!
			RDR PtrA CPI 0 BNE de_delcheck          ; re-read FLASH location -> data okay?
            JPA loadHighscore
saveHighRTS: RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
loadHighscore:
            LDI <fileNameHGS STB _ReadPtr+0
            LDI >fileNameHGS STB _ReadPtr+1
            JPS _FindFile
            CPI 0
            BNE hgrFound1
                              ; no file there, so create a new one
            LDI <Highscore PHS LDI >Highscore PHS ; first address
            LDI <Highscore+159 PHS LDI >Highscore+159 ; last address
            PHS
            JPS _SaveFile
            PLS PLS PLS PLS
            RTS
hgrFound1:  AIV 24,PtrA JPS OS_FlashA ; file found, skip header
            MIZ 160,0
			MIV Highscore,PtrB
hgrFound2:  RDR PtrA  		; copy block from A -> to B (formerly(ehemals): SEC RR1 ßßß ROL)
            STR PtrB        ; store in RAM
            INW PtrA INW PtrB JPS OS_FlashA
            DEZ 0
            BNE hgrFound2
            RTS
fileNameHGS: 'highscore.lr',0,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
bcdAdd:                       ;CLB bcdC        ; carry = 0 must be set in the calling program
            JPS bcdNib
            LDB tmp1          ;{{ergebnis in tmp1
            STB result        ;{{merken
            LDB sum1
            RL5
            STB sum1
            LDB sum2
            RL5
            STB sum2
            JPS bcdNib
            LDB tmp1
            LL4
            OR.B result
            RTS
bcdNib:        LDB sum1
            ANI 0x0f
            AD.B bcdC
            STB tmp1
            CLB bcdC
            LDB sum2
            ANI 0x0f
            AD.B tmp1
            CPI    9
            BLE done
            SUI 10
            STB tmp1
            INB bcdC
done:        RTS
result:        0x00,
tmp1:        0x00,
bcdC:        0x00,
sum1:        0x00,
sum2:        0x00,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; score = score + 100 * y + x (bcd)
addYXtoScoreBCD:
            CLB bcdC
            LDZ 0
            STB sum1
            LDB score+0
            STB sum2
            JPS bcdAdd
            LDB result
            STB score+0
                              ;LDA value+1
            LDZ 1
            STB sum1
            LDB score+1
            STB sum2
            JPS bcdAdd
            LDB result
            STB score+1
            CLB sum1
            LDB score+2
            STB sum2
            JPS bcdAdd
            LDB result
            STB score+2
            CLB sum1
            LDB score+3
            STB sum2
            JPS bcdAdd
            LDB result
            STB score+3
            JPA printScore
; print score (7 digits, 4 bytes bcd)
printScore:
            LDI 23
            STB _YPos
            LDI 7
            STB _XPos
            LDI <score
            STB ptrScore+0
            LDI >score
            STB ptrScore+1
printScoreXY:
            LDI 3
            ADW ptrScore
            LDR ptrScore      ;score+3
            ANI 0x0f          ;first digit (most significant) of score in lower nibble (BCD)
            ADI 0x30          ;convert to 0..9
            PHS JPS printCharXY PLS
            LDI 0x02
            STB tmp03
nextScoreByte:
            DEW ptrScore
                              ;MBZ tmp03,0
                              ;LTX score
            LDR ptrScore
            PHS
            RL5
            ANI 0x0f
            ADI 0x30
            PHS JPS printCharXY PLS
            PLS
            ANI 0x0f
            ADI 0x30
            PHS JPS printCharXY PLS
            DEB tmp03
            BPL nextScoreByte
            RTS
;
printLives:
            LDI 23
            STB _YPos
            LDI 23
            STB _XPos
            LDB lives
            PHS JPS printThreeDigitNumber PLS
            RTS
;
printLevel:
            LDI 23
            STB _YPos
            LDI 36
            STB _XPos
            LDB level
            PHS JPS printThreeDigitNumber PLS
            RTS
printThreeDigitNumber:        ;
            LDI 100
            STB tmp03
            LDI 0x02
            STB tmp02
            LDS 3
nextDigit:
            CLB tmp04
countUnits:
            PHS INB tmp04 PLS ; X = X + 1
            SUB tmp03         ; A = A - 100|10
            BPL countUnits    ; if C = 1
            ADB tmp03         ; A = A + 100|10
            PHS               ; A remember
            LDB tmp04
            ADI 0x2f
            PHS JPS printCharXY PLS
            LDI 10
            STB tmp03
            DEB tmp02
            PLS
            BNE nextDigit
            ADI 0x30
            PHS JPS printCharXY PLS
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drawLineScore:
            LDI >ViewPort+0x1400 ; Y (0,10,20,30,40,50,60,..)/4
            STB tmp01
            JPA drawStrongLine1
drawStrongLine:
                              ; draw a thick line (3x line)
            LDI >ViewPort+0x3800
            STB tmp01
drawStrongLine1:
            LDI 0x4c
            STB tmp00
                              ;LDA tmp00
            STB tmp02
            STB tmp04
            LDB tmp01
            STB tmp03
            STB tmp05
            LDI 64
            ADW tmp02
            LDI 128
            ADW tmp04
            MIZ 49,0
dlLoop:        LDI 0xff
            STR tmp00
            STR tmp02
            STR tmp04
            INW tmp00
            INW tmp02
            INW tmp04
            DEZ 0
            BPL dlLoop
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
clearScreen2:
            LDI 0x78
            STB tmp02
            LDI 0x77
            STB tmp03
            JPA clsEntry
clearScreen:
            LDI 0x00
            STB tmp02
            LDI 0xef
            STB tmp03
clsEntry:    MIZ 120,1
cSloop1:    LDB tmp02
            STB tmp00
            JPS calcVRAM
            LDB tmp00
            STB lineT+0
            LDB tmp01
            STB lineT+1
            LDB tmp03
            STB tmp00
            JPS calcVRAM
            LDB tmp00
            STB lineB+0
            LDB tmp01
            STB lineB+1
            MIZ 49,0
cSloop2:    LDI 0x00
            STB
lineT:        0x0000
            STB
lineB:        0x0000
            INW lineT
            INW lineB
            DEZ 0
            BPL cSloop2
            CLB tmp00
            LDI 0x20
            STB tmp01
cSdelay:    DEB tmp00
            BNE cSdelay
            DEB tmp01
            BNE cSdelay
            INB tmp02
            DEB tmp03
            DEZ 1
            BNE cSloop1
            RTS
calcVRAM:    CLB tmp01
            LLW tmp00         ; *2
            LLW tmp00         ; *4
            LLW tmp00         ; *8
            LLW tmp00         ; *16
            LLW tmp00         ; *32
            LLW tmp00         ; *64
            LDI 0x0c
            ADW tmp00
            LDI >ViewPort
            AD.B tmp01
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; input: A=tilemap row number, output: $81/$80=tilemap row ptr = tileMap+28*row
; Input: mapY Output: ptrM = (28 * mapY) + tileMap
calcTileMapRowPtr:
            LDB mapY          ; 7
            LL2               ; 6  *4
            PHS               ; 11
            STB ptrM+0        ; 7
            CLB ptrM+1        ; 10
            LLW ptrM          ; 10   *8
            LLW ptrM          ; 10   *16
            LLW ptrM          ; 10   *32
            PLS               ; 7
            SUW ptrM          ; 12  ptrM = 28 * mapY
            LDI <tileMap      ; 5
            AD.B ptrM+0       ; 8
            LDI >tileMap      ; 5
            AC.B ptrM+1       ; 8
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Input: coordinates in Map mapX, mapY Output: ptrM is pointer in MapArray
calcTileMapPtr:
            JPS calcTileMapRowPtr
            LDB mapX          ; 7
            ADW ptrM          ; 11
            RTS               ; 12 summe=146
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Input mapX, mapY (Block) Output: xpos16, ypos8 = 14 * mapX, 14 * mapY
calcMapPtr2Pixel:
            LDB mapX          ; val
            LL1
            STB tmp01         ; val=*2
            STB xpos16+0
            CLB xpos16+1
            LLW xpos16        ; val=*4
            LLW xpos16        ; val=*8
            LLW xpos16        ; val=*16
            LDB tmp01
            SUW xpos16        ; val= val*16-val*2
            LDB mapY
            LL1
            STB tmp01
            STB ypos8
            LLB ypos8
            LLB ypos8
            LLB ypos8
            LDB tmp01
            SU.B ypos8
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
buildTileMap:
            JPS loadFlashLevel
            LDI    <levelData
            STB levelDataPtr+0
            LDI    >levelData
            STB levelDataPtr+1
;            MBZ level,0
;            DEZ 0
;            BEQ    calcDone
;add224:        LDI    224
;            ADW levelDataPtr+0
;            DEZ 0
;            BNE    add224
calcDone:    LDI    <tileMap
            STB tileMapPtr+0
            LDI    >tileMap
            STB tileMapPtr+1
            MIZ 224,0
nextByteOfLevelData:
            LDR    levelDataPtr
            PHS
            ANI 0x0f
            LAB    levelNibbleToTile
            STR tileMapPtr
            INW tileMapPtr
            PLS
            RL5
            ANI 0x0f
            LAB    levelNibbleToTile
            STR tileMapPtr
            INW tileMapPtr
            INW levelDataPtr
            DEZ 0
            BNE    nextByteOfLevelData
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drawOrErasePlayerSprite:
            LDB oldPlayerXPosLo
            STB xpos16+0
            LDB oldPlayerXPosHi
            STB xpos16+1
            LDB oldPlayerYPos
            STB ypos8
            LDB oldPlayerFrameNumber
            STB spriteId
; spriteId is sprite number, xpos16 is 16-bit ypos8 is ypos
plotSprite14x14:
            LDB xpos16+0
            ANI 7
            STB shift
                              ; Y 0..239
            LDB ypos8
            LL6
            STB vAddr+0
            LDB ypos8
            RL7
            ANI 63
            ADI >ViewPort
            STB vAddr+1
                              ; X 0..399
            LDB xpos16+1
            DEC
            LDB xpos16+0
            RL6
            ANI 63
            ADI 12
            OR.B vAddr+0
                              ; set sprite
            LDB spriteId
            LL1               ; A = 2 * A
            STZ 0             ; X = A
            LZB 0, spriteAddr16
            STB spritePtr+0
            INZ 0
            LZB 0, spriteAddr16
            STB spritePtr+1
            LDI 14
            STB lineCnt
lineloop:   LDR spritePtr
            STB buffer+0
            INW spritePtr
            LDR spritePtr
            STB buffer+1
            CLB buffer+2
            MBZ shift,0
            DEZ 0
            BCC shiftdone
shiftloop:    LLW buffer+0
            RLB buffer+2
            DEZ 0
            BCS shiftloop
shiftdone:    LDR vAddr
            XRB buffer+0
            STR vAddr
            INW vAddr
            LDR vAddr
            XRB buffer+1
            STR vAddr
            INW vAddr
            LDR vAddr
            XRB buffer+2
            STR vAddr
            LDI 62
            ADW vAddr         ; VRAM + 62     ; ... and move to the next line
            INW spritePtr
            DEB lineCnt
            BNE lineloop
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
readJoystickAndKeys:
KeyHandler: INK               ; PS/2 Input and Clear
            CPI 0xff
            BEQ key_rts
            CPI 0xf0
            BEQ release
key_entry:
            CLB gameRun
            CPI 0x6b
            BEQ is_left       ; cursor left
            CPI 0x74
            BEQ is_right      ; cursor right
            CPI 0x75
            BEQ is_up         ; cursor up
            CPI 0x72
            BEQ is_down       ; cursor down
            CPI 0x1a
            BEQ is_digLeft    ; key z/y
            CPI 0x22
            BEQ is_digRight   ; key x
            CPI 0x15          ; key q
            BEQ is_quit
            CPI 0x1c          ; key a
            BEQ is_escape
            CPI 0x5a          ; key CR
            BEQ is_pressed
            CPI 0x29          ; kay space
            BEQ is_pressed
key_rts:    RTS
is_left:    LDB pressed STB _left ORI 1 STB pressed CLB _right RTS
is_right:    LDB pressed STB _right ORI 1 STB pressed CLB _left RTS
is_up:        LDB pressed STB _up ORI 1 STB pressed CLB _down RTS
is_down:    LDB pressed STB _down ORI 1 STB pressed CLB _up RTS
is_digLeft:    LDB pressed STB _digLeft ORI 1 STB pressed CLB _digRight RTS
is_digRight:    LDB pressed STB _digRight ORI 1 STB pressed CLB _digLeft RTS
is_escape:    LDB pressed STB _escape ORI 1 STB pressed RTS
is_quit:    LDB pressed STB _quit ORI 1 STB pressed RTS
is_pressed: LDB pressed STB _pressed ORI 1 STB pressed RTS
release:    CLB released_cntr ; IMPROVED PS2 RELEASE DETECTION by Michael Kamprath - Verbesserte PS2 losgelassen Erkennung
key_wait:    INK              ; PS/2 Input and Clear - poll for max. 10.1ms
            CPI 0xff
            BNE key_release
            NOP NOP NOP NOP NOP NOP NOP ; wait for key up datagram
            NOP NOP NOP NOP NOP NOP
            INB released_cntr
            BCC key_wait
            JPA key_rts       ; no 2nd datagram -> avoid
key_release: CLB pressed      ; released key was received -> analyze it
            JPA key_entry
released_cntr:  0
_right: 0
_left: 0
_up: 0
_down: 0
_digLeft: 0
_digRight: 0
_escape: 0
_quit: 0
_pressed: 0
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Outputs the text immediately after JPS
; must be terminated 0
printLine:    LDS 1
            STB ptr1+1
            LDS 2
            STB ptr1+0
            INW ptr1
            INW ptr1
pL1:        LDR ptr1
            CPI 0x00
            BNE pL2
            DEW ptr1
            LDB ptr1+0
            STS 2
            LDB ptr1+1
            STS 1
            RTS
pL2:        PHS JPS printCharXY PLS
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
            STB xpos16+0      ; xpos16 = _XPos * 2
            PHS               ; memorize _XPos * 2
            LLW    xpos16     ; xpos16 = _XPos * 4
            LLW    xpos16     ; xpos16 = _XPos * 8
            PLS               ; Restore _XPos * 2
            ADW xpos16        ; xpos16 = _XPos * 8 + _XPos * 2 = _XPos * 10
            LDB xpos16+0x00
            PHS               ; XPos low
            LDB xpos16+0x01
            PHS               ; XPos hight
            LDB _YPos
            LL1
            STB ypos8
            LL2
            ADB ypos8
            PHS               ; yPos = _YPos* 10
            LDS 6             ; Char is LDS 3+3
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
pCxy1:        RTS
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; print char 0x20..0x5f
; PHS: xLow, xHiht, y, char
printChar:        LDS 4       ; Y
                LL6 STB vAddr+0 ;
                LDS 4         ; Y
                RL7 ANI 63 ADI >ViewPort STB vAddr+1
                LDS 5         ; Xhight
                DEC
                LDS 6         ; Xlow
                RL6 ANI 63 ADI 12 OR.B vAddr+0
                LDS 6 ANI 7 STB shift ; Xlow
                LDI 10 STB lineCnt ; scnt loop counter 8 byte + 2 byte space
                LDS 3         ; char
                CPI 0x60
                BCS rPCrts    ; char > 0x5f
                SUI 0x20
                BCC rPCrts    ; char < 0x20
                STB spritePtr+0
                CLB spritePtr+1 ; spritePtr=(char-' ')
                LLW spritePtr ; *2
                LLW spritePtr ; *4
                LLW spritePtr ; *8 8 bytes per character
                LDI <alphaNumSprites ; Sprite data low
                ADW spritePtr ; Add to pointer
                LDI >alphaNumSprites
                AD.B spritePtr+1
                DEW spritePtr
clineloop:      LDB lineCnt
                CPI 10
                BEQ cl1
                CPI 1
                BEQ cl1
                INW spritePtr
                LDR spritePtr
                JPA cl2
cl1:            LDI 0x00
cl2:            STB buffer+0
                CLB buffer+1
                CLB buffer+2
                CLB mask+0
                LDI 0xfc
                STB mask+1
                LDI 0xff
                STB mask+2
                MBZ shift,1   ; shift counter
                DEZ 1         ; X coordinate
                BCC cshiftdone
cshiftloop:      LLW buffer+0 ; logical shift to the left word absolute vAddress
                RLB buffer+2  ; rotate shift left byte absolute vAddress
                SEC
                RLW mask+0
                RLB mask+2
                DEZ 1
                BCS cshiftloop ; branch on carry Set
cshiftdone:        LDB mask+0
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
ccommon:        LDI 62
                ADW vAddr
                DEB lineCnt
                BNE clineloop
rPCrts:         RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
loadEnemyPointer:
            LDI <enemyArray   ; low enemy array
            STB enemyXBlockPos+0
            LDI >enemyArray   ; high enemy array
            STB enemyXBlockPos+1
            LDB enemyIndex    ; 0..5
            LL1               ; enemy index =*2
            ADW enemyXBlockPos
            LDR enemyXBlockPos
            PHS
            INW enemyXBlockPos
            LDR enemyXBlockPos
            STB enemyXBlockPos+1
            STB enemyYBlockPos+1
            STB enemyXBlkInternalDecimalOffset+1
            STB enemyYBlkInternalDecimalOffset+1
            STB enemyXPosLo+1
            STB enemyXPosHi+1
            STB enemyYPos+1
            STB enemyFrames+1
            STB enemyFalling+1
            STB enemyCounter+1
            STB enemyInHoleHeight+1
            STB enemyInHoleCountdown+1
            STB enemyRespawnCountdown+1
            STB enemyHoldsGoldIngot+1
            PLS
            STB enemyXBlockPos+0
            STB enemyYBlockPos+0
            STB enemyXBlkInternalDecimalOffset+0
            STB enemyYBlkInternalDecimalOffset+0
            STB enemyXPosLo+0
            STB enemyXPosHi+0
            STB enemyYPos+0
            STB enemyFrames+0
            STB enemyFalling+0
            STB enemyCounter+0
            STB enemyInHoleHeight+0
            STB enemyInHoleCountdown+0
            STB enemyRespawnCountdown+0
            STB enemyHoldsGoldIngot+0
            INW enemyYBlockPos
            LDI 2
            ADW enemyXBlkInternalDecimalOffset
            LDI 3
            ADW enemyYBlkInternalDecimalOffset
            LDI 4
            ADW enemyXPosLo
            LDI 5
            ADW enemyXPosHi
            LDI 6
            ADW enemyYPos
            LDI 7
            ADW enemyFrames
            LDI 8
            ADW enemyFalling
            LDI 9
            ADW enemyCounter
            LDI 10
            ADW enemyInHoleHeight
            LDI 11
            ADW enemyInHoleCountdown
            LDI 12
            ADW enemyRespawnCountdown
            LDI 13
            ADW enemyHoldsGoldIngot
            RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
initFlashLevel:
            LDI <fileName
            STB _ReadPtr+0
            LDI >fileName
            STB _ReadPtr+1
            JPS _FindFile
deb001:     CPI 0
            BNE m001
            JPS printLine
            'LODERUNNER.DAT NOT FOUND.',0,
halt:        JPA halt
fileName:    'loderunner.dat', 0

m001:       AIV 22,PtrA JPS OS_FlashA                   	; search for target addr
            RDR PtrA STZ PtrB+0 INV PtrA JPS OS_FlashA 		; destination addr -> PtrC, PtrD
            RDR PtrA STZ PtrB+1 INV PtrA JPS OS_FlashA
			MVV PtrA,PtrC MZZ PtrA+2,PtrC+2           		; PtrA -> PtrC
                              ; hier noch grˆﬂe pr¸fen PtrB

loadFlashLevel:
			MVV PtrC,PtrA MZZ PtrC+2,PtrA+2           ; PtrC -> PtrA
            MBZ level,0
m002:       DEZ 0
            BEQ m003
            ;LDI 224 ADW PtrA JPS OS_FlashA
            AIV 224,PtrA JPS OS_FlashA 			
            JPA m002
m003:       MIZ 224,0
			MIV levelData,PtrB
m004:       RDR PtrA 		; copy block from A -> to B (formerly(ehemals): SEC RR1 ßßß ROL)
            STR PtrB        ; store in RAM
            INW PtrA INW PtrB JPS OS_FlashA
            DEZ 0
            BNE m004
            RTS
OS_FlashA:      LDZ PtrA+1 RL5 ANI 0x0f                       ; is something in the upper nibble?
                CPI 0 BEQ fa_farts
                  AD.Z PtrA+2                                 ; there was something -> update bank register PtrA+2
                  LDI 0x0f AN.Z PtrA+1                        ; correct PtrA+1
  fa_farts:     RTS
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
progLastByte:    0
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; #org 0x4000                            ; only better for debugging, line can be removed
xpos16:            0x0000,
ypos8:            0x00,
spriteId:        0x00,
tileMapPtr:        0x0000,
spritePtr:        0x0000,
shiftSprite:    0x00,
levelDataPtr:
vAddr:            0x0000,
lineCnt:        0x00,
tmp00:            0x00,
tmp01:            0x00,
tmp02:            0x00,
tmp03:            0x00,
tmp04:            0x00,
tmp05:            0x00,
shift:            0x00,
buffer:            0xff, 0xff, 0xff ; move buffer
mask:            0xff, 0xff, 0xff,
ptr1:            0x0000,      ; JPS printLine
ptrE:            0x0000,      ; tileMapRawPointerEnemy
ptrM:            0x0000,      ; ($80,$81) tileMapRawPointer
cntLevelComplete: 0x00,       ; ($82)
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
pressed:        0x00,
gameRun:        0x00,
;value:            0x0250,
level:            0x01,
lives:            0x05,
score:            0x00,0x00,0x00,0x00, ;7 digits, BCD in 4 bytes
ptrScore:        0x00, 0x00,
mapX:            0x00,
mapY:            0x00,
numberOfGoldIngots: 0x00,
playerSpriteFrames: 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x08,0x09,0x07,0x0b,0x0c,0x0a,0x0e,0x0d,0x0f,0x11,0x12,0x10,0x14,0x15,0x13,
spriteNumbersAnimDigHole:    0x1c,0x1b,0x1a,0x19,0x18,0x01,
playerMapPtr:    0x0000,      ; ($76,$77)
tmpXPosLo:    0x00,
tmpXPosHi:    0x00,
tmpYPos:    0x00,
oldPlayerFrameNumber:    0x00,
playerFrameNumber: 0x00,
oldPlayerXPosLo: 0x00,
oldPlayerXPosHi: 0x00,
oldPlayerYPos: 0x00,
playerXBlockPos: 0x00,
playerYBlockPos: 0x00,
playerXBlkInternalDecimalOffset: 0x00,
playerYBlkInternalDecimalOffset: 0x00,
playerDirection: 0x00,
playerIsDead: 0x00,
playerFalling:    0x00,
allGoldCollected:    0x00,
diggingHole:    0x00,
soundIndexGold:    0x00,
playingSoundAllGold:    0x00,
soundIndexAllGold:    0x00,
soundPitchWhileFalling:    0x00,
indexAnimDigHole:    0x00,
xPosDigHoleLo:    0x00,
xPosDigHoleHi:    0x00,
yPosDigHole:    0x00,
xBlockPosDigHole:    0x00,
yBlockPosDigHole:    0x00,
soundCounterWhileFalling:    0x00,
numberOfEnemies:    0x00,     ;holds number of enemies - 1 (so $ff means no enemies)
enemyIndex:    0x00,
enemyFrameNumber:    0x00,
distanceToPassageGoingLeft:    0x00,
distanceToPassageGoingRight:    0x00,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Array
enemyXBlockPos:    0x0000,
enemyYBlockPos:    0x0000,
enemyXBlkInternalDecimalOffset:    0x0000, ;where pixel offset is 0,2,4,6,8 in a 10px block, this one goes 0,20,40,60,80 in decimal
enemyYBlkInternalDecimalOffset:    0x0000, ;where pixel offset is 0,2,4,6,8 in a 10px block, this one goes 0,20,40,60,80 in decimal
enemyXPosLo:    0x0000,       ;enemy pixel pos (lo)
enemyXPosHi:    0x0000,       ;enemy pixel pos (hi)
enemyYPos:        0x0000,
enemyFrames:    0x0000,
enemyFalling:    0x0000,      ;0=normal, 1=falling
enemyCounter:    0x0000,
enemyInHoleHeight:    0x0000, ;5=top of hole, 4, 3, 2, 1, 0=bottom of hole (5*2px=10px)
enemyInHoleCountdown:    0x0000, ;time spent by enemy in hole before climbing out, starting at &1E, counting down to 0
enemyRespawnCountdown:    0x0000, ;countdown from 10 to 0 before enemy is respawned at the top of the screen after being buried (not just trapped) in a hole
enemyHoldsGoldIngot:    0x0000,
; 6 * 15 Byte = 90
enemyArray:        enemyArray0,enemyArray1,enemyArray2,enemyArray3,enemyArray4,enemyArray5,
enemyArray0:    0,0,0,0,0,0,0,0,0,0,0,0,0,0,
enemyArray1:    0,0,0,0,0,0,0,0,0,0,0,0,0,0,
enemyArray2:    0,0,0,0,0,0,0,0,0,0,0,0,0,0,
enemyArray3:    0,0,0,0,0,0,0,0,0,0,0,0,0,0,
enemyArray4:    0,0,0,0,0,0,0,0,0,0,0,0,0,0,
enemyArray5:    0,0,0,0,0,0,0,0,0,0,0,0,0,0,
enemyFrameOffset:
            0x01,0x02,0x00,0x04,0x05,0x03,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
holeIndex:    0x00,
holeAnimFrame:    0x00,
holeFillCounters:    0x0000,  ; don't change order!!!
holeXBlockPos:    0x0000,
holeYBlockPos:    0x0000,
; 11*(3) Byte = 33
holeArray:    0,0,0,          ; If this array overflows, the part assignment in the map will be corrupted
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
            0,0,0,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
levelNibbleToTile:
            0x00,             ;00 empty tile
            0x01,             ;01 brick
            0x02,             ;02 solid block
            0x03,             ;03 ladder
            0x04,             ;04 tile
            0x31,             ;05 trapdoor
            0x32,             ;06 escape ladder
            0x05,             ;07 gold ingot
            0x23,             ;08 enemy
            0x07,             ;01 player
            0x00,             ;   undefined, default to empty tile
            0x00,             ;   undefined, default to empty tile
            0x00,             ;   undefined, default to empty tile
            0x00,             ;   undefined, default to empty tile
            0x00,             ;   undefined, default to empty tile
            0x00,             ;   undefined, default to empty tile
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
spriteAddr16:
    spriteData,
    brick,
    solid,
    ladder,
    line,
    ingot,
    sprite6,
    sprite7,
    sprite8,
    sprite9,
    sprite10,
    sprite11,
    sprite12,
    sprite13,
    sprite14,
    sprite15,
    sprite16,
    sprite17,
    sprite18,
    sprite19,
    sprite20,
    sprite21,
    sprite22,
    sprite23,
    sprite24,
    sprite25,
    sprite26,
    sprite27,
    sprite28,
    sprite29,
    sprite30,
    sprite31,
    sprite32,
    sprite33,
    sprite34,
    sprite35,
    sprite36,
    sprite37,
    sprite38,
    sprite39,
    sprite40,
    sprite41,
    sprite42,
    sprite43,
    sprite44,
    sprite45,
    sprite46,
    sprite47,
    sprite48,
    sprite49,
    sprite50,
    sprite51,
    sprite51,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
spriteData:
0x54,0x55, 0xa8,0xaa, 0x54,0x55, 0xa8,0xaa, 0x54,0x55, 0xa8,0xaa, 0x54,0x55,
0xa8,0xaa, 0x54,0x55, 0xa8,0xaa, 0x54,0x55, 0xa8,0xaa, 0x54,0x55, 0xa8,0xaa,
brick:
0xfc,0xe7, 0xfc,0xe7, 0xfc,0xe7, 0xfc,0xe7, 0xfc,0xe7, 0xfc,0xe7, 0x00,0x00,
0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x00,0x00,
solid:
0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff,
0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0x00,0x00,
ladder:
0x18,0x60, 0x18,0x60, 0x18,0x60, 0xf8,0x7f, 0xf8,0x7f, 0x18,0x60, 0x18,0x60,
0x18,0x60, 0x18,0x60, 0x18,0x60, 0xf8,0x7f, 0xf8,0x7f, 0x18,0x60, 0x18,0x60,
line:
0x00,0x00, 0xfc,0xff, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
ingot:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0xc0,0x0f, 0xc0,0x0a, 0x40,0x0d, 0xc0,0x0a, 0x40,0x0d, 0xc0,0x0f,
sprite6:
0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
sprite7:
0x00,0x00, 0x00,0x06, 0x00,0x0f, 0x00,0x0b, 0x80,0x0f, 0x60,0x03, 0xb0,0x0f,
0x80,0x32, 0x80,0x02, 0x80,0x07, 0xf8,0x0c, 0x78,0x0c, 0x00,0x0c, 0x00,0x0c,
sprite8:
0x00,0x00, 0x00,0x06, 0x00,0x0f, 0x00,0x0b, 0x80,0x0f, 0xc0,0x03, 0xe0,0x0f,
0x90,0x1a, 0x80,0x02, 0x80,0x07, 0x00,0x0e, 0x00,0x0f, 0x80,0x03, 0x00,0x03,
sprite9:
0x00,0x00, 0x00,0x06, 0x00,0x0f, 0x00,0x0b, 0x80,0x0f, 0x60,0x03, 0xb0,0x13,
0x80,0x1e, 0x80,0x02, 0x80,0x07, 0xc0,0x0c, 0x60,0x18, 0x30,0x18, 0x30,0x00,
sprite10:
0x00,0x00, 0x80,0x01, 0xc0,0x03, 0x40,0x03, 0xc0,0x07, 0x00,0x1b, 0xc0,0x37,
0x30,0x05, 0x00,0x05, 0x80,0x07, 0xc0,0x7c, 0xc0,0x78, 0xc0,0x00, 0xc0,0x00,
sprite11:
0x00,0x00, 0x80,0x01, 0xc0,0x03, 0x40,0x03, 0xc0,0x07, 0x00,0x0f, 0xc0,0x1f,
0x60,0x25, 0x00,0x05, 0x80,0x07, 0xc0,0x01, 0xc0,0x03, 0x00,0x07, 0x00,0x03,
sprite12:
0x00,0x00, 0x80,0x01, 0xc0,0x03, 0x40,0x03, 0xc0,0x07, 0x00,0x1b, 0x20,0x37,
0xe0,0x05, 0x00,0x05, 0x80,0x07, 0xc0,0x0c, 0x60,0x18, 0x60,0x30, 0x00,0x30,
sprite13:
0x00,0x00, 0x00,0x0c, 0x00,0x0e, 0x00,0x0e, 0x20,0x0e, 0xe0,0x27, 0x00,0x3e,
0x00,0x0a, 0x00,0x0a, 0x00,0x0f, 0x80,0x19, 0xc0,0x19, 0xc0,0x19, 0x00,0x38,
sprite14:
0x00,0x00, 0xc0,0x00, 0xc0,0x01, 0xc0,0x01, 0xc0,0x11, 0x90,0x1f, 0xf0,0x01,
0x40,0x01, 0x40,0x01, 0xc0,0x03, 0x60,0x06, 0x60,0x0e, 0x60,0x0e, 0x70,0x00,
sprite15:
0x00,0x00, 0x18,0x31, 0x98,0x33, 0x98,0x33, 0x98,0x31, 0xf0,0x1f, 0x80,0x03,
0x80,0x02, 0x80,0x02, 0xc0,0x07, 0xc0,0x0c, 0xc0,0x0c, 0xc0,0x0c, 0xc0,0x00,
sprite16:
0x00,0x00, 0x18,0x31, 0x98,0x33, 0x98,0x33, 0x10,0x13, 0xf0,0x1f, 0x80,0x03,
0x00,0x03, 0x00,0x03, 0x80,0x07, 0xc0,0x04, 0xc0,0x04, 0xc0,0x06, 0x00,0x06,
sprite17:
0x00,0x00, 0x30,0x62, 0x30,0x67, 0x30,0x67, 0x20,0x26, 0xe0,0x3f, 0x00,0x07,
0x00,0x06, 0x00,0x06, 0x00,0x0f, 0x80,0x09, 0x80,0x09, 0x80,0x0d, 0x00,0x0c,
sprite18:
0x30,0x00, 0x30,0x00, 0xb0,0x01, 0xe0,0x01, 0xc0,0x01, 0x80,0x0f, 0x80,0x1b,
0x80,0x02, 0x80,0x02, 0x80,0x03, 0xc0,0x06, 0xc0,0x06, 0xc0,0x06, 0x00,0x00,
sprite19:
0x00,0x30, 0x00,0x30, 0x00,0x36, 0x00,0x1e, 0x00,0x0e, 0xc0,0x07, 0x60,0x07,
0x00,0x05, 0x00,0x05, 0x00,0x07, 0x80,0x0d, 0x80,0x0d, 0x80,0x0d, 0x00,0x00,
sprite20:
0x30,0x30, 0xb0,0x31, 0xb0,0x31, 0xe0,0x31, 0xc0,0x1f, 0x80,0x03, 0x80,0x02,
0x80,0x02, 0x80,0x03, 0x80,0x0e, 0x80,0x18, 0x80,0x19, 0x00,0x13, 0x00,0x00,
sprite21:
0x30,0x00, 0x30,0x00, 0xb0,0x01, 0xe0,0x01, 0xc0,0x01, 0x80,0x0f, 0x80,0x1b,
0x80,0x02, 0x80,0x02, 0x80,0x03, 0xc0,0x06, 0xc0,0x06, 0xc0,0x06, 0x00,0x00,
sprite22:
0x00,0x30, 0x00,0x30, 0x00,0x36, 0x00,0x1e, 0x00,0x0e, 0xc0,0x07, 0x60,0x07,
0x00,0x05, 0x00,0x05, 0x00,0x07, 0x80,0x0d, 0x80,0x0d, 0x80,0x0d, 0x00,0x00,
sprite23:
0x00,0x00, 0x00,0x06, 0x00,0x0f, 0x00,0x0b, 0x80,0x0f, 0x60,0x03, 0xb0,0x0f,
0x80,0x72, 0x80,0x62, 0x80,0x07, 0xc0,0x0c, 0xc0,0x0c, 0xc0,0x0c, 0xc0,0x0c,
sprite24:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
sprite25:
0x00,0x01, 0x00,0x01, 0xdc,0x01, 0x1c,0x00, 0xfc,0xe7, 0xfc,0xe7, 0x00,0x00,
0x00,0x00, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x00,0x00,
sprite26:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x02, 0xc4,0x63, 0xc0,0x07,
0x00,0x00, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x9c,0xff, 0x00,0x00,
sprite27:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x80,0x00, 0x80,0x0f, 0x80,0x0f, 0xf4,0x0f, 0x04,0x00, 0x9c,0xff, 0x00,0x00,
sprite28:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x80,0x00, 0xf0,0x00, 0xf0,0x0f, 0xf0,0x0f, 0x00,0x00,
sprite29:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x0c,0xc0, 0x0c,0xc0, 0x00,0x00,
sprite30:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x1c,0xe0, 0x1c,0xe0, 0x1c,0xe0, 0x1c,0xe0, 0x1c,0xe0, 0x00,0x00,
sprite31:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
sprite32:
0x00,0x00, 0x00,0x04, 0x00,0x0e, 0x00,0x0a, 0x80,0x0f, 0x60,0x03, 0x30,0x0f,
0x80,0x33, 0x80,0x03, 0x80,0x07, 0xe0,0x0c, 0x78,0x0c, 0x00,0x0c, 0x00,0x0c,
sprite33:
0x00,0x00, 0x00,0x04, 0x00,0x0e, 0x00,0x0a, 0x80,0x0f, 0xc0,0x03, 0x60,0x0f,
0x80,0x1b, 0x80,0x03, 0x80,0x07, 0x00,0x03, 0x80,0x03, 0xc0,0x03, 0x00,0x03,
sprite34:
0x00,0x00, 0x00,0x04, 0x00,0x0e, 0x00,0x0a, 0x80,0x0f, 0x60,0x03, 0x60,0x13,
0x80,0x1f, 0x80,0x03, 0x80,0x07, 0xc0,0x0c, 0x60,0x18, 0x30,0x18, 0x30,0x00,
sprite35:
0x00,0x00, 0x80,0x00, 0xc0,0x01, 0x40,0x01, 0xc0,0x07, 0x00,0x1b, 0xc0,0x33,
0x30,0x07, 0x00,0x07, 0x80,0x07, 0xc0,0x1c, 0xc0,0x78, 0xc0,0x00, 0xc0,0x00,
sprite36:
0x00,0x00, 0x80,0x00, 0xc0,0x01, 0x40,0x01, 0xc0,0x07, 0x00,0x0f, 0xc0,0x1b,
0x60,0x07, 0x00,0x07, 0x80,0x07, 0x00,0x03, 0x00,0x07, 0x00,0x0f, 0x00,0x03,
sprite37:
0x00,0x00, 0x80,0x00, 0xc0,0x01, 0x40,0x01, 0xc0,0x07, 0x00,0x1b, 0x20,0x1b,
0xe0,0x07, 0x00,0x07, 0x80,0x07, 0xc0,0x0c, 0x60,0x18, 0x60,0x30, 0x00,0x30,
sprite38:
0x00,0x00, 0x00,0x0c, 0x00,0x0e, 0x00,0x0e, 0x40,0x0e, 0xc0,0x27, 0x00,0x3e,
0x00,0x06, 0x00,0x06, 0x00,0x0f, 0x80,0x09, 0x80,0x08, 0x80,0x08, 0x00,0x18,
sprite39:
0x00,0x00, 0x18,0x31, 0x98,0x33, 0x98,0x33, 0x90,0x11, 0xf0,0x1f, 0x80,0x01,
0x80,0x01, 0x80,0x01, 0xc0,0x03, 0x40,0x06, 0x40,0x06, 0xc0,0x06, 0xc0,0x00,
sprite40:
0x00,0x00, 0x18,0x31, 0x98,0x33, 0x98,0x33, 0x90,0x11, 0xf0,0x1f, 0x80,0x01,
0x80,0x01, 0x80,0x01, 0xc0,0x03, 0x40,0x06, 0x40,0x06, 0xc0,0x06, 0xc0,0x00,
sprite41:
0x00,0x30, 0x00,0x30, 0x00,0x36, 0x00,0x1e, 0x00,0x0e, 0x80,0x07, 0xc0,0x06,
0x00,0x06, 0x00,0x06, 0x00,0x07, 0x80,0x0d, 0x80,0x0d, 0x80,0x0d, 0x00,0x00,
sprite42:
0x30,0x00, 0x30,0x00, 0xb0,0x01, 0xe0,0x01, 0xc0,0x01, 0x80,0x07, 0x80,0x0d,
0x80,0x01, 0x80,0x01, 0x80,0x03, 0xc0,0x06, 0xc0,0x06, 0xc0,0x06, 0x00,0x00,
sprite43:
0x30,0x30, 0xb0,0x31, 0xb0,0x31, 0xe0,0x31, 0xc0,0x1f, 0x80,0x01, 0x80,0x01,
0x80,0x01, 0x80,0x03, 0x80,0x06, 0x80,0x0c, 0x80,0x0d, 0x00,0x09, 0x00,0x00,
sprite44:
0x30,0x00, 0x30,0x00, 0xb0,0x01, 0xe0,0x01, 0xc0,0x01, 0x80,0x07, 0x80,0x0d,
0x80,0x01, 0x80,0x01, 0x80,0x03, 0xc0,0x06, 0xc0,0x06, 0xc0,0x06, 0x00,0x00,
sprite45:
0x00,0x30, 0x00,0x30, 0x00,0x36, 0x00,0x1e, 0x00,0x0e, 0x80,0x07, 0xc0,0x06,
0x00,0x06, 0x00,0x06, 0x00,0x07, 0x80,0x0d, 0x80,0x0d, 0x80,0x0d, 0x00,0x00,
sprite46:
0x30,0x30, 0x30,0x36, 0x30,0x36, 0x30,0x1e, 0xe0,0x0f, 0x00,0x06, 0x00,0x06,
0x00,0x06, 0x00,0x07, 0x80,0x05, 0xc0,0x04, 0xc0,0x06, 0x40,0x02, 0x00,0x00,
sprite47:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x80,0x07, 0xe0,0x1f,
sprite48:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x80,0x07, 0xe0,0x1f, 0xe0,0x1f,
sprite49:
0xfc,0xff, 0xfc,0xff, 0xfc,0xff, 0x00,0x00, 0x00,0x00, 0xf0,0x3f, 0xf0,0x3f,
0xf0,0x3f, 0x00,0x03, 0x00,0x03, 0x00,0x03, 0xfc,0xff, 0xfc,0xff, 0xfc,0xff,
sprite50:
0x18,0x00, 0x18,0x00, 0x18,0x00, 0xf8,0x7f, 0xf8,0x7f, 0x18,0x60, 0x00,0x60,
0x00,0x60, 0x00,0x60, 0x18,0x60, 0xf8,0x7f, 0xf8,0x7f, 0x18,0x00, 0x18,0x00,
sprite51:
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
levelData:
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; tilemap for current level, 28*(16+1)=476 tiles
tileMap:
    0x00,0x00,0x00,0x05,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x03,0x02,0x02,0x01,
    0x02,0x02,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x05,0x00,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x03,0x00,0x00,0x00,0x00,0x00,0x03,0x00,
    0x00,0x00,0x00,0x03,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x03,0x00,0x05,
    0x00,0x00,0x00,0x03,0x03,0x00,0x05,0x00,0x23,0x00,0x03,0x00,0x00,0x00,0x00,0x03,
    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x01,0x01,0x01,0x01,0x01,0x03,
    0x03,0x01,0x02,0x01,0x02,0x01,0x03,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,
    0x00,0x00,0x03,0x04,0x04,0x04,0x04,0x03,0x04,0x04,0x04,0x04,0x04,0x04,0x00,0x00, ; 160
    0x23,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x03,0x00,
    0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x03,0x01,0x01,0x01,0x02,0x02,0x02,
    0x02,0x02,0x02,0x03,0x03,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x03,
    0x00,0x00,0x05,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,
    0x03,0x00,0x00,0x00,0x23,0x00,0x03,0x00,0x05,0x00,0x00,0x03,0x01,0x01,0x01,0x01,
    0x01,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x02,0x01,0x01,0x01,
    0x02,0x01,0x01,0x02,0x01,0x01,0x02,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x03,0x01,0x01,0x01,0x03,0x01,0x01,0x02,0x01,0x01,0x01,0x02,0x00,0x00,0x00,
    0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,
    0x00,0x03,0x00,0x00,0x02,0x05,0x00,0x00,0x02,0x00,0x00,0x00,0x00,0x00,0x00,0x03, ; 320
    0x00,0x00,0x00,0x04,0x04,0x04,0x04,0x04,0x04,0x03,0x00,0x00,0x00,0x03,0x00,0x05,
    0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x03,0x01,0x01,0x01,0x02,0x02,0x02,0x02,
    0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x00,0x03,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x03,0x00,0x00,0x00,0x00,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00, ; 416
    0x00,0x00,0x00,0x00,      ; 420
; bottom row of tilemap is always 28 bricks
    0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,
    0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01, ; +28=448
; very last row of tilemap is always 28 red bar blocks
    0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,
    0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06, ; +28=476
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; #org 0x5000 only debug
Highscore:
;    'NameName   ', level, score,
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 01
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 02
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 03
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 04
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 05
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 06
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 07
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 08
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 09
    '           ', 0x00, 0x00,0x00,0x00,0x00, ; 10
;    'TEST01     ', 0x01, 0x00,0x90,0x00,0x00,        ; 01
;    'TEST02     ', 0x01, 0x00,0x80,0x00,0x00,        ; 02
;    'TEST03     ', 0x01, 0x00,0x70,0x00,0x00,        ; 03
;    'TEST04     ', 0x01, 0x00,0x60,0x00,0x00,        ; 04
;    'TEST05     ', 0x01, 0x00,0x50,0x00,0x00,        ; 05
;    'TEST06     ', 0x01, 0x00,0x40,0x00,0x00,        ; 06
;    'TEST07     ', 0x01, 0x00,0x30,0x00,0x00,        ; 07
;    'TEST08     ', 0x01, 0x00,0x20,0x00,0x00,        ; 08
;    'TEST09     ', 0x01, 0x00,0x10,0x00,0x00,        ; 09
;    '           ', 0x00, 0x00,0x00,0x00,0x00,        ; 10
HiScTemp:
    '           ', 0xff, 0xff,0xff,0xff,0xff,
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
endOfData:                    ; maximum available memory up to 0xafff
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#mute
#org 0x0000 _enemyXBlockPos:
#org 0x0001 _enemyYBlockPos:
#org 0x0002 _enemyXBlkInternalDecimalOffset:
#org 0x0003 _enemyYBlkInternalDecimalOffset:
#org 0x0004 _enemyXPosLo:
#org 0x0005 _enemyXPosHi:
#org 0x0006 _enemyYPos:
#org 0x0007 _enemyFrames:
#org 0x0008 _enemyFalling:
#org 0x0009 _enemyCounter:
#org 0x000a _enemyInHoleHeight:
#org 0x000b _enemyInHoleCountdown:
#org 0x000c _enemyRespawnCountdown:
#org 0x000d _enemyHoldsGoldIngot:

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