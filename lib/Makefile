# Makefile

# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -Wextra -O2

# Source files
SRC = split_interleave_fastq.c

# Output directory and executable name
BIN_DIR = ../bin
OUTPUT = $(BIN_DIR)/split_interleave_fastq

# Build target
all: $(OUTPUT)

# Linking
$(OUTPUT): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

# Clean target
clean:
	rm -f $(OUTPUT)

.PHONY: all clean
