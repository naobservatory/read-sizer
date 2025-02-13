#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { SPLIT_INTERLEAVE } from './modules/split_interleave.nf'

// Define parameters (these can be overridden at runtime)
params.bucket            = params.bucket          
params.delivery          = params.delivery
params.reads_per_file    = params.reads_per_file    ?: 1000

workflow {

    // Define a local mount point for the S3 bucket (using baseDir)
    def bucket = params.bucket
    def delivery = params.delivery
    def base = baseDir
    def s3_mount = "${base}/${bucket}"

    // Create the mount directory if it doesn't exist
    def mountDir = new File(s3_mount)
    if( !mountDir.exists() ) {
        mountDir.mkdirs()
    }

    // Mount the S3 bucket using s3-mount if not already mounted
    def mountCheckCmd = "mountpoint -q ${s3_mount}"
    def mountStatus = mountCheckCmd.execute().waitFor()
    if( mountStatus != 0 ) {
        println "Mounting S3 bucket ${bucket} at ${s3_mount}"
        def mountCmd = "mount-s3 --read-only ${bucket} ${s3_mount}"
        def proc = mountCmd.execute()
        proc.waitFor()
        if( proc.exitValue() != 0 ) {
            error "Failed to mount S3 bucket: ${proc.err.text}"
        }
    } else {
        println "S3 bucket ${bucket} already mounted at ${s3_mount}"
    }

    // List all sample names from ${s3_mount}/${delivery}/raw/*_1.fastq.gz
    def rawDir = new File("${s3_mount}/${delivery}/raw")
    if( !rawDir.exists() ) {
         error "Raw directory does not exist: ${rawDir}"
    }
    def rawFiles = rawDir.listFiles().findAll { it.name.endsWith("_1.fastq.gz") }
    def samples = rawFiles.collect { it.name.replaceFirst(/_1.fastq.gz$/, '') }.unique()
    println "Found samples: ${samples}"

    // Filter samples: if any file matching ${s3_mount}/${delivery}/siz/${sample}*.fastq.zst exists, skip that sample.
    def sizDir = new File("${s3_mount}/${delivery}/siz")
    def samplesToProcess = samples.findAll { sample ->
         if (!sizDir.exists()) return true
         def matching = sizDir.listFiles(new FilenameFilter() {
              boolean accept(File dir, String name) {
                  return name.startsWith(sample) && name.endsWith(".fastq.zst")
              }
         })
         return (matching == null || matching.size() == 0)
    }

    println "Samples to process: ${samplesToProcess}"

    // Create a channel of tuples (sample, delivery, bucket) for those samples needing processing
    Channel.from(samplesToProcess)
           .map { sample -> tuple(sample, delivery, bucket) }
           .set { sampleChannel }

    // Launch the SPLIT_INTERLEAVE process for each sample that needs processing
    sampleChannel | SPLIT_INTERLEAVE
}
