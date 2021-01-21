#!/bin/bash
for s in 001 002 003 004 005 006 007 008 011 013 014 016 020 021 022 095 026; do
mkdir -p ~/scratch/working_dir/PPC_MD/ASHS_raw2/sub-${s}
regularSubmit -E 'export ASHS_ROOT=/project/6050199/akhanf/opt/ashs-fastashs_2018' "$ASHS_ROOT"'/bin/ashs_main.sh -a ~/projects/rrg-akhanf/akhanf/opt/ashs-fastashs/atlases/ashs_atlas_upennpmc_20161128/ -g ~/projects/ctb-akhanf/switt4/switt4-bids/Kohler/PPC_MD/bids/sub-'"${s}"'/anat/sub-'"${s}"'_acq-MPRAGE_run-01_T1w.nii.gz -f ~/projects/ctb-akhanf/switt4/switt4-bids/Kohler/PPC_MD/bids/sub-'"${s}"'/anat/sub-'"${s}"'_acq-SPACE_run-01_T2w.nii.gz -w ~/scratch/working_dir/PPC_MD/ASHS_raw2/sub-'"${s}"'/ -T'
sleep 3
done

#pretty sure ashs_main.sh by itself does not submit jobs on Graham, it has some qsubmit call at the end but without -Q flag I don't think those are called.