#!/usr/bin/env python3
import argparse
import subprocess
import csv
import sys

def list_s3_files(s3_path, allow_missing=False):
    """
    List files at an S3 path using the AWS CLI.
    Returns a list of filenames, i.e. ["c.txt"] from s3://a/b/c.txt
    If allow_missing is True and the command fails, returns an empty list.
    """
    try:
        result = subprocess.run(["aws", "s3", "ls", s3_path],
                                capture_output=True, text=True, check=True)
        files = []
        for line in result.stdout.strip().splitlines():
            parts = line.split()
            # AWS CLI ls output format: <date> <time> <size> <filename>
            # We split the line and take the last part which is the filename
            if len(parts) >= 4:
                filename = parts[-1]
                files.append(filename)
        return files
    except subprocess.CalledProcessError as e:
        if allow_missing:
            sys.stderr.write(f"Warning: Could not list {s3_path}. Assuming directory is missing.\n")
            return []
        else:
            sys.stderr.write(f"Error listing {s3_path}: {e}\n")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description="Generate sample_sheet.csv from raw FASTQ files and existing SIZ files on S3"
    )
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--delivery", required=True, help="Delivery folder name")
    parser.add_argument("--output", default="sample_sheet.csv", help="Output CSV file (default: sample_sheet.csv)")
    args = parser.parse_args()

    # Construct S3 paths for raw and siz directories
    raw_dir = f"s3://{args.bucket}/{args.delivery}/raw/"
    siz_dir = f"s3://{args.bucket}/{args.delivery}/siz/"

    # List files in raw and siz directories.
    raw_files = list_s3_files(raw_dir, allow_missing=False)
    siz_files = list_s3_files(siz_dir, allow_missing=True)

    # Build dictionary of prefixes from raw files.
    # We assume raw files end with _1.fastq.gz and _2.fastq.gz for forward and reverse reads.
    prefixes = {}
    for f in raw_files:
        if f.endswith("_1.fastq.gz"):
            prefix = f[:-len("_1.fastq.gz")]
            prefixes.setdefault(prefix, {})['R1'] = raw_dir + f
        elif f.endswith("_2.fastq.gz"):
            prefix = f[:-len("_2.fastq.gz")]
            prefixes.setdefault(prefix, {})['R2'] = raw_dir + f

    # Determine processed prefixes by examining SIZ files.
    # We assume a SIZ file is named like: <prefix>_div000000.fastq.zst,
    # so the prefix name is everything before the first occurrence of '_div'
    processed_prefixes = set()
    for f in siz_files:
        if '_div' in f:
            prefix = f.partition("_div")[0]
            processed_prefixes.add(prefix)

    # Write the sample sheet for prefixes that haven't been processed.
    with open(args.output, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["id", "fastq_1", "fastq_2"])
        for prefix, reads in prefixes.items():
            if prefix in processed_prefixes:
                continue
            if 'R1' in reads and 'R2' in reads:
                writer.writerow([prefix, reads['R1'], reads['R2']])
            else:
                sys.stderr.write(f"Warning: Incomplete pair for prefix {prefix}\n")

    print(f"Sample sheet written to {args.output}")

if __name__ == "__main__":
    main()
