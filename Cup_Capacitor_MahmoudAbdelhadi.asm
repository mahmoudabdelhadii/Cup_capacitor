; Cup_Capacitor.asm:  This program implements usage of a simple serial port
; communication protocol to program, verify, and read an SPI flash memory. It also
; measures the frequency of an attached capacitor. The sound then reads out the water level at certain intervals
; It is assumed that the wav sampling rate is
; 22050Hz, 8-bit, mono.
;
; Connections:
; 
; EFM8 board  SPI_FLASH
; P0.0        Pin 6 (SPI_CLK)
; P0.1        Pin 2 (MISO)
; P0.2        Pin 5 (MOSI)
; P0.3        Pin 1 (CS/)
; GND         Pin 4
; 3.3V        Pins 3, 7, 8  (The MCP1700 3.3V voltage regulator or similar is required)
;
; P3.0 is the DAC output which should be connected to the input of power amplifier (LM386 or similar)
;

$NOLIST
$MODEFM8LB1
$LIST

SYSCLK         EQU 72000000  ; Microcontroller system clock frequency in Hz
TIMER2_RATE    EQU 22050     ; 22050Hz is the sampling rate of the wav file we are playing
TIMER2_RELOAD  EQU 0x10000-(SYSCLK/TIMER2_RATE)
F_SCK_MAX      EQU 20000000
BAUDRATE       EQU 115200

FLASH_CE EQU P0.3
SPEAKER  EQU P2.0

; Commands supported by the SPI flash memory according to the datasheet
WRITE_ENABLE     EQU 0x06  ; Address:0 Dummy:0 Num:0
WRITE_DISABLE    EQU 0x04  ; Address:0 Dummy:0 Num:0
READ_STATUS      EQU 0x05  ; Address:0 Dummy:0 Num:1 to infinite
READ_BYTES       EQU 0x03  ; Address:3 Dummy:0 Num:1 to infinite
READ_SILICON_ID  EQU 0xab  ; Address:0 Dummy:3 Num:1 to infinite
FAST_READ        EQU 0x0b  ; Address:3 Dummy:1 Num:1 to infinite
WRITE_STATUS     EQU 0x01  ; Address:0 Dummy:0 Num:1
WRITE_BYTES      EQU 0x02  ; Address:3 Dummy:0 Num:1 to 256
ERASE_ALL        EQU 0xc7  ; Address:0 Dummy:0 Num:0
ERASE_BLOCK      EQU 0xd8  ; Address:3 Dummy:0 Num:0
READ_DEVICE_ID   EQU 0x9f  ; Address:0 Dummy:2 Num:1 to infinite

; Variables used in the program:
dseg at 30H
	w:   ds 3 ; 24-bit play counter.  Decremented in Timer 2 ISR.
	tic_counter: ds 2 ; counter to determine whether a second has passed
	x: ds 4 ; For holding the pointer to the flash memory of what sound to play
; large registors for holding the frequency values
	y: ds 4
	z: ds 4
	bcd: ds 5
	
bseg
	one_sec_flag: dbit 1 ; Used for determing whether one second has passed
	Sound_On: dbit 1 ; Used for turning the sound on and off
	mf: dbit 1 ; Needed for math32.inc
	playing_sound: dbit 1 ; Making sure it doesn't restart playing sound

; Interrupt vectors:
cseg

org 0x0000 ; Reset vector
    ljmp MainProgram

org 0x0003 ; External interrupt 0 vector (not used in this code)
	reti

org 0x000B ; Timer/Counter 0 overflow interrupt vector (not used in this code)
	reti

org 0x0013 ; External interrupt 1 vector (not used in this code)
	reti

org 0x001B ; Timer/Counter 1 overflow interrupt vector (not used in this code)
	reti

org 0x0023 ; Serial port receive/transmit interrupt vector (not used in this code)
	reti

org 0x005b ; Timer 2 interrupt vector.  Used in this code to replay the wave file.
	ljmp Timer2_ISR
	
; These 'equ' must match the hardware wiring
; They are used by 'LCD_4bit.inc'
LCD_RS equ P1.7
LCD_RW equ P1.6
LCD_E  equ P1.5
LCD_D4 equ P2.2
LCD_D5 equ P2.3
LCD_D6 equ P2.4
LCD_D7 equ P2.5
$NOLIST
$include(LCD_4bit.inc)
$include(math32.inc)
$LIST
 
