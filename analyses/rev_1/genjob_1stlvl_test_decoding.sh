#!/bin/bash
usage(){
echo "generate 1st-lvl decoding script
 usage: genjob_1stlvl_test_decoding <derivative> <GLM_dir> <ASHS_dir> <subs> > <joblist.txt>"
}
deriv_dir=$1
glm_dir=$2
ashs_dir=$3
suffix="sub-"
if [ "$4" = 'all' ];then #all the space in [ ] are necessary, fuck bash
	subs=$(cat ~/scratch/working_dir/PPC_MD/sub_list_libmotion.txt)
	#subs=$(cut -f 1 $bids_dir/participants.tsv|tail -n +2)
else
	subs=$4
fi
if [ "$#" -eq 4 ]; then
for sub in $subs; do
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/home/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); test_lvl1_decoding_wrapper('"'$deriv_dir'"','"'$glm_dir'"','"'$ashs_dir'"','"'$suffix$sub'"'); exit;"' 
	done
else
usage
exit 1
fi