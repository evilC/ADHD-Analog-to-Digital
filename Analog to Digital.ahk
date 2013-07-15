
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

ADHD.config_about({name: "Analog to Digital", version: 1.2, author: "evilC", link: "<a href=""http://mwomercs.com/forums/topic/127120-analog-to-digital-analog-jump-jets-variable-fire-rate-gatling-gun-ac2"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(375,280)

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

Gui, Add, Text, x5 yp+25, Joystick: ID
ADHD.gui_add("DropDownList", "JoyID", "xp+60 yp-5 W50", "1|2|3|4|5|6|7|8", "1")

Gui, Add, Text, xp+60 yp+5, Axis
ADHD.gui_add("DropDownList", "JoyAxis", "xp+40 yp-5 W50", "1|2|3|4|5|6", "1")

ADHD.gui_add("CheckBox", "InvertAxis", "xp+60  yp+5", "Invert Axis", 0)

Gui, Add, Text, x5 yp+30, Use Half Axis
ADHD.gui_add("DropDownList", "HalfAxis", "xp+120 yp-5 W50", "None|Low|High", "None")

Gui, Add, Text, x5 yp+30, Fire Sequence
ADHD.gui_add("Edit", "FireSequence", "xp+120 yp-5 W50", "", "Space")
Gui, Add, Text, xp+70 yp+5, AHK key names. ie "Space" not " "

Gui, Add, Text, x5 yp+30, Fire Rate Divider
ADHD.gui_add("Edit", "FireDivider", "xp+120 yp-5 W50", "", "1")
Gui, Add, Text, xp+70 yp+5, Set to 1 to disable, not 0

ADHD.gui_add("CheckBox", "KeyUpOnFull", "x5 yp+25", "Send key up when at 100% rate", 1)

Gui, Add, Text, x5 yp+25, Current axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueIn Disabled,

Gui, Add, Text, x5 yp+25, Adjusted axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueOut Disabled,

Gui, Add, Text, x5 yp+25, Current fire rate (ms)
Gui, Add, Edit, xp+120 yp-2 W50 R1 vCurrFireRate Disabled,




; End GUI creation section
; ============================================================================================

; The time a game needs to recognise a key down
min_delay := 50	

; The fraction of the delay time to run as a "clock"
; Should probably be at least 2
loop_time := min_delay / 2
time_on := 0
button_down := 0
basetime := 0

allowed_fire := 1

ADHD.finish_startup()


Loop, {
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
	time_on := time_on / FireDivider
	GuiControl,,CurrFireRate, % round(time_on)
	
	; Check that the amount of time we need to hold the button is more than the minimum delay
	if (time_on >= min_delay){
		num_presses := time_on / min_delay
		tick_rate := 1000 / num_presses
		
		if (button_down){
			; Process UP
			; Wait for time from last press, plus min delay
			if (A_TickCount >= basetime + min_delay){
				; LEAVE basetime as the time when key was last pressed
				; Do not send key up at 100% rate
				if (KeyUpOnFull || time_on != 1000){
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
}
return

reset_vars:
	time_on := 0
	if (button_down){
		send_key_up()
	}
	
	basetime := 0
	tick_rate := 0
	return

send_key_down(){
	global fire_cur
	global fire_max
	global fire_sequence
	global button_down
	
	button_down := 1
	Send % "{" fire_sequence[fire_cur] " down}"

}
	
send_key_up(){
	global fire_cur
	global fire_max
	global fire_sequence
	global button_down

	button_down := 0
	Send % "{" fire_sequence[fire_cur] " up}"
	
	fire_cur := fire_cur + 1
	if (fire_cur > fire_max){
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
	global fire_max
	
	fire_max := 0
	StringSplit, tmp, FireSequence, `,
	fire_sequence := []
	Loop, % tmp0
	{
		fire_max := fire_max + 1
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
