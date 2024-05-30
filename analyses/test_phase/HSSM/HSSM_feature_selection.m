%% Modified on May-11-2024 based on the subject_feature_selection.m, select voxels that are most strongly activated by the frequency and lifetime separately for each subject in the PPC,
%% using testphase-LSSN output.
%% also recode accuracy and and rebin the response output a spreadsheet for HDDM/HSSM
%% pass in different ROI mask to extract betas in different regions
function HSSM_feature_selection(sublist,LSSN_foldername,mask_dir,project_derivative,output_dir,strict_coding)
%some hard-coded parameters to load event files
TR=2.5;
expstart_vol=5;
%project_derivative='/scratch/hyang336/working_dir/PPC_MD';
%fmriprep_foldername='fmriprep_1.5.4_AROMA';
regions={'random','hippo','PrC','mPFC_recent','mPPC_recent','mPFC_lifetime','mPPC_lifetime','lAnG_lifetime','lSFG_lifetime'};


%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

freq_result=cell2table(cell(0,20),'VariableNames',{'subj_idx','obj_freq','rt','raw_rating','accuracy','bin12_rating','bin23_rating','bin34_rating','bin45_rating','random_z','hippo_beta_pos','hippo_z_pos','hippo_beta_neg','hippo_z_neg','PrC_beta','PrC_z','mPFC_beta','mPFC_z','mPPc_beta','mPPC_z'});
life_result=cell2table(cell(0,23),'VariableNames',{'subj_idx','norm_fam','rt','raw_rating','bin12_rating','bin23_rating','bin34_rating','bin45_rating','random_z','hippo_beta_pos','hippo_z_pos','hippo_beta_neg','hippo_z_neg','PrC_beta','PrC_z','mPFC_beta','mPFC_z','mPPc_beta','mPPC_z','lAnG_beta','lAnG_z','lSFG_beta','lSFG_z'});

