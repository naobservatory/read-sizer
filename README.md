# read-sizer
Nextflow module/workflow to convert paired-end sequencing read files to SIZ chunks

## Rationale
This module optimizes paired-end sequencing read files for parallel processing by splitting them into smaller, interleaved, and Zstandard-compressed (.fastq.zst) chunks. This approach enhances parallelism, reduces the need to stream file pairs, and achieves significant size savings.

## Installation
To install `read-sizer`, follow these steps:

1. Clone the repository:
```{bash}
git clone https://github.com/naobservatory/read-sizer.git
cd read-sizer
```
2. Ensure you have Nextflow installed. You can install Nextflow using the following command:

```{bash}
curl -s https://get.nextflow.io | bash
```

3. Ensure you have the required dependencies installed:
- C compiler (e.g., gcc)
- Zstandard library
- Make

## Usage

## Input/Output
