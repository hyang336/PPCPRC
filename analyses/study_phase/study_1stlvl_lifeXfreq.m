%% study phase lifetime and freq (specifically reduction of repsup with high lifetime)interaction effect for mirror effect analysis

% Each level of presentation and lifetime is modelled as a separate
% condition (max: 9 freq * 5 lifetime = 45 conditions)
function study_1stlvl_lifeXfreq(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile)

%subject directory
sub_dir=strcat(output,'/study_1stlvl_lifeXfreq_softAROMA/',sub);

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

%find the nii files
runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*study*_space-MNI152*smoothAROMAnonaggr*.nii.gz');

runfile=dir(runkey);
substr=struct();
substr.run=extractfield(runfile,'name');
substr.id=sub;

%unzip the nii.gz files into the temp directory
gunzip(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
%gunzip(maskfile,temp_dir);
%load the nii files, primarily to get the number of time points
substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));

%call smooth function, which is in
%analyses/pilot/
%smooth the unzipped .nii files, return smoothed
%.nii as 1-by-run cells to a field in substr
substr.runsmooth=crapsmoothspm(temp_dir,erase(substr.run,'.gz'),[4 4 4]);


%make the matlabbatch struct outside of the run-loop since it has separate
%fields for each run
study_1stlvl_repetition_suppression_job;%initialized matlabbatch template MUST HAVE ALL THE NECESSARY FIELDS

%record which condtions each run has, useful for specifying design matrix at
%the end
runbycond=cell(length(substr.run),46);%maximam 46 condtions (5 levels of lifetime fam. * 9 level of freq, and noresp) that may differ between runs.

