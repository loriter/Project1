$NOLIST
	
CSEG

Timer2_Interrupt:
	push psw
	push acc
	push dpl
	push dph
	lcall push_carry
	
	clr TF2
	
	mov a, cnt_10ms
	inc a
	mov cnt_10ms, a
	
	cjne a, #100, Interrupt_Ret
	
	mov cnt_10ms, #0
	jnb started, String_Roll
Update_Sec:	
	mov a, sec
	add a, #1
	da a
	mov sec, a
	
	cjne a, #96, Show_Time
	lcall Reset_Sec
Show_Time:	
	lcall Display_Time
	sjmp String_Slide
String_Roll:
	cpl roll_start
	jnb roll_start, Interrupt_Ret
	setb roll_start
	jb roll_state2, String_Roll_State2
	jb roll_state3, String_Roll_State3
	mov a, #80H
	lcall LCD_Command
	mov dptr, #UseSwitch
	lcall Send_String
	mov a, #0C0H
	lcall LCD_Command
	mov dptr, #UseKey1
	lcall Send_String
	setb roll_state2
	sjmp Interrupt_Ret 
String_Roll_State2:
	mov a, #80H
	lcall LCD_Command
	mov dptr, #UseKey1
	lcall Send_String
	mov a, #0C0H
	lcall LCD_Command
	mov dptr, #UseKey2
	lcall Send_String
	clr roll_state2
	setb roll_state3
	sjmp Interrupt_Ret
String_Roll_State3:
	mov a, #80H
	lcall LCD_Command
	mov dptr, #UseKey2
	lcall Send_String
	mov a, #0C0H
	lcall LCD_Command
	mov dptr, #UseSwitch
	lcall Send_String
	clr roll_state3
Interrupt_Ret:
	lcall pop_carry
	pop dph
	pop dpl
	pop acc
	pop psw
	reti
push_carry:
	jc push_carry2
	clr carry_set
	ret
push_carry2:
	setb carry_set
	ret
pop_carry:
	jb carry_set, pop_carry2
	clr c
	ret
pop_carry2:
	setb c
	ret
String_Slide:
	mov a, #0C0H
	lcall LCD_Command
	mov dptr, #xcreate_data
	mov dptr_count, #0
	clr c
	mov a, curr_string
	add a, dpl 
	mov dpl, a
	jnc String_Slide_Send
	mov a, dph
	inc a
	mov dph, a
String_Slide_Send:
	clr a
	movx a, @dptr
	jz String_Slide_Send3
String_Slide_Send2:
	lcall LCD_put
	mov a, dptr_count
	inc a
	mov dptr_count, a
	cjne a, #16, String_Slide_Loop
	sjmp SSlDone
String_Slide_Send3:
	mov dptr, #xcreate_data
	movx a, @dptr
	sjmp String_Slide_Send2
String_Slide_Loop:
	inc dptr
	sjmp String_Slide_Send
SSlDone:
	mov a, curr_string
	inc a
	cjne a, #34, SSlDone2
	mov a, #0
SSlDone2:
	mov curr_string, a
	ljmp Interrupt_Ret

Reset_Sec:
	mov sec, #0
	mov a, min
	add a, #1
	da a
	mov min, a
	ret

Create_Data_Start:
	mov dptr, #DSoakTemp
	mov r0, #5BH
Create_Data_Loop:
	clr a
	movc a, @a+dptr
	jz Create_Data_End
	mov @r0, a
	inc r0
	inc dptr
	sjmp Create_Data_Loop
Create_Data_End:
	mov a, soak_temp
	mov b, #100
	div ab
	add a, #30h
	mov @r0, a
	inc r0
	
	mov a,b
    mov b,#10
    div ab
    add a,#30h
    mov @r0, a
    inc r0

    mov a,b
    add a,#30h
    mov @r0,a
    inc r0

    mov @r0, #43H
    inc r0
    
    mov @r0, #20H
    inc r0
    
    mov dptr, #DSoakTime
Create_Data_Loop2:
	clr a
	movc a, @a+dptr
	jz Create_Data_End2
	mov @r0, a
	inc r0
	inc dptr
	sjmp Create_Data_Loop2
Create_Data_End2:
	mov a, soak_time
	mov b, #100
	div ab
	add a, #30h
	cjne a, #30H, Create_Data_End2_1
	sjmp Create_Data_End2_2
