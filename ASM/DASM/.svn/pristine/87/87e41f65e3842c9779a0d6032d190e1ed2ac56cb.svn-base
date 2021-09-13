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
 *  Fairchild F8 support code for DASM
 *  Copyright (c) 2004 by Thomas Mathys.
 */

#include "asm.h"
#include "errors.h"
#include "symbols.h"
#include "util.h"
#include "version.h"

#include <ctype.h> /* for isspace() */
#include <assert.h>

/*@unused@*/
SVNTAG("$Id$");

/*
 * special registers. must use numbers from 16 and up,
 * since numbers below 16 are used for scratchpad registers.
 *
 * there is no REG_J, since J is really just scratchpad register 9.
 */
enum REGISTERS {
    REG_A = 16,
    REG_DC0,
    REG_H,
    REG_IS,
    REG_K,
    REG_KU,
    REG_KL,
    REG_PC0,
    REG_PC1,
    REG_Q,
    REG_QU,
    REG_QL,
    REG_W,
    REG_NONE,
};

#if 0
/*
 * used to print error messages.
 * mnename and opstring are copied into a single error message,
 * which is passed to asmerr.
 *
 * err      : error code (ERROR_xxx constant, passed to asmerr)
 * mnename  : name of the mnemonic
 * opstring : operand string
 * abort    : false = don't abort assembly
 *            true = abort assembly
 */
static void f8err(error_t err, const char *mnename, const char *opstring, bool bAbort) {

    char *buf;

    buf = checked_malloc(strlen(mnename) + strlen(opstring) + 64);
    strcpy(buf, mnename);
    strcat(buf, " ");
    strcat(buf, opstring);
    asmerr(err, bAbort, buf);
    free(buf);
}
#endif

/*
 * emits a one byte opcode.
 */
static void emit_opcode1(unsigned char opcode) {
    Glen = 1;
    Gen[0] = opcode;
    generate();
}


/*
 * emits a two byte opcode
 *
 * byte0 : first byte (lower address)
 * byte1 : second byte (higher address)
 */
static void emit_opcode2(unsigned char byte0, unsigned char byte1) {
    Glen = 2;
    Gen[0] = byte0;
    Gen[1] = byte1;
    generate();
}


/*
 * emits a three byte opcode
 *
 * byte0 : first byte (lowest address)
 * byte1 : second byte (middle address)
 * byte2 : third byte (highest address)
 */
static void emit_opcode3(unsigned char byte0, unsigned char byte1, unsigned char byte2) {
    Glen = 3;
    Gen[0] = byte0;
    Gen[1] = byte1;
    Gen[2] = byte2;
    generate();
}



/*
 * check wether the current program counter is known.
 *
 * result : zero = current program counter is unknown
 *          nonzero = current program counter is known
 */
static int isPCKnown(void)
{
    dasm_flag_t pcf;
    pcf = ((Csegment->flags & SF_RORG) != 0) ? Csegment->rflags : Csegment->flags;
    return ((pcf & (SF_UNKNOWN|2)) == 0) ? 1 : 0;
    /* TODO: can probably just return expression as bool? */
}


/*
 * returns the current program counter
 */
static long getPC(void)
{
    return ((Csegment->flags & SF_RORG) != 0) ? Csegment->rorg : Csegment->org;
}


/*
 * attempts to parse a 32 bit unsigned value from a string.
 *
 * str    : string to parse the value from
 * value  : parsed value is stored here
 *
 * result : zero = ok or syntax error
 *          nonzero = unresolved expression
 */
static int parse_value(const char *str, unsigned long *value) {

    SYMBOL *sym;
    int result = 0;

    *value = 0;
    sym = eval(str, false);

    if (NULL != sym->next || AM_BYTEADR != sym->addrmode) {
        /* [phf] removed
        asmerr(ERROR_SYNTAX_ERROR, true, str);
        */
        error_fmt(ERROR_SYNTAX_ONE, str); /* TODO: fatal? since true passed? */
    }
    else if ((sym->flags & SYM_UNKNOWN) != 0) {
        ++Redo;
        Redo_why |= REASON_MNEMONIC_NOT_RESOLVED;
        result = 1;
    }
    else {
        *value = sym->value;
    }
    free_symbol_list(sym);

    return result;
}


