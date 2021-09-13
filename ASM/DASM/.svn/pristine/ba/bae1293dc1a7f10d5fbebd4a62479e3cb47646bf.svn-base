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
 *  MAIN.C
 *  DASM   sourcefile
 *  NOTE: must handle mnemonic extensions and expression decode/compare.
 */

#include "asm.h"
#include "errors.h"
#include "symbols.h"
#include "util.h"
#include "version.h"

#include <assert.h>
#include <ctype.h>

/*@unused@*/
SVNTAG("$Id$");

#define MAXLINE 1024
#define ISEGNAME    "INITIAL CODE SEGMENT"

/*
   replace old atoi() calls; I wanted to protect this using
   #ifdef strtol but the C preprocessor doesn't recognize
   function names, at least not GCC's; we should be safe
   since MS compilers document strtol as well... [phf]
*/
#define atoi(x) ((int)strtol(x, (char **)NULL, 10))

static const char *cleanup(char *buf, bool bDisable);

static MNEMONIC *parse(char *buf);
static MNEMONIC *findmne(const char *str);
static void clearsegs(void);

static unsigned int hash_mnemonic(const char *str);
static void outlistfile(const char *);

static const char *Extstr;
static int pass;
static int Inclevel;

static bool F_ListAllPasses = false;
static bool bDoAllPasses = false;
static int nMaxPasses = 10;

/* debugging helper for hash collisions */
/*
    Using ./dasm ../test/example.asm for all of these...

    Original hash functions and 1024 sizes:

      Collisions for MNEMONICS: 15
      Collisions for SYMBOLS: 27

    Original hash functions and 4096 sizes:

      Collisions for MNEMONICS: 11
      Collisions for SYMBOLS: 16

    DJB hash function and 1024 sizes:

      Collisions for MNEMONICS: 5
      Collisions for SYMBOLS: 11

    DJB hash function and 4096 sizes:

      Collisions for MNEMONICS: 1
      Collisions for SYMBOLS: 4
*/
static void debug_mnemonic_hash_collisions(void)
{
    MNEMONIC *mne;
    int collisions = 0;
    int i;
    bool first;

    for (i = 0; i < MHASHSIZE; i++) {
        first = true;
        for (mne = MHash[i]; mne != NULL; mne = mne->next) {
            if (!first) {
                collisions += 1;
            }
            else {
                first = false;
            }
        }
    }

    debug_fmt("Collisions for MNEMONICS: %d", collisions);
}

static void debug_hash_collisions(void)
{
    debug_mnemonic_hash_collisions();
    debug_symbol_hash_collisions();
}

#define SHOW_SEGMENTS_FORMAT "%-24s %-3s %-8s %-8s %-8s %-8s\n"

static void ShowSegments(void)
{
    SEGMENT *seg;
    const char *bss;

    printf("\n----------------------------------------------------------------------\n");
    printf(SHOW_SEGMENTS_FORMAT, "SEGMENT NAME", "", "INIT PC", "INIT RPC", "FINAL PC", "FINAL RPC");
    
    for (seg = Seglist; seg != NULL; seg = seg->next) {
        bss = ((seg->flags & SF_BSS) != 0) ? "[u]" : "   ";

        printf(
            SHOW_SEGMENTS_FORMAT,
            seg->name,
            bss,
            sftos(seg->initorg, seg->initflags),
            sftos(seg->initrorg, seg->initrflags),
            sftos(seg->org, seg->flags),
            sftos(seg->rorg, seg->rflags)
        );
    }
    (void) puts("----------------------------------------------------------------------");
    
    printf("%d references to unknown symbols.\n", Redo_eval);
    printf("%d events requiring another assembler pass.\n", Redo);
    
    if (Redo_why != 0)
    {
        if ((Redo_why & REASON_MNEMONIC_NOT_RESOLVED) != 0)
            printf(" - Expression in mnemonic not resolved.\n");
        
        if ((Redo_why & REASON_OBSCURE) != 0)
            printf(" - Obscure reason - to be documented :)\n");
        
        if ((Redo_why & REASON_DC_NOT_RESOVED) != 0)
            printf(" - Expression in a DC not resolved.\n");
        
        if ((Redo_why & REASON_DV_NOT_RESOLVED_PROBABLY) != 0)
            printf(" - Expression in a DV not resolved (probably in DV's EQM symbol).\n");
        
        if ((Redo_why & REASON_DV_NOT_RESOLVED_COULD) != 0)
            printf(" - Expression in a DV not resolved (could be in DV's EQM symbol).\n");
        
        if ((Redo_why & REASON_DS_NOT_RESOLVED) != 0)
            printf(" - Expression in a DS not resolved.\n");
        
        if ((Redo_why & REASON_ALIGN_NOT_RESOLVED) != 0)
            printf(" - Expression in an ALIGN not resolved.\n");
        
        if ((Redo_why & REASON_ALIGN_RELOCATABLE_ORIGIN_NOT_KNOWN) != 0)
            printf(" - ALIGN: Relocatable origin not known (if in RORG at the time).\n");
        
        if ((Redo_why & REASON_ALIGN_NORMAL_ORIGIN_NOT_KNOWN) != 0)
            printf(" - ALIGN: Normal origin not known	(if in ORG at the time).\n");
        
        if ((Redo_why & REASON_EQU_NOT_RESOLVED) != 0)
            printf(" - EQU: Expression not resolved.\n");
        
        if ((Redo_why & REASON_EQU_VALUE_MISMATCH) != 0)
            printf(" - EQU: Value mismatch from previous pass (phase error).\n");
        
        if ((Redo_why & REASON_IF_NOT_RESOLVED) != 0)
            printf(" - IF: Expression not resolved.\n");
        
        if ((Redo_why & REASON_REPEAT_NOT_RESOLVED) != 0)
            printf(" - REPEAT: Expression not resolved.\n");
        
        if ((Redo_why & REASON_FORWARD_REFERENCE) != 0)
            printf(" - Label defined after it has been referenced (forward reference).\n");
        
        if ((Redo_why & REASON_PHASE_ERROR) != 0)
            printf(" - Label value is different from that of the previous pass (phase error).\n");
    }

    printf( "\n" );
}

