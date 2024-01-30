#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stddef.h>
#include <ctype.h>
#include <stdarg.h>
#include <limits.h>

int main(int argc,char **argv) {
	int i,notoption;
	for(i=1;i<argc;i++) {
		if(*argv[i]=='-') {

		} else {
		        printf("TEST: %d, '%s'\n", notoption, argv[i]);
			notoption++;
		}
	}
}
