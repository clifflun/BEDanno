#!/bin/bash

a=""
b=""
f=0.98
r=false
output=""

usage() {
    echo "Usage: $0 [-ab] [-o OUTPUT_FILE] "
    echo "  -a INPUT_FILE    Input file"
    echo "  -b DATABASE_FILE Database file"
    echo "  -o OUTPUT_FILE   Specify output file"
    echo "  -f OUTPUT_FILE   set fraction"
    echo "  -r OUTPUT_FILE   set overlap recipricol"
    exit 1
}

while getopts ":a:b:o:f:r" opt; do
    case $opt in
        a)
            a="$OPTARG"
            # echo "input file: $a"
            ;;
        b)
            b="$OPTARG"
            # echo "database file: $b"
            ;;
        f)
            f="$OPTARG"
            # echo "overlapping fraction: $f"
            ;;
        r)
            r=true
            # echo "set recipricol"
            ;;
        o)
            output="$OPTARG"
            # echo "output file: $output"
            ;;
        :)
            usage
            exit 1;;
    esac
done

cmd_args="intersect -sorted -a ${a}.tmp_sorted -b $b -wb -f ${f}"
if [ $r = true ]; then
    cmd_args+=" -r"
fi

sort -k1,1 -k2,2n $a > ${a}.tmp_sorted


bedtools $cmd_args | cut -f6,10- | awk '{
for (i=2; i<=NF; i++) {
data[$1][i] = (data[$1][i] ? data[$1][i] ";" : "") $i
}
}
END {
for (key in data) {
printf "%s", key
for (i=2; i<=NF; i++) {
printf " %s", data[key][i]
}
printf "\n"
}
}' | sort -k 1b,1 > $output


