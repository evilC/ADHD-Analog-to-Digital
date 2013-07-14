#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; The time a game needs to recognise a key down
min_delay := 50	

; The fraction of the delay time to run as a "clock"
; Should probably be at least 2
loop_time := min_delay / 2
time_on := 0
time_off := 0
button_down := 0
basetime := 0

/*
10% thrust
= 100ms in 1s
= 2x 50ms blocks on a 500ms tick?
= pressed for 50ms on a 500ms tick

1000 * 30%
30% thrust
= 300ms in 1s
300/50 = 6
1000/6 = 166.666
= pressed for 50ms on a 166.66ms tick
*/

Loop, {
	; How many ms in a second do we need to be holding the button?
	
	; XBOX controllerleft trigger
	GetKeyState, axis, 3JoyZ
	; trigger is half an axis, so ignore right trigger
	if (axis < 50){
		; Less than 50 is considered a "release", so call reset_vars
		Gosub, reset_vars
		continue
	}
	; Convert from 50-100 to 0-1000
	time_on := round((axis - min_delay) * 20, 2)

	/*
	;Flighstick throttle
	GetKeyState, axis, 1JoyZ
	; Convert from 0-100 to 0-1000
	; 30%: 300ms
	time_on := round(axis * 10, 2)
	*/
	
	; Check that the amount of time we need to hold the button is more than the minimum delay
	if (time_on >= min_delay){
		num_presses := time_on / min_delay
		tick_rate := 1000 / num_presses
		
		time_off := 1000 - time_on
		if (button_down){
			; Process UP
			; Wait for time from last press, plus min delay
			if (A_TickCount >= basetime + min_delay){
				; LEAVE basetime as the time when key was last pressed
				if (time_on != 1000){
					button_down := 0
					If Winactive("ahk_class CryENGINE"){
						;Send up
						Send {space up}
					}
				}
			}
			
		} else {
			; Process DOWN
			; Wait for time from last press, plus the tick rate, ?plus the amount delayed?
			if (A_TickCount >= basetime + tick_rate){
				button_down := 1
				; Set basetime to time when we last pressed
				basetime := A_TickCount
				If Winactive("ahk_class CryENGINE"){
					;Send down
					Send {space down}
				}
				
			}
			
		}
	} else {
		Gosub, reset_vars
	}
	Sleep, % loop_time
}
return

reset_vars:
	time_on := 0
	time_off := 0
	if (button_down){
		Send {space up}
		button_down := 0
	}
	
	basetime := 0
	tick_rate := 0
	tooltip,
	return

; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
;#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
