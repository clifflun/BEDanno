# BEDanno

**BEDanno** is a pipeline for annotating structural variants (SVs) with genomic features and disease/gene databases. It takes a tab-separated list of SVs (chromosomes, breakpoints, type, length, sample info) and adds annotations from reference BED files using [BEDTools](https://bedtools.readthedocs.io/) and a Python join step.

## Features

- **Reference builds**: hg19 and hg38
- **Breakpoint annotation**: Left (L) and right (R) breakpoints annotated separately for genes and regulatory features
- **Population data**: gnomAD (and TopMED for hg38) overlap and allele frequency
- **Gene/disease databases**: RefSeq, OMIM, genCC, Orphanet, DECIPHER, ISCA
- **Constraint**: ClinGen haploinsufficiency/triplosensitivity (HI/TS), Collins HI/TS
- **Other**: Segmental duplications/gaps, imprinting genes, cytoband, enhancer, promoter, repeat mask

## Requirements

- **Bash** (Unix shell)
- **BEDTools** (must be on `PATH` or load via `module load bedtools`)
- **Python 3** with **pandas**
- **Reference data**: Pre-built BED files in `reference/hg19/` and `reference/hg38/` (see [Reference data](#reference-data))

## Input format

Input is a **tab-separated** file with a header row. The first 9 columns are used; column 9 is used in the UUID. Expected columns (by position):

| # | Role |
|---|------|
| 1 | chrom1 |
| 2 | pos1 (left breakpoint) |
| 3 | chrom2 |
| 4 | pos2 (right breakpoint) |
| 5 | SV identifier |
| 6 | SV type (DEL, DUP, INS, INV) |
| 7 | SV length |
| 8 | (unused in UUID) |
| 9 | Sample/cohort identifier (e.g. genotype or ID used in UUID) |

Additional columns are preserved through the pipeline. Rows after the header are treated as one variant per line. BND (breakend) rows are excluded from the main annotation.

```

## Usage

```bash
./BEDanno.sh -i INPUT_FILE -o OUTPUT_FILE [-v REFERENCE_VERSION]
```

| Option | Description |
|--------|-------------|
| `-i` | Input TSV of SVs (required) |
| `-o` | Output annotated TSV (required) |
| `-v` | Reference version: `hg19` (default) or `hg38` |

**Examples**

```bash
# Annotate with hg19 (default)
./BEDanno.sh -i my_svs.tsv -o my_svs_annotated.tsv

# Annotate with hg38
./BEDanno.sh -i my_svs.tsv -o my_svs_annotated.tsv -v hg38
```

The script must be run from the repository directory (or with paths such that `reference/` and `mega_join.py` are found). It creates and then removes temporary files in the current directory.

## Output

The output is a single TSV with a header (from `header_hg19.txt` or `header_hg38.txt`) followed by one row per input variant. Columns include:

- Original identifiers and coordinates (UUID, chrom1, pos1, chrom2, pos2, SV_ID, SV_TYPE, SV_LEN, genotype, PT_ID, FAM_ID, PROJECT, etc.)
- **Population**: `SD_overlap`, gnomAD (and TopMED for hg38) IDs and allele frequencies
- **Gene/disease**: RefSeq, OMIM, genCC, Orphanet counts/symbols/disease/inheritance
- **Constraint**: ClinGen HI/TS, Collins HI/TS, imprinting, DECIPHER, ISCA
- **Per-breakpoint (L_ / R_)**: OMIM, RefSeq, ClinGen/collins HI/TS, cytoband, enhancer, promoter, repeat mask

Exact column names and order are in `header_hg19.txt` and `header_hg38.txt`.

## Pipeline overview

1. **Parse input**: Build UUID per variant (from chrom1, pos1, chrom2, pos2, SV ID, and column 9); write temporary BED-like files for left (L), right (R), and left+right (LR) breakpoints.
2. **Sort and merge**: Sort breakpoint BEDs with a reference `dummy.bed`; split LR by SV type (DEL, DUP, INS, INV) for type-specific population BEDs.
3. **BEDTools annotation**: Run `bedtools map` (and overlap) against reference BEDs in `reference/<hg19|hg38>/` for OMIM, RefSeq, genCC, Orphanet, DECIPHER, ISCA, ClinGen/collins HI/TS, segdup/gaps, gnomAD (and TopMED for hg38), etc., writing one `.tmp_join` file per annotation.
4. **Join**: `mega_join.py` performs a series of left joins on UUID to merge all `.tmp_join` files into one table.
5. **Finalize**: Prepend the appropriate header and write the result to `-o`.


## Files in this repo

| File | Purpose |
|------|---------|
| `BEDanno.sh` | Main annotation script |
| `mega_join.py` | Joins all annotation `.tmp_join` files by UUID |
| `header_hg19.txt` | Output column header for hg19 |
| `header_hg38.txt` | Output column header for hg38 |


## Install Python dependency

```bash
pip install pandas
```

## License

See repository license, if present.
