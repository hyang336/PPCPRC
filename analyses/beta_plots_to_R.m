%% compile beta_plots.m and beta_plots_study_lifetime.m output into long format to be used in R (indi-ss)

%manually load in files and output csv

%lifetime task-relevant
%(lPrC75_SVC_global_null_abovethreshold_mask.nii_life1.mat)
task_rele_life=cell(size(sub_life1_ROI_beta,1)+size(sub_life2_ROI_beta,1)+size(sub_life3_ROI_beta,1)+size(sub_life4_ROI_beta,1)+size(sub_life5_ROI_beta,1),4);
task_rele_life(:,4)={'task_rele_life'};
sub_life1_ROI_beta(:,3)={'1'};
sub_life2_ROI_beta(:,3)={'2'};
sub_life3_ROI_beta(:,3)={'3'};
sub_life4_ROI_beta(:,3)={'4'};
sub_life5_ROI_beta(:,3)={'5'};
task_rele_life(:,1:3)=[sub_life1_ROI_beta;sub_life2_ROI_beta;sub_life3_ROI_beta;sub_life4_ROI_beta;sub_life5_ROI_beta];

%recent task-relevant
%(lPrC75_SVC_global_null_abovethreshold_mask.nii_recent1.mat)
task_rele_rec=cell(size(sub_recent1_ROI_beta,1)+size(sub_recent2_ROI_beta,1)+size(sub_recent3_ROI_beta,1)+size(sub_recent4_ROI_beta,1)+size(sub_recent5_ROI_beta,1),4);
task_rele_rec(:,4)={'task_rele_rec'};
sub_recent1_ROI_beta(:,3)={'1'};
sub_recent2_ROI_beta(:,3)={'2'};
sub_recent3_ROI_beta(:,3)={'3'};
sub_recent4_ROI_beta(:,3)={'4'};
sub_recent5_ROI_beta(:,3)={'5'};
task_rele_rec(:,1:3)=[sub_recent1_ROI_beta;sub_recent2_ROI_beta;sub_recent3_ROI_beta;sub_recent4_ROI_beta;sub_recent5_ROI_beta];

%lifetime during recent
%(lPrC75_SVC_global_null_abovethreshold_mask.nii_life_irr_1.mat)
task_irrele_life=cell(size(sub_life_irr_1_ROI_beta,1)+size(sub_life_irr_2_ROI_beta,1)+size(sub_life_irr_3_ROI_beta,1)+size(sub_life_irr_4_ROI_beta,1)+size(sub_life_irr_5_ROI_beta,1),4);
task_irrele_life(:,4)={'task_irrele_life(rec)'};
sub_life_irr_1_ROI_beta(:,3)={'1'};
sub_life_irr_2_ROI_beta(:,3)={'2'};
sub_life_irr_3_ROI_beta(:,3)={'3'};
sub_life_irr_4_ROI_beta(:,3)={'4'};
sub_life_irr_5_ROI_beta(:,3)={'5'};
task_irrele_life(:,1:3)=[sub_life_irr_1_ROI_beta;sub_life_irr_2_ROI_beta;sub_life_irr_3_ROI_beta;sub_life_irr_4_ROI_beta;sub_life_irr_5_ROI_beta];

%repetition suppression (lPrC75_SVC_abovethreshold_mask.nii_pres1.mat)
task_irrele_rec=cell(size(sub_pres1_ROI_beta,1)+size(sub_pres2_ROI_beta,1)+size(sub_pres3_ROI_beta,1)+size(sub_pres4_ROI_beta,1)+size(sub_pres5_ROI_beta,1)+size(sub_pres6_ROI_beta,1)+size(sub_pres7_ROI_beta,1)+size(sub_pres8_ROI_beta,1)+size(sub_pres9_ROI_beta,1),4);
task_irrele_rec(:,4)={'task_irrele_rec'};
sub_pres1_ROI_beta(:,3)={'1'};
sub_pres2_ROI_beta(:,3)={'2'};
sub_pres3_ROI_beta(:,3)={'3'};
sub_pres4_ROI_beta(:,3)={'4'};
sub_pres5_ROI_beta(:,3)={'5'};
sub_pres6_ROI_beta(:,3)={'6'};
sub_pres7_ROI_beta(:,3)={'7'};
sub_pres8_ROI_beta(:,3)={'8'};
sub_pres9_ROI_beta(:,3)={'9'};
task_irrele_rec(:,1:3)=[sub_pres1_ROI_beta;sub_pres2_ROI_beta;sub_pres3_ROI_beta;sub_pres4_ROI_beta;sub_pres5_ROI_beta;sub_pres6_ROI_beta;sub_pres7_ROI_beta;sub_pres8_ROI_beta;sub_pres9_ROI_beta];

