MCU=attiny45
AVRDUDEMCU=t45
AVRA=/usr/bin/avra
AVRDUDE=/usr/bin/avrdude
DEVICE=/dev/ttyACM0
PROGRAMMER=stk500

TARGET=C64_autofire

all :
	$(AVRA) $(TARGET).asm
	rm -f $(TARGET)

install : all
	sudo $(AVRDUDE) -p $(AVRDUDEMCU) -P $(DEVICE) -c $(PROGRAMMER) -B 1024 -U flash:w:$(TARGET).hex
	sudo $(AVRDUDE) -p $(AVRDUDEMCU) -P $(DEVICE) -c $(PROGRAMMER) -B 1024 -U lfuse:w:0xe2:m -U hfuse:w:0x57:m

fuse :
	sudo $(AVRDUDE) -p $(AVRDUDEMCU) -P $(DEVICE) -c $(PROGRAMMER) -B 1024 -U lfuse:w:0xe2:m -U hfuse:w:0x57:m

clean :
	rm -f *.hex *.obj *.o *.cof

erase :
	sudo $(AVRDUDE) -p $(AVRDUDEMCU) -P $(DEVICE) -c $(PROGRAMMER) -e -B 1024

r_eprom :
	sudo $(AVRDUDE) -p $(AVRDUDEMCU) -P $(DEVICE) -c $(PROGRAMMER) -B 1024 -U eeprom:r:main.eep:i

w_eprom :
	sudo $(AVRDUDE) -p $(AVRDUDEMCU) -P $(DEVICE) -c $(PROGRAMMER) -B 1024 -U eeprom:w:main.eep:i
