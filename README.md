# read-sizer
Nextflow module/workflow to convert paired-end sequencing read files to SIZ chunks

## Rationale
This module optimizes paired-end sequencing read files for parallel processing by splitting them into smaller, interleaved, and Zstandard-compressed (.fastq.zst) chunks. This approach enhances parallelism, reduces the need to stream file pairs, and achieves significant size savings.

## Installation
To install `read-sizer`, follow these steps:

1. Clone the repository:
```bash
git clone https://github.com/naobservatory/read-sizer.git
cd read-sizer
```
2. Ensure you have Nextflow installed. You can install Nextflow using the following command:
```bash
curl -s https://get.nextflow.io | bash
```
3. Ensure you have the required dependencies installed:
- C compiler (e.g., gcc)
- Zstandard library
- Make

## Usage
### Mounting the S3 Bucket
Before running the workflow, ensure that the S3 bucket is mounted. The workflow script will attempt to mount the S3 bucket if it is not already mounted.

### Running the Workflow
```bash
nextflow run main.nf --bucket <S3_BUCKET_NAME> --delivery <DELIVERY_FOLDER> --reads_per_file <READS_PER_FILE>
```
- `<S3_BUCKET_NAME>`: The name of the S3 bucket where the raw FASTQ files are stored.
- `<DELIVERY_FOLDER>`: The folder within the S3 bucket where the raw FASTQ files are located.
- `<READS_PER_FILE>`: The number of reads per output file (default is 1000).

### Example
```bash
nextflow run main.nf --bucket my-s3-bucket --delivery my-delivery-folder --reads_per_file 10000000
```

### Unmounting the S3 Bucket
The workflow will automatically unmount the S3 bucket after processing is complete.
