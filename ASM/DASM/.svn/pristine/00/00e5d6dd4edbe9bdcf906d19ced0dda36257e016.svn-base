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
 * @brief Handle expression evaluation and addressing mode decode.
 * @note If you use the string field in an expression you must clear
 * the SYM_MACRO and SYM_STRING bits in the flags before calling
 * FreeSymbolList()!
 */

#include "asm.h"
#include "errors.h"
#include "symbols.h"
#include "util.h"
#include "version.h"

#include <assert.h>
#include <ctype.h>
#include <stdbool.h>

/*@unused@*/
SVNTAG("$Id$");

/*
    There used to be big hack here to allow unary functions
    to take only v1 and f1 while binary functions also took
    v2 and f2; this lead to all kinds of problems, casting
    excesses for example; early on in DASM's history unions
    were used, but ANSI C didn't allow this anymore, so we
    used the old () hack to allow arbitrary parameter lists.
    No more. We now simply use the binary signature, which
    means unary functions just ignore v2 and f2. Maybe not
    as accurate as Matt's original, but less of a hack than
    what we had before. [phf]
*/
typedef void (*opfunc_t)(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);

static void stackarg(long val, dasm_flag_t flags, /*@null@*/ const char *ptr1);

static void doop(opfunc_t, int pri);
static void evaltop(void);

