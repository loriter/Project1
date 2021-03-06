$MODDE2

CLK           EQU 33333333
FREQ_0        EQU 100
FREQ_2        EQU 100
TIMER0_RELOAD EQU 65536-(CLK/(12*FREQ_0)) ;change calculations to 1 second
TIMER2_RELOAD EQU 65536-(CLK/(12*FREQ_2))

start_temp      EQU 0
min_soak_time   EQU 60
max_soak_time   EQU 90
min_soak_temp   EQU 140
max_soak_temp   EQU 200
min_reflow_time EQU 30
max_reflow_time EQU 45
min_reflow_temp EQU 219
max_reflow_temp EQU 225

MISO   EQU  P0.0 
MOSI   EQU  P0.1 
SCLK   EQU  P0.2
CE_ADC EQU  P0.3
CE_EE  EQU  P0.4
CE_RTC EQU  P0.5 
SSR    EQU  P1.0

org 0000H
	ljmp Program_Init
org 000BH
	ljmp Timer0_Interrupt
org 002BH
	ljmp Timer2_Interrupt
	
DSEG at 30H
cnt_10ms:    ds 1
cnt_10ms2:   ds 1
sec:		 ds 1
min:		 ds 1
x:   	     ds 4
y: 	 	     ds 4
bcd: 	     ds 5
soak_temp:	 ds 1
soak_time:	 ds 1
reflow_temp: ds 1
reflow_time: ds 1
req_temp:    ds 5
curr_temp:   ds 5
prev_temp:   ds 5
temp_rate:   ds 5
curr_string: ds 1
dptr_count:  ds 1
create_data: ds 34

BSEG
mf:           dbit 1
roll_start:   dbit 1
roll_state2:  dbit 1
roll_state3:  dbit 1
carry_set:    dbit 1
pwm_switch:   dbit 1
started:      dbit 1
preheating:   dbit 1
processing:   dbit 1
cooling:      dbit 1
timer_done:   dbit 1
preheat_done: dbit 1
soak_done:    dbit 1
reflow_done:  dbit 1
cool_done:    dbit 1

XSEG

xcreate_data: ds 34

CSEG

$include(math32.asm)
$include(Get_Parameters.asm)
$include(LCD_Controller.asm)

UseSwitch:    DB 'SW0-3:Parameters', 0
UseKey1:      DB 'KEY1:Start      ', 0
UseKey2:      DB 'KEY2:Stop       ', 0
PleaseSet:    DB 'Please set the  ', 0
SoakTemp:     DB 'Soak Temp       ', 0
SoakTime:     DB 'Soak Time       ', 0
ReflowTemp:   DB 'Reflow Temp     ', 0
ReflowTime:   DB 'Reflow Time     ', 0
PreHeatState: DB 'Preheat State   ', 0
SoakState:    DB 'Soaking State   ', 0
ReflowState:  DB 'Reflow State    ', 0
CoolingState: DB 'Cooling State   ', 0
DisplayTemp:  DB 'Temp: ',0
DSoakTemp:    DB 'Soak Temp: ', 0 
DSoakTime:    DB 'Soak Time: ', 0
DReflowTemp:  DB 'Reflow Temp: ', 0
DReflowTime:  DB 'Reflow Time: ', 0
DisplayClear: DB '                ', 0
myLUT:        DB 0C0H, 0F9H, 0A4H, 0B0H, 099H, 092H, 082H, 0F8H, 080H, 090H

INIT_SPI:
    orl P0MOD, #00000110b
    anl P0MOD, #11111110b
    clr SCLK
	ret

DO_SPI_G:
	push acc
    mov R1, #0
    mov R2, #8
DO_SPI_G_LOOP:
    mov a, R0
    rlc a
    mov R0, a
    mov MOSI, c
    setb SCLK
    mov c, MISO
    mov a, R1
    rlc a
    mov R1, a
    clr SCLK
    djnz R2, DO_SPI_G_LOOP
    pop acc
    ret

Delay:
	mov R3, #20
Delay_Loop:
	djnz R3, Delay_Loop
	ret
	
