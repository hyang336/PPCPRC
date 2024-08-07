% Decode lifetime vs. recent task in the test phase in MNI (since we want
% to use post-AROMA file) with LSS-N beta values. This was to test if mPFC
% is more involved in representing goal-behavior association compared to
% mPPC and PrC.

%1.ROIs (AAL for mPFC and precuneus , ASHS for PrC, generated in native T1w
%and T2w and registered to each subject's MNI data)

%2. feature/voxel selection based on F statistics in the 1st-level

%3. Leave-one-run-out (4 fold) cross-validated linear SVM decoding with and
%without the task-switch trials

function test_task_decode(project_derivative,GLM_dir,ROI,output_dir,sub)

%% load ROI
switch ROI
    case 'mPFC'
        mask=nifitiread(strcat(project_derivative,'/masks/mPFC_masks/Frontal_SupMedial_MedOrb_CingulumAnt_aal.nii'));
    case 'precuneus'
        mask=nifitiread(strcat(project_derivative,'/masks/precuneus_masks/precuneus_mask_aal.nii'));
    case 'PrC'
        mask=niftiread(strcat(project_derivative,'ASHS_raw2/',sub,'/final/',sub,'_PRC_MNINLin6_resampled.nii'));
end

%% load events and LSS-N betas

%hard code some variables so we can use load_event_test.m
task='task-test_';
TR=2.5;
expstart_vol=5;
runs={'task-test_run_1','task-test_run_2','task-test_run_3','task-test_run_4'};
num_trials={45,45,45,45};

for i=1:length(runs)
    for j=1:num_trials{i}        
        %load the beta img which is in subject T1 space with functional resolution, beta_0001.nii is the trial of
        %interest
        beta_img=niftiread(strcat(GLM_dir,'/',sub,'/temp/',runs{i},'/trial_',num2str(j),'/beta_0001.nii'));
        %check image size, if not equal,throw an error
        if any(size(beta_img)~=size(PrC))            
            error('beta_img has a size different from the PrC mask!');
        end
        %apply PrC mask
        prc_beta=beta_img(find(PrC));
        features((i-1)*num_trials{i}+j,:)=prc_beta';
    end
        
    %load event file and generate labels
    events((i-1)*num_trials{i}+1:i*num_trials{i},:)=load_event_test(project_derivative,sub,{task},{strcat('run-0',num2str(i),'_')},expstart_vol,TR);
    
end

%remove columns(voxels) with NaNs in any run
feature_consistent=features;
feature_consistent(:,any(isnan(feature_consistent),1))=[];

%divide events and features based on task
recent_trials=events(strcmp(events(:,4),'recent'),:);
recent_features=feature_consistent(strcmp(events(:,4),'recent'),:);

lifetime_trials=events(strcmp(events(:,4),'lifetime'),:);
lifetime_features=feature_consistent(strcmp(events(:,4),'lifetime'),:);

%find the mean ratings of lifetime and recent tasks. remove NaN, which are noresp so cell2mat can work
lifetime_trials_resp=~cellfun(@isnan,lifetime_trials(:,6));
lifetime_features=lifetime_features(lifetime_trials_resp,:);

recent_trials_resp=~cellfun(@isnan,recent_trials(:,6));
recent_features=recent_features(recent_trials_resp,:);

lifetime_ratings=lifetime_trials(lifetime_trials_resp,6);
recent_ratings=recent_trials(recent_trials_resp,6);
%calculate mean
lifetime_mean=mean(str2num(cell2mat(lifetime_ratings)));
recent_mean=mean(str2num(cell2mat(recent_ratings)));


% mark trials based on distance to previous task-switch (0, 1, 2, 3, 4)

for k = 1:5 %decode with all trials but 0, 1, 2, 3, or 4, feature-selection within each CV fold
    
    %feature selection 5% voxels for each contrast (~44 in PrC, ~470 in mPFC,
%and ~340 in precuneus)in each ROI (also save the percentage of overlap
%between the two tasks in each ROI)

%define labels        
        lifetime_label=cell(size(lifetime_ratings));
        lifetime_label(str2num(cell2mat(lifetime_ratings))<lifetime_mean,:)={'low'};
        lifetime_label(str2num(cell2mat(lifetime_ratings))>=lifetime_mean,:)={'high'};

        recent_label=cell(size(recent_ratings));
        recent_label(str2num(cell2mat(recent_ratings))<recent_mean,:)={'low'};
        recent_label(str2num(cell2mat(recent_ratings))>=recent_mean,:)={'high'};
        
        if ~exist(strcat(sub_dir,'output'),'dir')
            mkdir (sub_dir,'output');
        end
        recent_SVM=fitclinear(recent_features,recent_label,'KFold',10);
        recent_ce = kfoldLoss(recent_SVM);%return fraction of missclassification, this is the same as 1-kfoldPredict(SVM)
        save(strcat(sub_dir,'/output/recent_mean_di_SVM.mat'),'recent_SVM','recent_ce');
        
        lifetime_SVM=fitclinear(lifetime_features,lifetime_label,'KFold',10);
        lifetime_ce = kfoldLoss(lifetime_SVM);%return fraction of missclassification, this is the same as 1-kfoldPredict(SVM)
        save(strcat(sub_dir,'/output/lifetime_mean_di_SVM.mat'),'lifetime_SVM','lifetime_ce');
end


%% save results

end