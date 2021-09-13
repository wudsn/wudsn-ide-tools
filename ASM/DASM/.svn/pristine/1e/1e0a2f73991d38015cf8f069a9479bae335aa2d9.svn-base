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

#include "asm.h"
#include "errors.h"
#include "version.h"

#include <assert.h>

/*@unused@*/
SVNTAG("$Id$");

MNEMONIC    *MHash[MHASHSIZE];   /*	mnemonic hash table */
INCFILE *pIncfile;	    /*	include file stack  */
REPLOOP *Reploop;	    /*	repeat loop stack   */
SEGMENT *Seglist;	    /*	segment list	    */
SEGMENT *Csegment;	    /*	current segment     */
IFSTACK *Ifstack;	    /*	IF/ELSE/ENDIF stack */
char	*Av[256];	    /*	up to 256 arguments */
char	Avbuf[512];
bool MsbOrder = true;
int	Mnext;
unsigned int	Mlevel;
unsigned long	Localindex;	   /*  to generate local variables */
unsigned long	Lastlocalindex;

unsigned long	Localdollarindex;
unsigned long	Lastlocaldollarindex;

bool bTrace = false;

unsigned long   Redo_why = 0;
int	Redo_eval = 0;	   /*  infinite loop detection only    */
int Redo = 0;


unsigned long	Redo_if = 0;

bool	ListMode = true;
unsigned long	CheckSum;	    /*	output data checksum		*/

int F_format = FORMAT_DEFAULT;

int F_verbose;
const char	*F_outfile = "a.out";
/*@null@*/ char	*F_listfile;
/*@null@*/ FILE	*FI_listfile;
FILE	*FI_temp;
bool Fisclear;
unsigned long Plab;
dasm_flag_t Pflags;

/*unsigned int	Adrbytes[]  = { 1, 2, 3, 2, 2, 2, 3, 3, 3, 2, 2, 2, 3, 1, 1, 2, 3 };*/
static address_mode_t Cvt[]	    = { 0, 2, 0, 6, 7, 8, 9, 0, 0, 0, 0, 0, 0, 4, 5, 0, 0 };
static size_t Opsize[]    = { 0, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 2, 0, 0, 1, 1 };

address_mode_t convert_address_mode(address_mode_t am)
{
  /*assert(am >= 0); // TODO: what if enum is not unsigned? [phf] */
  assert(am < 17);
  return Cvt[am];
}

size_t operand_size(address_mode_t am)
{
  /*assert(am >= 0); // TODO: what if enum is not unsigned? [phf] */
  assert(am < 17);
  return Opsize[am];
}

MNEMONIC Ops[] = {
    { NULL, v_list    , "list",           0,      0, {0,} },
    { NULL, v_include , "include",        0,      0, {0,} },
    { NULL, v_seg     , "seg",            0,      0, {0,} },
    { NULL, v_hex     , "hex",            0,      0, {0,} },
    { NULL, v_err     , "err",            0,      0, {0,} },
    { NULL, v_dc      , "dc",             0,      0, {0,} },
    { NULL, v_dc      , "byte",           0,      0, {0,} },
    { NULL, v_dc      , "word",           0,      0, {0,} },
    { NULL, v_dc      , "long",           0,      0, {0,} },
    { NULL, v_ds      , "ds",             0,      0, {0,} },
    { NULL, v_dc      , "dv",             0,      0, {0,} },
    { NULL, v_end     , "end",            0,      0, {0,} },
    { NULL, v_trace   , "trace",          0,      0, {0,} },
    { NULL, v_org     , "org",            0,      0, {0,} },
    { NULL, v_rorg    , "rorg",           0,      0, {0,} },
    { NULL, v_rend    , "rend",           0,      0, {0,} },
    { NULL, v_align   , "align",          0,      0, {0,} },
    { NULL, v_subroutine, "subroutine",   0,      0, {0,} },
    { NULL, v_equ     , "equ",            0,      0, {0,} },
    { NULL, v_equ     , "=",              0,      0, {0,} },
    { NULL, v_eqm     , "eqm",            0,      0, {0,} },
    { NULL, v_set     , "set",            0,      0, {0,} },
    { NULL, v_macro   , "mac",            MF_IF,  0, {0,} },
    { NULL, v_endm    , "endm",           MF_ENDM,0, {0,} },
    { NULL, v_mexit   , "mexit",          0,      0, {0,} },
    { NULL, v_ifconst , "ifconst",        MF_IF,  0, {0,} },
    { NULL, v_ifnconst, "ifnconst",       MF_IF,  0, {0,} },
    { NULL, v_if      , "if",             MF_IF,  0, {0,} },
    { NULL, v_else    , "else",           MF_IF,  0, {0,} },
    { NULL, v_endif   , "endif",          MF_IF,  0, {0,} },
    { NULL, v_endif   , "eif",            MF_IF,  0, {0,} },
    { NULL, v_repeat  , "repeat",         MF_IF,  0, {0,} },
    { NULL, v_repend  , "repend",         MF_IF,  0, {0,} },
    { NULL, v_echo    , "echo",           0,      0, {0,} },
    { NULL, v_processor,"processor",      0,      0, {0,} },
    { NULL, v_incbin  , "incbin",         0,      0, {0,} },
    { NULL, v_incdir  , "incdir",         0,      0, {0,} },
    MNEMONIC_NULL
};

/* vim: set tabstop=4 softtabstop=4 expandtab shiftwidth=4 autoindent: */
