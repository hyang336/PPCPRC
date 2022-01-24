%% 2nd-lvl permutation test for regression slope estimated with LSS-N on the first level within PrC
%the prc mask is just to generate .nii files for visualization
%for now only focuses on the interaction between frequency and lifetime
function test_2ndlvl_freqXlife_softAROMA(lvl1_dir,sublist,output_dir,prc_mask)
%% load subject files


%% calculate null distribution (t: ~ slope / between_sub_std) and get thresholds
nsample=10000;
for s=1:nsample
   %randomly sample one image from each subject
   
   %calculate max t in PrC
   
   
end

%% calculate actual data t-maps


%% apply thresholds, anything left?


end