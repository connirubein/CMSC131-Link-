NAME LINK
.STACK 100
.MODEL MEDIUM

.DATA

	HOME DB	 'menu.txt', 0
	LOADSCRN DB 'load.txt', 0
	HOW DB 'how.txt', 0
	GAMEOVER DB 'gameover.txt',0
	FILE_HANDLE	DW	 ?
	ERROR_STR DB 'Error!$'
	FILE_BUFFER	DB 1896 DUP('$')
	LOAD DB	 'Loading...$'
	COMP DB	 'Press any key$'
	INIT DB	  0ah, 0dh, 20 DUP(219), '$'
	BAR	DB	  219, '$'
	FLAG DB	  0
	ARROW DB	  175, '$'
	EMPTY DB	  '$'
	ROW	DB		0
	COL	DB		0
	ROWD DB		6H, '$'
	COLD DB		0
	SPACE DB   ' ', '$'                                ;BLANK CHARACTER for clearing
	ACTION_COUNTER DB 0										;counts the number of turns
	WINNER DB 0												;distinguishes when a winner is declared or not

	;strings for point system
	POINT1 DB '1$'
	POINT2 DB '2$'
	POINT3 DB '3$'
	POINT4 DB '4$'
	POINT5 DB '5$'
	POINT6 DB '6$'
	POINT7 DB '7$'
	POINT8 DB '8$'
	POINT9 DB '9$'
	POINT10 DB '10$'
	POINT11 DB '11$'
	POINT12 DB '12$'
	POINT13 DB '13$'
	POINT14 DB '14$'
	POINT15 DB '15$'



	MESSAGE DB 'Invalid format$'
	FMES DB '  WON (PRESS ANY KEY)$'
	LABEL_E DB 'E - EXIT$'
	LABEL_N DB 'N - NEW$'
	LABEL_HS DB 'HIGHSCORE:$'
	PLAY1 DB 'Player 1$'
	PLAY2 DB 'Player 2$'
	PROMPT1 DB 'Player 1 turn$'
	PROMPT2 DB 'Player 2 turn$'
	SCORE DB 'SCORE:$'
	SCORE1 DB 'P1:$'
	SCORE2 DB 'P2:$'
;	SCORE1HERE DB '0$'
	CLEAR DB 30 DUP(' '),'$'
	BUFF DB 51,0, 51 DUP('$')
	SCORECOUNT1 DB 0
	SCORECOUNT2 DB 0
	STRSCORE1 DB '  $'
	STRSCORE2 DB '  $'
	TEMP DW 0
	TEMPB DB 0
	TEMPB2 DB 0
	ROW_TOP DB 0
	ROW_END DB 0
	COL_START DB 0
	COL_END DB 0
	CURR_PLAYER DB 0
	CURR_COL DB 0
	COLOR DB 0
	HEIGHT DB 6 DUP(5)
	TROW DB 0
	TCOL DB 0
	PROW DB 12 DUP(0)
	PCOL DB 12 DUP(0)
	PDIAG1 DB 10 DUP(0)
	PDIAG2 DB 10 DUP(0)
	TEMPP DB 0
	TEMPU DB 0
	PATHFILENAME  DB 'record.txt', 00H

;------------------------- LIST OF MACROS
; MACRO (defn):
; a means for generating a commonly used sequence of assembler instructions/statements. The sequence of instructions/statements
; will be coded ONE time within the macro definition. Whenever the sequence is needed within a program, the macro will be "called"
  
	SET_CURSOR MACRO ROW, COL 				;sets cursor for table printing, string printing
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		
		MOV AH, 02H							;cursor position
		MOV DH, ROW 						;set row
		MOV DL, COL 						;set column
		MOV BH, 0							;page number
		INT 10H								;video display control. controls the screen format (color, text style)
		
		POP DX
		POP CX
		POP BX
		POP AX
	ENDM
	
	SET_VIDEO_MODE MACRO MODE
		PUSH AX
	
		MOV AL, MODE 		;for entering and exiting video mode  (13h for entering and 03h for exit)
		MOV AH, 0			;corresponds to "Set the Video Mode"
		INT 10H				;video display control. controls the screen format (color, text style)
		
		POP AX		
	ENDM
	
	DRAW_HLINE MACRO ROW, COL,LEN 			;row, column, length are in bytes in video mode
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		
		MOV BX, COL
		HDRAW:				;draw horizontal lines
			MOV AL, 0CH		
			MOV CX, BX		;counter of column
			MOV DX, ROW
			MOV AH, 0CH 	;write/draw graphics (ex. routine to draw a lines)
			INT 10H 		;video display control. controls the screen format (color, text style)

			;draw line until it reaches bytes:
			INC BX
			CMP BX, LEN
			JLE HDRAW
		
		POP DX
		POP CX
		POP BX
		POP AX
	ENDM
	
	DRAW_VLINE MACRO ROW, COL,LEN
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		
		MOV BX, ROW 		
		VDRAW:				;draw horizontal lines
			MOV AL, 0CH
			MOV CX, COL
			MOV DX, BX 		;counter of row
			MOV AH, 0CH		;write/draw graphics (ex. routine to draw a lines)
			INT 10H 		;video display control. controls the screen format (color, text style)

			;draw line until it reaches bytes:
			INC BX
			CMP BX, LEN
			JLE VDRAW
		
		POP DX
		POP CX
		POP BX
		POP AX
	ENDM
	
