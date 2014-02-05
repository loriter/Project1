$MODDE2

CLK EQU 33333333
FREQ_0 EQU 100
TIMER0_RELOAD EQU 65536-(CLK/(12*FREQ_0)) ;change calculations to 1 second

start_temp EQU 0

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
	
DSEG at 30H
x:   	     ds 4
y: 	 	     ds 4
bcd: 	     ds 5
soak_temp:	 ds 1
soak_time:	 ds 1
reflow_temp: ds 1
reflow_time: ds 1
req_temp:    ds 4
curr_temp:   ds 4
prev_temp:   ds 4
temp_rate:   ds 4

BSEG
mf:           dbit 1
pwm_switch:   dbit 1
preheating:   dbit 1
processing:   dbit 1
cooling:      dbit 1
timer_done:   dbit 1
preheat_done: dbit 1
soak_done:    dbit 1
reflow_done:  dbit 1
cool_done:    dbit 1

CSEG

$include(math32.asm)

myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H

Display:
	mov dptr, #myLUT
    mov A, bcd+0
    anl a, #0fh
    movc A, @A+dptr
    mov HEX0, A
    mov A, bcd+0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX1, A
    mov A, bcd+1
    anl a, #0fh
    movc A, @A+dptr
    mov HEX2, A
    mov A, bcd+1
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX3, A
    mov A, bcd+2
    anl a, #0fh
    movc A, @A+dptr
    mov HEX4, A
    ret

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
Delay_loop:
	djnz R3, Delay_loop
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
	mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    djnz R5, Timer0_Interrupt_Ret ;when R5(required time) hits 0, set timer_done
    setb timer_done
Timer0_Interrupt_Ret:
	reti

;for Oliver
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
	
	setb CE_ADC
	lcall Init_SPI
	
	mov TMOD, #00000001B
	clr TR0
	clr TF0
    setb ET0
    
    setb EA
	
Forever:
	;call whatever needs to be done
	jnb Key.1, Stop_Function ;check if stop key is pressed
	jb preheating, Preheat_Loop
	jb processing, Process_Jump
	jb cooling, Cool_Loop_Jump
	jb cool_done, End_Function
	jb reflow_done, Cool_Jump
	jb soak_done, Reflow
	jb preheat_done, Soak
	sjmp Preheat
Process_Jump:
	lcall Process_Maintain_Loop
Cool_Jump:
	ljmp Cool
Cool_Loop_Jump:
	ljmp Cool_Loop
	
Stop_Function:
	jnb Key.3, Stop_Function
	;call whatever needs when oven stops
End_Function:
	;call whatever when entire process done
	
;turns on oven and notifies user when it hits maximum preheat temp
Preheat:
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
	mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
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
	
	;I use 10^8 for 2 decimal accuracy
	;To turn voltage to microvoltage, multiyply by 10^6
	;To get the two extra decimals for accuracy sake, multiply above by 10^2
	Load_y(488281)         ;multiply bit by (0.00488281*10^8)
	mov x+3, #0
	mov x+2, #0
	mov x+1, R7
	mov x+0, R6
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