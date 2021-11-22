#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: study_1stlvl_lifeXfreq_genjob.bash <project_derivatives> <output_dir> <sub> <exp_start volume> <fmriprep_foldername> <TR> <maskfile> > <joblist.txt>"
}
project_derivatives=$1
output_dir=$2
suffix="sub-"
if [ "$3" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat /scratch/hyang336/working_dir/PPC_MD/sub_list_libmotion.txt)
	#subs=$(cut -f 1 $bids_dir/participants.tsv|tail -n +2)
else
	subs=$3
fi
expstart_vol=$4
fmriprep_fn=$5
TR=$6
maskfile=$7
if [ "$#" -eq 7 ]; then
	for sub in $subs; do
		echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); study_1stlvl_lifeXfreq('"'$project_derivatives'"','"'$output_dir'"','"'$suffix$sub'"','"$expstart_vol"','"'$fmriprep_fn'"','"$TR"','"'$maskfile'"'); exit;"' 
	done
else
usage
exit 1
fi