;--------------------------------------------------------CODE SEGMENT------------------------------------------------------------------------------------

.CODE
START:

	MOV AX, @DATA;
	MOV DS, AX

	CALL  HIDE_CURSOR 		;hides the cursor when loading is called
	CALL LOADING 			;displays loading page
	CALL DISP_HOME 			;displays the menu
							;start of the game is called in MENU_CH

;------------------------- LIST OF PROCEDURES

START_LINK PROC NEAR														;the proc of the game

	CALL INITL 																;initializes values; esp helpful when user wants to play a new game

	;take inputs (player number and column number)
	;while giving string as input give exactly 5 characters
	;don't press space at end
	CALL TAKE_INPUT
	
	;03h - exit video mode.
	SET_VIDEO_MODE 03H

	RET

START_LINK ENDP

;----------------------------------------------------------------------------------------------

SCOREUPDATE1 PROC NEAR				;this proc updates player 1's score
	
	CMP BL, 1 						;updates when it was player 1's turn
	JNE _RET
	CMP WINNER, 1					;does not update when there is a winner
	JE _RET
	JMP CONT
	_RET:
		RET
	CONT:
	INC ACTION_COUNTER

	SET_CURSOR 0,4

	CMP ACTION_COUNTER, 1
	JNE _CHECK1_2
	
	MOV AH, 09
	LEA DX, POINT1
	INT 21H
	JMP _RETURN

	_CHECK1_2:
		CMP ACTION_COUNTER, 2
		JNE _CHECK1_3
		MOV AH, 09
		LEA DX, POINT2
		INT 21H
		JMP _RETURN

	_CHECK1_3:
		CMP ACTION_COUNTER, 3
		JNE _CHECK1_4
		MOV AH, 09
		LEA DX, POINT3
		INT 21H
		JMP _RETURN

	_CHECK1_4:
		CMP ACTION_COUNTER, 4
		JNE _CHECK1_5
		MOV AH, 09
		LEA DX, POINT4
		INT 21H
		JMP _RETURN

	_CHECK1_5:
		CMP ACTION_COUNTER, 5
		JNE _CHECK1_6
		MOV AH, 09
		LEA DX, POINT5
		INT 21H
		JMP _RETURN

	_CHECK1_6:
		CMP ACTION_COUNTER, 6
		JNE _CHECK1_7
		MOV AH, 09
		LEA DX, POINT6
		INT 21H
		JMP _RETURN

	_CHECK1_7:
		CMP ACTION_COUNTER, 7
		JNE _CHECK1_8
		MOV AH, 09
		LEA DX, POINT8
		INT 21H
		JMP _RETURN

	_CHECK1_8:
		CMP ACTION_COUNTER, 8
		JNE _CHECK1_9
		MOV AH, 09
		LEA DX, POINT9
		INT 21H
		JMP _RETURN

	_CHECK1_9:
		CMP ACTION_COUNTER, 9
		JNE _CHECK1_10
		MOV AH, 09
		LEA DX, POINT9
		INT 21H
		JMP _RETURN

	_CHECK1_10:
		CMP ACTION_COUNTER, 10
		JNE _CHECK1_11
		MOV AH, 09
		LEA DX, POINT10
		INT 21H
		JMP _RETURN

	_CHECK1_11:
		CMP ACTION_COUNTER, 11
		JNE _CHECK1_12
		MOV AH, 09
		LEA DX, POINT11
		INT 21H
		JMP _RETURN

	_CHECK1_12:
		CMP ACTION_COUNTER, 12
		JNE _CHECK1_13
		MOV AH, 09
		LEA DX, POINT12
		INT 21H
		JMP _RETURN

	_CHECK1_13:
		CMP ACTION_COUNTER, 13
		JNE _CHECK1_14
		MOV AH, 09
		LEA DX, POINT13
		INT 21H
		JMP _RETURN

	_CHECK1_14:
		CMP ACTION_COUNTER, 14
		JNE _CHECK1_15
		MOV AH, 09
		LEA DX, POINT14
		INT 21H
		JMP _RETURN

	_CHECK1_15:
		CMP ACTION_COUNTER, 15
		JNE _RETURN
		MOV AH, 09
		LEA DX, POINT15
		INT 21H
		JMP _RETURN


	_RETURN:
		RET