ResistorB equ 10
ResistorA equ 10 
 
Cap_Message: db 'Capacitance:', 0
nf_message: db 'nf', 0

; Approximate index of sounds in file 'Simple_Cup_Voice.wav'
fetch_sound: ; Playback a portion of the stored wav file

ljmp main_program_sound

Play_empty: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x4d
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xd9
 	mov w+0, #0xb8
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'

Play_9: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES 
	lcall Send_SPI
	mov a, #0x00
	lcall Send_SPI
	mov a, #0xda
	lcall Send_SPI
	mov a, #0x05
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xb3
 	mov w+0, #0x9b
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'

Play_18: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x01
	lcall Send_SPI
	mov a, #0x8d
	lcall Send_SPI
	mov a, #0xa0
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xbc
 	mov w+0, #0xca
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_27: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x02
	lcall Send_SPI
	mov a, #0x4a
	lcall Send_SPI
	mov a, #0x6a
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xd6
 	mov w+0, #0xbd
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_36: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x03
	lcall Send_SPI
	mov a, #0x21
	lcall Send_SPI
	mov a, #0x27
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xce
 	mov w+0, #0x18
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'

Play_45: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x03
	lcall Send_SPI
	mov a, #0xef
	lcall Send_SPI
	mov a, #0x3f
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xca
 	mov w+0, #0x51
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_54: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x04
	lcall Send_SPI
	mov a, #0xb9
	lcall Send_SPI
	mov a, #0x90
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xd0
 	mov w+0, #0xd0
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_64: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x05
	lcall Send_SPI
	mov a, #0x8a
	lcall Send_SPI
	mov a, #0x60
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xd5
 	mov w+0, #0xc4
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_72: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x06
	lcall Send_SPI
	mov a, #0x60
	lcall Send_SPI
	mov a, #0x24
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xd4
 	mov w+0, #0xe3
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_81: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x07
	lcall Send_SPI
	mov a, #0x35
	lcall Send_SPI
	mov a, #0x07
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0xcd
 	mov w+0, #0xd1
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
Play_91: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x08
	lcall Send_SPI
	mov a, #0x02
	lcall Send_SPI
	mov a, #0xd8
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
	mov w+1, #0xc6
	mov w+0, #0x91
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
 	
Play_full: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	clr SPEAKER ; Turn off speaker.
 
; Set the begining of the sound to play
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	mov a, #0x08
	lcall Send_SPI
	mov a, #0xc9
	lcall Send_SPI
	mov a, #0x69
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x01
 	mov w+1, #0x4e
 	mov w+0, #0x3e
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
main_program_sound:
check_lower1:
Load_y (09000)
lcall x_gteq_y
jb mf,check_upper1
ljmp sound_done3

check_upper1:
Load_y (10030)
lcall x_lteq_y
jnb mf, check_lower2
lcall Play_empty
ljmp sound_done3

check_lower2: 
Load_y (10100)
lcall x_gteq_y
jb mf,check_upper2
ljmp sound_done3

check_upper2: ; 9%
Load_y (10130)
lcall x_lteq_y
jnb mf, check_lower3
lcall Play_9
ljmp sound_done3

check_lower3: ;18%
Load_y (10190)
lcall x_gteq_y
jb mf,check_upper3
ljmp sound_done3

check_upper3:
Load_y (10220)
lcall x_lteq_y
jnb mf, check_lower4
lcall Play_18
ljmp sound_done3

check_lower4: ;27
Load_y (10325)
lcall x_gteq_y
jb mf,check_upper4
ljmp sound_done3

check_upper4:
Load_y (10365)
lcall x_lteq_y
jnb mf, check_lower5
lcall Play_27
ljmp sound_done3

sound_done3: ljmp sound_done2

check_lower5: ; 36
Load_y (10400)
lcall x_gteq_y
jb mf,check_upper5
ljmp sound_done2

check_upper5:
Load_y (10460)
lcall x_lteq_y
jnb mf, check_lower7
lcall Play_36
ljmp sound_done2

sound_done2: ljmp sound_done1

