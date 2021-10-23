#!/bin/bash

#Generate ErC mask using ASHS output, we already have both hemispheres combined and registered to MNI in the PrC analysis(75% participants)

for s in 001 002 003 004 005 006 007 008 011 012 013 014 015 016 017 018 019 020 021 022 023 024 095 026 027 028 029 030 031 032; do
#threshod
neuroglia fslmaths ~/scratch/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur_MNINLin6.nii -thr 10 -uthr 10 /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_ErC_MNINLin6.nii

#reslice to functional resolution
neuroglia reg_resample -ref /scratch/hyang336/working_dir/PPC_MD/fmriprep_1.5.4_AROMA/fmriprep/sub-"${s}"/func/sub-"${s}"_task-keyprac_run-01_space-MNI152NLin6Asym_desc-preproc_bold.nii.gz -flo /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_ErC_MNINLin6.nii -res /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_ErC_MNINLin6_resampled.nii -inter 0
done

#copy the mask for the 1st subject to output folder so the original doesn' get overwrite
cp /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-001/final/sub-001_ErC_MNINLin6_resampled.nii /scratch/hyang336/working_dir/PPC_MD/masks/sum_ErC_MNINLin6_resampled.nii

gzip /scratch/hyang336/working_dir/PPC_MD/masks/sum_ErC_MNINLin6_resampled.nii
#get the union(sum) of all masks in MNI space
out_file=/scratch/hyang336/working_dir/PPC_MD/masks/sum_ErC_MNINLin6_resampled.nii.gz
for s in 001 002 003 004 005 006 007 008 011 012 013 014 015 016 017 018 019 020 021 022 023 024 095 026 027 028 029 030 031 032; do
  neuroglia fslmaths $out_file -add /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_ErC_MNINLin6_resampled.nii $out_file
done  

#binarize again with 75% participants
neuroglia fslmaths ~/scratch/working_dir/PPC_MD/masks/sum_ErC_MNINLin6_resampled.nii.gz -thr 23 -bin ~/scratch/working_dir/PPC_MD/masks/bin75_sum_ErC_MNINLin6_resampled.nii.gz

#unzip to be used in SPM
gzip -d ~/scratch/working_dir/PPC_MD/masks/bin75_sum_ErC_MNINLin6_resampled.nii.gz