SCOREUPDATE1 ENDP

;----------------------------------------------------------------------------------------------

SCOREUPDATE2 PROC NEAR				;this proc updates player 2's score

	CMP BL, 2						;updates when it was player 2's turn
	JNE _RET2
	CMP WINNER, 1					;does not update when there is a winner
	JE _RET2
	JMP CONT2

	_RET2:
		RET

	CONT2:
	SET_CURSOR 0,16

	CMP ACTION_COUNTER, 1
	JNE _CHECK2_2
	MOV AH, 09
	LEA DX, POINT1
	INT 21H
	JMP _RETURN2

	_CHECK2_2:
		CMP ACTION_COUNTER, 2
		JNE _CHECK2_3
		MOV AH, 09
		LEA DX, POINT2
		INT 21H
		JMP _RETURN

	_CHECK2_3:
		CMP ACTION_COUNTER, 3
		JNE _CHECK2_4
		MOV AH, 09
		LEA DX, POINT3
		INT 21H
		JMP _RETURN

	_CHECK2_4:
		CMP ACTION_COUNTER, 4
		JNE _CHECK2_5
		MOV AH, 09
		LEA DX, POINT4
		INT 21H
		JMP _RETURN

	_CHECK2_5:
		CMP ACTION_COUNTER, 5
		JNE _CHECK2_6
		MOV AH, 09
		LEA DX, POINT5
		INT 21H
		JMP _RETURN

	_CHECK2_6:
		CMP ACTION_COUNTER, 6
		JNE _CHECK2_7
		MOV AH, 09
		LEA DX, POINT6
		INT 21H
		JMP _RETURN

	_CHECK2_7:
		CMP ACTION_COUNTER, 7
		JNE _CHECK2_8
		MOV AH, 09
		LEA DX, POINT8
		INT 21H
		JMP _RETURN

	_CHECK2_8:
		CMP ACTION_COUNTER, 8
		JNE _CHECK2_9
		MOV AH, 09
		LEA DX, POINT9
		INT 21H
		JMP _RETURN

	_CHECK2_9:
		CMP ACTION_COUNTER, 9
		JNE _CHECK2_10
		MOV AH, 09
		LEA DX, POINT9
		INT 21H
		JMP _RETURN

	_CHECK2_10:
		CMP ACTION_COUNTER, 10
		JNE _CHECK2_11
		MOV AH, 09
		LEA DX, POINT10
		INT 21H
		JMP _RETURN

	_CHECK2_11:
		CMP ACTION_COUNTER, 11
		JNE _CHECK2_12
		MOV AH, 09
		LEA DX, POINT11
		INT 21H
		JMP _RETURN

	_CHECK2_12:
		CMP ACTION_COUNTER, 12
		JNE _CHECK2_13
		MOV AH, 09
		LEA DX, POINT12
		INT 21H
		JMP _RETURN

	_CHECK2_13:
		CMP ACTION_COUNTER, 13
		JNE _CHECK2_14
		MOV AH, 09
		LEA DX, POINT13
		INT 21H
		JMP _RETURN

	_CHECK2_14:
		CMP ACTION_COUNTER, 14
		JNE _CHECK2_15
		MOV AH, 09
		LEA DX, POINT14
		INT 21H
		JMP _RETURN

	_CHECK2_15:
		CMP ACTION_COUNTER, 15
		JNE _RETURN2
		MOV AH, 09
		LEA DX, POINT15
		INT 21H
		JMP _RETURN

	_RETURN2:
		RET
SCOREUPDATE2 ENDP

;----------------------------------------------------------------------------------------------

