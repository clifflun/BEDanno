#!/bin/bash

i=""
o=""
v="hg19"

usage() {
    echo "Usage: $0 -i INPUT_FILE -o OUTPUT_FILE [-v REFERENCE_VERSION]"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while getopts ":i:o:v:" opt; do
    case $opt in
        i)
            i="$OPTARG"
            echo "input file: $i" 
            echo "Number of variants: $(wc -l $i | cut -d ' ' -f1)" 
            ;;
        o)
            o="$OPTARG"
            echo "output file: $o"
            ;;

        v)
            v="$OPTARG"
            echo "reference version: $v" 
            ;;
        :)
            usage
            ;;            
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done

if [[ -z "$i" || -z "$o" ]]; then
    echo "Error: -i (input) and -o (output) are required."
    usage
fi

fn=$(basename $i)

module load bedtools

if [[ $v == "hg19" ]]; then
    ref_path="${SCRIPT_DIR}/reference/hg19/"
else
    ref_path="${SCRIPT_DIR}/reference/hg38/"
fi

### get intermediate f
rm *tmp*
echo "Preparing Files"
# Process all sorts in parallel using pipes
# Optional: Clear files beforehand to ensure they are fresh
> "L_bkpt_${fn}.tmp"
> "R_bkpt_${fn}.tmp"
> "LR_bkpt_${fn}.tmp"

awk -v fn="$fn" 'BEGIN { OFS="\t" }
FNR > 1 {
    uuid = $1 "_" $2 "_" $3 "_" $4 "_" $5 "_" $9
    
    # Keep these sorted as they are likely your join keys
    print uuid | "sort -u > uuid_" fn ".tmp"
    print uuid, $0 | "sort -k1,1 > 00_original_info_" fn ".tmp_join"
    
    # Direct write (No Sorting)
    print $1, $2, $2, $6, $9, uuid > "L_bkpt_" fn ".tmp"
    print $1, $4, $4, $6, $9, uuid > "R_bkpt_" fn ".tmp"
    print $1, $2, $4, $6, $9, uuid > "LR_bkpt_" fn ".tmp"
}' "$i"
echo 
# echo
# echo "Preparing Files" 
# awk '{print $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > uuid_${fn}.tmp
# awk '{print $1"_"$2"_"$3"_"$4"_"$5"_"$9, $0}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > 00_original_info_${fn}.tmp_join
# awk '{print $1, $2, $2, $6, $9, $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > L_bkpt_${fn}.tmp
# awk '{print $1, $4, $4, $6 ,$9, $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > R_bkpt_${fn}.tmp
# awk '{print $1, $2, $4, $6 ,$9, $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > LR_bkpt_${fn}.tmp

cat ${ref_path}dummy.bed LR_bkpt_${fn}.tmp | grep -v BND | sort -k1,1 -k2,2n > LR_bkpt2_${fn}.tmp
mv LR_bkpt2_${fn}.tmp LR_bkpt_${fn}.tmp

cat ${ref_path}dummy.bed L_bkpt_${fn}.tmp | sort -k1,1 -k2,2n > L_bkpt2_${fn}.tmp
mv L_bkpt2_${fn}.tmp L_bkpt_${fn}.tmp

cat ${ref_path}dummy.bed R_bkpt_${fn}.tmp | sort -k1,1 -k2,2n > R_bkpt2_${fn}.tmp
mv R_bkpt2_${fn}.tmp R_bkpt_${fn}.tmp

for type in  DEL DUP INS INV; do   
  grep ${type} LR_bkpt_${fn}.tmp > LR_bkpt_${type}_${fn}.tmp
done

## Annotation

echo "Breakpoint Annotation"
bedtools map -a L_bkpt_${fn}.tmp -b ${ref_path}OMIM_sorted.bed -c 4,5,6 -o collapse,collapse,collapse -null 0 | cut -f6- > L_bkpt_${fn}_OMIM.tmp_join &
bedtools map -a R_bkpt_${fn}.tmp -b ${ref_path}OMIM_sorted.bed -c 4,5,6 -o collapse,collapse,collapse -null 0 | cut -f6- > R_bkpt_${fn}_OMIM.tmp_join &

bkpt_list=$(ls ${ref_path}*sorted.bed 2>/dev/null | grep -iv -E "OMIM|gnomad|segdup|genCC|orphanet|imprinting|ISCA|DECIPHER|TopMED")
for a in $bkpt_list; do
    refname=$(basename $a)
    echo $refname
    bedtools map -a L_bkpt_${fn}.tmp -b $a -c 4 -o distinct -null 0 | cut -f6- > L_bkpt_${fn}_${refname}.tmp_join &
    bedtools map -a R_bkpt_${fn}.tmp -b $a -c 4 -o distinct -null 0 | cut -f6- > R_bkpt_${fn}_${refname}.tmp_join &
