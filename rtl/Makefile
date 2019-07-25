.PHONY: all
all:	soc
CXX   := g++
FBDIR := .
VDIRFB:= $(FBDIR)/obj_dir
RTLDR := ../rtl
VERILATOR := verilator
VFLAGS := -Wall --MMD --trace --trace-params --trace-structs -y $(RTLDR) -cc -Wno-UNDRIVEN -Wno-UNUSED -Wno-WIDTH -CFLAGS "-g"
#VFLAGS := -Wall --MMD -y $(RTLDR) -cc -Wno-UNDRIVEN -Wno-UNUSED -Wno-WIDTH

.PHONY: soc
soc:   $(VDIRFB)/Vsoc__ALL.a

$(VDIRFB)/Vsoc__ALL.a:   $(VDIRFB)/Vsoc.cpp

$(VDIRFB)/V%.mk:  $(VDIRFB)/%.h
$(VDIRFB)/V%.h:   $(VDIRFB)/%.cpp
$(VDIRFB)/V%.cpp: $(FBDIR)/%.v
	$(VERILATOR) $(VFLAGS) $*.v

$(VDIRFB)/V%__ALL.a: $(VDIRFB)/V%.cpp
	cd $(VDIRFB); make -f V$*.mk

tags: $(wildcard *.v) $(wildcard $(RTLDR)/*.v)
	ctags *.v $(RTLDR)/*.v

.PHONY: clean
clean:
	rm -rf tags $(VDIRFB)/

DEPS := $(wildcard $(VDIRFB)/*.d)

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(DEPS),)
include $(DEPS)
endif
endif
