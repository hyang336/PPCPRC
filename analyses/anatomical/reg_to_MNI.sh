#!/bin/bash
#register fmriprep preprocessed T1 to MNI, use the transformation matrix to register contrast images (which is in BOLD space which is registered to T1 by fmriprep) to MNI for 2nd lvl analyses

#these are quick, just run in an interactive session
for s in 001 002 003 004 005 006 007 008; do
mkdir -p ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/T1_to_MNI/sub-${s}
neuroglia reg_aladin -ref ~/projects/rrg-akhanf/akhanf/opt/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz -flo ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/fmriprep_1.5.4_newTF/fmriprep/sub-'"${s}"'/anat/sub-'"${s}"'_desc-preproc_T1w.nii.gz -aff ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/T1_to_MNI/sub-'"${s}"'/affoutput.txt -res ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/T1_to_MNI/sub-'"${s}"'/resampled_T1.nii
done

