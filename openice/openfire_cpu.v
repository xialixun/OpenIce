/*

MODULE: openfire_cpu

DESCRIPTION: This is the top module for the openfire processor, instantiating
the fetch, decode, execute, pipeline_ctrl, and register file modules.

AUTHOR: 
Stephen Douglas Craven
Configurable Computing Lab
Virginia Tech
scraven@vt.edu

REVISION HISTORY:
Revision 0.2, 8/10/2005 SDC
Initial release

Revision 0.3, 12/17/2005 SDC
Fixed PC size bug

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


`ifdef FSL_LINK
// pc is output to create FSL_debug port at the next level up
module openfire_cpu (
	clock, reset, stall,					// inputs
	dmem_data_in, imem_data_in,
	fsl_s_data, fsl_s_control, fsl_s_exists, fsl_m_full,	// FSL
	dmem_addr, imem_addr, dmem_data_out, dmem_we, pc,	// outputs
	fsl_m_data, fsl_m_control, fsl_m_write, fsl_s_read);	// FSL
`else
module openfire_cpu (
	clock, reset, stall,					// inputs
	dmem_data_in, imem_data_in,
	dmem_addr, imem_addr, dmem_data_out, dmem_we);		// outputs
`endif

input		clock;
input		reset;
input		stall;
input	[31:0]	dmem_data_in;
input	[31:0]	imem_data_in;

`ifdef FSL_LINK
input	[31:0]	fsl_s_data;
input		fsl_s_control;
input		fsl_s_exists;
input		fsl_m_full;

output	[31:0]	fsl_m_data;
output		fsl_m_control;
output		fsl_m_write;
output		fsl_s_read;

output	[31:0]	pc;
`endif

output	[31:0]	dmem_data_out;
output	[31:0]	dmem_addr;
output	[31:0]	imem_addr;
output		dmem_we;

wire	[31:0]	dmem_addr_internal;
wire		branch_taken;
wire	[`A_SPACE+1:0]	pc_branch;
wire	[`A_SPACE+1:0]	pc_decode;
wire	[`A_SPACE+1:0]	pc_exe_rf;
wire	[31:0]	instruction;
wire	[4:0]	regA_addr;
wire	[4:0]	regB_addr;
wire	[4:0]	regD_addr;
wire	[`D_WIDTH-1:0]	immediate;

wire	[1:0]	alu_inputA_sel;
wire	[1:0]	alu_inputB_sel;
wire	[1:0]	alu_inputC_sel;
wire	[3:0]	alu_fns_sel;
wire	[2:0]	comparator_fns_sel;
wire		we_alu_branch;
wire		we_load;
wire		we_store;
wire	[2:0]	regfile_input_sel;
wire	[1:0]	dmem_input_sel;
wire		delay_bit;
wire	[`D_WIDTH-1:0]	result;

wire	[`D_WIDTH-1:0]	regA;
wire	[`D_WIDTH-1:0]	regB;
wire	[`D_WIDTH-1:0]	regD;
wire		we_load_dly;
wire		we_store_dly;
wire		update_carry;
wire		stall_exe;
wire		stall_decode;
wire		stall_fetch;
wire		instr_complete;
wire		flush;
wire		branch_instr;
wire	[1:0]	byte_sel;

`ifdef FSL_LINK
wire		fsl_get;
wire		fsl_cmd_vld;
wire		fsl_control;
wire		fsl_blocking;
`endif

assign dmem_we = we_store_dly;
assign dmem_addr = { 2'b0, dmem_addr_internal[31:2]};

openfire_fetch	FETCH ( .stall(stall_fetch), .clock(clock), 
	.reset(reset), .branch_taken(branch_taken), 
	.pc_branch(pc_branch), .idata(imem_data_in), .imem_addr(imem_addr),
	.pc_decode(pc_decode), .instruction(instruction));

`ifdef FSL_LINK
assign fsl_m_data = {{(32-`D_WIDTH){1'b0}},regA}; // zero pad FSL to 32-bits
assign pc = {{(32-`A_SPACE+2){1'b0}}, pc_exe_rf};

openfire_decode	DECODE (.clock(clock), .stall(stall_decode),
	.reset(reset), .pc_decode(pc_decode), .instruction(instruction), 
	.regA_addr(regA_addr), 
	.regB_addr(regB_addr), .regD_addr(regD_addr), 
	.immediate(immediate), .pc_exe(pc_exe_rf),	
	.alu_inputA_sel(alu_inputA_sel), .alu_inputB_sel(alu_inputB_sel), 
	.alu_inputC_sel(alu_inputC_sel), .alu_fns_sel(alu_fns_sel), 
	.comparator_fns_sel(comparator_fns_sel), .branch_instr(branch_instr),
	.we_alu_branch(we_alu_branch), .we_load(we_load), 
	.we_store(we_store), .regfile_input_sel(regfile_input_sel), 
	.dmem_input_sel(dmem_input_sel), .flush(flush), 
	.delay_bit(delay_bit), .update_carry(update_carry),
	.fsl_get(fsl_get), .fsl_control(fsl_control), 
	.fsl_blocking(fsl_blocking), .fsl_cmd_vld(fsl_cmd_vld));
	
openfire_execute 	EXECUTE (.clock(clock), .reset(reset), 
	.stall(stall_exe), .immediate(immediate), 
	.pc_exe(pc_exe_rf), .alu_inputA_sel(alu_inputA_sel),
	.alu_inputB_sel(alu_inputB_sel), .alu_inputC_sel(alu_inputC_sel),
	.alu_fns_sel(alu_fns_sel), .comparator_fns_sel(comparator_fns_sel),	
	.we_load(we_load), .we_store(we_store), .update_carry(update_carry),
	.regA(regA), .regB(regB), .regD(regD), .alu_result(result), 
        .pc_branch(pc_branch), .branch_taken(branch_taken), .dmem_input_sel(dmem_input_sel), 	
	.we_regfile(we_load_dly), .we_store_dly(we_store_dly),
	.dmem_addr(dmem_addr_internal), .dmem_data_in(dmem_data_in),
	.dmem_data_out(dmem_data_out), .instr_complete(instr_complete),
	.fsl_m_control(fsl_m_control), .fsl_m_write(fsl_m_write), .byte_sel(byte_sel),
	.fsl_s_read(fsl_s_read), .fsl_cmd_vld(fsl_cmd_vld), .fsl_get(fsl_get),
	.fsl_blocking(fsl_blocking), .fsl_control(fsl_control), .fsl_s_exists(fsl_s_exists),
	.fsl_m_full(fsl_m_full), .branch_instr(branch_instr), .fsl_s_control(fsl_s_control));
	
openfire_regfile 	REGFILE (.reset(reset), .clock(clock), .regA_addr(regA_addr),
	.regB_addr(regB_addr), .regD_addr(regD_addr), .result(result),
	.pc_regfile(pc_exe_rf), .dmem_data(dmem_data_in),
	.regfile_input_sel(regfile_input_sel), .we_load_dly(we_load_dly),
	.we_alu_branch(we_alu_branch), .regA(regA), .regB(regB), .regD(regD),
	.enable(~stall_exe), .dmem_addr_lsb(byte_sel), .fsl_s_data(fsl_s_data));
`else
openfire_decode	DECODE (.clock(clock), .stall(stall_decode),
	.reset(reset), .pc_decode(pc_decode), .instruction(instruction), 
	.regA_addr(regA_addr), 
	.regB_addr(regB_addr), .regD_addr(regD_addr), 
	.immediate(immediate), .pc_exe(pc_exe_rf),	
	.alu_inputA_sel(alu_inputA_sel), .alu_inputB_sel(alu_inputB_sel), 
	.alu_inputC_sel(alu_inputC_sel), .alu_fns_sel(alu_fns_sel), 
	.comparator_fns_sel(comparator_fns_sel), 
	.we_alu_branch(we_alu_branch), .we_load(we_load), 
	.we_store(we_store), .regfile_input_sel(regfile_input_sel), 
	.dmem_input_sel(dmem_input_sel), .flush(flush),  .branch_instr(branch_instr),
	.delay_bit(delay_bit), .update_carry(update_carry));
	
openfire_execute 	EXECUTE (.clock(clock), .reset(reset), 
	.stall(stall_exe), .immediate(immediate), 
	.pc_exe(pc_exe_rf), .alu_inputA_sel(alu_inputA_sel),
	.alu_inputB_sel(alu_inputB_sel), .alu_inputC_sel(alu_inputC_sel),
	.alu_fns_sel(alu_fns_sel), .comparator_fns_sel(comparator_fns_sel),	
	.we_load(we_load), .we_store(we_store), .update_carry(update_carry),
	.regA(regA), .regB(regB), .regD(regD), .alu_result(result), 
        .pc_branch(pc_branch), .branch_taken(branch_taken), .dmem_input_sel(dmem_input_sel), 	
	.we_regfile(we_load_dly), .we_store_dly(we_store_dly), .branch_instr(branch_instr),
	.dmem_addr(dmem_addr_internal), .dmem_data_in(dmem_data_in), .byte_sel(byte_sel),
	.dmem_data_out(dmem_data_out), .instr_complete(instr_complete));
	
openfire_regfile 	REGFILE (.reset(reset), .clock(clock), .regA_addr(regA_addr),
	.regB_addr(regB_addr), .regD_addr(regD_addr), .result(result),
	.pc_regfile(pc_exe_rf), .dmem_data(dmem_data_in),
	.regfile_input_sel(regfile_input_sel), .we_load_dly(we_load_dly),
	.we_alu_branch(we_alu_branch), .regA(regA), .regB(regB), .regD(regD),
	.enable(~stall_exe), .dmem_addr_lsb(byte_sel));
`endif

openfire_pipeline_ctrl PIPELINE (.clock(clock), .reset(reset), .stall(stall), .flush(flush),	
	.branch_taken(branch_taken), .instr_complete(instr_complete), .delay_bit(delay_bit),	
	.stall_fetch(stall_fetch), .stall_decode(stall_decode), .stall_exe(stall_exe));	
	
endmodule
