#include <XC.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
// Configuration Bits (somehow XC32 takes care of this)
#pragma config FNOSC = FRCPLL       // Internal Fast RC oscillator (8 MHz) w/ PLL
#pragma config FPLLIDIV = DIV_2     // Divide FRC before PLL (now 4 MHz)
#pragma config FPLLMUL = MUL_20     // PLL Multiply (now 80 MHz)
#pragma config FPLLODIV = DIV_2     // Divide After PLL (now 40 MHz)
 
#pragma config FWDTEN = OFF         // Watchdog Timer Disabled
#pragma config FPBDIV = DIV_1       // PBCLK = SYCLK

// Defines
#define SYSCLK 40000000L
#define Baud2BRG(desired_baud)( (SYSCLK / (16*desired_baud))-1)

// Function Prototypes
int SerialTransmit(const char *buffer);
int UART2Configure( int baud_rate, int desired_baud);

int UART2Configure(int baud_rate, int desired_baud)
{

    // Setting up the serial port connection for the PIC32
    U2MODE = 0;		    // disable autobaud, TX and RX enabled only, 8N1, idle=high
    U2STA = 0x1400;
    U2BRG = Baud2BRG(desired_baud);	// U2BRG = (FPb / (16*baud)) - 1
    // Calculate actual baud rate
    int actual_baud = SYSCLK / (16 * (U2BRG + 1));
    
    // Peripheral Pin Select
    U2RXRbits.U2RXR = 4;    //SET RX to RB8
    RPB9Rbits.RPB9R = 2;    //SET RB9 to TX

    U2MODE = 0;         // disable autobaud, TX and RX enabled only, 8N1, idle=HIGH
    U2STA = 0x1400;     // enable TX and RX
    U2BRG = Baud2BRG(baud_rate); // U2BRG = (FPb / (16*baud)) - 1
    
    U2MODESET = 0x8000;     // enable UART2

    return actual_baud;
}

int SerialTransmit(const char *buffer)
{

    unsigned int size = strlen(buffer);
    while( size)
    {
	while(U2STAbits.UTXBF);
	U2TXREG = *buffer;
	buffer++;
	size--;
    }

    while( !U2STAbits.TRMT);

    return 0;
}

/* SerialReceive() is a blocking function that waits for data on
 *  the UART2 RX buffer and then stores all incoming data into *buffer
 *
 * Note that when a carriage return '\r' is received, a nul character
 *  is appended signifying the strings end
 *
 * Inputs:  *buffer = Character array/pointer to store received data into
 *          max_size = number of bytes allocated to this pointer
 * Outputs: Number of characters received */
unsigned int SerialReceive(char *buffer, unsigned int max_size)
{
    unsigned int num_char = 0;
 
    /* Wait for and store incoming data until either a carriage return is received
     *   or the number of received characters (num_chars) exceeds max_size */
    while(num_char < max_size)
    {
        while( !U2STAbits.URXDA);   // wait until data available in RX buffer
        *buffer = U2RXREG;          // empty contents of RX buffer into *buffer pointer
 
        // insert nul character to indicate end of string
        if( *buffer == '\r')
        {
            *buffer = '\0';     
            break;
        }
 
        buffer++;
        num_char++;
    }
 
    return num_char;
}


// Good information about ADC in PIC32 found here:
// http://umassamherstm5.org/tech-tutorials/pic32-tutorials/pic32mx220-tutorials/adc
void ADCConf(void)
{
    AD1CON1CLR = 0x8000;    // disable ADC before configuration
    AD1CON1 = 0x00E0;       // internal counter ends sampling and starts conversion (auto-convert), manual sample
    AD1CON2 = 0;            // AD1CON2<15:13> set voltage reference to pins AVSS/AVDD
    AD1CON3 = 0x0f01;       // TAD = 4*TPB, acquisition time = 15*TAD 
    AD1CON1SET=0x8000;      // Enable ADC
}

int ADCRead(char analogPIN)
{
    AD1CHS = analogPIN << 16;    // AD1CHS<16:19> controls which analog pin goes to the ADC
 
    AD1CON1bits.SAMP = 1;        // Begin sampling
    while(AD1CON1bits.SAMP);     // wait until acquisition is done
    while(!AD1CON1bits.DONE);    // wait until conversion done
 
    return ADC1BUF0;             // result stored in ADC1BUF0
}

void main(void)
{
    volatile unsigned long t=0;
    int adcval;
    float voltage;
    char temp[1];

	CFGCON = 0;
  
    UART2Configure(115200, 115200);  // Configure UART2 for a baud rate of 115200
    U2MODESET = 0x8000;
 
    // Configure pins as analog inputs
    ANSELBbits.ANSB3 = 1;   // set RB3 (AN5, pin 7 of DIP28) as analog pin
    TRISBbits.TRISB3 = 1;   // set RB3 as an input
    
	TRISBbits.TRISB6 = 0;
	LATBbits.LATB6 = 0;	
	INTCONbits.MVEC = 1;
 
    ADCConf(); // Configure ADC
 
    printf("*** PIC32 ADC test ***\r\n");
	while(1)
	{
		t++;
		if(t==500000)
		{
        	adcval = ADCRead(5); // note that we call pin AN5 (RB3) by it's analog number
        	voltage=adcval*3.3/1023.0;
        	temp[0] = (voltage-2.73)*100;
        	//printf("%7.3f\r\n", temp);
			SerialTransmit(temp);
        	fflush(stdout);
			t = 0;
			if(temp[0] >= 23.0) {
			LATBbits.LATB6 = 0; // Blink led on RB6
			}
			else {
			LATBbits.LATB6 = 1;
			}
		}
	}
}
