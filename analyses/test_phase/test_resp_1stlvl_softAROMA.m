%% same as test_resp_1stlvl.m but using soft AROMA-ICA instead of raw motion regressors

function test_resp_1stlvl_softAROMA(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile)
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 

%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/test_1stlvl_softAROMA/',sub);

% %for copying matlabbatch template, no longer in use
% %only works when you run the whole script
% git_file=mfilename('fullpath');
% s=dbstack();
% folderpath=erase(git_file,s(1).name);

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
        
            %get #runs from each /fmriprep/subject/func/ folder, search for task
            %"lifetime" for pilot subjects
            
            %% 20200208 all subjects now have consistent task names, thus the if statement is no longer needed
            runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-MNI152*smoothAROMAnonaggr*.nii.gz');

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
            test_1stlvl_template_job;%initialized matlabbatch template MUST HAVE ALL THE NECESSARY FIELDS
            
            %record which condtions each run has, useful for specifying design matrix at
            %the end
            runbycond=cell(length(substr.run),11);%maximam 11 condtions (5 in each task + noresp) that may differ between runs.
            
            %loop through runs
            for j=1:length(substr.run)
%% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**           
                %moved in run-level for-loop on 20190322 to accomodate runs with different
                %task names
                task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
                                                
                %get design onset, duration, conditions, and confound regressors
                run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv

                substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
                %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT'};
         
