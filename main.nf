#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// Import the SPLIT_INTERLEAVE process module
include { SPLIT_INTERLEAVE } from './modules/local/split_interleave.nf'

// Process to generate the sample sheet from S3 listings using your Python script
process SAMPLE_SHEET {
    container 'community.wave.seqera.io/library/python_pip_awscli:7c57e4f4ddcd4d47'
    tag "${params.bucket}/${params.delivery}"
  
  input:
    // Receive bucket and delivery as values
    val bucket
    val delivery
    path script
  
  output:
    // Produce a sample_sheet.csv file in the process workDir
    path "sample_sheet.csv"
  
  script:
    """
    # Call the Python script (stored under scripts/) to generate the sample sheet.
    # This script lists raw FASTQ files and (if present) existing SIZ outputs, then writes sample_sheet.csv.
    python ${script} --bucket ${bucket} --delivery ${delivery} --output sample_sheet.csv
    """
}

workflow {

  // Determine the sample sheet channel:
  // If --sample_sheet is provided, use it.
  // Otherwise, generate it from bucket and delivery parameters.
  def sampleSheetChannel
  if( params.sample_sheet ) {
      println "Using provided sample sheet: ${params.sample_sheet}"
      sampleSheetChannel = Channel.fromPath(params.sample_sheet)
  } else if( params.bucket && params.delivery ) {
      println "No sample sheet provided; generating sample sheet from bucket ${params.bucket} and delivery ${params.delivery}"
      def script = file("scripts/generate_samplesheet.py")
      sampleSheetChannel = SAMPLE_SHEET(params.bucket, params.delivery, script)
  } else {
      error "You must provide either --sample_sheet or both --bucket and --delivery"
  }

  // Create a channel from the sample sheet CSV.
  // The CSV is expected to have header columns: sample,fastq_1,fastq_2.
  samples_ch = sampleSheetChannel
                    .splitCsv(header:true)
                    .map { row ->
                        def meta = [
                          prefix         : row.sample,
                          reads_per_file : params.reads_per_file ?: 1000,
                          sample         : row.sample
                        ]
                        // Stage the FASTQ files (can be S3 URIs). Nextflow will handle file staging.
                        tuple(meta, file(row.fastq_1), file(row.fastq_2))
                      }
  
  // Launch the SPLIT_INTERLEAVE process for each sample
  def splitInterleave = file("bin/split_interleave_fastq")
  results = SPLIT_INTERLEAVE(samples_ch, splitInterleave)
  
  // For demonstration, print out the result for each sample.
  results.view { meta, outFiles ->
    def count = outFiles.size()
    def first = outFiles[0]
    def last = outFiles[-1]
    println "Sample ${meta.sample} produced ${count} output files: ${first} ... ${last}"
  }
}
