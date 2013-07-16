
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

ADHD.config_about({name: "Analog to Digital", version: 2.2, author: "evilC", link: "<a href=""http://mwomercs.com/forums/topic/127120-analog-to-digital-analog-jump-jets-variable-fire-rate-gatling-gun-ac2"">Homepage</a>"})
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
ADHD.gui_add("DropDownList", "JoyID", "xp+80 yp-5 W50", "1|2|3|4|5|6|7|8", "1")
JoyID_TT := "The ID (Order in Windows Game Controllers?) of your Joystick"

Gui, Add, Text, xp+60 ys+20, Axis
ADHD.gui_add("DropDownList", "JoyAxis", "xp+80 yp-5 W50", "1|2|3|4|5|6", "1")
JoyAxis_TT := "The Axis on that stick that you wish to use"

ADHD.gui_add("CheckBox", "InvertAxis", "xp+60  yp+5", "Invert Axis", 0)
InvertAxis_TT := "Inverts the input axis.`nNot intended to be used with ""Use Half Axis"""

Gui, Add, Text, x15 ys+50, Use Half Axis
ADHD.gui_add("DropDownList", "HalfAxis", "xp80 yp-5 W50", "None|Low|High", "None")
HalfAxis_TT := "Use only half the axis - eg for XBOX left trigger, use ""High"""

Gui, Add, Text, xp+60 ys+50, % "Deadzone (%)"
ADHD.gui_add("Edit", "DeadZone", "xp+80 yp-5 W50", "", 0)
DeadZone_TT := "Ignore axis values below this amount"

Gui, Add, GroupBox, x5 yp+35 R1 W365 R1.2 section, Output Configuration
Gui, Add, Text, x15 ys+20, Fire Sequence
ADHD.gui_add("Edit", "FireSequence", "xp+120 yp-5 W80", "", "Space")
FireSequence_TT := "One key or a sequence of keys separated by commas, eg 1,2,3,4`nAHK key names. ie ""Space"" not "" """

Gui, Add, GroupBox, x5 yp+30 R1.4 W365 section, Fire Rate (in ms, lower number is faster fire!)
Gui, Add, Text, x15 ys+20, Min (Fastest Rate!)
ADHD.gui_add("Edit", "FireRateMin", "xp+100 yp-2 W50", "", 0)
FireRateMin_TT := "Minimum Fire Rate (in ms) Default is 0"

Gui, Add, Text, xp+70 ys+20, Max (Slowest Rate!)
ADHD.gui_add("Edit", "FireRateMax", "xp+100 yp-2 W50", "", 1000)
FireRateMax_TT := "Maximum Fire Rate (in ms) Default is 1000"

/*
Gui, Add, Text, xp+70 ys+20, Bands
ADHD.gui_add("Edit", "FireRateBands", "xp+40 yp-2 W50", "", "0")
FireRateBands_TT := "Split the axis up into a number of sections.`neg setting 10 would split the output into 10 blocks - 10,20,30% etc.`nUse 0 to turn off."
*/

Gui, Add, GroupBox, x5 yp+35 R3.5 W365 section, Debugging
Gui, Add, Text, x15 ys+15, Current axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueIn ReadOnly,
AxisValueIn_TT := "Raw input value of the axis.`nIf you have Joystick ID and axis set correctly,`nmoving the axis should change the numbers here"

Gui, Add, Text, xp+60 ys+15, Adjusted axis value
Gui, Add, Edit, xp+100 yp-2 W50 R1 vAxisValueOut ReadOnly,
AxisValueOut_TT := "Input value adjusted according to options`nShould be 0 at center, 100 at full deflection"

Gui, Add, Text, x15 yp+25, Current fire rate (ms)
Gui, Add, Edit, xp+120 yp-2 W50 R1 vCurrFireRate ReadOnly,
CurrFireRate_TT := "The fire rate the macro currently wants to fire at"

Gui, Add, Text, xp+60 yp+2, Fire State: 
Gui, Add, Edit, xp+50 yp-3 W80 Readonly vFireState,
FireState_TT := "Whether button state is down or up"

Gui, Add, CheckBox, x15 yp+25 vPlayDebugBeeps gdebug_beep_changed, Play debug beeps
PlayDebugBeeps_TT := "Warning! beeps take 10ms! Script stops running while beeps play..."


; End GUI creation section
; ============================================================================================

min_delay := 50	
loop_rate := min_delay / 5

allowed_fire := 1
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
	
	if (axis){
		; Adjust tick rate to fall between specified maximums and minimums
		tick_rate := round(FireRateMax - ((FireRateMax - FireRateMin) * (axis / 100)))
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
		; Let key ups happen if tick_rate off, not at max rate, or if firing a sequence
		if (tick_rate == -1 || tick_rate > min_delay || fire_seq_count > 1){
			;button_down := 0
			if (allowed_fire){
				send_key_up()
			}
			if (PlayDebugBeeps){
				soundbeep, 750, 20
			}
		}
	}
	
	set_fire_state(button_down)
	
	; Process any waiting key down events
	;tooltip, % "tick_rate: " tick_rate " last_tick: " last_tick " loop_time: " loop_time
	; Conditions for sending key down:
	; We are not at max rate (Or we are sending a sequence of keys)
	; Button is not already down (could be at 100% and key ups not getting sent, so dont send key downs
	; tick_rate is not disabled
	; it is time for another tick
	if (!button_down && tick_rate != -1 && (last_tick + tick_rate <= loop_time)){
		; Let key downs happen if not at max rate or firing a sequence
		if (tick_rate > min_delay || fire_seq_count > 1){
			last_tick := loop_time
			;button_down := 1
			if (allowed_fire){
				send_key_down()
			}
			if (PlayDebugBeeps){
				soundbeep, 500, 20
			}
		}
	}
	
	set_fire_state(button_down)
	
	Sleep, % loop_rate
}
return

; Conform the input value from an axis to a range between 0 and 100
; Handles invert, half axis usage (eg xbox left trigger) etc
conform_axis(){
	global axis_list_ahk
	global JoyID
	global JoyAxis
	global InvertAxis
	global HalfAxis
	global DeadZone
	
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
	; axis is now conformed to 0-100

	/*
	if (FireRateBands != 0 && FireRateBands != ""){
		bandsize := 100 / FireRateBands
		axis := ceil(axis / bandsize) * bandsize		
	}
	*/
	
	if (DeadZone != 0 && DeadZone != ""){
		axis := (100 / (100 - DeadZone)) * (axis - DeadZone)
		if (axis < 0){
			axis := 0
		}
	}
	GuiControl,,AxisValueOut, % round(axis,1)
	
	;axis := round(axis,1)
	return axis
}

set_fire_state(state){
	global tick_rate
	global min_delay
	
	if ((tick_rate != -1) && tick_rate <= min_delay){
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

reset_vars:
	if (button_down){
		send_key_up()
	}
	tick_rate := 0
	last_tick := 0
	return
	
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
	
	set_fire_state(0)	; init the output display
	
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
	Gosub, reset_vars
	
	
}
; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
