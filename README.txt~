OpenFire Processor Version 0.3 Beta

This initial release of the OpenFire processor includes the Verilog RTL source
code with basic integration into the Xilinx EDK flow.  Version 0.3 addresses 
two bugs identified in the version 0.2 code.  One limited the addressible
memory to a maximum of 1/4th the expected value while the other resulted
in occassional incorrect results of the CMP instruction.

This initial release contains everything needed to create a simple OpenFire
system running the Dhrystone benchmark.  The system uses a MicroBlaze as a 
master node to interface with the outside world through a UART.  (The OpenFire
does not currently have an OPB interface and thus must use another processor
like the MicroBlaze to use EDK peripherals.)  The master MicroBlaze controls
the slave OpenFire processor that runs the benchmark.

For updates see:
http://www.ccm.ece.vt.edu/~scraven/

For licence information see:
http://www.opensource.org/licenses/mit-license.php

Included Directories:
docs/		contains OpenFire_v0.3.doc Word file
pcores/		includes Verilog HDL and sundry files needed for EDK to find core 
utils/		contains various scripts for compiling OpenFire code and loading
			BRAMs and a C simulator
code/		Dhrystone 2.1 benchmark C code and C simulator code

Included files:
array.make	Makefile for creating arrays of OpenFires tied to a master MicroBlaze
