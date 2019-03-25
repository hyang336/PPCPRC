%event-related design GLM using SPM
%following Duke et al., 2017, lifetime (response) effect was modeled as a linear contrast,
%each response options is modeled as an individual regressor
function lifetime180(project_derivative,output,sub,expstart_vol)
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
            runkey=fullfile(strcat(project_derivative,'/fmriprep/',sub,'/func/'),'*lifetime*_bold_space-MNI152NLin2009cAsym_preproc.nii.gz');
            runfile=dir(runkey);
            substr=struct();
            substr.run=extractfield(runfile,'name');
            substr.id=sub;
            
            %unzip the nii.gz files into the temp directory
            gunzip(strcat(project_derivative,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
            %load the nii files, primarily to get the number of time points
            substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));
            
            %% 2019-03-25
            %loop through runs
            for j=1:length(substr.run)
%% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**           
                %moved in run-level for-loop on 20190322 to accomodate runs with different
                %task names
                task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
                                                
                %get design onset, duration, conditions, and confound regressors
                run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
                runum=str2double(erase(erase(run{1},'run-'),'_'));
                substr.runevent{j}=load_event_lifetime180(project_derivative,sub,'lifetime',runum);%store the loaded event files in sub.runevent
               
                %make task-xxx_run-specific dir
                mkdir(temp_dir,strcat(task{1},erase(run{1},'_')));
                run_temp=strcat(temp_dir,strcat(task{1},erase(run{1},'_')));
                
                %change these to what types of block you have
                %scrambled=substr.runevent{j}(cellfun(@(x)strcmp(x,'s'),substr.runevent{j}(:,3)),:);
                face=substr.runevent{j}(cellfun(@(x)strcmp(x,'f'),substr.runevent{j}(:,3)),:);
                object=substr.runevent{j}(cellfun(@(x)strcmp(x,'o'),substr.runevent{j}(:,3)),:);
                place=substr.runevent{j}(cellfun(@(x)strcmp(x,'p'),substr.runevent{j}(:,3)),:);
          
                conf_name=strcat(project_derivative,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'bold_','confounds.tsv');%use task{1} and run{1} since it's iteratively defined
                substr.runconf{j}=tdfread(conf_name,'tab');
                
                %build the cell structure for loading each TR into matlabbatch
                slice=(expstart_vol:length(substr.runexp{j}));
                slice=cellstr(num2str(slice'));
                slice=cellfun(@strtrim,slice,'UniformOutput',false);%get rid of the white spaces
                comma=repmat(',',(length(substr.runexp{j})-expstart_vol+1),1);
                comma=cellstr(comma);
                prefix={substr.runexp{j}(expstart_vol:end).fname};
                prefix=prefix';
                sliceinfo=cellfun(@strcat,prefix,comma,slice,'UniformOutput',false);

                %make the matlabbatch struct
                localizer_template_job;%initialized matlabbatch template MUST HAVE ALL THE NECESSARY FIELDS
                
                %specify the matlabbatch fields, 4 conditions and 6 confound regressors
                matlabbatch{1}.spm.stats.fmri_spec.dir = {run_temp};
                matlabbatch{1}.spm.stats.fmri_spec.timing.units = 'secs';
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT = 1.6;
                matlabbatch{1}.spm.stats.fmri_spec.sess.scans = sliceinfo;
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name = 'face';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = cell2mat(face(:,1));
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = cell2mat(face(:,2));
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name = 'object';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = cell2mat(object(:,1));
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = cell2mat(object(:,2));
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).name = 'place';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).onset = cell2mat(place(:,1));
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(3).duration = cell2mat(place(:,2));
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).name = 'x_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).val = substr.runconf{j}.X(expstart_vol:end);%need to consider dummy scan
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).name = 'y_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).val = substr.runconf{j}.Y(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).name = 'z_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).val = substr.runconf{j}.Z(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).name = 'x_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).val = substr.runconf{j}.RotX(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).name = 'y_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).val = substr.runconf{j}.RotY(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).name = 'z_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).val = substr.runconf{j}.RotZ(expstart_vol:end);
                matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(run_temp,'/SPM.mat')};
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(run_temp,'/SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'face > place';
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec = [1 0 -1 0];
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
                matlabbatch{4}.spm.stats.results.spmmat = {strcat(run_temp,'/SPM.mat')};
                matlabbatch{4}.spm.stats.results.conspec.titlestr = 'face>place';
                matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
                matlabbatch{4}.spm.stats.results.export{2}.tspm.basename = 'face-place';%for details about threshold and correction, see localizer_template_job.m
                
                %initil setup for SPM
                spm('defaults', 'FMRI');
                spm_jobman('initcfg');
                
                spm_jobman('run',matlabbatch);
                
            end
        end 