check_lower7: ;45
Load_y (10520)
lcall x_gteq_y
jb mf,check_upper7
ljmp sound_done1

check_upper7:
Load_y (10560)
lcall x_lteq_y
jnb mf, check_lower8
lcall Play_45
ljmp sound_done1

sound_done1: ljmp sound_done

check_lower8: ;54
Load_y (10620)
lcall x_gteq_y
jb mf,check_upper8
ljmp sound_done

check_upper8:
Load_y (10660)
lcall x_lteq_y
jnb mf, check_lower9
lcall Play_54
ljmp sound_done

check_lower9: ;64
Load_y (10680)
lcall x_gteq_y
jb mf,check_upper9
ljmp sound_done

check_upper9:
Load_y (10720)
lcall x_lteq_y
jnb mf, check_lower10
lcall Play_64
ljmp sound_done

check_lower10: ;73
Load_y (10750)
lcall x_gteq_y
jb mf,check_upper10
ljmp sound_done

check_upper10:
Load_y (10790)
lcall x_lteq_y
jnb mf, check_lower11
lcall Play_72
ljmp sound_done

check_lower11: ;82
Load_y (10800)
lcall x_gteq_y
jb mf,check_upper11
ljmp sound_done

check_upper11:
Load_y (10830)
lcall x_lteq_y
jnb mf, check_lower12
lcall Play_81
ljmp sound_done

check_lower12: 
Load_y (10830)
lcall x_gteq_y
jb mf,check_upper12
ljmp sound_done

check_upper12:
Load_y (10870)
lcall x_lteq_y
jnb mf, check_lower13
lcall Play_91
ljmp sound_done

check_lower13: 
Load_y (10900)
lcall x_gteq_y
jb mf,check_upper13
ljmp sound_done

check_upper13:
Load_y (14000)
lcall x_lteq_y
jnb mf, overlimit
lcall Play_full
ljmp sound_done

overlimit:
Load_y (14000)
lcall x_gteq_y
jb mf,sound_done
ljmp sound_done
sound_done: ; Playback a portion of the stored wav file
ret

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

; We can display a number any way we want.  In this case with
; four decimal places.

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
 

;-------------------------------------;
; ISR for Timer 2.  Used to playback  ;
; the WAV file stored in the SPI      ;
; flash memory.                       ;
;-------------------------------------;
Timer2_ISR:
	mov	SFRPAGE, #0x00
	clr	TF2H ; Clear Timer2 interrupt flag
	
	; The registers used in the ISR must be saved in the stack
	push acc
	push psw
	
 	jb one_sec_flag, sound_output ; check whether it's been a second
 	
 	mov a, tic_counter+0
 	cjne a, #low(22050), tic_incremental ; check and see whether tic_counter is at 22050
 	mov a, tic_counter+1
 	cjne a, #high(22050), tic_incremental
 	setb one_sec_flag ; if it is a 22050 set the one_second_counter and reset counter to zero
 	mov tic_counter+0, #0x00
 	mov tic_counter+1, #0x00
 	sjmp sound_output
 
tic_incremental: ; if not at 22050, increment tic_counter
 	mov a, tic_counter+0
 	add a, #1
 	mov tic_counter+0,a 
 	mov a, tic_counter+1
 	addc a, #0
 	mov tic_counter+1,a

sound_output:
	
	jnb Sound_On, Timer2_ISR_Done
	; Check if the play counter is zero.  If so, stop playing sound.
	mov a, w+0
	orl a, w+1
	orl a, w+2
	jz stop_playing
	
	; Decrement play counter 'w'.  In this implementation 'w' is a 24-bit counter.
	mov a, #0xff
	dec w+0
	cjne a, w+0, keep_playing
	dec w+1
	cjne a, w+1, keep_playing
	dec w+2
	
	
keep_playing:

	setb SPEAKER
	lcall Send_SPI ; Read the next byte from the SPI Flash...
	
	; It gets a bit complicated here because we read 8 bits from the flash but we need to write 12 bits to DAC:
	mov SFRPAGE, #0x30 ; DAC registers are in page 0x30
	push acc ; Save the value we got from flash
	swap a
	anl a, #0xf0
	mov DAC0L, a
	pop acc
	swap a
	anl a, #0x0f
	mov DAC0H, a
	mov SFRPAGE, #0x00
	
	sjmp Timer2_ISR_Done

