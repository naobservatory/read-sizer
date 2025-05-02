// Process to SIZer a pair of fastq files
process SIZER {
    tag "${id}"

  input:
    // We pass inputs as S3 path strings since the pipeline will stream
    tuple val(id), val(r1), val(r2), val(outdir), val(sizer_params)
    
  // no Nextflow output: the pipeline stream uploads

  script:
    """
    sizer.sh -s /usr/local/bin/split_interleave_fastqs \
        -u /sequence_tools/compress_upload.sh \
        -c ${sizer_params.chunk_size} \
        -l ${sizer_params.zstd_level} \
        <(aws s3 cp ${r1} - | gunzip) \
        <(aws s3 cp ${r2} - | gunzip) \
        ${id} \
        ${outdir}${id}
    """
}
