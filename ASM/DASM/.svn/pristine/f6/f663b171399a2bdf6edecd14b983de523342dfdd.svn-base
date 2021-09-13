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

#include "symbols.h"

#include "asm.h"
#include "errors.h"
#include "util.h"
#include "version.h"

#include <assert.h>
#include <limits.h>

/*@unused@*/
SVNTAG("$Id$");

/*
  Size of SYMBOL hash table. Must be a power of two
  for the AND trick to work!
*/
#define SHASHSIZE ((size_t)(1<<10))
#define SHASHAND (SHASHSIZE-1)

/* Hash table for symbols. */
static SYMBOL *SHash[SHASHSIZE];

/* Special symbols returned by find_symbol. */
static SYMBOL special_org; /* "." or current origin (PC) */
static SYMBOL special_dv_eqm; /* ".." or special symbol in EQM as part of DV */
static SYMBOL special_checksum; /* "..." or current checksum */

/* Name of symbol file if we should write one. */
/*@null@*/
static const char *symbol_file_name = NULL;

/* Custom memory management for SYMBOLs.  */
/*@null@*/
static SYMBOL *symbol_free_list = NULL;

/* How to sort the symbol table for -T option. */
static sortmode_t F_sortmode = SORTMODE_DEFAULT;

bool valid_sort_mode(int mode)
{
    return (SORTMODE_MIN <= mode && mode <= SORTMODE_MAX);
}

void set_sort_mode(sortmode_t mode)
{
    assert(valid_sort_mode(mode));
    F_sortmode = mode;
}

static unsigned int hash_symbol(const char *str, size_t len)
{
    return hash_string(str, len) & SHASHAND;
}

void set_special_dv_symbol(int value, dasm_flag_t flags)
{
    special_dv_eqm.value = value;
    special_dv_eqm.flags = flags;
}

SYMBOL *find_symbol(const char *str, size_t len)
{
    unsigned int hash;
    SYMBOL *sym;
    char buf[MAX_SYM_LEN+14]; /* historical */

    assert(str != NULL);
    assert(len > 0);
    
    if (len > MAX_SYM_LEN) {
        len = MAX_SYM_LEN;
        /* TODO: should we truncate? ever? [phf] */
    }

    if (str[0] == '.') {
        /* TODO: shouldn't this be a big else-if cascade instead? [phf] */
        /* TODO: isn't '*' a synonym for '.' since Olaf's version? [phf] */
        if (len == 1) {
            if ((Csegment->flags & SF_RORG) != 0) {
                special_org.flags = Csegment->rflags & SYM_UNKNOWN;
                special_org.value = Csegment->rorg;
            }
            else {
                special_org.flags = Csegment->flags & SYM_UNKNOWN;
                special_org.value = Csegment->org;
            }
            return &special_org;
        }
        if (len == 2 && str[1] == '.') {
            return &special_dv_eqm;
        }
        if (len == 3 && str[1] == '.' && str[2] == '.') {
            special_checksum.flags = 0;
            special_checksum.value = CheckSum;
            return &special_checksum;
        }
        assert(len < INT_MAX);
        sprintf(buf, "%lu%.*s", Localindex, (int) len, str);
        len = strlen(buf);
        str = buf;
    }
    else if (str[len-1] == '$') {
        assert(len < INT_MAX);
        sprintf(buf, "%lu$%.*s", Localdollarindex, (int) len, str);
        len = strlen(buf);
        str = buf;
    }
    else {
        /* not a special identifier? i think that's what this case is,
           there was no "else" at all originally [phf] */
    }
    
    hash = hash_symbol(str, len);
    for (sym = SHash[hash]; sym != NULL; sym = sym->next) {
        if ((sym->namelen == len) && (memcmp(sym->name, str, len) == 0)) {
            break;
        }
    }
    return sym;
}

SYMBOL *create_symbol(const char *str, size_t len)
{
    SYMBOL *sym;
    unsigned int hash;
    char buf[MAX_SYM_LEN + 14]; /* historical */
    char *name;

    assert(str != NULL);
    assert(len > 0);

    if (len > MAX_SYM_LEN) {
        /* TODO: truncate? is that good? [phf] */
        len = MAX_SYM_LEN;
    }
    
    if (str[0] == '.')
    {
        assert(len < INT_MAX);
        sprintf(buf, "%lu%.*s", Localindex, (int) len, str);
        len = strlen(buf);
        str = buf;
    }
    else if (str[len-1] == '$')
    {
        assert(len < INT_MAX);
        sprintf(buf, "%lu$%.*s", Localdollarindex, (int) len, str);
        len = strlen(buf);
        str = buf;
    }
    else {
        /* not a special identifier? i think that's what this case is,
           there was no "else" at all originally [phf] */
    }

    sym = alloc_symbol();
    name = small_alloc(len+1);
    memcpy(name, str, len); /* small_alloc zeros the array for us */
    sym->name = name;
    sym->namelen = len;
    hash = hash_symbol(str, len);
    sym->next = SHash[hash];
    sym->flags = SYM_UNKNOWN;
    SHash[hash] = sym;
    return sym;
}

