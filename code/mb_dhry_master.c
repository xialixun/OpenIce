/********************************************************************
 * MicroBlaze Master Control Program for Dhrystone Benchmark
 *
 * Stephen Douglas Craven -- Virginia Tech
 * 8/16/2005
 *
 * This program initiates, times, and verifies proper operation
 * of the Dhrystone 2.1 Benchmark running on an attached MicroBlaze
 * or OpenFire processor connected to FSL0.  The Slave processor
 * Must be running mb_dhrystone_slave.c.
 *
 * NOTES:
 *  - Master Processor must have an OPB Timer Attached
 *  - Adjust the Clock frequency define statement to match the actual
 ********************************************************************/

/***********************************************
 * Edit this to the correct frequency in Hertz *
 ***********************************************/
#define CLOCK_FREQ 100000000

#include "mb_interface.h"	// Needed for FSL interface
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <xparameters.h>
#include <xbasic_types.h>
#include <xstatus.h>
#include <xtmrctr.h>		// Needed for timer

int main(void)
{
	int 	num_runs, my_time, value, tmp;
	int correct_response[32] = {5, 1, 0x41, 0x42, 7, 666, 0, 2, 0x11, 0, 1, 0x12, 5, 0xd, 7, 1};
	int 	get_input;
	char	character;
	char	string[31];
	XTmrCtr timer;

		// Initialize timer
		XTmrCtr_Initialize( &timer, XPAR_OPB_TIMER_1_DEVICE_ID);

	while(1)
	{
		xil_printf("\r\nDhrystone 2.1 Benchmark for the OpenFire.\r\n");
		xil_printf("Enter # (1-9) of Runs (x 10).  For example, \'3\' => 30 runs.\r\n");
		get_input = getchar();
		num_runs = 10 * (get_input - 48);

		xil_printf("Starting %d runs.\r\n", num_runs);
		microblaze_bwrite_cntlfsl(num_runs, 0);

		// Start timer
		XTmrCtr_Start( &timer, 0);

		// Slave Runs Dhrystone Benchmark

		// Stop timer
		microblaze_bread_cntlfsl(value, 0);
		my_time = XTmrCtr_GetValue( &timer, 0);

		// Test return values to verify successful completion
		if(value == (0x666 + num_runs)) {
			xil_printf("Test Completed in %d Clock Cycles, producing %d DMIPS\r\n", my_time, ( CLOCK_FREQ / (my_time/num_runs) ) / 1857);

			for (tmp = 0; tmp < 16; tmp++) {
				microblaze_bread_cntlfsl(value, 0);
				if (correct_response[tmp] != 666) {
					if(value != correct_response[tmp])
						xil_printf("### ERROR!  Benchmark failed! ### Test Number = %d\r\n", tmp);
				} else {
					if(value != num_runs + 10)
						xil_printf("### ERROR!  Benchmark failed! ### Test Number = %d\r\n", tmp);
				}
			}

	  		for(tmp = 0; tmp < 30; tmp++) {
		 		microblaze_bread_cntlfsl(value, 0);
				character = (char) value;
				memcpy(&string[tmp], &character, 1);
	  		}
			string[30] = '\0';
			//xil_printf("Ptr_Glob->variant.var_1.Str_Comp correct = %d\r\n", (1 - strcmp(string,"DHRYSTONE PROGRAM, SOME STRING")));
			if((1 - strcmp(string,"DHRYSTONE PROGRAM, SOME STRING")) != 1)
				xil_printf("### ERROR!  Benchmark failed! ###\r\n");

	  		for(tmp = 0; tmp < 30; tmp++) {
		 		microblaze_bread_cntlfsl(value, 0);
				character = (char) value;
				memcpy(&string[tmp], &character, 1);
	  		}
			string[30] = '\0';
			//xil_printf("Next_Ptr_Glob->variant.var_1.Str_Comp correct = %d\r\n", (1 - strcmp(string,"DHRYSTONE PROGRAM, SOME STRING")));
			if((1 - strcmp(string,"DHRYSTONE PROGRAM, SOME STRING")) != 1)
				xil_printf("### ERROR!  Benchmark failed! ###\r\n");

	  		for(tmp = 0; tmp < 30; tmp++) {
		 		microblaze_bread_cntlfsl(value, 0);
				character = (char) value;
				memcpy(&string[tmp], &character, 1);
	  		}
			string[30] = '\0';
			//xil_printf("Str_1_Loc correct = %d\r\n", (1 - strcmp(string,"DHRYSTONE PROGRAM, 1'ST STRING")));
			if((1 - strcmp(string,"DHRYSTONE PROGRAM, 1'ST STRING")) != 1)
				xil_printf("### ERROR!  Benchmark failed! ###\r\n");

	  		for(tmp = 0; tmp < 30; tmp++) {
		 		microblaze_bread_cntlfsl(value, 0);
				character = (char) value;
				memcpy(&string[tmp], &character, 1);
	  		}
			string[30] = '\0';
			//xil_printf("Str_2_Loc correct = %d\r\n", (1 - strcmp(string,"DHRYSTONE PROGRAM, 2'ND STRING")));
			if((1 - strcmp(string,"DHRYSTONE PROGRAM, 2'ND STRING")) != 1)
				xil_printf("### ERROR!  Benchmark failed! ###\r\n");

		} else {
			xil_printf("Test Completed but bad value of 0x%x returned\r\n", value);
		}
	} // End While 4ever loop
}
