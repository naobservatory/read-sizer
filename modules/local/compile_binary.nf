process COMPILE_BINARY {
    input:
        path src
    
    output:
        path "bin/split_interleave_fastq", emit: binary
    
    script:
    """
    # Create fresh directories
    mkdir -p bin
    
    # Direct compilation
    gcc -Wall -Wextra -O2 -o bin/split_interleave_fastq -lzstd ${src}
    chmod +x bin/split_interleave_fastq
    """
}