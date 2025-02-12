#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import the SPLIT_INTERLEAVE process from the module file
include { SPLIT_INTERLEAVE } from './modules/split_interleave.nf'

params.manifest = params.manifest ?: null

workflow {

    /*
     * This workflow supports two modes:
     * 1. If a manifest CSV is provided via --manifest, it is assumed to have columns: id, read1, read2.
     * 2. If no manifest is provided, a demo channel with two example samples is used.
     */

    def sampleChannel

    if ( params.manifest ) {
        sampleChannel = Channel.fromPath(params.manifest)
                        .splitCsv(header:true)
                        .map { row ->
                            tuple( [ id: row.id ], [ file(row.read1), file(row.read2) ] )
                        }
    }
    else {
        log.warn "No manifest provided; using demo samples."
        sampleChannel = Channel.of(
            tuple( [ id: "test" ], [ file("test/test_1.fastq.gz"), file("test/test_2.fastq.gz") ].collect { file(it) } )
        )
    }

    def results = sampleChannel | SPLIT_INTERLEAVE

    results.view { meta, outFiles ->
        "Sample ${meta.id} produced: ${outFiles.join(', ')}"
    }
}