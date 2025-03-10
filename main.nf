#!/usr/bin/env nextflow

// Import the SPLIT_INTERLEAVE process module
include { SPLIT_INTERLEAVE } from './modules/local/split_interleave.nf'
include { GENERATE_SAMPLESHEET } from './modules/local/gen_samplesheet.nf'
include { COMPILE_BINARY } from './modules/local/compile_binary.nf'

workflow {
  // Compile the binary first
  COMPILE_BINARY(
    file("${workflow.projectDir}/lib/split_interleave_fastq.c"),
    file("${workflow.projectDir}/lib/Makefile")
  )

  // Get compiled binary path
  splitInterleave = COMPILE_BINARY.out.binary

  // Determine the sample sheet channel
  def sampleSheetChannel

  //  If --sample_sheet is provided, use it.
  if ( params.sample_sheet ) {
      println "Using provided sample sheet: ${params.sample_sheet}"
      sampleSheetChannel = Channel.fromPath(params.sample_sheet)
  } 
  // Otherwise, generate it from bucket and delivery parameters.
  else if ( params.bucket && params.delivery ) {
      println "No sample sheet provided; generating sample sheet from bucket ${params.bucket} and delivery ${params.delivery}"
      def script = file("scripts/generate_samplesheet.py")
      sampleSheetChannel = GENERATE_SAMPLESHEET(
        params.bucket, 
        params.delivery,
        params.outdir ? params.outdir : '', 
        script
      )
  } else {
      error "You must provide either --sample_sheet or both --bucket and --delivery"
  }

  // Create a channel from the sample sheet CSV.
  ids_ch = sampleSheetChannel
      .splitCsv(header:true)
      .map { row ->
          def sizOutdir
          
          // Check if outdir column exists and has a value
          if (row.containsKey('outdir') && row.outdir) {
              sizOutdir = row.outdir
          } else {
              // Infer output directory by replacing "raw" with "siz"
              def fastqPath = row.fastq_1
              sizOutdir = fastqPath.replaceAll('/raw/', '/siz/').replaceAll('/[^/]+$', '/')
          }
      
          def meta = [
            id: row.id,
            read_pairs_per_siz: params.read_pairs_per_siz,
            outdir: sizOutdir
          ]
          
          tuple(meta, file(row.fastq_1), file(row.fastq_2))
      }
  
  results = SPLIT_INTERLEAVE(ids_ch, splitInterleave)
}
