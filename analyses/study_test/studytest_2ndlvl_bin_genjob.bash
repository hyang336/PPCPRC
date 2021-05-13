#!/bin/bash
usage(){
echo "generate 2nd-lvl MATLAB script
 usage: studytest_2ndlvl_bin_genjob <con_dir> <output_dir> <sub_list> <contrast> <maskfile> > <joblist.txt>"
}
con_dir=$1
output_dir=$2
sub_list=$3
contrast=$4
maskfile=$5
if [ "$#" -eq 5 ]; then
echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); studytest_2ndlvl_softAROMA_bin('"'$con_dir'"','"'$output_dir'"','"'$sub_list'"','"'$contrast'"','"'$maskfile'"'); exit;"' 
else
usage
exit 1
fi