%study lifetime all trials (lPrC75_SVC_abovethreshold_mask.nii_life1.mat)
task_irrele_life_sa=cell(size(sub_life1_ROI_beta,1)+size(sub_life2_ROI_beta,1)+size(sub_life3_ROI_beta,1)+size(sub_life4_ROI_beta,1)+size(sub_life5_ROI_beta,1),4);
task_irrele_life_sa(:,4)={'task_irrele_life(sa)'};
sub_life1_ROI_beta(:,3)={'1'};
sub_life2_ROI_beta(:,3)={'2'};
sub_life3_ROI_beta(:,3)={'3'};
sub_life4_ROI_beta(:,3)={'4'};
sub_life5_ROI_beta(:,3)={'5'};
task_irrele_life_sa(:,1:3)=[sub_life1_ROI_beta;sub_life2_ROI_beta;sub_life3_ROI_beta;sub_life4_ROI_beta;sub_life5_ROI_beta];

%study lifetime 1st trials (lPrC75_SVC_abovethreshold_mask.nii_life1_pres1.mat)
task_irrele_life_s1=cell(size(sub_life1_ROI_beta,1)+size(sub_life2_ROI_beta,1)+size(sub_life3_ROI_beta,1)+size(sub_life4_ROI_beta,1)+size(sub_life5_ROI_beta,1),4);
task_irrele_life_s1(:,4)={'task_irrele_life(s1)'};
sub_life1_ROI_beta(:,3)={'1'};
sub_life2_ROI_beta(:,3)={'2'};
sub_life3_ROI_beta(:,3)={'3'};
sub_life4_ROI_beta(:,3)={'4'};
sub_life5_ROI_beta(:,3)={'5'};
task_irrele_life_s1(:,1:3)=[sub_life1_ROI_beta;sub_life2_ROI_beta;sub_life3_ROI_beta;sub_life4_ROI_beta;sub_life5_ROI_beta];

%%
headers={'beta','SSID','fam','task'};
indi_beta=cell2table([task_rele_life;task_rele_rec;task_irrele_life;task_irrele_life_s1;task_irrele_life_sa;task_irrele_rec],'VariableNames',headers);
writetable(indi_beta,'indi_beta.xlsx');











% function beta_plots_to_R(mat_dir,output_dir)
% 
% file_affix={'lPrC75_SVC_global_null_abovethreshold_mask[.]nii_life[1-5][.]mat','lPrC75_SVC_abovethreshold_mask[.]nii_pres[1-9][.]mat',...
%     'lPrC75_SVC_abovethreshold_mask[.]nii_life[1-5][.]mat','lPrC75_SVC_abovethreshold_mask[.]nii_life[1-5]_pres1[.]mat',...
%     'lPrC75_SVC_global_null_abovethreshold_mask[.]nii_recent[1-5][.]mat','lPrC75_SVC_global_null_abovethreshold_mask[.]nii_life_irr_[1-5][.]mat'};
% 
% plot_name={'task_relevant_lifetime','task_irrelevant_recent','study_lifetime_alltrials','study_lifetime_pres1',...
%     'task_relevant_recent','lifetime_during_recent'};
% 
% summary_csv=table();
% summary_csv_name=["mean_beta","se","sd","plotname"];
% 
% indi_csv=table();
% indi_csv_name=["beta","fam","task","SSID"];
% for i=1:length(file_affix)
%     %find number of files in the mat_dir that matches file name patter
%     allfiles=dir(mat_dir);
%     targets = regexpi({allfiles.name},file_affix{i},"match");
%     filenames=targets(find(~cellfun(@isempty,targets)));
%     for j=1:length(filenames)
%         %read in file
%         
%         %concatenate
% 
% 
%     end
% end
% end