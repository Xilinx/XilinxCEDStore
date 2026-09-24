include Makefile.rtl_vars

LOG?=0
SIM?=questa

help:
	@echo "---Targets"
	@echo "    - c, compile"
	@echo "    - cln, clean"
	@echo "---Options" 
	@echo "    - SIM=[questa,vcs] | default=$(SIM)" 
	@echo "    - LOG=[0,1] | default=$(LOG) ; control whether to keep compilation logfile"

c compile:
ifeq ($(SIM),questa)
	vlog -64 -incr -l vlog.log $(PACKAGES) $(INTFS) $(MODULES) || true
	@rm -rf work
ifeq ($(LOG),0)
	-@tail -n 1 vlog.log | egrep -q -v "[1-9]" && rm vlog.log
endif
else ifeq ($(SIM),vcs)
	@echo "WORK > DEFAULT"  > synopsys_sim.setup
	@echo "DEFAULT : work" > synopsys_sim.setup
	vlogan -full64 -sverilog -l vlogan.log \
      $(PACKAGES) $(INTFS) $(MODULES) || true
	@rm -rf work synopsys_sim.setup
ifeq ($(LOG),0)
	-@tail -n 1 vlogan.log | grep -q "to compile" && rm vlogan.log
endif
endif

cln clean:
	rm -rf v*log work
