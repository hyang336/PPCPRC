%% LSS-N GLM for MVPA analyses. Shame it had to be in the MNI space to use soft ICA-AROMA for denoising
% For LSS-N it is up to the user to specify what the "N"
% would be. This script provides two options that either
% consider different presentations or different level of
% post-scan lifetime familiarity as different conditions

function study_1stlvl_LSSN_softAROMA(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile,onset_mode,Nis)

switch Nis %how to model "N"
    
    case 'presentation'
        %sub needs to be in the format of 'sub-xxx'
        switch onset_mode %how to model onsets of events (Grinband et al. 2008)
            case 'var_epoch'
                sub_dir=strcat(output,'/study_1stlvl_LSS-pres_softAROMA_var-epoch_pmod/',sub);
            case 'const_epoch'
                sub_dir=strcat(output,'/study_1stlvl_LSS-pres_softAROMA_const-epoch_pmod/',sub);
        end
        
        if ~exist(strcat(sub_dir,'output'),'dir')
            mkdir (sub_dir,'output');
        end
        if ~exist(strcat(sub_dir,'temp'),'dir')
            mkdir (sub_dir,'temp');
        end
        output_dir=strcat(sub_dir,'/output/');
        temp_dir=strcat(sub_dir,'/temp/');
        
        %find run files
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
        
        %load post-scan ratings
        [~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));
        substr.postscan=raw;
        
        %loop through runs
        for j=1:length(substr.run)
            %moved in run-level for-loop on 20190322 to accomodate runs with different
            %task names
            task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
            
            %get design onset, duration, conditions, and confound regressors
            run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
            
            %% the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase, but otherwise it should work
            substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
            %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT'};
            
            %make run-specific dir
            mkdir(temp_dir,strcat(task{1},'run_', num2str(j)));
            run_temp=strcat(temp_dir,strcat(task{1},'run_', num2str(j)));
            
            %load confounds
            conf_name=strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'*confound*.tsv');%use task{1} and run{1} since it's iteratively defined
            confstruct=dir(conf_name);
            conffile=strcat(confstruct.folder,'/',confstruct.name);
            substr.runconf{j}=tdfread(conffile,'tab');
            
            %build the cell structure for loading each TR into matlabbatch
            slice=(1:length(substr.runexp{j}));
            slice=cellstr(num2str(slice'));
            slice=cellfun(@strtrim,slice,'UniformOutput',false);%get rid of the white spaces
            comma=repmat(',',(length(substr.runexp{j})-1+1),1);
            comma=cellstr(comma);
            prefix=cell(length(slice),1);
            prefix(:)={substr.runexp{j}.fname};%should be a unique run name
            sliceinfo=cellfun(@strcat,prefix,comma,slice,'UniformOutput',false);
            
            %conditions are difined on the number of
            %presentation of a trial, regardless of
            %total number of presentations
            pres_1=substr.runevent{j}(cellfun(@(x) x==11,substr.runevent{j}(:,2))|cellfun(@(x) x==31,substr.runevent{j}(:,2))|cellfun(@(x) x==51,substr.runevent{j}(:,2))|cellfun(@(x) x==71,substr.runevent{j}(:,2))|cellfun(@(x) x==91,substr.runevent{j}(:,2)),:);
            pres_2=substr.runevent{j}(cellfun(@(x) x==32,substr.runevent{j}(:,2))|cellfun(@(x) x==52,substr.runevent{j}(:,2))|cellfun(@(x) x==72,substr.runevent{j}(:,2))|cellfun(@(x) x==92,substr.runevent{j}(:,2)),:);
            pres_3=substr.runevent{j}(cellfun(@(x) x==33,substr.runevent{j}(:,2))|cellfun(@(x) x==53,substr.runevent{j}(:,2))|cellfun(@(x) x==73,substr.runevent{j}(:,2))|cellfun(@(x) x==93,substr.runevent{j}(:,2)),:);
            pres_4=substr.runevent{j}(cellfun(@(x) x==54,substr.runevent{j}(:,2))|cellfun(@(x) x==74,substr.runevent{j}(:,2))|cellfun(@(x) x==94,substr.runevent{j}(:,2)),:);
            pres_5=substr.runevent{j}(cellfun(@(x) x==55,substr.runevent{j}(:,2))|cellfun(@(x) x==75,substr.runevent{j}(:,2))|cellfun(@(x) x==95,substr.runevent{j}(:,2)),:);
            pres_6=substr.runevent{j}(cellfun(@(x) x==76,substr.runevent{j}(:,2))|cellfun(@(x) x==96,substr.runevent{j}(:,2)),:);
            pres_7=substr.runevent{j}(cellfun(@(x) x==77,substr.runevent{j}(:,2))|cellfun(@(x) x==97,substr.runevent{j}(:,2)),:);
            pres_8=substr.runevent{j}(cellfun(@(x) x==98,substr.runevent{j}(:,2)),:);
            pres_9=substr.runevent{j}(cellfun(@(x) x==99,substr.runevent{j}(:,2)),:);
            
            %loop through trials
            for trial = 1:length(substr.runevent{1,j})
                
                %matlabbatch template
                load('template_AvsB.mat');
                
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT=TR;
                matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0;%turn off implicit mask
                matlabbatch{1}.spm.stats.fmri_spec.mask = {maskfile};%use explicit mask, different from the LSS script which uses implicit mask
                %load nii files into job
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans=[];
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans=sliceinfo;
                
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
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).name = 'acomp_WM1';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).val = substr.runconf{j}.(WM_1)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).name = 'acomp_WM2';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).val = substr.runconf{j}.(WM_2)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).name = 'acomp_WM3';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).val = substr.runconf{j}.(WM_3)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).name = 'acomp_WM4';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).val = substr.runconf{j}.(WM_4)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).name = 'acomp_WM5';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).val = substr.runconf{j}.(WM_5)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).name = 'acomp_WM6';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).val = substr.runconf{j}.(WM_6)(1:end);
                    
                    w=6;%how many WM regressors we have
                else
                    for w=1:length(WM_ind)
                        WM=fn{WM_ind(w)};
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w).name = strcat('acomp_WM',num2str(w));
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w).val = substr.runconf{j}.(WM)(1:end);
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
                    
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+1).name = 'acomp_CSF1';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+1).val = substr.runconf{j}.(CSF_1)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+2).name = 'acomp_CSF2';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+2).val = substr.runconf{j}.(CSF_2)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+3).name = 'acomp_CSF3';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+3).val = substr.runconf{j}.(CSF_3)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+4).name = 'acomp_CSF4';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+4).val = substr.runconf{j}.(CSF_4)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+5).name = 'acomp_CSF5';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+5).val = substr.runconf{j}.(CSF_5)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+6).name = 'acomp_CSF6';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+6).val = substr.runconf{j}.(CSF_6)(1:end);
                else
                    for c=1:length(CSF_ind)
                        CSF=fn{CSF_ind(c)};
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+c).name = strcat('acomp_CSF',num2str(c));
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+c).val = substr.runconf{j}.(CSF)(1:end);
                    end
                end
                
                %output dir
                mkdir(run_temp,strcat('trial_', num2str(trial)));
                trial_temp=strcat(run_temp,'/',strcat('trial_', num2str(trial)));
                matlabbatch{1}.spm.stats.fmri_spec.dir = {trial_temp};
                
                % this part redefine the conditions in the
                % design for each trial, cond(1) is the
                % trial of interest 
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name='trial_interest';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = substr.runevent{1,j}{trial,1};
                switch onset_mode
                    case 'var_epoch'
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = substr.runevent{1,j}{trial,7};%use RT
                    case 'const_epoch'
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                end
                
                %trials in each condition other than the
                %current trial
                other_pres_1_ind=~eq(cell2mat(pres_1(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_2_ind=~eq(cell2mat(pres_2(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_3_ind=~eq(cell2mat(pres_3(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_4_ind=~eq(cell2mat(pres_4(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_5_ind=~eq(cell2mat(pres_5(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_6_ind=~eq(cell2mat(pres_6(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_7_ind=~eq(cell2mat(pres_7(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_8_ind=~eq(cell2mat(pres_8(:,1)),substr.runevent{1,j}{trial,1});
                other_pres_9_ind=~eq(cell2mat(pres_9(:,1)),substr.runevent{1,j}{trial,1});
                
                %find which conditions exist in the current run
                cond={'pres_1','pres_2','pres_3','pres_4','pres_5','pres_6','pres_7','pres_8','pres_9';...
                    pres_1(other_pres_1_ind,:),pres_2(other_pres_2_ind,:),pres_3(other_pres_3_ind,:),pres_4(other_pres_4_ind,:),pres_5(other_pres_5_ind,:),...
                    pres_6(other_pres_6_ind,:),pres_7(other_pres_7_ind,:),pres_8(other_pres_8_ind,:),pres_9(other_pres_9_ind,:)};
                [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                %miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                %remove_cond=length(miss_cond);
                
                %fill in other conditions
                for k=1:length(have_cond)%again the column number here is *hard-coded*
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).name = cond{1,have_cond(k)};
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).onset = cell2mat(cond{2,have_cond(k)}(:,1));
                    switch onset_mode
                        case 'var_epoch'
                            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).duration = cell2mat(cond{2,have_cond(k)}(:,7));%use RT
                        case 'const_epoch'
                            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                    end
                    %gotta fill these fields too
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).tmod = 0;
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).orth = 1;
                end
                
                %estimate the specified lvl-1 model
                matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(trial_temp,'/SPM.mat')};
                
                %run here to generate SPM.mat
                spm_jobman('run',matlabbatch);
                
                %clear job structure for each trial
                clear matlabbatch
            end
        end
        
        %%
    case 'lifetime'
        %sub needs to be in the format of 'sub-xxx'
        switch onset_mode %how to model onsets of events (Grinband et al. 2008)
            case 'var_epoch'
                sub_dir=strcat(output,'/study_1stlvl_LSS-life_softAROMA_var-epoch_pmod/',sub);
            case 'const_epoch'
                sub_dir=strcat(output,'/study_1stlvl_LSS-life_softAROMA_const-epoch_pmod/',sub);
        end
        
        if ~exist(strcat(sub_dir,'output'),'dir')
            mkdir (sub_dir,'output');
        end
        if ~exist(strcat(sub_dir,'temp'),'dir')
            mkdir (sub_dir,'temp');
        end
        output_dir=strcat(sub_dir,'/output/');
        temp_dir=strcat(sub_dir,'/temp/');
        
        %find run files
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
        
        %load post-scan ratings
        [~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/',sub,'/',erase(sub,'sub-'),'_task-pscan_data.xlsx'));
        substr.postscan=raw;
        
        %loop through runs
        for j=1:length(substr.run)
            %moved in run-level for-loop on 20190322 to accomodate runs with different
            %task names
            task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
            
            %get design onset, duration, conditions, and confound regressors
            run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
            
            %% the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase, but otherwise it should work
            substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
            %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT'};
            
            %make run-specific dir
            mkdir(temp_dir,strcat(task{1},'run_', num2str(j)));
            run_temp=strcat(temp_dir,strcat(task{1},'run_', num2str(j)));
            
            %load confounds
            conf_name=strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'*confound*.tsv');%use task{1} and run{1} since it's iteratively defined
            confstruct=dir(conf_name);
            conffile=strcat(confstruct.folder,'/',confstruct.name);
            substr.runconf{j}=tdfread(conffile,'tab');
            
            %build the cell structure for loading each TR into matlabbatch
            slice=(1:length(substr.runexp{j}));
            slice=cellstr(num2str(slice'));
            slice=cellfun(@strtrim,slice,'UniformOutput',false);%get rid of the white spaces
            comma=repmat(',',(length(substr.runexp{j})-1+1),1);
            comma=cellstr(comma);
            prefix=cell(length(slice),1);
            prefix(:)={substr.runexp{j}.fname};%should be a unique run name
            sliceinfo=cellfun(@strcat,prefix,comma,slice,'UniformOutput',false);
            
            lifetime_1=substr.runevent{j}(cellfun(@(x) strcmp(x,'1'),substr.runevent{j}(:,13)),:);
            lifetime_2=substr.runevent{j}(cellfun(@(x) strcmp(x,'2'),substr.runevent{j}(:,13)),:);
            lifetime_3=substr.runevent{j}(cellfun(@(x) strcmp(x,'3'),substr.runevent{j}(:,13)),:);
            lifetime_4=substr.runevent{j}(cellfun(@(x) strcmp(x,'4'),substr.runevent{j}(:,13)),:);
            lifetime_5=substr.runevent{j}(cellfun(@(x) strcmp(x,'5'),substr.runevent{j}(:,13)),:);
            noresp=substr.runevent{j}(cellfun(@(x) isnan(x),substr.runevent{j}(:,13)),:);
            
            %loop through trials
            for trial = 1:length(substr.runevent{1,j})
                
                %matlabbatch template
                load('template_AvsB.mat');
                
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT=TR;
                matlabbatch{1}.spm.stats.fmri_spec.mthresh = 0;%turn off implicit mask
                matlabbatch{1}.spm.stats.fmri_spec.mask = {maskfile};%use explicit mask, different from the LSS script which uses implicit mask
                %load nii files into job
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans=[];
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans=sliceinfo;
                
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
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).name = 'acomp_WM1';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).val = substr.runconf{j}.(WM_1)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).name = 'acomp_WM2';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).val = substr.runconf{j}.(WM_2)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).name = 'acomp_WM3';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).val = substr.runconf{j}.(WM_3)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).name = 'acomp_WM4';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).val = substr.runconf{j}.(WM_4)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).name = 'acomp_WM5';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).val = substr.runconf{j}.(WM_5)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).name = 'acomp_WM6';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).val = substr.runconf{j}.(WM_6)(1:end);
                    
                    w=6;%how many WM regressors we have
                else
                    for w=1:length(WM_ind)
                        WM=fn{WM_ind(w)};
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w).name = strcat('acomp_WM',num2str(w));
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w).val = substr.runconf{j}.(WM)(1:end);
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
                    
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+1).name = 'acomp_CSF1';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+1).val = substr.runconf{j}.(CSF_1)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+2).name = 'acomp_CSF2';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+2).val = substr.runconf{j}.(CSF_2)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+3).name = 'acomp_CSF3';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+3).val = substr.runconf{j}.(CSF_3)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+4).name = 'acomp_CSF4';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+4).val = substr.runconf{j}.(CSF_4)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+5).name = 'acomp_CSF5';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+5).val = substr.runconf{j}.(CSF_5)(1:end);
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+6).name = 'acomp_CSF6';
                    matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+6).val = substr.runconf{j}.(CSF_6)(1:end);
                else
                    for c=1:length(CSF_ind)
                        CSF=fn{CSF_ind(c)};
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+c).name = strcat('acomp_CSF',num2str(c));
                        matlabbatch{1}.spm.stats.fmri_spec.sess.regress(w+c).val = substr.runconf{j}.(CSF)(1:end);
                    end
                end
                
                %output dir
                mkdir(run_temp,strcat('trial_', num2str(trial)));
                trial_temp=strcat(run_temp,'/',strcat('trial_', num2str(trial)));
                matlabbatch{1}.spm.stats.fmri_spec.dir = {trial_temp};
                
                % this part redefine the conditions in the
                % design for each trial, cond(1) is the
                % trial of interest 
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name='trial_interest';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = substr.runevent{1,j}{trial,1};
                switch onset_mode
                    case 'var_epoch'
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = substr.runevent{1,j}{trial,7};%use RT
                    case 'const_epoch'
                        matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                end
                
                %trials in each condition other than the
                %current trial
                other_life_1_ind=~eq(cell2mat(lifetime_1(:,1)),substr.runevent{1,j}{trial,1});
                other_life_2_ind=~eq(cell2mat(lifetime_2(:,1)),substr.runevent{1,j}{trial,1});
                other_life_3_ind=~eq(cell2mat(lifetime_3(:,1)),substr.runevent{1,j}{trial,1});
                other_life_4_ind=~eq(cell2mat(lifetime_4(:,1)),substr.runevent{1,j}{trial,1});
                other_life_5_ind=~eq(cell2mat(lifetime_5(:,1)),substr.runevent{1,j}{trial,1});
                other_noresp_ind=~eq(cell2mat(noresp(:,1)),substr.runevent{1,j}{trial,1});
                
                
                %find which conditions exist in the current run
                cond={'life_1','life_2','life_3','life_4','life_5','noresp';...
                    lifetime_1(other_life_1_ind,:),lifetime_2(other_life_2_ind,:),lifetime_3(other_life_3_ind,:),lifetime_4(other_life_4_ind,:),lifetime_5(other_life_5_ind,:),...
                    noresp(other_noresp_ind,:)};
                [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                %miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                %remove_cond=length(miss_cond);
                
                %fill in other conditions
                for k=1:length(have_cond)%again the column number here is *hard-coded*
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).name = cond{1,have_cond(k)};
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).onset = cell2mat(cond{2,have_cond(k)}(:,1));
                    switch onset_mode
                        case 'var_epoch'
                            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).duration = cell2mat(cond{2,have_cond(k)}(:,7));%use RT
                        case 'const_epoch'
                            matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                    end
                    %gotta fill these fields too
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).tmod = 0;
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).pmod = struct('name', {}, 'param', {}, 'poly', {});
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).orth = 1;
                end
                
                %estimate the specified lvl-1 model
                matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(trial_temp,'/SPM.mat')};
                
                %run here to generate SPM.mat
                spm_jobman('run',matlabbatch);
                
                %clear job structure for each trial
                clear matlabbatch
            end
        end
end

end





