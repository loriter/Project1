$NOLIST
	
ISR_timer2:
	push psw
	push acc
	push dpl
	push dph
	
	clr TF2
	
	mov a, Cnt_10ms
	inc a
	mov Cnt_10ms, a
	
	cjne a, #100, do_nothing
	
	mov Cnt_10ms, #0
	
UpdateSec:	
	mov a, Sec
	add a, #1
	da a
	mov Sec, a
	
	cjne a, #96, ShowTime ;96
	lcall resetSec

ShowTime:	
	lcall DisplayTime
	
do_nothing:
	pop dph
	pop dpl
	pop acc
	pop psw
	
	reti
	
resetSec:
	mov Sec, #0
	mov a, Min
	add a, #1
	da a
	mov Min, a
	ret
	
DisplayTime:
	mov dptr, #myLUT
	
; Display Seconds
	mov A, Sec
    anl A, #0FH
    movc A, @A+dptr
    mov HEX0, A

    mov A, Sec
    swap A
    anl A, #0FH
    movc A, @A+dptr
    mov HEX1, A
; Display Minutes
	mov A, Min
	anl A, #0FH
	movc A, @A+dptr
	mov HEX2, A
	
	mov A, Min
	swap A
	anl A, #0FH
	movc A, @A+dptr
	mov HEX3, A
	
	ret
    
PleaseSet:
	DB 'Please set the',0
	
SoakTemp1:
	DB 'Soak Temp    ', 0
	
SoakTime1:
	DB 'Soak Time    ', 0
	
ReflowTemp1:
	DB 'Reflow Temp', 0

ReflowTime1:
	DB 'Reflow Time', 0
	
StartMessage:
	DB 'KEY1 to start  ', 0
 
StopMessage:
	DB 'KEY2 to stop  ', 0
	
PreHeatState:
	DB 'Preheat State  ', 0

SoakState:
	DB 'Soaking State  ', 0
	
ReflowState:
	DB 'Reflow State  ', 0
	
CoolingState:
	DB 'Cooling State  ', 0
	
DisplayTemp:
	DB 'Temp: ', 0 
	
;Displays current state on line 1
showState:
	mov a, #80H
	lcall LCD_command
	mov a, curr_state
	cjne a, #0, checkSoak
	mov DPTR, #PreHeatState
	lcall SendString
	ret
checkSoak:
	cjne a, #1, checkReflow
    mov DPTR, #SoakState
    lcall SendString
    ret
checkReflow:
	cjne a, #2, checkCool
	mov DPTR, #ReflowState
	lcall SendString
	ret
checkCool:
	mov DPTR, #CoolingState
	lcall SendString
	ret
	
;Needs some work to show exact values
showTemp:
	mov a, #0C0H
	lcall LCD_command
	mov DPTR, #DisplayTemp
	lcall SendString
	mov a, curr_temp+2
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_put
	mov a, curr_temp+1
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_put
	mov a, curr_temp+0
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_put
	mov a, #0x43
	lcall LCD_put
    ret
   
	
StartPrompts:

	;Defaults for Temps and Times
	;SoakTemp
	
	mov a, #80H
	lcall LCD_command ;Sets pointer to first line
	
	mov DPTR, #PleaseSet
	lcall SendString

PromptsTest:
	mov a, SWA
	jb acc.0, SoakTempPrompt
	jb acc.1, SoakTimePrompt
	jb acc.2, ReflowTempPrompt
	jb acc.3, ReflowTimePrompt
	jnb key.1, EndPrompt
	sjmp PromptsTest
	
EndPrompt:
	ret

SoakTempPrompt:
	mov a,#0C0H ;Sets pointer to second line
	lcall LCD_command
	
	mov DPTR, #SoakTemp1
	lcall SendString
	
	lcall Enter_soak_temp
	lcall Display_null
	
	sjmp PromptsTest

SoakTimePrompt:
	mov a, #0C0H
	lcall LCD_command
	
	mov DPTR, #SoakTime1
	lcall SendString
	
	lcall Enter_soak_time
	lcall Display_null
	
	sjmp PromptsTest

ReflowTempPrompt:
	mov a, #0C0H
	lcall LCD_command
	
	mov DPTR, #ReflowTemp1
	lcall SendString
	
	lcall Enter_reflow_temp
	lcall Display_null
	
	sjmp PromptsTest
	
ReflowTimePrompt:
	mov a, #0C0H
	lcall LCD_command
	
	mov DPTR, #ReflowTime1
	lcall SendString
	
	lcall Enter_reflow_time
	lcall Display_null
	
	sjmp PromptsTest
	
Display_null:
	mov HEX0, #0xFF
	mov HEX1, #0xFF
	mov HEX2, #0xFF
	ret
	
SetTimer2:

	mov T2CON, #00H
	clr TR2
	clr TF2
	mov RCAP2H,#high(TIMER0_RELOAD)
	mov RCAP2L,#low(TIMER0_RELOAD)
	setb TR2
	setb ET2
	
	mov Cnt_10ms, #0
	mov Sec, #0
	mov Min, #0
	mov curr_state, #0
	
	mov a,#80H
	lcall LCD_command
	
	mov DPTR, #StartMessage
	lcall SendString
	
	mov a,#0C0H
	lcall LCD_command
	
	mov DPTR, #StopMessage
	lcall SendString
	
	ret
	
WaitForStart:
	jnb KEY.1, StartProcess
	sjmp WaitForStart
	
StartProcess:
	ret

	
	