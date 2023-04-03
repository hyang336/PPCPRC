%% 2023-02-13
% IMPORTANT!! The datetime() function in MATLAB has been updated so some
% scripts that calls that function in the Princeton MVPA toolbox need to be
% manually changed, otherwise it will give and error

%Using Princton MVPA toolbox to do study phase decoding of high vs. low
%recent familiarity (1vs789) and lifetime familiarity (12vs345 & 123vs45).
%Using LSS-N (study_1stlvl_LSSN_softAROMA.m) data ("N" codes for objective
%presentations) with individual PrC mask (sub_PRC_MNINLin6_resampled.nii)
%in the MNI space. Note that the functional data was smoothed by 6mm since
%it was the output of soft ICA-AROMA

%Here is a flow chart of steps done prior to this step: BIDS data --->
%fmriprep 1.5.4 soft-ICA-AROMA ---> study-phase LSSN in MNI space

% This script can do 3 binary classifications in study phase: recent high
% vs. low (1 vs. avg(7,8,9)) lifetime high vs. low (with 3 as high)
% lifetime high vs. low (with 3 as low) for each subject, the code also
% subsample to match the trial counts between lifetime decoding and recent
% decoding

%doesn't seem to work since the the distribution of high vs. low frequency
%bins in the study phase are very uneven across runs, so cross-run
%cross-validation will fail
function study_1stlvl_decoding_highlow(project_derivative,GLM_dir,ASHS_dir,sub,c_type,bin_type,fs_type,varargin)
%% set up dir and parameters

output=[project_derivative,'/Rev_1_study-decoding'];

% make subject-specific output dir if not already exist
if ~exist(strcat(output,'/',sub),'dir')
    mkdir (output,sub);
end
sub_output=[output,'/',sub];

%subject specific PrC mask
sub_mask_file=[ASHS_dir,'/',sub,'/final/',sub,'_PRC_MNINLin6_resampled.nii'];

%postscan behaviour
[~,~,postscan]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));

%number of trials per run
num_trial=90;
%number of study runs
num_run=5;

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
    runevent{i}=load_event_test(project_derivative,sub,'task-study_',['run-0',num2str(i),'_'],expstart_vol,TR);
    %loop over study trials to find stim and fill in postscan ratings
    for s=1:size(runevent{i},1)
        postscan_rating=postscan{strcmp(postscan(:,6),runevent{i}{s,10}),11};
        runevent{i}{s,13}=postscan_rating;%add postscan ratings
    end
    % reshape and concatenate the raw behavioural ratings for data filtering
    rec_ratings=num2cell(mod(cell2mat(runevent{i}(:,2)),10));%2nd column obj. freq. mod 10
    life_ratings=cellfun(@str2num,runevent{i}(:,13),'UniformOutput',false);%13th column pscan life ratings

    raw_rating=[rec_ratings';life_ratings'];
    raw_rating_cat=[raw_rating_cat,raw_rating];%needs to be in cell to handle missing responses
    for j=1:num_trial %these include both recent and lifetime trials
        LSS_beta_filenames = [LSS_beta_filenames,cellstr(strcat(GLM_dir,'/study_1stlvl_LSS-pres_softAROMA_const-epoch_pmod/',sub,'/temp/task-study_run_',num2str(i),'/trial_',num2str(j),'/beta_0001.nii'))]; %This is a bit hard-coded
    end
end

% %convert ratings into numbers
% raw_rating_cat(2,:)=num2cell(str2double(raw_rating_cat(2,:)));
%set run indicator
runs=repelem([1:1:num_run],num_trial);


%% separate for different kinds of binary classification (rec h vs l, life h vs l, rec vs life)
switch c_type
    case 'rec'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         rec h vs l

        % include pres1, 7, 8, 9 trials in both behaviour and LSS beta
        recent_trials=ismember([raw_rating_cat{1,:}],[1,7,8,9]);

        raw_rating_cat_rec=raw_rating_cat(1,recent_trials);%ratings
        LSS_beta_filenames_rec=LSS_beta_filenames(:,recent_trials);%beta imgs
        rec_runs=runs(:,recent_trials);%run indicators

        % create "regressors", only 1 binarization scheme for recent since
        % it is 1 vs mean(789)

                recbin=zeros(2,size(raw_rating_cat_rec,2));
                
                %binarization, raw_rating_cat_rec should only have 1, 7, 8,
                %9 
                recbin(1,cell2mat(raw_rating_cat_rec)>=3)=1;%trials for high rec 
                recbin(2,cell2mat(raw_rating_cat_rec)<3)=1;%trials for low rec 

                %populate subj structure at the inner-most level of the
                %script
                % regressor (classes)
                subj = init_object(subj,'regressors','rec');
                subj = set_mat(subj,'regressors','rec',recbin);
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

                % Compare for selecting both directions (ANOVA) vs.
                % single direction (inc or dec with t-test), the MVPA
                % toolbox uses str2fun() to call its customized ANOVA
                % function (statmap_anova.m), I made a statmap_ttest.m to
                % do one-tail selection