/*
 * attempts to parse a scratchpad register name.
 * register numbers are parsed as expressions.
 * if an expression is invalid, asmerr is called
 * and the assembly aborted.
 *
 * accepts the following input:
 *
 * - numbers 0..14 (as expressions, numbers 12-14 map to S, I and D)
 * - J  (alias for register  9)
 * - HU (alias for register 10)
 * - HL (alias for register 11)
 * - S and (IS)
 * - I and (IS)+
 * - D and (IS)-
 *
 * str    : string to parse the scratchpad register from
 * reg    : parsed scratchpad register is stored here.
 *          this is the value which will become the lower
 *          nibble of the opcodes.
 *
 * result : zero = ok or syntax error
 *          nonzero = unresolved expression
 */
static int parse_scratchpad_register(const char *str, unsigned char *reg) {

    unsigned long regnum;

    /* parse special cases where ISAR is used as index */
    if (!strcasecmp("s", str) || !strcasecmp("(is)", str)) {
        *reg = 0x0c;
        return 0;
    }
    if (!strcasecmp("i", str) || !strcasecmp("(is)+", str)) {
        *reg = 0x0d;
        return 0;
    }
    if (!strcasecmp("d", str) || !strcasecmp("(is)-", str)) {
        *reg = 0x0e;
        return 0;
    }

    /* parse aliases for scratchpad registers */
    if (!strcasecmp("j", str)) {
        *reg = 0x09;
        return 0;
    }
    if (!strcasecmp("hu", str)) {
        *reg = 0x0a;
        return 0;
    }
    if (!strcasecmp("hl", str)) {
        *reg = 0x0b;
        return 0;
    }

    /* parse register number */
    if (parse_value(str, &regnum)) {
        return 1;       /* unresolved expr */
    } else {
        if (regnum > 14) {
            /* [phf] removed
            asmerr(ERROR_VALUE_MUST_BE_LT_F, true, str);
            */
            error_fmt("Value in '%s' must be <$f!", str);
            /* TODO: fatal? since true passed? refactor to general message? */
        }
        *reg = regnum;
        return 0;
    }
}


/*
 * attempts to parse a special register name from str
 *
 * result : one of the REG_xxx constants (possibly also REG_NONE)
 */
static int parse_special_register(char *str) {

    if (!strcasecmp("a", str)) {
        return REG_A;
    }
    if (!strcasecmp("dc0", str) || !strcasecmp("dc", str) ) {
        return REG_DC0;
    }
    if (!strcasecmp("h", str)) {
        return REG_H;
    }
    if (!strcasecmp("is", str)) {
        return REG_IS;
    }
    if (!strcasecmp("k", str)) {
        return REG_K;
    }
    if (!strcasecmp("ku", str)) {
        return REG_KU;
    }
    if (!strcasecmp("kl", str)) {
        return REG_KL;
    }
    if (!strcasecmp("pc0", str) || !strcasecmp("p0", str)) {
        return REG_PC0;
    }
    if (!strcasecmp("pc1", str) || !strcasecmp("p", str)) {
        return REG_PC1;
    }
    if (!strcasecmp("q", str)) {
        return REG_Q;
    }
    if (!strcasecmp("qu", str)) {
        return REG_QU;
    }
    if (!strcasecmp("ql", str)) {
        return REG_QL;
    }
    if (!strcasecmp("w", str)) {
        return REG_W;
    }
    else {
        return REG_NONE;
    }
}


static void v_ins_outs(const char *str, MNEMONIC *mne) {

    unsigned long operand;

    programlabel();
    parse_value(str, &operand);
    if (operand > 15) {
        /* [phf] removed
        f8err(ERROR_VALUE_MUST_BE_LT_10, mne->name, str, false);
        */
        error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 15);
    }
    emit_opcode1(mne->opcode[0] | (operand & 15));
}


static void v_sl_sr(const char *str, MNEMONIC *mne) {

    unsigned long operand;

    programlabel();

    if (parse_value(str, &operand)) {
        /* unresolved expression, reserve space */
        emit_opcode1(0);
    } else {
        switch (operand) {
            case 1:
                emit_opcode1(mne->opcode[0]);
                break;
            case 4:
                emit_opcode1(mne->opcode[0] + 2);
                break;
            default:
                /* [phf] removed
                f8err(ERROR_VALUE_MUST_BE_1_OR_4, mne->name, str, false);
                */
                error_fmt(ERROR_VALUE_ONEOF, mne->name, str, "1 or 4");
                emit_opcode1(0);
                break;
        }
    }
}


