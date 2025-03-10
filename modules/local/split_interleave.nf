// Process to SIZ read pairs using 'bin/split_interleave_fastq'
process SPLIT_INTERLEAVE {
    tag "${meta.id}"

  input:
    // Each tuple contains a metadata map and the two FASTQ files (r1 and r2)
    tuple val(meta), path(r1), path(r2)
    path splitInterleave
    
  output:
    // The process outputs a tuple with the meta and all files matching "*.fastq.zst"
    tuple val(meta), path("*.fastq.zst")
    path "cleanup.success", optional: true
    
  script:
    """
    # Run the compiled binary.
    # It is expected to be available in the work directory
    ./${splitInterleave} ${meta.id} ${meta.read_pairs_per_siz} ${r1} ${r2}

    # Check if output files were created and then remove input files
    if [ \$(ls -1 *.fastq.zst 2>/dev/null | wc -l) -gt 0 ]; then
        rm -f "${r1}" "${r2}"
        
        # Create a success flag file only if files were removed successfully
        if [ ! -f "${r1}" ] && [ ! -f "${r2}" ]; then
            touch cleanup.success
        fi
    fi
    """
}
