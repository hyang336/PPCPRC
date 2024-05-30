#!/bin/bash

# Base directory
base_dir="/scratch/hyang336/working_dir/PPCMD_arch/scratch/hyang336/working_dir/PPC_MD/GLM_avgMask_nosmooth/LSS-N_test"

# File to copy
file_to_copy="beta_0001.nii"  # replace with your filename

# Destination base directory
dest_base_dir="/scratch/hyang336/working_dir/HDDM_HSSM/LSSN_test"  # replace with your destination directory

# Loop over each subject
for subject in $(ls $base_dir); do
    # Loop over each run
    for run_path in $(find $base_dir/$subject/temp -mindepth 1 -maxdepth 1 -type d); do
        # Extract just the run directory name
        run=$(basename $run_path)
        
        # Loop over each trial
        for trial in $(ls $base_dir/$subject/temp/$run); do
            # Construct the source file path
            src_file="$base_dir/$subject/temp/$run/$trial/$file_to_copy"
            
            # Construct the destination file path
            dest_file="$dest_base_dir/$subject/temp/$run/$trial/$file_to_copy"
            
            # Check if the source file exists
            if [[ -f $src_file ]]; then
                # Create the destination directory if it doesn't exist
                mkdir -p $(dirname $dest_file)
                
                # Copy the file to the destination directory
                cp $src_file $dest_file
            fi
        done
    done
done