static void v_lis(const char *str, MNEMONIC *mne) {

    unsigned long operand;

    programlabel();
    parse_value(str, &operand);
    if (operand > 15) {
        /* [phf] removed
        f8err(ERROR_VALUE_MUST_BE_LT_10, mne->name, str, false);
        */
        error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 15);
    }
    emit_opcode1(0x70 | (operand & 15));
}


static void v_lisu_lisl(const char *str, MNEMONIC *mne) {

    unsigned long operand;

    programlabel();
    parse_value(str, &operand);
    if (operand > 7) {
        /* [phf] removed
        f8err(ERROR_VALUE_MUST_BE_LT_8, mne->name, str, false);
        */
        error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 7);
    }
    emit_opcode1(mne->opcode[0] | (operand & 7));
}


/*
 * handles opcodes with a scratchpad register operand:
 * as, asd, ds, ns, xs
 */
static void v_sreg_op(const char *str, MNEMONIC *mne) {

    unsigned char reg;

    programlabel();
    parse_scratchpad_register(str, &reg);
    emit_opcode1(mne->opcode[0] | reg);
}

/*
 * helper for parsing comma-separated parameter lists [phf]
 */
static void find_commas(const char *str, int *nof_commas, int *first_comma)
{
    int i;

    *nof_commas = 0;
    *first_comma = 0;

    for (i=0; str[i] != '\0'; i++) {
        if (',' == str[i]) {
            (*nof_commas)++;
            (*first_comma) = i;
        }
    }
}

/*
 * extract the two operands seperated at given position in str [phf]
 * TODO: this is quite ugly, we should find a better way
 */
static void extract_operands(const char *str, int cindex, char *op1, char *op2, size_t size)
{
  int len = strlen(str);
  char one[MAX_SYM_LEN];
  char two[MAX_SYM_LEN];
  size_t res;

  assert(cindex > 0);
  assert(cindex < len);
  assert(len < MAX_SYM_LEN);

  strncpy(one, str, cindex);
  one[cindex] = '\0';

  strncpy(two, str+cindex+1, len-cindex);
  two[len-cindex] = '\0';

  /* TODO: When this was done inline, v_lr() stripped two whitespaces
     while v_bf_bt() didn't bother; we now remove all whitespace
     anyway; apparently parse() in main.c does some whitespace
     stuff as well, at least according to Thomas Mathys; I still
     need to investigate some more when exactly this needs to be
     done and whether it could be done in one place only. [phf] */

  res = strip_whitespace(op1, one, size);
  assert(res < size);

  res = strip_whitespace(op2, two, size);
  assert(res < size);
}

