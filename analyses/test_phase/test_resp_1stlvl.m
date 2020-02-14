%event-related design GLM using SPM
%following Duke et al., 2017, lifetime (response) effect was modeled as a linear contrast,
%each response options is modeled as an individual regressor

%2019-09-25 added an input variable to specify how to handle
%noresp trials (model as a separate regressor "regress" or replace
%with norm_fam and obj_freq "replace")


function test_resp_1stlvl(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,noresp_opt)
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 

%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/test_1stlvl/',sub);

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
            % also changed search pattern since we are now
            % ouptputing to T1w space for ASHS
            runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-T1w*preproc*.nii.gz');

            runfile=dir(runkey);
            substr=struct();
            substr.run=extractfield(runfile,'name');
            substr.id=sub;
            
            %unzip the nii.gz files into the temp directory
            gunzip(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
            
            %load the nii files, primarily to get the number of time points
            substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));
            
            %call smooth function, which is in
            %analyses/pilot/
            %smooth the unzipped .nii files, return smoothed
            %.nii as 1-by-run cells to a field in substr
            substr.runsmooth=crapsmoothspm(temp_dir,erase(substr.run,'.gz'),[4 4 4]);
            
switch noresp_opt
    case 'regress'
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

                substr.runevent{j}=load_event_test(project_derivative,sub,task,run);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
                %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT'};
         
%                 %make task-xxx_run-specific dir
%                 mkdir(temp_dir,strcat(task{1},erase(run{1},'_')));
%                 run_temp=strcat(temp_dir,strcat(task{1},erase(run{1},'_')));
              
                %change these to what types of block you
                %have, the column numbers are *hard-coded*
                %% 20200208 the resp column is character-type not int-type
                freq_trials=substr.runevent{j}(strcmp(substr.runevent{j}(:,4),'recent'),:);
                fam_trials=substr.runevent{j}(strcmp(substr.runevent{j}(:,4),'lifetime'),:);
                %column 9 is the dichotomous feat_over to be
                %used as parametric modulator
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
                            
                %build the cell structure for loading each TR into matlabbatch
                slice=(expstart_vol:length(substr.runexp{j}));
                slice=cellstr(num2str(slice'));
                slice=cellfun(@strtrim,slice,'UniformOutput',false);%get rid of the white spaces
                comma=repmat(',',(length(substr.runexp{j})-expstart_vol+1),1);
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
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod = struct('name', 'feat_over', 'param', cell2mat(cond{2,have_cond(k)}(:,8)), 'poly', 1);%the 8th column of a cond cell array is the feat_over para_modulator, using dichotomized value then to result in some conditions having all same feat_over value in a given run, which means the design matrix becomes rand deficient and requiring the contrast vector involving that column to add up to 1.
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).orth = 1;
                end
                %always have 6 motion regressors
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).name = 'x_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).val = substr.runconf{j}.trans_x(expstart_vol:end);%need to consider dummy scan
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).name = 'y_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).val = substr.runconf{j}.trans_y(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).name = 'z_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).val = substr.runconf{j}.trans_z(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).name = 'x_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).val = substr.runconf{j}.rot_x(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).name = 'y_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).val = substr.runconf{j}.rot_y(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).name = 'z_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).val = substr.runconf{j}.rot_z(expstart_vol:end);
                        
            end
                
                %specify run-agnostic fields
                matlabbatch{1}.spm.stats.fmri_spec.dir = {temp_dir};%all runs are combined into one
                matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;%remember to change this according to actual TR in second
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
                
                interact_col=cell(1); %a cell array saving all the design-column numbers for later check
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
                        interact_col{l+1,m,2}=sum(spmmat.SPM.xX.X(:,interact_col{l+1,m,1}))==0;
                        if interact_col{l+1,m,2}==1
                            empty_col=[empty_col,interact_col{l+1,m,1}];%save the index (cells of interact_col) of all-zero columns
                        end
                    end
                end
                empty_col=empty_col(~cellfun('isempty',empty_col));%remove the leading empty cell
                
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
                
                %% results (thresholded)
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
            
   %% replacing noresp trials with norm_fam or obj_freq
   %% 2019-10-21 line run in sub-P005_script.mat
   %% the 'replace' code below are not finished!!!
    case 'replace'
        
        test_1stlvl_template_job;
        %delete the noresp regressor
        for c=1:numel(matlabbatch{1}.spm.stats.fmri_spec.sess)
            matlabbatch{1}.spm.stats.fmri_spec.sess(c).cond(6)=[];
        end
        
        %record which condtions each run has, useful for specifying design matrix at
        %the end
        runbycond=cell(length(substr.run),5);%maximam 5 condtions (since we are replacing noresp now) that may differ between runs.
            
end 
end
        



