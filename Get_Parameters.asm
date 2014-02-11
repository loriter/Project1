$NOLIST

CSEG

;---------------------------------------------
;Enter_Reflow_Time
;---------------------------------------------
Enter_Reflow_Time:
	mov x+0, reflow_time
	lcall hex2bcd
	lcall display
	
	Main_Reflow_Time:
		mov A, SWA
		jnb acc.3, Return_Enter_Parameters_Reflowtime
		jnb key.2, Check_Reflowtime_Bound_Inc
		jnb key.3, Check_Reflowtime_Bound_Dec
		sjmp Main_Reflow_Time
	
	Check_Reflowtime_Bound_Inc:
		jnb key.2, Check_Reflowtime_Bound_Inc
		;if temp is 45, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #max_reflow_time, Increment_Reflowtime
		lcall hex2bcd
		sjmp Main_Reflow_time
		
	Increment_Reflowtime:
		Load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Reflow_Time
		
	Check_Reflowtime_Bound_Dec:
		jnb key.3, Check_Reflowtime_Bound_Dec
		;if temp is 30, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #min_reflow_time, Decrement_Reflowtime
		lcall hex2bcd
		sjmp Main_Reflow_Time
		
	Decrement_Reflowtime:
		Load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_Reflow_Time
	
	Return_Enter_Parameters_Reflowtime:
		lcall bcd2hex
		mov a, x+0
		mov reflow_time, a
		ret
;---------------------------------------------
;Enter_Reflow_Temp
;---------------------------------------------
Enter_Reflow_Temp:
	mov x+0, reflow_temp
	lcall hex2bcd
	lcall display
	
	Main_Reflow_Temp:
		mov A, SWA
		jnb acc.2, Return_Enter_Parameters_Reflowtemp
		jnb key.2, Check_Reflowtemp_Bound_Inc
		jnb key.3, Check_Reflowtemp_Bound_Dec
		sjmp Main_Reflow_Temp
	
	Check_Reflowtemp_Bound_Inc:
		jnb key.2, Check_Reflowtemp_Bound_Inc
		;if temp is 230, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #max_reflow_temp, Increment_Reflowtemp
		lcall hex2bcd
		sjmp Main_Reflow_temp
		
	Increment_Reflowtemp:
		Load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Reflow_Temp
		
	Check_Reflowtemp_Bound_Dec:
		jnb key.3, Check_Reflowtemp_Bound_Dec
		;if temp is 219, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #min_reflow_temp, Decrement_Reflowtemp
		lcall hex2bcd
		sjmp Main_Reflow_Temp
		
	Decrement_Reflowtemp:
		Load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_Reflow_Temp
	
	Return_Enter_Parameters_Reflowtemp:
		lcall bcd2hex
		mov a, x+0
		mov reflow_temp, a
		ret
;---------------------------------------------
;Enter_Soak_Time
;---------------------------------------------
Enter_Soak_Time:
	mov x+0, soak_time
	lcall hex2bcd
	lcall display
	
	Main_Soak_Time:
		mov A, SWA
		jnb acc.1, Return_Enter_Parameters_Soaktime
		jnb key.2, Check_Soaktime_Bound_Inc
		jnb key.3, Check_Soaktime_Bound_Dec
		sjmp Main_Soak_Time
	
	Check_Soaktime_Bound_Inc:
		jnb key.2, Check_Soaktime_Bound_Inc
		;if temp is 90, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #max_soak_time, Increment_Soaktime
		lcall hex2bcd
		sjmp Main_Soak_Time
		
	Increment_Soaktime:
		load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_Time
		
	Check_Soaktime_Bound_Dec:
		jnb key.3, Check_Soaktime_Bound_Dec
		;if temp is 60, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #min_soak_time, Decrement_Soaktime
		lcall hex2bcd
		sjmp Main_Soak_Time
		
	Decrement_Soaktime:
		Load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_Time
	
	Return_Enter_Parameters_Soaktime:
		lcall bcd2hex
		mov a, x+0
		mov soak_time, a
		ret
;---------------------------------------------
;Enter_Soak_Temp
;---------------------------------------------
Enter_Soak_Temp:
	mov x+0, soak_temp
	lcall hex2bcd
	lcall display
	
	Main_Soak_Temp:
		mov A, SWA
		jnb acc.0, Return_Enter_Parameters_Soaktemp
		jnb key.2, Check_Soaktemp_Bound_Inc
		jnb key.3, Check_Soaktemp_Bound_Dec
		sjmp Main_Soak_Temp
	
	Check_Soaktemp_Bound_Inc:
		jnb key.2, Check_Soaktemp_Bound_Inc
		;if temp is 200, will not increment
		lcall bcd2hex

		mov a, x+0
		cjne a, #max_soak_temp, Increment_Soaktemp
		lcall hex2bcd
		sjmp Main_Soak_temp
		
	Increment_Soaktemp:
		Load_y(1)
		lcall add32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_Temp
		
	Check_Soaktemp_Bound_Dec:
		jnb key.3, Check_Soaktemp_Bound_Dec
		;if temp is 140, will not decrement
		lcall bcd2hex

		mov a, x+0
		cjne a, #min_soak_temp, Decrement_Soaktemp
		lcall hex2bcd
		sjmp Main_Soak_Temp
		
	Decrement_Soaktemp:
		Load_y(1)
		lcall sub32
		lcall hex2bcd
		lcall display
		sjmp Main_Soak_temp
	
	Return_Enter_Parameters_Soaktemp:
		lcall bcd2hex
		mov a, x+0
		mov soak_temp, a
		ret
$LIST