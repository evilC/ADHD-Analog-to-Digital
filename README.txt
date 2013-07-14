ADHD-Analog-to-Digital
======================

An experiment in analog to digital - using an axis to spam a key at varying rates
It is an attempt to solve the problem of how you "strobe" a key at a dynamically altering rate when the game only recognises presses of a certain duration.


Installation:
Either
You either need Autohotkey and ADHD installed and run the ahk file
Or
Run the EXE file

Usage:
Joystick ID sets the ID of your physical stick
Joystick Axis sets the axis number of the axis you wish to use
Use Half Axis allows you to use only half the axis (ie from the mid-point to either end)
Invert Axis allows you to invert the input (Probably useless in combination with Use Half Axis)

Settings for XBOX controller analogue triggers:
Axis: 3
Use Half Axis: Low for Right trigger, High for Left trigger

Current Axis Value: Shows you the input value of the selected axis. Usefel for finding the right setting
Adjusted Axis value: Shows the amount (in percent) that it is trying to jump jet. Useful for debugging eg Use Half Axis and Invert Axis settings
