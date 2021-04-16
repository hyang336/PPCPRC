#!/bin/bash
#doesn't submit job, just run it in an interactive session
#no need to register to MNI since we only need to calculate the tSNR and we have the output in native space from fmriprep
for s in 001 002 003 004 005 006 007 008 011 012 013 014 016 017 018 019 020 021 022 024 095 026 027 028 029 030 031 032; do
#add left right segmentation
neuroglia fslmaths /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_left_lfseg_heur.nii.gz -add /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_right_lfseg_heur.nii.gz /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz

#extract PrC ROIs from ASHS segmentation
neuroglia fslmaths /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz -thr 11 -uthr 12 /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_PRC.nii

#resample to functional resolution, using key_prac scan as the reference image
neuroglia reg_resample -ref /scratch/hyang336/working_dir/PPC_MD/fmriprep_1.5.4_AROMA/fmriprep/sub-"${s}"/func/sub-"${s}"_task-keyprac_run-01_space-T1w_desc-preproc_bold.nii.gz -flo /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_PRC.nii -res /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_PRC_resampled.nii -inter 0

done
