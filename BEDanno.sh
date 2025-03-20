#!/bin/bash

i=""
o=""
v="hg19"

usage() {
    echo "Usage: $0 [-ab] [-o OUTPUT_FILE] "
    echo "  -i INPUT_FILE    Input file"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LOG_FILE="${o}.log"

# exec > >(tee -a "$LOG_FILE") 2>&1

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
            exit 1;;
    esac
done

fn=$(basename $i)

module load bedtools

if [[ $v == "hg19" ]]; then
    ref_path="${SCRIPT_DIR}/reference/hg19/"
else
    ref_path="${SCRIPT_DIR}/reference/hg38/"
fi

### get intermediate files
echo
echo "Preparing Files" 
awk '{print $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > uuid_${fn}.tmp
awk '{print $1"_"$2"_"$3"_"$4"_"$5"_"$9, $0}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > 00_original_info_${fn}.tmp_join
awk '{print $1, $2, $2, $6, $9, $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > L_bkpt_${fn}.tmp
awk '{print $1, $4, $4, $6 ,$9, $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > R_bkpt_${fn}.tmp
awk '{print $1, $2, $4, $6 ,$9, $1"_"$2"_"$3"_"$4"_"$5"_"$9}' $i |sed 's/ /\t/g' | sort -k1,1 -k2,2n | grep -v pos > LR_bkpt_${fn}.tmp

cat ${ref_path}dummy.bed LR_bkpt_${fn}.tmp | grep -v BND | sort -k1,1 -k2,2n > LR_bkpt2_${fn}.tmp
mv LR_bkpt2_${fn}.tmp LR_bkpt_${fn}.tmp

cat ${ref_path}dummy.bed L_bkpt_${fn}.tmp | sort -k1,1 -k2,2n > L_bkpt2_${fn}.tmp
mv L_bkpt2_${fn}.tmp L_bkpt_${fn}.tmp

cat ${ref_path}dummy.bed R_bkpt_${fn}.tmp | sort -k1,1 -k2,2n > R_bkpt2_${fn}.tmp
mv R_bkpt2_${fn}.tmp R_bkpt_${fn}.tmp

for type in  DEL DUP INS INV; do   
  grep ${type} LR_bkpt_${fn}.tmp > LR_bkpt_${type}_${fn}.tmp
done

### Annotation

### get bkpt info
echo "Breakpoint Annotation" 
bkpt_list=$(ls ${ref_path}*sorted.bed|grep -iv -E "gnomad|segdup|genCC|orphanet|imprinting|ISCA|DECIPHER|TopMED")
for a in $bkpt_list; do
    echo "annotating $(basename $a)" 
    for b in L_bkpt_${fn}.tmp R_bkpt_${fn}.tmp; do
        # refseq OMIM repeat_mask IDR promoter enhancer cytoband ISCA DECIPHER IDR, TAD pending
        bash ${SCRIPT_DIR}/get_bkpt_id.sh -a $b -b $a -o ${b}_$(basename $a)_${fn}.tmp_join
    done
done

### get matching info
echo 
echo "Population Annotation" 
echo "--------------------" 

echo "segdup" 
bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}segdup_sorted.bed -o 01_LR_bkpt_segdup_${fn}.tmp_join

echo "gnomad" 
bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_DUP_${fn}.tmp -b ${ref_path}gnomad_DUP_sorted.bed -r -o gnomad_DUP_${fn}.tmp_gnomad
bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_INS_${fn}.tmp -b ${ref_path}gnomad_sorted.bed -r -o gnomad_INS_${fn}.tmp_gnomad
bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_DEL_${fn}.tmp -b ${ref_path}gnomad_DEL_sorted.bed -r -o gnomad_DEL_${fn}.tmp_gnomad
bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_INV_${fn}.tmp -b ${ref_path}gnomad_INV_sorted.bed -r -o gnomad_INV_${fn}.tmp_gnomad
cat *tmp_gnomad | sort -k1,1 -k2,2n > 1a_LR_bkpt_gnomad_${fn}.tmp_join 