static void print_usage(void)
{
    (void) puts(DASM_ID);
    DASM_PRINT_LEGAL
    (void) puts("");
    (void) puts("Usage: dasm sourcefile [options]");
    (void) puts("");
    (void) puts("-f#      output format 1-3 (default 1)");
    (void) puts("-oname   output file name (else a.out)");
    (void) puts("-lname   list file name (else none generated)");
    (void) puts("-Lname   list file, containing all passes");
    (void) puts("-sname   symbol dump file name (else none generated)");
    (void) puts("-v#      verboseness 0-4 (default 0)");
    (void) puts("-d#      debug mode (for developers)");
    (void) puts("-Dsymbol              define symbol, set to 0");
    (void) puts("-Dsymbol=expression   define symbol, set to expression");
    (void) puts("-Msymbol=expression   define symbol using EQM (same as -D)");
    (void) puts("-Idir    search directory for INCLUDE and INCBIN");
    (void) puts("-p#      maximum number of passes");
    (void) puts("-P#      maximum number of passes, with fewer checks");
    (void) puts("-T#      symbol table sorting (default 0 = alphabetical, 1 = address/value)");
    (void) puts("-E#      error format (default 0 = MS, 1 = Dillon, 2 = GNU)");
    (void) puts("");
    DASM_PRINT_BUGS
}

static void parse_options_fail(void)
{
    print_usage();
    /* TODO: if we passed a message, we could be more detailed */
    fatal_fmt("Check command-line format.");
    /* TODO: is this the best we can do? */
    exit(EXIT_FAILURE);
}

static bool char_starts_option(char c)
{
    return (c == '-')  /* Unix */
        || (c == '/'); /* Windows */
}

static void parse_error_format(char *str)
{
    int format = atoi(str);
    if (valid_error_format(format)) {
        set_error_format(format);
    }
    else {
        panic_fmt("Invalid error format for -E, must be 0, 1, 2");
    }
}

static void parse_sort_mode(char *str)
{
    int mode = atoi(str);
    if (valid_sort_mode(mode)) {
        set_sort_mode(mode);
    }
    else {
        panic_fmt("Invalid sorting mode for -T option, must be 0 or 1");
    }
}

static void parse_debug_trace(char *str)
{
    int debug = atoi(str);
    if (debug == 0) {
        /* nothing to do, already at default error level? */
    }
    else if (debug == 1) {
        set_error_level(ERRORLEVEL_DEBUG);
    }
    else {
        panic_fmt("Invalid debug mode for -d option, must be 0 or 1");
    }
    /* TODO: get rid of this message? */
    printf("Debug trace %s\n", debug != 0 ? "ON" : "OFF");
}

static void parse_define(char kind, char *str)
{
    /*const*/ char *name = str; /* the name we define */
    const char *value = "0"; /* the value we define it to */
    char *equals; /* location of '=' in str, if any */

    assert(kind == 'M' || kind == 'D');

    equals = strchr(str, '=');
    if (equals != NULL) {
        *equals = '\0'; /* terminate name */
        value = equals + 1; /* override default value */
    }

    Av[0] = name;

    if (kind == 'M') {
        v_eqm(value, NULL);
    }
    else { /* kind == 'D' */
        v_set(value, NULL);
    }
}

