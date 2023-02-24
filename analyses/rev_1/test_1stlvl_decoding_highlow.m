%% 2023-02-13
%Using Princton MVPA toolbox to decode test phase decoding of high vs.
%low recent familiarity and lifetime familiarity (separately median split
%for each ss) *Using LSS-N (test_resp_1stlvl_LSSN_softAROMA.m) data in with
%individual PrC mask (sub_PRC_MNINLin6_resampled.nii) in the MNI space.
%Note that the functional data was smoothed by 6mm since it was the output
%of soft ICA-AROMA if this doesn't work I may need to consider rerun
%fmriprep without soft AROMA to get rid of smoothing and/or reestimate the
%GLM (with LSS-1 or GLMsingle) the old code "PrC_SVMs.m" was run on
%fmriprep output (not a full sample) without soft AROMA (thus no smoothing
%either) and it was based on LSS-1 in native space technically the old code
%was more "approprieate" for decoding since it has no smoothing and was run
%in individual space but since we merely want to corroborate the univariate
%analyses, it is good to have a common starting point (i.e. having common
%preprocessing steps as the univariate analyses)

%Here is a flow chart of steps done prior to this step:
%BIDS data ---> fmriprep 1.5.4 soft-ICA-AROMA ---> test-phase LSSN in MNI space

% This can do 5 binary classifications in test phase:
% recent high vs. low (with 3 as high)
% recent high vs. low (with 3 as low)
% lifetime high vs. low (with 3 as high)
% lifetime high vs. low (with 3 as low)
% recent vs. lifetime

% if it doesn't work try group PrC mask first, since the individual mask
% may have holes in it.

function test_1stlvl_decoding_highlow(project_derivative,GLM_dir,ASHS_dir,output,sub,c_type,bin_type,varargin)
%% set up dir and parameters
%subject specific PrC mask
sub_mask_file=[ASHS_dir,'/',sub,'/final/',sub,'_PRC_MNINLin6_resampled.nii'];

%number of trials per run
num_trial=45;
%number of test runs
num_run=4;

%dummy scan and TR
expstart_vol=5;
TR=2.5;

%princeton MVPA related
defaults.fextension = '.nii';

args = propval(varargin,defaults);

if (isfield(args,'fextension'))
    fextension=args.fextension;
else
    fextension=defaults.fextension;
end

% Check to make sure the Neuralnetwork toolbox is in the path or this
% won't work.
if ~exist('newff') %#ok<EXIST>
    error('This tutorial requires the neural networking toolbox, if it is unavailable this will not execute');
end

%%
% start by creating an empty subj structure
subj = init_subj('PrC-PPC',sub);

% create the mask that will be used when loading in the data
mask_name=[sub,'_PrC_MNI_mask'];
subj = load_spm_mask(subj,mask_name,sub_mask_file);%auto convert all nonzero values to 1

% now, read and set up the actual data. This step has been modified to load
% the single-trial betas resulted from LSS-N, and load in behavioural file
% for each run
LSS_beta_filenames=cell(0);
raw_rating_cat=[];
for i=1:num_run
    %load run-level behavioural file
    runevent{i}=load_event_test(project_derivative,sub,'task-test_',['run-0',num2str(i),'_'],expstart_vol,TR);
    % reshape and concatenate the raw behavioural ratings for data filtering
    raw_rating=[runevent{i}(:,4)';runevent{i}(:,6)'];
    raw_rating_cat=[raw_rating_cat,raw_rating];
    for j=1:num_trial %these include both recent and lifetime trials
        LSS_beta_filenames = [LSS_beta_filenames,[GLM_dir,'/LSS-N_test',sub,'/temp/task-test_run_',num2str(i),'/trial_',num2str(j),'/beta_0001.nii']]; %This is a bit hard-coded
    end
end

%% separate for different kinds of binary classification (rec h vs l, life h vs l, rec vs life)
switch c_type
    case 'rec'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         rec h vs l

% include only recent trials in both behaviour and LSS beta
recent_trials=strcmp(raw_rating_cat(1,:),'recent');

raw_rating_cat_rec=raw_rating_cat(:,recent_trials);
LSS_beta_filenames_rec=LSS_beta_filenames(:,recent_trials);

% create "regressors", split around rating 3 since it is more similar to our univariate results
% than using subject-specific medial rating
switch bin_type
    case 'high3'
        recbin_3_high=zeros(2,size(raw_rating_cat_rec,2));%3 as high
        
    case 'low3'
        recbin_3_low=zeros(2,size(raw_rating_cat_rec,2)); %3 as low
end
%keeping only the voxels active in the mask (see above)
subj = load_spm_pattern(subj,'LSS_rec_beta',mask_name,LSS_beta_filenames_rec);


% initialize the regressors object in the subj structure, load in the
% contents from a file, set the contents into the object and add a
% cell array of condnames to the object for future reference
% number of rows in the regressor correspond to the number of conditions,
% for me this should be 4 (i.e. high vs. low in recent and lifetime)

%initialization
subj = init_object(subj,'regressors','conds');
%build the regressor

%set the regressor
subj = set_mat(subj,'regressors','conds',regs);
condnames = {'rec_high','rec_low','life_high','life_low'};
subj = set_objfield(subj,'regressors','conds','condnames',condnames);





%It seems that the load_spm_pattern.m could be compatible with LSS output, try it
%out first

%uses subject specific PrC mask transformed to MNI space and resampled to
%functional resolution

    case 'life'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         life h vs l

    case 'task'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         rec vs life
end
end