%                 switch fs_type
%                     case 'xgy' %x greater than y, where x and y are the first and second conditions
%                         arg_struct.tail='right';
%                         [subj] = feature_select(subj,'LSS_rec_beta_z','rec','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
%                     case 'xsy' %x smaller than y
                        arg_struct.tail='left';
                        [subj] = feature_select(subj,'LSS_rec_beta_z','rec','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
%                     case 'anova' %two-tail selection using anova
%                         % run the anova multiple times, separately for each iteration,
%                         % using the selector indices created above
%                         [subj] = feature_select(subj,'LSS_rec_beta_z','rec','runs_xval');
% 
%                 end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CLASSIFICATION - n-minus-one cross-validation

                % set some basic arguments for a backprop classifier
                class_args.train_funct_name = 'train_bp';
                class_args.test_funct_name = 'test_bp';
                class_args.nHidden = 0;

                % now, run the classification multiple times, training and testing
                % on different subsets of the data on each iteration
                [subj results] = cross_validation(subj,'LSS_rec_beta_z','rec','runs_xval','LSS_rec_beta_z_thresh0.05',class_args);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%code below is not finished%%%%%%%%%%%%%












    case 'life'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         life h vs l
        % include only recent trials in both behaviour and LSS beta
        life_trials=strcmp(raw_rating_cat(1,:),'lifetime');
        
        %handle no responses

        raw_rating_cat_life=raw_rating_cat(:,life_trials);%ratings
        LSS_beta_filenames_life=LSS_beta_filenames(:,life_trials);%beta imgs
        life_runs=runs(:,life_trials);%run indicators

        % create "regressors", split around rating 3 since it is more similar to our univariate results
        % than using subject-specific medial rating
        switch bin_type
            case 'high3'
                lifebin_3_high=zeros(2,size(raw_rating_cat_life,2));%3 as high

                lifebin_3_high(1,cell2mat(raw_rating_cat_life(2,:))>=3)=1;%trials for high life judgement
                lifebin_3_high(2,cell2mat(raw_rating_cat_life(2,:))<3)=1;%trials for low life judgement

                %populate subj structure at the inner-most level of the
                %script
                % regressor (classes)
                subj = init_object(subj,'regressors','life');
                subj = set_mat(subj,'regressors','life',lifebin_3_high);
                condnames = {'life_high','life_low'};%order matters
                subj = set_objfield(subj,'regressors','life','condnames',condnames);
                % run selector
                subj = init_object(subj,'selector','runs');
                subj = set_mat(subj,'selector','runs',life_runs);

                %keeping only the voxels active in the mask (see above)
                subj = load_spm_pattern(subj,'LSS_life_beta',mask_name,LSS_beta_filenames_life);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % PRE-PROCESSING - z-scoring in time and no-peeking anova

                % z-score the LSS beta (called 'LSS_life_beta'),
                % individually on each run (using the 'runs' selectors)
                subj = zscore_runs(subj,'LSS_life_beta','runs');

                % now, create selector indices for the n different iterations of
                % the nminusone
                subj = create_xvalid_indices(subj,'runs');

                % Compare for selecting both directions (ANOVA) vs.
                % single direction (inc or dec with t-test), the MVPA
                % toolbox uses str2fun() to call its customized ANOVA
                % function (statmap_anova.m), I made a statmap_ttest.m to
                % do one-tail selection
                switch fs_type
                    case 'xgy' %x greater than y, where x and y are the first and second conditions
                        arg_struct.tail='right';
                        [subj] = feature_select(subj,'LSS_life_beta_z','life','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
                    case 'xsy' %x smaller than y
                        arg_struct.tail='left';
                        [subj] = feature_select(subj,'LSS_life_beta_z','life','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
                    case 'anova' %two-tail selection using anova
                        % run the anova multiple times, separately for each iteration,
                        % using the selector indices created above
                        [subj] = feature_select(subj,'LSS_life_beta_z','life','runs_xval');

                end


                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CLASSIFICATION - n-minus-one cross-validation

                % set some basic arguments for a backprop classifier
                class_args.train_funct_name = 'train_bp';
                class_args.test_funct_name = 'test_bp';
                class_args.nHidden = 0;

                % now, run the classification multiple times, training and testing
                % on different subsets of the data on each iteration
                [subj results] = cross_validation(subj,'LSS_life_beta_z','life','runs_xval','LSS_life_beta_z_thresh0.05',class_args);

            case 'low3'
                lifebin_3_low=zeros(2,size(raw_rating_cat_life,2)); %3 as low
                lifebin_3_low(1,cell2mat(raw_rating_cat_life(2,:))>3)=1;%trials for high life judgement
                lifebin_3_low(2,cell2mat(raw_rating_cat_life(2,:))<=3)=1;%trials for low life judgement

                %populate subj structure at the inner-most level of the
                %script
                % regressor (classes)
                subj = init_object(subj,'regressors','life');
                subj = set_mat(subj,'regressors','life',lifebin_3_low);
                condnames = {'life_high','life_low'};%order matters
                subj = set_objfield(subj,'regressors','life','condnames',condnames);
                % run selector
                subj = init_object(subj,'selector','runs');
                subj = set_mat(subj,'selector','runs',life_runs);

                %keeping only the voxels active in the mask (see above)
                subj = load_spm_pattern(subj,'LSS_life_beta',mask_name,LSS_beta_filenames_life);

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % PRE-PROCESSING - z-scoring in time and no-peeking anova

                % z-score the LSS beta (called 'LSS_life_beta'),
                % individually on each run (using the 'runs' selectors)
                subj = zscore_runs(subj,'LSS_life_beta','runs');

                % now, create selector indices for the n different iterations of
                % the nminusone
                subj = create_xvalid_indices(subj,'runs');
                % Compare for selecting both directions (ANOVA) vs.
                % single direction (inc or dec with t-test), the MVPA
                % toolbox uses str2fun() to call its customized ANOVA
                % function (statmap_anova.m), I made a statmap_ttest.m to
                % do one-tail selection
                switch fs_type
                    case 'xgy' %x greater than y, where x and y are the first and second conditions
                        arg_struct.tail='right';
                        [subj] = feature_select(subj,'LSS_life_beta_z','life','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
                    case 'xsy' %x smaller than y
                        arg_struct.tail='left';
                        [subj] = feature_select(subj,'LSS_life_beta_z','life','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
                    case 'anova' %two-tail selection using anova
                        % run the anova multiple times, separately for each iteration,
                        % using the selector indices created above
                        [subj] = feature_select(subj,'LSS_life_beta_z','life','runs_xval');

                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % CLASSIFICATION - n-minus-one cross-validation

                % set some basic arguments for a backprop classifier
                class_args.train_funct_name = 'train_bp';
                class_args.test_funct_name = 'test_bp';
                class_args.nHidden = 0;

                % now, run the classification multiple times, training and testing
                % on different subsets of the data on each iteration
                [subj results] = cross_validation(subj,'LSS_life_beta_z','life','runs_xval','LSS_life_beta_z_thresh0.05',class_args);


        end


    case 'task'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%         rec vs life
        % include all trials in both behaviour and LSS beta

        %hard code bin_type for task decoding
        bin_type='na';

        taskbin=zeros(2,size(raw_rating_cat,2)); % init dummy coding
        taskbin(1,strcmp(raw_rating_cat(1,:),'recent'))=1;%recent trials on row 1
        taskbin(2,strcmp(raw_rating_cat(1,:),'lifetime'))=1;%lifetime trials on row 2

        %populate subj structure at the inner-most level of the
        %script
        % regressor (classes)
        subj = init_object(subj,'regressors','task');
        subj = set_mat(subj,'regressors','task',taskbin);
        condnames = {'recent','lifetime'};%order matters
        subj = set_objfield(subj,'regressors','task','condnames',condnames);
        % run selector
        subj = init_object(subj,'selector','runs');
        subj = set_mat(subj,'selector','runs',runs);

        %keeping only the voxels active in the mask (see above)
        subj = load_spm_pattern(subj,'LSS_beta',mask_name,LSS_beta_filenames);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % PRE-PROCESSING - z-scoring in time and no-peeking anova

        % z-score the LSS beta (called 'LSS_life_beta'),
        % individually on each run (using the 'runs' selectors)
        subj = zscore_runs(subj,'LSS_beta','runs');

        % now, create selector indices for the n different iterations of
        % the nminusone
        subj = create_xvalid_indices(subj,'runs');
        % Compare for selecting both directions (ANOVA) vs.
        % single direction (inc or dec with t-test), the MVPA
        % toolbox uses str2fun() to call its customized ANOVA
        % function (statmap_anova.m), I made a statmap_ttest.m to
        % do one-tail selection
        switch fs_type
            case 'xgy' %x greater than y, where x and y are the first and second conditions
                arg_struct.tail='right';
                [subj] = feature_select(subj,'LSS_beta_z','task','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
            case 'xsy' %x smaller than y
                arg_struct.tail='left';
                [subj] = feature_select(subj,'LSS_beta_z','task','runs_xval','statmap_funct','statmap_ttest','statmap_arg',arg_struct);
            case 'anova' %two-tail selection using anova
                % run the anova multiple times, separately for each iteration,
                % using the selector indices created above
                [subj] = feature_select(subj,'LSS_beta_z','task','runs_xval');

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % CLASSIFICATION - n-minus-one cross-validation

        % set some basic arguments for a backprop classifier
        class_args.train_funct_name = 'train_bp';
        class_args.test_funct_name = 'test_bp';
        class_args.nHidden = 0;

        % now, run the classification multiple times, training and testing
        % on different subsets of the data on each iteration
        [subj results] = cross_validation(subj,'LSS_beta_z','task','runs_xval','LSS_beta_z_thresh0.05',class_args);

end

% save cross-validated results
filename=[c_type,'_',bin_type,'_',fs_type,'.mat']
save([sub_output,'/',filename],"results","subj");
end



