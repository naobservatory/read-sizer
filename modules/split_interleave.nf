process SPLIT_INTERLEAVE {
    tag "$meta.id"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${params.output_dir}/*.fastq.zst"), emit: siz_chunks

    script:
    def prefix = "${meta.id}"
    def reads_per_file = params.reads_per_file
    def reads1 = reads[0]
    def reads2 = reads[1]
    def output_dir = params.output_dir

    """
    mkdir -p ${output_dir}
    "${baseDir}/bin/split_interleave_fastq" \\
        ${prefix} \\
        ${reads_per_file} \\
        <(gunzip --to-stdout ${reads1}) \\
        <(gunzip --to-stdout ${reads2}) \\
        . \\
        ${output_dir}
    """    
}