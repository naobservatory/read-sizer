// Process to SIZ read pairs using 'bin/split_interleave_fastq'
process SPLIT_INTERLEAVE {
    publishDir "s3://${params.bucket}/${params.delivery}/siz/", mode: 'copy'
    container 'community.wave.seqera.io/library/gzip_zstd:9f7a7e4daeb80cea'
    tag "${meta.sample}"

  input:
    // Each tuple contains a metadata map and the two FASTQ files (r1 and r2)
    tuple val(meta), path(r1), path(r2)
    path splitInterleave
    
  output:
    // The process outputs a tuple with the meta and all files matching "*.fastq.zst"
    tuple val(meta), path("*.fastq.zst")
    
  script:
    """
    # Run the compiled binary.
    # It is expected to be available in the PATH (or in the container)
    chmod +x ${splitInterleave}
    ${splitInterleave} ${meta.prefix} ${meta.reads_per_file} ${r1} ${r2}
    """
}
