;TODO: Convert Temperature to ASCII and display it
;TODO: Have state changes after certain times

$MODDE2

org 0000H
	ljmp MyProgram
	
org 002BH
	ljmp ISR_timer2
	
CLK EQU 33333333
FREQ EQU 100
TIMER2_RELOAD EQU 65536-(CLK/(12*FREQ))
	
DSEG at 30H
Cnt_10ms: ds 1
ReflowTemp: ds 4
ReflowTime: ds 1
SoakTemp: ds 4
SoakTime: ds 1
Sec: ds 1
Min: ds 1
SoakSec: ds 1
ReflowSec: ds 1
CurrentTemp: ds 4
CurrentState: ds 1
Finished: ds 1
x: ds 2
y: ds 2
bcd: ds 3

BSEG
mf:     dbit 1

CSEG

$include(math32.asm)
$include(LCDtest.asm)

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
    
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
	
	mov a, CurrentState
	cjne a, #1, checkReflowTime
	mov a, SoakSec
	add a, #1
	da a
	mov SoakSec, a
	sjmp UpdateSec
	
checkReflowTime:
	mov a, CurrentState
	cjne a, #2, UpdateSec
	mov a, ReflowSec
	add a, #1
	da a
	mov ReflowSec, a
	
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
	DB 'KEY2 to stop', 0
	
PreHeatState:
	DB 'Preheat State', 0

SoakState:
	DB 'Soaking State', 0
	
ReflowState:
	DB 'Reflow State', 0
	
CoolingState:
	DB 'Cooling State', 0
	
DisplayTemp:
	DB 'Temperature:', 0 
	
showState:
	mov a, #80H
	lcall LCD_command
	mov a, CurrentState
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
	
showTemp:
	mov a, #0C0H
	lcall LCD_command
	mov DPTR, #DisplayTemp
	lcall SendString
	mov a, CurrentTemp+2
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_put
	mov a, CurrentTemp+1
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_put
	mov a, CurrentTemp
	anl a, #00001111B
	orl a, #00110000B
	lcall LCD_put
	mov a, #0x43
	lcall LCD_put
    ret
    
checkState:
	mov a, CurrentState
	cjne a, #0, switchSoak
	mov a, CurrentTemp
	cjne a, #0x05, switchSoak
	mov CurrentState, #1
	lcall showState
	ret
switchSoak:
	mov a, CurrentState
	cjne a, #1, switchReflow
	mov a, SoakSec
	cjne a, SoakTime, switchReflow
	mov CurrentState, #2
	lcall showState
	ret
switchReflow:
	mov a, CurrentState
	cjne a, #2, switchCool
	mov a, ReflowSec
	cjne a, ReflowTime, switchCool
	mov CurrentState, #3
	lcall showState
	ret
switchCool:
	mov a, CurrentTemp
	cjne a, #100, endState
	mov Finished, #1
endState:
	ret
    
MyProgram:
	mov SP, #7FH
	mov LEDRA, #0
	mov LEDRB, #0
	mov LEDRC, #0
	mov LEDG, #0
	
	lcall LCD_Init
	
	mov a, #80H
	lcall LCD_command ;Sets pointer to first line
	
	mov DPTR, #PleaseSet
	lcall SendString

SoakTempPrompt:
	mov a,#0C0H ;Sets pointer to second line
	lcall LCD_command
	
	mov DPTR, #SoakTemp1
	lcall SendString
	
	lcall WaitHalfSec

SoakTimePrompt:
	mov a, #0C0H
	lcall LCD_command
	
	mov DPTR, #SoakTime1
	lcall SendString
	
	lcall WaitHalfSec

ReflowTempPrompt:
	mov a, #0C0H
	lcall LCD_command
	
	mov DPTR, #ReflowTemp1
	lcall SendString
	
	lcall WaitHalfSec
	
ReflowTimePrompt:
	mov a, #0C0H
	lcall LCD_command
	
	mov DPTR, #ReflowTime1
	lcall SendString
	
	lcall WaitHalfSec
	
TimerSet:

	mov T2CON, #00H
	clr TR2
	clr TF2
	mov RCAP2H,#high(TIMER2_RELOAD)
	mov RCAP2L,#low(TIMER2_RELOAD)
	setb TR2
	setb ET2
	
	mov Cnt_10ms, #0
	mov Sec, #0
	mov Min, #0
	mov SoakSec, #0
	mov ReflowSec, #0
	mov SoakTime, #5
	mov ReflowTime, #5
	mov CurrentTemp, #0x05
	mov CurrentTemp+1, #0x02
	mov CurrentTemp+2, #0x01
	mov CurrentState, #0
	mov Finished, #0
	
	mov a,#80H
	lcall LCD_command
	
	mov DPTR, #StartMessage
	lcall SendString
	
	mov a,#0C0H
	lcall LCD_command
	
	mov DPTR, #StopMessage
	lcall SendString
	
WaitForStart:
	jnb KEY.1, StartProcess
	sjmp WaitForStart
	
StartProcess:
	setb EA
	mov LEDG, #1
	lcall showState
Running:
	jnb KEY.2, EndProcess
	lcall showTemp
	lcall checkState
	mov a, Finished
	cjne a, #0, EndProcess
	sjmp Running
EndProcess:
	mov LEDG, #3
	clr TR2
	sjmp EndProcess
end
	
	
	
	