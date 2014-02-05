$NOLIST

CSEG

;---------------------------------------------
;Enter_Reflow_Time
;---------------------------------------------
Enter_Reflow_Time:
	mov x+0, R4
	lcall hex2bcd
	lcall display
	
	Main_Reflow_Time:
		mov A, SWA
		jnb acc.0, Return_Enter_Parameters_Reflowtime
		jnb key.2, Check_reflowtime_bound_inc
		jnb key.3, Check_reflowtime_bound_dec
		sjmp Main_Reflow_Time
	
	Check_reflowtime_bound_inc:
		jnb key.2, Check_reflowtime_bound_inc
		;if temp is 45, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #45, increment_reflowtime
		lcall hex2bcd
		sjmp Main_Reflow_time
		
	increment_reflowtime:
		load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Reflow_time
		
	Check_reflowtime_bound_dec:
		jnb key.3, Check_reflowtime_bound_dec
		;if temp is 30, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #30, decrement_reflowtime
		lcall hex2bcd
		sjmp Main_reflow_time
		
	decrement_reflowtime:
		load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_reflow_time
	
	Return_Enter_Parameters_Reflowtime:
		lcall bcd2hex
		mov a, x+0
		mov R4, a
		ret
;---------------------------------------------
;Enter_Reflow_Temp
;---------------------------------------------
Enter_Reflow_Temp:
	mov x+0, R5
	lcall hex2bcd
	lcall display
	
	Main_Reflow_Temp:
		mov A, SWA
		jnb acc.1, Return_Enter_Parameters_Reflowtemp
		jnb key.2, Check_reflowtemp_bound_inc
		jnb key.3, Check_reflowtemp_bound_dec
		sjmp Main_Reflow_Temp
	
	Check_reflowtemp_bound_inc:
		jnb key.2, Check_reflowtemp_bound_inc
		;if temp is 230, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #230, increment_reflowtemp
		lcall hex2bcd
		sjmp Main_Reflow_temp
		
	increment_reflowtemp:
		load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Reflow_temp
		
	Check_reflowtemp_bound_dec:
		jnb key.3, Check_reflowtemp_bound_dec
		;if temp is 219, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #219, decrement_reflowtemp
		lcall hex2bcd
		sjmp Main_reflow_temp
		
	decrement_reflowtemp:
		load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_reflow_temp
	
	Return_Enter_Parameters_Reflowtemp:
		lcall bcd2hex
		mov a, x+0
		mov R5, a
		ret
;---------------------------------------------
;Enter_Soak_Time
;---------------------------------------------
Enter_Soak_Time:
	mov x+0, R6
	lcall hex2bcd
	lcall display
	
	Main_Soak_Time:
		mov A, SWA
		jnb acc.2, Return_Enter_Parameters_Soaktime
		jnb key.2, Check_Soaktime_bound_inc
		jnb key.3, Check_Soaktime_bound_dec
		sjmp Main_Soak_Time
	
	Check_Soaktime_bound_inc:
		jnb key.2, Check_Soaktime_bound_inc
		;if temp is 90, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #90, increment_Soaktime
		lcall hex2bcd
		sjmp Main_Soak_time
		
	increment_Soaktime:
		load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_time
		
	Check_soaktime_bound_dec:
		jnb key.3, Check_soaktime_bound_dec
		;if temp is 60, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #60, decrement_soaktime
		lcall hex2bcd
		sjmp Main_Soak_time
		
	decrement_Soaktime:
		load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_time
	
	Return_Enter_Parameters_Soaktime:
		lcall bcd2hex
		mov a, x+0
		mov R6, a
		ret
;---------------------------------------------
;Enter_Soak_Temp
;---------------------------------------------
Enter_Soak_Temp:
	mov x+0, R7
	lcall hex2bcd
	lcall display
	
	Main_Soak_Temp:
		mov A, SWA
		jnb acc.3, Return_Enter_Parameters_Soaktemp
		jnb key.2, Check_Soaktemp_bound_inc
		jnb key.3, Check_Soaktemp_bound_dec
		sjmp Main_Soak_Temp
	
	Check_Soaktemp_bound_inc:
		jnb key.2, Check_Soaktemp_bound_inc
		;if temp is 200, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #200, increment_Soaktemp
		lcall hex2bcd
		sjmp Main_Soak_temp
		
	increment_Soaktemp:
		load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_temp
		
	Check_soaktemp_bound_dec:
		jnb key.3, Check_soaktemp_bound_dec
		;if temp is 140, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #140, decrement_soaktemp
		lcall hex2bcd
		sjmp Main_Soak_temp
		
	decrement_Soaktemp:
		load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_temp
	
	Return_Enter_Parameters_Soaktemp:
		lcall bcd2hex
		mov a, x+0
		mov R7, a
		ret
$LIST