if [[ $v == "hg38" ]]; then
    echo "TopMED" 
    bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_DUP_${fn}.tmp -b ${ref_path}TopMED_DUP_sorted.bed -r -o TopMED_DUP_${fn}.tmp_TopMED
    bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_INS_${fn}.tmp -b ${ref_path}TopMED_sorted.bed -r -o TopMED_INS_${fn}.tmp_TopMED
    bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_DEL_${fn}.tmp -b ${ref_path}TopMED_DEL_sorted.bed -r -o TopMED_DEL_${fn}.tmp_TopMED
    bash ${SCRIPT_DIR}/get_match.sh -a LR_bkpt_INV_${fn}.tmp -b ${ref_path}TopMED_INV_sorted.bed -r -o TopMED_INV_${fn}.tmp_TopMED
    cat *tmp_TopMED | sort -k1,1 -k2,2n > 1b_LR_bkpt_TopMED_${fn}.tmp_join 
fi
echo 

### any overlap
echo "Any overlap Annotation" 
echo "--------------------" 

echo "refseq" 
bash ${SCRIPT_DIR}/get_count.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}RefSeq_sorted.bed -o 2a_count_refseq_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}RefSeq_sorted.bed -o 2b_any_ol_refseq_${fn}.tmp_join

echo "OMIM" 
bash ${SCRIPT_DIR}/get_count.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}OMIM_sorted.bed -o 3a_count_omim_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}OMIM_sorted.bed -o 3b_any_ol_omim_${fn}.tmp_join

echo "genCC" 
bash ${SCRIPT_DIR}/get_count.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}genCC_sorted.bed -o 4a_count_genCC_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}genCC_sorted.bed -o 4b_any_ol_genCC_${fn}.tmp_join

echo "orphanet" 
bash ${SCRIPT_DIR}/get_count.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}orphanet_sorted.bed -o 5a_count_orphanet_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}orphanet_sorted.bed -o 5b_any_ol_orphanet_${fn}.tmp_join

echo "imprinting genes" 
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}imprinting_genes_sorted.bed -o 6_imprinting_genes_${fn}.tmp_join

echo "DECIPHER" 
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}DECIPHER_sorted.bed -o 7_DECIPHER_${fn}.tmp_join

echo "ISCA" 
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}ISCA_sorted.bed -o 8_ISCA_${fn}.tmp_join

echo "HI/TS"  
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}clinGenHaplo_sorted.bed -o 96_any_ol_CGHI_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}clinGenTriplo_sorted.bed -o 97_any_ol_CGTS_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}collinsHaplo_sorted.bed -o 98_any_ol_collinsHI_${fn}.tmp_join
bash ${SCRIPT_DIR}/get_any_ol.sh -a LR_bkpt_${fn}.tmp -b ${ref_path}collinsTriplo_sorted.bed -o 99_any_ol_collinsTS_${fn}.tmp_join
echo 

echo "Joining files"  
echo "--------------------" 

join_list=$(ls *${fn}.tmp_join)
annotated="uuid_${fn}.tmp"
for file in $join_list; do 
    echo "Joining $file" 
    join -a1 -e "0" -o auto $annotated $file > joined_${fn}.tmp
    mv joined_${fn}.tmp $annotated
done

if [[ $v == "hg19" ]]; then
    header="${SCRIPT_DIR}/header_hg19.txt"
else
    header="${SCRIPT_DIR}/header_hg38.txt"
fi

awk '{print $0}' OFS="\t" $annotated | sed 's/\r//g' | sed 's/ /\t/g'> annotated_${fn}.tmp
cat $header annotated_${fn}.tmp> $o
echo   

echo "Annotation Done" 
echo "--------------------" 
echo "input file: $i"      
echo "Number of variants: $(wc -l $o | cut -d ' ' -f1)"  
echo "output file: $o" 
echo "reference path: ${ref_path}" 

rm *${fn}.tmp*

