/*

MODULE: openfire_top_syn

DESCRIPTION: This is the top level module for synthesis.  A single, joint 
memory is used for both instructions and data.  This memory is a Xilinx 
coregen generated BRAM component.  However, any synchronous dual-port memory
would work.

AUTHOR: 
Stephen Douglas Craven
Configurable Computing Lab
Virginia Tech
scraven@vt.edu

REVISION HISTORY:
Revision 0.2, 8/10/2005 SDC
Initial release

COPYRIGHT:
Copyright (c) 2005 Stephen Douglas Craven

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.

*/


module openfire_top_syn (
	clock, reset,
//	FSL_Clk, FSL_Rst,
	FSL_S_DATA, FSL_S_CONTROL, FSL_S_EXISTS, FSL_M_FULL,
	FSL_M_DATA, FSL_M_CONTROL, FSL_M_WRITE, FSL_S_READ,
	FSL_M_CLK, FSL_S_CLK,
	FSL_M_DATA_DBG, FSL_M_CONTROL_DBG, FSL_M_WRITE_DBG, FSL_M_FULL_DBG,
	FSL_M_CLK_DBG);

input		clock;
input		reset;

//input		FSL_Clk;
//input		FSL_Rst;

`ifdef FSL_LINK
input	[31:0]	FSL_S_DATA;
input		FSL_S_CONTROL;
input		FSL_S_EXISTS;
input		FSL_M_FULL;

output	[31:0]	FSL_M_DATA;
output		FSL_M_CONTROL;
output		FSL_M_WRITE;
output		FSL_S_READ;

output		FSL_M_CLK;
output		FSL_S_CLK;

// Debug Outputs
input		FSL_M_FULL_DBG;
output	[31:0]	FSL_M_DATA_DBG;
output		FSL_M_CONTROL_DBG;
output		FSL_M_WRITE_DBG;
output		FSL_M_CLK_DBG;

`endif

wire	[31:0]	imem_data;
wire	[31:0]	imem_addr;
wire	[31:0]	dmem_data2mem;
wire	[31:0]	dmem_data2cpu;
wire	[31:0]	dmem_addr;
wire		dmem_we;
wire		stall;

wire		reset_correct_polarity;
//wire		clock;
//wire		reset;

//assign clock = FSL_Clk;
//assign reset = FSL_Rst;

// Determine polarity (active high or low) or core reset
`ifdef RESET_ACTIVE_LOW
assign reset_correct_polarity = ~reset;
`else
assign reset_correct_polarity = reset;
`endif

`ifdef FSL_LINK

assign FSL_S_CLK = clock;
assign FSL_M_CLK = clock;
assign FSL_M_CLK_DBG = clock;

assign FSL_M_CONTROL_DBG = 1'b0;

// debugging only... force PC outside
assign FSL_M_WRITE_DBG = ~FSL_M_FULL_DBG;
assign stall = 1'b0;

openfire_cpu	OPENFIRE0 (.clock(clock), .reset(reset_correct_polarity), .stall(stall),
	.dmem_data_in(dmem_data2cpu), .imem_data_in(imem_data),
	.dmem_addr(dmem_addr), .imem_addr(imem_addr), 
	.dmem_data_out(dmem_data2mem), .dmem_we(dmem_we), .pc(FSL_M_DATA_DBG), // PC added for debugging
	.fsl_s_data(FSL_S_DATA), .fsl_s_control(FSL_S_CONTROL), .fsl_s_exists(FSL_S_EXISTS), .fsl_m_full(FSL_M_FULL),
	.fsl_m_data(FSL_M_DATA), .fsl_m_control(FSL_M_CONTROL), .fsl_m_write(FSL_M_WRITE), .fsl_s_read(FSL_S_READ));
`else
openfire_cpu	OPENFIRE0 (.clock(clock), .reset(reset_correct_polarity), .stall(stall),
	.dmem_data_in(dmem_data2cpu), .imem_data_in(imem_data),
	.dmem_addr(dmem_addr), .imem_addr(imem_addr), 
	.dmem_data_out(dmem_data2mem), .dmem_we(dmem_we));
`endif

openfire_dual_sram MEM(
        .read_addr(imem_addr[`IM_SIZE - 1:0]),
        .write_addr(dmem_addr[`DM_SIZE - 1:0]),
        .clock(~clock), // see explanation below
        .wr_clock(clock),
        .data_in(dmem_data2mem),
        .data_out(imem_data),
        .wr_data_out(dmem_data2cpu),
        .we(dmem_we),
	.enable(1'b1));

// In order to complete instruction Fetch in a single cycle, the read clock
// on the instruction port is inverted.  During the first phase of the Fetch
// stage, the PC is supplied to the memory address bus.  At the falling edge
// of the clock, this address is clocked into the instruction memory.  During
// the second Fetch stage phase the memory fetchs the instruction and places
// it on the data bus.  On the next rising edge, the instruction word is
// clocked in and decoded.

endmodule