/*
*  Label Support Routines
*/

void programlabel(void)
{
    size_t len;
    SYMBOL *sym;
    SEGMENT *cseg = Csegment;
    const char *str;
    bool rorg = (cseg->flags & SF_RORG) != 0;
    dasm_flag_t cflags = (rorg) ? cseg->rflags : cseg->flags;
    unsigned long pc = (rorg) ? cseg->rorg : cseg->org;
    
    Plab = cseg->org;
    Pflags = cseg->flags;
    str = Av[0];
    if (*str == 0)
        return;
    len = strlen(str);


    if (str[len-1] == ':')
        --len;
    
    if (str[0] != '.' && str[len-1] != '$')
    {
        Lastlocaldollarindex++;
        Localdollarindex = Lastlocaldollarindex;
    }
    
    /*
    *	Redo:	unknown and referenced
    *		referenced and origin not known
    *		known and phase error	 (origin known)
    */
    
    if ((sym = find_symbol(str, len)) != NULL)
    {
        if ((sym->flags & (SYM_UNKNOWN|SYM_REF)) == (SYM_UNKNOWN|SYM_REF))
        {
            ++Redo;
            Redo_why |= REASON_FORWARD_REFERENCE;
            debug_fmt("redo 13: '%s' %04x %04x", sym->name, sym->flags, cflags);
        }
        else if ((cflags & SYM_UNKNOWN) != 0 && (sym->flags & SYM_REF) != 0)
        {
            ++Redo;
            Redo_why |= REASON_FORWARD_REFERENCE;
        }
        else if ((cflags & SYM_UNKNOWN) == 0 && (sym->flags & SYM_UNKNOWN) == 0)
        {
            if (pc != sym->value)
            {
                /*
                    If we had an unevaluated IF expression in the
                    previous pass, don't complain about phase errors
                    too loudly.
                */
                if (F_verbose >= 1 || !(Redo_if & (REASON_OBSCURE)))
                {
                    /* [phf] removed
                    char sBuffer[ MAX_SYM_LEN * 2 ];
                    sprintf( sBuffer, "%s %s", sym->name, sftos( sym->value, 0 ) );
                    */
                    /* TODO: the following was already removed before [phf]
                       started hacking, it looks like the way Andrew
                       put the error message together, some information
                       might be missing? need to check with Matt's DASM */
                    /*, sftos(sym->value,
                    sym->flags) ); , sftos(pc, cflags & 7));*/
                    /* [phf] removed:
                    asmerr( ERROR_LABEL_MISMATCH, false, sBuffer );
                    */
                    error_fmt("Label mismatch...\n --> %s %s",
                              sym->name, sftos(sym->value, 0));
                }
                ++Redo;
                Redo_why |= REASON_PHASE_ERROR;
            }
        }
    }
    else
    {
        sym = create_symbol( str, len );
    }
    sym->value = pc;
    sym->flags = (sym->flags & ~SYM_UNKNOWN) | (cflags & SYM_UNKNOWN);
}

SYMBOL *alloc_symbol(void)
{
    SYMBOL *sym;

    if (symbol_free_list != NULL) {
        sym = symbol_free_list;
        symbol_free_list = symbol_free_list->next;
        memset(sym, 0, sizeof(SYMBOL));
    }
    else {
        sym = small_alloc(sizeof(SYMBOL));
    }

    return sym;
}

static void free_symbol(SYMBOL *sym)
{
    assert(sym != NULL);

    if ((sym->flags & SYM_STRING) != 0) {
        free(sym->string); /* TODO: really how we allocate those? [phf] */
    }
    sym->next = symbol_free_list;
    symbol_free_list = sym;
}

void free_symbol_list(SYMBOL *sym)
{
    SYMBOL *next;

    while (sym != NULL) {
        next = sym->next;
        free_symbol(sym);
        sym = next;
    }
}

void clear_all_symbol_refs(void)
{
    SYMBOL *sym;
    size_t i;

    for (i = 0; i < SHASHSIZE; i++) {
        for (sym = SHash[i]; sym != NULL; sym = sym->next) {
            sym->flags &= ~SYM_REF;
        }
    }
}

static size_t nof_unresolved_symbols(void)
{
    SYMBOL *sym;
    size_t unresolved = 0;
    size_t i;
    
    /* Pre-count unresolved symbols */
    for (i = 0; i < SHASHSIZE; i++) {
        for (sym = SHash[i]; sym != NULL; sym = sym->next) {
            if ((sym->flags & SYM_UNKNOWN) != 0) {
                unresolved++;
            }
        }
    }
            
	return unresolved;
}

size_t ShowUnresolvedSymbols(void)
{
    SYMBOL *sym;
    size_t i;
    
    size_t nUnresolved = nof_unresolved_symbols();
    if (nUnresolved > 0)
    {
        printf("--- Unresolved Symbol List\n");
        
        for (i = 0; i < SHASHSIZE; i++) {
            for (sym = SHash[i]; sym != NULL; sym = sym->next) {
                if ((sym->flags & SYM_UNKNOWN) != 0) {
                    printf(
                        "%-24s %s\n",
                        sym->name,
                        sftos(sym->value, sym->flags)
                    );
                }
            }
        }
                
        printf(
            "--- %zu Unresolved Symbol%c\n\n",
            nUnresolved,
            (nUnresolved == 1) ? ' ' : 's'
        );
    }
    
    return nUnresolved;
}

