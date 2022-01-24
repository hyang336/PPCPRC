%% mainly for interaction effect of frequency and (pscan)lifetime judgement during frequency judgement
%% based on LSS-N results

% Use LSS-N results during the frequency judgement to fit a regression
% model of task-irrelevant lifetime effect for each voxel for each subject:
% LSS-N betas ~ post-scan lifetime ratings + frequency effect + life*freq

function test_1stlvl_freqXlife_softAROMA(project_derivative, LSSN_foldername,sub,output,prc_mask)
%predefine some parameters
TR=2.5;
expstart_vol=5;
fmriprep_foldername='fmriprep_1.5.4_AROMA';
%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/test_1stlvl_freqXlife_con/',sub);
if ~exist(strcat(sub_dir),'dir')
    mkdir (sub_dir);
end

%load event file
runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
runfile=dir(runkey);
substr=struct();
substr.run=extractfield(runfile,'name');
[~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));
substr.postscan=raw;
runevent=cell(0);

for j=1:4 %loop through 4 runs
    task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
    run=regexp(substr.run{j},'run-\d\d_','match');
    substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);
    
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
    
    [o,l]=ismember(resp_event(:,10),substr.postscan(:,6));%find stimuli
    resp_event(:,11)=substr.postscan(l,11);%fill in post-scan ratings
    if ismember(sub,{'sub-020','sub-022'}) % these 2 subjects had negative correlation between their postscan ratings and normative data
        %use normative ratings
        %our stimuli (180 in total) has a
        %normative rating ranging from 1.75 to
        %8.95, the cutoffs were defined by
        %evenly dividing that range into 5
        %intervals
        lifetime_irr_1_row=find(cellfun(@(x)x<=3.19,resp_event(:,3)));
        resp_event(lifetime_irr_1_row,11)={'1'};
        
        lifetime_irr_2_row=find(cellfun(@(x)x>3.19&&x<=4.63,resp_event(:,3)));
        resp_event(lifetime_irr_2_row,11)={'2'};
        
        lifetime_irr_3_row=find(cellfun(@(x)x>4.63&&x<=6.07,resp_event(:,3)));
        resp_event(lifetime_irr_3_row,11)={'3'};
        
        lifetime_irr_4_row=find(cellfun(@(x)x>6.07&&x<=7.51,resp_event(:,3)));
        resp_event(lifetime_irr_4_row,11)={'4'};
        
        lifetime_irr_5_row=find(cellfun(@(x)x>7.51,resp_event(:,3)));
        resp_event(lifetime_irr_5_row,11)={'5'};
    end
    
    %concatenate into one cell
    runevent=[runevent;resp_event];
end

%% mass regression for PrC voxel with permutation
%load PrC group mask
prc=niftiread(prc_mask);
%extract betas corresponding to frequency trials

