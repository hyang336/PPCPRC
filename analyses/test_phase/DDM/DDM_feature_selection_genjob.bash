#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit. Note that this particular procedure does not create the output directory when it does no exist.
 usage: DDM_feature_selection_genjob <sublist> <mask_file> <LSSN_foldername> <output_dir> > <joblist.txt>"
}
sublist=$1
mask_file=$2
LSSN_foldername=$3
output_dir=$4
if [ "$#" -eq 4 ]; then
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); subject_PPC_feature_selection('"'$sublist'"','"'$mask_file'"','"'$LSSN_foldername'"','"'$output_dir'"'); exit;"' 
else
usage
exit 1
fi

