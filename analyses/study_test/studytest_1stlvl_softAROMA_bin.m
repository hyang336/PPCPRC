%% one design matrix for dec-rele and dec-irrele lifetime and recent exposure effects

function studytest_1stlvl_softAROMA_bin(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile)
%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/studytest_1stlvl_softAROMA/',sub);

%% step 1 generate alltrial regressor and noise regressor
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
        
        %% find both study and test runs
        runkey_study=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*study*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
        runfile_study=dir(runkey_study);        
        substr=struct();
        substr.run=extractfield(runfile_study,'name');
        runkey_test=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
        runfile_test=dir(runkey_test); 
        substr.run=[substr.run,extractfield(runfile_test,'name')];
        
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
        studytest_1stlvl_softAROMA_job;%initialized matlabbatch template MUST HAVE ALL THE NECESSARY FIELDS
        %load post-scan beh
        [~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));
        substr.postscan=raw;
%         %record which condtions each run has, useful for specifying design matrix at
%         %the end (depreciated)
%         runbycond=cell(length(substr.run),45);%maximam 45 condtions (5 bins with presentation number 1, 3, 5, 7, 9) that may differ between runs.
            
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

                %% find different conditions
                if contains(task,'study')%study phase
                    pres_1=substr.runevent{j}(cellfun(@(x) x==11,substr.runevent{j}(:,2))|cellfun(@(x) x==31,substr.runevent{j}(:,2))|cellfun(@(x) x==51,substr.runevent{j}(:,2))|cellfun(@(x) x==71,substr.runevent{j}(:,2))|cellfun(@(x) x==91,substr.runevent{j}(:,2)),:);
                    pres_2=substr.runevent{j}(cellfun(@(x) x==32,substr.runevent{j}(:,2))|cellfun(@(x) x==52,substr.runevent{j}(:,2))|cellfun(@(x) x==72,substr.runevent{j}(:,2))|cellfun(@(x) x==92,substr.runevent{j}(:,2)),:);
                    pres_3=substr.runevent{j}(cellfun(@(x) x==33,substr.runevent{j}(:,2))|cellfun(@(x) x==53,substr.runevent{j}(:,2))|cellfun(@(x) x==73,substr.runevent{j}(:,2))|cellfun(@(x) x==93,substr.runevent{j}(:,2)),:);
                    pres_4=substr.runevent{j}(cellfun(@(x) x==54,substr.runevent{j}(:,2))|cellfun(@(x) x==74,substr.runevent{j}(:,2))|cellfun(@(x) x==94,substr.runevent{j}(:,2)),:);
                    pres_5=substr.runevent{j}(cellfun(@(x) x==55,substr.runevent{j}(:,2))|cellfun(@(x) x==75,substr.runevent{j}(:,2))|cellfun(@(x) x==95,substr.runevent{j}(:,2)),:);
                    pres_6=substr.runevent{j}(cellfun(@(x) x==76,substr.runevent{j}(:,2))|cellfun(@(x) x==96,substr.runevent{j}(:,2)),:);
                    pres_7=substr.runevent{j}(cellfun(@(x) x==77,substr.runevent{j}(:,2))|cellfun(@(x) x==97,substr.runevent{j}(:,2)),:);
                    pres_8=substr.runevent{j}(cellfun(@(x) x==98,substr.runevent{j}(:,2)),:);
                    pres_9=substr.runevent{j}(cellfun(@(x) x==99,substr.runevent{j}(:,2)),:);
                elseif contains(task,'test')%test phase
                    %no response trials
                    noresp=substr.runevent{j}(cellfun(@(x)isnan(x),substr.runevent{j}(:,6)),:);
                    resptrials=substr.runevent{j}(~cellfun(@(x)isnan(x),substr.runevent{j}(:,6)),:);
                    %pull out all columns in the current run's
                    %event file
                    freq_trials=resptrials(strcmp(resptrials(:,4),'recent'),:);
                    fam_trials=resptrials(strcmp(resptrials(:,4),'lifetime'),:);                

                    %use post-scan ratings to mark frequency
                    %trials
                    [o,l]=ismember(freq_trials(:,10),substr.postscan(:,6));%find stimuli                
                    freq_trials(:,11)=substr.postscan(l,11);%fill in post-scan ratings
                    if ~ismember(sub,{'sub-005','sub-020','sub-022'})
                        %if not these 3 subjects, use postscan
                        %ratings
                        lifetime_irr_low=freq_trials(cellfun(@(x)x=='1'||x=='2',freq_trials(:,11)),:);
                        lifetime_irr_mid=freq_trials(cellfun(@(x)x=='3',freq_trials(:,11)),:);
                        lifetime_irr_high=freq_trials(cellfun(@(x)x=='4'||x=='5',freq_trials(:,11)),:);
                    else
                        %otherwise use normative ratings
                        %since it is on 9-point scale, below 3.6
                        %is considered low, and above 5.4 is
                        %considered high (5 quntiles)
                        lifetime_irr_low=freq_trials(cellfun(@(x)x<=3.6,freq_trials(:,3)),:);
                        lifetime_irr_mid=freq_trials(cellfun(@(x)x>3.6&&x<=5.4,freq_trials(:,3)),:);
                        lifetime_irr_high=freq_trials(cellfun(@(x)x>5.4,freq_trials(:,3)),:);
                    end
                    %column 8 and column 9 are the raw and dichotomous feat_over to be
                    %used as parametric modulator, respectively
                    recent_low=freq_trials(cellfun(@(x)x=='1'||x=='2',freq_trials(:,6)),:);
                    recent_mid=freq_trials(cellfun(@(x)x=='3',freq_trials(:,6)),:);
                    recent_high=freq_trials(cellfun(@(x)x=='4'||x=='5',freq_trials(:,6)),:);

                    lifetime_low=fam_trials(cellfun(@(x)x=='1'||x=='2',fam_trials(:,6)),:);
                    lifetime_mid=fam_trials(cellfun(@(x)x=='3',fam_trials(:,6)),:);
                    lifetime_high=fam_trials(cellfun(@(x)x=='4'||x=='5',fam_trials(:,6)),:);
                end
                
                %load confunds
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
                if contains(task,'study')
                    cond={'pres_1','pres_2','pres_3','pres_4','pres_5','pres_6','pres_7','pres_8','pres_9';pres_1,pres_2,pres_3,pres_4,pres_5,pres_6,pres_7,pres_8,pres_9};
                    [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                    miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                    remove_cond=length(miss_cond);%num of cond to be removed from matlabbatch
                elseif contains(task,'test')
                    cond={'recent_low','recent_mid','recent_high','lifetime_low','lifetime_mid','lifetime_high','lifetime_irr_low','lifetime_irr_mid','lifetime_irr_high','noresp';recent_low,recent_mid,recent_high,lifetime_low,lifetime_mid,lifetime_high,lifetime_irr_low,lifetime_irr_mid,lifetime_irr_high,noresp};
                    [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                    miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                    remove_cond=length(miss_cond);
                end
%                 %record condition order for each run
%                 (depreciated)
%                 runbycond(j,1:length(have_cond))=cond(1,have_cond);

                %specify the run-specific matlabbatch fields, "sess" means run in SPM
                %need to account for missing conditions also in job_temlate.m
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(end-remove_cond+1:end)=[];%adjust number of conditions in a given run
                %assign nii images to matlabbatch
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).scans = sliceinfo;
                
                %loop through conitions in a run to fill the
                %matlabbatch structure
                for k=1:length(have_cond)%again the column number here is *hard-coded*
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).name = cond{1,have_cond(k)};
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).onset = cell2mat(cond{2,have_cond(k)}(:,1));
                    if contains(task,'study')
                        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                    elseif contains(task,'test')
                        matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = cell2mat(cond{2,have_cond(k)}(:,5));
                    end
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).tmod = 0;
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod = struct('name', {}, 'param', {}, 'poly', {});
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
%% load SPM.mat and use the design matrix info to define contrasts, using t-contrasts to get the linear combination of betas, then use F-test on 2nd-lvl
                spmmat=load(strcat(temp_dir,'SPM.mat'));
                
                %hopefully the column headers are
                %consistently named, better not update SPM
                %the below lines should return a single
                %number each
              
                %% setup main effect of presentation frequency (high 789 vs. low 1 in study and high 45 vs low 12 in test)
                %setup linear contrast for lifetime
                %conditions
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'recent_main_l-h';
                %use spmmat.SPM.xX.name header to find the
                %right columns
                [~,pres1_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_1*bf(1)'));
                [~,pres7_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_7*bf(1)'));
                [~,pres8_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_8*bf(1)'));
                [~,pres9_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_9*bf(1)'));
                [~,recent_low_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_low*bf(1)'));
                [~,recent_high_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_high*bf(1)'));
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,pres1_col)=1/length(pres1_col);
                convec(1,recent_low_main_col)=1/length(recent_low_main_col);
                
                convec(1,pres7_col)=-1/(3*length(pres7_col));
                convec(1,pres8_col)=-1/(3*length(pres8_col));
                convec(1,pres9_col)=-1/(3*length(pres9_col));
                convec(1,recent_high_main_col)=-1/length(recent_high_main_col);
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                
                %% setup main effect of lifetime familiarity (dec-rele and dec-irrele in test phase)
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'lifetime_main_h-l';
                
                [~,life_low_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_low*bf(1)'));
                [~,life_high_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_high*bf(1)'));
                [~,life_irr_low_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_low*bf(1)'));
                [~,life_irr_high_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_high*bf(1)'));
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life_low_main_col)=-1/length(life_low_main_col);                
                convec(1,life_irr_low_main_col)=-1/length(life_irr_low_main_col);
                
                convec(1,life_high_main_col)=1/length(life_high_main_col);
                convec(1,life_irr_high_main_col)=1/length(life_irr_high_main_col);
                
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = convec;
                
                %% setup interaction between dec-relevance and frequency
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'dec-rele(phase/task) x recent exposure';
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,pres1_col)=-1/length(pres1_col);
                               
                convec(1,pres7_col)=1/(3*length(pres7_col));
                convec(1,pres8_col)=1/(3*length(pres8_col));
                convec(1,pres9_col)=1/(3*length(pres9_col));
                
                convec(1,recent_low_main_col)=1/length(recent_low_main_col);
                
                convec(1,recent_high_main_col)=-1/length(recent_high_main_col);
                
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = convec;
                
                %% setup interaction between dec-relevance and lifetime familiarity          
                matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'dec-rele(task) x lifetime exposure';
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life_low_main_col)=-1/length(life_low_main_col);                
                
                convec(1,life_high_main_col)=1/length(life_high_main_col);
                
                convec(1,life_irr_low_main_col)=1/length(life_irr_low_main_col);
                
                convec(1,life_irr_high_main_col)=-1/length(life_irr_high_main_col);
                
                matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = convec;
            
            %run the contrast and thresholding jobs
            spm_jobman('run',matlabbatch(3));
end