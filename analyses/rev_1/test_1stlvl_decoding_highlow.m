%% 2023-02-13
% IMPORTANT!! The datetime() function in MATLAB has been updated so some
% scripts that calls that function in the Princeton MVPA toolbox need to be
% manually changed, otherwise it will give and error

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

%It seems that the load_spm_pattern.m could be compatible with LSS output, try it
%out first

% This script can do 5 binary classifications in test phase:
% recent high vs. low (with 3 as high)
% recent high vs. low (with 3 as low)
% lifetime high vs. low (with 3 as high)
% lifetime high vs. low (with 3 as low)
% recent vs. lifetime

% if it doesn't work try group PrC mask first, since the individual mask
% may have holes in it.

function test_1stlvl_decoding_highlow(project_derivative,GLM_dir,ASHS_dir,sub,c_type,bin_type,varargin)
%% set up dir and parameters

output=[project_derivative,'/Rev_1_test-decoding'];

% make subject-specific output dir if not already exist
if ~exist(strcat(output,'/',sub),'dir')
    mkdir (output,sub);
end
sub_output=[output,'/',sub];

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
    error('This script requires the neural networking toolbox, if it is unavailable this will not execute');
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
        LSS_beta_filenames = [LSS_beta_filenames,[GLM_dir,'/LSS-N_test/',sub,'/temp/task-test_run_',num2str(i),'/trial_',num2str(j),'/beta_0001.nii']]; %This is a bit hard-coded
    end
end

%convert ratings into numbers
raw_rating_cat(2,:)=num2cell(str2double(raw_rating_cat(2,:)));
%set run indicator
runs=repelem([1:1:num_run],num_trial);


%% separate for different kinds of binary classification (rec h vs l, life h vs l, rec vs life)
switch c_type
    case 'rec'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         rec h vs l

        %make rec classification output folder
        if ~exist(strcat(sub_output,'/rec'),'dir')
            mkdir (sub_output,'rec');
        end
        rec_output=[sub_output,'/rec/'];

        % include only recent trials in both behaviour and LSS beta
        recent_trials=strcmp(raw_rating_cat(1,:),'recent');

        raw_rating_cat_rec=raw_rating_cat(:,recent_trials);%ratings
        LSS_beta_filenames_rec=LSS_beta_filenames(:,recent_trials);%beta imgs
        rec_runs=runs(:,recent_trials);%run indicators

        % create "regressors", split around rating 3 since it is more similar to our univariate results
        % than using subject-specific medial rating
        switch bin_type
            case 'high3'
                recbin_3_high=zeros(2,size(raw_rating_cat_rec,2));%3 as high

                recbin_3_high(1,cell2mat(raw_rating_cat_rec(2,:))>=3)=1;%trials for high rec judgement
                recbin_3_high(2,cell2mat(raw_rating_cat_rec(2,:))<3)=1;%trials for low rec judgement

                %populate subj structure at the inner-most level of the
                %script
                % regressor (classes)
                subj = init_object(subj,'regressors','rec');
                subj = set_mat(subj,'regressors','rec',recbin_3_high);
                condnames = {'rec_high','rec_low'};%order matters
                subj = set_objfield(subj,'regressors','rec','condnames',condnames);
                % run selector
                subj = init_object(subj,'selector','runs');
                subj = set_mat(subj,'selector','runs',rec_runs);

                %keeping only the voxels active in the mask (see above)
                subj = load_spm_pattern(subj,'LSS_rec_beta',mask_name,LSS_beta_filenames_rec);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % PRE-PROCESSING - z-scoring in time and no-peeking anova

                % z-score the LSS beta (called 'LSS_rec_beta'),
                % individually on each run (using the 'runs' selectors)
                subj = zscore_runs(subj,'LSS_rec_beta','runs');

                % now, create selector indices for the n different iterations of
                % the nminusone
                subj = create_xvalid_indices(subj,'runs');

                % TODO: compare for selecting both directions (ANOVA) vs.
                % single direction (inc or dec with t-test)

                    % run the anova multiple times, separately for each iteration,
                    % using the selector indices created above
                    [subj] = feature_select(subj,'LSS_rec_beta_z','rec','runs_xval');


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CLASSIFICATION - n-minus-one cross-validation

                % set some basic arguments for a backprop classifier
                class_args.train_funct_name = 'train_bp';
                class_args.test_funct_name = 'test_bp';
                class_args.nHidden = 0;

                % now, run the classification multiple times, training and testing
                % on different subsets of the data on each iteration
                [subj results] = cross_validation(subj,'LSS_rec_beta_z','rec','runs_xval','LSS_rec_beta_z_thresh0.05',class_args);
            
                % save cross-validated results
                save([rec_output,'rec_high3.mat'],"results");
                
            case 'low3'
                recbin_3_low=zeros(2,size(raw_rating_cat_rec,2)); %3 as low
                recbin_3_low(1,cell2mat(raw_rating_cat_rec(2,:))>3)=1;%trials for high rec judgement
                recbin_3_low(2,cell2mat(raw_rating_cat_rec(2,:))<=3)=1;%trials for low rec judgement

                %populate subj structure at the inner-most level of the
                %script
                % regressor (classes)
                subj = init_object(subj,'regressors','rec');
                subj = set_mat(subj,'regressors','rec',recbin_3_low);
                condnames = {'rec_high','rec_low'};%order matters
                subj = set_objfield(subj,'regressors','rec','condnames',condnames);
                % run selector
                subj = init_object(subj,'selector','runs');
                subj = set_mat(subj,'selector','runs',rec_runs);

                %keeping only the voxels active in the mask (see above)
                subj = load_spm_pattern(subj,'LSS_rec_beta',mask_name,LSS_beta_filenames_rec);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % PRE-PROCESSING - z-scoring in time and no-peeking anova

                % z-score the LSS beta (called 'LSS_rec_beta'),
                % individually on each run (using the 'runs' selectors)
                subj = zscore_runs(subj,'LSS_rec_beta','runs');

                % now, create selector indices for the n different iterations of
                % the nminusone
                subj = create_xvalid_indices(subj,'runs');
                % TODO: compare for selecting both directions (ANOVA) vs.
                % single direction (inc or dec with t-test)

                    % run the anova multiple times, separately for each iteration,
                    % using the selector indices created above
                    [subj] = feature_select(subj,'LSS_rec_beta_z','rec','runs_xval');


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CLASSIFICATION - n-minus-one cross-validation

                % set some basic arguments for a backprop classifier
                class_args.train_funct_name = 'train_bp';
                class_args.test_funct_name = 'test_bp';
                class_args.nHidden = 0;

                % now, run the classification multiple times, training and testing
                % on different subsets of the data on each iteration
                [subj results] = cross_validation(subj,'LSS_rec_beta_z','rec','runs_xval','LSS_rec_beta_z_thresh0.05',class_args);
        
                % save cross-validated results
                save([rec_output,'rec_low3.mat'],"results");
        end



    case 'life'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         life h vs l

        %make rlife classification output folder
        if ~exist(strcat(sub_output,'/life'),'dir')
            mkdir (sub_output,life);
        end

    case 'task'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         rec vs life

        %make task classification output folder
        if ~exist(strcat(sub_output,'/task'),'dir')
            mkdir (sub_output,task);
        end
end
end



