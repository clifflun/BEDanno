
## 🧬 Structural Variant Annotation Pipeline

This repository includes a Bash script `BEDanno.sh` for annotating structural variant (SV) breakpoints with multiple curated and population databases.

### 🔧 Usage

```bash
./BEDanno.sh -i INPUT_FILE -o OUTPUT_FILE [-v hg19|hg38]
```

- `-i`: Path to the input file (required)
- `-o`: Path to the output file (required)
- `-v`: Reference genome version (`hg19` or `hg38`, default: `hg19`)

### 📋 Description

The script processes a structural variant list and performs multi-layered annotation. Key operations include:

1. **Preprocessing & Sorting**
   - Extracts left, right, and combined breakpoints
   - Sorts entries for efficient processing

2. **Breakpoint Annotation**
   - Annotates with various curated datasets using helper script `get_bkpt_id.sh`
   - Includes gene, repeat, regulatory, and cytoband features

3. **Population Frequency Annotation**
   - Uses `get_match.sh` to annotate with:
     - `gnomAD` (SV type-specific)
     - `TopMED` (hg38 only)
     - `Segmental duplications` and `gaps`

4. **Overlap-based Annotation**
   - Uses `get_any_ol.sh` and `get_count.sh` to compute overlap with:
     - RefSeq, OMIM, genCC, Orphanet, Imprinting Genes, ISCA, DECIPHER
     - ClinGen and Collins HI/TS datasets

5. **Joining and Output**
   - Merges all annotations into a unified file
   - Adds appropriate headers based on genome version
   - Outputs a tab-separated file

### 🗂️ Reference File Organization

The script expects a directory structure like:
```
reference/
├── hg19/
│   ├── RefSeq_sorted.bed
│   ├── OMIM_sorted.bed
│   └── ...
└── hg38/
    ├── RefSeq_sorted.bed
    ├── TopMED_DUP_sorted.bed
    └── ...
```

### 📚 Annotation Sources

| Annotation                 | Filtering Criteria                          | Source                 | Reference                                |
|---------------------------|---------------------------------------------|------------------------|------------------------------------------|
| Promoters, Enhancers      | NA                                          | AnnotSV                | Geoffroy et al. 2018                      |
| Cytobands                 | NA                                          | AnnotSV                | Geoffroy et al. 2018                      |
| RefSeq                    | NCBI RefSeq curated                         | UCSC                   | Pruitt KD et al. 2014                     |
| SegDup                    | `bedtools merge -d 1000`, PARs removed      | UCSC                   | Bailey JA et al. 2022                     |
| RepeatMasker              | NA                                          | UCSC                   | [RepeatMasker](https://www.repeatmasker.org) |
| ClinGen HI/TS             | Score > 3                                   | UCSC                   | Rehm HL 2015 et al.                       |
| Collins HI/TS             | HI ≥ 0.86, TS ≥ 0.94                        | UCSC                   | Collins RL et al. 2022                    |
| genCC                     | "Definitive\|strong\|moderate\|supportive"  | UCSC                   | DeStefano MT et al. 2022                  |
| Orphanet                  | “Assessed” only                             | UCSC                   | Pavan S et al. 2017                       |
| ISCA                      | NA                                          | UCSC                   | Rehm HL 2015 et al.                       |
| gnomAD                    | NA                                          | gnomAD                 | Konrad J et al. 2020                      |
| OMIM                      | Category 3 and 4 only                       | OMIM                   | Amberger J et al. 2009                    |
| DECIPHER                  | NA                                          | DECIPHER website       | [DECIPHER](https://www.deciphergenomics.org) |
| Imprinting genes          | Green category only                         | Genomic England        | Valter et al. 2019                        |
| Inverted and Direct Repeats | NA                                        | Fernandez-Luna et al.  | Fernandez-Luna et al. 2024               |
