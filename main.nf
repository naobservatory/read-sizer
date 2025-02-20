#!/usr/bin/env nextflow

// Import the SPLIT_INTERLEAVE process module
include { SPLIT_INTERLEAVE } from './modules/local/split_interleave.nf'
include { GENERATE_SAMPLESHEET } from './modules/local/gen_samplesheet.nf'

workflow {
  // Determine the sample sheet channel
  def sampleSheetChannel
  // If --sample_sheet is provided, use it.
  if ( params.sample_sheet ) {
      println "Using provided sample sheet: ${params.sample_sheet}"
      sampleSheetChannel = Channel.fromPath(params.sample_sheet)
  // Otherwise, generate it from bucket and delivery parameters.
  } else if ( params.bucket && params.delivery ) {
      println "No sample sheet provided; generating sample sheet from bucket ${params.bucket} and delivery ${params.delivery}"
      def script = file("scripts/generate_samplesheet.py")
      sampleSheetChannel = GENERATE_SAMPLESHEET(params.bucket, params.delivery, script)
  } else {
      error "You must provide either --sample_sheet or both --bucket and --delivery"
  }

  // Create a channel from the sample sheet CSV.
  // The CSV is expected to have header columns: id, fastq_1, fastq_2.
  ids_ch = sampleSheetChannel
      .splitCsv(header:true)
      .map { row ->
          def meta = [
            id                 : row.id,
            read_pairs_per_siz : params.read_pairs_per_siz,
            bucket             : row.bucket, 
            delivery           : row.delivery
          ]
          // Stage the FASTQ files (can be S3 URIs). Nextflow will handle file staging.
          tuple(meta, file(row.fastq_1), file(row.fastq_2))
        }
  
  def splitInterleave = file("bin/split_interleave_fastq")
  results = SPLIT_INTERLEAVE(ids_ch, splitInterleave)
}
