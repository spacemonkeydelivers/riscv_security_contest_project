INCLUDE=$(TOP)/include
OBJ_FILES=boot.o isr.o config.o \
	os.o \
	libc-start.o \
	stdlib.o unistd.o string.o
LIBNAME=libc
INSTALL_HEADERS=stdbool.h stdint.h stdlib.h string.h unistd.h soc/traps.h

all: $(LIBNAME).a

tests: $(LIBNAME).a $(TOP)/tests/basic.c
	$(CC) $(CFLAGS) -static -L. -lc $(TOP)/tests/basic.c -o test_basic \
		-T$(TOP)/share/soc.ld -I$(TOP)/include

install: $(LIBNAME).a $(addprefix $(TOP)/include/,$(INSTALL_HEADERS))
	mkdir -p $(INSTALL_DIR)/lib/
	mkdir -p $(INSTALL_DIR)/include/
	mkdir -p $(INSTALL_DIR)/share/
	cp $(LIBNAME).a $(INSTALL_DIR)/lib/
	cp $(addprefix $(TOP)/include/,$(INSTALL_HEADERS)) $(INSTALL_DIR)/include/
	cp -r $(TOP)/share/soc.ld $(INSTALL_DIR)/share/

generated/esf.h: $(TOP)/src/internals/esf.h.erb
	mkdir -p generated && erb -T 1 $(TOP)/src/internals/esf.h.erb >generated/esf.h

isr.o: $(TOP)/src/asm/isr.S generated/esf.h
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

boot.o: $(TOP)/src/asm/boot.S generated/esf.h
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

os.o: $(TOP)/src/internals/os.c generated/esf.h
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -I. -o $@ -c $<

config.o: $(TOP)/src/asm/config.S
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

libc-start.o: $(TOP)/src/libc-start.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

stdlib.o: $(TOP)/src/stdlib.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

string.o: $(TOP)/src/string.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

unistd.o: $(TOP)/src/unistd.c
	$(CC) $(CFLAGS) $(addprefix -I,$(INCLUDE)) -o $@ -c $<

$(LIBNAME).a: $(OBJ_FILES)
	$(AR) rcs $@ $^

.PHONY: clean

clean:
	rm -rf ${BUILD_DIR}/$(OBJ_FILES) ${BUILD_DIR}/$(LIBNAME).a

# End of Makefile