static void parse_output_format(char *str)
{
    /* TODO: switch to enum format/check */
    F_format = atoi(str);
    if (F_format < FORMAT_DEFAULT || F_format >= FORMAT_MAX) {
        panic_fmt("Illegal format specification");
    }
}

/* TODO: still need to improve option parsing and errors for it [phf] */
static void parse_options(int ac, char **av)
{
    int i;

    if (ac < 2) {
        parse_options_fail(/* No source file given. */);
    }
    
    for (i = 2; i < ac; ++i) {
        if (char_starts_option(av[i][0])) {
            char *str = av[i]+2;
            /* all options require an argument! */
            if (strlen(str) == 0) {
                /* TODO: print usage, too? can't use panic then... */
                panic_fmt("Missing argument for -%c option!", av[i][1]);
            }
            switch(av[i][1])
            {
            case 'E':
                parse_error_format(str);
                break;

            case 'T':
                parse_sort_mode(str);
                break;

            case 'd':
                parse_debug_trace(str);
                break;

            case 'M':
            case 'D':
                parse_define(av[i][1], str);
                break;

            case 'f':
                parse_output_format(str);
                break;

            case 'o':
                F_outfile = str;
                break;

            case 'L':
                F_ListAllPasses = true;
                /* fall through to 'l' */
            case 'l':
                F_listfile = str;
                break;

            case 'P':
                bDoAllPasses = true;
                /* fall through to 'p' */
            case 'p':
                nMaxPasses = atoi(str);
                break;

            case 's':
                set_symbol_file_name(str);
                break;

            case 'v':
                F_verbose = atoi(str);
                break;

            case 'I':
                v_incdir(str, NULL);
                break;
                
            default:
                parse_options_fail(/* Unknown option. */);
                break;
            }
            /* TODO: "continue" because surrounding "if" has no "else"?  */
            continue;
        }
        parse_options_fail(/* Illegal start of option. */);
    }
}