Read_ADC_Channel:
	clr CE_ADC
	mov R0, #00000001B
	lcall DO_SPI_G
	
	mov a, b
	swap a
	anl a, #0F0H
	setb acc.7
	
	mov R0, a
	lcall DO_SPI_G
	mov a, R1
	anl a, #03H
	mov R7, a
	
	mov R0, #55H
	lcall DO_SPI_G
	mov a, R1
	mov R6, a
	setb CE_ADC
	ret

Timer0_Interrupt:
	push psw
	push acc
	push dpl
	push dph
	
	mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    clr TF0
    
    mov a, cnt_10ms2
    inc a
    mov cnt_10ms, a
    
    cjne a, #100, Timer0_Interrupt_Ret
    
    mov cnt_10ms, #0
    
    djnz R5, Timer0_Interrupt_Ret ;when R5(required time) hits 0, set timer_done
    setb timer_done
Timer0_Interrupt_Ret:
	pop dph
	pop dpl
	pop acc
	pop psw
	
	reti

PWM_On:
	setb SSR ;turn on oven
	ret
PWM_Off:
	clr SSR  ;turn off oven
	ret
PWM_Speed:
	;determine the speed at which the oven temp should be rising
	jb PWM_Switch, PWM_Decrease
	sjmp PWM_Increase
	
PWM_Increase:
	;increase on pulses
	ret
PWM_Decrease:
	;decrease off pulses
	ret

Program_Init:
	mov SP,    #7FH
	mov LEDRA, #0
	mov LEDRB, #0
	mov LEDRC, #0
	mov LEDG,  #0
	
	mov curr_string, #0
	setb roll_start
	mov dptr_count, #0
	clr preheat_done
	clr soak_done
	clr reflow_done
	clr cool_done
	clr preheating
	clr processing
	clr cooling
	
	mov x+0, #0
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	
	mov y+0, #0
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
		
	mov soak_time, #min_soak_time
	mov soak_temp, #min_soak_temp
	mov reflow_time, #min_reflow_time
	mov reflow_temp, #min_reflow_temp
	
	clr started
		
	setb CE_ADC
	lcall Init_SPI
	lcall LCD_init
	
	mov TMOD, #00000001B
	clr TR0
	clr TF0
	mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
	mov cnt_10ms2, #0
    setb ET0
    setb EA
    
	lcall Start_Prompts
	lcall Set_Timer2
	lcall Wait_For_Start
	mov a, #80H
	lcall LCD_Command
	mov dptr, #DisplayClear
	lcall Send_String
	mov a, #0C0H
	lcall LCD_Command
	mov dptr, #DisplayClear
	lcall Send_String
	
Forever:
	;lcall Show_Temp
	;call whatever needs to be done
	jnb Key.2, Stop_Function ;check if stop key is pressed
	jb preheating, Preheat_Loop
	jb processing, Process_Jump
	jb cooling, Cool_Loop_Jump
	jb cool_done, End_Function
	jb reflow_done, Cool_Jump
	jb soak_done, Reflow
	jb preheat_done, Soak
	sjmp Preheat
Process_Jump:
	ljmp Process_Maintain_Loop
Cool_Jump:
	ljmp Cool
Cool_Loop_Jump:
	ljmp Cool_Loop
	
Stop_Function:
	mov LEDG, #3
	clr TF2
	jb Key.3, Stop_Function
	;call whatever needs when oven stops
End_Function:
	;call whatever when entire process done
	
;turns on oven and notifies user when it hits maximum preheat temp
Preheat:
	lcall Show_State
	Load_req_temp(14000)  ;load required temperature to 140 degrees
	setb preheating
Preheat_Loop:
	lcall cmp_temp        ;compares current temp with required temp
	jb mf, Preheat_End    ;if current temp > required temp, end preheat
	lcall PWM_On          ;turn on oven
	ljmp Forever     ;loops until current temp > required temp
Preheat_End:
	clr preheating
	setb preheat_done     ;end of preheat
	ljmp Forever

;maintains temperature of oven at soak temp for the required time
Soak_Pre:
	;call pwm function that raises preheat temp to soak temp
	;this is where we we increase/decrease pulse to quicken/slow heating
Soak:
	lcall Show_State
	mov x+0, soak_temp    ;defined by user and placed in this variable
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	Load_y(100)
	lcall mul32           ;make soak temp accurate to two decimals
	
	mov R5, soak_time     ;defined by user and placed in this variable
	
	sjmp Process_Init    ;call process to maintain heat at required temp
