%% extract voxels that are selected for >, < or != for each subject, aggregate across cross-validation folds and generate nifti files
% I think we can use the nifti header of the subject specific PrC mask in
% MNI space reseampled to functional resolution for all the masks generated
% by Princeton MVPA toolbox since they should all be in the MNI space and
% having functional resolution. But I'm not sure if the MVPA toolbox moves
% or deforms the masks in the process. It is unlikely...

%How should I handle the 2 types of binarizations? Does 1 voxel showing
%significant 12 > 345 necessitate it showing 123 > 45? For now just take
%the union of the two since we are averaging the decoding performance
%across the two types of binarization anyway
sub_list={'sub-001','sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-011','sub-012','sub-013','sub-014','sub-015','sub-016','sub-017','sub-018','sub-019','sub-020','sub-021','sub-022','sub-023','sub-024','sub-095','sub-026','sub-027','sub-028','sub-029','sub-030','sub-031','sub-032'};
ASHS_dir='C:/Users/haozi/OneDrive/Desktop/PhD/fMRI_PrC-PPC_data/ASHS_raw2';
working_dir='C:/Users/haozi/OneDrive/Desktop/PhD/fMRI_PrC-PPC_data/Rev_1_test-decoding';

% For each classification, select voxels that are in 3 out of the 4
% feature-selection mask in a subject to form a subject-specific voxel mask
for i=1:length(sub_list)
    %read in subject PrC-MNI-resampled mask (ASHS) header
    niiheader=niftiinfo(strcat(ASHS_dir,'/',sub_list{i},'/final/',sub_list{i},'_PRC_MNINLin6_resampled.nii'));
    %init a zero volume using the PrC mask nii
    niimat=zeros(size(niftiread(strcat(ASHS_dir,'/',sub_list{i},'/final/',sub_list{i},'_PRC_MNINLin6_resampled.nii'))));

    % Task-relevant recent decrease
    niiheader.Filename=[working_dir,'/',sub_list{i},'/rel_rec_dec_voxels.nii'];
    % load decoding results
    rec_xsy3l=load([working_dir,'/',sub_list{i},'/rec_low3_xsy.mat']);%3 coded as low
    rec_xsy3h=load([working_dir,'/',sub_list{i},'/rec_high3_xsy.mat']);%3 coded as high
    %detect which voxels were selected in 3 out of 4 feature-selection
    %folds
    for j=1:4 %4folde so feature selection
        voxels3h{j,:}=find(rec_xsy3h.subj.masks{1,j+1}.mat);
        voxels3l{j,:}=find(rec_xsy3l.subj.masks{1,j+1}.mat);
    end
    %find voxels appearing in 3 out of 4
    commonV3h = intersect(intersect(voxels3h{1},voxels3h{2}), voxels3h{3});
    commonV3h = union(commonV3h, intersect(intersect(voxels3h{1},voxels3h{2}), voxels3h{4}));
    commonV3h = union(commonV3h, intersect(intersect(voxels3h{1},voxels3h{3}), voxels3h{4}));
    commonV3h = union(commonV3h, intersect(intersect(voxels3h{2},voxels3h{3}), voxels3h{4}));

    commonV3l = intersect(intersect(voxels3l{1},voxels3l{2}), voxels3l{3});
    commonV3l = union(commonV3l, intersect(intersect(voxels3l{1},voxels3l{2}), voxels3l{4}));
    commonV3l = union(commonV3l, intersect(intersect(voxels3l{1},voxels3l{3}), voxels3l{4}));
    commonV3l = union(commonV3l, intersect(intersect(voxels3l{2},voxels3l{3}), voxels3l{4}));

    commonV_rec_xsy=union(commonV3l,commonV3h);%combine voxels in both binarization schemes

    %nifti mat
    rec_xsy_mat=niimat;
    rec_xsy_mat(commonV_rec_xsy)=1;

    %save nifti using PrC mask header and nifti mat
    niftiwrite(rec_xsy_mat,niiheader.Filename,niiheader);




    % Task-relevant lifetime increase
    niiheader.Filename=[working_dir,'/',sub_list{i},'/rel_life_inc_voxels.nii'];
    % load decoding results
    life_xgy3l=load([working_dir,'/',sub_list{i},'/life_low3_xgy.mat']);%3 coded as low
    life_xgy3h=load([working_dir,'/',sub_list{i},'/rec_high3_xgy.mat']);%3 coded as high
    %detect which voxels were selected in 3 out of 4 feature-selection
    %folds
    for j=1:4 %4folde so feature selection
        voxels3h{j,:}=find(life_xgy3h.subj.masks{1,j+1}.mat);
        voxels3l{j,:}=find(life_xgy3l.subj.masks{1,j+1}.mat);
    end
    %find voxels appearing in 3 out of 4
    commonV3h = intersect(intersect(voxels3h{1},voxels3h{2}), voxels3h{3});
    commonV3h = union(commonV3h, intersect(intersect(voxels3h{1},voxels3h{2}), voxels3h{4}));
    commonV3h = union(commonV3h, intersect(intersect(voxels3h{1},voxels3h{3}), voxels3h{4}));
    commonV3h = union(commonV3h, intersect(intersect(voxels3h{2},voxels3h{3}), voxels3h{4}));

    commonV3l = intersect(intersect(voxels3l{1},voxels3l{2}), voxels3l{3});
    commonV3l = union(commonV3l, intersect(intersect(voxels3l{1},voxels3l{2}), voxels3l{4}));
    commonV3l = union(commonV3l, intersect(intersect(voxels3l{1},voxels3l{3}), voxels3l{4}));
    commonV3l = union(commonV3l, intersect(intersect(voxels3l{2},voxels3l{3}), voxels3l{4}));

    commonV_life_xgy=union(commonV3l,commonV3h);%combine voxels in both binarization schemes

    %nifti mat
    life_xgy_mat=niimat;
    life_xgy_mat(commonV_life_xgy)=1;

    %save nifti using PrC mask header and nifti mat
    niftiwrite(life_xgy_mat,niiheader.Filename,niiheader);
end

% For each classification, aggregate across subject, with each voxel value
% represents the number of subjects having that voxel selected as a feature
% for a particular classification
rec_xsy_2ndlvl=zeros(size(niimat));
life_xgy_2ndlvl=zeros(size(niimat));
for i=1:length(sub_list)
    % Task-relevant recent decrease
    rec_xsy_2ndlvl=rec_xsy_2ndlvl+niftiread([working_dir,'/',sub_list{i},'/rel_rec_dec_voxels.nii']);

    % Task-relevant lifetime increase
    life_xgy_2ndlvl=life_xgy_2ndlvl+niftiread([working_dir,'/',sub_list{i},'/rel_life_inc_voxels.nii']);
end
niiheader.Filename=[working_dir,'/rel_rec_dec_voxels_2ndlvl.nii'];
%save nifti using PrC mask header and nifti mat
niftiwrite(rec_xsy_2ndlvl,niiheader.Filename,niiheader);

niiheader.Filename=[working_dir,'/rel_life_inc_voxels_2ndlvl.nii'];
%save nifti using PrC mask header and nifti mat
niftiwrite(life_xgy_2ndlvl,niiheader.Filename,niiheader);
