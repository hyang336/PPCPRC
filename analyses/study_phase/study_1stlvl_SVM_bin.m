%% classify high (1,2,3,4) vs. low (6,7,8,9) presentations using SVM in the left PrC (individual ASHS mask in MNINLinAsym6)
function study_1stlvl_SVM_bin(project_derivative,fmriprep_foldername,GLM_dir,ASHS_dir,output,sub)

%some parameters to load event files
TR=2.5;
expstart_vol=5;

%% load event files and recode high vs. low freq and lifetime
runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*study*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
runfile=dir(runkey);
substr=struct();
substr.run=extractfield(runfile,'name');
[~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));
substr.postscan=raw;
runevent=cell(0);
for j=1:5 %loop through 5 runs
    task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
    run=regexp(substr.run{j},'run-\d\d_','match');
    substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);
    substr.runevent{j}(:,14)={j};%run number
    for s=1:size(substr.runevent{j},1)
        postscan_rating=substr.postscan{strcmp(substr.postscan(:,6),substr.runevent{j}{s,10}),11};
        substr.runevent{j}{s,13}=postscan_rating;%replace with postscan ratings
        substr.runevent{j}{s,15}=s;%trial number
    end
    %concatenate across runs
    runevent=[runevent;substr.runevent{j}];
end
%recode freq
[freq_high,~]=find(cellfun(@(x) mod(x,10),runevent(:,2))==6|cellfun(@(x) mod(x,10),runevent(:,2))==7|cellfun(@(x) mod(x,10),runevent(:,2))==8|cellfun(@(x) mod(x,10),runevent(:,2))==9);
[freq_low,~]=find(cellfun(@(x) mod(x,10),runevent(:,2))==1|cellfun(@(x) mod(x,10),runevent(:,2))==2|cellfun(@(x) mod(x,10),runevent(:,2))==3|cellfun(@(x) mod(x,10),runevent(:,2))==4);
%recode lifetime

%% load betas in the left PrC to form the training and testing data

%% sample trials to equalize high vs. low

%% cross-validated training and testing on freq

%% cross classify high vs. low lifetime

%% cross-validated training and testing on lifetime

%% cross classify high vs. low freq
end