%load post-scan ratings
[~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));
substr.postscan=raw;
%loop through runs
for j=1:length(substr.run)
    %% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**
    %moved in run-level for-loop on 20190322 to accomodate runs with different
    %task names
    task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
    
    %get design onset, duration, conditions, and confound regressors
    run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
    
    %% the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase, but otherwise it should work
    substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
    %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT'};
    
    %% add another column with participants postscan ratings, this should automatically leave the norm_fam (in 5-point scale) when someone doesn't have postscan rating for a stimulus
    %loop over study trials to find stim
    for s=1:size(substr.runevent{j},1)
        postscan_rating=substr.postscan{strcmp(substr.postscan(:,6),substr.runevent{j}{s,10}),11};
        substr.runevent{j}{s,13}=postscan_rating;%replace with postscan ratings
    end
    
    %% define conditions with postscan lifetime familiarity ratings
    %trials participants did not repond, cant be sure if they perceived the stimulus
    respnan=cellfun(@(x) isnan(x),substr.runevent{j}(:,6),'UniformOutput',0);%more complicated than test phase because now the resp has more than one characters in each cell
    noresp_trials=cellfun(@(x) any(x), respnan);
    noresp=substr.runevent{j}(noresp_trials,:);
    
    pres_1=cellfun(@(x) x==11,substr.runevent{j}(:,2))|cellfun(@(x) x==31,substr.runevent{j}(:,2))|cellfun(@(x) x==51,substr.runevent{j}(:,2))|cellfun(@(x) x==71,substr.runevent{j}(:,2))|cellfun(@(x) x==91,substr.runevent{j}(:,2));
    pres_2=cellfun(@(x) x==32,substr.runevent{j}(:,2))|cellfun(@(x) x==52,substr.runevent{j}(:,2))|cellfun(@(x) x==72,substr.runevent{j}(:,2))|cellfun(@(x) x==92,substr.runevent{j}(:,2));
    pres_3=cellfun(@(x) x==33,substr.runevent{j}(:,2))|cellfun(@(x) x==53,substr.runevent{j}(:,2))|cellfun(@(x) x==73,substr.runevent{j}(:,2))|cellfun(@(x) x==93,substr.runevent{j}(:,2));
    pres_4=cellfun(@(x) x==54,substr.runevent{j}(:,2))|cellfun(@(x) x==74,substr.runevent{j}(:,2))|cellfun(@(x) x==94,substr.runevent{j}(:,2));
    pres_5=cellfun(@(x) x==55,substr.runevent{j}(:,2))|cellfun(@(x) x==75,substr.runevent{j}(:,2))|cellfun(@(x) x==95,substr.runevent{j}(:,2));
    pres_6=cellfun(@(x) x==76,substr.runevent{j}(:,2))|cellfun(@(x) x==96,substr.runevent{j}(:,2));
    pres_7=cellfun(@(x) x==77,substr.runevent{j}(:,2))|cellfun(@(x) x==97,substr.runevent{j}(:,2));
    pres_8=cellfun(@(x) x==98,substr.runevent{j}(:,2));
    pres_9=cellfun(@(x) x==99,substr.runevent{j}(:,2));
    
    if ~ismember(sub,{'sub-020','sub-022'})
        lifetime_1=cellfun(@(x) strcmp(x,'1'),substr.runevent{j}(:,13));
        lifetime_2=cellfun(@(x) strcmp(x,'2'),substr.runevent{j}(:,13));
        lifetime_3=cellfun(@(x) strcmp(x,'3'),substr.runevent{j}(:,13));
        lifetime_4=cellfun(@(x) strcmp(x,'4'),substr.runevent{j}(:,13));
        lifetime_5=cellfun(@(x) strcmp(x,'5'),substr.runevent{j}(:,13));
    else
        %otherwise use normative ratings
        %our stimuli (180 in total) has a
        %normative rating ranging from 1.75 to
        %8.95, the cutoffs were defined by
        %evenly dividing that range into 5
        %intervals
        lifetime_1=cellfun(@(x)x<=3.19,substr.runevent{j}(:,3));
        lifetime_2=cellfun(@(x)x>3.19&&x<=4.63,substr.runevent{j}(:,3));
        lifetime_3=cellfun(@(x)x>4.63&&x<=6.07,substr.runevent{j}(:,3));
        lifetime_4=cellfun(@(x)x>6.07&&x<=7.51,substr.runevent{j}(:,3));
        lifetime_5=cellfun(@(x)x>7.51,substr.runevent{j}(:,3));
    end
    
    prescell={pres_1,pres_2,pres_3,pres_4,pres_5,pres_6,pres_7,pres_8,pres_9};
    lifecell={lifetime_1,lifetime_2,lifetime_3,lifetime_4,lifetime_5};
    %all combination of freq and life
    name=cell(0);
    events=cell(0);
    for f=1:9
        for l=1:5
            name=[name,{strcat('f',num2str(f),'l',num2str(l))}];
            events=[events,{substr.runevent{j}(prescell{f}&lifecell{l},:)}];
        end
    end
    %add no resp condition
    name=[name,'noresp'];
    events=[events,{noresp}];
    
    %confounds
    conf_name=strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'*confound*.tsv');%use task{1} and run{1} since it's iteratively defined
    confstruct=dir(conf_name);
    conffile=strcat(confstruct.folder,'/',confstruct.name);
    substr.runconf{j}=tdfread(conffile,'tab');
    
    %% 2020-07-15 changed expstart_vol to 1 since now we are loading in all TRs in the nifti file and adjusting the trial onsets with dummy TRs in mind (i.e. load_event_test.m)
    %build the cell structure for loading each TR into matlabbatch
    slice=(1:length(substr.runexp{j}));
    slice=cellstr(num2str(slice'));
    slice=cellfun(@strtrim,slice,'UniformOutput',false);%get rid of the white spaces
    comma=repmat(',',(length(substr.runexp{j})-1+1),1);
    comma=cellstr(comma);
    prefix=cell(length(slice),1);
    prefix(:)={substr.runsmooth{j}};%should be a unique run name (using smoothed data)
    %prefix=prefix';
    sliceinfo=cellfun(@strcat,prefix,comma,slice,'UniformOutput',false);
    
    %% since the 9th presentations are unlikely to happen in the first run, we need to account for this in our design matrix
    %an indicator for which condition is missing in a given run
    cond=[name;events];
    [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
    miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
    remove_cond=length(miss_cond);%num of cond to be removed from matlabbatch
    
    %record condition order for each run
    runbycond(j,1:length(have_cond))=cond(1,have_cond);
    
    %specify the run-specific matlabbatch fields, "sess" means run in SPM
    %need to account for missing conditions also in job_temlate.m
    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(length(have_cond)+1:end)=[];%adjust number of conditions in a given run
    matlabbatch{1}.spm.stats.fmri_spec.sess(j).scans = sliceinfo;
    
    %loop through conitions in a run to fill the
    %matlabbatch structure
    for k=1:length(have_cond)%again the column number here is *hard-coded*
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).name = cond{1,have_cond(k)};
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).onset = cell2mat(cond{2,have_cond(k)}(:,1));
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
        
        %gotta fill these fields too
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).tmod = 0;
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod = struct('name', {}, 'param', {}, 'poly', {});%struct('name', 'feat_over', 'param', cell2mat(cond{2,have_cond(k)}(:,8)), 'poly', 1);%the 8th column of a cond cell array is the feat_over para_modulator, using dichotomized value then to result in some conditions having all same feat_over value in a given run, which means the design matrix becomes rank deficient and requiring the contrast vector involving that column to add up to 1.
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).orth = 1;
    end
    
    %no longer include motion regressors since
    %the ICA should have taken care of that
    
    %6 acompcor for WM and CSF, this part
    %assumes that the confounds in the json
    %file are ordered in terms of variance
    %explained
    json_name=strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'*confound*.json');%use task{1} and run{1} since it's iteratively defined
    jsonstruct=dir(json_name);
    jsonfile=strcat(jsonstruct.folder,'/',jsonstruct.name);
    ref = jsondecode(fileread(jsonfile));
    fn=fieldnames(ref);
    acomps=~cellfun(@isempty,strfind(fn,'a_comp_cor'));%find all entries of a_comp_cor
    fn=fn(acomps);
    masks=cell(0);
    for k=1:numel(fn)
        masks{k}=ref.(fn{k}).Mask;
    end
    %find the index for the first 6 occurance of
    %WM and CSF in masks, also account for the
    %posssibility that there might be fewer than
    %6
    WM_ind=find(cellfun(@(x)strcmp(x,'WM'),masks));
    if length(WM_ind)>=6
        WM_1=fn{WM_ind(1)};
        WM_2=fn{WM_ind(2)};
        WM_3=fn{WM_ind(3)};
        WM_4=fn{WM_ind(4)};
        WM_5=fn{WM_ind(5)};
        WM_6=fn{WM_ind(6)};
        
        %add these components as regressors into the
        %GLM
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).name = 'acomp_WM1';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).val = substr.runconf{j}.(WM_1)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).name = 'acomp_WM2';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).val = substr.runconf{j}.(WM_2)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).name = 'acomp_WM3';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).val = substr.runconf{j}.(WM_3)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).name = 'acomp_WM4';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).val = substr.runconf{j}.(WM_4)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).name = 'acomp_WM5';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).val = substr.runconf{j}.(WM_5)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).name = 'acomp_WM6';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).val = substr.runconf{j}.(WM_6)(1:end);
        
        w=6;%how many WM regressors we have
    else
        for w=1:length(WM_ind)
            WM=fn{WM_ind(w)};
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w).name = strcat('acomp_WM',num2str(w));
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w).val = substr.runconf{j}.(WM)(1:end);
        end
    end
    
    CSF_ind=find(cellfun(@(x)strcmp(x,'CSF'),masks));
    if length(CSF_ind)>=6
        CSF_1=fn{CSF_ind(1)};
        CSF_2=fn{CSF_ind(2)};
        CSF_3=fn{CSF_ind(3)};
        CSF_4=fn{CSF_ind(4)};
        CSF_5=fn{CSF_ind(5)};
        CSF_6=fn{CSF_ind(6)};
        
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+1).name = 'acomp_CSF1';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+1).val = substr.runconf{j}.(CSF_1)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+2).name = 'acomp_CSF2';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+2).val = substr.runconf{j}.(CSF_2)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+3).name = 'acomp_CSF3';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+3).val = substr.runconf{j}.(CSF_3)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+4).name = 'acomp_CSF4';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+4).val = substr.runconf{j}.(CSF_4)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+5).name = 'acomp_CSF5';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+5).val = substr.runconf{j}.(CSF_5)(1:end);
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+6).name = 'acomp_CSF6';
        matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+6).val = substr.runconf{j}.(CSF_6)(1:end);
    else
        for c=1:length(CSF_ind)
            CSF=fn{CSF_ind(c)};
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+c).name = strcat('acomp_CSF',num2str(c));
            matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(w+c).val = substr.runconf{j}.(CSF)(1:end);
        end
    end
