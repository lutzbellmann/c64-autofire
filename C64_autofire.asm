;  C64 Autofire Adapter; Source Code V0.1

.include "tn45def.inc"

.dseg			; Data Segment
speedA: .byte 1		; Autofire Speed Channel A
speedB: .byte 1		; Autofire Speed Channel B
sp_table: .byte 4	; Speed Table 8, 18, 36

.cseg
.org	0x0000

rjmp reset		;Reset handler
reti;rjmp INT0		;IRQ0 handler
rjmp pc_int0		;Pin change handler
reti;rjmp TIMER1_COMPA	;Timer1 compare match 1A
reti;rjmp TIMER1_OVF	;Timer1 overflow handler
reti;rjmp TIMER0_OVF	;Timer0 overflow handler
reti;rjmp EE_RDY	;EEPROM Ready handler
reti;rjmp ANA_COMP	;Analog Comparator handler
reti;rjmp ADC		;ADC Conversion Handler
reti;rjmp TIMER1_COMPB	;Timer1 compare match 1B
reti;rjmp TIMER0_COMPA	;Timer0 compare match 0A
reti;rjmp TIMER0_COMPB	;Timer0 compare match 0B
reti;rjmp WDT		;WatchDog handler
reti;rjmp USI_START 	;USI Start handler
reti;rjmp USI_OVF	;USI Overflow handler

reset:
ldi r16, high(RAMEND)
out SPH, r16
ldi r16, low(RAMEND)	; Stack Allocation
out SPL, r16
clr r16			; clear registers
clr r20
clr r21
ldi XL, low(sp_table)	; X Pointer to Speed Table
ldi XH, high(sp_table)
ldi r16, 52		; save speed table to data segment
st X+, r16
ldi r16, 32		; save speed table to data segment
st X+, r16
ldi r16, 16
st X+, r16
ldi r16, 6
st X+, r16
ldi r16,0b00000011
out ddrb, r16		; all pins to input, except fire (PB0/1)
ldi r16, 0b00111111	
out portb, r16		; all inputs pull-up, except Joyport A/B
ldi r16, 0b10000000
ldi r17, 0b00001000
out CLKPR, r16		; enable clock write
out CLKPR, r17		; Clock divider 256-->31,25kHz
in r16, PCMSK
sbr r16, (1<<PCINT2)|(1<<PCINT5)
out PCMSK, r16		; Mask PB2 and PB5 as Interrupt PCINT
in r16, GIMSK
sbr r16, (1<<PCIE)
out GIMSK, r16		; PCINT Interrupt enable
rcall eeprom_read	; read speed data
sei			; enable global interrupts

main:
sbrs r20, PB0		; ON command for Autofire A?
rcall deconfigure_T0	; if not, deconfigure Autofire A
sbrc r20, PB0
rcall configure_T0	; if yes, configure Autofire A
sbrs r20, PB1		; ON command for Autofire B?
rcall deconfigure_T1	; if not, deconfigure Autofire B
sbrc r20, PB1
rcall configure_T1	; if yes, configure Autofire B
sbis pinb, PB4		; Joystick A Fire pressed?
rcall fireA		; if yes, jump to Fire A Override
sbic pinb, PB4		; Joystick A Fire pressed?
rcall fireAn		; if not, jump to Fire An
sbis pinb, PB3		; Joystick B Fire pressed?
rcall fireB		; if yes, jump to Fire B Override
sbic pinb, PB3		; Joystick B Fire pressed?
rcall fireBn		; if not , jump to Fire Bn
rcall chkconf		; check configuration
rjmp main		; loop back

chkconf:
cli			; turn interrupts off
eor r20, r21		; toggle activation bits in r20 if set in r21
clr r21			; clear toggle commands
sei			; turn interrupts on
ret
 
configure_T0:
sbis pinb, PB4		; fire currently being pressed?
ret			; if yes, do not activate
in r16, TCCR0A
sbrc r16, COM0A0	; is autofire active?
ret			; if yes, do not activate again
sbi portb, PB0		; FireA off
clr r16
out TCNT0, r16		; set Timer 0 -> 0
ldi r16, 0b01000010
out TCCR0A, r16		; Timer0, CTC, OC0A toggle
ldi r16, 0b00000100
out TCCR0B, r16		; Timer0, Prescaler=256
lds r16, speedA		; get configured speed
out OCR0A, r16
ret

