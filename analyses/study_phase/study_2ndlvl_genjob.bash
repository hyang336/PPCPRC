#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: study_2ndlvl_genjob <con_dir> <output_dir> <sublist> <maskfile> <contrast_type> <contrast(s)> > <joblist.txt>"
}
con_dir=$1
output_dir=$2
sublist=$3
maskfile=$4
contrast_type=$5
contrast1=$6
contrast2=$7
if [ "$#" -eq 6 ]; then
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); study_2ndlvl_repsup('"'$con_dir'"','"'$output_dir'"','"'$sublist'"','"'$maskfile'"','"'$contrast_type'"','"'$contrast1'"'); exit;"'
elif [ "$#" -eq 7 ]; then
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); study_2ndlvl_repsup('"'$con_dir'"','"'$output_dir'"','"'$sublist'"','"'$maskfile'"','"'$contrast_type'"','"'$contrast1'"','"'$contrast2'"'); exit;"'
else
usage
exit 1
fi