done
wait

### get matching info
echo 
echo "Population Annotation" 
echo "--------------------" 

echo "segdup and gaps" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}segdup_gap_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 01_LR_bkpt_segdup_${fn}.tmp_join &

echo "gnomad" 

bedtools map -a LR_bkpt_DUP_${fn}.tmp -b ${ref_path}gnomad_DUP_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > gnomad_DUP_${fn}.tmp_gnomad &
bedtools map -a LR_bkpt_INS_${fn}.tmp -b ${ref_path}gnomad_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > gnomad_INS_${fn}.tmp_gnomad &
bedtools map -a LR_bkpt_DEL_${fn}.tmp -b ${ref_path}gnomad_DEL_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > gnomad_DEL_${fn}.tmp_gnomad &
bedtools map -a LR_bkpt_INV_${fn}.tmp -b ${ref_path}gnomad_INV_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > gnomad_INV_${fn}.tmp_gnomad &
wait
cat *tmp_gnomad > 1a_LR_bkpt_gnomad_${fn}.tmp_join 

if [[ $v == "hg38" ]]; then
    echo "TopMED" 
    bedtools map -a LR_bkpt_DUP_${fn}.tmp -b ${ref_path}TopMED_DUP_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > TopMED_DUP_${fn}.tmp_TopMED &
    bedtools map -a LR_bkpt_INS_${fn}.tmp -b ${ref_path}TopMED_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > TopMED_INS_${fn}.tmp_TopMED &
    bedtools map -a LR_bkpt_DEL_${fn}.tmp -b ${ref_path}TopMED_DEL_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > TopMED_DEL_${fn}.tmp_TopMED &
    bedtools map -a LR_bkpt_INV_${fn}.tmp -b ${ref_path}TopMED_INV_sorted.bed -r -f 0.98 -c 4,5,5 -o collapse,collapse,min -null 0 | cut -f6- > TopMED_INV_${fn}.tmp_TopMED &
    wait
    cat *tmp_TopMED > 1b_LR_bkpt_TopMED_${fn}.tmp_join 
fi
echo 

### any overlap
echo "Any overlap Annotation" 
echo "--------------------" 

echo "refseq" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}RefSeq_sorted.bed -c 4,4 -o count,collapse -null 0 | cut -f6- > 2_RefSeq_${fn}.tmp_join &

echo "OMIM"
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}OMIM_sorted.bed -c 4,4,5,6 -o count,collapse,collapse,collapse -null 0 | cut -f6- > 3a_omim_${fn}.tmp_join &

echo "genCC" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}genCC_sorted.bed -c 4,4 -o count,collapse -null 0 | cut -f6- > 4a_genCC_${fn}.tmp_join &

echo "orphanet" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}orphanet_sorted.bed -c 4,4,5 -o count,collapse,collapse -null 0 | cut -f6- > 5a_orphanet_${fn}.tmp_join &

echo "imprinting genes" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}imprinting_genes_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 6_imprinting_genes_${fn}.tmp_join &

echo "DECIPHER" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}DECIPHER_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 7_DECIPHER_${fn}.tmp_join &

echo "ISCA" 
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}ISCA_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 8_ISCA_${fn}.tmp_join &

echo "HI/TS"  
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}clinGenHaplo_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 96_CGHI_${fn}.tmp_join &
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}clinGenTriplo_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 97_CGTS_${fn}.tmp_join &
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}collinsHaplo_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 98_collinsHI_${fn}.tmp_join &
bedtools map -a LR_bkpt_${fn}.tmp -b ${ref_path}collinsTriplo_sorted.bed -c 4 -o distinct -null 0 | cut -f6- > 99_collinsTS_${fn}.tmp_join &
echo 
wait



echo "Joining files via Python (Fast Mode)"
echo "--------------------"
# Run the Python mega-joiner
python3 ${SCRIPT_DIR}/mega_join.py uuid_${fn}.tmp $join_list

if [[ $v == "hg19" ]]; then
    header="${SCRIPT_DIR}/header_hg19.txt"
else
    header="${SCRIPT_DIR}/header_hg38.txt"
fi
# Clean up final formatting
mv uuid_${fn}.tmp.final annotated_${fn}.tmp
cat $header annotated_${fn}.tmp > $o


echo "Annotation Done"
echo "--------------------"
echo "input file: $i"
if [[ -n "$input_line_count" ]]; then
    echo "Number of variants (input): $input_line_count"
fi
echo "Number of variants: $(wc -l < "$o")"
echo "output file: $o"
echo "reference path: ${ref_path}"

rm *tmp*
