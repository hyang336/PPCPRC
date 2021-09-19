%% classify high (1,2,3,4) vs. low (6,7,8,9) presentations using SVM in the left PrC (individual ASHS mask in MNINLinAsym6)

%% 2021-07-26 I realized that the cross-classification won't work by design...
function study_1stlvl_SVM_bin(project_derivative,fmriprep_foldername,LSS_dir,ASHS_dir,output,sub)

%some parameters to load event files
TR=2.5;
expstart_vol=5;
cvfold=5;%cross-validation fold

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
% %recode lifetime around subject mean
submean=nanmean(str2double(runevent(:,13)));%calculate mean
runevent(:,13)=num2cell(str2double(runevent(:,13)));%replace lifetime with num
[life_high,~]=find(cellfun(@(x) x>submean,runevent(:,13)));
[life_low,~]=find(cellfun(@(x) x<=submean,runevent(:,13)));

%% sample trials to equalize high vs. low 10 times to guarantee every trial is at least included once following (Martin et al. 2013, 2016)
% 1. First sample the larger class (a) n times without replacement until we have
% less trials (x) than the smaller class (b), then sample
% b-a from a-b, which guarantees that all trials are
% included at least once. Then we just randomly sample
% without replacement from a until we have at least 10 samples.

%to train on freq
if length(freq_high)<=length(freq_low)
    mult=floor(length(freq_low)/length(freq_high));%ratio of sample size between the two classes, round down
    randind=randperm(length(freq_low)); %permute order in the larger class
    ind=[];%sampled indices of the larger class
    for j=1:mult %generate the max amount of nonoverlapping samples from the larger class with the size of the smaller class
        sample=randind((j*length(freq_high))-length(freq_high)+1:(j*length(freq_high)));
        freq_low_sample{j}=freq_low(sample);
        ind=[ind,sample];
    end
    %include the remaining trials from the larger class, after this
    %all trials are included in at least one of the samples
    freq_low_sample{j+1}=[datasample(freq_low(ind),length(freq_high)-(length(freq_low)-length(ind)),'Replace',false);freq_low(setdiff(1:length(freq_low),ind))];
    if mult<10 %if the larger class is not 10 times bigger than the small class
        for k=length(freq_low_sample)+1:10%generate the remaining samples, don't care about overlap
            freq_low_sample{k}=datasample(freq_low,length(freq_high),'Replace',false);
        end
    end
    %the entirety of the smaller class is the sample
    freq_high_sample{1}=freq_high;
else
    mult=floor(length(freq_high)/length(freq_low));
    randind=randperm(length(freq_high)); %permute order in the larger class
    ind=[];%sampled indices of the larger class
    for j=1:mult %generate the max amount of nonoverlapping samples from the larger class with the size of the smaller class
        sample=randind((j*length(freq_low))-length(freq_low)+1:(j*length(freq_low)));
        freq_high_sample{j}=freq_high(sample);
        ind=[ind,sample];
    end
    %include the remaining trials from the larger class, after this
    %all trials are included in at least one of the samples
    freq_high_sample{j+1}=[datasample(freq_high(ind),length(freq_low)-(length(freq_high)-length(ind)),'Replace',false);freq_high(setdiff(1:length(freq_high),ind))];
    if mult<10 %if the larger class is not 10 times bigger than the small class
        for k=length(freq_high_sample)+1:10%generate the remaining samples, don't care about overlap
            freq_high_sample{k}=datasample(freq_high,length(freq_low),'Replace',false);
        end
    end
    %the entirety of the smaller class is the sample
    freq_low_sample{1}=freq_low;
end

%to train on lifetime
if length(life_high)<=length(life_low)
    mult=floor(length(life_low)/length(life_high));%ratio of sample size between the two classes, round down
    randind=randperm(length(life_low)); %permute order in the larger class
    ind=[];%sampled indices of the larger class
    for j=1:mult %generate the max amount of nonoverlapping samples from the larger class with the size of the smaller class
        sample=randind((j*length(life_high))-length(life_high)+1:(j*length(life_high)));
        life_low_sample{j}=life_low(sample);
        ind=[ind,sample];
    end
    %include the remaining trials from the larger class, after this
    %all trials are included in at least one of the samples
    life_low_sample{j+1}=[datasample(life_low(ind),length(life_high)-(length(life_low)-length(ind)),'Replace',false);life_low(setdiff(1:length(life_low),ind))];
    if mult<10 %if the larger class is not 10 times bigger than the small class
        for k=length(life_low_sample)+1:10%generate the remaining samples, don't care about overlap
            life_low_sample{k}=datasample(life_low,length(life_high),'Replace',false);
        end
    end
    %the entirety of the smaller class is the sample
    life_high_sample{1}=life_high;
