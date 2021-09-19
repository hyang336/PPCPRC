%% select voxels that are most strongly activated by the frequency task for each subject in the PPC, using testphase-LSSN output
%% also recode accuracy and output a spreadsheet for HDDM
function subject_PPC_feature_selection(sublist,PPC_mask_dir,LSSN_foldername,output_dir)
%some hard-coded parameters to load event files
TR=2.5;
expstart_vol=5;
project_derivative='/scratch/hyang336/working_dir/PPC_MD';
fmriprep_foldername='fmriprep_1.5.4_AROMA';
precuneus=niftiread(PPC_mask_dir);

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

freq_result=cell2table(cell(0,4),'VariableNames',{'subj_idx','rt','response','precuneus_beta'});

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
    ratings=str2num(cell2mat(freq_trials_resp(:,6)));%convert to numeric array
    %if the objective rating differ from the subject rating by most 1, the
    %trial is considered accurate
    accurate=abs(objfreq-ratings)<2;
    freq_trials_resp(:,13)=num2cell(accurate);
    
    %load beta images
    %for now using the aal bilateral precuneus mask from WFU_pickatlas as the
    %ROI
    Precuneus_beta=zeros(0);
    for trial=1:size(freq_trials_resp,1)
        beta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(freq_trials_resp{trial,14}),'/trial_',num2str(freq_trials_resp{trial,15}),'/beta_0001.nii'));
        Precuneus_beta(trial,:)=beta(find(precuneus));
    end
    %feature selection using linear regression of BOLD~freq_ratings, then rank
    %ordering the slope
    b=zeros(0);
    for voxel=1:size(Precuneus_beta,2)
        b(voxel)=Precuneus_beta(:,voxel)\ratings;%regression slope on freq ratings
    end
    [~,topvoxels]=maxk(b,ceil(length(b)*0.05));%top 5% voxels
    
    %average betas among the selected voxels within each trial
    precuneus_signal=mean(Precuneus_beta(:,topvoxels),2);
    
    %compile results and save RT, accuracy, betas, and subject number
    temp=[repmat({SSID{i}},[size(freq_trials_resp,1),1]),freq_trials_resp(:,7),freq_trials_resp(:,13),num2cell(precuneus_signal)];    
    freq_result=[freq_result;temp];
    
end
writetable(freq_result,strcat(output_dir,'/hddm_data.csv'));
end