static int MainShadow(int ac, char **av)
{
/*    int nError = ERROR_NONE;*/
    
    char buf[MAXLINE];
    MNEMONIC *mne;
    
    int oldredo = -1;
    unsigned long oldwhy = 0;
    int oldeval = 0;
    
    addhashtable(Ops);
    pass = 1;

    parse_options(ac, av);

    /* INITIAL SEGMENT */
    {
        SEGMENT *seg = small_alloc(sizeof(SEGMENT));
        seg->name = strcpy(small_alloc(sizeof(ISEGNAME)), ISEGNAME);
        seg->flags= seg->rflags = seg->initflags = seg->initrflags = SF_UNKNOWN;
        Csegment = Seglist = seg;
    }

    /* TOP LEVEL IF */
    {
        IFSTACK *ifs = zero_malloc(sizeof(IFSTACK));
        ifs->file = NULL;
        ifs->flags = IFF_BASE;
        ifs->acctrue = true;
        ifs->xtrue  = true;
        Ifstack = ifs;
    }
    
    
nextpass:
    
    
    if (F_verbose > 0) {
        (void) puts("");
        printf("START OF PASS: %d\n", pass);
    }
    
    Localindex = Lastlocalindex = 0;
    
    Localdollarindex = Lastlocaldollarindex = 0;
    
    FI_temp = fopen(F_outfile, "wb");
    Fisclear = true;
    CheckSum = 0;
    if (FI_temp == NULL) {
        printf("Warning: Unable to [re]open '%s'\n", F_outfile);
        fatal_fmt("Unable to open file.");
/*        return ERROR_FILE_ERROR;*/
        return EXIT_FAILURE; /* needed for rest of code to work? [phf] */
    }
    if (F_listfile != NULL) {

        FI_listfile = fopen(F_listfile,
            F_ListAllPasses && (pass > 1)? "a" : "w");

        if (FI_listfile == NULL) {
            printf("Warning: Unable to [re]open '%s'\n", F_listfile);
            fatal_fmt("Unable to open file.");
/*            return ERROR_FILE_ERROR;*/
            return EXIT_FAILURE; /* needed for rest of code to work? [phf] */
        }
    }
    pushinclude(av[1]);
    
    while (pIncfile != NULL)
    {
        for (;;) {
            const char *comment;
            if ((pIncfile->flags & INF_MACRO) != 0) {
                if (pIncfile->strlist == NULL) {
                    Av[0] = "";
                    v_mexit(NULL, NULL);
                    continue;
                }
                strcpy(buf, pIncfile->strlist->buf);
                pIncfile->strlist = pIncfile->strlist->next;
            }
            else
            {
                if (fgets(buf, MAXLINE, pIncfile->fi) == NULL)
                    break;
            }
            
            debug_fmt("%08lx %s", (unsigned long) pIncfile, buf);
            
            comment = cleanup(buf, false);
            ++pIncfile->lineno;
            mne = parse(buf);
            
            if (Av[1][0])
            {
                if (mne != NULL)
                {
                    if ((mne->flags & MF_IF) != 0 || (Ifstack->xtrue && Ifstack->acctrue))
                        (*mne->vect)(Av[2], mne);
                }
                else
                {
                    if (Ifstack->xtrue && Ifstack->acctrue)
                    {
                        /* [phf] removed
                        asmerr( ERROR_UNKNOWN_MNEMONIC, false, Av[1] );
                        */
                        error_fmt("Unknown mnemonic '%s'!", Av[1]);
                    }
                }
                
            }
            else
            {
                if (Ifstack->xtrue && Ifstack->acctrue)
                    programlabel();
            }
            
            if (FI_listfile != NULL && ListMode) {
                outlistfile(comment);
            }
        }
        
        while (Reploop != NULL && Reploop->file == pIncfile)
            rmnode((void **)&Reploop, sizeof(REPLOOP));
        
        while (Ifstack->file == pIncfile)
            rmnode((void **)&Ifstack, sizeof(IFSTACK));
        
        if (fclose(pIncfile->fi) != 0) {
            warning_fmt("Problem closing include file '%s'.", pIncfile->name);
        }
        free(pIncfile->name); /* can't do anything about this warning :-( [phf] */
        --Inclevel;
        rmnode((void **)&pIncfile, sizeof(INCFILE));
        
        if (pIncfile != NULL) {
        /*
        if (F_verbose > 1)
        printf("back to: %s\n", Incfile->name);
            */
            if (FI_listfile != NULL) {
                fprintf(FI_listfile, "------- FILE %s\n", pIncfile->name);
            }
        }
    }

    if (F_verbose >= 1) {
        ShowSegments();
    }
    
    if (F_verbose >= 3) {
        if (Redo == 0 || F_verbose == 4) {
            ShowSymbols(stdout);
        }
        ShowUnresolvedSymbols();
    }
    
    closegenerate();
    assert(FI_temp != NULL); /* fclose() undefined for NULL [phf] */
    if (fclose(FI_temp) != 0) {
        warning_fmt("Problem closing temporary file '%s'.", F_outfile);
    }
    if (FI_listfile != NULL) {
        if (fclose(FI_listfile) != 0) {
            warning_fmt("Problem closing list file '%s'.", F_listfile);
        }
    }
    
    if (Redo != 0)
    {
        if ( !bDoAllPasses )
            if (Redo == oldredo && Redo_why == oldwhy && Redo_eval == oldeval)
            {
                ShowUnresolvedSymbols();
                fatal_fmt("Source is not resolvable.");
/*                return ERROR_NOT_RESOLVABLE;*/
                return EXIT_FAILURE; /* needed for rest of code to work? [phf] */
            }
            
            oldredo = Redo;
            oldwhy = Redo_why;
            oldeval = Redo_eval;
            Redo = 0;
            Redo_why = 0;
            Redo_eval = 0;

            Redo_if <<= 1;
            ++pass;
            
            if (number_of_fatals() > 0)
            {
                printf("Unrecoverable error(s) in pass, aborting assembly!\n");
            }
            else if ( pass > nMaxPasses )
            {
                /* [phf] removed
                char sBuffer[64];
                sprintf( sBuffer, "%d", pass );
                return asmerr( ERROR_TOO_MANY_PASSES, false, sBuffer );
                */
                fatal_fmt("Too many passes (%d)!", pass);
                return EXIT_FAILURE; /* TODO: refactor somehow? */
            }
            else
            {
                clear_all_symbol_refs();
                clearsegs();
                goto nextpass;
            }
    }

    debug_hash_collisions();

/*    return nError;*/
    return EXIT_SUCCESS;
}


static int tabit(const char *buf1, char *buf2)
{
    char *bp;
    const char *ptr;
    int j, k;
    
    bp = buf2;
    ptr= buf1;
    for (j = 0; *ptr != '\0' && *ptr != '\n'; ++ptr, ++bp, j = (j+1)&7) {
        *bp = *ptr;
        if (*ptr == '\t') {
            /* optimize out spaces before the tab */
            while (j > 0 && bp[-1] == ' ') {
                bp--;
                j--;
            }
            j = 0;
            *bp = '\t';         /* recopy the tab */
        }
        if (j == 7 && *bp == ' ' && bp[-1] == ' ') {
            k = j;
            while (k-- >= 0 && *bp == ' ')
                --bp;
            *++bp = '\t';
        }
    }
    while (bp != buf2 && (bp[-1] == ' ' || bp[-1] == '\t'))
        --bp;
    *bp++ = '\n';
    *bp = '\0';
    assert(((int)(bp - buf2)) >= 0); /* passed to a size_t in places [phf] */
    return (int)(bp - buf2);
}

