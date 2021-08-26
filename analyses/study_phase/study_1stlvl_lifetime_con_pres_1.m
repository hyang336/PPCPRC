%% generate contrast images using 1st presentatons only (from LSS-N)

%% For now, this script ignores unused rating options
%% for example, if a paricipant only used 2 3 4 5, then the contrast vector would be 0 -1 0 1 2

%% in keeping with postscan_lifetime_1stlvl_softAROMA.m, we ignore noresp trial (i.e. no post-scan ratings)
function study_1stlvl_lifetime_con_pres_1(project_derivative,LSSN_foldername,output,sub,fmriprep_foldername)
    
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 

%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/study_lifetime_con_pres-1/',sub);



%% make dir
        %assume BIDS folder structure
        %temp_dir now under sub_dir
        if ~exist(strcat(sub_dir,'output'),'dir')
         mkdir (sub_dir,'output');
        end
        if ~exist(strcat(sub_dir,'temp'),'dir')
         mkdir (sub_dir,'temp');
        end
        output_dir=strcat(sub_dir,'/output/');
        temp_dir=strcat(sub_dir,'/temp/');

%% load event file to pull out which trials correspond to which level of lifetime ratings and is 1st presentation
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
        if ~ismember(sub,{'sub-020','sub-022'})%use normative data for these 2, otherwise use postscan ratings
            postscan_rating=substr.postscan{strcmp(substr.postscan(:,6),substr.runevent{j}{s,10}),11};
        else
            %our stimuli (180 in total) has a
            %normative rating ranging from 1.75 to
            %8.95, the cutoffs were defined by
            %evenly dividing that range into 5
            %intervals
            if substr.runevent{j}{s,3}<=3.19
                postscan_rating='1';
            elseif substr.runevent{j}{s,3}>3.19&&substr.runevent{j}{s,3}<=4.63
                postscan_rating='2';
            elseif substr.runevent{j}{s,3}>4.63&&substr.runevent{j}{s,3}<=6.07
                postscan_rating='3';
            elseif substr.runevent{j}{s,3}>6.07&&substr.runevent{j}{s,3}<=7.51
                postscan_rating='4';
            elseif substr.runevent{j}{s,3}>7.51
                postscan_rating='5';
            end            
        end
        substr.runevent{j}{s,13}=postscan_rating;%replace with postscan ratings
        substr.runevent{j}{s,15}=s;%trial number
    end
    %concatenate across runs
    runevent=[runevent;substr.runevent{j}];
end

pres_1=find(cellfun(@(x) mod(x,10),runevent(:,2))==1);
pres_1_event=runevent(pres_1,:);

%disregard trials without response, since we cannot be sure that
%participants perceived the stimulus
respnan=cellfun(@(x) isnan(x),pres_1_event(:,6),'UniformOutput',0);%more complicated than test phase because now the resp has more than one characters in each cell
noresp_trials=cellfun(@(x) any(x), respnan);
pres_1_event_resp=pres_1_event(~noresp_trials,:);

%find different levels of lifetime
life1=find(strcmp(pres_1_event_resp(:,13),'1'));
life2=find(strcmp(pres_1_event_resp(:,13),'2'));
life3=find(strcmp(pres_1_event_resp(:,13),'3'));
life4=find(strcmp(pres_1_event_resp(:,13),'4'));
life5=find(strcmp(pres_1_event_resp(:,13),'5'));

%% load and average the corresponding beta.nii images for each level of lifetime familiarity

%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%generate calculation string, this must be the dumbest
%design choice I have seen in SPM
fmt='%s%.0f';
%life 1
if ~isempty(life1)%if there is at least 1 trial for this condition
    imcalc_temp_job;%load spm imcalc template
    if length(life1)>1 %if there is more than 1 trial, make the averaging str
        temp_str=cell(0);
        for i=1:length(life1)
            temp_str{i}=sprintf(fmt,'i',i);
            matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life1(i),14}),'/trial_',num2str(pres_1_event_resp{life1(i),15}),'/beta_0001.nii');
        end
        life1_str=join(temp_str,'+');
        life1_str=strcat('(',life1_str,')/',num2str(length(life1)));
        life1_str=life1_str{1};
    else
        life1_str=sprintf(fmt,'i',1);
        matlabbatch{1}.spm.util.imcalc.input{1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life1,14}),'/trial_',num2str(pres_1_event_resp{life1,15}),'/beta_0001.nii');
    end
    matlabbatch{1}.spm.util.imcalc.output = 'life1_beta.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life1_str;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end

%life2
if ~isempty(life2)%if there is at least 1 trial for this condition
    imcalc_temp_job;%load spm imcalc template
    if length(life2)>1 %if there is more than 1 trial, make the averaging str
        temp_str=cell(0);
        for i=1:length(life2)
            temp_str{i}=sprintf(fmt,'i',i);
            matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life2(i),14}),'/trial_',num2str(pres_1_event_resp{life2(i),15}),'/beta_0001.nii');
        end
        life2_str=join(temp_str,'+');
        life2_str=strcat('(',life2_str,')/',num2str(length(life2)));
        life2_str=life2_str{1};
    else
        life2_str=sprintf(fmt,'i',1);
        matlabbatch{1}.spm.util.imcalc.input{1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life2,14}),'/trial_',num2str(pres_1_event_resp{life2,15}),'/beta_0001.nii');
    end
    matlabbatch{1}.spm.util.imcalc.output = 'life2_beta.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life2_str;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end

