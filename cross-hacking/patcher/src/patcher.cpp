#include "patcher.h"
#include "files_usage.h"

void patch()
{
    FILE* fp = fopen("..\\Andrew_crackme\\CRACKME.COM", "r");
    if (fp == NULL) { fprintf(stderr, "Could not open file to patch\n"); return; }

    size_t file_size = get_file_size(fp);
    char* file_data = read_file(fp);

    file_data[16*10 + 14] = char(9*16);
    file_data[16*10 + 15] = char(9*16);


    if (!fclose(fp)) { fprintf(stderr, "Could not close file after patch\n"); }

    FILE* fp_out = get_stream_for_save();
    fwrite(file_data, sizeof(char), file_size, fp_out);

    free(file_data);
}