static void outlistfile(const char *comment)
{
    char xtrue;
    char c;
    static char buf1[MAXLINE+32];
    static char buf2[MAXLINE+32];
    const char *ptr;
    const char *dot;
    int i, j;
    int len;
    
    /* TODO: what does this mean exactly? [phf] */
    if ((pIncfile->flags & INF_NOLIST) != 0) {
        return;
    }
    
    assert(FI_listfile != NULL);

    xtrue = (Ifstack->xtrue && Ifstack->acctrue) ? ' ' : '-';
    c = ((Pflags & SF_BSS) != 0) ? 'U' : ' ';
    ptr = Extstr;
    dot = "";
    if (ptr)
        dot = ".";
    else
        ptr = "";
    
    len = snprintf(buf1, sizeof(buf1), "%7lu %c%s", pIncfile->lineno, c, sftos(Plab, Pflags & 7));
    assert(len < (int)sizeof(buf1));
    j = strlen(buf1);
    for (i = 0; i < Glen && i < 4; ++i, j += 3)
        sprintf(buf1+j, "%02x ", Gen[i]);
    if (i < Glen && i == 4)
        xtrue = '*';
    for (; i < 4; ++i) {
        buf1[j] = buf1[j+1] = buf1[j+2] = ' ';
        j += 3;
    }
    sprintf(buf1+j-1, "%c%-10s %s%s%s\t%s\n",
        xtrue, Av[0], Av[1], dot, ptr, Av[2]);
    if (comment[0] != '\0') { /*  tab and comment */
        j = strlen(buf1) - 1;
        sprintf(buf1+j, "\t;%s", comment);
    }
    fwrite(buf2, tabit(buf1,buf2), 1, FI_listfile);
    Glen = 0;
    Extstr = NULL;
}

char *sftos(long val, dasm_flag_t flags)
{
    static char buf[MAX_SYM_LEN + 14];
    static char c;
    char *ptr = (c) ? buf : buf + sizeof(buf) / 2;
    
    memset(buf, 0, sizeof(buf));
    
    c = 1 - c;
    
    sprintf(ptr, "%04lx ", val);
    
    if ((flags & SYM_UNKNOWN) != 0) {
        strcat( ptr, "???? ");
    }
    else {
        strcat( ptr, "     " );
    }
    
    if ((flags & SYM_STRING) != 0) {
        strcat( ptr, "str ");
    }
    else {
        strcat( ptr, "    " );
    }
    
    if ((flags & SYM_MACRO) != 0) {
        strcat( ptr, "eqm ");
    }
    else {
        strcat( ptr, "    " );
    }
    
    if ((flags & (SYM_MASREF|SYM_SET)) != 0) {
        strcat( ptr, "(" );
    }
    else {
        strcat( ptr, " " );
    }
    
    if ((flags & SYM_MASREF) != 0) {
        strcat( ptr, "R" );
    }
    else {
        strcat( ptr, " " );
    }
    
    if ((flags & SYM_SET) != 0) {
        strcat( ptr, "S" );
    }
    else {
        strcat( ptr, " " );
    }
    
    if ((flags & (SYM_MASREF|SYM_SET)) != 0) {
        strcat( ptr, ")" );
    }
    else {
        strcat( ptr, " " );
    }
    
    return ptr;
}

static void clearsegs(void)
{
    SEGMENT *seg;
    
    for (seg = Seglist; seg != NULL; seg = seg->next) {
        seg->flags = (seg->flags & SF_BSS) | SF_UNKNOWN;
        seg->rflags = seg->initflags = seg->initrflags = SF_UNKNOWN;
    }
}

