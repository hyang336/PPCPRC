%event-related design GLM using SPM
%following Duke et al., 2017, lifetime (response) effect was modeled as a linear contrast,
%each response options is modeled as an individual regressor
function lifetime180(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR)
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 
sub_dir=strcat(output,'/pilot_lifetime180/',sub);

% %for copying matlabbatch template, no longer in use
% %only works when you run the whole script
% git_file=mfilename('fullpath');
% s=dbstack();
% folderpath=erase(git_file,s(1).name);

%% step 1 generate alltrial regressor and noise regressor
        %assume BIDS folder structure
        %temp_dir now under sub_dir
        mkdir (sub_dir,'output');
        mkdir (sub_dir,'temp');
        output_dir=strcat(sub_dir,'/output/');
        temp_dir=strcat(sub_dir,'/temp/');
        
            %get #runs from each /fmriprep/subject/func/ folder, search for task
            %"lifetime" 
            runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*lifetime*_space-MNI152NLin2009cAsym*preproc*.nii.gz');
            runfile=dir(runkey);
            substr=struct();
            substr.run=extractfield(runfile,'name');
            substr.id=sub;
            
            %unzip the nii.gz files into the temp directory
            gunzip(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
            %load the nii files, primarily to get the number of time points
            substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));
            
            %% 2019-03-25
            
            %make the matlabbatch struct outside of the run-loop since it has separate
            %fields for each run
            lifetime180_template_job;%initialized matlabbatch template MUST HAVE ALL THE NECESSARY FIELDS
            
            %record which condtions each run has, useful for specifying design matrix at
            %the end
            runbycond=cell(length(substr.run),6);%maximam 6 condtions that may differ between runs.
            
            %loop through runs
            for j=1:length(substr.run)
%% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**           
                %moved in run-level for-loop on 20190322 to accomodate runs with different
                %task names
                task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
                                                
                %get design onset, duration, conditions, and confound regressors
                run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
                runum=erase(run{1},'_');
                substr.runevent{j}=load_event_lifetime180(project_derivative,sub,task,runum);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
               