static void v_lr(const char *str, MNEMONIC *mne) {

    int ncommas;
    int cindex;
    char op1[MAX_SYM_LEN];
    char op2[MAX_SYM_LEN];
    unsigned char reg_dst;
    unsigned char reg_src;
    int opcode;

    programlabel();

    /* a valid operand string must contain exactly one comma. find it. */
    find_commas(str, &ncommas, &cindex);
    if (1 != ncommas) {
    	/* [phf] removed
        f8err(ERROR_SYNTAX_ERROR, mne->name, str, false);
        */
        error_fmt(ERROR_SYNTAX_TWO, mne->name, str);
        return;
    }

    /* extract operand strings  */
    extract_operands(str, cindex, op1, op2, MAX_SYM_LEN);

    /* parse operand strings for register names */
    reg_dst = parse_special_register(op1);
    if (REG_NONE == reg_dst) {
        if (parse_scratchpad_register(op1, &reg_dst)) {
            /* unresolved expression, reserve space */
            emit_opcode1(0);
            return;
        }
    }
    reg_src = parse_special_register(op2);
    if (REG_NONE == reg_src) {
        if (parse_scratchpad_register(op2, &reg_src)) {
            /* unresolved expression, reserve space */
            emit_opcode1(0);
            return;
        }
    }

    /* generate opcode */
    opcode = -1;
    switch (reg_dst) {
        case REG_A:     /* lr a,xxx */
            switch (reg_src) {
                case REG_IS: opcode = 0x0a; break;
                case REG_KL: opcode = 0x01; break;
                case REG_KU: opcode = 0x00; break;
                case REG_QL: opcode = 0x03; break;
                case REG_QU: opcode = 0x02; break;
                default:
                    if (reg_src < 15) {
                        opcode = 0x40 | reg_src;
                    }
                    break;
                }
                break;
        case REG_DC0:
            switch (reg_src) {
                case REG_H: opcode = 0x10; break;
                case REG_Q: opcode = 0x0f; break;
            }
            break;
        case REG_H:
            if (REG_DC0 == reg_src) opcode = 0x11;
            break;
        case REG_IS:
            if (REG_A == reg_src) opcode = 0x0b;
            break;
        case REG_K:
            if (REG_PC1 == reg_src) opcode = 0x08;
            break;
        case REG_KL:
            if (REG_A == reg_src) opcode = 0x05;
            break;
        case REG_KU:
            if (REG_A == reg_src) opcode = 0x04;
            break;
        case REG_PC0:
            if (REG_Q == reg_src) opcode = 0x0d;
            break;
        case REG_PC1:
            if (REG_K == reg_src) opcode = 0x09;
            break;
        case REG_Q:
            if (REG_DC0 == reg_src) opcode = 0x0e;
            break;
        case REG_QL:
            if (REG_A == reg_src) opcode = 0x07;
            break;
        case REG_QU:
            if (REG_A == reg_src) opcode = 0x06;
            break;
        case REG_W:
            if (0x09 == reg_src) opcode = 0x1d;
            break;
        default:        /* lr sreg,xxx*/
            if ( (15 > reg_dst) && (REG_A == reg_src) ) {
                /* lr sreg,a */
                opcode = 0x50 | reg_dst;
            }
            else if ( (9 == reg_dst) && (REG_W == reg_src) ) {
                /* special case : lr j,w */
                opcode = 0x1e;
            }
            break;
    }
    if (opcode < 0) {
        /* [phf] removed
        f8err(ERROR_ILLEGAL_OPERAND_COMBINATION, mne->name, str, true);
        */
        error_fmt("Invalid combination of operands '%s %s'!",
                  mne->name, str); /* TODO: fatal? since true passed? */
    } else {
        emit_opcode1(opcode);
    }
}


/*
 * generates branch opcodes
 *
 * opcode : opcode of the branch (for instance 0x8f for BR7)
 * str    : operand string
 */
static void generate_branch(unsigned char opcode, const char *str) {

    unsigned long target_adr;
    long disp;

    programlabel();

    /* get target address */
    if (parse_value(str, &target_adr)) {
        /* unresolved target address, reserve space */
        emit_opcode2(0, 0);
        return;
    }

    /* calculate displacement */
    if (isPCKnown()) {
        disp = target_adr - getPC() - 1;
        /* [phf] ops.c v_mnemonic() checks different range! */
        if (disp > 127 || disp < -128) {
            /* [phf] removed
            char buf[64];
            sprintf(buf, "%d", (int)disp);
            asmerr(ERROR_BRANCH_OUT_OF_RANGE, false, buf);
            */
            error_fmt(ERROR_BRANCH_RANGE, disp);
            /* TODO: this doesn't say by how much it's out of range! */
        }
    } else {
        /* unknown pc, will be (hopefully) resolved in future passes */
        disp = 0;
    }

    emit_opcode2(opcode, disp & 255);
}


/*
 * handles the following branch mnemonics:
 * bc, bm, bnc, bno, bnz, bp, br, br7, bz
 */
static void v_branch(const char *str, MNEMONIC *mne) {
    generate_branch(mne->opcode[0], str);
}


