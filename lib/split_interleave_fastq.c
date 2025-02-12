#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_READ_LEN 1024

// credits: @evanfields
// to-do: modify so it works with streaming input?

void compress_file(char* fname) {
    // Compress with original name
    int max_cmd_len = strlen(fname) + 64;
    char cmd[max_cmd_len];
    snprintf(cmd, max_cmd_len, "zstd -9 -T6 --rm %s", fname);

    int return_code = system(cmd);
    if (return_code != 0) {
        printf("zstd compression of %s failed\n", fname);
        exit(1);
    }
}

// Helper function to read one FASTQ record
int read_fastq_record(FILE* f, char** title, char** seq, char** plus, char** quality,
                     size_t* title_size, size_t* seq_size, size_t* plus_size, size_t* quality_size,
                     long read_num) {
    ssize_t title_len = getline(title, title_size, f);
    ssize_t seq_len = getline(seq, seq_size, f);
    ssize_t plus_len = getline(plus, plus_size, f);
    ssize_t quality_len = getline(quality, quality_size, f);

    if (title_len == -1 || seq_len == -1 || plus_len == -1 || quality_len == -1) {
        return 0;
    }

    // Validate FASTQ format
    if ((*title)[0] != '@' || (*plus)[0] != '+' || seq_len != quality_len ||
        title_len > MAX_READ_LEN || seq_len > MAX_READ_LEN ||
        plus_len > MAX_READ_LEN || quality_len > MAX_READ_LEN) {
        printf("Corrupt fastq on record %ld\n", read_num);
        printf("Lengths: title=%zd seq=%zd plus=%zd qual=%zd\n",
               title_len, seq_len, plus_len, quality_len);
        printf("Record contents:\n");
        printf("%s", *title);
        printf("%s", *seq);
        printf("%s", *plus);
        printf("%s", *quality);
        exit(1);
    }

    return 1;
}

void copy_to_s3(char* compressed_fname, char* s3_fname) {
  int max_copy_cmd_len = 2048;
  char copy_cmd[max_copy_cmd_len];
  snprintf(copy_cmd, max_copy_cmd_len,
           "cp %s %s", compressed_fname, s3_fname);
  if (system(copy_cmd) != 0) {
    printf("Failed to copy %s to %s\n", compressed_fname, s3_fname);
    exit(1);
  }
}

void finish_file(char* fname, char* compressed_fname, char* s3_fname) {
  compress_file(fname);
  copy_to_s3(compressed_fname, s3_fname);
  unlink(compressed_fname);
}

int main(int argc, char** argv) {
    if (argc != 7) {
        printf("Usage: %s <prefix> <reads_per_file> <r1_fastq> <r2_fastq> "
               "<working_dir> <s3_output_dir>\n", argv[0]);
        printf("  Outputs are automatically zstd compressed\n");
        exit(1);
    }
    char* prefix = argv[1];
    long max_reads = strtol(argv[2], NULL, 10);
    char* r1_path = argv[3];
    char* r2_path = argv[4];
    char* working_dir = argv[5];
    char* s3_output_dir = argv[6];

    if (chdir(working_dir) != 0) {
      printf("Error: Unable to change to directory %s\n", argv[5]);
      exit(1);
    }

    if (max_reads <= 0) {
        printf("Error: reads_per_file must be a positive number\n");
        exit(1);
    }

    if (strlen(s3_output_dir) < 10 ||
        s3_output_dir[0] != 's' ||
        s3_output_dir[1] != '3' ||
        s3_output_dir[2] != ':' ||
        s3_output_dir[3] != '/' ||
        s3_output_dir[4] != '/' ||
        s3_output_dir[strlen(s3_output_dir) - 1] == '/') {

        printf("Error: s3_output_dir should be in the form s3://path/to/dir\n");
    }

    // Open input files
    FILE* f1 = fopen(r1_path, "r");
    FILE* f2 = fopen(r2_path, "r");
    if (!f1 || !f2) {
        printf("Error opening input files\n");
        exit(1);
    }

    int division = 0;
    int produced_files = 0;
    long reads = 0;  // reads per current file
    long all_reads = 0;  // total read pairs processed
    FILE* out = NULL;

    int max_fname_len = strlen(prefix) + 36;
    char fname[max_fname_len];
    int max_s3_fname_len = max_fname_len + strlen(s3_output_dir);
    char s3_fname[max_s3_fname_len];

    // Compressed output file ends in .zst
    char compressed_fname[max_fname_len + 5];  // +5 for .zst and null terminator


    // Initialize all line buffers and their sizes for both R1 and R2
    char *title1 = NULL, *title2 = NULL;
    char *seq1 = NULL, *seq2 = NULL;
    char *plus1 = NULL, *plus2 = NULL;
    char *quality1 = NULL, *quality2 = NULL;

    size_t title1_size = 0, title2_size = 0;
    size_t seq1_size = 0, seq2_size = 0;
    size_t plus1_size = 0, plus2_size = 0;
    size_t quality1_size = 0, quality2_size = 0;

    while (1) {
        // Read one record from each file
        int r1_success = read_fastq_record(f1, &title1, &seq1, &plus1, &quality1,
                                         &title1_size, &seq1_size, &plus1_size, &quality1_size,
                                         all_reads);
        int r2_success = read_fastq_record(f2, &title2, &seq2, &plus2, &quality2,
                                         &title2_size, &seq2_size, &plus2_size, &quality2_size,
                                         all_reads);

        // Check for end of files or mismatched pairs
        if (!r1_success && !r2_success) {
            break;  // Normal end of both files
        }
        if (r1_success != r2_success) {
            printf("Error: Unequal number of reads in R1 and R2 files\n");
            exit(1);
        }

        if (!out) {
            snprintf(fname, max_fname_len, "%s_div%06d.fastq", prefix, division);
            out = fopen(fname, "w");
            if (!out) {
                printf("Error creating output file %s\n", fname);
                exit(1);
            }
            sprintf(compressed_fname, "%s.zst", fname);
            snprintf(s3_fname, max_s3_fname_len, "%s/%s_div%06d.fastq.zst",
                     s3_output_dir, prefix, division);
        }

        // Write interleaved records
        fprintf(out, "%s%s%s%s", title1, seq1, plus1, quality1);
        fprintf(out, "%s%s%s%s", title2, seq2, plus2, quality2);

        all_reads++;
        reads++;

        if (reads >= max_reads) {
            fclose(out);
            out = NULL;
            reads = 0;
            division++;
            finish_file(fname, compressed_fname, s3_fname);
            produced_files++;
        }
    }

    // Clean up final file
    if (out) {
        fclose(out);
        finish_file(fname, compressed_fname, s3_fname);
        produced_files++;
    }

    // Close input files
    fclose(f1);
    fclose(f2);

    // Free all buffers
    free(title1); free(title2);
    free(seq1); free(seq2);
    free(plus1); free(plus2);
    free(quality1); free(quality2);

    printf("Processed %ld read pairs into %d files\n", all_reads, produced_files);
    return 0;
}