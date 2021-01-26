#!/bin/bash

#generate whole-brain mask based on average brain masks (in MNI space) across subjects
usage(){
echo "usage: wholebrain_mask <fmri_dir> ,<output_dir>,<sublist.txt>"
}
#add all participants' brain masks
neuroglia fslmaths scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-001/anat/sub-001_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-002/anat/sub-002_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz scratch/working_dir/PPC_MD/masks/1-2_mask.nii
#binarize the mask
neuroglia fslmaths scratch/working_dir/PPC_MD/masks/1-13_mask.nii.gz -thr 0 -bin scratch/working_dir/PPC_MD/masks/bin_1-13_mask.nii

#resample to functional resolution