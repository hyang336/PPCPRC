%block design GLM using SPM
%following Martin et al. 2016, face>scene contrast for identifing PrC(ATFP), with
%scrambled modeled as baseline
function localizer(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR)
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 
sub_dir=strcat(output,'/pilot_localizer/',sub);

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
            %"localizer" and "run-01" since different localizer runs are all counted as 01
            runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*localizer*run-01*space-MNI152NLin2009cAsym*preproc*bold.nii.gz');%fmriprep 1.3.2 switched the position of the "bold" tag and the "space" tag, and added "desc-" before "preproc", changed to more liberal expression matching on 2019-04-12
            runfile=dir(runkey);
            substr=struct();
            substr.run=extractfield(runfile,'name');
            substr.id=sub;
            
            %unzip the nii.gz files into the temp directory
            gunzip(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
            %load the nii files, primarily to get the number of time points
            substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));
            
            
            %for now runkey only look for run-01 of the localizer runs 
            for j=1:length(substr.run)
%% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**           
                %moved in run-level for-loop on 20190322 to accomodate runs with different
                %task names
                task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
                                                
                %get design onset, duration, conditions, and confound regressors
                run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
                runum=str2double(erase(erase(run{1},'run-'),'_'));
                substr.runevent{j}=load_event(project_derivative,sub,'localizer',runum);%store the loaded event files in sub.runevent, only one event file is needed since all localizer runs has the same block sequency
               
                %make task-xxx_run-specific dir
                mkdir(temp_dir,strcat(task{1},erase(run{1},'_')));
                run_temp=strcat(temp_dir,strcat(task{1},erase(run{1},'_')));
                
                %change these to what types of block you have
                %scrambled=substr.runevent{j}(cellfun(@(x)strcmp(x,'s'),substr.runevent{j}(:,3)),:);
                face=substr.runevent{j}(cellfun(@(x)strcmp(x,'f'),substr.runevent{j}(:,3)),:);
                object=substr.runevent{j}(cellfun(@(x)strcmp(x,'o'),substr.runevent{j}(:,3)),:);
                place=substr.runevent{j}(cellfun(@(x)strcmp(x,'p'),substr.runevent{j}(:,3)),:);
          
                conf_name=strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',sub,'_',task{1},run{1},'*confound*.tsv');%use task{1} and run{1} since it's iteratively defined. Changed on 2019-04-12 to reflect new naming
                confstruct=dir(conf_name);
                conffile=strcat(confstruct.folder,'/',confstruct.name);
                substr.runconf{j}=tdfread(conffile,'tab');%there should be only one file since search terms are iteratively defined
                
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
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT = TR;
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
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).val = substr.runconf{j}.trans_x(expstart_vol:end);%need to consider dummy scan
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).name = 'y_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).val = substr.runconf{j}.trans_y(expstart_vol:end);%fucking fmriprep changed its naming for these confounds fields
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).name = 'z_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).val = substr.runconf{j}.trans_z(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).name = 'x_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).val = substr.runconf{j}.rot_x(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).name = 'y_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).val = substr.runconf{j}.rot_y(expstart_vol:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).name = 'z_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).val = substr.runconf{j}.rot_z(expstart_vol:end);
                matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(run_temp,'/SPM.mat')};
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(run_temp,'/SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'face > place';
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1 0 -1 0];
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
                matlabbatch{4}.spm.stats.results.spmmat = {strcat(run_temp,'/SPM.mat')};
                matlabbatch{4}.spm.stats.results.conspec.titlestr = 'face>place';
                matlabbatch{4}.spm.stats.results.conspec.contrasts = 1;
                matlabbatch{4}.spm.stats.results.export{2}.tspm.basename = 'face-place';%for details about threshold and correction, see localizer_template_job.m
                
                %initil setup for SPM
                spm('defaults', 'FMRI');
                spm_jobman('initcfg');
                
                spm_jobman('run',matlabbatch);
                
                %% 2019-03-16 note: for some reason the spm_jobman call does not fill the input...
%                 %% use batch_template, 
%                 cellofinput=cell(1);
%                 cellofinput{1} = run_temp;
%                 cellofinput{2} = 'secs';
%                 cellofinput{3} = 1.6;
%                 cellofinput{4} = sliceinfo;
%                 cellofinput{5} = 'scrambled';
%                 cellofinput{6} = cell2mat(scrambled(:,1));
%                 cellofinput{7} = cell2mat(scrambled(:,2));
%                 cellofinput{8} = 'face';
%                 cellofinput{9} = cell2mat(face(:,1));
%                 cellofinput{10} = cell2mat(face(:,2));
%                 cellofinput{11} = 'object';
%                 cellofinput{12} = cell2mat(object(:,1));
%                 cellofinput{13} = cell2mat(object(:,2));
%                 cellofinput{14} = 'place';
%                 cellofinput{15} = cell2mat(place(:,1));
%                 cellofinput{16} = cell2mat(place(:,2));
%                 cellofinput{17} = 'x_move';
%                 cellofinput{18} = substr.runconf{j}.X(expstart_vol:end);%need to consider dummy scan
%                 cellofinput{19} = 'y_move';
%                 cellofinput{20} = substr.runconf{j}.Y(expstart_vol:end);
%                 cellofinput{21} = 'z_move';
%                 cellofinput{22} = substr.runconf{j}.Z(expstart_vol:end);
%                 cellofinput{23} = 'x_rot';
%                 cellofinput{24} = substr.runconf{j}.RotX(expstart_vol:end);
%                 cellofinput{25} = 'y_rot';
%                 cellofinput{26} = substr.runconf{j}.RotY(expstart_vol:end);
%                 cellofinput{27} = 'z_rot';
%                 cellofinput{28} = substr.runconf{j}.RotZ(expstart_vol:end);
%                 cellofinput{29} = {strcat(run_temp,'/SPM.mat')};
%                 cellofinput{30} = {strcat(run_temp,'/SPM.mat')};
%                 
%                 batch_template(1,{'batch_template_job.m'},cellofinput);
            end
        end 



