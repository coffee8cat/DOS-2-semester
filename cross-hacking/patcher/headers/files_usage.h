#ifndef _FILES_USAGE_H__
#define _FILES_USAGE_H__

#include <stdlib.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <assert.h>
#include <stdio.h>

char* read_file_data();
char* read_file(FILE*);
size_t get_file_size(FILE* fp);

FILE* get_stream_for_save();

#endif