static int CompareAlpha( const void *arg1, const void *arg2 )
{
    /* Simple alphabetic ordering comparison function for quicksort */

    const SYMBOL *sym1 = *(SYMBOL * const *) arg1;
    const SYMBOL *sym2 = *(SYMBOL * const *) arg2;
    
    /*
       The cast above is wild, thank goodness the Linux man page
       for qsort(3) has an example explaining it... :-) [phf]

       TODO: Note that we compare labels case-insensitive here which
       is not quite right; I believe we should be case-sensitive as
       in other contexts where symbols (labels) are compared. But
       the old CompareAlpha() was case-insensitive as well, so I
       didn't want to change that right now... [phf]
    */

    return strcasecmp(sym1->name, sym2->name);
}

static int CompareAddress( const void *arg1, const void *arg2 )
{
    /* Simple numeric ordering comparison function for quicksort */
    
    const SYMBOL *sym1 = *(SYMBOL * const *) arg1;
    const SYMBOL *sym2 = *(SYMBOL * const *) arg2;
    
    return sym1->value - sym2->value;
}

/*
  Display symbol table. Sorted if enough memory, unsorted otherwise.
*/
void ShowSymbols(FILE *file)
{
    SYMBOL **symArray;
    SYMBOL *sym;
    size_t i;
    size_t nSymbols = 0;

    fprintf(file, "--- Symbol List");

    /* First count the number of symbols */
    for (i = 0; i < SHASHSIZE; i++) {
        for (sym = SHash[i]; sym != NULL; sym = sym->next) {
            nSymbols++;
        }
    }
        
    /* Malloc an array of pointers to data */
    symArray = (SYMBOL**) malloc(nSymbols * sizeof(SYMBOL*));
    if (symArray == NULL) {
        fprintf(file, " (unsorted - not enough memory to sort!)\n");
            
        /* Display complete symbol table */
        for (i = 0; i < SHASHSIZE; i++) {
            for (sym = SHash[i]; sym != NULL; sym = sym->next) {
                fprintf(file, "%-24s %s\n", sym->name, sftos(sym->value, sym->flags));
            }
        }
    }
    else {
        size_t nPtr = 0;
         
        /* Copy the element pointers into the symbol array */
        for (i = 0; i < SHASHSIZE; i++) {
            for (sym = SHash[i]; sym != NULL; sym = sym->next) {
                symArray[nPtr++] = sym;
            }
        }
                
        if (F_sortmode == SORTMODE_ADDRESS) {
            /* Sort via address */
            fprintf(file, " (sorted by address)\n");
            qsort(symArray, nPtr, sizeof(SYMBOL*), CompareAddress);
        }
        else if (F_sortmode == SORTMODE_ALPHA) {
            /* Sort via name */
            fprintf(file, " (sorted by symbol)\n");
            qsort(symArray, nPtr, sizeof(SYMBOL*), CompareAlpha);
        }
        else {
            assert(false);
        }
                
        /* Now display sorted list */
                
        for (i = 0; i < nPtr; i++) {
            /* TODO: format is different here that above [phf] */
            fprintf(file, "%-24s %-12s", symArray[i]->name, sftos(symArray[i]->value, symArray[i]->flags));

            if ((symArray[i]->flags & SYM_STRING) != 0) {
                /* If a string, display actual string */
                /* TODO: we don't do this above? [phf] */
                fprintf(file, " \"%s\"", symArray[i]->string);
            }
            fprintf(file, "\n");
        }
                
        free(symArray);
    }
        
    fputs("--- End of Symbol List.\n", file);
}

/* Functions for writing symbol files. */

void set_symbol_file_name(const char *name)
{
    assert(symbol_file_name == NULL);
    assert(name != NULL);
    symbol_file_name = name;
}

void DumpSymbolTable(void)
{
    if (symbol_file_name != NULL)
    {
        FILE *fi = fopen(symbol_file_name, "w");
        if (fi != NULL) {
            ShowSymbols(fi);
            if (fclose(fi) != 0) {
                warning_fmt("Problem closing symbol file '%s'.",
                            symbol_file_name);
            }
        }
        else {
            warning_fmt("Unable to open symbol dump file '%s'.",
                        symbol_file_name);
        }
    }
}

void debug_symbol_hash_collisions(void)
{
    const SYMBOL *sym;
    int collisions = 0;
    size_t i;
    bool first;

    for (i = 0; i < SHASHSIZE; i++) {
        first = true;
        for (sym = SHash[i]; sym != NULL; sym = sym->next) {
            if (!first) {
                collisions += 1;
            }
            else {
                first = false;
            }
        }
    }

    debug_fmt("Collisions for SYMBOLS: %d", collisions);
}

/* vim: set tabstop=4 softtabstop=4 expandtab shiftwidth=4 autoindent: */
