#include "patcher.h"
#include "files_usage.h"

void patch()
{
    FILE* fp = fopen("../Andrew_crackme/CRACKME.COM", "r");
    if (fp == NULL) { fprintf(stderr, "Could not open file to patch\n"); return; }

    size_t file_size = get_file_size(fp);
    char* file_data  = read_file(fp);

    size_t fill_pos = 10 * 16 + 14;         // pos of jne for passing authorization
    //size_t fill_len = 2                   // jne length
    char fill_value = 9 * 16;               // nop code

    if (file_data[fill_pos] != fill_value || file_data[fill_pos + 1] != fill_value)
    {
        file_data[fill_pos]     = fill_value;
        file_data[fill_pos + 1] = fill_value;

        FILE* fp_out = get_stream_for_save();
        fwrite(file_data, sizeof(char), file_size, fp_out);
        printf("Patch completed! File saved to [cracked] folder\n");
    }
    else { printf("Already patched\n"); }

    if (!fclose(fp)) { fprintf(stderr, "Could not close file after patch\n"); }
    free(file_data);
}
