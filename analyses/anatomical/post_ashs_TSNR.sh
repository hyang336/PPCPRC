#!/bin/bash
#doesn't submit job, just run it in an interactive session
#no need to register to MNI since we only need to calculate the tSNR and we have the output in native space from fmriprep
for s in 001 002 003 004 005 006 007 008 011 013 014 016 020 021 022 095 026; do
#add left right segmentation
neuroglia fslmaths /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_left_lfseg_heur.nii.gz -add /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_right_lfseg_heur.nii.gz /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz

#extract PrC ROIs from ASHS segmentation
neuroglia fslmaths /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz -thr 11 -uthr 12 /scratch/hyang336/working_dir/PPC_MD/ASHS_raw2/sub-"${s}"/final/sub-"${s}"_PRC.nii
done