static void v_bf_bt(const char *str, MNEMONIC *mne) {

    int ncommas;
    int cindex;
    char op1[MAX_SYM_LEN];
    char op2[MAX_SYM_LEN];
    unsigned long value;

    /* a valid operand string must contain exactly one comma. find it. */
    find_commas(str, &ncommas, &cindex);
    if (1 != ncommas) {
        /* [phf] removed
        f8err(ERROR_SYNTAX_ERROR, mne->name, str, false);
        */
        error_fmt(ERROR_SYNTAX_TWO, mne->name, str);
        return;
    }

    /* extract operands */
    extract_operands(str, cindex, op1, op2, MAX_SYM_LEN);

    /* parse first operand*/
    if (parse_value(op1, &value)) {
        /* unresolved expression, reserve space */
        emit_opcode2(0, 0);
        return;
    }

    /* check first operand */
    if ('f' == mne->name[1]) {
        /* bf */
        if (value > 15) {
            /* [phf] removed
            f8err(ERROR_VALUE_MUST_BE_LT_10, mne->name, str, false);
            */
            error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 15);
            value &= 15;
        }
    } else {
        /* bt */
        if (value > 7) {
            /* [phf] removed
            f8err(ERROR_VALUE_MUST_BE_LT_8, mne->name, str, false);
            */
            error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 7);
            value &= 7;
        }
    }

    generate_branch(mne->opcode[0] | value, op2);
}


/*
 * handles instructions that take a word operand:
 * dci, jmp, pi
 */
static void v_wordop(const char *str, MNEMONIC *mne) {

    unsigned long value;

    programlabel();
    parse_value(str, &value);
    if (value > 0xffff) {
        /* [phf] removed
        f8err(ERROR_VALUE_MUST_BE_LT_10000, mne->name, str, false);
        */
        error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 65535);
    }
    emit_opcode3(mne->opcode[0], (value >> 8) & 0xff, value & 0xff);
}


/*
 * handles instructions that take a byte operand:
 * ai, ci, in, li, ni, oi, out, xi
 */
static void v_byteop(const char *str, MNEMONIC *mne) {

    unsigned long value;

    programlabel();
    parse_value(str, &value);
    if (value > 0xff) {
        /* [phf] removed
        f8err(ERROR_ADDRESS_MUST_BE_LT_100, mne->name, str, false);
        */
        error_fmt(ERROR_VALUE_RANGE, mne->name, str, 0, 255);
    }
    emit_opcode2(mne->opcode[0], value & 0xff);
}