%                 %make task-xxx_run-specific dir
%                 mkdir(temp_dir,strcat(task{1},erase(run{1},'_')));
%                 run_temp=strcat(temp_dir,strcat(task{1},erase(run{1},'_')));
              
                %change these to what types of block you
                %have, the column numbers are *hard-coded*
                %% 20200208 the resp column is character-type not int-type
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
                %The parametric modulator needs to have the
                %same onsets as each condition regressors,
                %see SPM12 manual figure 31.16. Since they
                %have same onsets as resp regressors, they
                %need to be entered as parametric modulator
                %and be demeaned so that they are orthogonal with
                %respect to previous regressors.
                
                
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
                
                %an indicator for which condition is missing in a given run
                cond={'recent_1','recent_2','recent_3','recent_4','recent_5','lifetime_1','lifetime_2','lifetime_3','lifetime_4','lifetime_5','noresp';recent_1,recent_2,recent_3,recent_4,recent_5,lifetime_1,lifetime_2,lifetime_3,lifetime_4,lifetime_5,noresp};
                [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                remove_cond=length(miss_cond);%num of cond to be removed from matlabbatch
                
                %record condition order for each run
                runbycond(j,1:length(have_cond))=cond(1,have_cond);

                %specify the run-specific matlabbatch fields, "sess" means run in SPM
                %need to account for missing conditions also in job_temlate.m
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(end-remove_cond+1:end)=[];%adjust number of conditions in a given run
                
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).scans = sliceinfo;
                
                %loop through conitions in a run to fill the
                %matlabbatch structure
                for k=1:length(have_cond)%again the column number here is *hard-coded*
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).name = cond{1,have_cond(k)};
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).onset = cell2mat(cond{2,have_cond(k)}(:,1));
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = cell2mat(cond{2,have_cond(k)}(:,5));
                    %gotta fill these fields too
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).tmod = 0;
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod = struct('name', 'feat_over', 'param', cell2mat(cond{2,have_cond(k)}(:,8)), 'poly', 1);%the 8th column of a cond cell array is the feat_over para_modulator, using dichotomized value then to result in some conditions having all same feat_over value in a given run, which means the design matrix becomes rank deficient and requiring the contrast vector involving that column to add up to 1.
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).orth = 1;
                end                
                
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
                
                %for condition/modulated-condition (separate design columns)
                %main effect, convec should sum to 0, for
                %parametric modulator main effect, convec
                %should sum to 1
                
                interact_col=cell(1,1,1); %a cell array saving all the design-column numbers for later check
                interact_col(1,2:11,1)={'life1_fo_col_in_spmmat','life2_fo_col_in_spmmat','life3_fo_col_in_spmmat','life4_fo_col_in_spmmat','life5_fo_col_in_spmmat','recent1_fo_col_in_spmmat','recent2_fo_col_in_spmmat','recent3_fo_col_in_spmmat','recent4_fo_col_in_spmmat','recent5_fo_col_in_spmmat'};
                empty_col=cell(1);
                for l=1:length(substr.run)
                    interact_col(l+1,1,1)={strcat('run',num2str(l))};
                    [~,interact_col{l+1,2,1}]=find(strcmp(strcat('Sn(',num2str(l),') lifetime_1xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,3,1}]=find(strcmp(strcat('Sn(',num2str(l),') lifetime_2xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,4,1}]=find(strcmp(strcat('Sn(',num2str(l),') lifetime_3xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,5,1}]=find(strcmp(strcat('Sn(',num2str(l),') lifetime_4xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,6,1}]=find(strcmp(strcat('Sn(',num2str(l),') lifetime_5xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    
                    [~,interact_col{l+1,7,1}]=find(strcmp(strcat('Sn(',num2str(l),') recent_1xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,8,1}]=find(strcmp(strcat('Sn(',num2str(l),') recent_2xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,9,1}]=find(strcmp(strcat('Sn(',num2str(l),') recent_3xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,10,1}]=find(strcmp(strcat('Sn(',num2str(l),') recent_4xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    [~,interact_col{l+1,11,1}]=find(strcmp(strcat('Sn(',num2str(l),') recent_5xfeat_over^1*bf(1)'),spmmat.SPM.xX.name(1,:)));
                    
                    %indicate in the 3rd dimension if any of
                    %the above columns are all zeros
                    for m=2:11%hard-coded
                        interact_col{l+1,m,2}=sum(spmmat.SPM.xX.X(:,interact_col{l+1,m,1}))==0;%logic to check if the sum is 0
                        if interact_col{l+1,m,2}
                            empty_col=[empty_col,interact_col{l+1,m,1}];%save the index (cells of interact_col) of all-zero columns
                        end
                    end
                end
                empty_col=empty_col(~cellfun('isempty',empty_col));%remove the leading empty cell
                
                %% sub-020 has a weird contrast issue 
               if ~strcmp(sub,'sub-020')
                %% setup lifetime linear main effect. Note that "as long as all of the contrasts are derived from the same GLM model, then you can have as many as you want in a single SPM.mat" ---Suzanne Witt
                %setup linear contrast for lifetime
                %conditions
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'linear inc lifetime';
                %use spmmat.SPM.xX.name header to find the
                %right columns
                [~,life1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
                [~,life2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
                [~,life3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
                [~,life4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
                [~,life5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_main_col)=-2/length(life1_main_col);
                convec(1,life2_main_col)=-1/length(life2_main_col);
                convec(1,life3_main_col)=0;
                convec(1,life4_main_col)=1/length(life4_main_col);
                convec(1,life5_main_col)=2/length(life5_main_col);
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                
                %% recent linear main contrast (put it in a different consess)
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'linear dec recent';
                [~,recent1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_1*bf(1)'));
                [~,recent2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_2*bf(1)'));
                [~,recent3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_3*bf(1)'));
                [~,recent4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_4*bf(1)'));
                [~,recent5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_5*bf(1)'));
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,recent1_main_col)=2/length(recent1_main_col);
                convec(1,recent2_main_col)=1/length(recent2_main_col);
                convec(1,recent3_main_col)=0;
                convec(1,recent4_main_col)=-1/length(recent4_main_col);
                convec(1,recent5_main_col)=-2/length(recent5_main_col);
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = convec;
                
                %% contrast for lifetime interacting with feat_over
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'linear inc lifetime with feat_over';
                [~,life1_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1xfeat_over^1*bf(1)'));
                [~,life2_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2xfeat_over^1*bf(1)'));
                [~,life3_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3xfeat_over^1*bf(1)'));
                [~,life4_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4xfeat_over^1*bf(1)'));
                [~,life5_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5xfeat_over^1*bf(1)'));
                %remove all zero columns
                for n=1:length(empty_col)
                   life1_fomod_col=life1_fomod_col(life1_fomod_col~=empty_col{n});
                   life2_fomod_col=life2_fomod_col(life2_fomod_col~=empty_col{n});
                   life3_fomod_col=life3_fomod_col(life3_fomod_col~=empty_col{n});
                   life4_fomod_col=life4_fomod_col(life4_fomod_col~=empty_col{n});
                   life5_fomod_col=life5_fomod_col(life5_fomod_col~=empty_col{n});
                end
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_fomod_col)=-2/length(life1_fomod_col);
                convec(1,life2_fomod_col)=-1/length(life2_fomod_col);
                convec(1,life3_fomod_col)=0;
                convec(1,life4_fomod_col)=1/length(life4_fomod_col);
                convec(1,life5_fomod_col)=2/length(life5_fomod_col);
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = convec;
                
                %% contrast for recent interacting with feat_over.
                matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'linear dec recent with feat_over';
                [~,recent1_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_1xfeat_over^1*bf(1)'));
                [~,recent2_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_2xfeat_over^1*bf(1)'));
                [~,recent3_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_3xfeat_over^1*bf(1)'));
                [~,recent4_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_4xfeat_over^1*bf(1)'));
                [~,recent5_fomod_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_5xfeat_over^1*bf(1)'));
                %remove all zero columns
                for n=1:length(empty_col)
                   recent1_fomod_col=recent1_fomod_col(recent1_fomod_col~=empty_col{n});
                   recent2_fomod_col=recent2_fomod_col(recent2_fomod_col~=empty_col{n});
                   recent3_fomod_col=recent3_fomod_col(recent3_fomod_col~=empty_col{n});
                   recent4_fomod_col=recent4_fomod_col(recent4_fomod_col~=empty_col{n});
                   recent5_fomod_col=recent5_fomod_col(recent5_fomod_col~=empty_col{n});
                end
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,recent1_fomod_col)=2/length(recent1_fomod_col);
                convec(1,recent2_fomod_col)=1/length(recent2_fomod_col);
                convec(1,recent3_fomod_col)=0;
                convec(1,recent4_fomod_col)=-1/length(recent4_fomod_col);
                convec(1,recent5_fomod_col)=-2/length(recent5_fomod_col);
                matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = convec;
                
                %% main effect of feat_over in each task, all-zero interecation columns are removed when defining previous contrasts, making this part easy
                matlabbatch{3}.spm.stats.con.consess{5}.tcon.name = 'positive feat_over in lifetime';
                %total number of modulated lifetime conditions across runs
                sum_life_mod=length(life1_fomod_col)+length(life2_fomod_col)+length(life3_fomod_col)+length(life4_fomod_col)+length(life5_fomod_col);
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_fomod_col)=1/sum_life_mod;
                convec(1,life2_fomod_col)=1/sum_life_mod;
                convec(1,life3_fomod_col)=1/sum_life_mod;
                convec(1,life4_fomod_col)=1/sum_life_mod;
                convec(1,life5_fomod_col)=1/sum_life_mod;
                matlabbatch{3}.spm.stats.con.consess{5}.tcon.weights = convec;
                
                matlabbatch{3}.spm.stats.con.consess{6}.tcon.name = 'positive feat_over in recent';
                %total number of modulated recent conditions across
                %runs
                sum_recent_mod=length(recent1_fomod_col)+length(recent2_fomod_col)+length(recent3_fomod_col)+length(recent4_fomod_col)+length(recent5_fomod_col);
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,recent1_fomod_col)=1/sum_recent_mod;
                convec(1,recent2_fomod_col)=1/sum_recent_mod;
                convec(1,recent3_fomod_col)=1/sum_recent_mod;
                convec(1,recent4_fomod_col)=1/sum_recent_mod;
                convec(1,recent5_fomod_col)=1/sum_recent_mod;
                matlabbatch{3}.spm.stats.con.consess{6}.tcon.weights = convec;
                
                %% main effect of feat_over overall
                matlabbatch{3}.spm.stats.con.consess{7}.tcon.name = 'positive feat_over in test';
                %total number of modulated conditions across
                %runs
                sum_all_mod=sum_life_mod+sum_recent_mod;
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_fomod_col)=1/sum_all_mod;
                convec(1,life2_fomod_col)=1/sum_all_mod;
                convec(1,life3_fomod_col)=1/sum_all_mod;
                convec(1,life4_fomod_col)=1/sum_all_mod;
                convec(1,life5_fomod_col)=1/sum_all_mod;
                convec(1,recent1_fomod_col)=1/sum_all_mod;
                convec(1,recent2_fomod_col)=1/sum_all_mod;
                convec(1,recent3_fomod_col)=1/sum_all_mod;
                convec(1,recent4_fomod_col)=1/sum_all_mod;
                convec(1,recent5_fomod_col)=1/sum_all_mod;
                matlabbatch{3}.spm.stats.con.consess{7}.tcon.weights = convec;
                
                %% main effect of linear increase with recent (for PPC mainly)
                matlabbatch{3}.spm.stats.con.consess{8}.tcon.name = 'linear inc recent';
                [~,recent1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_1*bf(1)'));
                [~,recent2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_2*bf(1)'));
                [~,recent3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_3*bf(1)'));
                [~,recent4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_4*bf(1)'));
                [~,recent5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_5*bf(1)'));
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,recent1_main_col)=-2/length(recent1_main_col);
                convec(1,recent2_main_col)=-1/length(recent2_main_col);
                convec(1,recent3_main_col)=0;
                convec(1,recent4_main_col)=1/length(recent4_main_col);
                convec(1,recent5_main_col)=2/length(recent5_main_col);
                matlabbatch{3}.spm.stats.con.consess{8}.tcon.weights = convec;
                
                %% main effect of linear decrease with lifetime (for PrC mainly)
                matlabbatch{3}.spm.stats.con.consess{9}.tcon.name = 'linear dec lifetime';
                [~,life1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
                [~,life2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
                [~,life3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
                [~,life4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
                [~,life5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_main_col)=2/length(life1_main_col);
                convec(1,life2_main_col)=1/length(life2_main_col);
                convec(1,life3_main_col)=0;
                convec(1,life4_main_col)=-1/length(life4_main_col);
                convec(1,life5_main_col)=-2/length(life5_main_col);
                matlabbatch{3}.spm.stats.con.consess{9}.tcon.weights = convec;
               else
                %% setup lifetime linear main effect. Note that "as long as all of the contrasts are derived from the same GLM model, then you can have as many as you want in a single SPM.mat" ---Suzanne Witt
                %setup linear contrast for lifetime
                %conditions
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'linear inc lifetime';
                %use spmmat.SPM.xX.name header to find the
                %right columns
                [~,life1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
                [~,life2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
                [~,life3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
                [~,life4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
                [~,life5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_main_col)=-2/length(life1_main_col);
                convec(1,life2_main_col)=-1/length(life2_main_col);
                convec(1,life3_main_col)=0;
                convec(1,life4_main_col)=1/length(life4_main_col);
                convec(1,life5_main_col)=2/length(life5_main_col);
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                
                %% recent linear main contrast (put it in a different consess)
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'linear dec recent';
                [~,recent1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_1*bf(1)'));
                [~,recent2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_2*bf(1)'));
                [~,recent3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_3*bf(1)'));
                [~,recent4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_4*bf(1)'));
                [~,recent5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_5*bf(1)'));
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,recent1_main_col)=2/length(recent1_main_col);
                convec(1,recent2_main_col)=1/length(recent2_main_col);
                convec(1,recent3_main_col)=0;
                convec(1,recent4_main_col)=-1/length(recent4_main_col);
                convec(1,recent5_main_col)=-2/length(recent5_main_col);
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = convec;
                
                %% main effect of linear increase with recent (for PPC mainly)
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'linear inc recent';
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,recent1_main_col)=-2/length(recent1_main_col);
                convec(1,recent2_main_col)=-1/length(recent2_main_col);
                convec(1,recent3_main_col)=0;
                convec(1,recent4_main_col)=1/length(recent4_main_col);
                convec(1,recent5_main_col)=2/length(recent5_main_col);
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = convec;
                
                %% main effect of linear decrease with lifetime (for PrC mainly)
                matlabbatch{3}.spm.stats.con.consess{4}.tcon.name = 'linear dec lifetime';
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,life1_main_col)=2/length(life1_main_col);
                convec(1,life2_main_col)=1/length(life2_main_col);
                convec(1,life3_main_col)=0;
                convec(1,life4_main_col)=-1/length(life4_main_col);
                convec(1,life5_main_col)=-2/length(life5_main_col);
                matlabbatch{3}.spm.stats.con.consess{4}.tcon.weights = convec;
               end
                %% 1st lvl results (thresholded)
                matlabbatch{4}.spm.stats.results.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{4}.spm.stats.results.export{2}.tspm.basename = 'test resp fwe';%for details about threshold and correction, see xxx_template_job.m
                %first contrast
                matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'linear inc lifetime fwe';
                matlabbatch{4}.spm.stats.results.conspec(1).contrasts = 1;               
                %second contrast
                matlabbatch{4}.spm.stats.results.conspec(2).titlestr = 'linear dec recent fwe';
                matlabbatch{4}.spm.stats.results.conspec(2).contrasts = 2;               
            
            
            %run the contrast and thresholding jobs
            spm_jobman('run',matlabbatch(3:4));
            
     
end
        