stop_playing:
	clr sound_on ; De-assert sound_on flag
	setb FLASH_CE  ; Disable SPI Flash
	clr SPEAKER ; Turn off speaker.  Removes hissing noise when not playing sound.
	;clr playing_sound

Timer2_ISR_Done:	
	pop psw
	pop acc
	reti
	
;---------------------------------;
; Sends a byte via serial port    ;
;---------------------------------;
putchar:
	jbc	TI,putchar_L1
	sjmp putchar
putchar_L1:
	mov	SBUF,a
	ret

;---------------------------------;
; Receive a byte from serial port ;
;---------------------------------;
getchar:
	jbc	RI,getchar_L1
	sjmp getchar
getchar_L1:
	mov	a,SBUF
	ret

;---------------------------------;
; Sends AND receives a byte via   ;
; SPI.                            ;
;---------------------------------;
Send_SPI:
	mov	SPI0DAT, a
Send_SPI_L1:
	jnb	SPIF, Send_SPI_L1 ; Wait for SPI transfer complete
	clr SPIF ; Clear SPI complete flag 
	mov	a, SPI0DAT
	ret

;---------------------------------;
; SPI flash 'write enable'        ;
; instruction.                    ;
;---------------------------------;
Enable_Write:
	clr FLASH_CE
	mov a, #WRITE_ENABLE
	lcall Send_SPI
	setb FLASH_CE
	ret

;---------------------------------;
; This function checks the 'write ;
; in progress' bit of the SPI     ;
; flash memory.                   ;
;---------------------------------;
Check_WIP:
	clr FLASH_CE
	mov a, #READ_STATUS
	lcall Send_SPI
	mov a, #0x55
	lcall Send_SPI
	setb FLASH_CE
	jb acc.0, Check_WIP ;  Check the Write in Progress bit
	ret
	
Init_all:
	; Disable WDT:
	mov	WDTCN, #0xDE
	mov	WDTCN, #0xAD
	
	mov	VDM0CN, #0x80
	mov	RSTSRC, #0x06
	
	; Switch SYSCLK to 72 MHz.  First switch to 24MHz:
	mov	SFRPAGE, #0x10
	mov	PFE0CN, #0x20
	mov	SFRPAGE, #0x00
	mov	CLKSEL, #0x00
	mov	CLKSEL, #0x00 ; Second write to CLKSEL is required according to datasheet
	
	; Wait for clock to settle at 24 MHz by checking the most significant bit of CLKSEL:
Init_L1:
	mov	a, CLKSEL
	jnb	acc.7, Init_L1
	
	; Now switch to 72MHz:
	mov	CLKSEL, #0x03
	mov	CLKSEL, #0x03  ; Second write to CLKSEL is required according to datasheet
	
	; Wait for clock to settle at 72 MHz by checking the most significant bit of CLKSEL:
