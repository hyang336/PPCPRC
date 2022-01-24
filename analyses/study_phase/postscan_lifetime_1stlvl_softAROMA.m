%% use postscan ratings to code GLM columns

function postscan_lifetime_1stlvl_softAROMA(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile,onset_mode)
    
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 

%sub needs to be in the format of 'sub-xxx'
switch onset_mode %how to model onsets of events (Grinband et al. 2008)
    case 'var_epoch'
        sub_dir=strcat(output,'/postscan_lifetime_softAROMA_var-epoch/',sub);
    case 'const_epoch'
        sub_dir=strcat(output,'/postscan_lifetime_softAROMA_const-epoch/',sub);
end


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
        
        %% 20200208 all subjects now have consistent task names, thus the if statement is no longer needed
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
        runbycond=cell(length(substr.run),6);%maximam 6 condtions (5 levels of lifetime fam. and noresp) that may differ between runs.
        
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
                
                if ~ismember(sub,{'sub-020','sub-022'})
                    lifetime_1=substr.runevent{j}(cellfun(@(x) strcmp(x,'1'),substr.runevent{j}(:,13)),:);
                    lifetime_2=substr.runevent{j}(cellfun(@(x) strcmp(x,'2'),substr.runevent{j}(:,13)),:);
                    lifetime_3=substr.runevent{j}(cellfun(@(x) strcmp(x,'3'),substr.runevent{j}(:,13)),:);
                    lifetime_4=substr.runevent{j}(cellfun(@(x) strcmp(x,'4'),substr.runevent{j}(:,13)),:);
                    lifetime_5=substr.runevent{j}(cellfun(@(x) strcmp(x,'5'),substr.runevent{j}(:,13)),:); 
                else
                    %otherwise use normative ratings
                    %our stimuli (180 in total) has a
                    %normative rating ranging from 1.75 to
                    %8.95, the cutoffs were defined by
                    %evenly dividing that range into 5
                    %intervals
                    lifetime_1=substr.runevent{j}(cellfun(@(x)x<=3.19,substr.runevent{j}(:,3)),:);
                    lifetime_2=substr.runevent{j}(cellfun(@(x)x>3.19&&x<=4.63,substr.runevent{j}(:,3)),:);
                    lifetime_3=substr.runevent{j}(cellfun(@(x)x>4.63&&x<=6.07,substr.runevent{j}(:,3)),:);
                    lifetime_4=substr.runevent{j}(cellfun(@(x)x>6.07&&x<=7.51,substr.runevent{j}(:,3)),:);
                    lifetime_5=substr.runevent{j}(cellfun(@(x)x>7.51,substr.runevent{j}(:,3)),:);
                end
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
                cond={'lifetime_1','lifetime_2','lifetime_3','lifetime_4','lifetime_5','noresp';lifetime_1,lifetime_2,lifetime_3,lifetime_4,lifetime_5,noresp};
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
                    switch onset_mode
                        case 'var_epoch'
                            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = cell2mat(cond{2,have_cond(k)}(:,7));%use RT
                        case 'const_epoch'
                            matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                    end
%                    % pmods
%                     matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).tmod = 0;
%                     matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod(1) = struct('name', 'lifetime_fam', 'param', cell2mat(cond{2,have_cond(k)}(:,3)), 'poly', 1);%pmod of lifetime fam
%                     matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod(2) = struct('name', 'feat_over', 'param', cell2mat(cond{2,have_cond(k)}(:,8)), 'poly', 1);%pmod of feat_over
%                     matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).orth = 1;
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
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_dec';
                %use spmmat.SPM.xX.name header to find the
                %right columns
                [~,life1_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
                [~,life2_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
                [~,life3_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
                [~,life4_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
                [~,life5_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));

                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_col)=2/length(life1_col);
                convec(1,life2_col)=1/length(life2_col);
                convec(1,life3_col)=0/length(life3_col);
                convec(1,life4_col)=-1/length(life4_col);
                convec(1,life5_col)=-2/length(life5_col);
                
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
   
            %run the contrast and thresholding jobs
            spm_jobman('run',matlabbatch(3));
           

end

