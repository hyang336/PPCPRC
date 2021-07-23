#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: study_1stlvl_lifetime_pres1_genjob <project_derivatives> <LSSN_foldername> <output_dir> <sub>  <fmriprep_foldername> > <joblist.txt>"
}
project_derivatives=$1
LSSN_foldername=$2
output_dir=$3
suffix="sub-"
if [ "$4" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat /scratch/hyang336/working_dir/PPC_MD/sub_list_libmotion.txt)
else
	subs=$4
fi
fmriprep_fn=$5
if [ "$#" -eq 5 ]; then
	for sub in $subs; do
		echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); study_1stlvl_lifetime_con_pres_1('"'$project_derivatives'"','"'$LSSN_foldername'"','"'$output_dir'"','"'$suffix$sub'"','"'$fmriprep_fn'"'); exit;"' 
	done
else
usage
exit 1
fi