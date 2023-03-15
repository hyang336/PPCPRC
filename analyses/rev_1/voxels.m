%% extract voxels that are selected for >, < or != for each subject, aggregate across cross-validation folds and generate nifti files
% I think we can use the nifti header of the subject specific PrC mask in
% MNI space reseampled to functional resolution for all the masks generated
% by Princeton MVPA toolbox since they should all be in the MNI space and
% having functional resolution. But I'm not sure if the MVPA toolbox moves
% or deforms the masks in the process. It is unlikely...

% For each classification, adding all the feature-selection masks (across 4
% runs/validation folds) in a subject to form a subject-specific voxel mask

    %read in subject PrC-MNI-resampled mask (ASHS) header

% For each classification, aggregate across subject, with each voxel value
% represents the number of subjects having that voxel selected as a feature
% for a particular classification
