#!/bin/bash

in_file=$1
split_name=$2
lines_per_file=750000

echo "Initializing"

# Extract header
head -n 1 "${in_file}" > header.txt

echo "Splitting into chunks of ${lines_per_file} lines..."

# Split the file starting from line 2 (skipping header)
# -l: split by line count
# -d: numeric suffixes
# -a 3: uses 3 digits (000, 001) in case you have >100 chunks
tail -n +2 "${in_file}" | split -l ${lines_per_file} -d -a 3 - "${split_name}_chunk"

echo "Re-attaching headers"

# Loop through the newly created chunks
for chunk in ${split_name}_chunk*; do
	    cat header.txt "$chunk" > "${chunk}.tsv"
	        rm "$chunk"
	done

rm header.txt

echo "Done. Files are named ${split_name}_chunkXXX.tsv"
