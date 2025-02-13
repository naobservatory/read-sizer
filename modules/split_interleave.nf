process SPLIT_INTERLEAVE {
    tag "${sample}"
    
     publishDir "${baseDir}/${bucket}/${delivery}", mode: 'move', pattern: "siz/*_div*.fastq.zst"
    
    input:
    tuple val(sample), val(delivery), val(bucket)

    output:
    tuple val(sample),
            file("completion-tracking/${sample}.complete"),
            file("siz/*_div*.fastq.zst")

    script:
    def reads_per_file = params.reads_per_file

    """
    #!/usr/bin/env bash
    set -eu

    mkdir -p completion-tracking siz
    FINISHED_FILE="completion-tracking/${sample}.complete"

    if [[ -e \$FINISHED_FILE ]]; then
      exit 0
    fi

    ${baseDir}/bin/split_interleave_fastq \\
        ${sample} \\
        ${reads_per_file} \\
        <(gunzip --to-stdout ${baseDir}/${bucket}/${delivery}/raw/${sample}_1.fastq.gz) \\
        <(gunzip --to-stdout ${baseDir}/${bucket}/${delivery}/raw/${sample}_2.fastq.gz) \\
        . \\
        siz

    touch \$FINISHED_FILE
    """    
}