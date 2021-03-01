%% compile data, run SVMs on test phase data for one participant
function PrC_SVMs(project_derivative,GLM_dir,ASHS_dir,output,sub,classification_type)

sub_dir=strcat(output,'/PrC_test_phase_SVM/',sub);

%folder name for LSS output
runs={'task-test_run_1','task-test_run_2','task-test_run_3','task-test_run_4'};
%number of trials for each run
num_trials={45,45,45,45};

%hard code some variables so we can use load_event_test.m
task='task-test_';
TR=2.5;
expstart_vol=5;

%load subject PrC file, which is in subject T1 space with
%functional resolution
prcfile=strcat(sub,'_PRC_resampled.nii');
PrC=niftiread(strcat(ASHS_dir,'/',sub,'/final/',prcfile));
% %find non-zero entries which are the voxels in the
% %ROI
% [p,r,c]=ind2sub(size(PrC),find(PrC));

%% load PrC beta maps and event files
for i=1:length(runs)
    for j=1:num_trials{i}        
        %load the beta img which is in subject T1 space with functional resolution, beta_0001.nii is the trial of
        %interest
        beta_img=niftiread(strcat(GLM_dir,'/',sub,'/temp/',runs{i},'/trial_',num2str(j),'/beta_0001.nii'));
        %apply PrC mask
        prc_beta=beta_img(find(PrC));
        features((i-1)*num_trials{i}+j,:)=prc_beta';
    end
        
    %load event file and generate labels
    events((i-1)*num_trials{i}+1:i*num_trials{i},:)=load_event_test(project_derivative,sub,{task},{strcat('run-0',num2str(i),'_')},expstart_vol,TR);
    
end
    
%% process PrC beta maps and event files
% I'm still getting NaNs in the beta images even without any
% masking (see template_AvsB.mat, matlabbatch{1,
% 1}.spm.stats.fmri_spec.mthresh)
% Moreover, the NaNs appear at different locations across
% runs, indicating registration error.

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


%% run SVM
switch classification_type
    case 'mean_di'
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
    case '3_di'
        %define labels        
        lifetime_label=cell(size(lifetime_ratings));
        lifetime_label(str2num(cell2mat(lifetime_ratings))<3,:)={'low'};
        lifetime_label(str2num(cell2mat(lifetime_ratings))>=3,:)={'high'};

        recent_label=cell(size(recent_ratings));
        recent_label(str2num(cell2mat(recent_ratings))<3,:)={'low'};
        recent_label(str2num(cell2mat(recent_ratings))>=3,:)={'high'};
        
        if ~exist(strcat(sub_dir,'output'),'dir')
            mkdir (sub_dir,'output');
        end
        recent_SVM=fitclinear(recent_features,recent_label,'KFold',10);
        recent_ce = kfoldLoss(recent_SVM);%return fraction of missclassification, this is the same as 1-kfoldPredict(SVM)
        save(strcat(sub_dir,'/output/recent_3_di_SVM.mat'),'recent_SVM','recent_ce');
        
        lifetime_SVM=fitclinear(lifetime_features,lifetime_label,'KFold',10);
        lifetime_ce = kfoldLoss(lifetime_SVM);%return fraction of missclassification, this is the same as 1-kfoldPredict(SVM)
        save(strcat(sub_dir,'/output/lifetime_3_di_SVM.mat'),'lifetime_SVM','lifetime_ce');
end
end