static const char *cleanup(char *buf, bool bDisable)
{
    char *str;
    STRLIST *strlist;
    int arg, add;
    const char *comment = "";
    
    for (str = buf; *str != '\0'; ++str)
    {
        switch(*str)
        {
        case ';':
            comment = (char *)str + 1;
            /*    FALL THROUGH    */
        case '\r':
        case '\n':
            goto br2;
        case '\t':
            *str = ' ';
            break;
        case '\'':
            ++str;
            if (*str == '\t')
                *str = ' ';
            if (*str == '\n' || *str == '\0')
            {
                str[0] = ' ';
                str[1] = '\0';
            }
            if (str[0] == ' ')
                str[0] = '\x80';
            break;
        case '\"':
            ++str;
            while (*str != '\0' && *str != '\"')
            {
                if (*str == ' ')
                    *str = '\x80';
                ++str;
            }
            if (*str != '\"')
            {
                /* [phf] removed
                asmerr( ERROR_SYNTAX_ERROR, false, buf );
                */
                error_fmt(ERROR_SYNTAX_ONE, buf);
                --str;
            }
            break;
        case '{':
            if ( bDisable )
                break;
            
            debug_fmt("macro tail: '%s'", str);
            
            arg = atoi(str+1);
            for (add = 0; *str != '\0' && *str != '}'; ++str)
                --add;
            if (*str != '}')
            {
                (void) puts("end brace required");
                --str;
                break;
            }
            --add;
            ++str;
            
            
            debug_fmt("add/str: %d '%s'", add, str);
            
            for (strlist = pIncfile->args; arg != 0 && strlist != NULL;)
            {
                --arg;
                strlist = strlist->next;
            }
            
            if (strlist)
            {
                add += strlen(strlist->buf);
                
                debug_fmt("strlist: '%s' %zu", strlist->buf, strlen(strlist->buf));
                
                if (str + add + strlen(str) + 1 > buf + MAXLINE)
                {
                    debug_fmt("str %8ld buf %8ld (add/strlen(str)): %d %ld",
                              (unsigned long)str, (unsigned long)buf, add, (long)strlen(str));
                    panic_fmt("failure1");
                }
                
                memmove(str + add, str, strlen(str)+1);
                str += add;
                if (str - strlen(strlist->buf) < buf)
                    panic_fmt("failure2");
                memmove(str - strlen(strlist->buf), strlist->buf, strlen(strlist->buf));
                str -= strlen(strlist->buf);
                if (str < buf || str >= buf + MAXLINE)
                    panic_fmt("failure 3");
                --str;      /*  for loop increments string    */
            }
            else
            {
                /* [phf] removed
                asmerr( ERROR_NOT_ENOUGH_ARGUMENTS_PASSED_TO_MACRO, false, NULL );
                */
                error_fmt("Not enough arguments passed to macro!");
                goto br2;
            }
            break;
        }
    }
    
br2:
    while(str != buf && *(str-1) == ' ')
        --str;
    *str = 0;
    
    return comment;
}

/*
*  .dir    direct              x
*  .ext    extended              x
*  .r          relative              x
*  .x          index, no offset          x
*  .x8     index, byte offset          x
*  .x16    index, word offset          x
*  .bit    bit set/clr
*  .bbr    bit and branch
*  .imp    implied (inherent)          x
*  .b                      x
*  .w                      x
*  .l                      x
*  .u                      x
*/


void findext(char *str)
{
    Mnext = -1;
    Extstr = NULL;

    if (str[0] == '.') {    /* Allow .OP for OP */
        return;
    }

    while (*str != '\0' && *str != '.')
        ++str;
    if (*str != '\0') {
        *str = '\0';
        ++str;
        Extstr = str;
        switch(tolower(str[0])) {
        case '0':
        case 'i':
            Mnext = AM_IMP;
            switch(tolower(str[1])) {
            case 'x':
                Mnext = AM_0X;
                break;
            case 'y':
                Mnext = AM_0Y;
                break;
            case 'n':
                Mnext = AM_INDWORD;
                break;
            }
            return;
            case 'd':
            case 'b':
            case 'z':
                switch(tolower(str[1])) {
                case 'x':
                    Mnext = AM_BYTEADRX;
                    break;
                case 'y':
                    Mnext = AM_BYTEADRY;
                    break;
                case 'i':
                    Mnext = AM_BITMOD;
                    break;
                case 'b':
                    Mnext = AM_BITBRAMOD;
                    break;
                default:
                    Mnext = AM_BYTEADR;
                    break;
                }
                return;
                case 'e':
                case 'w':
                case 'a':
                    switch(tolower(str[1])) {
                    case 'x':
                        Mnext = AM_WORDADRX;
                        break;
                    case 'y':
                        Mnext = AM_WORDADRY;
                        break;
                    default:
                        Mnext = AM_WORDADR;
                        break;
                    }
                    return;
                    case 'l':
                        Mnext = AM_LONG;
                        return;
                    case 'r':
                        Mnext = AM_REL;
                        return;
                    case 'u':
                        Mnext = AM_BSS;
                        return;
        }
    }
}

/*
*  bytes arg will eventually be used to implement a linked list of free
*  nodes.
*  Assumes *base is really a pointer to a structure with .next as the first
*  member.
*/

