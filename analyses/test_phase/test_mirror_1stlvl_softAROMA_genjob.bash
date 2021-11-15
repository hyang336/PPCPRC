#!/bin/bash
usage(){
echo "Create joblist to be run with joblistSubmit
 usage: test_mirror_1stlvl_softAROMA_genjob <project_derivatives> <LSSN_foldername (relative to project_derivatives)> <output_dir> <sub> > <joblist.txt>"
}
project_derivatives=$1
LSSN_foldername=$2
output_dir=$3
suffix="sub-"
if [ "$4" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat ~/scratch/working_dir/PPC_MD/sub_list_libmotion.txt)
	#subs=$(cut -f 1 $bids_dir/participants.tsv|tail -n +2)
else
	subs=$4
fi
if [ "$#" -eq 4 ]; then
	for sub in $subs; do
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); test_mirror_1stlvl_softAROMA('"'$project_derivatives'"','"'$LSSN_foldername'"','"'$suffix$sub'"','"'$output_dir'"'); exit;"' 
	done
else
usage
exit 1
fi