INITL PROC NEAR 						;called when a new game is prompted so that values will be reset
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	SET_VIDEO_MODE 13H 					;13h - start video mode
	CALL COLOR_SCREEN					;renews screen with colors
  
	
	MOV CX, 7							;7 - number of horizontal lines in table
	MOV TEMP, 50						;row from byte 70
	HORIZONTAL:
		;temp- row
		;100 - col
		;240 - length
		DRAW_HLINE TEMP,100,220			
		ADD TEMP, 20					;20 - gap between lines in bytes
		LOOP HORIZONTAL 				;writing/drawing of all horizontal lines
	
	MOV CX, 7							;number of vertical lines in table
	MOV TEMP, 100						;col from byte 50
	VERTICAL:
		;50  - row
		;temp- col
		;170 - length
		DRAW_VLINE 50,TEMP,170
		ADD TEMP, 20 					;20 - gap between lines in bytes
		LOOP VERTICAL 					;writing/drawing of all vertical lines
	
	;initialize all variables
	MOV WINNER, 0
	MOV ACTION_COUNTER, 0
	MOV TEMP ,0
	MOV TEMPB ,0
	MOV TEMPB2 ,0
	MOV ROW_TOP , 0
	MOV ROW_END , 0
	MOV COL_START , 0
	MOV COL_END , 0
	MOV CURR_PLAYER , 2
	MOV CURR_COL ,0
	MOV COLOR , 0
	MOV TROW , 0
	MOV TCOL , 0
	MOV TEMPP , 0
	MOV TEMPU , 0
	
	MOV CX, 6
	MOV BX, 0

	HINIT: 						;height initialization
		MOV HEIGHT[BX], 5
		INC BX
		LOOP HINIT
	
	MOV CX, 12 					
	MOV BX, 0
	RCINIT: 					;row/column initialization
		MOV PROW[BX], 0
		MOV PCOL[BX], 0
		INC BX
		LOOP RCINIT
	
	MOV CX, 10
	MOV BX, 0
	DINIT: 						;diagonal initialization
		MOV PDIAG1[BX], 0
		MOV PDIAG2[BX], 0
		INC BX
		LOOP DINIT
	
	POP DX
	POP CX
	POP BX
	POP AX
	RET
INITL ENDP
  
COLOR_SCREEN PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
		;clear screen
        MOV AX, 0600H
    	INT 10H
        
        MOV BH, 00H			;set colors

        ;whole screen:
        MOV CX, 0H 			;upper left row:column
        MOV DX, 184FH		;lower right row:column
        INT 10H				;video display control. controls the screen format (color, text style)
	
	POP DX
	POP CX
	POP BX
	POP AX
        RET
COLOR_SCREEN ENDP