Soak_End:
	setb soak_done        ;end of soak
	ljmp forever

;works similar to soak, but for reflow temp
Reflow_Pre:
	;call pwm function that raises preheat temp to reflow temp
	;this is where we we increase/decrease pulse to quicken/slow heating
Reflow:
	lcall Show_State
	mov x+0, reflow_temp
	mov x+1, #0
	mov x+2, #0
	mov x+3, #0
	Load_y(100)
	lcall mul32
	
	mov R5, reflow_time
	
	sjmp Process_Init
Reflow_End:
	setb reflow_done
	ljmp forever

Process_Init:
	;x has required temp defined by user, accurate to two decimals
	mov req_temp+0, x+0 
	mov req_temp+1, x+1
	mov req_temp+2, x+2
	mov req_temp+3, x+3
	
	;start timer for required time (read annotations on timer 0 interrupt)
	;R5 has required time
	clr timer_done
	setb TR0
	
	setb processing
Process_Maintain_Loop:
	jb timer_done, Process_End       ;loops until soak time is done
	lcall cmp_temp
	jb mf, Process_Maintain_Off      ;if current temp > soak temp, turn oven off
	lcall PWM_On                     ;else turn oven on
	ljmp Forever
Process_Maintain_Off:
	lcall PWM_Off
	ljmp Forever
Process_End:
	clr processing
	jb soak_done, Reflow_End
	ljmp Soak_End

;turns off oven and notifies user when oven is at room temp
;works similar to preheat
Cool:
	lcall Show_State
	Load_req_temp(2500)
	setb cooling
Cool_Loop:
	lcall cmp_temp
	jnb mf, Cool_End
	lcall PWM_Off
	ljmp forever
Cool_End:
	clr cooling
	setb cool_done
	ljmp End_Function
	
;change if necessary
Get_Temp:
	mov b, #0
	lcall Read_ADC_Channel
	
	;Load_y(100)
	;mov x+3, #0
	;mov x+2, #0
	;mov x+1, R7
	;mov x+0, R6
	;lcall mul32
	
	;Load_y(4)
	;lcall div32
	
	;mov curr_temp+0, x+0
	;mov curr_temp+1, x+1
	;mov curr_temp+2, x+2
	;mov curr_temp+3, x+3
	
	;lcall Delay
	
	;ret
	
	;I use 10^8 for 2 decimal accuracy
	;To turn voltage to microvoltage, multiyply by 10^6
	;To get the two extra decimals for accuracy sake, multiply above by 10^2
	Load_y(488281)         ;multiply bit by (0.00488281*10^8)
	mov x+3, #0
	mov x+2, #0
	mov x+1, #0
	mov x+0, #0
	lcall mul32
	
	Load_y(19270)          ;divide by (41uV*470)
	lcall div32
	
	Load_y(start_temp)     ;add starting temp to get current temp in oven
	lcall add32
	
	;x now has temperature accurate to 2 decimal
	;can use this when displaying temp on LCD
	mov curr_temp+0, x+0
	mov curr_temp+1, x+1
	mov curr_temp+2, x+2
	mov curr_temp+3, x+3
	
	lcall Delay
	
	ret

;compares current temp with required temp
;mf=1 if current temp > required temp
Cmp_Temp:
	lcall Get_Temp

	mov y+0, req_temp+0
	mov y+1, req_temp+1
	mov y+2, req_temp+2
	mov y+3, req_temp+3
	
	;x has current temperature accurate to 2 decimal
	lcall x_gt_y
	
	ret

;ignore
PWM_Cmp_Temp:
	lcall Get_Temp
	
    mov y+0, prev_temp+0
    mov y+1, prev_temp+1
    mov y+2, prev_temp+2
    mov y+3, prev_temp+3
    
    lcall sub32
    
    mov y+0, temp_rate+0
    mov y+1, temp_rate+1
    mov y+2, temp_rate+2
    mov y+3, temp_rate+3
    
    lcall x_gt_y
    
    mov prev_temp+0, curr_temp+0
    mov prev_temp+1, curr_temp+1
    mov prev_temp+2, curr_temp+2
    mov prev_temp+3, curr_temp+3    
    ret
	
END