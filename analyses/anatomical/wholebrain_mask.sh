#!/bin/bash

##################just a template, does not work, manually do this!!!#############################
#generate whole-brain mask based on average brain masks (in MNI space) across subjects
#usage(){
#echo "usage: wholebrain_mask <fmriprep_dir> ,<output_dir>"
#}
subs=$(cat ~/scratch/working_dir/PPC_MD/sub_list_test_2mmMotionCor.txt)
#command="neuroglia fslmaths "
#if [ "$#" -eq 2 ]; then
#	for sub in $subs; do
#	command='${command} "$fmriprep_dir"/fmriprep/sub-"$sub"/anat/sub-"$sub"_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  '
#	done
#else
#usage
#exit 1
#fi
#add all participants' brain masks
neuroglia fslmaths ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-001/anat/sub-001_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-002/anat/sub-002_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-003/anat/sub-003_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-004/anat/sub-004_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-005/anat/sub-005_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-006/anat/sub-006_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-007/anat/sub-007_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-008/anat/sub-008_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-011/anat/sub-011_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-013/anat/sub-013_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-014/anat/sub-014_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-016/anat/sub-016_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-020/anat/sub-020_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-021/anat/sub-021_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-022/anat/sub-022_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-026/anat/sub-026_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz -add  ~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected/fmriprep/sub-095/anat/sub-095_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz ~/scratch/working_dir/PPC_MD/masks/17Ss_2mmMotionCor_testphase_MNI_avgMask.nii
#binarize the mask
neuroglia fslmaths ~/scratch/working_dir/PPC_MD/masks/17Ss_2mmMotionCor_testphase_MNI_avgMask.nii.gz -thr 0 -bin ~/scratch/working_dir/PPC_MD/masks/bin_17Ss_2mmMotionCor_testphase_MNI_avgMask.nii
#resample to functional resolution, all functional runs from all subjects have the same 3d dimensions in MNI
neuroglia reg_resample -ref ~/projects/rrg-akhanf/akhanf/opt/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz -flo ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_raw/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz -res /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_PRC_resampled.nii -inter 0