MNEMONIC MneF8[] = {

    /* ds is an f8 opcode, so we replace the ds directive by res */
    {NULL, v_ds, "res", 0, 0, {0,}},

    /* add db/dw/dd directives for f8tool compatibility */
    {NULL, v_dc, "db", 0, 0, {0,}},
    {NULL, v_dc, "dw", 0, 0, {0,}},
    {NULL, v_dc, "dd", 0, 0, {0,}},

    /*
     * f8 opcodes
     *
     * some instructions have AF_IMP in der addressflag, although
     * they are handled by own handlers and have explicit operands.
     * this is to keep dasm from clearing the opcode array when
     * adding the hashtable.
     *
     * the only instructions that are handled by v_mnemonic are
     * those with implicit operands.
     *
     * other f8 instructions have register operands, which v_mnemonic
     * can't handle.
     *
     * or they have byte and word operands (values or addresses).
     * these could theoretically be handled by v_mnemonic, but
     * we do it ourselves anyway, since this allows us to have
     * expressions with parentheses as operands.
     */
    {NULL, v_mnemonic, "adc", 0, AF_IMP, {0x8e}},
    {NULL, v_byteop,   "ai" , 0, AF_IMP, {0x24}},
    {NULL, v_mnemonic, "am" , 0, AF_IMP, {0x88}},
    {NULL, v_mnemonic, "amd", 0, AF_IMP, {0x89}},
    {NULL, v_sreg_op,  "as" , 0, AF_IMP, {0xc0}},       /* base opcode */
    {NULL, v_sreg_op,  "asd", 0, AF_IMP, {0xd0}},       /* base opcode */
    {NULL, v_branch,   "bc" , 0, AF_IMP, {0x82}},
    {NULL, v_bf_bt,    "bf" , 0, AF_IMP, {0x90}},       /* base opcode */
    {NULL, v_branch,   "bm" , 0, AF_IMP, {0x91}},
    {NULL, v_branch,   "bnc", 0, AF_IMP, {0x92}},
    {NULL, v_branch,   "bno", 0, AF_IMP, {0x98}},
    {NULL, v_branch,   "bnz", 0, AF_IMP, {0x94}},
    {NULL, v_branch,   "bp" , 0, AF_IMP, {0x81}},
    {NULL, v_branch,   "br" , 0, AF_IMP, {0x90}},
    {NULL, v_branch,   "br7", 0, AF_IMP, {0x8f}},
    {NULL, v_bf_bt,    "bt" , 0, AF_IMP, {0x80}},       /* base opcode */
    {NULL, v_branch,   "bz" , 0, AF_IMP, {0x84}},
    {NULL, v_byteop,   "ci" , 0, AF_IMP, {0x25}},
    {NULL, v_mnemonic, "clr", 0, AF_IMP, {0x70}},
    {NULL, v_mnemonic, "cm" , 0, AF_IMP, {0x8d}},
    {NULL, v_mnemonic, "com", 0, AF_IMP, {0x18}},
    {NULL, v_wordop,   "dci", 0, AF_IMP, {0x2a}},
    {NULL, v_mnemonic, "di" , 0, AF_IMP, {0x1a}},
    {NULL, v_sreg_op,  "ds" , 0, AF_IMP, {0x30}},       /* base opcode */
    {NULL, v_mnemonic, "ei" , 0, AF_IMP, {0x1b}},
    {NULL, v_byteop,   "in" , 0, AF_IMP, {0x26}},
    {NULL, v_mnemonic, "inc", 0, AF_IMP, {0x1f}},
    {NULL, v_ins_outs, "ins", 0, AF_IMP, {0xa0}},       /* base opcode */
    {NULL, v_wordop,   "jmp", 0, AF_IMP, {0x29}},
    {NULL, v_byteop,   "li" , 0, AF_IMP, {0x20}},
    {NULL, v_lis,      "lis", 0, 0, {0,}},
    {NULL, v_lisu_lisl,"lisl",0, AF_IMP, {0x68}},       /* base opcode */
    {NULL, v_lisu_lisl,"lisu",0, AF_IMP, {0x60}},       /* base opcode */
    {NULL, v_mnemonic, "lm" , 0, AF_IMP, {0x16}},
    {NULL, v_mnemonic, "lnk", 0, AF_IMP, {0x19}},
    {NULL, v_lr,       "lr" , 0, 0, {0,}},
    {NULL, v_byteop,   "ni" , 0, AF_IMP, {0x21}},
    {NULL, v_mnemonic, "nm" , 0, AF_IMP, {0x8a}},
    {NULL, v_mnemonic, "nop", 0, AF_IMP, {0x2b}},
    {NULL, v_sreg_op,  "ns" , 0, AF_IMP, {0xf0}},       /* base opcode */
    {NULL, v_byteop,   "oi" , 0, AF_IMP, {0x22}},
    {NULL, v_mnemonic, "om" , 0, AF_IMP, {0x8b}},
    {NULL, v_byteop,   "out", 0, AF_IMP, {0x27}},
    {NULL, v_ins_outs, "outs",0, AF_IMP, {0xb0}},       /* base opcode */
    {NULL, v_wordop,   "pi" , 0, AF_IMP, {0x28}},
    {NULL, v_mnemonic, "pk" , 0, AF_IMP, {0x0c}},
    {NULL, v_mnemonic, "pop", 0, AF_IMP, {0x1c}},
    {NULL, v_sl_sr,    "sl" , 0, AF_IMP, {0x13}},       /* base opcode for "sl 1" */
    {NULL, v_sl_sr,    "sr" , 0, AF_IMP, {0x12}},       /* base opcode for "sr 1" */
    {NULL, v_mnemonic, "st" , 0, AF_IMP, {0x17}},
    {NULL, v_mnemonic, "xdc", 0, AF_IMP, {0x2c}},
    {NULL, v_byteop,   "xi" , 0, AF_IMP, {0x23}},
    {NULL, v_mnemonic, "xm" , 0, AF_IMP, {0x8c}},
    {NULL, v_sreg_op,  "xs" , 0, AF_IMP, {0xe0}},       /* base opcode */
    MNEMONIC_NULL
};

/* vim: set tabstop=4 softtabstop=4 expandtab shiftwidth=4 autoindent: */
