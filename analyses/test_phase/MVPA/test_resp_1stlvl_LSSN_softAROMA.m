%% LSS-N for test phase, using softAROMA and variable epoch
%% this could be done in native space but since we pulled out the effect ROI in MNI space we decide to remain in that space

%20210902, it runs the smooth function but the output is not used, the
%entire procedure uses non-smoothed data

function test_resp_1stlvl_LSSN_softAROMA(project_derivative,fmriprep_foldername,output,sub,expstart_vol,maskfile)
%updated 2021, now mainly support my own fMRI project,
%changed the folder structure so we no longer delete SPM.mat
%after certain processing steps.

%updated 20190227, added another input variable to indicate the volume when the
%experiement starts (i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 
%so far putting most output in temp dir

%20190603, added input var to specify fmriprep folder name,
%assuming it's in derivative under BIDS folder
sub_dir=strcat(output,'/LSS-N_test/',sub);

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
       
        %get #runs from each derivatives/fmriprep_1.0.7/fmriprep/subject/func/ folder
        runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');

        runfile=dir(runkey);
        substr=struct();
        substr.run=extractfield(runfile,'name');
        substr.id=sub;
        task=regexp(substr.run{1},'task-\w*_','match');%this will return something like "task-blablabla_"
        %unzip the nii.gz files into the temp directory
        gunzip(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
        
        %load the nii files, primarily to get the number of time points
        substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));
        %substr.runsmooth=crapsmoothspm(temp_dir,erase(substr.run,'.gz'),[4 4 4]);
        
        %initil setup for SPM
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');

        %loop through runs for each participants, store output in the
        %structure named "substr"
        for j=1:length(substr.run)
%% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**
            
            %get TR from nifti header
            ninfo=niftiinfo(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run{j}));
            TR=ninfo.PixelDimensions(4);
             
            %task names
            task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
            
            %make run-specific dir
            mkdir(temp_dir,strcat(task{1},'run_', num2str(j)));
            run_temp=strcat(temp_dir,strcat(task{1},'run_', num2str(j)));
            
            %get design onset, duration, conditions, and confound regressors
            run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
            substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
            %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT',feat_over,bi_feat_over,stimuli,epi_t,sem_t};
                
            conf_name=strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'*confound*.tsv');%use task{1} and run{1} since it's iteratively defined
            confstruct=dir(conf_name);
            conffile=strcat(confstruct.folder,'/',confstruct.name);
            substr.runconf{j}=tdfread(conffile,'tab');
            %% step 1 specify job details of runs
            %% 2020-07-15 changed expstart_vol to 1 since now we are loading in all TRs in the nifti file and adjusting the trial onsets with dummy TRs in mind (i.e. load_event_test.m)
            %build the cell structure for loading each TR into matlabbatch
            slice=(1:length(substr.runexp{j}));
            slice=cellstr(num2str(slice'));
            slice=cellfun(@strtrim,slice,'UniformOutput',false);%get rid of the white spaces
            comma=repmat(',',(length(substr.runexp{j})-1+1),1);
            comma=cellstr(comma);
            prefix=cell(length(slice),1);
            prefix(:)={substr.runexp{j}.fname};%should be a unique run name
            sliceinfo=cellfun(@strcat,prefix,comma,slice,'UniformOutput',false);
            
            %pull out all columns in the current run's
            %event file
            freq_trials=substr.runevent{j}(strcmp(substr.runevent{j}(:,4),'recent'),:);
            fam_trials=substr.runevent{j}(strcmp(substr.runevent{j}(:,4),'lifetime'),:);
            %column 8 and column 9 are the raw and dichotomous feat_over to be
            %used as parametric modulator, respectively
            recent_1=freq_trials(cellfun(@(x)x=='1',freq_trials(:,6)),:);
            recent_2=freq_trials(cellfun(@(x)x=='2',freq_trials(:,6)),:);
            recent_3=freq_trials(cellfun(@(x)x=='3',freq_trials(:,6)),:);
            recent_4=freq_trials(cellfun(@(x)x=='4',freq_trials(:,6)),:);
            recent_5=freq_trials(cellfun(@(x)x=='5',freq_trials(:,6)),:);
            lifetime_1=fam_trials(cellfun(@(x)x=='1',fam_trials(:,6)),:);
            lifetime_2=fam_trials(cellfun(@(x)x=='2',fam_trials(:,6)),:);
            lifetime_3=fam_trials(cellfun(@(x)x=='3',fam_trials(:,6)),:);
            lifetime_4=fam_trials(cellfun(@(x)x=='4',fam_trials(:,6)),:);
            lifetime_5=fam_trials(cellfun(@(x)x=='5',fam_trials(:,6)),:);
            noresp=substr.runevent{j}(cellfun(@(x)isnan(x),substr.runevent{j}(:,6)),:);
                
                
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
                % trial of interest and cond(2) is all other trials
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name='trial_interest';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = substr.runevent{1,j}{trial,1};
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = substr.runevent{1,j}{trial,7};%use RT for boxcar length
               
                
                %trials in each condition other than the
                %current trial
                other_recent_1_ind=~eq(cell2mat(recent_1(:,1)),substr.runevent{1,j}{trial,1});
                other_recent_2_ind=~eq(cell2mat(recent_2(:,1)),substr.runevent{1,j}{trial,1});
                other_recent_3_ind=~eq(cell2mat(recent_3(:,1)),substr.runevent{1,j}{trial,1});
                other_recent_4_ind=~eq(cell2mat(recent_4(:,1)),substr.runevent{1,j}{trial,1});
                other_recent_5_ind=~eq(cell2mat(recent_5(:,1)),substr.runevent{1,j}{trial,1});
                
                other_lifetime_1_ind=~eq(cell2mat(lifetime_1(:,1)),substr.runevent{1,j}{trial,1});
                other_lifetime_2_ind=~eq(cell2mat(lifetime_2(:,1)),substr.runevent{1,j}{trial,1});
                other_lifetime_3_ind=~eq(cell2mat(lifetime_3(:,1)),substr.runevent{1,j}{trial,1});
                other_lifetime_4_ind=~eq(cell2mat(lifetime_4(:,1)),substr.runevent{1,j}{trial,1});
                other_lifetime_5_ind=~eq(cell2mat(lifetime_5(:,1)),substr.runevent{1,j}{trial,1});
                
                other_noresp_ind=~eq(cell2mat(noresp(:,1)),substr.runevent{1,j}{trial,1});
                %find which conditions exist in the current run
                cond={'recent_1','recent_2','recent_3','recent_4','recent_5','lifetime_1','lifetime_2','lifetime_3','lifetime_4','lifetime_5','noresp';...
                    recent_1(other_recent_1_ind,:),recent_2(other_recent_2_ind,:),recent_3(other_recent_3_ind,:),recent_4(other_recent_4_ind,:),recent_5(other_recent_5_ind,:),...
                    lifetime_1(other_lifetime_1_ind,:),lifetime_2(other_lifetime_2_ind,:),lifetime_3(other_lifetime_3_ind,:),lifetime_4(other_lifetime_4_ind,:),lifetime_5(other_lifetime_5_ind,:),noresp(other_noresp_ind,:)};
                [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                %miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                %remove_cond=length(miss_cond);
                
                %fill in other conditions 
                for k=1:length(have_cond)%again the column number here is *hard-coded*
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).name = cond{1,have_cond(k)};
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).onset = cell2mat(cond{2,have_cond(k)}(:,1));                   
                    matlabbatch{1}.spm.stats.fmri_spec.sess.cond(k+1).duration = cell2mat(cond{2,have_cond(k)}(:,7));%use RT                        
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