Create_Data_End2_1:
	mov @r0, a
	inc r0
Create_Data_End2_2:
	mov a,b
    mov b,#10
    div ab
    add a,#30h
    mov @r0, a
    inc r0

    mov a,b
    add a,#30h
    mov @r0,a
    inc r0

    mov @r0, #73H
    inc r0
    
    mov @r0, #20H
    inc r0

    mov @r0, #0
    
    mov dptr, #xcreate_data
    mov r0, #5Bh
    mov r1, #0
Create_Data_Loop3:
	mov a, @r0
	movx @dptr, a
	inc dptr
	inc r0
	inc r1
	cjne a, #0, Create_Data_Loop3
	ret
	
Display_Time:
	mov dptr, #myLUT
	
	
; Display Seconds
	mov A, sec
    anl A, #0FH
    movc A, @A+dptr
    mov HEX4, A

    mov A, sec
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX5, A
    
; Display Minutes
	mov A, min
	anl A, #0FH
	movc A, @A+dptr
	mov HEX6, A
	
	mov A, min
	swap A
	anl A, #0FH
	movc A, @A+dptr
	mov HEX7, A
	
	ret
	
;Displays current state on line 1
Show_State:
	mov a, #80H
	lcall LCD_Command
	jb reflow_done, Show_Cool
	jb soak_done, Show_Reflow
	jb preheat_done, Show_Soak
	mov DPTR, #PreHeatState
	lcall Send_String
	ret
Show_Soak:
    mov DPTR, #SoakState
    lcall Send_String
    ret
Show_Reflow:
	mov DPTR, #ReflowState
	lcall Send_String
	ret
Show_Cool:
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
	
	lcall Display_Select

Prompts_Test:
	mov a, SWA
	jb acc.0, Soak_Temp_Prompt
	jb acc.1, Soak_Time_Prompt
	jb acc.2, Reflow_Temp_Prompt
	jb acc.3, Jump_To_Reflow_Time_Prompt
	jnb key.1, End_Prompt
	sjmp Prompts_Test

Jump_To_Reflow_Time_Prompt:
	ljmp Reflow_Time_Prompt

End_Prompt:
	ret

Soak_Temp_Prompt:
	clr TR2
	lcall Display_Please_Set
	
	mov DPTR, #SoakTemp
	lcall Send_String
	
	lcall Enter_Soak_Temp
	lcall Display_Null
	
	lcall Display_Select
	
	ljmp Prompts_Test

Soak_Time_Prompt:
	clr TR2
	lcall Display_Please_Set
	
	mov DPTR, #SoakTime
	lcall Send_String
	
	lcall Enter_Soak_Time
	lcall Display_Null
	
	lcall Display_Select
	
	ljmp Prompts_Test

Reflow_Temp_Prompt:
	clr TR2
	lcall Display_Please_Set
	
	mov DPTR, #ReflowTemp
	lcall Send_String
	
	lcall Enter_Reflow_Temp
	lcall Display_Null
	
	lcall Display_Select
	
	ljmp Prompts_Test
	
Reflow_Time_Prompt:
	clr TR2
	lcall Display_Please_Set
	
	mov DPTR, #ReflowTime
	lcall Send_String
	
	lcall Enter_Reflow_Time
	lcall Display_Null
	
	lcall Display_Select
	
	ljmp Prompts_Test

Display_Select:
	mov a, #80H
	lcall LCD_Command
	mov dptr, #UseSwitch
	lcall Send_String
	mov a, #0C0H
	lcall LCD_Command
	mov dptr, #UseKey1
	lcall Send_String
	setb roll_state2
	
	lcall Set_Timer2
	ret
	
Display_Please_Set:
	mov a, #80H ;set pointer to first line
	lcall LCD_Command
	mov dptr, #PleaseSet
	lcall Send_String 
	mov a, #0C0H ;set pointer to second line
	lcall LCD_Command
	ret
	
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
	setb ET2
	
	mov cnt_10ms, #0
	mov sec, #0
	mov min, #0
	
	setb TR2
	
	ret
	
Wait_For_Start:
	jnb KEY.1, Start_Process
	sjmp Wait_For_Start
	
Start_Process:
	setb started
	lcall Create_Data_Start
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

Send_String:
	clr A
	movc A, @A+DPTR
	jz SSDone
	lcall LCD_put
	inc dptr
	sjmp Send_String
SSDone:
	ret
	
$LIST	
	