TAKE_INPUT PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	
	
	REDO:

	SET_CURSOR 0, 1				;for the "p1:"
	MOV AH, 09
	LEA DX, SCORE1
	INT 21H
	SET_CURSOR 0, 4

	SET_CURSOR 0, 10			;for the "p2:"
	MOV AH, 09
	LEA DX, SCORE2
	INT 21H

	SET_CURSOR 18,30 			;for the "e - exit"
	MOV AH, 09
	LEA DX, LABEL_E
	INT 21H

	SET_CURSOR 20,30			;for the "n - new game"
	MOV AH, 09
	LEA DX, LABEL_N
	INT 21H

	SET_CURSOR 0, 25 			;for the "highscore: "
	MOV AH, 09
	LEA DX, LABEL_HS
	INT 21H

	;0 - row
	;5 - col
	SET_CURSOR 2,5 				;for where prompt will display

	LEA DX, PROMPT1				;"Player1 turn"
	CMP CURR_PLAYER, 2 			
	JZ UI
	LEA DX, PROMPT2 			;"Player2 turn"
	;ADD SCORECOUNT1, 1
	UI:
		MOV AH, 09H
		INT 21H
		SET_CURSOR 3,5 			;for where input will be typed
		MOV AH, 0AH
		LEA DX, BUFF
		INT 21H
	
		CMP BUFF[2], 'n'		;N/n for new game
		JE NGAME
		CMP BUFF[2], 'N'
		JNE OGAME
	NGAME: 						;new game: generate new screen with blank table
		CALL INITL
		JMP REDO
	OGAME:	
		CMP BUFF[2], 'e'		;E/e for exit
		JE OEXIT
		CMP BUFF[2], 'E'
		JNE NEXIT
	OEXIT:
		POP DX
		POP CX
		POP BX
		POP AX
		RET

	;-----checkers for input syntax:

	NEXIT:
		CMP BUFF[1], 5 		;check length
		JNE ASSISTJ			;leads to invalid
		CMP BUFF[2], 'P'  	;first input must be p (syntax). it is located at index 2 of BUFF. index is enclosed (ex. [2]) for
							;the actual value to be obtained and compared
		JE PCHK 			;check next character
		CMP BUFF[2],'p'
		JNE ASSISTJ			;leads to invalid

	PCHK: 					;checks validity of the entered player number
		CMP BUFF[3], '1' 	;second input must be either 1 or 2, to indicate which player made the move
		JL ASSISTJ 			;leads to invalid
		CMP BUFF[3], '2'
		JG ASSISTJ 			;leads to invalid
		SUB BUFF[3], '0'	;convert to int so that it'll be used to know which player will have the next turn (refer to the next
							;CMP command)
		MOV AL, BUFF[3]
		CMP CURR_PLAYER, AL
		JE ASSISTJ 			;leads to invalid
		MOV BL, AL 			;BL holds the player number

	
	CMP BUFF[4], ' ' 		;separates player identification and desired location
	JNE ASSISTJ
	
	CMP BUFF[5], 'C' 		;c stands for "column". indicates the start of column identification
	JE CCHK 				;check the next character
	CMP BUFF[5],'c'
	JNE INVALID
	CCHK: 					;checks validity of the entered column number and converts it
		MOV AL, BUFF[6]
		MOV CURR_COL, AL
		SUB CURR_COL, '0' 	;convert to int
		DEC CURR_COL
		CMP AL, '1' 		;check range
		JL INVALID
		CMP AL, '6'
		JG INVALID
		MOV CL,BL 			;BL value (player number) copied to CL
	
		JMP SKIP
	ASSISTJ:
		JMP INVALID
	
	SKIP:

		CALL SCOREUPDATE1
		CALL SCOREUPDATE2
		SET_CURSOR 3, 5		;overwrites "textfield" where input is typed to blank
		MOV AH, 09H
		LEA DX, CLEAR 		;' '
		INT 21H
		MOV BH, 0
		MOV BL, CURR_COL
		MOV AL, HEIGHT[BX]
		MOV TEMPB2, AL
		CMP TEMPB2, 0
		JL INVALID
		DEC HEIGHT[BX]
		MOV CURR_PLAYER, CL 	;CL value is the player number from previous value of BL and AL
		CALL CROSS_CELL 		;X marks the occupied cell
		SET_CURSOR 23,5 			;"textfield" where "Invalid format" is printed
		MOV AH, 09H
		LEA DX, CLEAR
		INT 21H
		JMP REDO
	
	
	
	INVALID:
		SET_CURSOR 3, 5 		;clears "text field" for input
		MOV AH, 09H
		LEA DX, CLEAR
		INT 21H
		SET_CURSOR 23,5 			;clears "text field" for prompter if input is invalid
		MOV AH, 09H
		LEA DX, MESSAGE
		INT 21H
		JMP REDO
	
	
	POP DX
	POP CX
	POP BX
	POP AX
	RET
TAKE_INPUT ENDP

;---------------------------------------------------------------------------------------------------------------------
													;cross_cell procedure:
CROSS_CELL PROC NEAR								;called when user inputs valid column number
	PUSH AX											;used to draw a cross or "X" at desired location
	PUSH BX
	PUSH CX
	PUSH DX
		
	CMP CURR_PLAYER, 1
	JE P2
	MOV COLOR, 02H
	JMP P1
	P2:
		MOV COLOR, 09H
	P1:
		MOV ROW_TOP, 50
		MOV CH, 0
		MOV CL, TEMPB2
		CMP CX, 0
		JLE RDONE
	RFIND:
		ADD ROW_TOP, 20
		LOOP RFIND
		
		
	RDONE:
		MOV CH, ROW_TOP
		MOV ROW_END, CH
		ADD ROW_END, 20
		
		MOV COL_START, 100
		MOV CH, 0
		MOV CL, CURR_COL
		CMP CX, 0
		JLE CDONE
	CFIND:
		ADD COL_START, 20
		LOOP CFIND
		
	CDONE:
		MOV CH, COL_START
		MOV COL_END, CH
		ADD COL_END, 20

		INC ROW_TOP
		DEC ROW_END
		INC COL_START
		DEC COL_END
		
		MOV CH, COL_START
		MOV TEMPB, CH 
		MOV CH, ROW_TOP
		MOV TEMPB2, CH
	DIAGNL1:
		MOV AL, COLOR
		MOV DH, 0
		MOV CH, 0
		MOV DL, ROW_TOP
		MOV CL, COL_START
		MOV AH, 0CH
		INT 10H
		ADD ROW_TOP, 1
		ADD COL_START, 1
		CMP CL,   COL_END
		JB DIAGNL1
		CMP DL,   ROW_END
		JB DIAGNL1
		
		MOV CH, TEMPB
		MOV COL_START, CH 
		MOV CH, TEMPB2
		MOV ROW_TOP, CH
	DIAGNL2:
		MOV AL, COLOR
		MOV DH, 0
		MOV CH, 0
		MOV DL, ROW_END
		MOV CL, COL_START
		MOV AH, 0CH
		INT 10H
		SUB ROW_END, 1
		ADD COL_START, 1
		CMP CL,   COL_END
		JB DIAGNL2
		CMP DL, ROW_TOP
		JA DIAGNL2
		
		CALL PROCESS
		CALL CHECK_SOL

		POP DX
		POP CX
		POP BX		
		POP AX
		RET
