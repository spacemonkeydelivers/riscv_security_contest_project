INCLUDE=$(TOP)/include
OBJ_FILES=boot.o isr.o config.o libgcc_.o \
	os.o malloc.o security.o \
	libc-start.o printf.o \
	stdlib.o unistd.o string.o
LIBNAME=libc
INSTALL_HEADERS=stdarg.h stdbool.h stddef.h stdint.h stdio.h stdlib.h string.h unistd.h
INSTALL_SOC_HEADERS=traps.h timer.h
INSTALL_MISC_HEADERS=printk.h toolchain.h
INSTALL_SHARE_CONTENT=soc.ld

I_HEADERS     := $(addprefix $(TOP)/include/,$(INSTALL_HEADERS))
I_SOC_HEADERS := $(addprefix $(TOP)/include/soc/,$(INSTALL_SOC_HEADERS))
I_MISC_HEADERS:= $(addprefix $(TOP)/include/misc/,$(INSTALL_MISC_HEADERS))
I_SHARE       := $(addprefix $(TOP)/share/,$(INSTALL_SHARE_CONTENT))
I_STRUCTURE   := $(addprefix $(INSTALL_DIR)/,lib include include/soc include/misc share)
DEPS_INSTALL := $(LIBNAME).a
DEPS_INSTALL += $(I_HEADERS)
DEPS_INSTALL += $(I_SOC_HEADERS)
DEPS_INSTALL += $(I_MISC_HEADERS)
DEPS_INSTALL += $(I_SHARE)

install: $(DEPS_INSTALL)
	install -d $(I_STRUCTURE)
	install -m 644 $(LIBNAME).a $(INSTALL_DIR)/lib
	install -m 644 $(I_HEADERS) $(INSTALL_DIR)/include
	install -m 644 $(I_SOC_HEADERS) $(INSTALL_DIR)/include/soc
	install -m 644 $(I_MISC_HEADERS) $(INSTALL_DIR)/include/misc
	install -m 644 $(I_SHARE) $(INSTALL_DIR)/share

test_program: $(LIBNAME).a $(TOP)/tests/basic.c
	$(CC) $(CFLAGS) $(TOP)/tests/basic.c -static -L. -lc \
		-Xlinker --defsym=__SOC_MEM_SIZE=999999 \
		-T$(TOP)/share/soc.ld -I$(TOP)/include -o test_program

all: $(LIBNAME).a

generated/esf.h: $(TOP)/src/internals/esf.h.erb
	mkdir -p generated && erb -T 1 $(TOP)/src/internals/esf.h.erb >generated/esf.h

libgcc_.o: $(TOP)/src/asm/libgcc.S
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

isr.o: $(TOP)/src/asm/isr.S generated/esf.h
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

boot.o: $(TOP)/src/asm/boot.S generated/esf.h
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

os.o: $(TOP)/src/internals/os.c generated/esf.h
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

malloc.o: $(TOP)/src/internals/malloc.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I.  -I$(TOP)/include -o $@ -c $<

security.o: $(TOP)/src/internals/security.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -I$(TOP)/include -o $@ -c $<

config.o: $(TOP)/src/asm/config.S
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

libc-start.o: $(TOP)/src/libc-start.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

printf.o: $(TOP)/src/printf/printf.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) \
		-DPRINTF_DISABLE_SUPPORT_LONG_LONG -DPRINTF_DISABLE_SUPPORT_FLOAT -o $@ -c $<

stdlib.o: $(TOP)/src/stdlib.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

string.o: $(TOP)/src/string.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

unistd.o: $(TOP)/src/unistd.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

$(LIBNAME).a: $(OBJ_FILES)
	$(AR) rcs $@ $^

# ar -rcT libaz.a ../build/distrib/tools/lib/libc.a /tank/work/dev/toolchains/riscv32-newlib-gcc/lib/gcc/riscv32-unknown-elf/8.3.0/libgcc.a
.PHONY: clean

clean:
	rm -rf ${BUILD_DIR}/$(OBJ_FILES) ${BUILD_DIR}/$(LIBNAME).a

# End of Makefile

