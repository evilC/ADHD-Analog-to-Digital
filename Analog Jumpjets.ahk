
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

ADHD.config_about({name: "Analogue Jumpjets", version: 0.1, author: "evilC", link: "<a href=""http://evilc.com/proj/adhd"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(375,200)

; We need no actions, so disable warning
ADHD.config_ignore_noaction_warning()

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
/*
ADHD.config_event("option_changed", "option_changed_hook")
ADHD.config_event("program_mode_on", "program_mode_on_hook")
ADHD.config_event("program_mode_off", "program_mode_off_hook")
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("disable_timers", "disable_timers_hook")
ADHD.config_event("resolution_changed", "resolution_changed_hook")
*/
ADHD.init()
ADHD.create_gui()

; The "Main" tab is tab 1
Gui, Tab, 1
; ============================================================================================
; GUI SECTION

axis_list_ahk := Array("X","Y","Z","R","U","V")

Gui, Add, Text, x5 yp+25, Joystick number
ADHD.gui_add("DropDownList", "JoyID", "xp+120 yp-2 W50", "1|2|3|4|5|6|7|8", "1")

Gui, Add, Text, x5 yp+25, Joystick Axis
ADHD.gui_add("DropDownList", "JoyAxis", "xp+120 yp-2 W50", "1|2|3|4|5|6", "1")

Gui, Add, Text, x5 yp+25, Use Half Axis
ADHD.gui_add("DropDownList", "HalfAxis", "xp+120 yp-2 W50", "None|Start|End", "None")

Gui, Add, Text, x5 yp+25, Current axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValue Disabled, Use Half Axis

ADHD.gui_add("CheckBox", "InvertAxis", "x5 yp+30", "Invert Axis", 0)


; End GUI creation section
; ============================================================================================


ADHD.finish_startup()
;return

; The time a game needs to recognise a key down
min_delay := 50	

; The fraction of the delay time to run as a "clock"
; Should probably be at least 2
loop_time := min_delay / 2
time_on := 0
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
	
	; XBOX controller left trigger
	;GetKeyState, axis, 3JoyZ
	tmp := JoyID "Joy" axis_list_ahk[JoyAxis]
	GetKeyState, axis, % tmp
	if (InvertAxis){
		axis := 100 - axis
	}
	axis := round(axis,2)
	GuiControl,,AxisValue, % axis
	; trigger is half an axis, so ignore right trigger
	if (HalfAxis == "Start"){
		if (axis <= 50){
			; Convert from 0(max press)-50(no press) to 0-1000
			time_on := round(((50 - axis)) * 20, 2)
		} else {
			Gosub, reset_vars
			continue
		}
	} else if (HalfAxis == "End"){
		if (axis >= 50){
			; Convert from 50-100 to 0-1000
			time_on := round((axis - 50) * 20, 2)
			;soundbeep
	} else {
			Gosub, reset_vars
			continue
		}
	} else {
		; Convert from 0-100 to 0-1000
		time_on := round(axis * 10, 2)
	}
	/*
	if (axis < 50){
		; Less than 50 is considered a "release", so call reset_vars
		Gosub, reset_vars
		continue
	}
	
	; Convert from 50-100 to 0-1000
	time_on := round((axis - min_delay) * 20, 2)
	*/

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
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
