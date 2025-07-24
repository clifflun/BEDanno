## Annotation Sources and Filtering Criteria

This table summarizes the genomic annotations integrated in our analysis, along with filtering criteria, source repositories, and references.

| **Annotation**                 | **Filtering**                                                | **Source**                               | **Reference**                                             |
|-------------------------------|---------------------------------------------------------------|-------------------------------------------|-----------------------------------------------------------|
| Promoters                     | NA                                                            | AnnotSV                                   | Geoffroy et al. 2018                                      |
| Enhancers                     | NA                                                            | AnnotSV                                   | Geoffroy et al. 2018                                      |
| Cytobands                     | NA                                                            | AnnotSV                                   | Geoffroy et al. 2018                                      |
| RefSeq                        | NCBI RefSeq curated                                           | UCSC                                      | Pruitt KD et al. 2014                                     |
| SegDup                        | `bedtools merge -d 1000`, removed PAR regions                | UCSC                                      | Bailey JA et al. 2022                                     |
| RepeatMasker                  | NA                                                            | UCSC                                      | [RepeatMasker](https://www.repeatmasker.org/)             |
| ClinGen HI/TS                 | Score > 3                                                     | UCSC                                      | Rehm HL et al. 2015                                       |
| Collins HI/TS                 | HI ≥ 0.86, TS ≥ 0.94                                          | UCSC                                      | Collins RL et al. 2022                                    |
| GenCC                         | “Definitive”, “strong”, “moderate”, or “supportive” only     | UCSC                                      | DeStefano MT et al. 2022                                  |
| Orphanet                      | “Assessed” only                                               | UCSC                                      | Pavan S et al. 2017                                       |
| ISCA                          | NA                                                            | UCSC                                      | Rehm HL et al. 2015                                       |
| gnomAD                        | NA                                                            | gnomAD (GRCh37:v2, GRCh38:v4)             | Karczewski KJ et al. 2020                                 |
| OMIM                          | Category 3 and 4 only                                         | OMIM                                      | Amberger JS et al. 2009                                   |
| DECIPHER                      | NA                                                            | DECIPHER website                          | [DECIPHER](https://www.deciphergenomics.org/)             |
| Imprinting genes              | Green category only                                           | Genomic England                           | Valter et al. 2019                                        |
| Inverted and Direct Repeats   | NA                                                            | Fernandez-Luna et al. 2024                | Fernandez-Luna et al. 2024                                |