CROSS_CELL ENDP

;-----------------------------------------------------------------------------------------------------------------
;sets the appropriate bit in each number
;processes each bit made in creating the cross or X
;shl instruction is used to shift the bits of the operand destination to the left
;second variation left shifts by a count value specified in the CL register
PROCESS PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
		
	MOV BX, 0
	MOV BL, CURR_COL 
	MOV  CL, HEIGHT[BX]
	INC CL
	MOV AL, 1
	SHL AL, CL
	CMP CURR_PLAYER, 2
	JNE CPL1
	ADD BL, 6
	CPL1:
		OR PCOL[BX], AL
		
		MOV BX, 0
		MOV BL, CURR_COL 
		MOV  CL, HEIGHT[BX]
		INC CL
		MOV BL, CL
		MOV CL, CURR_COL
		MOV AL, 1
		SHL AL, CL
		CMP CURR_PLAYER, 2
		JNE RPL1
		ADD BL, 6
	RPL1:
		OR PROW[BX], AL
		
		MOV BX, 0
		MOV BL, CURR_COL
		MOV CL, HEIGHT[BX]
		INC CL
		ADD CL, CURR_COL
		SUB CL, 3
		CMP CL, 0
		JB OTHER
		CMP CL, 4
		JA OTHER
		MOV BL, CL
		MOV CL, CURR_COL
		MOV AL, 1
		SHL AL, CL
		CMP CURR_PLAYER, 2
		JNE DPL1
		ADD BL, 5
	DPL1:
		OR PDIAG1[BX], AL
		
	OTHER:
		MOV BX, 0
		MOV BL, CURR_COL
		MOV CL, HEIGHT[BX]
		INC CL
		SUB CL, CURR_COL
		ADD CL, 2
		CMP CL, 0
		JB OTHER1
		CMP CL, 4
		JA OTHER1
		MOV BL, CL
		MOV CL, CURR_COL
		MOV AL, 1
		SHL AL, CL
		CMP CURR_PLAYER, 2
		JNE D2PL1
		ADD BL, 5
	D2PL1:
		OR PDIAG2[BX], AL
		
	OTHER1:
		
		POP DX
		POP CX
		POP BX
		POP AX
		RET