/* these are really binary [phf] */
static void op_mult(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_div(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_mod(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_add(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_sub(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_shiftleft(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_shiftright(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_greater(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_greatereq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_smaller(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_smallereq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_eqeq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_noteq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_andand(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_oror(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_xor(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_and(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_or(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_question(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);

/* these are really unary but pretend to be binary [phf] */
static void op_takelsb(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_takemsb(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_negate(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_invert(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);
static void op_not(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2);

static const char *pushsymbol(const char *str);
static const char *pushstr(const char *str);
static const char *pushbin(const char *str);
static const char *pushoct(const char *str);
static const char *pushdec(const char *str);
static const char *pushhex(const char *str);
static const char *pushchar(const char *str);

/*
*  evaluate an expression.  Figure out the addressing mode:
*
*		implied
*    #val	immediate
*    val	zero page or absolute
*    val,x	zero,x or absolute,x
*    val,y	zero,y or absolute,y
*    (val)	indirect
*    (val,x)	zero indirect x
*    (val),y	zero indirect y
*
*    exp, exp,.. LIST of expressions
*
*  an absolute may be returned as zero page
*  a relative may be returned as zero page or absolute
*
*  unary:  - ~ ! < >
*  binary: (^)(* / %)(+ -)(>> <<)(& |)(`)(&& ||)(== != < > <= >=)
*
*  values: symbol, octal, decimal, $hex, %binary, 'c "str"
*
*/

#define MAXOPS	    32
#define MAXARGS     64

static dasm_flag_t Argflags[MAXARGS];
static long  Argstack[MAXARGS];
static char *Argstring[MAXARGS];
static int Oppri[MAXOPS];
static opfunc_t Opdis[MAXOPS];

static int	Argi, Opi;
static bool Lastwasop;
static int	Argibase, Opibase;

static bool is_alpha_num(char c)
{
    return isalnum((int)c) != 0;
}

SYMBOL *eval(const char *str, bool wantmode)
{
    SYMBOL *base, *cur;
    int oldargibase = Argibase;
    int oldopibase = Opibase;
    int scr;
    
    const char *pLine = str;

    Argibase = Argi;
    Opibase = Opi;
    Lastwasop = true;
    base = cur = alloc_symbol();
    

    while (*str != '\0')
    {
        debug_fmt("char '%c'", *str);
        
        switch(*str)
        {
        case ' ':
        case '\n':
            ++str;
            break;

        case '~':
            if (Lastwasop)
                doop(op_invert, 128);
            else
            {
                /* [phf] removed
                asmerr( ERROR_SYNTAX_ERROR, false, pLine );
                */
                error_fmt(ERROR_SYNTAX_ONE, pLine);
            }
            ++str;
            break;

        case '*':
            if (Lastwasop) {
                pushsymbol(".");
            } else
                doop(op_mult, 20);
            ++str;
            break;

        case '/':
            doop(op_div, 20);
            ++str;
            break;

        case '%':
            if (Lastwasop) {
                str = pushbin(str+1);
            } else {
                doop(op_mod, 20);
                ++str;
            }
            break;

        case '?':   /*  10      */
            doop(op_question, 10);
            ++str;
            break;

        case '+':   /*  19      */
            doop(op_add, 19);
            ++str;
            break;

        case '-':   /*  19: -   (or - unary)        */
            if (Lastwasop) {
                doop(op_negate, 128);
            } else {
                doop(op_sub, 19);
            }
            ++str;
            break;

        case '>':   /*  18: >> <<  17: > >= <= <    */
            
            if (Lastwasop)
            {
                doop(op_takemsb, 128);
                ++str;
                break;
            }

            if (str[1] == '>')
            {
                doop(op_shiftright, 18);
                ++str;
            }

            else if (str[1] == '=')
            {
                doop(op_greatereq, 17);
                ++str;
            }
            else
            {
                doop(op_greater, 17);
            }
            ++str;
            break;

        case '<':
            
            if (Lastwasop)
            {
                doop(op_takelsb, 128);
                ++str;
                break;
            }

            if (str[1] == '<')
            {
                doop(op_shiftleft, 18);
                ++str;
            }
            else if (str[1] == '=')
            {
                doop(op_smallereq, 17);
                ++str;
            }
            else
            {
                doop(op_smaller, 17);
            }
            ++str;
            break;

        case '=':   /*  16: ==  (= same as ==)      */
            
            if (str[1] == '=')
                ++str;
            doop(op_eqeq, 16);
            ++str;
            break;

        case '!':   /*  16: !=                      */
            
            if (Lastwasop)
            {
                doop(op_not, 128);
            }
            else
            {
                doop(op_noteq, 16);
                ++str;
            }
            ++str;
            break;

        case '&':   /*  15: &   12: &&              */
            
            if (str[1] == '&')
            {
                doop(op_andand, 12);
                ++str;
            }
            else
            {
                doop(op_and, 15);
            }
            ++str;
            break;

        case '^':   /*  14: ^                       */
            
            doop(op_xor, 14);
            ++str;
            break;

        case '|':   /*  13: |   11: ||              */
            
            if (str[1] == '|')
            {
                doop(op_oror, 11);
                ++str;
            }
            else
            {
                doop(op_or, 13);
            }
            ++str;
            break;

            
        case '(':
            
            if (wantmode)
            {
                cur->addrmode = AM_INDWORD;
                ++str;
                break;
            }
            
            /* fall thru OK */
            
        case '[':   /*  eventually an argument      */
            
            if (Opi == MAXOPS)
                /* TODO: should be an error message? [phf] */
                (void) puts("too many ops");
            else
                Oppri[Opi++] = 0;
            ++str;
            break;
            
        case ')':
            
            if (wantmode)
            {
                if (cur->addrmode == AM_INDWORD &&
                    str[1] == ',' && tolower(str[2]) == 'y')
                {
                    cur->addrmode = AM_INDBYTEY;
                    str += 2;
                }
                ++str;
                break;
            }
            
            /* fall thru OK */
            
        case ']':
            
            while(Opi != Opibase && Oppri[Opi-1])
                evaltop();
            if (Opi != Opibase)
                --Opi;
            ++str;
            if (Argi == Argibase)
            {
                /* TODO: should be an error message? [phf] */
                (void) puts("']' error, no arg on stack");
                break;
            }
            
            if (*str == 'd')
            {  /*  STRING CONVERSION   */
                char buf[32];
                ++str;
                if (Argflags[Argi-1] == 0)
                {
                    int len = snprintf(buf,sizeof(buf),"%ld",Argstack[Argi-1]);
                    assert(len < (int)sizeof(buf));
                    Argstring[Argi-1] = checked_strdup(buf);
                }
            }
            break;

        case '#':
            
            cur->addrmode = AM_IMM8;
            ++str;
            /*
            * No other addressing mode is possible from now on
            * so we might as well allow () instead of [].
            */
            wantmode = false;
            break;
            
        case ',':
            
            while(Opi != Opibase)
                evaltop();
            Lastwasop = true;
            scr = tolower(str[1]);
            
            if (cur->addrmode == AM_INDWORD && scr == 'x' && !is_alpha_num(str[2]))
            {
                cur->addrmode = AM_INDBYTEX;
                ++str;
            }
            else if (scr == 'x' && !is_alpha_num(str[2]))
            {
                cur->addrmode = AM_0X;
                ++str;
            }
            else if (scr == 'y' && !is_alpha_num(str[2]))
            {
                cur->addrmode = AM_0Y;
                ++str;
            }
            else
            {
                SYMBOL *pNewSymbol = alloc_symbol();
                cur->next = pNewSymbol;
                --Argi;
                if (Argi < Argibase)
                {
                    /* [phf] removed
                    asmerr( ERROR_SYNTAX_ERROR, false, pLine );
                    */
                    error_fmt(ERROR_SYNTAX_ONE, pLine);
                }
                if (Argi > Argibase)
                {
                    /* [phf] removed
                    asmerr( ERROR_SYNTAX_ERROR, false, pLine );
                    */
                    error_fmt(ERROR_SYNTAX_ONE, pLine);
                }
                cur->value = Argstack[Argi];
                cur->flags = Argflags[Argi];
                
                if ((cur->string = Argstring[Argi]) != NULL)
                {
                    cur->flags |= SYM_STRING;
                    debug_fmt("STRING: %s", cur->string);
                }
                cur = pNewSymbol;
            }
            ++str;
            break;

        case '$':
            str = pushhex(str+1);
            break;

        case '\'':
            str = pushchar(str+1);
            break;

        case '\"':
            str = pushstr(str+1);
            break;

        default:
            {
                const char *dol = str;
                while (*dol >= '0' && *dol <= '9')
                    dol++;
                if (*dol == '$')
                {
                    str = pushsymbol(str);
                    break;
                }
            }

            if (*str == '0')
                str = pushoct(str);
            else
            {
                if (*str > '0' && *str <= '9')
                    str = pushdec(str);
                else
                    str = pushsymbol(str);
            }
            break;
        }
    }

    while(Opi != Opibase)
        evaltop();
    
    if (Argi != Argibase)
    {
        --Argi;
        cur->value = Argstack[Argi];
        cur->flags = Argflags[Argi];
        if ((cur->string = Argstring[Argi]) != NULL)
        {
            cur->flags |= SYM_STRING;
            debug_fmt("STRING: %s", cur->string);
        }
        if (base->addrmode == 0)
            base->addrmode = AM_BYTEADR;
    }

    if (Argi != Argibase || Opi != Opibase)
    {
        /* [phf] removed
        asmerr( ERROR_SYNTAX_ERROR, false, pLine );
        */
        error_fmt(ERROR_SYNTAX_ONE, pLine);
    }


    Argi = Argibase;
    Opi  = Opibase;
    Argibase = oldargibase;
    Opibase = oldopibase;
    return base;
}


static void evaltop(void)
{
    debug_fmt("evaltop @(A,O) %d %d", Argi, Opi);
    
    if (Opi <= Opibase)
    {
        /* [phf] removed
        asmerr( ERROR_SYNTAX_ERROR, false, NULL );
        */
        error_fmt(ERROR_SYNTAX_NONE);
        Opi = Opibase;
        return;
    }
    --Opi;
    if (Oppri[Opi] == 128) {
        if (Argi < Argibase + 1)
        {
            /* [phf] removed
            asmerr( ERROR_SYNTAX_ERROR, false, NULL );
            */
            error_fmt(ERROR_SYNTAX_NONE);
            Argi = Argibase;
            return;
        }
        --Argi;
        /* call unary function through binary signature [phf] */
        (*Opdis[Opi])(Argstack[Argi], 0, Argflags[Argi], 0);
    }
    else
    {
        if (Argi < Argibase + 2)
        {
            /* [phf] removed
            asmerr( ERROR_SYNTAX_ERROR, false, NULL );
            */
            error_fmt(ERROR_SYNTAX_NONE);
            Argi = Argibase;
            return;
        }

        Argi -= 2;
        /* call binary function, for real [phf] */
        (*Opdis[Opi])(Argstack[Argi], Argstack[Argi+1],
            Argflags[Argi], Argflags[Argi+1]);
    }
}

static void stackarg(long val, dasm_flag_t flags, /*@null@*/ const char *ptr1)
{
    char *str = NULL;
    
    debug_fmt("stackarg %ld (@%d)", val, Argi);
    
    Lastwasop = false;
    if ((flags & SYM_STRING) != 0)
    {
        /*
           Why unsigned char? Looks like we're converting to
           long in a very strange way... [phf]
        */
        const unsigned char *ptr = (const unsigned char *)ptr1;
        char *new;
        size_t len = 0;
        val = 0;
        while (*ptr != '\0' && *ptr != '\"')
        {
            val = (val << 8) | *ptr;
            ++ptr;
            ++len;
        }
        new = checked_malloc(len + 1);
        memcpy(new, ptr1, len);
        new[len] = '\0';
        flags &= ~SYM_STRING;
        str = new;
    }
    Argstack[Argi] = val;
    Argstring[Argi] = str;
    Argflags[Argi] = flags;
    if (++Argi == MAXARGS) {
        /* TODO: should be an error message? [phf] */
        (void) puts("stackarg: maxargs stacked");
        Argi = Argibase;
    }
    while (Opi != Opibase && Oppri[Opi-1] == 128)
        evaltop();
}

static void doop(opfunc_t func, int pri)
{
    debug_fmt("doop");
    
    Lastwasop = true;
    
    if (Opi == Opibase || pri == 128)
    {
        debug_fmt("doop @ %d unary", Opi);
        Opdis[Opi] = func;
        Oppri[Opi] = pri;
        ++Opi;
        return;
    }
    
    while (Opi != Opibase && Oppri[Opi-1] && pri <= Oppri[Opi-1])
        evaltop();
    
    debug_fmt("doop @ %d", Opi);
    
    Opdis[Opi] = func;
    Oppri[Opi] = pri;
    ++Opi;
    
    if (Opi == MAXOPS)
    {
        /* TODO: should be an error message? [phf] */
        (void) puts("doop: too many operators");
        Opi = Opibase;
    }
    return;
}

/* unary [phf] */
static void op_takelsb(long v1, long UNUSED(v2), dasm_flag_t f1, dasm_flag_t UNUSED(f2))
{
    stackarg(v1 & 0xFFL, f1, NULL);
}

static void op_takemsb(long v1, long UNUSED(v2), dasm_flag_t f1, dasm_flag_t UNUSED(f2))
{
    stackarg((v1 >> 8) & 0xFF, f1, NULL);
}

static void op_negate(long v1, long UNUSED(v2), dasm_flag_t f1, dasm_flag_t UNUSED(f2))
{
    stackarg(-v1, f1, NULL);
}

static void op_invert(long v1, long UNUSED(v2), dasm_flag_t f1, dasm_flag_t UNUSED(f2))
{
    stackarg(~v1, f1, NULL);
}

static void op_not(long v1, long UNUSED(v2), dasm_flag_t f1, dasm_flag_t UNUSED(f2))
{
    stackarg(!v1, f1, NULL);
}

/* binary [phf] */
static void op_mult(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg(v1 * v2, f1|f2, NULL);
}

static void op_div(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if (f1|f2) {
        stackarg(0L, f1|f2, NULL);
        return;
    }
    if (v2 == 0)
    {
        /* [phf] removed
        asmerr( ERROR_DIVISION_BY_0, true, NULL );
        */
        fatal_fmt("Division by zero!");
        /* TODO: not fatal in Matt's DASM, Andrew made it fatal in 2.20.04 [phf] */
        stackarg(0L, 0, NULL);
    }
    else
    {
        stackarg(v1 / v2, 0, NULL);
    }
}

static void op_mod(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if (f1|f2) {
        stackarg(0L, f1|f2, NULL);
        return;
    }
    if (v2 == 0)
        stackarg(v1, 0, NULL);
    else
        stackarg(v1 % v2, 0, NULL);
}

static void op_question(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if (f1)
        stackarg(0L, f1, NULL);
    else
        stackarg((long)((v1) ? v2 : 0), ((v1) ? f2 : 0), NULL);
}

static void op_add(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg(v1 + v2, f1|f2, NULL);
}

static void op_sub(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg(v1 - v2, f1|f2, NULL);
}

static void op_shiftright(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if (f1|f2)
        stackarg(0L, f1|f2, NULL);
    else
        stackarg((long)(v1 >> v2), 0, NULL);
}

static void op_shiftleft(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if (f1|f2)
        stackarg(0L, f1|f2, NULL);
    else
        stackarg((long)(v1 << v2), 0, NULL);
}

static void op_greater(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg((long)(v1 > v2), f1|f2, NULL);
}

static void op_greatereq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg((long)(v1 >= v2), f1|f2, NULL);
}

static void op_smaller(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg((long)(v1 < v2), f1|f2, NULL);
}

static void op_smallereq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg((long)(v1 <= v2), f1|f2, NULL);
}

static void op_eqeq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg((long)(v1 == v2), f1|f2, NULL);
}

static void op_noteq(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg((long)(v1 != v2), f1|f2, NULL);
}

static void op_andand(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if ((!f1 && !v1) || (!f2 && !v2)) {
        stackarg(0L, 0, NULL);
        return;
    }
    stackarg(1L, f1|f2, NULL);
}

static void op_oror(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    if ((!f1 && v1) || (!f2 && v2)) {
        stackarg(1L, 0, NULL);
        return;
    }
    stackarg(0L, f1|f2, NULL);
}

static void op_xor(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg(v1^v2, f1|f2, NULL);
}

static void op_and(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg(v1&v2, f1|f2, NULL);
}

static void op_or(long v1, long v2, dasm_flag_t f1, dasm_flag_t f2)
{
    stackarg(v1|v2, f1|f2, NULL);
}

static const char *pushchar(const char *str)
{
    if (*str != '\0') {
        stackarg((long)*str, 0, NULL);
        ++str;
    } else {
        stackarg((long)' ', 0, NULL);
    }
    return str;
}

static const char *pushhex(const char *str)
{
    long val = 0;
    for (;; ++str) {
        if (*str >= '0' && *str <= '9') {
            val = (val << 4) + (*str - '0');
            continue;
        }
        if ((*str >= 'a' && *str <= 'f') || (*str >= 'A' && *str <= 'F')) {
            val = (val << 4) + ((*str&0x1F) + 9);
            continue;
        }
        break;
    }
    stackarg(val, 0, NULL);
    return str;
}

const char *pushoct(const char *str)
{
    long val = 0;
    while (*str >= '0' && *str <= '7') {
        val = (val << 3) + (*str - '0');
        ++str;
    }
    stackarg(val, 0, NULL);
    return str;
}

static const char *pushdec(const char *str)
{
    long val = 0;
    while (*str >= '0' && *str <= '9') {
        val = (val * 10) + (*str - '0');
        ++str;
    }
    stackarg(val, 0, NULL);
    return str;
}

static const char *pushbin(const char *str)
{
    long val = 0;
    while (*str == '0' || *str == '1') {
        val = (val << 1) | (*str - '0');
        ++str;
    }
    stackarg(val, 0, NULL);
    return str;
}

static const char *pushstr(const char *str)
{
    stackarg(0, SYM_STRING, str);
    while (*str != '\0' && *str != '\"')
        ++str;
    if (*str == '\"')
        ++str;
    return str;
}

static const char *pushsymbol(const char *str)
{
    SYMBOL *sym;
    const char *ptr;
    bool macro = false;
    
    for (ptr = str; *ptr == '_' || *ptr == '.' || is_alpha_num(*ptr); ++ptr);

    if (ptr == str)
    {
        /* [phf] removed
        asmerr( ERROR_ILLEGAL_CHARACTER, false, str );
        */
        error_fmt("Invalid character '%s'!", str); /* TODO: (*str) instead? */
        /* TODO: should go in error handling code, not here! [phf] */
        printf("char = '%c' %d (-1: %d)\n", *str, *str, *(str-1));
        if (FI_listfile != NULL) {
            fprintf(FI_listfile, "char = '%c' code %d\n", *str, *str);
        }
        return str+1;
    }

    if (*ptr == '$')
        ptr++;

    /*
        make sure we pass non-negative here, maybe we can change
        find_symbol() signature [phf]
    */
    assert((ptr-str) >= 0);

    if ((sym = find_symbol(str, ptr - str)) != NULL)
    {
        if ((sym->flags & SYM_UNKNOWN) != 0) {
            ++Redo_eval;
        }
        
        if ((sym->flags & SYM_MACRO) != 0) {
            macro = true;
            sym = eval(sym->string, false);
            assert(sym != NULL);
        }
        
        if ((sym->flags & SYM_STRING) != 0) {
            stackarg(0, SYM_STRING, sym->string);
        } 
        else {
            stackarg(sym->value, sym->flags & SYM_UNKNOWN, NULL);
        }
        
        sym->flags |= SYM_REF|SYM_MASREF;
        
        if (macro) {
            free_symbol_list(sym);
        }
    }
    else {
        stackarg(0L, SYM_UNKNOWN, NULL);
        sym = create_symbol(str, ptr - str);
        assert(sym != NULL);
        sym->flags = SYM_REF|SYM_MASREF|SYM_UNKNOWN;
        ++Redo_eval;
    }
    return ptr;
}

/* vim: set tabstop=4 softtabstop=4 expandtab shiftwidth=4 autoindent: */