void rmnode(void **base,  size_t UNUSED(bytes))
{
    /* [phf] base is a pointer to a pointer to a struct,
       the address of a pointer; node is the pointer
       to the struct itself, and if that pointer is NULL
       we do nothing; if it's not NULL, we overwrite the
       original pointer (the variable whose address we
       were passed) with the content of the first element
       of the struct (the next field?); then we free the
       original struct we were pointing to; tricky! */
    void *node;
    
    if ((node = *base) != NULL) {
        *base = *(void **)node;
        free(node);
    }
}

/*
*  Parse into three arguments: Av[0], Av[1], Av[2]
*/
static MNEMONIC *parse(char *buf)
{
    int i, j;
    MNEMONIC *mne = NULL;
    
    i = 0;
    j = 1;

#if OlafFreeFormat
    /* Skip all initial spaces */
    while (buf[i] == ' ')
        ++i;
#endif

#if OlafHashFormat
        /*
        * If the first non-space is a ^, skip all further spaces too.
        * This means what follows is a label.
        * If the first non-space is a #, what follows is a directive/opcode.
    */
    while (buf[i] == ' ')
        ++i;
    if (buf[i] == '^') {
        ++i;
        while (buf[i] == ' ')
            ++i;
    } else if (buf[i] == '#') {
        buf[i] = ' ';   /* label separator */
    } else
        i = 0;
#endif

    Av[0] = Avbuf + j;
    while (buf[i] != '\0' && buf[i] != ' ') {

        if (buf[i] == ':') {
            i++;
            break;
        }

        if ((unsigned char)buf[i] == 0x80)
            buf[i] = ' ';
        Avbuf[j++] = buf[i++];
    }
    Avbuf[j++] = 0;

#if OlafFreeFormat
    /* Try if the first word is an opcode */
    findext(Av[0]);
    mne = findmne(Av[0]);
    if (mne != NULL) {
    /* Yes, it is. So there is no label, and the rest
    * of the line is the argument
        */
        Avbuf[0] = 0;    /* Make an empty string */
        Av[1] = Av[0];    /* The opcode is the previous first word */
        Av[0] = Avbuf;    /* Point the label to the empty string */
    } else
#endif

    {    /* Parse the second word of the line */
        while (buf[i] == ' ')
            ++i;
        Av[1] = Avbuf + j;
        while (buf[i] && buf[i] != ' ') {
            if ((unsigned char)buf[i] == 0x80)
                buf[i] = ' ';
            Avbuf[j++] = buf[i++];
        }
        Avbuf[j++] = 0;
        /* and analyse it as an opcode */
        findext(Av[1]);
        mne = findmne(Av[1]);
    }
    /* Parse the rest of the line */
    while (buf[i] == ' ')
        ++i;
    Av[2] = Avbuf + j;
    while (buf[i] != '\0') {
        if (buf[i] == ' ') {
            while(buf[i+1] == ' ')
                ++i;
        }
        if ((unsigned char)buf[i] == 0x80)
            buf[i] = ' ';
        Avbuf[j++] = buf[i++];
    }
    Avbuf[j] = 0;
    
    return mne;
}

static MNEMONIC *findmne(const char *str)
{
    MNEMONIC *mne;
    char buf[MAX_SYM_LEN]; /* TODO: fixed size? was 64 before! argh! [phf] */
    size_t res;
    
    assert(str != NULL);

    if (strlen(str) == 0) {
        return NULL; /* avoid doing the rest for an empty string */
    }

    if (str[0] == '.') {    /* Allow .OP for OP */
        str++;
    }

    res = strlower(buf, str, sizeof(buf));
    assert(res < sizeof(buf));

    for (mne = MHash[hash_mnemonic(buf)]; mne != NULL; mne = mne->next) {
        if (strcmp(buf, mne->name) == 0) {
            break;
        }
    }
    return mne;
}

