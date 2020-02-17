#!/bin/bash
##############This is stupid, Should just use ASHS to segment the MNI template################
#register raw T1w to MNI to get the transformation matrix
mkdir -p ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI
for s in 001 002 003 004 005 006 007 008; do
neuroglia reg_aladin -ref ~/projects/rrg-akhanf/akhanf/opt/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz -flo ~/projects/rrg-akhanf/hyang336/PPCMD_bids/sub-"${s}"/anat/sub-"${s}"_acq-MPRAGE_run-01_T1w.nii.gz -aff ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI/sub-"${s}"_affoutput.txt -res ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI/sub-"${s}"_resampled_rawT1.nii

#add left right segmentation
neuroglia fslmaths ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_raw/sub-"${s}"/final/sub-"${s}"_left_lfseg_heur.nii.gz -add ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_raw/sub-"${s}"/final/sub-"${s}"_right_lfseg_heur.nii.gz ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_raw/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz

#register and resample ASHS segmentation to MNI
neuroglia reg_resample -ref ~/projects/rrg-akhanf/akhanf/opt/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz -flo ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_raw/sub-"${s}"/final/sub-"${s}"_both_lfseg_heur.nii.gz -aff ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI/sub-"${s}"_affoutput.txt -res ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI/sub-"${s}"_ASHS_MNI.nii

#extract PrC ROIs from ASHS segmentation
neuroglia fslmaths ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI/sub-"${s}"_ASHS_MNI.nii -thr 11 -uthr 12 ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS_rawT1_to_MNI/sub-"${s}"_PRC.nii
done



