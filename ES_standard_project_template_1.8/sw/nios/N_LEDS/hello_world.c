#include <inttypes.h>
#include "io.h"
#include "system.h"
#include <unistd.h>

#define NU_OF_LED_OFFSET	0
#define REFRESH_OFFSET 		4
#define LED_OFFSET 			8
#define NU_OF_BYTES_PER_LED 4
#define MAX_NUM_LEDS		12

/*
 * wait: sleep for given time
 * 	- sleep_time: defines sleeping time in ms
 */
void wait(uint16_t sleep_time)
{
	usleep(1000*sleep_time);
}

/*
 * init_leds: initialises leds and turns all off
 * 	- refresh_time: defines time before next refresh in us
 * 	  -> in theory min. refresh time = 50us (see datasheet), in practice refresh
 * 	     time < 60us is not recommended because it may be unstable
 *    -> max. refresh time = 1310us because converted value is limited by 2 bytes
 *    -> convert refresh time into system cycles: clk_frequency=50MHz -> clk_periode=20ns ->
 *       nb. of cycles = refresh_time(in ms)*1000/clk_periode = refresh_time(in ms)*50
 */
void init_leds(uint16_t refresh_time)
{
	// set number of leds to maximum
	IOWR_32DIRECT(N_LEDS_CONTROLLER_0_BASE, NU_OF_LED_OFFSET, MAX_NUM_LEDS);

	// convert refresh time from us in nb. of cycles and set it
	refresh_time = refresh_time*50;
	IOWR_32DIRECT(N_LEDS_CONTROLLER_0_BASE, REFRESH_OFFSET, refresh_time);

	// turn all leds off
	uint32_t colours_off = 0x00000000;
	for (int j = 0; j< MAX_NUM_LEDS; j++) {
		IOWR_32DIRECT(N_LEDS_CONTROLLER_0_BASE, LED_OFFSET + NU_OF_BYTES_PER_LED*j, colours_off);
	}

	// wait a small amount of time and do nothing until leds are reset
	wait(10); // sleep 10ms
}

/*
 * main: initialise leds and display colours array (always shifting leds by one position)
 */
int main()
{
	//colour code: nothing-green-red-blue (1 byte each)
	uint32_t colours[12] = { 0x00000000, 0x00A5FF00, 0x008CFF00, 0x0045FF00,
							 0x0000FF00, 0x0014DC3C, 0x00008000, 0x00008B8B,
							 0x002B8AE2, 0x00000080, 0x000000FF, 0x00000000};

	// init. leds
	uint16_t refresh_time =	200; // in us
	init_leds(refresh_time);

	// set number of leds displayed
	uint8_t num_of_leds = MAX_NUM_LEDS;
	IOWR_32DIRECT(N_LEDS_CONTROLLER_0_BASE, NU_OF_LED_OFFSET, num_of_leds);

	// define temporary variable for led shift
	uint32_t temp_colour;
	while(1) {
		// Write sequence to leds
		temp_colour = colours[num_of_leds-1];
		for (int j = num_of_leds-1; j >= 0; j--) {
			// Shift sequence by one led
			if(j == 0) {
				colours[j] = temp_colour;
			} else {
				colours[j] = colours[j-1];
			}
			IOWR_32DIRECT(N_LEDS_CONTROLLER_0_BASE, LED_OFFSET + NU_OF_BYTES_PER_LED*j, colours[j]);
		}

		// wait a little bit before shifting again
		wait(200); // sleep 100ms
	}

	return 0;
}
