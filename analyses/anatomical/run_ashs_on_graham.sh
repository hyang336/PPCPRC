#!/bin/bash
for s in 001 002 003 004 005 006 007 008; do
mkdir -p ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS/sub-${s}
regularSubmit -E 'export ASHS_ROOT=/project/6007967/akhanf/opt/ashs-fastashs_2018' ''"$ASHS_ROOT"'/bin/ashs_main.sh -a ~/projects/rrg-akhanf/akhanf/opt/ashs-fastashs/atlases/ashs_atlas_upennpmc_20161128/ -g ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/fmriprep_1.5.4_all/fmriprep/sub-'"${s}"'/anat/sub-'"${s}"'_desc-preproc_T1w.nii.gz -f ~/projects/rrg-akhanf/hyang336/PPCMD_bids/sub-'"${s}"'/anat/sub-'"${s}"'_acq-SPACE_run-01_T2w.nii.gz -w ~/projects/rrg-akhanf/cfmm-deriv/Kohler/PPC_MD/ASHS/sub-'"${s}"'/ -T'
sleep 3
done

#pretty sure ashs_main.sh by itself does not submit jobs on Graham, it has some qsubmit call at the end but without -Q flag I don't think those are called.