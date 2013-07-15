ADHD-Analog-to-Digital
======================

An experiment in analog to digital - using a joystick axis to spam a key at varying rates.
Normally an easy thing to code, but compounded when a game only recognises presses of a certain minimum duration (eg 50ms between down and up)


Installation:
=============

Either
You either need Autohotkey and ADHD installed and run the ahk file (You may need to tweak the include statement at the end of the script)
Or
Run the EXE file

Usage:
======

Joystick ID - sets the ID of your physical stick

Joystick Axis - sets the axis number of the axis you wish to use

Use Half Axis - allows you to use only half the axis (ie from the mid-point to either end)

Invert Axis - allows you to invert the input (Probably useless in combination with Use Half Axis)

Fire Sequence - a comma separated list of AHK key names to hit
eg for just space, enter "Space", To hit 3,4,5,6 in sequence, enter "3,4,5,6" (Without the quotes)

Fire Rate Divider - A divider to allow you to adjust max speed.
eg to fire at a max of once per 250ms, set it to 2.5 (1000*2.5 = 250)

Useful readouts:
================

Current Axis Value - Shows you the input value of the selected axis. Usefel for finding the right setting for Joystick ID / Axis

Adjusted Axis value - Shows the amount (in percent) that it is trying to jump jet. Useful for debugging eg Use Half Axis and Invert Axis settings

Current Fire Rate - The current rate at which the macro will strobe the key (higher is faster). Useful for finding desired values Fire Rate Divider

Note:
Whilst there are no bindings in this ADHD macro, the "Limit Application" option in the bindings tab takes effect!


Settings for XBOX controller analogue trigger:
==============================================
Axis: 3
Use Half Axis: Low for Right trigger, High for Left trigger

Settings for Jumpjets:
======================
Divider: 1
Fire Sequence: Space

Settings for 250 ms fire rate (MWO 4xAC2):
==========================================
Divider: 2.5
Fire Sequence: 3,4,5,6



