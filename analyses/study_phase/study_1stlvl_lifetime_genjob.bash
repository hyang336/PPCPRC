#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: study_1stlvl_lifetime_genjob <bids_dir> <project_derivatives> <output_dir> <sub> <exp_start volume> <fmriprep_foldername> <TR> <maskfile> <onset_mode> > <joblist.txt>"
}
bids_dir=$1
project_derivatives=$2
output_dir=$3
suffix="sub-"
if [ "$4" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat /scratch/hyang336/working_dir/PPC_MD/sub_list_libmotion.txt)
	#subs=$(cut -f 1 $bids_dir/participants.tsv|tail -n +2)
else
	subs=$4
fi
expstart_vol=$5
fmriprep_fn=$6
TR=$7
maskfile=$8
onset_mode=$9
if [ "$#" -eq 9 ]; then
	for sub in $subs; do
		echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); postscan_lifetime_1stlvl_softAROMA('"'$project_derivatives'"','"'$output_dir'"','"'$suffix$sub'"','"$expstart_vol"','"'$fmriprep_fn'"','"$TR"','"'$maskfile'"','"'$onset_mode'"'); exit;"' 
	done
else
usage
exit 1
fi