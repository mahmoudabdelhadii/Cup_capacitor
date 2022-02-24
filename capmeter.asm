; FreqEFM8.asm:  Shows how to use timer 0 to measure the frequency of a pulse waveform
; in the range 0 to 65535Hz applied to pin T0 (P0.0).

$NOLIST
$MODEFM8LB1
$LIST

org 0x0000
   ljmp MyProgram
   
 ; Timer/Counter 0 overflow interrupt vector  
org 0x000B
    inc R7 ; Keep count of overflow in some available register not used anywhere else
    reti

DSEG at 30H
x:   ds 4
y:   ds 4
z:   ds 4
bcd: ds 5


BSEG
mf: dbit 1

; These 'equ' must match the hardware wiring
; They are used by 'LCD_4bit.inc'
LCD_RS equ P2.0
LCD_RW equ P1.7
LCD_E  equ P1.6
LCD_D4 equ P1.1
LCD_D5 equ P1.0
LCD_D6 equ P0.7
LCD_D7 equ P0.6
$NOLIST
$include(LCD_4bit.inc)
$include(math32.inc)
$LIST

ResistorB equ 10 ;in Kilo ohms
ResistorA equ 10 ;in Kilo ohms

CSEG

Msg1:  db 'Capacitance:', 0
Msg2:  db 'nF', 0

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



; This 'wait' must be as precise as possible. Sadly the 24.5MHz clock in the EFM8LB1 has an accuracy of just 2%.
Wait_one_second:	
    ;For a 24.5MHz clock one machine cycle takes 1/24.5MHz=40.81633ns
   
   
    mov R2, #203
X3: mov R1, #245
X2: mov R0, #167
X1: djnz R0, X1 ; 3 machine cycles -> 3*40.81633ns*167=20.44898us (see table 10.2 in reference manual)
    djnz R1, X2 ; 20.44898us*245=5.01ms
    djnz R2, X3 ; 5.01ms*198=0.991s + overhead
    ret
    


;Converts the hex number in TH0-TL0 to packed BCD in R2-R1-R0
Display_8_digit_BCD:
	Set_Cursor(2, 1)
	Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_char(#'.')
	Display_BCD(bcd+1)

	Display_BCD(bcd+0)
	; Replace all the zeros to the left with blanks
	Set_Cursor(2, 1)
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

Display_10_digit_BCD:
	Set_Cursor(1, 1)
	Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	
	Display_BCD(bcd+1)

	Display_BCD(bcd+0)
	; Replace all the zeros to the left with blanks
	Set_Cursor(1, 1)
	Left_blank(bcd+4, skip_blank2)
	Left_blank(bcd+3, skip_blank2)
	Left_blank(bcd+2, skip_blank2)
	Left_blank(bcd+1, skip_blank2)
	mov a, bcd+0
	anl a, #0f0h
	swap a
	jnz skip_blank2
	Display_char(#' ')
skip_blank2:
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
    
	
Forever:

    ; Measure the frequency applied to pin T0 (T0 is routed to pin P0.0 using the 'crossbar')
    clr TR0 ; Stop counter 0
    mov TL0, #0
    mov TH0, #0
    mov R7, #0
    clr TF0 ; Clear overflow flag
    setb ET0  ; Enable timer 0 interrupt
    setb EA ; Enable global interrupts
    setb TR0 ; Start counter 0
    lcall Wait_one_second
    clr TR0 ; Stop counter 0, R7-TH0-TL0 has the frequency

    mov x+0,TL0
    mov x+1,TH0         ; freq in x
    mov x+2,R7
    mov x+3,#0
	
	lcall hex2bcd 
	lcall Display_10_digit_BCD

    
    Load_x(ResistorB) ;Rb = 2*5000
   
    Load_y(2)    ;multiply by 2

    lcall mul32 

    Load_y(ResistorA)  ;Ra = 3000
    

    lcall add32     ;(Ra+2Rb) in x


    mov y+0,x+0
    mov y+1,x+1 
    mov y+2,x+2         ;(Ra+2Rb) in y
    mov y+3,x+3



    mov x+0,TL0
    mov x+1,TH0         ; freq in x
    mov x+2,R7
    mov x+3,#0
	
	
	
	
    lcall mul32
    Load_y(100)
    lcall div32
    
    mov y+0,x+0
    mov y+1,x+1
    mov y+2,x+2
    mov y+3,x+3 
    



    Load_x(144000000)
  
    lcall div32
	lcall hex2bcd
	lcall Display_8_digit_BCD

	Set_Cursor(2, 14)
    Send_Constant_String(#Msg2)
   
	; Convert the result to BCD and display on LCD
	
	
	ljmp Forever ; Repeat!
	
END