Init_L2:
	mov	a, CLKSEL
	jnb	acc.7, Init_L2

	mov	SFRPAGE, #0x00
	
	; Configure P3.0 as analog output.  P3.0 pin is the output of DAC0.
	anl	P3MDIN, #0xFE
	orl	P3, #0x01
	
	;Skip the pins used by the SPI and the LCD
	orl P0SKIP, #0b_0000_1000 ; Pin P0.3 which is used as CS for SPI
	orl P1SKIP, #0b_1110_0000 ; Pins P1.5,P1.6,P1.7 used for LCD
	orl P2SKIP, #0b_0011_1100 ; Pins P2,2,P2.3,P2.4,P2.5 used for LCD
	
	; Configure the pins used for SPI (P0.0 to P0.3)
	mov	P0MDOUT, #0x1D ; SCK, MOSI, P0.3, TX0 are push-pull, all others open-drain

	mov	XBR0, #0x03 ; Enable SPI and UART0: SPI0E=1, URT0E=1
	mov	XBR1, #0x10 ; Enable T0 on P1.2 which is for the frequency measurement
	mov	XBR2, #0x40 ; Enable crossbar and weak pull-ups

	; Enable serial communication and set up baud rate using timer 1
	mov	SCON0, #0x10	
	mov	TH1, #(0x100-((SYSCLK/BAUDRATE)/(12*2)))
	mov	TL1, TH1
	anl	TMOD, #0x0F ; Clear the bits of timer 1 in TMOD
	orl	TMOD, #0x20 ; Set timer 1 in 8-bit auto-reload mode.  Don't change the bits of timer 0
	setb TR1 ; START Timer 1
	setb TI ; Indicate TX0 ready
	
	; Configure DAC 0
	mov	SFRPAGE, #0x30 ; To access DAC 0 we use register page 0x30
	mov	DACGCF0, #0b_1000_1000 ; 1:D23REFSL(VCC) 1:D3AMEN(NORMAL) 2:D3SRC(DAC3H:DAC3L) 1:D01REFSL(VCC) 1:D1AMEN(NORMAL) 1:D1SRC(DAC1H:DAC1L)
	mov	DACGCF1, #0b_0000_0000
	mov	DACGCF2, #0b_0010_0010 ; Reference buffer gain 1/3 for all channels
	mov	DAC0CF0, #0b_1000_0000 ; Enable DAC 0
	mov	DAC0CF1, #0b_0000_0010 ; DAC gain is 3.  Therefore the overall gain is 1.
	; Initial value of DAC 0 is mid scale:
	mov	DAC0L, #0x00
	mov	DAC0H, #0x08
	mov	SFRPAGE, #0x00
	
	; Configure SPI
	mov	SPI0CKR, #((SYSCLK/(2*F_SCK_MAX))-1)
	mov	SPI0CFG, #0b_0100_0000 ; SPI in master mode
	mov	SPI0CN0, #0b_0000_0001 ; SPI enabled and in three wire mode
	setb FLASH_CE ; CS=1 for SPI flash memory
	clr SPEAKER ; Turn off speaker.
	
	;Initializes timer/counter 0 as a 16-bit counter
    clr TR0 ; Stop timer 0
    mov a, TMOD
    anl a, #0b_1111_0000 ; Clear the bits of timer/counter 0
    orl a, #0b_0000_0101 ; Sets the bits of timer/counter 0 for a 16-bit counter
    mov TMOD, a
	
	; Configure Timer 2 and its interrupt
	mov	TMR2CN0,#0x00 ; Stop Timer2; Clear TF2
	orl	CKCON0,#0b_0001_0000 ; Timer 2 uses the system clock
	; Initialize reload value:
	mov	TMR2RLL, #low(TIMER2_RELOAD)
	mov	TMR2RLH, #high(TIMER2_RELOAD)
	; Set timer to reload immediately
	mov	TMR2H,#0xFF
	mov	TMR2L,#0xFF
	setb ET2 ; Enable Timer 2 interrupts
	setb TR2 ; Timer 2 is only enabled to play stored sound
	
	; Initialize the variables used for the sound and frequency measurements
	clr sound_on
	mov tic_counter, #0x00
	mov w+2,#0x00
	mov w+1,#0x00
	mov w+0,#0x00
	;clr playing_sound
	
	setb EA ; Enable interrupts
	
	ret

;---------------------------------;
; Main program. Includes hardware ;
; initialization and 'forever'    ;
; loop.                           ;
;---------------------------------;
Serial_Get_Intermed:
	lcall serial_get