for i=1:length(SSID)
    %load event files and code run/trial numbers
    %runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/sub-',SSID{i},'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
    %runfile=dir(runkey);
    substr=struct();
    %substr.run=extractfield(runfile,'name');
    runevent=cell(0);
    for j=1:4 %loop through 4 runs
        %task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
        %disp(task);
        %run=regexp(substr.run{j},'run-\d\d_','match');
        %disp(run);
        substr.runevent{j}=load_event_test(project_derivative,strcat('sub-',SSID{i}),{'task-test_'},{['run-0',num2str(j),'_']},expstart_vol,TR);
        substr.runevent{j}(:,14)={j};%run number
        for s=1:size(substr.runevent{j},1)
            substr.runevent{j}{s,15}=s;%trial number
        end
        %concatenate across runs
        runevent=[runevent;substr.runevent{j}];
    end

    %extract frequency trials
    freq_trials=runevent(strcmp(runevent(:,4),'recent'),:);
    %remove noresp trials
    freq_trials_resp=freq_trials(~cellfun(@isnan,freq_trials(:,6)),:);
    %recode accuracy
    objfreq=rescale(cell2mat(freq_trials_resp(:,2)),1,5);%convert to numeric array and rescale to 1-5
    freq_ratings=str2num(cell2mat(freq_trials_resp(:,6)));%convert to numeric array
    %if the objective rating differ from the subject rating by most 1, the
    %trial is considered accurate
    if ~strict_coding
        accurate=abs(objfreq-freq_ratings)<2;
    else
        accurate=abs(objfreq-freq_ratings)<1;
    end
    freq_trials_accuracy=num2cell(accurate);
    % bin frequency ratings
    freq_ratings_bin12=freq_ratings;
    freq_ratings_bin12(freq_ratings==1|freq_ratings==2,1)=1;
    [~,~,freq_ratings_bin12]=unique(freq_ratings_bin12);%trick to recode an ascending vector to successive nature numbers
    freq_ratings_bin23=freq_ratings;
    freq_ratings_bin23(freq_ratings==2|freq_ratings==3,1)=2;
    [~,~,freq_ratings_bin23]=unique(freq_ratings_bin23);%trick to recode an ascending vector to successive nature numbers
    freq_ratings_bin34=freq_ratings;
    freq_ratings_bin34(freq_ratings==3|freq_ratings==4,1)=3;
    [~,~,freq_ratings_bin34]=unique(freq_ratings_bin34);%trick to recode an ascending vector to successive nature numbers
    freq_ratings_bin45=freq_ratings;
    freq_ratings_bin45(freq_ratings==4|freq_ratings==5,1)=4;
    [~,~,freq_ratings_bin45]=unique(freq_ratings_bin45);%trick to recode an ascending vector to successive nature numbers

    %extract frequency trials
    life_trials=runevent(strcmp(runevent(:,4),'lifetime'),:);
    %remove noresp trials
    life_trials_resp=life_trials(~cellfun(@isnan,life_trials(:,6)),:);
    %recode normative lifetime familiarity
    normfam=rescale(cell2mat(life_trials_resp(:,3)),1,5);%convert to numeric array and rescale to 1-5
    life_ratings=str2num(cell2mat(life_trials_resp(:,6)));%convert to numeric array
    %bin lifetime ratings
    life_ratings_bin12=life_ratings;
    life_ratings_bin12(life_ratings==1|life_ratings==2,1)=1;
    [~,~,life_ratings_bin12]=unique(life_ratings_bin12);%trick to recode an ascending vector to successive nature numbers
    life_ratings_bin23=life_ratings;
    life_ratings_bin23(life_ratings==2|life_ratings==3,1)=2;
    [~,~,life_ratings_bin23]=unique(life_ratings_bin23);%trick to recode an ascending vector to successive nature numbers
    life_ratings_bin34=life_ratings;
    life_ratings_bin34(life_ratings==3|life_ratings==4,1)=3;
    [~,~,life_ratings_bin34]=unique(life_ratings_bin34);%trick to recode an ascending vector to successive nature numbers
    life_ratings_bin45=life_ratings;
    life_ratings_bin45(life_ratings==4|life_ratings==5,1)=4;
    [~,~,life_ratings_bin45]=unique(life_ratings_bin45);%trick to recode an ascending vector to successive nature numbers

    % compile behavioral data
    freq_temp=[repmat({SSID{i}},[size(freq_trials_resp,1),1]),num2cell(objfreq),freq_trials_resp(:,7),num2cell(freq_ratings),freq_trials_accuracy,num2cell(freq_ratings_bin12),num2cell(freq_ratings_bin23),num2cell(freq_ratings_bin34),num2cell(freq_ratings_bin45)];
    life_temp=[repmat({SSID{i}},[size(life_trials_resp,1),1]),num2cell(normfam),life_trials_resp(:,7),num2cell(life_ratings),num2cell(life_ratings_bin12),num2cell(life_ratings_bin23),num2cell(life_ratings_bin34),num2cell(life_ratings_bin45)];

    %load beta images, loop over ROIs
    for roi=1:length(regions)
        % specify mask and slope sign for feature-selection based on region
        switch regions{roi}
            case 'random'
                maskfile='none';
                rand_beta_freq=rand(size(freq_trials_resp,1),1);
                rand_beta_freq_z=zscore(rand_beta_freq);
                rand_beta_life=rand(size(life_trials_resp,1),1);
                rand_beta_life_z=zscore(rand_beta_life);
            case 'hippo'
                maskfile=[mask_dir,'/','bin75_sum_hippo_noPrC.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                freq_roi_beta=zeros(0);
                life_roi_beta=zeros(0);

                %frequency trials
                for ftrial=1:size(freq_trials_resp,1)
                    freqbeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(freq_trials_resp{ftrial,14}),'/trial_',num2str(freq_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    freq_roi_beta(ftrial,:)=freqbeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~freq_ratings
                freq_b=zeros(0);
                for voxel=1:size(freq_roi_beta,2)
                    freq_b(voxel)=freq_roi_beta(:,voxel)\freq_ratings;%regression slope on freq ratings
                end

                %lifetime trials
                for ltrial=1:size(life_trials_resp,1)
                    lifebeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(life_trials_resp{ltrial,14}),'/trial_',num2str(life_trials_resp{ltrial,15}),'/beta_0001.nii'));
                    life_roi_beta(ltrial,:)=lifebeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~life_rating
                life_b=zeros(0);
                for voxel=1:size(life_roi_beta,2)
                    life_b(voxel)=life_roi_beta(:,voxel)\life_ratings;%regression slope on freq ratings
                end

                % for hippocampus, select both positive and negative slopes
                [~,freq_posvoxels]=maxk(freq_b,ceil(length(freq_b)*0.05));
                [~,freq_negvoxels]=mink(freq_b,ceil(length(freq_b)*0.05));
                [~,life_posvoxels]=maxk(life_b,ceil(length(life_b)*0.05));
                [~,life_negvoxels]=mink(life_b,ceil(length(life_b)*0.05));

                %average betas among the selected voxels within each trial
                hippo_freq_pos_signal=mean(freq_roi_beta(:,freq_posvoxels),2);
                hippo_freq_neg_signal=mean(freq_roi_beta(:,freq_negvoxels),2);
                hippo_life_pos_signal=mean(life_roi_beta(:,life_posvoxels),2);
                hippo_life_neg_signal=mean(life_roi_beta(:,life_negvoxels),2);

                %z-score within subject and within ROI
                hippo_freq_pos_z=zscore(hippo_freq_pos_signal);
                hippo_freq_neg_z=zscore(hippo_freq_neg_signal);
                hippo_life_pos_z=zscore(hippo_life_pos_signal);
                hippo_life_neg_z=zscore(hippo_life_neg_signal);

            case 'PrC'
                maskfile=[mask_dir,'/','bin75_sum_PRC_MNINLin6_resampled.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                freq_roi_beta=zeros(0);
                life_roi_beta=zeros(0);

                %frequency trials
                for ftrial=1:size(freq_trials_resp,1)
                    freqbeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(freq_trials_resp{ftrial,14}),'/trial_',num2str(freq_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    freq_roi_beta(ftrial,:)=freqbeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~freq_ratings
                freq_b=zeros(0);
                for voxel=1:size(freq_roi_beta,2)
                    freq_b(voxel)=freq_roi_beta(:,voxel)\freq_ratings;%regression slope on freq ratings
                end

                %lifetime trials
                for ltrial=1:size(life_trials_resp,1)
                    lifebeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(life_trials_resp{ltrial,14}),'/trial_',num2str(life_trials_resp{ltrial,15}),'/beta_0001.nii'));
                    life_roi_beta(ltrial,:)=lifebeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~life_rating
                life_b=zeros(0);
                for voxel=1:size(life_roi_beta,2)
                    life_b(voxel)=life_roi_beta(:,voxel)\life_ratings;%regression slope on freq ratings
                end

                % for PrC, select negative slopes
                [~,freq_negvoxels]=mink(freq_b,ceil(length(freq_b)*0.05));
                [~,life_negvoxels]=mink(life_b,ceil(length(life_b)*0.05));

                %average betas among the selected voxels within each trial
                PrC_freq_neg_signal=mean(freq_roi_beta(:,freq_negvoxels),2);
                PrC_life_neg_signal=mean(life_roi_beta(:,life_negvoxels),2);

                %z-score within subject and within ROI
                PrC_freq_neg_z=zscore(PrC_freq_neg_signal);
                PrC_life_neg_z=zscore(PrC_life_neg_signal);

            case 'mPFC_recent'
                maskfile=[mask_dir,'/','recent_inc_t_mPFC_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                freq_roi_beta=zeros(0);

                %frequency trials
                for ftrial=1:size(freq_trials_resp,1)
                    freqbeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(freq_trials_resp{ftrial,14}),'/trial_',num2str(freq_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    freq_roi_beta(ftrial,:)=freqbeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~freq_ratings
                freq_b=zeros(0);
                for voxel=1:size(freq_roi_beta,2)
                    freq_b(voxel)=freq_roi_beta(:,voxel)\freq_ratings;%regression slope on freq ratings
                end

                % for mPFC, select positive slopes
                [~,freq_posvoxels]=maxk(freq_b,ceil(length(freq_b)*0.05));

                %average betas among the selected voxels within each trial
                mPFC_freq_pos_signal=mean(freq_roi_beta(:,freq_posvoxels),2);

                %z-score within subject and within ROI
                mPFC_freq_pos_z=zscore(mPFC_freq_pos_signal);

            case 'mPPC_recent'
                maskfile=[mask_dir,'/','recent_inc_t_mPPC_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                freq_roi_beta=zeros(0);

                %frequency trials
                for ftrial=1:size(freq_trials_resp,1)
                    freqbeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(freq_trials_resp{ftrial,14}),'/trial_',num2str(freq_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    freq_roi_beta(ftrial,:)=freqbeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~freq_ratings
                freq_b=zeros(0);
                for voxel=1:size(freq_roi_beta,2)
                    freq_b(voxel)=freq_roi_beta(:,voxel)\freq_ratings;%regression slope on freq ratings
                end

                % for mPPC, select positive slopes
                [~,freq_posvoxels]=maxk(freq_b,ceil(length(freq_b)*0.05));

                %average betas among the selected voxels within each trial
                mPPC_freq_pos_signal=mean(freq_roi_beta(:,freq_posvoxels),2);

                %z-score within subject and within ROI
                mPPC_freq_pos_z=zscore(mPPC_freq_pos_signal);

            case 'mPFC_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_mPFC_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                life_roi_beta=zeros(0);

                %lifetime trials
                for ftrial=1:size(life_trials_resp,1)
                    lifebeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(life_trials_resp{ftrial,14}),'/trial_',num2str(life_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    life_roi_beta(ftrial,:)=lifebeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~life_ratings
                life_b=zeros(0);
                for voxel=1:size(life_roi_beta,2)
                    life_b(voxel)=life_roi_beta(:,voxel)\life_ratings;%regression slope on life ratings
                end

                % for mPFC, select positive slopes
                [~,life_posvoxels]=maxk(life_b,ceil(length(life_b)*0.05));

                %average betas among the selected voxels within each trial
                mPFC_life_pos_signal=mean(life_roi_beta(:,life_posvoxels),2);

                %z-score within subject and within ROI
                mPFC_life_pos_z=zscore(mPFC_life_pos_signal);

            case 'mPPC_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_precuneus_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                life_roi_beta=zeros(0);

                %lifetime trials
                for ftrial=1:size(life_trials_resp,1)
                    lifebeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(life_trials_resp{ftrial,14}),'/trial_',num2str(life_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    life_roi_beta(ftrial,:)=lifebeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~life_ratings
                life_b=zeros(0);
                for voxel=1:size(life_roi_beta,2)
                    life_b(voxel)=life_roi_beta(:,voxel)\life_ratings;%regression slope on life ratings
                end

                % for mPPC, select positive slopes
                [~,life_posvoxels]=maxk(life_b,ceil(length(life_b)*0.05));

                %average betas among the selected voxels within each trial
                mPPC_life_pos_signal=mean(life_roi_beta(:,life_posvoxels),2);

                %z-score within subject and within ROI
                mPPC_life_pos_z=zscore(mPPC_life_pos_signal);

            case 'lAnG_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_lAnG_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                life_roi_beta=zeros(0);

                %lifetime trials
                for ftrial=1:size(life_trials_resp,1)
                    lifebeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(life_trials_resp{ftrial,14}),'/trial_',num2str(life_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    life_roi_beta(ftrial,:)=lifebeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~life_ratings
                life_b=zeros(0);
                for voxel=1:size(life_roi_beta,2)
                    life_b(voxel)=life_roi_beta(:,voxel)\life_ratings;%regression slope on life ratings
                end

                % for lAnG, select positive slopes
                [~,life_posvoxels]=maxk(life_b,ceil(length(life_b)*0.05));

                %average betas among the selected voxels within each trial
                lAnG_life_pos_signal=mean(life_roi_beta(:,life_posvoxels),2);

                %z-score within subject and within ROI
                lAnG_life_pos_z=zscore(lAnG_life_pos_signal);

            case 'lSFG_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_lSFG_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];

                % load the mask file
                roiimg=niftiread(maskfile);
                life_roi_beta=zeros(0);

                %lifetime trials
                for ftrial=1:size(life_trials_resp,1)
                    lifebeta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(life_trials_resp{ftrial,14}),'/trial_',num2str(life_trials_resp{ftrial,15}),'/beta_0001.nii'));
                    life_roi_beta(ftrial,:)=lifebeta(find(roiimg));
                end
                %feature selection using linear regression of BOLD~life_ratings
                life_b=zeros(0);
                for voxel=1:size(life_roi_beta,2)
                    life_b(voxel)=life_roi_beta(:,voxel)\life_ratings;%regression slope on life ratings
                end

                % for lSFG, select positive slopes
                [~,life_posvoxels]=maxk(life_b,ceil(length(life_b)*0.05));

                %average betas among the selected voxels within each trial
                lSFG_life_pos_signal=mean(life_roi_beta(:,life_posvoxels),2);

                %z-score within subject and within ROI
                lSFG_life_pos_z=zscore(lSFG_life_pos_signal);
        end
    end
    %compile results
    %freq{'subj_idx','obj_freq','rt','raw_rating','accuracy','bin12_rating','bin23_rating','bin34_rating',...
    % 'bin45_rating','random_z','hippo_beta_pos','hippo_z_pos','hippo_beta_neg','hippo_z_neg','PrC_beta',...
    % 'PrC_z','mPFC_beta','mPFC_z','mPPc_beta','mPPC_z'});
    freq_temp=[freq_temp,num2cell(rand_beta_freq_z),num2cell(hippo_freq_pos_signal),num2cell(hippo_freq_pos_z),...
        num2cell(hippo_freq_neg_signal),num2cell(hippo_freq_neg_z),num2cell(PrC_freq_neg_signal),...
        num2cell(PrC_freq_neg_z),num2cell(mPFC_freq_pos_signal),num2cell(mPFC_freq_pos_z),...
        num2cell(mPPC_freq_pos_signal),num2cell(mPPC_freq_pos_z)];
    %life{'subj_idx','norm_fam','rt','raw_rating','bin12_rating','bin23_rating','bin34_rating','bin45_rating',...
    % 'random_z','hippo_beta_pos','hippo_z_pos','hippo_beta_neg','hippo_z_neg','PrC_beta','PrC_z','mPFC_beta',...
    % 'mPFC_z','mPPc_beta','mPPC_z','lAnG_beta','lAnG_z','lSFG_beta','lSFG_z'});
    life_temp=[life_temp,num2cell(rand_beta_life_z),num2cell(hippo_life_pos_signal),num2cell(hippo_life_pos_z),...
        num2cell(hippo_life_neg_signal),num2cell(hippo_life_neg_z),num2cell(PrC_life_neg_signal),...
        num2cell(PrC_life_neg_z),num2cell(mPFC_life_pos_signal),num2cell(mPFC_life_pos_z),...
        num2cell(mPPC_life_pos_signal),num2cell(mPPC_life_pos_z),num2cell(lAnG_life_pos_signal),...
        num2cell(lAnG_life_pos_z),num2cell(lSFG_life_pos_signal),num2cell(lSFG_life_pos_z)];
    
    % concatenate over subjects
    freq_result=[freq_result;freq_temp];
    life_result=[life_result;life_temp];
end
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end
writetable(freq_result,strcat(output_dir,'/HSSM_freq_data.csv'));
writetable(life_result,strcat(output_dir,'/HSSM_life_data.csv'));
end