%% classify high (1,2,3,4) vs. low (6,7,8,9) presentations using SVM in the left PrC (individual ASHS mask in MNINLinAsym6)

%% 2021-07-26 I realized that the cross-classification won't work by design...
function study_1stlvl_SVM_bin(project_derivative,fmriprep_foldername,LSS_dir,ASHS_dir,output,sub)

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
%recode lifetime around subject mean
submean=mean(str2num(cell2mat(runevent(:,13))));%calculate mean
runevent(:,13)=num2cell(str2num(cell2mat(runevent(:,13))));%replace lifetime with num
[life_high,~]=find(cellfun(@(x) x>submean,runevent(:,13)));
[life_low,~]=find(cellfun(@(x) x<submean,runevent(:,13)));


%% sample trials to equalize high vs. low
 %to train on freq
 if length(freq_high)<=length(freq_low)
     freq_low_sample=datasample(freq_low,length(freq_high),'Replace',false);
     freq_high_sample=freq_high;
 else
     freq_high_sample=datasample(freq_high,length(freq_low),'Replace',false);
     freq_low_sample=freq_low;
 end
 %to train on lifetime
 if length(life_high)<=length(life_low)
     life_low_sample=datasample(life_low,length(life_high),'Replace',false);
     life_high_sample=life_high;
 else
     life_high_sample=datasample(life_high,length(life_low),'Replace',false);
     life_low_sample=life_low;
 end
 

% subject-specific left PrC mask in MNI
lPrC_mask=niftiread(strcat(project_derivative,'/',ASHS_dir,'/',sub,'/final/',sub,'_lPRC_MNINLin6_resampled.nii'));

%% cross-validated training and testing on freq

freq_high_data=cell(length(freq_high_sample),16);
freq_low_data=cell(length(freq_low_sample),16);
freq_high_feat=[];
freq_low_feat=[];
for i=1:length(freq_high_sample)
   freq_high_data(i,1:15)=runevent(freq_high_sample(i),:);
   beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(freq_high_data{i,14}),'/trial_',num2str(freq_high_data{i,15}),'/beta_0001.nii'));
   assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
   PrC_beta=beta_img(find(lPrC_mask));
   freq_high_data{i,16}=PrC_beta(~isnan(PrC_beta));%remove NaN which are probably voxels outside the brain
   freq_high_feat=[freq_high_feat;PrC_beta(~isnan(PrC_beta))'];
   
   freq_low_data(i,1:15)=runevent(freq_low_sample(i),:);
   beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(freq_low_data{i,14}),'/trial_',num2str(freq_low_data{i,15}),'/beta_0001.nii'));
   assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
   PrC_beta=beta_img(find(lPrC_mask));
   freq_low_data{i,16}=PrC_beta(~isnan(PrC_beta));
   freq_low_feat=[freq_low_feat;PrC_beta(~isnan(PrC_beta))'];
end

%actually I don't need all those variables above, just
%generate two arrays, one for lable, the other for betas
labels=cell(length(freq_high_sample)+length(freq_low_sample),1);
labels(1:length(freq_high_sample),1)={'high'};
labels(length(freq_high_sample)+1:end,1)={'low'};

features=[freq_high_feat;freq_low_feat];

freq_SVM=fitclinear(features,labels,'KFold',5);
freq_error=kfoldLoss(freq_SVM);

%% cross-validated training and testing on lifetime
life_high_data=cell(length(life_high_sample),16);
life_low_data=cell(length(life_low_sample),16);
life_high_feat=[];
life_low_feat=[];
for i=1:length(life_high_sample)
   life_high_data(i,1:15)=runevent(life_high_sample(i),:);
   beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(life_high_data{i,14}),'/trial_',num2str(life_high_data{i,15}),'/beta_0001.nii'));
   assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
   PrC_beta=beta_img(find(lPrC_mask));
   life_high_data{i,16}=PrC_beta(~isnan(PrC_beta));%remove NaN which are probably voxels outside the brain
   life_high_feat=[life_high_feat;PrC_beta(~isnan(PrC_beta))'];
   
   life_low_data(i,1:15)=runevent(life_low_sample(i),:);
   beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(life_low_data{i,14}),'/trial_',num2str(life_low_data{i,15}),'/beta_0001.nii'));
   assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
   PrC_beta=beta_img(find(lPrC_mask));
   life_low_data{i,16}=PrC_beta(~isnan(PrC_beta));
   life_low_feat=[life_low_feat;PrC_beta(~isnan(PrC_beta))'];
end

%actually I don't need all those variables above, just
%generate two arrays, one for lable, the other for betas
labels=cell(length(life_high_sample)+length(life_low_sample),1);
labels(1:length(life_high_sample),1)={'high'};
labels(length(life_high_sample)+1:end,1)={'low'};

features=[life_high_feat;life_low_feat];

life_SVM=fitclinear(features,labels,'KFold',5);
life_error=kfoldLoss(life_SVM);


%% save the output
if ~exist(strcat(output,'/',sub),'dir')
    mkdir (strcat(output,'/',sub));
end
save(strcat(output,'/',sub,'/SVM_results.mat'),'freq_SVM','freq_error','life_SVM','life_error');

end