; Approximate index of sounds in file 'Simple_Cup_Voice.wav'
fetch_sound: ; Playback a portion of the stored wav file

ljmp main_program_sound

sound_index:
    db 0x00, 0x00, 0x2b ; 0 
    db 0x00, 0x44, 0x6b ; 1 
    db 0x00, 0x48, 0x08 ; 2 
    db 0x00, 0x4b, 0xa4 ; 3 
    db 0x00, 0x7b, 0xb7 ; 4 
    db 0x00, 0x83, 0x8a ; 5 
    db 0x00, 0x8d, 0xac ; 6 
    db 0x00, 0x95, 0x95 ; 7 
    db 0x00, 0x9f, 0xba ; 8 
    db 0x00, 0xa1, 0xdd ; 9 
    db 0x00, 0xab, 0xd1 ; 10 
    db 0x00, 0xaf, 0x7a ; 11 
    db 0x00, 0xd9, 0x97 ; 12 
    db 0x01, 0x00, 0x8a ; 13 
    db 0x01, 0x25, 0x45 ; 14 
    db 0x01, 0xa2, 0x32 ; 15 
    db 0x01, 0xc4, 0x8c ; 16 
    db 0x01, 0xff, 0xdf ; 17 
    db 0x02, 0x0a, 0x09 ; 18 
    db 0x02, 0xb6, 0xee ; 19 
    db 0x02, 0xb9, 0xba 

; Size of each sound in 'sound_index'
Size_sound:
    db 0x00, 0x44, 0x40 ; 0 
    db 0x00, 0x03, 0x9d ; 1 
    db 0x00, 0x03, 0x9c ; 2 
    db 0x00, 0x30, 0x13 ; 3 
    db 0x00, 0x07, 0xd3 ; 4 
    db 0x00, 0x0a, 0x22 ; 5 
    db 0x00, 0x07, 0xe9 ; 6 
    db 0x00, 0x0a, 0x25 ; 7 
    db 0x00, 0x02, 0x23 ; 8 
    db 0x00, 0x09, 0xf4 ; 9 
    db 0x00, 0x03, 0xa9 ; 10 
    db 0x00, 0x2a, 0x1d ; 11 
    db 0x00, 0x26, 0xf3 ; 12 
    db 0x00, 0x24, 0xbb ; 13 
    db 0x00, 0x7c, 0xed ; 14 
    db 0x00, 0x22, 0x5a ; 15 
    db 0x00, 0x3b, 0x53 ; 16 
    db 0x00, 0x0a, 0x2a ; 17 
    db 0x00, 0xac, 0xe5 ; 18 
    db 0x00, 0x02, 0xcc ; 19 
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
	mov a, #0x2b
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x44
	lcall Send_SPI
	mov a, #0x6b
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x03
 	mov w+0, #0x9d
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x48
	lcall Send_SPI
	mov a, #0x08
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x03
 	mov w+0, #0x9c
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x4b
	lcall Send_SPI
	mov a, #0xa4
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
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
	mov a, #0x00
	lcall Send_SPI
	mov a, #0x7b
	lcall Send_SPI
	mov a, #0xb7
 	lcall Send_SPI
 
; Set how many bytes to play
 	mov w+2, #0x00
 	mov w+1, #0x44
 	mov w+0, #0x40
 
 	mov a, #0x00 ; Request first byte to send to DAC
 	lcall Send_SPI
 
 	setb SPEAKER ; Turn on speaker.
 	setb sound_on ; Start playback by enabling timer 2
 	ret ; If this is a subroutine, it must end with 'ret'
main_program_sound:
check_lower1:
Load_y (10000)
lcall x_gteq_y
jb mf,check_upper1
sjmp sound_done

check_upper1:
Load_y (10065)
lcall x_lteq_y
jnb mf, check_lower2
lcall Play_empty
sjmp sound_done

check_lower2: 
Load_y (10140)
lcall x_gteq_y
jb mf,check_upper2
sjmp sound_done

check_upper2:
Load_y (10170)
lcall x_lteq_y
jnb mf, check_lower3
lcall Play_9
sjmp sound_done

check_lower3: 
Load_y (10280)
lcall x_gteq_y
jb mf,check_upper3
sjmp sound_done

check_upper3:
Load_y (10300)
lcall x_lteq_y
jnb mf, check_lower4
lcall Play_18
sjmp sound_done

check_lower4: 
Load_y (10410)
lcall x_gteq_y
jb mf,check_upper4
sjmp sound_done

check_upper4:
Load_y (10430)
lcall x_lteq_y
jnb mf, check_lower5
lcall Play_27
sjmp sound_done

check_lower5: 
Load_y (10530)
lcall x_gteq_y
jb mf,check_upper5
sjmp sound_done

check_upper5:
Load_y (10550)
lcall x_lteq_y
jnb mf, check_lower6
lcall Play_36
sjmp sound_done

check_lower6: 
Load_y (10530)
lcall x_gteq_y
jb mf,check_upper6
sjmp sound_done

check_upper6:
Load_y (10550)
lcall x_lteq_y
jnb mf, check_lower7
lcall Play_36
sjmp sound_done

check_lower7: 
Load_y (10620)
lcall x_gteq_y
jb mf,check_upper7
sjmp sound_done

check_upper7:
Load_y (10640)
lcall x_lteq_y
jnb mf, check_lower8
lcall Play_45
sjmp sound_done

check_lower8: 
Load_y (10690)
lcall x_gteq_y
jb mf,check_upper8
sjmp sound_done

check_upper8:
Load_y (10710)
lcall x_lteq_y
jnb mf, check_lower9
lcall Play_54
sjmp sound_done

check_lower9: 
Load_y (10750)
lcall x_gteq_y
jb mf,check_upper9
sjmp sound_done

check_upper9:
Load_y (10770)
lcall x_lteq_y
jnb mf, check_lower10
lcall Play_64
sjmp sound_done

check_lower10: 
Load_y (10820)
lcall x_gteq_y
jb mf,check_upper10
sjmp sound_done

check_upper10:
Load_y (10840)
lcall x_lteq_y
jnb mf, check_lower11
lcall Play_73
sjmp sound_done

check_lower11: 
Load_y (10880)
lcall x_gteq_y
jb mf,check_upper11
sjmp sound_done

check_upper11:
Load_y (10900)
lcall x_lteq_y
jnb mf, check_lower12
lcall Play_82
sjmp sound_done

check_lower12: 
Load_y (10950)
lcall x_gteq_y
jb mf,check_upper11
sjmp sound_done

check_upper12:
Load_y (10970)
lcall x_lteq_y
jnb mf, check_lower12
lcall Play_91
sjmp sound_done

check_lower13: 
Load_y (11000)
lcall x_gteq_y
jb mf,check_upper11
sjmp sound_done

check_upper13:
Load_y (11020)
lcall x_lteq_y
jnb mf, sound_done
lcall Play_full
sjmp sound_done

sound_done: ; Playback a portion of the stored wav file
reti
