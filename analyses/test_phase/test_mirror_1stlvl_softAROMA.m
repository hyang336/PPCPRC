%% test for mirror effect during frequency judgement

% Use LSS-N results during the frequency judgement to fit a regression
% model of task-irrelevant lifetime effect for each voxel for each subject:
% LSS-N betas ~ post-scan lifetime ratings

% Don't select voxels based on dec-irr lifetime, since we already showed
% that freq_error is correlated with dec-irr lifetime, it would be
% double-dipping

% Do what is similar to studylifetime_pres1, construct a contrast of LSS-N
% betas based on decreasing activity with increasing overestimation of freq

function test_mirror_1stlvl_softAROMA(project_derivative, LSSN_foldername,sub,output)
%predefine some parameters
TR=2.5;
expstart_vol=5;
fmriprep_foldername='fmriprep_1.5.4_AROMA';
%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/test_1stlvl_mirror_dec_con/',sub);
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
    
    %rescale obj freq and calculate freq_error
    obj_freq_rescale=rescale(cell2mat(resp_event(:,2)),1,5);
    freq_error=str2num(cell2mat(resp_event(:,6)))-obj_freq_rescale;
    resp_event(:,15)= num2cell(freq_error);%freq_error judged-objective
    
    %concatenate into one cell
    runevent=[runevent;resp_event];
end

%find different levels of freq_error
fe_n4=find(cellfun(@(x) x == -4,runevent(:,15)));
fe_n3=find(cellfun(@(x) x == -3,runevent(:,15)));
fe_n2=find(cellfun(@(x) x == -2,runevent(:,15)));
fe_n1=find(cellfun(@(x) x == -1,runevent(:,15)));
fe_0=find(cellfun(@(x) x == 0,runevent(:,15)));
fe_p1=find(cellfun(@(x) x == 1,runevent(:,15)));
fe_p2=find(cellfun(@(x) x == 2,runevent(:,15)));
fe_p3=find(cellfun(@(x) x == 3,runevent(:,15)));
fe_p4=find(cellfun(@(x) x == 4,runevent(:,15)));
%compile into a cell
fe_cell={'fe_n4','fe_n3','fe_n2','fe_n1','fe_0','fe_1','fe_2','fe_3','fe_4';fe_n4,fe_n3,fe_n2,fe_n1,fe_0,fe_p1,fe_p2,fe_p3,fe_p4};

%% SPM stuff
%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%generate iamge calculation string, this must be the dumbest
%design choice I have seen in SPM
fmt='%s%.0f';%format string

for fe=1:size(fe_cell,2)%loop through conditions
    if ~isempty(fe_cell{2,fe})%if there is at least 1 trial for this condition
        imcalc_temp_job;%load spm imcalc template
        if length(fe_cell{2,fe})>1 %if there is more than 1 trial, make the averaging str
            temp_str=cell(0);
            for i=1:length(fe_cell{2,fe})
                temp_str{i}=sprintf(fmt,'i',i);
                matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-test_run_',num2str(runevent{fe_cell{2,fe}(i),14}),'/trial_',num2str(runevent{fe_cell{2,fe}(i),13}),'/beta_0001.nii');
            end
            imcalc_str=join(temp_str,'+');
            imcalc_str=strcat('(',imcalc_str,')/',num2str(length(fe_cell{2,fe})));
            imcalc_str=imcalc_str{1};
        else %otherwise just use the beta from that one trial
            imcalc_str=sprintf(fmt,'i',1);
            matlabbatch{1}.spm.util.imcalc.input{1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-test_run_',num2str(runevent{fe_cell{2,fe},14}),'/trial_',num2str(runevent{fe_cell{2,fe},13}),'/beta_0001.nii');
        end
        matlabbatch{1}.spm.util.imcalc.output = strcat(fe_cell{1,fe},'_beta.nii');
        matlabbatch{1}.spm.util.imcalc.outdir = {sub_dir};
        matlabbatch{1}.spm.util.imcalc.expression=imcalc_str;
        spm_jobman('run',matlabbatch);
        clear matlabbatch
    end
    
end

% generate the contrasts
fe_cond_length={'fe_n4','fe_n3','fe_n2','fe_n1','fe_0','fe_1','fe_2','fe_3','fe_4';length(fe_n4),length(fe_n3),length(fe_n2),length(fe_n1),length(fe_0),length(fe_p1),length(fe_p2),length(fe_p3),length(fe_p4)};
inc={'(-4)','(-3)','(-2)','(-1)','0','1','2','3','4'};
dec={'4','3','2','1','0','(-1)','(-2)','(-3)','(-4)'};

imcalc_temp_job;%load spm imcalc template
if all(cellfun(@(x) x~=0,fe_cond_length(2,:)))
    for i=1:size(fe_cond_length,2)
        matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(sub_dir,'/',fe_cond_length{1,i},'_beta.nii');
        fe_inc_str{i}=[inc{i},'.*',sprintf(fmt,'i',i)];
        fe_dec_str{i}=[dec{i},'.*',sprintf(fmt,'i',i)];
    end
    feinc_str=join(fe_inc_str,'+');
    fedec_str=join(fe_dec_str,'+');
    %fe inc
    matlabbatch{1}.spm.util.imcalc.output = 'con_fe_inc.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {sub_dir};
    matlabbatch{1}.spm.util.imcalc.expression=feinc_str{1};
    spm_jobman('run',matlabbatch);
    
    %fe dec
    matlabbatch{1}.spm.util.imcalc.output = 'con_fe_dec.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {sub_dir};
    matlabbatch{1}.spm.util.imcalc.expression=fedec_str{1};
    spm_jobman('run',matlabbatch);
else %adjust for empty condition
    zero_cond=find(cellfun(@(x) x==0,fe_cond_length(2,:)));
    fe_cond_length(:,zero_cond)=[];
    inc(zero_cond)=[];
    dec(zero_cond)=[];
    for i=1:size(fe_cond_length,2)
        matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(sub_dir,'/',fe_cond_length{1,i},'_beta.nii');
        fe_inc_str{i}=[inc{i},'.*',sprintf(fmt,'i',i)];
        fe_dec_str{i}=[dec{i},'.*',sprintf(fmt,'i',i)];
    end
    feinc_str=join(fe_inc_str,'+');
    fedec_str=join(fe_dec_str,'+');
    %life inc
    matlabbatch{1}.spm.util.imcalc.output = 'con_fe_inc.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {sub_dir};
    matlabbatch{1}.spm.util.imcalc.expression=feinc_str{1};
    spm_jobman('run',matlabbatch);
    
    %life dec
    matlabbatch{1}.spm.util.imcalc.output = 'con_fe_dec.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {sub_dir};
    matlabbatch{1}.spm.util.imcalc.expression=fedec_str{1};
    spm_jobman('run',matlabbatch);
end

end