deconfigure_T0:
in r16, TCCR0A
sbrs r16, COM0A0	; is autofire active?
ret			; if not, do not deactivate again
clr r16
out TCCR0A, r16		; clear Timer configuration
sbi portb, PB0		; Fire A line to high (unpressed)
ret

configure_T1:
sbis pinb, PB3		; fire currently being pressed?
ret			; if yes, do not activate
in r16, TCCR1
sbrc r16, COM1A0	; is autofire active?
ret			; if yes, do not activate again
sbi portb, PB1		; FireA off
clr r16
out TCNT1, r16		; set Timer1 -> 0
ldi r16, 0b10011001
out TCCR1, r16		; Timer1, CTC1, OC1A toggle, Prescaler 256
lds r16, speedB		; get speed from SRAM		
out OCR1A, r16		; set autofire frequency
out OCR1C, r16		
ret

deconfigure_T1:
in r16, TCCR1
sbrs r16, COM1A0	; is autofire active?
ret			; if not, do not deactivate again
clr r16
out TCCR1, r16		; clear Timer configuration
sbi portb, PB1		; Fire B line to high (unpressed)
ret

fireA:
rcall deconfigure_T0	; switch off autofire
cbi PORTB, PB0		; pull JoyA Input to GND
sbrc r20, PB0		; are we in autofire mode?
sbr r20, (1<<PB3)	; if yes, indicate reenable auto fire
sbis pinb, pb2		; config button held down?
rcall select_A		; if yes, switch to config mode
ret

fireAn:
sbi portb, PB0		; Fire A line high
sbrc r20, PB3		; was autofire enabled, when fire was pressed?
rcall configure_T0	; if yes, enable autofire
cbr r20, (1<<PB3)	; autofire history bit
ret

fireB:
rcall deconfigure_T1	; switch off autofire
cbi PORTB, PB1		; pull JoyB Input to GND
sbrc r20, PB1		; are we in autofire mode?
sbr r20, (1<<PB4)	; if yes, indicate reenable auto fire
sbis pinb, pb5		; config button held down?
rcall select_B		; if yes, switch to config mode
ret

fireBn:
sbi portb, PB1		; Fire B line high
sbrc r20, PB4		; was autofire enabled, when fire was pressed?
rcall configure_T1	; if yes, enable autofire
cbr r20, (1<<PB4)	; autofire history bit
ret

select_A:
cli			; disable interrupts
ldi r17, 4
ldi XL, low(sp_table)	; X Pointer to Speed Table
ldi XH, high(sp_table)
sbi portb, pb0		; Joy A high
loop1:
rcall entprellen	; debounce joybutton
ld r16, X+		; get speed
sts speedA, r16		; store speed
dec r17			; dec counter
brne loop2		; counter 0?
ldi r17, 4		; counter to 3 again
ldi XL, low(sp_table)	; X Pointer to Speed Table
ldi XH, high(sp_table)
loop2:
sbis pinb, PB4		; Joystick Button still pressed?
rjmp loop2		; if yes, wait
rcall entprellen	; debounce joybutton
rcall onesec		; set 1sec timer
loop3:
sbis pinb, PB4		; Joystick pressed again?
rjmp loop1		; set next speed in table
in r16, TCNT0		; one second waiting time over?
cpi r16, 0
brne loop3		; if not chekc button again
clr r16
out TCCR0A, r16		; clear timer configuration
out TCCR0B, r16
cbr r20, (1<<PB0)|(1<<PB3); do not start Autofire 
cbr r21, (1<<PB0)	; after configuration
rcall eeprom_write	; save new speed to eeprom
sei			; enable interrupts
ret			; setup complete

