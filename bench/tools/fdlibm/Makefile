#
#  @(#)Makefile 1.4 95/01/18 
# 
#  ====================================================
#  Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
# 
#  Developed at SunSoft, a Sun Microsystems, Inc. business.
#  Permission to use, copy, modify, and distribute this
#  software is freely granted, provided that this notice 
#  is preserved.
#  ====================================================
# 
# 

#
# There are two options in making libm at fdlibm compile time:
# 	_IEEE_LIBM 	--- IEEE libm; smaller, and somewhat faster
#	_MULTI_LIBM	--- Support multi-standard at runtime by 
#			    imposing wrapper functions defined in 
#			    fdlibm.h:
#				_IEEE_MODE 	-- IEEE
#				_XOPEN_MODE 	-- X/OPEN
#				_POSIX_MODE 	-- POSIX/ANSI
#				_SVID3_MODE 	-- SVID
#
# Here is how to set up CFLAGS to create the desired libm at 
# compile time:
#
# 	CFLAGS = -D_IEEE_LIBM		... IEEE libm (recommended)
#	CFLAGS = -D_SVID3_MODE	... Multi-standard supported
#					    libm with SVID as the 
#					    default standard
#	CFLAGS = -D_XOPEN_MODE	... Multi-standard supported
#					    libm with XOPEN as the 
#					    default standard
#	CFLAGS = -D_POSIX_MODE	... Multi-standard supported
#					    libm with POSIX as the 
#					    default standard
#	CFLAGS = 			... Multi-standard supported
#					    libm with IEEE as the 
#					    default standard
# 
# NOTE: if scalb's second arguement is an int, then one must
# define _SCALB_INT in CFLAGS. The default prototype of scalb
# is double scalb(double, double)
#


#
# Default IEEE libm
#
CFLAGS = -D_IEEE_LIBM $(C_FLAGS)

CC = $(C_COMPILER)

INCFILES = fdlibm.h
.INIT: $(INCFILES)
.KEEP_STATE:
src = 	k_standard.c k_rem_pio2.c \
	k_cos.c k_sin.c k_tan.c \
	e_acos.c e_acosh.c e_asin.c e_atan2.c \
	e_atanh.c e_cosh.c e_exp.c e_fmod.c \
	e_gamma.c e_gamma_r.c e_hypot.c e_j0.c \
	e_j1.c e_jn.c e_lgamma.c e_lgamma_r.c \
	e_log.c e_log10.c e_pow.c e_rem_pio2.c e_remainder.c \
	e_scalb.c e_sinh.c e_sqrt.c \
	w_acos.c w_acosh.c w_asin.c w_atan2.c \
	w_atanh.c w_cosh.c w_exp.c w_fmod.c \
	w_gamma.c w_gamma_r.c w_hypot.c w_j0.c \
	w_j1.c w_jn.c w_lgamma.c w_lgamma_r.c \
	w_log.c w_log10.c w_pow.c w_remainder.c \
	w_scalb.c w_sinh.c w_sqrt.c \
	s_asinh.c s_atan.c s_cbrt.c s_ceil.c s_copysign.c \
	s_cos.c s_erf.c s_expm1.c s_fabs.c s_finite.c s_floor.c \
	s_frexp.c s_ilogb.c s_isnan.c s_ldexp.c s_lib_version.c \
	s_log1p.c s_logb.c s_matherr.c s_modf.c s_nextafter.c \
	s_rint.c s_scalbn.c s_signgam.c s_significand.c s_sin.c \
	s_tan.c s_tanh.c

SOURCES := $(addprefix $(TOP)/,$(src))
OBJECTS := $(patsubst $(TOP)/%,%,$(SOURCES:.c=.o))

%.o: $(TOP)/%.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<

all: libm.a 

libm.a : $(OBJECTS) 
	$(AR) cru libm.a $(OBJECTS)
	$(AR) s libm.a

install : libm.a $(TOP)/fdlibm.h
	install -d $(INSTALL_DIR)/lib $(INSTALL_DIR)/include
	install -m 644 libm.a $(INSTALL_DIR)/lib
	install -m 644 $(TOP)/fdlibm.h $(INSTALL_DIR)/include/math.h


clean: 
	/bin/rm -f $(OBJECTS) a.out libm.a

