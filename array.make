#######################################################
# array.make
#
# Makefile to produce array of OpenFire processors.
#
# Stephen Douglas Craven  modified 11/18/05
# Virginia Tech
#######################################################

############
# Defaults #
############
ifndef PROJECT
	PROJECT = system
endif
ifndef NUM_NODES
	NUM_NODES = 1
endif
ifndef MB_INSTANCE
	MB_INSTANCE = microblaze_0
endif
ifndef SLAVE_C
	SLAVE_C = code/slave.c
endif
ifndef MASTER_C
	MASTER_C = code/master.c
endif
ifndef MB_SW_APP
	MB_SW_APP = master
endif
ifndef OF_SW_APP
	OF_SW_APP = slave
endif

all:
	@echo " "
	@echo "Makefile to generate OpenFire arrays."
	@echo ""
	@echo " Requires that the Xilinx EDK and Openfire utilities are in your path."
	@echo ""
	@echo " Instructions:"
	@echo "    1) Create an embedded MicroBlaze project from within XPS for the master"
	@echo "           node.  Do not implement this design yet."
	@echo "    2) Copy the OpenFire pcores directory into the project directory."
	@echo "    3) From the project directory, use the following targets to this makefile."
	@echo " "
	@echo " setup     : creates MHS and MSS files with instantiated OpenFire processors"
	@echo " program   : compiles programs"
	@echo " array_gen : generates bitstream"
	@echo " init_bram : initializes BRAMs"
	@echo " download  : puts bitstream on board"
	@echo " clean     : remove all generated files"
	@echo " "
	@echo "Specify options using the following:"
	@echo " NUM_NODES=#          Number of slave OpenFire processors (default of 1)"
	@echo " MASTER_C=file.c      Location of master node program (default: code/master.c)"
	@echo " MB_SW_APP=name       Name of the Master node's SW application in the XPS "
	@echo "                         project (default: master)"	
	@echo " SLAVE_C=file.c       Location of slave node program (default: code/slave.c)"
	@echo " CONSTRAINTS=file.ucf Location of optional area constraints for OpenFires"
	@echo " MB_INSTANCE=name     Name of master MicroBlaze in EDK project "
	@echo "                         (default: microblaze_0)"
	@echo " PROJECT=name         Name of EDK project (default: system)"
	@echo " "

###########
# Targets #
###########
clean:
	rm -rf $(OF_SW_APP)
	rm -f setup_complete
	make -f $(PROJECT).make clean
	mv create_array_bck.mhs $(PROJECT).mhs
	mv create_array_bck.mss $(PROJECT).mss
	
setup: setup_complete

array_gen: implementation/$(PROJECT).bit

program: $(PROJECT).make $(MB_SW_APP)/executable.elf $(OF_SW_APP)/executable.elf
	
init_bram: implementation/download.bit
	
download: implementation/download.bit
	make -f $(PROJECT).make download

################
# Instructions #
################
setup_complete:
	cp  data/$(PROJECT).ucf tmp666.ucf
	cat tmp666.ucf $(CONSTRAINTS) > data/$(PROJECT).ucf
	rm -f tmp666.ucf
	create_array.pl -n $(NUM_NODES) -m $(MB_INSTANCE) -p $(PROJECT)
	echo "dummy file needed for Make... I need more knowledge" > setup_complete

implementation/$(PROJECT).bit: setup_complete $(PROJECT).mhs
	make -f $(PROJECT).make bits
	xdl -ncd2xdl implementation/$(PROJECT).ncd implementation/$(PROJECT).xdl
	
implementation/download.bit: $(OF_SW_APP)/executable.elf $(MB_SW_APP)/executable.elf setup_complete $(PROJECT).mhs implementation/$(PROJECT).xdl
	make -f $(PROJECT).make init_bram
	openfire_bram.pl -t openfire -p $(NUM_NODES) -f $(OF_SW_APP)/executable.elf -n implementation/$(PROJECT).ncd

implementation/$(PROJECT).xdl: implementation/$(PROJECT).bit
	xdl -ncd2xdl implementation/$(PROJECT).ncd implementation/$(PROJECT).xdl

$(OF_SW_APP)/executable.elf: $(SLAVE_C)
	make -f $(PROJECT).make libs
	openfire_util.pl -f $(SLAVE_C) -m -p ./ -n $(MB_INSTANCE)
	mkdir -p $(OF_SW_APP)
	mv of_executable.elf $(OF_SW_APP)/executable.elf

$(MB_SW_APP)/executable.elf: $(MASTER_C)
	make -f $(PROJECT).make program