void v_macro(const char *str, MNEMONIC UNUSED(*dummy))
{
    STRLIST *base;
    bool defined = false;
    STRLIST **slp = NULL, *sl;
    MACRO *mac = NULL;    /* slp, mac: might be used uninitialised */
    MNEMONIC   *mne;
    unsigned int i;
    char buf[MAXLINE];
    int skipit = !(Ifstack->xtrue && Ifstack->acctrue);
    char sbuf[MAX_SYM_LEN]; /* TODO: fixed size? [phf] */
    size_t res;

    assert(str != NULL);

    res = strlower(sbuf, str, sizeof(sbuf));
    assert(res < sizeof(sbuf));

    if (skipit) {
        defined = true;
    } else {
        defined = (findmne(sbuf) != NULL);
        if (FI_listfile != NULL && ListMode) {
            outlistfile("");
        }
    }
    if (!defined) {
        base = NULL;
        slp = &base;
        mac = small_alloc(sizeof(MACRO));
        i = hash_mnemonic(sbuf);
        mac->next = (MACRO *)MHash[i];
        mac->vect = v_execmac;
        mac->name = strcpy(small_alloc(strlen(sbuf)+1), sbuf);
        mac->flags = MF_MACRO;
        MHash[i] = (MNEMONIC *)mac;
    }
    while (fgets(buf, MAXLINE, pIncfile->fi)) {
        const char *comment;
        
        debug_fmt("%08lx %s", (unsigned long) pIncfile, buf);
        
        ++pIncfile->lineno;
        
        
        comment = cleanup(buf, true);
        
        mne = parse(buf);
        if (Av[1][0]) {
            if (mne != NULL && (mne->flags & MF_ENDM) != 0) {
                if (!defined) {
                    mac->strlist = base;
                }
                return;
            }
        }
        if (!skipit && FI_listfile != NULL && ListMode) {
            outlistfile(comment);
        }
        if (!defined) {
            sl = small_alloc(STRLISTSIZE+1+strlen(buf));
            strcpy(sl->buf, buf);
            *slp = sl;
            slp = &sl->next;
        }
    }
    panic_fmt("Premature end of file!");
}


void addhashtable(MNEMONIC *mne)
{
    int i, j;
    unsigned int opcode[NUMOC];
    
    for (; mne->vect != NULL; ++mne) {
        memcpy(opcode, mne->opcode, sizeof(mne->opcode));
        for (i = j = 0; i < NUMOC; ++i) {
            mne->opcode[i] = 0;     /* not really needed */
            if (mne->okmask & (1L << i))
                mne->opcode[i] = opcode[j++];
        }
        if (findmne(mne->name) != NULL) {
            notice_fmt("Mnemonic '%s' was overridden!", mne->name);
        }
        i = hash_mnemonic(mne->name);
        mne->next = MHash[i];
        MHash[i] = mne;
    }
}

static unsigned int hash_mnemonic(const char *str)
{
    return hash_string(str, strlen(str)) & MHASHAND;
}

void pushinclude(const char *str)
{
    INCFILE *inf;
    FILE *fi;
    
    if ((fi = pfopen(str, "r")) != NULL) {
        if (F_verbose > 1 && F_verbose != 5) {
            printf("%.*s Including file \"%s\"\n", Inclevel*4, "", str);
        }
        ++Inclevel;
        
        if (FI_listfile != NULL) {
            fprintf(FI_listfile, "------- FILE %s LEVEL %d PASS %d\n", str, Inclevel, pass);
        }
        
        inf = zero_malloc(sizeof(INCFILE));
        inf->next = pIncfile;
        inf->name = checked_strdup(str);
        inf->fi = fi;
        inf->lineno = 0;
        pIncfile = inf;
    }
    else {
        warning_fmt("Unable to open include file '%s'.", str);
    }
}

/**
 * @brief Function that runs right before DASM exits.
 */
static void exit_handler(void)
{
    debug_fmt(DEBUG_ENTER, SOURCE_LOCATION);

    /* free all small allocations we ever made */
    small_free_all();

    /*
        Valgrind found a memory leak, apparently we never free
        the first IFSTACK we allocate; possible that the leak
        has been around for 20 years. I'd like to move this
        earlier, maybe into MainShadow() where the IFSTACK is
        zero_malloc()ed, but that lead to segmentation faults.
        Here it makes valgrind happy and doesn't seem to lead
        to other problems. A *real* fix will probably have to
        wait until most of dasm is cleaned up. [phf, 2008/11/01]

        Note that an IFSTACK is only allocated when we actually
        read some source, so I had to switch from an assert to
        a conditional here. [phf, 2008/11/02]
    */
    if (Ifstack != NULL) { /* one left to free */
        rmnode((void **)&Ifstack, sizeof(IFSTACK)); /* free it */
        assert(Ifstack == NULL); /* and we're NULL */
    }
    
    /* TODO: more cleanup actions here? */

    debug_fmt(DEBUG_LEAVE, SOURCE_LOCATION);
}

int main(int argc, char **argv)
{
    setprogname(argv[0]);

    if (atexit(exit_handler) != 0)
    {
        panic_fmt("Could not install exit handler!");
    }

    MainShadow(argc, argv);

#if 0
    if (nError)
    {
        printf("Fatal assembly error: %s\n", sErrorDef[nError].sDescription);
    }
#endif
    
    DumpSymbolTable();

    if (number_of_errors() > 0) {
      return EXIT_FAILURE;
    }
    else {
      return EXIT_SUCCESS;
    }
}

/* vim: set tabstop=4 softtabstop=4 expandtab shiftwidth=4 autoindent: */
