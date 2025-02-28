process COMPILE_BINARY {
    input:
        path src
        path makefile
    
    output:
        path "bin/split_interleave_fastq", emit: binary
    
    script:
    """
    # Create the output directory if it doesn't exist
    mkdir -p lib

    # Copy the input files to expected names.
    # This assumes the Makefile expects a source file named split_interleave_fastq.c.
    cp "${src}" lib/split_interleave_fastq.c
    cp "${makefile}" lib/Makefile

    # Run make using the provided Makefile.
    make -C lib
    chmod +x bin/split_interleave_fastq
    """
}