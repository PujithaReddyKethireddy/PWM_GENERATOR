# PWM_GENERATOR
PWM Generator using FPGA | Basys 3

This project demonstrates a Pulse Width Modulation (PWM) Generator designed using VHDL and implemented on a Basys 3 FPGA board. Users can input a desired duty cycle through a 4x4 matrix keypad, and the value is instantly displayed on a 7-segment display.

Tools Used

-Xilinx Vivado – Synthesis, Implementation

-ModelSim – Simulation and Verification

-VHDL – Hardware Description Language

-Basys 3 FPGA – Target Board

-4x4 Keypad – Input Device

-7-Segment Display – Output Display



Features
 
-Selectable duty cycle via keypad (0% to 100%)

-Real-time display on 7-segment LED

-PWM output can be used to drive external circuits (like motors or LEDs)

-Clean modular VHDL code



How It Works

-The keypad scanning module detects which key is pressed.

-The pressed key corresponds to a duty cycle percentage.

-This value is passed to the PWM generator, which modulates the signal accordingly.

-The selected value is displayed on the 7-segment display for user feedback.


Skills Applied
Digital Design & FSM,
Keypad Interfacing,
PWM Logic,
Display Interfacing,
RTL Design in VHDL
