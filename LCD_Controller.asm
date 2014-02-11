$NOLIST
	
CSEG

Timer2_Interrupt:
	push psw
	push acc
	push dpl
	push dph
	
	clr TF2
	
	mov a, cnt_10ms
	inc a
	mov cnt_10ms, a
	
	cjne a, #100, Interrupt_Ret
	
	mov cnt_10ms, #0
	
Update_Sec:	
	mov a, sec
	add a, #1
	da a
	mov sec, a
	
	cjne a, #96, Show_Time
	lcall Reset_Sec

Show_Time:	
	lcall Display_Time
	
Interrupt_Ret:
	pop dph
	pop dpl
	pop acc
	pop psw
	
	reti
	
Reset_Sec:
	mov sec, #0
	mov a, min
	add a, #1
	da a
	mov min, a
	ret
	
Display_Time:
	mov dptr, #myLUT
	
; Display Seconds
	mov A, sec
    anl A, #0FH
    movc A, @A+dptr
    mov HEX0, A

    mov A, sec
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX1, A
    
; Display Minutes
	mov A, min
	anl A, #0FH
	movc A, @A+dptr
	mov HEX2, A
	
	mov A, min
	swap A
	anl A, #0FH
	movc A, @A+dptr
	mov HEX3, A
	
	ret
	
;Displays current state on line 1
Show_State:
	mov a, #80H
	lcall LCD_Command
	mov a, curr_state
	cjne a, #0, Check_Soak
	mov DPTR, #PreHeatState
	lcall Send_String
	ret
Check_Soak:
	cjne a, #1, Check_Reflow
    mov DPTR, #SoakState
    lcall Send_String
    ret
Check_Reflow:
	cjne a, #2, Check_Cool
	mov DPTR, #ReflowState
	lcall Send_String
	ret
Check_Cool:
	mov DPTR, #CoolingState
	lcall Send_String
	ret
	
;Needs some work to show exact values
Show_Temp:
	mov a, #0C0H
	lcall LCD_Command
	mov DPTR, #DisplayTemp
	lcall Send_String
	mov a, curr_temp+2
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_Put
	mov a, curr_temp+1
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_Put
	mov a, curr_temp+0
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_Put
	mov a, #0x43
	lcall LCD_Put
    ret
   
	
Start_Prompts:

	;Defaults for Temps and Times
	;SoakTemp
	
	mov a, #80H
	lcall LCD_Command ;Sets pointer to first line
	
	mov DPTR, #PleaseSet
	lcall Send_String

Prompts_Test:
	mov a, SWA
	jb acc.0, Soak_Temp_Prompt
	jb acc.1, Soak_Time_Prompt
	jb acc.2, Reflow_Temp_Prompt
	jb acc.3, Reflow_Time_Prompt
	jnb key.1, End_Prompt
	sjmp Prompts_Test
	
End_Prompt:
	ret

Soak_Temp_Prompt:
	mov a,#0C0H ;Sets pointer to second line
	lcall LCD_Command
	
	mov DPTR, #SoakTemp1
	lcall Send_String
	
	lcall Enter_Soak_Temp
	lcall Display_Null
	
	sjmp Prompts_Test

Soak_Time_Prompt:
	mov a, #0C0H
	lcall LCD_Command
	
	mov DPTR, #SoakTime1
	lcall Send_String
	
	lcall Enter_Soak_Time
	lcall Display_Null
	
	sjmp Prompts_Test

Reflow_Temp_Prompt:
	mov a, #0C0H
	lcall LCD_Command
	
	mov DPTR, #ReflowTemp1
	lcall Send_String
	
	lcall Enter_Reflow_Temp
	lcall Display_Null
	
	sjmp Prompts_Test
	
Reflow_Time_Prompt:
	mov a, #0C0H
	lcall LCD_Command
	
	mov DPTR, #ReflowTime1
	lcall Send_String
	
	lcall Enter_Reflow_Time
	lcall Display_Null
	
	sjmp Prompts_Test
	
Display_Null:
	mov HEX0, #0xFF
	mov HEX1, #0xFF
	mov HEX2, #0xFF
	ret
	
Set_Timer2:

	mov T2CON, #00H
	clr TR2
	clr TF2
	mov RCAP2H,#high(TIMER2_RELOAD)
	mov RCAP2L,#low(TIMER2_RELOAD)
	setb TR2
	setb ET2
	
	mov cnt_10ms, #0
	mov sec, #0
	mov min, #0
	mov curr_state, #0
	
	mov a,#80H
	lcall LCD_Command
	
	mov DPTR, #StartMessage
	lcall Send_String
	
	mov a,#0C0H
	lcall LCD_Command
	
	mov DPTR, #StopMessage
	lcall Send_String
	
	ret
	
Wait_For_Start:
	jnb KEY.1, Start_Process
	sjmp Wait_For_Start
	
Start_Process:
	ret

Wait40us:
	mov R0, #149
Wait40us_L0: 
	nop
	nop
	nop
	nop
	nop
	nop
	djnz R0, Wait40us_L0 ; 9 machine cycles-> 9*30ns*149=40us
    ret

LCD_command:
	mov	LCD_DATA, A
	clr	LCD_RS
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us

LCD_put:
	mov	LCD_DATA, A
	setb LCD_RS
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us

LCD_Init:
    ; Turn LCD on, and wait a bit.
    setb LCD_ON
    clr LCD_EN  ; Default state of enable must be zero
    lcall Wait40us
    
    mov LCD_MOD, #0xff ; Use LCD_DATA as output port
    clr LCD_RW ;  Only writing to the LCD in this code.
	
	mov a, #0ch ; Display on command
	lcall LCD_command
	mov a, #38H ; 8-bits interface, 2 lines, 5x7 characters
	lcall LCD_command
	mov a, #01H ; Clear screen (Warning, very slow command!)
	lcall LCD_command
    
    ; Delay loop needed for 'clear screen' command above (1.6ms at least!)
    mov R1, #40
Clr_loop:
	lcall Wait40us
	djnz R1, Clr_loop
	ret

	
WaitHalfSec:
	mov R2, #90
L3: mov R1, #250
L2: mov R0, #250
L1: djnz R0, L1
	djnz R1, L2
	djnz R2, L3
	ret
	
Send_String:
	CLR A
	MOVC A, @A+DPTR
	JZ SSDone
	LCALL LCD_put
	INC DPTR
	SJMP Send_String
SSDone:
	ret

$LIST	
	