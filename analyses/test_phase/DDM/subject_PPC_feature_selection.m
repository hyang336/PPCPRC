%% select voxels that are most strongly activated by the frequency task for each subject in the PPC, using testphase-LSSN output
%% also recode accuracy and output a spreadsheet for HDDM
function subject_PPC_feature_selection(sub,PPC_mask,LSSN_dir,output)
%some hard-coded parameters to load event files
TR=2.5;
expstart_vol=5;
project_derivative='C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC_data';
fmriprep_foldername='fmriprep_1.5.4_AROMA';

%load event files and code run/trial numbers
runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
runfile=dir(runkey);
substr=struct();
substr.run=extractfield(runfile,'name');
runevent=cell(0);
for j=1:4 %loop through 4 runs
    task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
    run=regexp(substr.run{j},'run-\d\d_','match');
    substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);
    substr.runevent{j}(:,14)={j};%run number
    for s=1:size(substr.runevent{j},1)
        substr.runevent{j}{s,15}=s;%trial number
    end
    %concatenate across runs
    runevent=[runevent;substr.runevent{j}];
end

%extract frequency trials
freq_trials=runevent(strcmp(runevent(:,4),'recent'),:);
%recode accuracy and put it on column 13
objfreq=cell2mat(freq_trials(:,2));
ratings=str2num(cell2mat(freq_trials(:,6)));%probably need to handle missing resp in some subjects...

for k=1:size(freq_trials,1)
    if strcmp(freq_trials{i,6},'5')&&(freq_trials{i,2}==9||freq_trials{i,2}==7)%the 2nd column is objective presentation frequency
        
end
%load beta images

%feature selection using linear regression of BOLD~freq_ratings, then rank
%ordering the slope

end