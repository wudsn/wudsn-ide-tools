# $Id$
#
# the DASM macro assembler (aka small systems cross assembler)
#
# Copyright (c) 1988-2002 by Matthew Dillon.
# Copyright (c) 1995 by Olaf "Rhialto" Seibert.
# Copyright (c) 2003-2008 by Andrew Davie.
# Copyright (c) 2008 by Peter H. Froehlich.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# Executables will be generated in the trunk/src/ directory (the
# "current directory" as far as this Makefile is concerned). If
# you want to move them somewhere, trunk/bin/ say, do so in the
# trunk/ Makefile!

GOPTI= -O # -O for more warnings; use -O0 for debugging, use -O3 for speed

GWARN= -ansi -std=c99 -pedantic -Wall \
       -Wstrict-prototypes -Wdeclaration-after-statement \
       -Wold-style-definition -Wmissing-declarations -Wmissing-prototypes \
       -Wshadow -Wwrite-strings -Wcast-qual -Wnested-externs \
       -Wcast-align -Wpointer-arith -Wbad-function-cast \
       -Wformat-y2k -Wformat-nonliteral -Wformat-security \
       -Wfloat-equal -Wundef -Winline \
       -Wextra \
       # -Wunused # definition is weird in man gcc, effect is weird too
       # Warnings that only make sense for me once OS X has better gcc
       # -Wtraditional-conversion # prototype conversions gcc 4.3+
       # -Wconversion # sign conversions gcc 4.3+
       # Warnings we turned down after some consideration:
       # -Wunreachable-code # seems to create too many spurious warnings
       # -Wfour-char-constants # Apple OS X only option, not needed anyway?
       # -Wtraditional # we want to be C99 darn it, so we don't care

GDEBG= -g # -fprofile-arcs -ftest-coverage # -pg # -D_FORTIFY_SOURCE=2

CFLAGS= $(GOPTI) $(GWARN) $(GDEBG) -D_BSD_SOURCE # -D_XOPEN_SOURCE=500
CC= gcc

OBJS= main.o ops.o globals.o exp.o symbols.o errors.o util.o \
      mne6303.o mne6502.o mne68705.o mne6811.o mnef8.o
SRCS= main.c ops.c globals.c exp.c symbols.c errors.c util.c \
      mne6303.c mne6502.c mne68705.c mne6811.c mnef8.c

TEST= test_errors test_util

ALL= dasm ftohex ftobin $(TEST)

all: $(ALL)

dasm: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o dasm

symbols.o: symbols.c symbols.h
errors.o: errors.c errors.h
util.o: util.c util.h errors.h

# TODO: are these two lines really needed? GNU make
# seems to build ftohex/ftobin fine without them...
ftohex: ftohex.c
ftobin: ftobin.c

# produce executables for simple unit tests of certain
# modules
test_util: test_util.c util.o errors.o
test_errors: test_errors.c errors.o util.o

obj: $(OBJS)

$(OBJS): asm.h

clean:
	rm -rf *.o $(ALL) \
	dasm-alpha-*.tar.gz \
	*.gcda *.gcno *.gcov gmon.out

cscope:
	ls *.h *.c >cscope.files

splint:
	-splint $(SRCS) | grep "Finished"

# target to test compiles when neither __BSD__ nor __APPLE__ are
# defined
nobsd:
	gcc -U__BSD__ -U__APPLE__ util.c -o util.o -Wall -Wextra -c

# prepare an alpha release containing just the source code,
# nothing else is in the archive since it is not intended
# for the public, just designated volunteers

alpha:
	echo "This is an incomplete alpha release of DASM source code." >README.ALPHA
	echo "The purpose is to identify build problems, nothing more." >>README.ALPHA
	echo "Please do *not* re-distribute this release in any form!" >>README.ALPHA
	echo "Please do *not* distribute binaries derived from it either!" >>README.ALPHA
	echo "See http://dasm-dillon.sf.net/ for details on DASM." >>README.ALPHA
	tar zcvf dasm-alpha-`date +%F`.tar.gz README.ALPHA Makefile *.h *.c *.x
	rm -rf README.ALPHA
