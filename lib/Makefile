CC = gcc
CFLAGS = -Wall -Wextra -O2
TARGET_DIR = ../bin
TARGET = $(TARGET_DIR)/split_interleave_fastq
SRC = split_interleave_fastq.c

.PHONY: all clean

all: $(TARGET)

$(TARGET_DIR):
	mkdir -p $(TARGET_DIR)

$(TARGET): $(SRC) | $(TARGET_DIR)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(TARGET_DIR)
