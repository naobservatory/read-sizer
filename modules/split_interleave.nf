process SPLIT_INTERLEAVE {
    tag "${sample}"

    input:
    tuple val(sample), val(delivery), val(bucket)

    output:
    tuple val(sample), file("completion-tracking/${sample}.complete") 

    script:
    def reads_per_file = params.reads_per_file
    def siz_dir = "${bucket}/${params.delivery}/siz/"

    """
    #!/usr/bin/env bash
    set -eu

    mkdir -p completion-tracking
    FINISHED_FILE="completion-tracking/${sample}.complete"

    if [[ -e \$FINISHED_FILE ]]; then
      exit 0
    fi

    TMPDIR=\$(mktemp -d)

    ${baseDir}/bin/split_interleave_fastq \\
        ${sample} \\
        ${reads_per_file} \\
        <(gunzip --to-stdout ${bucket}/${delivery}/raw/${sample}_1.fastq.gz) \\
        <(gunzip --to-stdout ${bucket}/${delivery}/raw/${sample}_2.fastq.gz) \\
        \$TMPDIR \\
        ${siz_dir}

    rmdir \$TMPDIR
    touch \$FINISHED_FILE
    """    
}