else
    mult=floor(length(life_high)/length(life_low));
    randind=randperm(length(life_high)); %permute order in the larger class
    ind=[];%sampled indices of the larger class
    for j=1:mult %generate the max amount of nonoverlapping samples from the larger class with the size of the smaller class
        sample=randind((j*length(life_low))-length(life_low)+1:(j*length(life_low)));
        life_high_sample{j}=life_high(sample);
        ind=[ind,sample];
    end
    %include the remaining trials from the larger class, after this
    %all trials are included in at least one of the samples
    life_high_sample{j+1}=[datasample(life_high(ind),length(life_low)-(length(life_high)-length(ind)),'Replace',false);life_high(setdiff(1:length(life_high),ind))];
    if mult<10 %if the larger class is not 10 times bigger than the small class
        for k=length(life_high_sample)+1:10%generate the remaining samples, don't care about overlap
            life_high_sample{k}=datasample(life_high,length(life_low),'Replace',false);
        end
    end
    %the entirety of the smaller class is the sample
    life_low_sample{1}=life_low;
end


%% subject-specific left PrC mask in MNI
lPrC_mask=niftiread(strcat(project_derivative,'/',ASHS_dir,'/',sub,'/final/',sub,'_lPRC_MNINLin6_resampled.nii'));

%% training and testing loop for freq
for m=1:max(length(freq_high_sample),length(freq_low_sample))
    %select trials for each sample
    if length(freq_high_sample)>length(freq_low_sample)
        freq_low_trials=freq_low_sample{1};
        freq_high_trials=freq_high_sample{m};
    else
        freq_low_trials=freq_low_sample{m};
        freq_high_trials=freq_high_sample{1};
    end
    % features and labels
    classes=cell(length(freq_high_trials)+length(freq_low_trials),1);
    classes(1:length(freq_high_trials),1)={'high'};
    classes(length(freq_high_trials)+1:end,1)={'low'};
    
    %assert that the two classes have the same number of trials otherwise
    %the for-loop below needs to be more complex
    assert(length(freq_high_trials)==length(freq_low_trials));
    freq_high_PrC=[];
	freq_low_PrC=[];
    for o=1:length(freq_high_trials)
        freq_high_data(o,1:15)=runevent(freq_high_trials(o),:);
        beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(freq_high_data{o,14}),'/trial_',num2str(freq_high_data{o,15}),'/beta_0001.nii'));
        assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
        PrC_beta=beta_img(find(lPrC_mask));
        freq_high_PrC=[freq_high_PrC;PrC_beta'];
        
        freq_low_data(o,1:15)=runevent(freq_low_trials(o),:);
        beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(freq_low_data{o,14}),'/trial_',num2str(freq_low_data{o,15}),'/beta_0001.nii'));
        assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
        PrC_beta=beta_img(find(lPrC_mask));
        freq_low_PrC=[freq_low_PrC;PrC_beta'];
    end
    
    % concatenate lPrC betas for the two classes for this sample
    lPrC_betas=[freq_high_PrC;freq_low_PrC];
    
    % Divide data into n=5 bins for cross-validation   
    cv_split=cvpartition(length(classes),'KFold',cvfold);
    
    % cross validation loop for freq
    for n = 1:cvfold %using 5-fold cross-validation       
        % Feature/voxel selection using ANOVA then rank ordering F-values
        test_trials=cv_split.test(n);
        X=lPrC_betas(~test_trials,:);%training data
        Y=classes(~test_trials);%training label
        for voxel=1:size(X,2)%run one-way ANOVA for each voxel
            [~,tbl,~] = anova1(X(:,voxel),Y,'off');
            %checks for the ANOVA table size
            assert(size(tbl,1)==4);
            assert(size(tbl,2)==6);
            Fval(voxel)=tbl{2,5};%hard-coded for now since the ANOVA table is a cell array and should have consistent structure
        end
        % Find voxels with the top 10% of F-value, this should also get rid of
        % all NaNs in the data since voxels outside the brain is very
        % unlikely to have the largest F-values
        [~,topvoxels]=maxk(Fval,ceil(length(Fval)*0.1));
        %save the top voxel indices in a tensor for later calculation of overlap
        freq_voxels(m,:,n)=topvoxels;
        
        % Train
        model=fitcsvm(X(:,topvoxels),Y);
        % Test
        predictions=predict(model,lPrC_betas(test_trials,topvoxels));
        % Compile results
        freq_accuracy(m,n)=sum(strcmp(classes(test_trials),predictions))/length(predictions);
    end    
end


%% training and testing loop for life
for m=1:max(length(life_high_sample),length(life_low_sample))
    %select trials for each sample
    if length(life_high_sample)>length(life_low_sample)
        life_low_trials=life_low_sample{1};
        life_high_trials=life_high_sample{m};
    else
        life_low_trials=life_low_sample{m};
        life_high_trials=life_high_sample{1};
    end
    % features and labels
    classes=cell(length(life_high_trials)+length(life_low_trials),1);
    classes(1:length(life_high_trials),1)={'high'};
    classes(length(life_high_trials)+1:end,1)={'low'};
    
    %assert that the two classes have the same number of trials otherwise
    %the for-loop below needs to be more complex
    assert(length(life_high_trials)==length(life_low_trials));
    life_high_PrC=[];
	life_low_PrC=[];
    for o=1:length(life_high_trials)
        life_high_data(o,1:15)=runevent(life_high_trials(o),:);
        beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(life_high_data{o,14}),'/trial_',num2str(life_high_data{o,15}),'/beta_0001.nii'));
        assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
        PrC_beta=beta_img(find(lPrC_mask));
        life_high_PrC=[life_high_PrC;PrC_beta'];
        
        life_low_data(o,1:15)=runevent(life_low_trials(o),:);
        beta_img=niftiread(strcat(project_derivative,'/',LSS_dir,'/',sub,'/temp/task-study_run_',num2str(life_low_data{o,14}),'/trial_',num2str(life_low_data{o,15}),'/beta_0001.nii'));
        assert(all(size(beta_img)==size(lPrC_mask)));%make sure the beta image and the mask is in the same space
        PrC_beta=beta_img(find(lPrC_mask));
        life_low_PrC=[life_low_PrC;PrC_beta'];
    end
    
    % concatenate lPrC betas for the two classes for this sample
    lPrC_betas=[life_high_PrC;life_low_PrC];
    
    % Divide data into n=5 bins for cross-validation   
    cv_split=cvpartition(length(classes),'KFold',cvfold);
    
    % cross validation loop for life
    for n = 1:cvfold %using 5-fold cross-validation       
        % Feature/voxel selection using ANOVA then rank ordering F-values
        test_trials=cv_split.test(n);
        X=lPrC_betas(~test_trials,:);%training data
        Y=classes(~test_trials);%training label
        for voxel=1:size(X,2)%run one-way ANOVA for each voxel
            [~,tbl,~] = anova1(X(:,voxel),Y,'off');
            %checks for the ANOVA table size
            assert(size(tbl,1)==4);
            assert(size(tbl,2)==6);
            Fval(voxel)=tbl{2,5};%hard-coded for now since the ANOVA table is a cell array and should have consistent structure
        end
        % Find voxels with the top 10% of F-value, this should also get rid of
        % all NaNs in the data since voxels outside the brain is very
        % unlikely to have the largest F-values
        [~,topvoxels]=maxk(Fval,ceil(length(Fval)*0.1));
        %save the top voxel indices in a tensor for later calculation of overlap
        life_voxels(m,:,n)=topvoxels;
        
        % Train
        life_model=fitcsvm(X(:,topvoxels),Y);
        % Test
        predictions=predict(life_model,lPrC_betas(test_trials,topvoxels));
        % Compile results
        life_accuracy(m,n)=sum(strcmp(classes(test_trials),predictions))/length(predictions);
    end    
end


%% save the output
if ~exist(strcat(output,'/',sub),'dir')
    mkdir (strcat(output,'/',sub));
end
save(strcat(output,'/',sub,'/SVM_results.mat'),'freq_voxels','freq_accuracy','life_voxels','life_accuracy');

end