%                 %make task-xxx_run-specific dir
%                 mkdir(temp_dir,strcat(task{1},erase(run{1},'_')));
%                 run_temp=strcat(temp_dir,strcat(task{1},erase(run{1},'_')));
                
                %change these to what types of block you have
                lifetime_1=substr.runevent{j}(cellfun(@(x)x==1,substr.runevent{j}(:,3)),:);
                lifetime_2=substr.runevent{j}(cellfun(@(x)x==2,substr.runevent{j}(:,3)),:);
                lifetime_3=substr.runevent{j}(cellfun(@(x)x==3,substr.runevent{j}(:,3)),:);
                lifetime_4=substr.runevent{j}(cellfun(@(x)x==4,substr.runevent{j}(:,3)),:);
                lifetime_5=substr.runevent{j}(cellfun(@(x)x==5,substr.runevent{j}(:,3)),:);
                noresp=substr.runevent{j}(cellfun(@(x)isnan(x),substr.runevent{j}(:,3)),:);
                
                
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
                prefix={substr.runexp{j}(expstart_vol:end).fname};
                prefix=prefix';
                sliceinfo=cellfun(@strcat,prefix,comma,slice,'UniformOutput',false);
                %% 2019-03-27 
                %an indicator for which condition is missing in a given run
                cond={'lifetime_1','lifetime_2','lifetime_3','lifetime_4','lifetime_5','noresp';lifetime_1,lifetime_2,lifetime_3,lifetime_4,lifetime_5,noresp};
                [~,have_cond]=find(cellfun(@(x)~isempty(x),cond(2,:)));
                miss_cond=find(cellfun(@(x)isempty(x),cond(2,:)));
                remove_cond=length(miss_cond);%num of cond to be removed from matlabbatch
                
                %record condition order for each run
                runbycond(j,1:length(have_cond))=cond(1,have_cond);

                %specify the run-specific matlabbatch fields, "sess" means run in SPM
                %need to account for missing conditions also in job_temlate.m
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(end-remove_cond+1:end)=[];%adjust number of conditions in a given run
                
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).scans = sliceinfo;
                
                for k=1:length(have_cond)
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).name = cond{1,have_cond(k)};
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).onset = cell2mat(cond{2,have_cond(k)}(:,1));
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = cell2mat(cond{2,have_cond(k)}(:,2));
                end
                %always have 6 motion regressors
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).name = 'x_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).val = substr.runconf{j}.X(expstart_vol:end);%need to consider dummy scan
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).name = 'y_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).val = substr.runconf{j}.Y(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).name = 'z_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).val = substr.runconf{j}.Z(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).name = 'x_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).val = substr.runconf{j}.RotX(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).name = 'y_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).val = substr.runconf{j}.RotY(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).name = 'z_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).val = substr.runconf{j}.RotZ(expstart_vol:end);
                               
                
            end
                %specify run-agnostic fields
                matlabbatch{1}.spm.stats.fmri_spec.dir = {temp_dir};%all runs are combined into one
                matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;%remember to change this according to actual TR
                matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(temp_dir,'/SPM.mat')};
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'/SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'linear inc lifetime';
                %use runbycond to construct appropriate contrast vector
                %linear increase lifetime
                [lifetime1_runrow,lifetime1_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_1'),runbycond));
                [lifetime2_runrow,lifetime2_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_2'),runbycond));
                [lifetime3_runrow,lifetime3_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_3'),runbycond));
                [lifetime4_runrow,lifetime4_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_4'),runbycond));
                [lifetime5_runrow,lifetime5_designcol]=find(cellfun(@(x)strcmp(x,'lifetime_5'),runbycond));
                [noresp_runrow,noresp_designcol]=find(cellfun(@(x)strcmp(x,'noresp'),runbycond));%although not included in the contrast, need to account for all conditions that may differ between runs since they affect column numbers in the design matrix
                motionzero=zeros(size(runbycond,1),6);%6 motion regressors
                conmat=nan(size(runbycond));%can't use 0 since noresp is given 0 weight
                l1ind=sub2ind(size(conmat),lifetime1_runrow,lifetime1_designcol);
                l2ind=sub2ind(size(conmat),lifetime2_runrow,lifetime2_designcol);
                l3ind=sub2ind(size(conmat),lifetime3_runrow,lifetime3_designcol);
                l4ind=sub2ind(size(conmat),lifetime4_runrow,lifetime4_designcol);
                l5ind=sub2ind(size(conmat),lifetime5_runrow,lifetime5_designcol);
                nrind=sub2ind(size(conmat),noresp_runrow,noresp_designcol);
                conmat(l1ind)=-2/length(lifetime1_runrow);
                conmat(l2ind)=-1/length(lifetime2_runrow);
                conmat(l3ind)=0;
                conmat(l4ind)=1/length(lifetime4_runrow);
                conmat(l5ind)=2/length(lifetime5_runrow);
                conmat(nrind)=0;
                
                conmat=[conmat motionzero];%attach motion regressor weights (i.e. 0)
                convec=reshape(conmat',1,48);%unroll the matrix into a vector
                convec=convec(~isnan(convec));                
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                
                matlabbatch{4}.spm.stats.results.spmmat = {strcat(temp_dir,'/SPM.mat')};
                matlabbatch{4}.spm.stats.results.conspec.titlestr = 'linear inc lifetime fwe';
                matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
                matlabbatch{4}.spm.stats.results.export{2}.tspm.basename = 'linear inc lifetime fwe';%for details about threshold and correction, see localizer_template_job.m
            
            %initil setup for SPM
            spm('defaults', 'FMRI');
            spm_jobman('initcfg');
            
            %run after specifying all matlabbatch fields for all runs
            spm_jobman('run',matlabbatch);
        end 



