# Documentation for Makefile:
#
# Purpose:
#   This Makefile is used to compile the C program "split_interleave_fastq.c"
#   into an executable named "split_interleave_fastq", which is placed in the
#   directory "../bin".
#
# Usage:
#   - To compile the program, run: make
#   - To remove build outputs, run: make clean

CC = gcc
CFLAGS = -Wall -Wextra -O2

# Set target path for compiled executable
TARGET_DIR = ../bin
TARGET = $(TARGET_DIR)/split_interleave_fastq
SRC = split_interleave_fastq.c

.PHONY: all clean

all: $(TARGET)

$(TARGET_DIR):
	mkdir -p $(TARGET_DIR)

$(TARGET): $(SRC) | $(TARGET_DIR)
	$(CC) $(CFLAGS) -o $@ $<
	chmod +x $@

clean:
	rm -rf $(TARGET_DIR)
