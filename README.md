Inspired by AnnotSV

AnnotSV is lacking the following: 

annotation at breakpoint

annotation for BND

Hence, the development of this tool

I am not allowed to share all the sources publicly, but here are where you can get them


Following files are from AnnotSV

enhancers

promoters

cytoband


Below are processed/filtered from UCSC tableBrowser


RefSeq

repeatmask

segdup: merged 1k distance

HI/TS: filtered following the description

genCC: only "definitive|strong|moderate|supportive"

orphanet: only "assessed"


Independent sources: 

gnomad

TopMED (nstd229 downloaded Mar 2025)

IDR

DECIPHER

ISCA

imprinting genes(green tag only, from genomicsEngland)


breakpoint annotation = if breakpoint falls inside annotation data

match = 98% recipricol overlap (intersect -f -r)

any overlap (intersect -wb)