%life3
if ~isempty(life3)%if there is at least 1 trial for this condition
    imcalc_temp_job;%load spm imcalc template
    if length(life3)>1 %if there is more than 1 trial, make the averaging str
        temp_str=cell(0);
        for i=1:length(life3)
            temp_str{i}=sprintf(fmt,'i',i);
            matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life3(i),14}),'/trial_',num2str(pres_1_event_resp{life3(i),15}),'/beta_0001.nii');
        end
        life3_str=join(temp_str,'+');
        life3_str=strcat('(',life3_str,')/',num2str(length(life3)));
        life3_str=life3_str{1};
    else
        life3_str=sprintf(fmt,'i',1);
        matlabbatch{1}.spm.util.imcalc.input{1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life3,14}),'/trial_',num2str(pres_1_event_resp{life3,15}),'/beta_0001.nii');
    end
    matlabbatch{1}.spm.util.imcalc.output = 'life3_beta.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life3_str;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end

%life4
if ~isempty(life4)%if there is at least 1 trial for this condition
    imcalc_temp_job;%load spm imcalc template
    if length(life4)>1 %if there is more than 1 trial, make the averaging str
        temp_str=cell(0);
        for i=1:length(life4)
            temp_str{i}=sprintf(fmt,'i',i);
            matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life4(i),14}),'/trial_',num2str(pres_1_event_resp{life4(i),15}),'/beta_0001.nii');
        end
        life4_str=join(temp_str,'+');
        life4_str=strcat('(',life4_str,')/',num2str(length(life4)));
        life4_str=life4_str{1};
    else
        life4_str=sprintf(fmt,'i',1);
        matlabbatch{1}.spm.util.imcalc.input{1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life4,14}),'/trial_',num2str(pres_1_event_resp{life4,15}),'/beta_0001.nii');
    end
    matlabbatch{1}.spm.util.imcalc.output = 'life4_beta.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life4_str;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end

%life5
if ~isempty(life5)%if there is at least 1 trial for this condition
    imcalc_temp_job;%load spm imcalc template
    if length(life5)>1 %if there is more than 1 trial, make the averaging str
        temp_str=cell(0);
        for i=1:length(life5)
            temp_str{i}=sprintf(fmt,'i',i);
            matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life5(i),14}),'/trial_',num2str(pres_1_event_resp{life5(i),15}),'/beta_0001.nii');
        end
        life5_str=join(temp_str,'+');
        life5_str=strcat('(',life5_str,')/',num2str(length(life5)));
        life5_str=life5_str{1};
    else
        life5_str=sprintf(fmt,'i',1);
        matlabbatch{1}.spm.util.imcalc.input{1}=strcat(project_derivative,'/',LSSN_foldername,'/',sub,'/temp/task-study_run_',num2str(pres_1_event_resp{life5,14}),'/trial_',num2str(pres_1_event_resp{life5,15}),'/beta_0001.nii');
    end
    matlabbatch{1}.spm.util.imcalc.output = 'life5_beta.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life5_str;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end

%% generate contrast
%this var tells us which condition has no trials
life={'life1','life2','life3','life4','life5';length(life1),length(life2),length(life3),length(life4),length(life5)};
inc={'(-2)','(-1)','0','1','2'};
dec={'2','1','0','(-1)','(-2)'};

imcalc_temp_job;%load spm imcalc template
if all(cellfun(@(x) x~=0,life(2,:)))
    for i=1:size(life,2)
        matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(temp_dir,'/life',num2str(i),'_beta.nii');
        lifeinc_str{i}=[inc{i},'.*',sprintf(fmt,'i',i)];
        lifedec_str{i}=[dec{i},'.*',sprintf(fmt,'i',i)];
    end
    life_inc_str=join(lifeinc_str,'+');
    life_dec_str=join(lifedec_str,'+');
    %life inc
    matlabbatch{1}.spm.util.imcalc.output = 'con_lifeinc.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life_inc_str{1};
    spm_jobman('run',matlabbatch);
    
    %life dec
    matlabbatch{1}.spm.util.imcalc.output = 'con_lifedec.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life_dec_str{1};
    spm_jobman('run',matlabbatch);
else %adjust for empty condition
    zero_cond=find(cellfun(@(x) x==0,life(2,:)));
    life(:,zero_cond)=[];
    inc(zero_cond)=[];
    dec(zero_cond)=[];
    for i=1:size(life,2)
        matlabbatch{1}.spm.util.imcalc.input{i,1}=strcat(temp_dir,'/',life{1,i},'_beta.nii');
        lifeinc_str{i}=[inc{i},'.*',sprintf(fmt,'i',i)];
        lifedec_str{i}=[dec{i},'.*',sprintf(fmt,'i',i)];
    end
    life_inc_str=join(lifeinc_str,'+');
    life_dec_str=join(lifedec_str,'+');
    %life inc
    matlabbatch{1}.spm.util.imcalc.output = 'con_lifeinc.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life_inc_str{1};
    spm_jobman('run',matlabbatch);
    
    %life dec
    matlabbatch{1}.spm.util.imcalc.output = 'con_lifedec.nii';
    matlabbatch{1}.spm.util.imcalc.outdir = {temp_dir};
    matlabbatch{1}.spm.util.imcalc.expression=life_dec_str{1};
    spm_jobman('run',matlabbatch);
end


       
end
