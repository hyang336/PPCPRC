#!/bin/bash

#generate whole-brain mask based on average brain masks (in MNI space) across subjects
usage(){
echo "usage: wholebrain_mask <fmri_dir> ,<output_dir>"
}
subs=$(cat ~/scratch/working_dir/PPC_MD/sub_list_test_2mmMotionCor.txt)
if [ "$#" -eq 2 ]; then
	for sub in $subs; do
	echo 'matlab -nosplash -nodisplay -r "addpath(genpath('"'/project/6007967/hyang336/matlab/'"')); addpath(genpath('"'/home/hyang336/PPCPRC/'"')); test_resp_1stlvl('"'$project_derivatives'"','"'$output_dir'"','"'$suffix$sub'"','"$expstart_vol"','"'$fmriprep_fn'"','"$TR"','"'regress'"','"'$maskfile'"'); exit;"' 
	done
else
usage
exit 1
fi
#add all participants' brain masks
neuroglia fslmaths scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-"$sub"/anat/sub-"$sub"_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-002/anat/sub-002_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz scratch/working_dir/PPC_MD/masks/1-2_mask.nii
#binarize the mask
neuroglia fslmaths scratch/working_dir/PPC_MD/masks/1-13_mask.nii.gz -thr 0 -bin scratch/working_dir/PPC_MD/masks/bin_1-13_mask.nii

#resample to functional resolution, all functional runs from all subjects have the same 3d dimensions in MNI