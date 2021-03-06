# c64-autofire
Autofire Adapter for the Commodore 64 Control Ports

# Features
Dual Port, configurable Autofire Adapter for the C64 with any digital Joystick

- No external power supply; powered by the Commodore 64
- Tap on/ Tap off function
- no potis, no switches, 1 button control
- configurable for 4 different autofire speeds; 10Hz, 3,8Hz, 1,9Hz, 1,2Hz
- highly stable autofire frequency, due to hardware timers
- Port A and Port B fully independent
- fire button overrides autofire (f.e. load weapon *KATAKIS*)
- port functions fully retained; mouse or other appliances can be used without restrictions
- autofire speed for each port is retained for next power-up (saved to eeprom)
- autofire off on computer power-up (no more glitches due to forgotten Autofire switch ;-) )

# Installation
Schematics can be found in the respective folder. I added the PCB layout from KiCAD as well as the GERBER data. I am not proficient at this, so the GERBER data ma not be good enough for PCB manufacturing. Please check for yourself. Maybe, somebody can help.
Parts list:
- PCB
- Attiny45
- 2x BZX85 Diodes 5,6V or higher
- 2x 15nF ceramic capacitors
- 2x female DB9 connector
- 2x male DB9 connector

Housing:
I have put some FreeCAD files and STLs in the respective folder. Use at will, or make your own.

Flashing the Attiny:
- compatible flash programmer needed (f.e. STK500, TL866, Arduino like programmes,....)
- WARNING: flashing the Attiny will only work once with ISP programmers, since the Fuses are written to disable the Reset pin (PB5).
  For future programming/ reuse a high voltage programmer is needed.
- to compile the *.asm file, install AVRA with "sudo apt install avra"
- to flash using an STK500 or similar programmer, install AVRDUDE: "sudo apt install avrdude"

There are in general two options for programming:
1) - Use the Makefile to produce your own binaries and flash
Fix your directories and programmer in the Makefile.
To flash the chip and write the fuses, connect your programmer incl. Attiny and run:
sudo make install

2) - Use the HEX binaries included
You can flash the chip without compiling the assembly to binary by using the *.hex file provided.
To use AVR Dude in the directory with the hex file:
sudo avrdude -p t45 -P (your interface) -c (your programmer) -B 1024 -U flash:w:C64_autofire.hex

Then you have to burn the fuses with:

sudo $(AVRDUDE) -p t45 -P (your interface) -c (your programmer) -B 1024 -U lfuse:w:0xe2:m -U hfuse:w:0x57:m

For "your interface" choose the interface your programmer is connected to. F.e. /dev/ttyACM0 or COM3.
See detailed instructions for using AVRDUDE under https://linux.die.net/man/1/avrdude.

WARNING: check your circuit properly! Connection errors and short circuits could destroy your C64! No warranty is given for any usage
of this Autofire adapter. Do not try it, if you are not knowing what you are doing. Usage at your own risk!

# Usage
Plug in the autofire adapter carfully into the C64 Control Ports and switch on the computer.

Configuration of autofire speed:
- hold down config button for the respective port and tap the joystick button 1-4 times depending on the autofire speed you want.
1x -> very slow ... 4x -> very fast; after 1 sec speed is saved for that port
- activate autofire for the respective port by tapping the config button once
- tap again for deactivation

HAVE FUN



