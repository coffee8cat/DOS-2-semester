#include "files_usage.h"

char* read_file_data()
{
    char file_name[BUFSIZ]  = {};
    char input_name[BUFSIZ] = {};

    printf("Enter file name for reading: ");
    scanf("%s[^\n]\n", input_name);
    sprintf(file_name, "..\\data\\%s", input_name);

    FILE* input_file = fopen(file_name, "r");
    if (input_file == NULL)
    {
        fprintf(stderr, "ERROR: Could not open file [%s] for reading\n", file_name);
        assert(input_file);
    }
    char* buff = read_file(input_file);

    printf("file [%s] read succesfully\n", file_name);
    fclose(input_file);

    return buff;
}

char* read_file(FILE* input)
{
    assert(input);

    size_t file_size = get_file_size(input);
    char* buff = (char*)calloc(file_size, sizeof(char));
    if (buff == NULL) { fprintf(stderr, "ERROR: Calloc failed in %s:%d in %s\n", __FILE__, __LINE__, __func__); }

    fread(buff, sizeof(char), file_size, input);
    return buff;
}

size_t get_file_size(FILE* fp)
{
    assert(fp);

    struct stat st = {};
    fstat(fileno(fp), &st);
    return (size_t)st.st_size;
}

FILE* get_stream_for_save()
{
    char file_name[BUFSIZ]  = {};
    char output_name[BUFSIZ] = {};

    printf("Enter file name for saving: ");
    scanf("%s[^\n]\n", output_name);
    sprintf(file_name, "..\\data\\%s", output_name);

    FILE* output_file = fopen(file_name, "w");
    if (output_file == NULL)
    {
        fprintf(stderr, "ERROR: Could not open file [%s] for reading\n", file_name);
        assert(output_file);
    }

    return output_file;
}
