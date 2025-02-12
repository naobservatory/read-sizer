process SPLIT_INTERLEAVE {
    tag "$meta.id"

    input:
    tuple val(meta), val(reads)

    output:
    tuple val(meta), path("output/*.fastq.zst"), emit: siz_chunks

    script:
    def prefix = "${meta.id}"
    def reads_per_file = 1000000
    def reads1 = reads[0]
    def reads2 = reads[1]
    def working_dir = "."
    def output_dir = "output/"

    """
    mkdir -p ${output_dir}
    /home/teojcryan/projects/nf-sizer/bin/split_interleave_fastq \\
        ${prefix} \\
        ${reads_per_file} \\
        <(gunzip --to-stdout ${reads1}) \\
        <(gunzip --to-stdout ${reads2}) \\
        . \\
        ${output_dir}
    """    
}