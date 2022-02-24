; FreqEFM8.asm:  Shows how to use timer 0 to measure the frequency of a pulse waveform
; in the range 0 to 65535Hz applied to pin T0 (P0.0).

$NOLIST
$MODEFM8LB1
$LIST


org 0000H
   ljmp MyProgram

; These 'equ' must match the hardware wiring
; They are used by 'LCD_4bit.inc'
LCD_RS equ P2.0
LCD_RW equ P1.7
LCD_E  equ P1.6
LCD_D4 equ P1.1
LCD_D5 equ P1.0
LCD_D6 equ P0.7
LCD_D7 equ P0.6

ResistorB equ 10000
ResistorA equ 10000 
$NOLIST
$include(LCD_4bit.inc)
$LIST

; These register definitions needed for arithmetic
DSEG at 30H
x:   ds 4
y:   ds 4
z:	 ds 4
bcd: ds 5

BSEG

mf: dbit 1

$NOLIST
$include(math32.inc)
$LIST

CSEG

Left_blank mac
	mov a, %0
	anl a, #0xf0
	swap a
	jz Left_blank_%M_a
	ljmp %1
Left_blank_%M_a:
	Display_char(#' ')
	mov a, %0
	anl a, #0x0f
	jz Left_blank_%M_b
	ljmp %1
Left_blank_%M_b:
	Display_char(#' ')
endmac


Msg1:  db 'Capacitance(nF):', 0

; This 'wait' must be as precise as possible. Sadly the 24.5MHz clock in the EFM8LB1 has an accuracy of just 2%.
Wait_one_second:	
    ;For a 24.5MHz clock one machine cycle takes 1/24.5MHz=40.81633ns
    mov R2, #198 ; Calibrate using this number to account for overhead delays
X3: mov R1, #245
X2: mov R0, #167
X1: djnz R0, X1 ; 3 machine cycles -> 3*40.81633ns*167=20.44898us (see table 10.2 in reference manual)
    djnz R1, X2 ; 20.44898us*245=5.01ms
    djnz R2, X3 ; 5.01ms*198=0.991s + overhead
    ret

; Dumps the 5-digit packed BCD number in R2-R1-R0 into the LCD
DisplayBCD:
	; 5th digit:
    mov a, R2
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 4th digit:
    mov a, R1
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 3rd digit:
    mov a, R1
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 2nd digit:
    mov a, R0
    swap a
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
	; 1st digit:
    mov a, R0
    anl a, #0FH
    orl a, #'0' ; convert to ASCII
	lcall ?WriteData
    
    ret
    
; Sends 10-digit BCD number in bcd to the LCD
Display_10_digit_BCD:
	Set_Cursor(2, 7)
	Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	; Replace all the zeros to the left with blanks
	Set_Cursor(2, 7)
	Left_blank(bcd+4, skip_blank)
	Left_blank(bcd+3, skip_blank)
	Left_blank(bcd+2, skip_blank)
	Left_blank(bcd+1, skip_blank)
	mov a, bcd+0
	anl a, #0f0h
	swap a
	jnz skip_blank
	Display_char(#' ')
skip_blank:
	ret
    
; We can display a number any way we want.  In this case with
; four decimal places.
Display_formated_BCD:
	Set_Cursor(2, 7)
	Display_char(#' ')
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_char(#'.')
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	ret
    
MyProgram:
	mov sp, #0x7F ; Initialize the stack pointer
    
    ; DISABLE WDT: provide Watchdog disable keys
	mov	WDTCN,#0xDE ; First key
	mov	WDTCN,#0xAD ; Second key

    ; Enable crossbar and weak pull-ups
	mov	XBR0,#0x00
	mov	XBR1,#0x10 ; Enable T0 on P0.0.  T0 is the external clock input to Timer/Counter 0
	mov	XBR2,#0x40

	; Switch clock to 24.5 MHz
	mov	CLKSEL, #0x00 ; 
	mov	CLKSEL, #0x00 ; Second write to CLKSEL is required according to the user manual (page 77)
	
	; Wait for the 24.5 MHz oscillator to stabilze by checking bit DIVRDY in CLKSEL
waitclockstable:
	mov a, CLKSEL
	jnb acc.7, waitclockstable
	
	;Initializes timer/counter 0 as a 16-bit counter
    clr TR0 ; Stop timer 0
    mov a, TMOD
    anl a, #0b_1111_0000 ; Clear the bits of timer/counter 0
    orl a, #0b_0000_0101 ; Sets the bits of timer/counter 0 for a 16-bit counter
    mov TMOD, a

	; Configure LCD and display initial message
    lcall LCD_4BIT
	Set_Cursor(1, 1)
    Send_Constant_String(#Msg1)
    
    ; Moving the resistor value into x and multiplying by 2
    mov x+0, #low(ResistorB)
	mov x+1, #high(ResistorB)
	mov x+2, #0
	mov x+3, #0
	mov y+0, #2
	mov y+1, #0
	mov y+2, #0
	mov y+3, #0
	lcall mul32
	; The result goes into x+0,x+1,x+2,x+3. To find the denominator of our frequency equation, 2*Rb must be added to Ra
	mov y+0, #low(ResistorA)
	mov y+1, #high(ResistorA)
	mov y+2, #0
	mov y+3, #0
	lcall add32
	; 1.44/(Ra+2*Rb) will be what we multiply 1/frequency by
	mov y+0, x+0
	mov y+1, x+1
	mov y+2, x+2
	mov y+3, x+3
	mov x+0, #00h
	mov x+1, #0A8h
	mov x+2, #0D4h
	mov x+3, #055h
	lcall div32
	; Move the result of all these operations into z which will just hold the values
	mov z+0, x+0
	mov z+1, x+1
	mov z+2, x+2
	mov z+3, x+3 
	
Forever:

    ; Measure the frequency applied to pin T0 (T0 is routed to pin P0.0 using the 'crossbar')
    clr TR0 ; Stop counter 0
    mov TL0, #0
    mov TH0, #0
    setb TR0 ; Start counter 0
    lcall Wait_one_second
    clr TR0 ; Stop counter 0, TH0-TL0 has the frequency
    ; Move the multiplier into x so it can be divided by the frequency
    mov x+0, z+0
    mov x+1, z+1
    mov x+2, z+2
    mov x+3, z+3
    mov y+0, TL0
    mov y+1, TH0
    mov y+2, #0
    mov y+3, #0
    lcall div32
    ; Multiply the solution by 100 so we can divide by a "fudge factor" because for some reason the frequency
    ; that the board measures isn't quite correct
    mov y+0, #low(10000)
    mov y+1, #high(10000)
    mov y+2, #0
    mov y+3, #0
    lcall mul32
    ; the fudge factor is 1/0.9331
    mov y+0, #low(9331)
    mov y+1, #high(9331)
    mov y+2, #0
    mov y+2, #0
    lcall div32
    ; Multiply by 1000 so we can get the decimal places
    mov y+0, #low(10000)
    mov y+1, #high(10000)
    mov y+2, #0
    mov y+3, #0
    lcall mul32
    lcall hex2bcd
    lcall Display_formated_BCD 

	ljmp Forever ; Repeat!
	
END
