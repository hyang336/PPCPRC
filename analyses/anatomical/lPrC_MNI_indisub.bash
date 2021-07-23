#!/bin/bash

#generate left PrC mask for each subject in MNI space

for s in 001 002 003 004 005 006 007 008 011 012 013 014 015 016 017 018 019 020 021 022 023 024 095 026 027 028 029 030 031 032; do
#register the PrC mask to MNI space using the .h5 file produced by fMRIprep
neuroglia antsApplyTransforms -i /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_left_lfseg_heur.nii.gz -r /scratch/hyang336/working_dir/PPC_MD/fmriprep_1.5.4_AROMA/fmriprep/sub-"${s}"/anat/sub-"${s}"_space-MNI152NLin6Asym_desc-preproc_T1w.nii.gz -o /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_left_lfseg_heur_MNINLin6.nii -n NearestNeighbor -t /scratch/hyang336/working_dir/PPC_MD/fmriprep_1.5.4_AROMA/fmriprep/sub-"${s}"/anat/sub-"${s}"_from-T1w_to-MNI152NLin6Asym_mode-image_xfm.h5

#threshod
neuroglia fslmaths ~/scratch/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_left_lfseg_heur_MNINLin6.nii -thr 11 -uthr 12 /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_lPRC_MNINLin6.nii

#reslice to functional resolution
neuroglia reg_resample -ref /scratch/hyang336/working_dir/PPC_MD/fmriprep_1.5.4_AROMA/fmriprep/sub-"${s}"/func/sub-"${s}"_task-keyprac_run-01_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz -flo /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_lPRC_MNINLin6.nii -res /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_lPRC_MNINLin6_resampled.nii -inter 0
done