PROCESS ENDP
;--------------------------------------------------------------------------------------------------------------------
; CHECKS THE SOLUTION USING BIT METHODS
; CHECK WHETHER FOUR CONSECUTIVE BITS ARE SET IN A NUMBER
;checks for winner
;checks if crosses or X's from a player are aligned vertically, horizontally, or diagonally
CHECK_SOL PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
		
	MOV BH, 0
	MOV BL, CURR_COL
	CMP CURR_PLAYER, 2
	JNE CRPL1
	ADD BL, 6
	CRPL1:
		MOV AL, PCOL[BX]
		MOV CL, AL
		SHL CL, 1
		AND AL, CL
		MOV CL, AL
		SHL CL, 1
		SHL CL, 1
		AND AL, CL
		JNZ  ASSIST
		
		MOV BH, 0
		MOV BL, CURR_COL 
		MOV  CL, HEIGHT[BX]
		INC CL
		MOV BL, CL
		CMP CURR_PLAYER, 2
		JNE RRPL1
		ADD BL, 6
	RRPL1:
		MOV AL, PROW[BX]
		MOV CL, AL
		SHL CL, 1
		AND AL, CL
		MOV CL, AL
		SHL CL, 1
		SHL CL, 1
		AND AL, CL
		JNZ  ASSIST
		
		MOV BX, 0
		MOV BL, CURR_COL
		MOV CL, HEIGHT[BX]
		INC CL
		ADD CL, CURR_COL
		SUB CL, 3
		CMP CL, 0
		JB OTHERP
		CMP CL, 4
		JA OTHERP
		MOV BL, CL
		CMP CURR_PLAYER, 2
		JNE CPLA1
		ADD BL, 5
	CPLA1:
		MOV AL, PDIAG1[BX]
		MOV CL, AL
		SHL CL, 1
		AND AL, CL
		MOV CL, AL
		SHL CL, 1
		SHL CL, 1
		AND AL, CL
		JNZ OVERG
		
		JMP OTHERP
	ASSIST:
		JMP OVERG
		
		
	OTHERP:
		MOV BX, 0
		MOV BL, CURR_COL
		MOV CL, HEIGHT[BX]
		INC CL
		SUB CL, CURR_COL
		ADD CL, 2
		CMP CL, 0
		JB LAST
		CMP CL, 4
		JA LAST
		MOV BL, CL
		CMP CURR_PLAYER, 2
		JNE CPLA2
		ADD BL, 5
	CPLA2:
		MOV AL, PDIAG2[BX]
		MOV CL, AL
		SHL CL, 1
		AND AL, CL
		MOV CL, AL
		SHL CL, 1
		SHL CL, 1
		AND AL, CL
		JNZ OVERG
		
		JMP LAST
		
	OVERG:
		
		CALL F_CURSOR
		MOV AH, 09H
		LEA DX, CLEAR 		;replace "text field" for inputs to blank for prompting the winner
		INT 21H
		CALL F_CURSOR
		CMP CURR_PLAYER, 1
		JNE PRP2
		LEA DX, PLAY1 		;player 1 won
		JMP PRINTF
	PRP2:
		LEA DX, PLAY2 		;player 2 won

	PRINTF:
		MOV WINNER, 1
		MOV AH, 09H
		INT 21H
		
		MOV AH, 09H
		LEA DX, FMES 		;"won"
		INT 21H
		
		SET_CURSOR 4,5 		;prompter for "Invlid input" is replaced with a blank when winner is announced
		MOV AH, 09H
		LEA DX, CLEAR
		INT 21H
		
		MOV AH, 01H 		;keyboard input (any)
		INT 21H

		CALL DISP_GAMEOVER

		CALL INITL 			;new game

	LAST:
		POP DX
		POP CX
		POP BX
		POP AX
		RET
CHECK_SOL ENDP
;------------------------------------------------------------------------------------------------------------------------
; this proc sets cursor to 1,5 and used to avoid jump out of range error
;clears "Player1 turn" or "Player2 turn"
F_CURSOR PROC NEAR
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
		
	MOV AH, 02H
	MOV DH, 2
	MOV DL, 5
	MOV BH, 0
	INT 10H
		
	POP DX
	POP CX
	POP BX
	POP AX
	RET
F_CURSOR ENDP

;-------------------------------------------------------------------------------------------------------------

LOADING PROC NEAR
	CALL CLS
	LEA DX, LOADSCRN
	CALL FILE_READ
	MOV	ROW, 22
	MOV	COL, 23H
	SCRN:		
     	CALL SET_CURS
		CMP	FLAG, 0		;check flag if done loading or not
		JE _START
		CMP	FLAG, 1
		JE	MENU
						
	_START:		
        LEA	DX, LOAD	;print loading
		JMP	SET
							
	SET:		
        CALL SET_SCRN	;loading bar
		CMP	FLAG, 1		;exit if complete
		JE BACK
		MOV	FLAG, 1		;reset screen if complete
		JMP	SCRN

	MENU:		
        CALL SET_CURS	;display if done loading
		LEA	DX, COMP
		CALL DISPLAY
							
	BACK:		

        MOV	AH, 00H		;get input
		INT	16H
		RET

LOADING ENDP

;----------------------------------------
FILE_READ PROC NEAR
	MOV AX, 3D02H											;OPEN FILE
	INT	21H
	JC	_ERROR
	MOV	FILE_HANDLE, AX
	
	MOV	AH, 3FH												;READ FILE
	MOV	BX, FILE_HANDLE
	MOV	CX, 1896
	LEA	DX, FILE_BUFFER
	INT	21H
	JC _ERROR
	
	MOV	DX, 0500H											;DISPLAY FILE
	CALL SET_CURS
	LEA	DX, FILE_BUFFER
	CALL DISPLAY

	MOV AH, 3EH         							;CLOSE FILE
	MOV BX, FILE_HANDLE
	INT 21H
	JC _ERROR

	RET

	_ERROR:		
	    LEA	DX, ERROR_STR									;ERROR IN FILE OPERATION
		CALL DISPLAY
		RET
		BK:			
		    RET
FILE_READ ENDP
;---------------------------------------------
SET_CURS PROC NEAR 			 	;changes postion of cursor
	MOV	AH, 02H
	MOV	BH, 00
	MOV	DH, ROW
	MOV	DL, COL
	INT	10H
	RET
SET_CURS ENDP
;------------------------------------------------------------

