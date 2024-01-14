/*==========================================================================
 * Project: atari cross assembler
 * File: atasm_err.c
 *
 * Contains error handler
 *==========================================================================
 * Created: 07/27/03 mws
 * Modifications:
 *
 *==========================================================================
 * TODO: Add vprintf-like error function for convenience...
 *==========================================================================
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *==========================================================================*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "atasm_err.h"
#include "symbol.h"

#define ISIZE 128
ihashNode* ihash[ISIZE];

/*=========================================================================*
 * Function: errAdd, add an item to the warning table
 * Parameters: id, the key; d, the data item to add
 * Returns: bool indicating success
 *=========================================================================*/
void errAdd(unsigned int id, unsigned int num) {
	ihashNode* in;
	unsigned int key = id;
	key += ~(key << 15);
	key ^= (key >> 10);
	key += (key << 3);
	key ^= (key >> 6);
	key += ~(key << 11);
	key ^= (key >> 16);
	key = key % ISIZE;

	in = (ihashNode*)malloc(sizeof(ihashNode));
	if (!in) {
		error("Out of memory creating warning table", 1);
	}
	in->id = id;
	in->data = num;
	in->nxt = NULL;
	if (ihash[key]) {
		ihashNode* walk = ihash[key];
		while (walk->nxt) {
			walk = walk->nxt;
		}
		walk->nxt = in;
	}
	else {
		ihash[key] = in;
	}
}

/*=========================================================================*
 * Function: Get, retrieve an object from the table by UID
 * Parameters: id, the object id to return
 * Returns: the object, or NULL if not found
 *=========================================================================*/
int errCheck(unsigned int id, unsigned int num) {
	ihashNode* look;

	unsigned int key = id;
	key += ~(key << 15);
	key ^= (key >> 10);
	key += (key << 3);
	key ^= (key >> 6);
	key += ~(key << 11);
	key ^= (key >> 16);
	key = key % ISIZE;

	if (!ihash[key])
		return 0;
	look = ihash[key];
	while (look) {
		if ((look->id == id) && (look->data == num))
			return 1;
		look = look->nxt;
	}
	return 0;
}
/*=========================================================================*
 * function error(char *err, int tp)
 * parameters: err - the error message
 *             errLevel  - the error severity (0=warning, else fatal error)
 *
 * generates an error/warning message to stderr, including the position
 * of the error
 *=========================================================================*/
int error(char* err, int errLevel)
{
	char* filename = "UNKNOWN";
	int lineNumber = 0;
	char macroMsg[1024];
	macroMsg[0] = 0;

	if (opt.warn == 0 && errLevel == 0) {
		// Suppress warnings, if option no warn set
		warn++;
		return 1;
	}
	if (fin)
	{
		char buf[256];
		unsigned int crc;

		snprintf(buf, 256, "%s%d%s", fin->name, fin->line, err);
		crc = err_crc32((unsigned char*)buf, (int)strlen(buf));
		if (errCheck(crc, fin->line))
			return 1;
		else
			errAdd(crc, fin->line);

		filename = fin->name;
		lineNumber = fin->line;

		if (invoked)
			sprintf(macroMsg, "--[while expanding macro '%s']", invoked->orig->name);

		//fprintf(stderr, "\nIn %s\n ", fin->name);
		/*if (!invoked)
			fprintf(stderr, "\nIn %s, line %d--\n ", fin->name, fin->line);
		else
			fprintf(stderr, "\nIn %s, line %d--[while expanding macro '%s']\n ", fin->name, fin->line, invoked->orig->name);
		*/
	}
	fprintf(stderr, "\n %s: %s:%d: %s%s\n",
		errLevel ? "Error" : "Warning",
		filename, lineNumber,
		err,
		macroMsg
	);
	if (errLevel)
	{
		// Exit on error
		if (listFile)
			fclose(listFile);
		exit(errLevel);
	}
	warn++;
	return 0;
}
/*=========================================================================*/