end

%specify run-agnostic fields
matlabbatch{1}.spm.stats.fmri_spec.dir = {temp_dir};%all runs are combined into one
matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;%remember to change this according to actual TR in second
matlabbatch{1}.spm.stats.fmri_spec.mask = {maskfile};%specify explicit mask, using avg whole-brain mask
%estimate the specified lvl-1 model
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(temp_dir,'SPM.mat')};



%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%run here to generate SPM.mat
spm_jobman('run',matlabbatch(1:2));
%% load SPM.mat and use the design matrix info to define contrasts
spmmat=load(strcat(temp_dir,'SPM.mat'));

%hopefully the column headers are
%consistently named, better not update SPM
%the below lines should return a single
%number each

%% linear contrast of decreasing withe lifetime familiarity
%setup linear contrast for lifetime
%conditions
matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'reduced_repsup_at_high_lifetime';

%initialize contrast vector
convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
freq_convec=convec;
life_convec=convec;
freq_weight=[4,3,2,1,0,-1,-2,-3,-4];%weight for decreasing with freq
life_weight=[2,1,0,-1,-2];%weight for decreasing with lifetime

%use spmmat.SPM.xX.name header to find the
%right columns

%freq columns
f_col=cell(0);
for f=1:9 %loop through frequency levels
    f_col{f}=find(contains(spmmat.SPM.xX.name(1,:),strcat('f',num2str(f))));
    if ~isempty(f_col{f})
        freq_convec(f_col{f})=freq_weight(f)/length(f_col{f});%control for different number of conditions across runs
    end
end
%lifetime columns
l_col=cell(0);
for l=1:5 %loop through lifeitme levels
    l_col{l}=find(contains(spmmat.SPM.xX.name(1,:),strcat('l',num2str(l))));
    if ~isempty(l_col{l})
        life_convec(l_col{l})=life_weight(l)/length(l_col{l});%control for different number of conditions across runs
    end
end

%specific interaction contrast: reduction of decreasing signal with
%increasing frequency at higher level of lifetime
inter_convec=freq_convec.*life_convec; % the magnitude of these weights are kinda small, but should still work

matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = inter_convec;

%run the contrast and thresholding jobs
spm_jobman('run',matlabbatch(3));
end