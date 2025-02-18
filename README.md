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
- C compiler (gcc)
- Zstandard library
- Make
- AWS credentials configured

## Installation

1. Clone the repository:
```bash
git clone https://github.com/naobservatory/read-sizer.git
cd read-sizer
```

2. Install Nextflow if needed:
```bash
curl -s https://get.nextflow.io | bash
```

3. Build the `split_interleave_fastq` executable:
```bash
cd lib
make
cd ..
```

## AWS Configuration

Configure AWS access by setting up your credentials in either `~/.aws/config` or `~/.aws/credentials`:

`~/.aws/config`:
```ini
[default]
region = us-east-1
output = table
tcp_keepalive = true
aws_access_key_id = <ACCESS_KEY_ID>
aws_secret_access_key = <SECRET_ACCESS_KEY>
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

Your paired-end read files should be stored in:
```
s3://<bucket-name>/<delivery-name>/raw
```

### Sample Sheet (Optional)

You can provide a CSV sample sheet with the following format:

```csv
sample,fastq_1,fastq_2
sample1,s3://<bucket-name>/<delivery-name>/raw/sample1_1.fastq.gz,s3://<bucket-name>/<delivery-name>/raw/sample1_2.fastq.gz
sample2,s3://<bucket-name>/<delivery-name>/raw/sample2_1.fastq.gz,s3://<bucket-name>/<delivery-name>/raw/sample2_2.fastq.gz
```

If not provided, the pipeline will automatically generate a sample sheet by:
1. Scanning the input directory `s3://<bucket-name>/<delivery-name>/raw` for FASTQ files
2. Identifying pairs of files that need processing (files that don't already have a processed version in the output directory `s3://<bucket-name>/<delivery-name>/siz`)

### Running the Pipeline

Without sample sheet:
```bash
nextflow run main.nf \
    --bucket <bucket-name> \
    --delivery <delivery-name> \
    --reads_per_file <number-of-reads-per-file>
```

With sample sheet:
```bash
nextflow run main.nf \
    --sample_sheet <path-to-sample-sheet> \
    --reads_per_file <number-of-reads-per-file>
```

### Output

Processed files will be saved to:
```
s3://<bucket-name>/<delivery-name>/siz/
```

### Cleanup

Remove temporary work files:
```bash
aws s3 rm s3://<bucket-name>/work --recursive
```