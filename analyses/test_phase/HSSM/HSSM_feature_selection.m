%% Modified on May-11-2024 based on the subject_feature_selection.m, select voxels that are most strongly activated by the frequency and lifetime separately for each subject in the PPC, 
%% using testphase-LSSN output.
%% also recode accuracy and and rebin the response output a spreadsheet for HDDM/HSSM
%% pass in different ROI mask to extract betas in different regions
function HSSM_feature_selection(sublist,LSSN_foldername,mask_dir,project_derivative,output_dir,strict_coding)
%some hard-coded parameters to load event files
TR=2.5;
expstart_vol=5;
%project_derivative='/scratch/hyang336/working_dir/PPC_MD';
fmriprep_foldername='fmriprep_1.5.4_AROMA';
regions={'random','hippo','PrC','mPFC_recent','prec_recent','mPFC_lifetime','prec_lifetime','lAnG_lifetime','lSFG_lifetime'};


%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

freq_result=cell2table(cell(0,7),'VariableNames',{'subj_idx','stim','rt','response','roi_beta','roi_z','rating'});

life_result=cell2table(cell(0,7),'VariableNames',{'subj_idx','stim','rt','response','roi_beta','roi_z','rating'});

for i=1:length(SSID)
    %load event files and code run/trial numbers
    runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/sub-',SSID{i},'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
    runfile=dir(runkey);
    substr=struct();
    substr.run=extractfield(runfile,'name');
    runevent=cell(0);
    for j=1:4 %loop through 4 runs
        task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
        run=regexp(substr.run{j},'run-\d\d_','match');
        substr.runevent{j}=load_event_test(project_derivative,strcat('sub-',SSID{i}),task,run,expstart_vol,TR);
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
    %recode accuracy and put it on column 13
    objfreq=rescale(cell2mat(freq_trials_resp(:,2)),1,5);%convert to numeric array and rescale to 1-5
    freq_ratings=str2num(cell2mat(freq_trials_resp(:,6)));%convert to numeric array
    %if the objective rating differ from the subject rating by most 1, the
    %trial is considered accurate
    if ~strict_coding
        accurate=abs(objfreq-freq_ratings)<2;
    else
        accurate=abs(objfreq-freq_ratings)<1;
    end
    freq_trials_resp(:,13)=num2cell(accurate);
    
    %load beta images, loop over ROIs
    for roi=1:length(regions)
        % specify mask and slope sign for feature-selection based on region
        switch regions{roi}
            case 'random'
                maskfile='none';
                slope_sign='NA';
            case 'hippo'
                maskfile=[mask_dir,'/','bin75_sum_hippo_noPrC.nii'];
                slope_sign='both';
            case 'PrC'
                maskfile=[mask_dir,'/','bin75_sum_PRC_MNINLin6_resampled.nii'];
                slope_sign='negative';
            case 'mPFC_recent'
                maskfile=[mask_dir,'/','recent_inc_t_mPFC_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];
                slope_sign='positive';
            case 'prec_recent'
                maskfile=[mask_dir,'/','recent_inc_t_mPPC_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];
                slope_sign='positive';
            case 'mPFC_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_mPFC_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];
                slope_sign='positive';
            case 'prec_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_precuneus_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];
                slope_sign='positive';
            case 'lAnG_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_lAnG_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];
                slope_sign='positive';
            case 'lSFG_lifetime'
                maskfile=[mask_dir,'/','lifetime_inc_t_lSFG_PeakUncor001_clusterFWE_abovethreshold_mask.nii'];
                slope_sign='positive';
        end
        
        % load the mask file
        roi=niftiread(maskfile);

    end
    roi_beta=zeros(0);
    for trial=1:size(freq_trials_resp,1)
        beta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(freq_trials_resp{trial,14}),'/trial_',num2str(freq_trials_resp{trial,15}),'/beta_0001.nii'));
        roi_beta(trial,:)=beta(find(roi));
    end
    %feature selection using linear regression of BOLD~freq_ratings, then rank
    %ordering the slope
    b=zeros(0);
    for voxel=1:size(roi_beta,2)
        b(voxel)=roi_beta(:,voxel)\freq_ratings;%regression slope on freq ratings
    end
    
    if strcmp(slope_sign,'positive')
        [~,topvoxels]=maxk(b,ceil(length(b)*0.05));%top 5% voxels, need to change maxk to mink when using regions with decreasing signal (e.g. PrC)
    elseif strcmp(slope_sign,'negative')
        [~,topvoxels]=mink(b,ceil(length(b)*0.05));
    end
    %average betas among the selected voxels within each trial
    roi_signal=mean(roi_beta(:,topvoxels),2);
    
    %z-score within subject and within ROI
    roi_z=zscore(roi_signal);
    
    %compile results and save RT, accuracy, betas, and subject number
    temp=[repmat({SSID{i}},[size(freq_trials_resp,1),1]),freq_trials_resp(:,2),freq_trials_resp(:,7),freq_trials_resp(:,13),num2cell(roi_signal),num2cell(roi_z),num2cell(freq_ratings)];    
    freq_result=[freq_result;temp];
    
end
if ~exist(output_dir,'dir')
    mkdir(output_dir);
end
writetable(freq_result,strcat(output_dir,'/hddm_data_z.csv'));
end