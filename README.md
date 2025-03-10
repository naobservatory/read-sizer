# read-sizer

A Nextflow module/workflow for optimizing paired-end sequencing read files by converting them into SIZ chunks.

## Overview

read-sizer optimizes paired-end sequencing read files for parallel processing by:
- Splitting files into smaller chunks
- Interleaving paired reads
- Compressing using Zstandard (.fastq.zst)

These optimizations enhance parallelism, reduce the need to stream file pairs, and achieve significant storage savings.

## Prerequisites

- Nextflow
- Docker
- AWS credentials configured

## Installation

1. Clone the repository:
```bash
git clone git@github.com:naobservatory/read-sizer.git
cd read-sizer
```

2. Install Nextflow if needed:
```bash
curl -s https://get.nextflow.io | bash
```

## Build Process

The pipeline now automatically compiles the `split_interleave_fastq` binary during workflow execution:

1. The C source code is compiled at the start of each workflow run
2. Compilation uses a containerized environment with `gcc`, `make`, and `zstd`
3. No manual build step is required

## AWS access

Configure AWS access by setting up your region and credentials in  `~/.aws/config` and `~/.aws/credentials` respectively.

`~/.aws/config`:
```ini
[default]
region = us-east-1
output = table
tcp_keepalive = true
```

`~/.aws/credentials`:
```ini
[default]
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
```

> **Note**: If you encounter `AccessDenied` errors, export your credentials as environment variables:
> ```bash
> eval "$(aws configure export-credentials --format env)"
> ```

## Usage

### Input Data Requirements

The inputs need to be in `.fastq.gz` format, with forward and reverse reads in separate files, identically ordered. These files must be stored in:
```
s3://<bucket-name>/<delivery-name>/raw/
```

### Sample Sheet (Optional)

You can provide a CSV sample sheet with the following format:

```csv
id,fastq_1,fastq_2,outdir
sample1,s3://<bucket-name>/<delivery-name>/raw/sample1_1.fastq.gz,s3://<bucket-name>/<delivery-name>/raw/sample1_2.fastq.gz,s3://<output-bucket>/<output-path>/
sample2,s3://<bucket-name>/<delivery-name>/raw/sample2_1.fastq.gz,s3://<bucket-name>/<delivery-name>/raw/sample2_2.fastq.gz,s3://<output-bucket>/<output-path>/
```

The `outdir` column is optional. If omitted, the output directory will be automatically inferred by replacing `/raw/` with `/siz/` in the input path.

To process multiple samples across different deliveries with custom output directories, create a comprehensive sample sheet that includes samples from all deliveries with their custom output paths.

If no sample sheet is provided but `--bucket` and `--delivery` are specified, a sample sheet will be generated using `scripts/generate_samplesheet.py` by:
1. Scanning the input directory `s3://<bucket-name>/<delivery-name>/raw/` for FASTQ files
2. Identifying pairs of files that need processing (files that don't already have a processed version in the output directory `s3://<bucket-name>/<delivery-name>/siz/`)
3. The output directory for the SIZ files is inferred from the input paths if `--outdir` is not specified.

Note: The auto-generated sample sheet assumes FASTQ filenames end with _1.fastq.gz for forward reads and _2.fastq.gz for reverse reads. If your files use different suffixes, please provide a custom sample sheet.

### Running the Pipeline

Without sample sheet:
```bash
nextflow run main.nf \
    --bucket <bucket-name> \
    --delivery <delivery-name> \
    --read_pairs_per_siz <no-of-read-pairs-per-siz-file>
```
The `--read_pairs_per_siz` parameter defaults to 1,000,000 read pairs if not specified.

With sample sheet:
```bash
nextflow run main.nf \
    --sample_sheet <path-to-sample-sheet> \
    --read_pairs_per_siz <no-of-read-pairs-per-siz-file>
```

With a custom output directory:
```bash
nextflow run main.nf \
    --bucket <bucket-name> \
    --delivery <delivery-name> \
    --outdir s3://<output-bucket>/<output-path>/ \
    --read_pairs_per_siz <no-of-read-pairs-per-siz-file>
```