for i=1:size(runevent,1)
    %extract metadata, this should be the same other than some minor fields
    %like filenames for the same subject, but I haven't implement a check
    beta_info{i}=niftiinfo(strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-test_run_',num2str(runevent{i,14}),'/trial_',num2str(runevent{i,13}),'/beta_0001.nii'));
    %load beta file
    beta_temp=niftiread(strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-test_run_',num2str(runevent{i,14}),'/trial_',num2str(runevent{i,13}),'/beta_0001.nii'));
    %extract PrC beta
    beta_temp_prc=beta_temp;
    beta_temp_prc(~prc)=NaN;
    %save PrC beta
    beta_prc(:,:,:,i)=beta_temp_prc;
end

%extract PrC voxels that have data on every trial
[prc_x,prc_y,prc_z]=ind2sub(size(prc),find(prc));
exclude_nan=zeros(size(prc_x));
for v=1:length(prc_x)
    prc_NaN=any(isnan(beta_prc(prc_x(v),prc_y(v),prc_z(v),:)));%check if any trial of a given voxel has NaN
    if prc_NaN
        exclude_nan(v)=1;%mark voxels with NaN
    end
end
%remove NaN PrC voxels
nan_v=find(exclude_nan);
prc_x(nan_v)=[];
prc_y(nan_v)=[];
prc_z(nan_v)=[];

%run the regression model and save the slope of the interaction termn
lifetime_slopes=NaN(size(prc));
recent_slopes=NaN(size(prc));
inter_slopes=NaN(size(prc));
%z-score the IVs to account for potential range differences between the two
%types of familiarity judgement
recent_ratings=zscore(str2num(cell2mat(runevent(:,6))));
lifetime_ratings=zscore(str2num(cell2mat(runevent(:,11))));
%get interaction column
lifeXfreq=recent_ratings.*lifetime_ratings;
X=[ones(length(lifeXfreq),1),recent_ratings,lifetime_ratings,lifeXfreq];%also add intercept
for v=1:length(prc_x)
    dv=squeeze(beta_prc(prc_x(v),prc_y(v),prc_z(v),:));
    %z-score the IVs
    b=regress(dv,X);
    %save the slopes in array with the same shape of PrC.nii
    recent_slopes(prc_x(v),prc_y(v),prc_z(v))=b(2);
    lifetime_slopes(prc_x(v),prc_y(v),prc_z(v))=b(3);
    inter_slopes(prc_x(v),prc_y(v),prc_z(v))=b(4);
end

%write to files
info=beta_info{1};
info.Description = 'LSS regression slope';
niftiwrite(single(recent_slopes),strcat(sub_dir,'/recent_slopes_PrC.nii'),info);
niftiwrite(single(lifetime_slopes),strcat(sub_dir,'/lifetime_slopes_PrC.nii'),info);
niftiwrite(single(inter_slopes),strcat(sub_dir,'/inter_slopes_PrC.nii'),info);

% Preparing for permutation max-t procedure. We randomly permute both freq
% and lifetime labels for 100 times and recalculate the interaction term
% each time. On the 2nd lvl, we randomly choose one image for each subject
% and calculate the max t-value in PrC to construct a null distribution for
% us to test against (total 100^30 datapoints, but we may not need to
% sample all the points)
for iter=1:100
    recent_randmax=NaN(size(prc));%need to save random beta images
    lifetime_randmax=NaN(size(prc));
    inter_randmax=NaN(size(prc));
    
    %randomly permute recent and lifetime ratings
    recent_perm=recent_ratings(randperm(length(recent_ratings)));
    lifetime_perm=lifetime_ratings(randperm(length(lifetime_ratings)));
    %recalculate interaction term
    inter_perm=recent_perm.*lifetime_perm;
    %construct IVs
    X_perm=[ones(size(inter_perm)),recent_perm,lifetime_perm,inter_perm];
    %regression and save slopes
    for v=1:length(prc_x)
        dv=squeeze(beta_prc(prc_x(v),prc_y(v),prc_z(v),:));
        %z-score the IVs
        bp=regress(dv,X_perm);
        %save the slopes in array with the same shape of PrC.nii
        recent_randmax(prc_x(v),prc_y(v),prc_z(v))=bp(2);
        lifetime_randmax(prc_x(v),prc_y(v),prc_z(v))=bp(3);
        inter_randmax(prc_x(v),prc_y(v),prc_z(v))=bp(4);
    end
    %     %save the max slope
    %     [~,max_recent_i]=max(abs(bp(:,2)));%take absolute value before max for a two-tailed test (without a priori assumption of direction of signal change, so slope can be positive or negative)
    %     recent_randmax(:,iter)=[prc_x(max_recent_i);prc_y(max_recent_i);prc_z(max_recent_i);bp(max_recent_i,2)];%save the coordinates and results
    %
    %     [~,max_lifetime_i]=max(abs(bp(:,3)));
    %     lifetime_randmax(:,iter)=[prc_x(max_lifetime_i);prc_y(max_lifetime_i);prc_z(max_lifetime_i);bp(max_lifetime_i,3)];
    %
    %     [~,max_inter_i]=max(abs(bp(:,4)));
    %     inter_randmax(:,iter)=[prc_x(max_inter_i);prc_y(max_inter_i);prc_z(max_inter_i);bp(max_inter_i,4)];
    
    info=beta_info{1};
    info.Description = 'LSS regression slope random';
    niftiwrite(single(recent_randmax),strcat(sub_dir,'/recent_randslopes_PrC_',num2str(iter),'.nii'),info);
    niftiwrite(single(lifetime_randmax),strcat(sub_dir,'/lifetime_randslopes_PrC_',num2str(iter),'.nii'),info);
    niftiwrite(single(inter_randmax),strcat(sub_dir,'/inter_randslopes_PrC_',num2str(iter),'.nii'),info);
    
end

end