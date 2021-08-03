#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: study_1stlvl_decoding_bin_genjob <project_derivatives> <fmriprep_foldername> <LSSN_foldername> <ASHS_foldername> <output_dir> <sub> > <joblist.txt>"
}
project_derivatives=$1
fmriprep_fn=$2
LSSN_foldername=$3
ASHS_foldername=$4
output_dir=$5
suffix="sub-"
if [ "$6" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat /scratch/hyang336/working_dir/PPC_MD/sub_list_libmotion.txt)
else
	subs=$6
fi
if [ "$#" -eq 6 ]; then
	for sub in $subs; do
		echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); study_1stlvl_SVM_bin('"'$project_derivatives'"','"'$fmriprep_fn'"','"'$LSSN_foldername'"','"'ASHS_foldername'"','"'$output_dir'"','"'$suffix$sub'"'); exit;"' 
	done
else
usage
exit 1
fi