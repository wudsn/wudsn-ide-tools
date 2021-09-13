/*
    $Id$

    the DASM macro assembler (aka small systems cross assembler)

    Copyright (c) 1988-2002 by Matthew Dillon.
    Copyright (c) 1995 by Olaf "Rhialto" Seibert.
    Copyright (c) 2003-2008 by Andrew Davie.
    Copyright (c) 2008 by Peter H. Froehlich.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

/**
 * @file
 */

/*
 *  FTOHEX.C
 *
 *  FTOHEX format infile [outfile]
 *
 *  format: format used when assembling (asm705/asm65)
 *	    1,2,3	    -generate straight hex file
 */

/*
    NOTE: Applying ">>" to a signed left operand is not portable as
    it is undefined whether sign-extension is used or not [1]. We
    apply ">>" only to unsigned operands here, but since severe
    signed/unsigned confusion is part of DASM history, we also take
    precautions by doing some masking that may seem crazy to the
    casual reader. (Also, splint is *wrong* about "<<" causing
    similar trouble, it does not [1].) [phf]

    [1] Harbison, Steele: C: A Reference Manual, 4th edition,
        Prentice Hall, 1995; page 205+. (As far as I know, C99
        didn't mess with ">>" at all.)
*/

#include "version.h"

#include <assert.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

/*@unused@*/
SVNTAG("$Id$");

#define PERLINE 16

static void convert(int format, FILE *in, FILE *out);
static uint16_t get_word(FILE *in);
static void put_hex(uint8_t c, FILE *out);
/* TODO: maybe the warning flags *are* a bit too strong... */
static void exit_error(const char *str);
static void usage_exit(void);

int
main(int argc, char **argv)
{
    int format;
    FILE *infile;
    FILE *outfile;

    /* ensure at least 2 but at most 3 arguments! */
    if (argc < 3 || argc > 4)
    {
        usage_exit();
    }
    format = (int) strtol(argv[1], (char **)NULL, 10);
    /* TODO: error check strtol? doesn't matter much as 0 is not valid... */
    if (format < 1 || format > 3)
	exit_error("specify infile format 1, 2, or 3");
    infile = fopen(argv[2], "r");
    if (infile == NULL)
	exit_error("unable to open input file");
    /* Matt had (argv[3]) as condition, but that's ISO only [phf] */
    outfile = (argc == 4) ? fopen(argv[3], "w") : stdout;
    if (outfile == NULL)
	exit_error("unable to open output file");
    convert(format, infile, outfile);
    /* TODO: make configurable for sanity */
    putc('z'&0x1F, outfile); /* needed for old EPROM programmers! */
    fclose(infile);
    fclose(outfile); /* TODO: could close stdout, is that a problem? */

    return EXIT_SUCCESS;
}

/**
 * @brief Abort with error message.
 */
static
void
exit_error(const char *str)
{
    assert(str != NULL);
    fprintf(stderr, "error: %s\n", str);
    exit(EXIT_FAILURE);
}

/**
 * @brief Abort with usage message.
 */
static
void
usage_exit(void)
{
    (void) puts(DASM_ID);
    DASM_PRINT_LEGAL
    (void) puts("");
    (void) puts("Usage: ftohex format infile [outfile]");
    (void) puts("              format 1, 2, or 3 (raw).");
    (void) puts("");
    DASM_PRINT_BUGS
    exit(EXIT_FAILURE);
}

/*
 *  Formats:
 *
 *  1:  origin (word:lsb,msb) + data
 *  2:  origin (word:lsb,msb) + length (word:lsb,msb) + data  (repeat)
 *  3:  data
 *
 *  Hex output:
 *
 *  :lloooo00(ll bytes hex code)cc      ll=# of bytes
 *                                      oooo=origin
 *                                      cc=invert of checksum all codes
 */

static
void
convert(int format, FILE *in, FILE *out)
{
    /* TODO: rewrite this to new understanding of code and process! */
    uint16_t org = 0;
    unsigned int idx;
    uint16_t len;
    unsigned char buf[256];

    if (format < 3)
    {
        org = get_word(in);
    }
    if (format == 2)
    {
        len = get_word(in);
    }
    else
    {
        /* TODO: refactor! */
	long begin = ftell(in);
	fseek(in, 0, SEEK_END);
	len = ftell(in) - begin;
	fseek(in, begin, 0);
    }
    for (;;) {
	while (len > 0) {
	    register unsigned char chk;
	    register unsigned int i;

	    idx = (len > PERLINE) ? PERLINE : len;
	    fread(buf, idx, 1, in);
	    putc(':', out);
	    put_hex(idx, out);
	    put_hex(org >> 8, out);
	    put_hex(org & 0xFF, out);
	    putc('0', out);
	    putc('0', out);
	    chk = idx + (org >> 8) + (org & 0xFF);
	    for (i = 0; i < idx; ++i) {
		chk += buf[i];
		put_hex(buf[i], out);
	    }
	    put_hex((unsigned char)-chk, out);
            /* TODO: make configurable according to spec */
	    putc('\r', out);
	    putc('\n', out);
	    len -= idx;
	    org += idx;
	}
	if (format == 2) {
	    org = get_word(in);
	    if (feof(in))
		break;
	    len = get_word(in);
	} else {
	    break;
	}
    }
    fprintf(out, ":00000001FF\r\n");
}

/**
 * @brief Read 16-bit word (in format "lsb, msb") from (binary)
 * stream "in".
 */
static
uint16_t
get_word(FILE *in)
{
    uint16_t result = 0;
    int buffer = EOF;

    if ((buffer = getc(in)) == EOF)
    {
        exit_error("Unexcepted end of input file!");
    }
    result |= (buffer & 0xFF); /* mask out high bits, just in case */

    if ((buffer = getc(in)) == EOF)
    {
        exit_error("Unexcepted end of input file!");
    }
    result |= (buffer & 0xFF) << 8; /* mask out high bits, shift to high */

    return result;
}

/**
 * @brief Write 8-bit byte "c" to (text) stream "out" as two
 * ASCII hex digits (high nibble, low nibble of course).
 */
static
void
put_hex(uint8_t c, FILE *out)
{
    static const char digits[] = {"0123456789ABCDEF"};

    /* shift high to low, mask (>> portability, see above), write high digit */
    if (putc(digits[(c >> 4) & 0x0F], out) == EOF)
    {
        exit_error("Couldn't write to output file!");
    }

    /* mask out high, write low digit */
    if (putc(digits[c & 0x0F], out) == EOF)
    {
        exit_error("Couldn't write to output file!");
    }
}

/* vim: set tabstop=4 softtabstop=4 expandtab shiftwidth=4 autoindent: */
