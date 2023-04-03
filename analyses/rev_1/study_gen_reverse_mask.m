%% generate study phase reverse masks

%using uncorrected p < 0.01 masks
study_dec001=niftiread('C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\studyphase_2ndlvl\pres1v789_simple\prc_pres1vs789_uncorrected001_mask.nii');
prc_group_mask=niftiread('C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\masks\bin75_sum_PRC_MNINLin6_resampled.nii');
prc_mask_header=niftiinfo('C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\masks\bin75_sum_PRC_MNINLin6_resampled.nii');
study_life_dec001=niftiread('C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\studyphase_2ndlvl\postscan_stuff_020022excl\study_postscan_2ndlvl_alltrials\prc_lifedecall_uncorrected001_mask.nii');

%PrC - recent
prc_mask_header.Filename='C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\masks\bin75_sum_PRC_MNINLin6_resampled_de_study_rec_dec001.nii';
mat=prc_group_mask-double(study_rec_dec001);
niftiwrite(mat,prc_mask_header.Filename,prc_mask_header);

%PrC - life
prc_mask_header.Filename='C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\masks\bin75_sum_PRC_MNINLin6_resampled_de_study_life_dec001.nii';
mat=prc_group_mask-double(study_life_dec001);
niftiwrite(mat,prc_mask_header.Filename,prc_mask_header);


