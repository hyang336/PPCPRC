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
                %runum=erase(run{1},'_');
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
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod = struct('name', {}, 'param', {}, 'poly', {});
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
                
                %% setup the two contrast, lifetime and recent. Note that "as long as all of the contrasts are derived from the same GLM model, then you can have as many as you want in a single SPM.mat" ---Suzanne Witt
                %setup linear contrast for lifetime
                %conditions
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'linear inc lifetime';
                %use runbycond to construct appropriate contrast vector
                %lifetime conditions
                [lifetime1_runrow,lifetime1_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_1'),runbycond));
                [lifetime2_runrow,lifetime2_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_2'),runbycond));
                [lifetime3_runrow,lifetime3_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_3'),runbycond));
                [lifetime4_runrow,lifetime4_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_4'),runbycond));
                [lifetime5_runrow,lifetime5_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_5'),runbycond));
                %need to pull recent conditions as well to
                %give them 0 weights instead of NaN
                [recent1_runrow,recent1_designcol]=find(cellfun(@(x)strcmp(x,'recent_1'),runbycond));
                [recent2_runrow,recent2_designcol]=find(cellfun(@(x)strcmp(x,'recent_2'),runbycond));
                [recent3_runrow,recent3_designcol]=find(cellfun(@(x)strcmp(x,'recent_3'),runbycond));
                [recent4_runrow,recent4_designcol]=find(cellfun(@(x)strcmp(x,'recent_4'),runbycond));
                [recent5_runrow,recent5_designcol]=find(cellfun(@(x)strcmp(x,'recent_5'),runbycond));
                
                [noresp_runrow,noresp_designcol]=find(cellfun(@(x)strcmp(x,'noresp'),runbycond));%although not included in the contrast, need to account for all conditions that may differ between runs since they affect column numbers in the design matrix
                motionzero=zeros(size(runbycond,1),6);%6 motion regressors
                
                conmat=nan(size(runbycond));%can't use 0 since noresp is given 0 weight
                %lifetime condition index
                l1ind=sub2ind(size(conmat),lifetime1_runrow,lifetime1_designcol);
                l2ind=sub2ind(size(conmat),lifetime2_runrow,lifetime2_designcol);
                l3ind=sub2ind(size(conmat),lifetime3_runrow,lifetime3_designcol);
                l4ind=sub2ind(size(conmat),lifetime4_runrow,lifetime4_designcol);
                l5ind=sub2ind(size(conmat),lifetime5_runrow,lifetime5_designcol);
                %recent condition index
                r1ind=sub2ind(size(conmat),recent1_runrow,recent1_designcol);
                r2ind=sub2ind(size(conmat),recent2_runrow,recent2_designcol);
                r3ind=sub2ind(size(conmat),recent3_runrow,recent3_designcol);
                r4ind=sub2ind(size(conmat),recent4_runrow,recent4_designcol);
                r5ind=sub2ind(size(conmat),recent5_runrow,recent5_designcol);
                %noresp index
                nrind=sub2ind(size(conmat),noresp_runrow,noresp_designcol);
                %linear increase lifetime
                conmat(l1ind)=-2/length(lifetime1_runrow);
                conmat(l2ind)=-1/length(lifetime2_runrow);
                conmat(l3ind)=0;
                conmat(l4ind)=1/length(lifetime4_runrow);
                conmat(l5ind)=2/length(lifetime5_runrow);
                
                conmat(r1ind)=0;
                conmat(r2ind)=0;
                conmat(r3ind)=0;
                conmat(r4ind)=0;
                conmat(r5ind)=0;
                conmat(nrind)=0;
                                
                conmat=[conmat motionzero];%attach motion regressor weights (i.e. 0)
                convec=reshape(conmat',1,numel(conmat));%unroll the matrix into a vector
                convec=convec(~isnan(convec));                
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                                           
                %% recent linear contrast (put it in a different consess)
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'linear dec recent';
                
                conmat=nan(size(runbycond));%can't use 0 since noresp is given 0 weight
                conmat(r1ind)=2/length(recent1_runrow);
                conmat(r2ind)=1/length(recent2_runrow);
                conmat(r3ind)=0;
                conmat(r4ind)=-1/length(recent4_runrow);
                conmat(r5ind)=-2/length(recent5_runrow);
                
                conmat(l1ind)=0;
                conmat(l2ind)=0;
                conmat(l3ind)=0;
                conmat(l4ind)=0;
                conmat(l5ind)=0;
                conmat(nrind)=0;
                                
                conmat=[conmat motionzero];%attach motion regressor weights (i.e. 0)
                convec=reshape(conmat',1,numel(conmat));%unroll the matrix into a vector
                convec=convec(~isnan(convec));                
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = convec;
                
                %% results (thresholded)
                matlabbatch{4}.spm.stats.results.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{4}.spm.stats.results.export{2}.tspm.basename = 'test resp fwe';%for details about threshold and correction, see xxx_template_job.m
                %first contrast
                matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'linear inc lifetime fwe';
                matlabbatch{4}.spm.stats.results.conspec(1).contrasts = 1;               
                %second contrast
                matlabbatch{4}.spm.stats.results.conspec(2).titlestr = 'linear dec recent fwe';
                matlabbatch{4}.spm.stats.results.conspec(2).contrasts = 2;               
            
                
            %initil setup for SPM
            spm('defaults', 'FMRI');
            spm_jobman('initcfg');
            
            %run after specifying all matlabbatch fields for all runs
            spm_jobman('run',matlabbatch);
            
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
        


