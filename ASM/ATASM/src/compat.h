#ifndef COMPAT_H
#define COMPAT_H

#ifdef MSVC
//#define snprintf(buf,sz,format,x) _snprintf(buf,sz,format,x)
#define STRCASECMP(a,b) _stricmp((a),(b))
#define STRNCASECMP(a,b,c) _strnicmp((a),(b),(c))
#define STRDUP(a) _strdup(a)
#else
#define STRCASECMP(a,b) strcasecmp((a),(b))
#define STRNCASECMP(a,b,c) strncasecmp((a),(b),(c))
#define STRDUP(a) strdup(a)
#endif

#define ISSPACE(a) isspace((unsigned char)(a))
#define ISDIGIT(a) isdigit((unsigned char)(a))
#define ISXDIGIT(a) isxdigit((unsigned char)(a))
#define ISALPHA(a) isalpha((unsigned char)(a))
#define ISALNUM(a) isalnum((unsigned char)(a))
#define TOUPPER(a) toupper((unsigned char)(a))

#endif
