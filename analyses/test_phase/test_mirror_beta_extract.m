%% second way to test mirror effect during frequency judgement

% Select voxels that showed task-irrelevant lifetime effect during
% frequency judgement. Extract and average their LSS-N betas, output to a
% .csv file, then run a two-level regression in R

function test_mirror_beta_extract(project_derivative,LSSN_foldername,sublist,output,lifetime_mask)
%predefine some parameters
TR=2.5;
expstart_vol=5;
fmriprep_foldername='fmriprep_1.5.4_AROMA';
ROI=niftiread(lifetime_mask);
%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

event_compiled=cell(0);%predefine result cell

for i=1:length(SSID)%loop through subjects
    %load event file for each subject
    runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/sub-',SSID{i},'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
    runfile=dir(runkey);
    substr=struct();
    substr.run=extractfield(runfile,'name');
    [~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/sub-',SSID{i},'/',SSID{i},'_task-pscan_data.xlsx'));
    substr.postscan=raw;
    runevent=cell(0);
    
    for j=1:4 %loop through 4 runs
        task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
        run=regexp(substr.run{j},'run-\d\d_','match');
        substr.runevent{j}=load_event_test(project_derivative,strcat('sub-',SSID{i}),task,run,expstart_vol,TR);
        
        %need these two indices to remove individual trials and still load the
        %correct betas
        substr.runevent{j}(:,13)=num2cell([1:1:45]);%trial number
        substr.runevent{j}(:,14)={j};%run number
        
        %extract freq trials
        freq_trials=strcmp(substr.runevent{j}(:,4),'recent');
        freq_event=substr.runevent{j}(freq_trials,:);
        
        %handle noresp trials
        respnan=cellfun(@(x) isnan(x),freq_event(:,6),'UniformOutput',0);
        resp_event= freq_event(~cell2mat(respnan),:);
        
        %rescale obj freq and calculate freq_error
        obj_freq_rescale=rescale(cell2mat(resp_event(:,2)),1,5);
        freq_error=str2num(cell2mat(resp_event(:,6)))-obj_freq_rescale;
        resp_event(:,15)= num2cell(freq_error);%freq_error judged-objective
        
        %concatenate into one cell
        runevent=[runevent;resp_event];
    end
    
    %putin sub id
    runevent(:,17)=SSID(i);
    
    %load beta in the ROI mask and average
    for k = 1:size(runevent,1)
        %load LSS-N beta
        trial_beta=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/sub-',SSID{i},'/temp/task-test_run_',num2str(runevent{k,14}),'/trial_',num2str(runevent{k,13}),'/beta_0001.nii'));
        %extract beta in the ROI
        trial_ROI_beta=nanmean(trial_beta(find(ROI)));%average beta within the ROI
        %compute mean across voxels and save into event file
        runevent{k,16}=trial_ROI_beta;
    end
    
    event_compiled=[event_compiled;runevent];
end

headers={'onset','obj_freq','norm_fam','task','duration','resp','RT','feat_over','feat_over_bin','stim','epi_t','sem_t','trial_num','run_num','freq_overestimate','ROI_beta','sub'};
event_compiled=[headers;event_compiled];
writetable(event_compiled,strcat(output,'/test_lifetime-in-freq_event_compiled.csv'));
end