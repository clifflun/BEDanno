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

export PATH=$PATH:/store/carvalho/Member/clun/BEDanno/

fn=$(basename $i)

mkdir -p ${fn%.tsv}_output
input_abs=$(readlink -f "$i")

cd ${fn%.tsv}_output


file_split.sh $input_abs ${fn}_splits

for file in "${fn}_splits"*.tsv
do 
	time BEDanno -i ${PWD}/$file -o ${file%.tsv}_annotated.tsv -v ${v} 
done