SET_SCRN PROC NEAR
	CALL DISPLAY
	LEA	DX, INIT	;print initial bar
	CALL DISPLAY
	MOV	CX, 60		;set counter
			
PRGRS:		
    CMP FLAG, 1		
	JE _SKIP		;skip delay if complete
	CALL DELAY

_SKIP:		
    LEA	DX, BAR		;display more bars
	CALL DISPLAY
	LOOP PRGRS
			
	RET

SET_SCRN ENDP
;------------------------------------------------------------
DISPLAY PROC NEAR 			;called for printing
	MOV	AH, 09H
	INT	21H
	RET
DISPLAY	ENDP
;------------------------------------------------------------

DELAY PROC NEAR 			;delay
	MOV BX, 003H
			
	MAINLP: 	
		PUSH BX
        MOV BX, 0D090H
			
	SUBLP: 		
        DEC BX
        JNZ SUBLP
        POP BX
        DEC BX
        JNZ MAINLP
		
		RET
DELAY ENDP
;------------------------------------------------------------

CLS PROC NEAR			;clear screen shortcut
	MOV	AX, 0600H
	MOV	BH, 04H
	MOV	CX, 0000H
	MOV	DX, 184FH
	INT	10H
	RET
CLS ENDP
;-----------------------------------------------

HIDE_CURSOR PROC NEAR	;hides cursor (used when loading, and the like)
    MOV CX, 2000H
    MOV AH, 01H
    INT 10H
    RET
HIDE_CURSOR ENDP
;----------------------------------------------

DISP_HOWTO PROC NEAR		;displays instructions page
	MOV ROW, 0
	MOV COL, 0
	CALL SET_CURS
	CALL CLS
	LEA	DX, HOW
	CALL FILE_READ
	MOV	AH, 00H		;get any key input
	INT	16H
	CALL CLS
	CALL DISP_HOME
	RET
DISP_HOWTO ENDP
;-----------------------------------------
DISP_HOME PROC NEAR		;displays menu

	MOV ROW, 0
	MOV COL, 0
	CALL SET_CURS
	CALL CLS
	LEA DX, HOME
	CALL FILE_READ
	JMP MENU_CH			;list of choices
	RET
DISP_HOME ENDP
;--------------------------------------------------
MENU_CH	PROC NEAR			;choices of actions (play, read instructions, exit)
	MOV	ROW, 22
	MOV	COL, 15
	CALL SET_CURS
	LEA	DX, ARROW
	CALL DISPLAY

CHOOSE:		
  	MOV AH, 00H		;get input
	INT	16H
	CMP	AL, 0DH 	;ENTER
	JE	CHOICE
	CMP	AH, 4BH		;LEFT
	JE	LEFT
	CMP	AH, 4DH		;RIGHT
	JE	RIGHT

	JMP CHOOSE

RIGHT:		
    CMP COL, 49		;IF RIGHT KEY
	JE	CHOOSE
	CALL SET_CURS
	LEA	DX, SPACE
	CALL DISPLAY
	ADD	COL, 17
	CALL DISP_ARR

LEFT:	
    CMP	COL, 15 	;IF LEFT KEY
	JE	CHOOSE
	CALL SET_CURS
	LEA	DX, SPACE
	CALL DISPLAY
	SUB	COL, 17

DISP_ARR:	
    CALL SET_CURS	;DISPLAY ARROW
	LEA	DX, ARROW
	CALL DISPLAY

	JMP	CHOOSE

CHOICE:		
	CMP COL, 15		;START GAME
	JE	START_GAME
	CMP COL, 32
	JE	HOW_PG
	CMP COL, 49
	JE	FIN
	JMP CHOOSE

HOW_PG:	
	CALL DISP_HOWTO			;caller of instructions page
	RET
	FIN:		
      CALL EXIT	;EXIT GAME
      RET

START_GAME:
      CALL CLS
      CALL START_LINK			;call for the start of the game

EXIT:
	MOV   AX, 4C00H
	INT   21H
      
				
MENU_CH	ENDP
;--------------------------------------------------

DISP_GAMEOVER PROC NEAR
							
	CALL HIDE_CURSOR
	SET_VIDEO_MODE 03H 			;video mode exits because of txt file display in game over page
	CALL CLS
	MOV ROW, 0
	MOV COL, 0
	CALL SET_CURS
	CALL CLS
	LEA	DX, GAMEOVER
	CALL FILE_READ
	MOV	AH, 00H		;get any key input
	INT	16H
	CALL CLS
	CALL DISP_HOME
	RET

DISP_GAMEOVER ENDP
END START