MainProgram:
    mov SP, #0x7f ; Setup stack pointer to the start of indirectly accessable data memory minus one
    lcall Init_all ; Initialize the hardware
    
    
	; Configure LCD and display initial message
    lcall LCD_4BIT
	Set_Cursor(1, 1)
    Send_Constant_String(#Cap_Message)

forever_loop:

	jb RI, Serial_Get_Intermed

	; Code to read frequency
	clr TR0
	mov TH0, #0x00
	mov TL0, #0x00
	setb TR0
	clr one_sec_flag
	jnb one_sec_flag, $ ; Wait for a second to pass
	clr TR0
	
    mov x+0,TL0
    mov x+1,TH0         ; freq in x
    mov x+2,#0
    mov x+3,#0
	    
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
   	mov x+2,#0
   	mov x+3,#0
	

   	lcall mul32
  
   	
   	Load_y(88)
   	lcall div32
    
   	
   	mov y+0,x+0
   	mov y+1,x+1
    mov y+2,x+2
    mov y+3,x+3 
  
    Load_x(144000000)
 
    lcall div32
    lcall hex2bcd
    lcall Display_8_digit_BCD     
    Set_Cursor(2,14)
    Send_Constant_String(#nf_message)
    
    ; Check if play counter == zero if it is not, do not fetch new sound
    mov a, w+0
    orl a, w+1
    orl a, w+2
    jnz forever_loop_intermed
	;jnb playing_sound, forever_loop_intermed
    lcall fetch_sound
    ;setb playing_sound
    
	ljmp forever_loop
	
serial_get:
	lcall getchar ; Wait for data to arrive
	cjne a, #'#', forever_loop_intermed ; Message format is #n[data] where 'n' is '0' to '9'
	clr sound_on ; Stop Timer 2 from playing previous request
	setb FLASH_CE ; Disable SPI Flash	
	clr SPEAKER ; Turn off speaker.
	lcall getchar
	sjmp Commands
	
forever_loop_intermed:
	ljmp forever_loop

Commands:
;---------------------------------------------------------	
	cjne a, #'0' , Command_0_skip
Command_0_start: ; Identify command
	clr FLASH_CE ; Enable SPI Flash	
	mov a, #READ_DEVICE_ID
	lcall Send_SPI	
	mov a, #0x55
	lcall Send_SPI
	lcall putchar
	mov a, #0x55
	lcall Send_SPI
	lcall putchar
	mov a, #0x55
	lcall Send_SPI
	lcall putchar
	setb FLASH_CE ; Disable SPI Flash
	ljmp forever_loop	
Command_0_skip:

;---------------------------------------------------------	
	cjne a, #'1' , Command_1_skip 
Command_1_start: ; Erase whole flash (takes a long time)
	lcall Enable_Write
	clr FLASH_CE
	mov a, #ERASE_ALL
	lcall Send_SPI
	setb FLASH_CE
	lcall Check_WIP
	mov a, #0x01 ; Send 'I am done' reply
	lcall putchar		
	ljmp forever_loop	
Command_1_skip:

;---------------------------------------------------------	
	cjne a, #'2' , Command_2_skip 
Command_2_start: ; Load flash page (256 bytes or less)
	lcall Enable_Write
	clr FLASH_CE
	mov a, #WRITE_BYTES
	lcall Send_SPI
	lcall getchar ; Address bits 16 to 23
	lcall Send_SPI
	lcall getchar ; Address bits 8 to 15
	lcall Send_SPI
	lcall getchar ; Address bits 0 to 7
	lcall Send_SPI
	lcall getchar ; Number of bytes to write (0 means 256 bytes)
	mov r0, a
Command_2_loop:
	lcall getchar
	lcall Send_SPI
	djnz r0, Command_2_loop
	setb FLASH_CE
	lcall Check_WIP
	mov a, #0x01 ; Send 'I am done' reply
	lcall putchar		
	ljmp forever_loop	
Command_2_skip:

;---------------------------------------------------------	
	cjne a, #'3' , Command_3_skip 
Command_3_start: ; Read flash bytes (256 bytes or less)
	clr FLASH_CE
	mov a, #READ_BYTES
	lcall Send_SPI
	lcall getchar ; Address bits 16 to 23
	lcall Send_SPI
	lcall getchar ; Address bits 8 to 15
	lcall Send_SPI
	lcall getchar ; Address bits 0 to 7
	lcall Send_SPI
	lcall getchar ; Number of bytes to read and send back (0 means 256 bytes)
	mov r0, a

Command_3_loop:
	mov a, #0x55
	lcall Send_SPI
	lcall putchar
	djnz r0, Command_3_loop
	setb FLASH_CE	
	ljmp forever_loop	
Command_3_skip:

;---------------------------------------------------------	
	cjne a, #'4' , Command_4_skip 
Command_4_start: ; Playback a portion of the stored wav file
	clr sound_on ; Stop Timer 2 ISR from playing previous request
	setb FLASH_CE
	
	clr FLASH_CE ; Enable SPI Flash
	mov a, #READ_BYTES
	lcall Send_SPI
	; Get the initial position in memory where to start playing
	lcall getchar
	lcall Send_SPI
	lcall getchar
	lcall Send_SPI
	lcall getchar
	lcall Send_SPI
	; Get how many bytes to play
	lcall getchar
	mov w+2, a
	lcall getchar
	mov w+1, a
	lcall getchar
	mov w+0, a
	
	mov a, #0x00 ; Request first byte to send to DAC
	lcall Send_SPI
	
	setb sound_on ; Start playback by enabling timer 2
	ljmp forever_loop	
Command_4_skip:

;---------------------------------------------------------	
	cjne a, #'5' , Command_5_skip 
Command_5_start: ; Calculate and send CRC-16 of ISP flash memory from zero to the 24-bit passed value.
	; Get how many bytes to use to calculate the CRC.  Store in [r5,r4,r3]
	lcall getchar
	mov r5, a
	lcall getchar
	mov r4, a
	lcall getchar
	mov r3, a
	
	; Since we are using the 'djnz' instruction to check, we need to add one to each byte of the counter.
	; A side effect is that the down counter becomes efectively a 23-bit counter, but that is ok
	; because the max size of the 25Q32 SPI flash memory is 400000H.
	inc r3
	inc r4
	inc r5
	
	; Initial CRC must be zero.
	mov	SFRPAGE, #0x20 ; UART0, CRC, and SPI can work on this page
	mov	CRC0CN0, #0b_0000_1000 ; // Initialize hardware CRC result to zero;

	clr FLASH_CE
	mov a, #READ_BYTES
	lcall Send_SPI
	clr a ; Address bits 16 to 23
	lcall Send_SPI
	clr a ; Address bits 8 to 15
	lcall Send_SPI
	clr a ; Address bits 0 to 7
	lcall Send_SPI
	mov	SPI0DAT, a ; Request first byte from SPI flash
	sjmp Command_5_loop_start

Command_5_loop:
	jnb SPIF, Command_5_loop 	; Check SPI Transfer Completion Flag
	clr SPIF				    ; Clear SPI Transfer Completion Flag	
	mov a, SPI0DAT				; Save received SPI byte to accumulator
	mov SPI0DAT, a				; Request next byte from SPI flash; while it arrives we calculate the CRC:
	mov	CRC0IN, a               ; Feed new byte to hardware CRC calculator

Command_5_loop_start:
	; Drecrement counter:
	djnz r3, Command_5_loop
	djnz r4, Command_5_loop
	djnz r5, Command_5_loop
Command_5_loop2:	
	jnb SPIF, Command_5_loop2 	; Check SPI Transfer Completion Flag
	clr SPIF			    	; Clear SPI Transfer Completion Flag
	mov a, SPI0DAT	            ; This dummy read is needed otherwise next transfer fails (why?)
	setb FLASH_CE 				; Done reading from SPI flash
	
	; Computation of CRC is complete.  Send 16-bit result using the serial port
	mov	CRC0CN0, #0x01 ; Set bit to read hardware CRC high byte
	mov	a, CRC0DAT
	lcall putchar

	mov	CRC0CN0, #0x00 ; Clear bit to read hardware CRC low byte
	mov	a, CRC0DAT
	lcall putchar
	
	mov	SFRPAGE, #0x00

	ljmp forever_loop	
Command_5_skip:

;---------------------------------------------------------	
	cjne a, #'6' , Command_6_skip 
Command_6_start: ; Fill flash page (256 bytes)
	lcall Enable_Write
	clr FLASH_CE
	mov a, #WRITE_BYTES
	lcall Send_SPI
	lcall getchar ; Address bits 16 to 23
	lcall Send_SPI
	lcall getchar ; Address bits 8 to 15
	lcall Send_SPI
	lcall getchar ; Address bits 0 to 7
	lcall Send_SPI
	lcall getchar ; Byte to write
	mov r1, a
	mov r0, #0 ; 256 bytes
Command_6_loop:
	mov a, r1
	lcall Send_SPI
	djnz r0, Command_6_loop
	setb FLASH_CE
	lcall Check_WIP
	mov a, #0x01 ; Send 'I am done' reply
	lcall putchar		
	ljmp forever_loop	
Command_6_skip:

	ljmp forever_loop



END