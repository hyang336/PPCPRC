#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: test_resp_1stlvl_mean_centered_di_genjob <bids_dir> <project_derivatives> <output_dir> <sub> <exp_start volume> <fmriprep_foldername> <TR> <maskfile> > <joblist.txt>"
}
bids_dir=$1
project_derivatives=$2
output_dir=$3
suffix="sub-"
if [ "$4" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat ~/scratch/working_dir/PPC_MD/sub_list_test_2mmMotionCor.txt)
	#subs=$(cut -f 1 $bids_dir/participants.tsv|tail -n +2)
else
	subs=$4
fi
expstart_vol=$5
fmriprep_fn=$6
TR=$7
maskfile=$8
if [ "$#" -eq 8 ]; then
	for sub in $subs; do
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); test_resp_1stlvl_mean_centered_di('"'$project_derivatives'"','"'$output_dir'"','"'$suffix$sub'"','"$expstart_vol"','"'$fmriprep_fn'"','"$TR"','"'regress'"','"'$maskfile'"'); exit;"' 
	done
else
usage
exit 1
fi