select_B:
cli			; disable interrupts
ldi r17, 4
ldi XL, low(sp_table)	; X Pointer to Speed Table
ldi XH, high(sp_table)
sbi portb, pb1		; Joy B high
loop6:
rcall entprellenB	; debounce joybutton
ld r16, X+		; get speed
sts speedB, r16		; store speed
dec r17			; dec counter
brne loop7		; counter 0?
ldi r17, 4		; counter to 4 again
ldi XL, low(sp_table)	; X Pointer to Speed Table
ldi XH, high(sp_table)
loop7:
sbis pinb, PB3		; Joystick Button still pressed?
rjmp loop7		; if yes, wait
rcall entprellenB	; debounce joybutton
rcall onesecB		; set 1sec timer
loop8:
sbis pinb, PB3		; Joystick pressed again?
rjmp loop6		; set next speed in table
in r16, TCNT1		; one second waiting time over?
cpi r16, 0
brne loop8		; if not chekc button again
clr r16
out TCCR1, r16		; clear timer configuration
cbr r20, (1<<PB1)|(1<<PB4); do not start Autofire 
cbr r21, (1<<PB1)	; after configuration
rcall eeprom_write	; save new speed to eeprom
sei			; enable interrupts
ret

onesec:
ldi r16, 0b00000010
out TCCR0A, r16		; CTC Mode Timer0
ldi r16, 0b00000100
out TCCR0B, r16		; Timer0, Prescaler=256
ldi r16, 57 
out OCR0A, r16		; 1sec
ldi r16, 1
out TCNT0, r16		; clear timer
ret

onesecB:
ldi r16, 0b10001001
out TCCR1, r16		; CTC1, prescaler 256
ldi r16, 57 
out OCR1C, r16		; 1sec
ldi r16, 1
out TCNT1, r16		; clear timer
ret

eeprom_write:
clr r17
clr r18
lds r19, speedA 
loop4:
sbic EECR, EEPE		; wait for previous write complete
rjmp loop4
ldi r16, (0<<EEPM1)|(0<<EEPM0); configure EEPROM
out EECR, r16
out EEARH, r17		; set EEPROM address
out EEARL, r18
out EEDR, r19		; copy data to data register
sbi EECR, EEMPE		; pre enable EEPROM write
sbi EECR, EEPE		; write data
lds r19, speedB		; get next speed
inc r18			; increase Lowbyte EEPROM address
cpi r18, 2		; 2 bytes written?
brne loop4		; if not, write next byte
ret			; else return

eeprom_read:
clr r17
clr r18
loop5:
sbic EECR, EEPE
rjmp loop5
out EEARH, r17
out EEARL, r18
sbi EECR, EERE
in r16, EEDR
sts speedA, r16
inc r18
out EEARH, r17
out EEARL, r18
sbi EECR, EERE
in r16, EEDR
sts speedB, r16
ret

entprellen:
ldi r16, 0b00000010
out TCCR0A, r16		; CTC Mode Timer0
ldi r16, 0b00000100
out TCCR0B, r16		; Timer0, Prescaler=256
ldi r16, 7 
out OCR0A, r16		; ca. 50 msec
ldi r16, 1
out TCNT0, r16		; clear timer
loop:
in r16, TCNT0
cpi r16, 0
brne loop		; wait until Timer0 is reset
clr r16
out TCCR0A, r16		; clear timer configuration
out TCCR0B, r16
ret	

entprellenB:
ldi r16, 0b10001001
out TCCR1, r16		; CTC1, prescaler 256
ldi r16, 7 
out OCR1C, r16		; ca. 50 msec
ldi r16, 1
out TCNT1, r16		; clear timer
loopB:
in r16, TCNT1
cpi r16, 0
brne loopB		; wait until Timer1 is reset
clr r16
out TCCR1, r16
ret	

pc_int0:
sbis PINB, PB2
rcall entprellen
sbis PINB, PB5
rcall entprellenB
sbis PINB, PB2		; config button A pressed?
sbr r21, (1<<PB0)	; if yes, mark PortA Config pressed
sbis PINB, PB5		; config button B pressed?
sbr r21, (1<<PB1)	; if yes, mark PortB Config pressed
reti
