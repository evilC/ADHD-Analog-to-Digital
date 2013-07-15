
; Create an instance of the library
ADHD := New ADHDLib

; ============================================================================================
; CONFIG SECTION - Configure ADHD

; Authors - Edit this section to configure ADHD according to your macro.
; You should not add extra things here (except add more records to hotkey_list etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box

ADHD.config_about({name: "Analog to Digital", version: 1.3, author: "evilC", link: "<a href=""http://mwomercs.com/forums/topic/127120-analog-to-digital-analog-jump-jets-variable-fire-rate-gatling-gun-ac2"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(375,335)

; We need no actions, so disable warning
ADHD.config_ignore_noaction_warning()

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("option_changed", "option_changed_hook")

ADHD.init()
ADHD.create_gui()

; The "Main" tab is tab 1
Gui, Tab, 1
; ============================================================================================
; GUI SECTION

axis_list_ahk := Array("X","Y","Z","R","U","V")

Gui, Add, GroupBox, x5 yp+25 R1 W365 R3 section, Input Configuration
Gui, Add, Text, x15 ys+20, Joystick ID
ADHD.gui_add("DropDownList", "JoyID", "xp+60 yp-5 W50", "1|2|3|4|5|6|7|8", "1")

Gui, Add, Text, xp+60 ys+20, Axis
ADHD.gui_add("DropDownList", "JoyAxis", "xp+30 yp-5 W50", "1|2|3|4|5|6", "1")

ADHD.gui_add("CheckBox", "InvertAxis", "xp+60  yp+5", "Invert Axis", 0)

Gui, Add, Text, x15 ys+50, Use Half Axis
ADHD.gui_add("DropDownList", "HalfAxis", "xp80 yp-5 W50", "None|Low|High", "None")
HalfAxis_TT := "Use only half the axis - eg for XBOX left trigger, use ""High"""

Gui, Add, GroupBox, x5 yp+40 R1 W365 R1.2 section, Output Configuration
Gui, Add, Text, x15 ys+20, Fire Sequence
ADHD.gui_add("Edit", "FireSequence", "xp+120 yp-5 W80", "", "Space")
FireSequence_TT := "One key or a sequence of keys separated by commas, eg 1,2,3,4`nAHK key names. ie ""Space"" not "" """

Gui, Add, GroupBox, x5 yp+30 R1 W365 section, Fire Rate
Gui, Add, Text, x15 ys+15, Min
ADHD.gui_add("Edit", "FireRateMin", "xp+50 yp-5 W50", "", "0")
FireRateMin_TT := "Minimum Fire Rate (in ms) Default is 0"

Gui, Add, Text, xp+70 ys+15, Max
ADHD.gui_add("Edit", "FireRateMax", "xp+40 yp-5 W50", "", "1000")
FireRateMax_TT := "Maximum Fire Rate (in ms) Default is 1000"

Gui, Add, Text, xp+70 ys+15, Bands
ADHD.gui_add("Edit", "FireRateBands", "xp+40 yp-5 W50", "", "0")
FireRateBands_TT := ""

Gui, Add, GroupBox, x5 yp+30 R3.5 W365 section, Debugging
Gui, Add, Text, x15 ys+15, Current axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueIn Disabled,

Gui, Add, Text, xp+60 ys+15, Adjusted axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueOut Disabled,

Gui, Add, Text, x15 yp+25, Current fire rate (ms)
Gui, Add, Edit, xp+120 yp-2 W50 R1 vCurrFireRate Disabled,

Gui, Add, Text, xp+70 yp+2, Fire State: 
Gui, Add, Text, xp+50 yp W80 vFireState,

Gui, Add, CheckBox, x15 yp+25 vPlayDebugBeeps gdebug_beep_changed, Play debug beeps


; End GUI creation section
; ============================================================================================

/*
; The time a game needs to recognise a key down
min_delay := 50	

; The fraction of the delay time to run as a "clock"
; Should probably be at least 2
loop_time := min_delay / 2
time_on := 0
button_down := 0
basetime := 0
*/
allowed_fire := 1

; New
; The time a game needs to recognise a key down
min_delay := 50	

last_tick := 0
button_down := 0
fire_sequence := []
fire_seq_count := 0	; cached count of fire_sequence



ADHD.finish_startup()


Loop, {
	; Store time at start of tick to try and keep calculations and timings constant
	loop_time := A_TickCount
	; Conform the axis to 1 to 100
	axis := conform_axis()
	
	if (axis > 0){
		tick_rate := (100 - axis) * 10
	} else {
		; set tick rate off
		tick_rate := -1
	}
	
	; Adjust tick_rate according to options
	if (tick_rate == -1){
		GuiControl,,CurrFireRate, % "Off"	
	} else {
		; If not on a sequence, restrict tick_rate to min_delay
		if (tick_rate < min_delay && fire_seq_count == 1){
			tick_rate := min_delay
		}
		GuiControl,,CurrFireRate, % tick_rate
	}
	
	; Process any waiting key up events
	; We should probably do this before processing key downs, so we maintain order, even at high rates
	if (button_down && (last_tick + min_delay <= loop_time)){
		if (tick_rate > min_delay || fire_seq_count > 1){
			button_down := 0
			set_fire_state(button_down)
			if (PlayDebugBeeps){
				soundbeep, 750, 20
			}
		}
	}
	
	; Process any waiting key down events
	;tooltip, % "tick_rate: " tick_rate " last_tick: " last_tick " loop_time: " loop_time
	; Conditions for sending key down:
	; Button is not already down (could be at 100% and key ups not getting sent, so dont send key downs
	; tick_rate is not disabled
	; it is time for another tick
	if (!button_down && tick_rate != -1 && (last_tick + tick_rate <= loop_time)){
		last_tick := loop_time
		button_down := 1
		set_fire_state(button_down)
		if (PlayDebugBeeps){
			soundbeep, 500, 20
		}
	}
	
	
	Sleep, 10
	
	/*
	; How many ms in a second do we need to be holding the button?
	
	tmp := JoyID "Joy" axis_list_ahk[JoyAxis]
	GetKeyState, axis, % tmp
	if (InvertAxis){
		axis := 100 - axis
	}
	axis := round(axis,2)
	GuiControl,,AxisValueIn, % axis
	; trigger is half an axis, so ignore right trigger
	if (HalfAxis == "Low"){
		if (axis <= 50){
			; Convert from 0(max press)-50(no press) to 0-100
			axis := (50 - axis) * 2
		} else {
			Gosub, reset_vars
			continue
		}
	} else if (HalfAxis == "High"){
		if (axis >= 50){
			; Convert from 50-100 to 0-100
			axis := (axis - 50) * 2
	} else {
			Gosub, reset_vars
			continue
		}
	}
	axis := round(axis,2)
	GuiControl,,AxisValueOut, % axis
	time_on := round(axis * 10, 2)
	time_on := time_on / FireRateMin
	;GuiControl,,CurrFireRate, % round(time_on)
	
	; Check that the amount of time we need to hold the button is more than the minimum delay
	if (time_on >= min_delay){
		num_presses := time_on / min_delay
		tick_rate := 1000 / num_presses
		GuiControl,,CurrFireRate, % round(tick_rate)
		
		if (button_down){
			; Process UP
			; Wait for time from last press, plus min delay
			if (A_TickCount >= basetime + min_delay){
				; LEAVE basetime as the time when key was last pressed
				; Do not send key up at 100% rate
				; If time_on is 1000 (ie no time left to send a key up), only send key up if more than one key used
				if (time_on != 1000 || fire_sequence.MaxIndex() > 1){
					send_key_up()
				}
			}
			
		} else {
			; Process DOWN
			; Wait for time from last press, plus the tick rate, ?plus the amount delayed?
			if (A_TickCount >= basetime + tick_rate){
				if (allowed_fire){
					; Set basetime to time when we last pressed
					basetime := A_TickCount
					send_key_down()
				}
				
			}
		}
	} else {
		Gosub, reset_vars
	}
	Sleep, % loop_time
	*/
}
return

test(){
	;soundbeep
}

; Conform the input value from an axis to a range between 0 and 100
; Handles invert, half axis usage (eg xbox left trigger) etc
conform_axis(){
	global axis_list_ahk
	global JoyID
	global JoyAxis
	global InvertAxis
	global HalfAxis
	
	tmp := JoyID "Joy" axis_list_ahk[JoyAxis]
	GetKeyState, axis, % tmp
	if (InvertAxis){
		axis := 100 - axis
	}
	GuiControl,,AxisValueIn, % round(axis,1)
	; trigger is half an axis, so ignore right trigger
	if (HalfAxis == "Low"){
		if (axis <= 50){
			; Convert from 0(max press)-50(no press) to 0-100
			axis := (50 - axis) * 2
		} else {
			axis := 0
		}
	} else if (HalfAxis == "High"){
		if (axis >= 50){
			; Convert from 50-100 to 0-100
			axis := (axis - 50) * 2
	} else {
			axis := 0
		}
	}
	;axis := round(axis,1)
	GuiControl,,AxisValueOut, % axis
	return axis
}

set_fire_state(state){
	global axis
	if (axis == 100){
		GuiControl, +cred, FireState
		GuiControl,,FireState, Max Rate
		return
	}
	if (state){
		; Fire is on
		
		GuiControl, +cred, FireState
		GuiControl,,FireState, Down
	} else {
		; Fire is off
		
		GuiControl, +cgreen, FireState
		GuiControl,,FireState, Up
	}
}

; Pull value through for debug beep without triggering a gui submit
debug_beep_changed:
	GuiControlGet, PlayDebugBeeps
	return

/*
reset_vars:
	time_on := 0
	if (button_down){
		send_key_up()
	}
	
	basetime := 0
	tick_rate := 0
	return
*/

send_key_down(){
	global fire_cur
	global fire_seq_count
	global fire_sequence
	global button_down
	
	button_down := 1
	Send % "{" fire_sequence[fire_cur] " down}"

}
	
send_key_up(){
	global fire_cur
	global fire_seq_count
	global fire_sequence
	global button_down

	button_down := 0
	Send % "{" fire_sequence[fire_cur] " up}"
	
	fire_cur := fire_cur + 1
	if (fire_cur > fire_seq_count){
		fire_cur := 1
	}

}
	
app_active_hook(){
	global allowed_fire
	allowed_fire := 1
	
}

app_inactive_hook(){
	global allowed_fire
	allowed_fire := 0

}

option_changed_hook(){
	global ADHD
	global allowed_fire
	global FireSequence
	global fire_sequence
	global fire_cur
	global fire_seq_count
	
	; New
	set_fire_state(0)	; init the output display
	
	; Old
	
	fire_seq_count := 0
	StringSplit, tmp, FireSequence, `,
	fire_sequence := []
	Loop, % tmp0
	{
		fire_seq_count := fire_seq_count + 1
		fire_sequence[A_index] := tmp%A_Index%
	}
	
	; Reset allowed_fire if we enabled/disabled limit app
	allowed_fire := !ADHD.config_get_default_app_on()
	fire_cur := 1
	;Gosub, reset_vars
	
	
}
; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
