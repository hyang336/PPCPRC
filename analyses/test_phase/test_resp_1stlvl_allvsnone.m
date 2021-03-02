%% contrast all trials vs baseline to see if the onset time was done correctly.

function test_resp_1stlvl_allvsnone(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile)
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 

%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/test_1stlvl_allvsnone/',sub);

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
            runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-MNI152*preproc*.nii.gz');

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
            substr.runsmooth=crapsmoothspm(temp_dir,erase(substr.run,'.gz'),[8 8 8]);
            

            %make the matlabbatch struct outside of the run-loop since it has separate
            %fields for each run
            test_resp_1stlvl_allvsnone_template_job;%initialized matlabbatch template MUST HAVE ALL THE NECESSARY FIELDS
            
            %loop through runs
            for j=1:length(substr.run)         
                %moved in run-level for-loop on 20190322 to accomodate runs with different
                %task names
                task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
                                                
                %get design onset, duration, conditions, and confound regressors
                run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv

                substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
                %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT'};
                               
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
                %specify the run-specific matlabbatch fields, "sess" means run in SPM
                
                %only one condition which is all trials
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).scans = sliceinfo;
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(1).name = 'all_trials';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(1).onset = cell2mat(substr.runevent{j}(:,1));
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(1).duration = cell2mat(substr.runevent{j}(:,5));
                
                
                %always have 6 motion regressors
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).name = 'x_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(1).val = substr.runconf{j}.trans_x(1:end);%2020-07-15 dummy scans now corrected in trial onsets
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).name = 'y_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(2).val = substr.runconf{j}.trans_y(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).name = 'z_move';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(3).val = substr.runconf{j}.trans_z(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).name = 'x_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(4).val = substr.runconf{j}.rot_x(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).name = 'y_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(5).val = substr.runconf{j}.rot_y(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).name = 'z_rot';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(6).val = substr.runconf{j}.rot_z(1:end);
                
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
                %find the index for the first 6 occurance of WM and CSF in masks
                WM_ind=find(cellfun(@(x)strcmp(x,'WM'),masks));
                WM_1=fn{WM_ind(1)};
                WM_2=fn{WM_ind(2)};
                WM_3=fn{WM_ind(3)};
                WM_4=fn{WM_ind(4)};
                WM_5=fn{WM_ind(5)};
                WM_6=fn{WM_ind(6)};
                
                CSF_ind=find(cellfun(@(x)strcmp(x,'CSF'),masks));
                CSF_1=fn{CSF_ind(1)};
                CSF_2=fn{CSF_ind(2)};
                CSF_3=fn{CSF_ind(3)};
                CSF_4=fn{CSF_ind(4)};
                CSF_5=fn{CSF_ind(5)};
                CSF_6=fn{CSF_ind(6)};
                
                %add these components as regressors into the
                %GLM
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(7).name = 'acomp_WM1';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(7).val = substr.runconf{j}.(WM_1)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(8).name = 'acomp_WM2';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(8).val = substr.runconf{j}.(WM_2)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(9).name = 'acomp_WM3';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(9).val = substr.runconf{j}.(WM_3)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(10).name = 'acomp_WM4';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(10).val = substr.runconf{j}.(WM_4)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(11).name = 'acomp_WM5';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(11).val = substr.runconf{j}.(WM_5)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(12).name = 'acomp_WM6';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(12).val = substr.runconf{j}.(WM_6)(1:end);
                
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(13).name = 'acomp_CSF1';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(13).val = substr.runconf{j}.(CSF_1)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(14).name = 'acomp_CSF2';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(14).val = substr.runconf{j}.(CSF_2)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(15).name = 'acomp_CSF3';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(15).val = substr.runconf{j}.(CSF_3)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(16).name = 'acomp_CSF4';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(16).val = substr.runconf{j}.(CSF_4)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(17).name = 'acomp_CSF5';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(17).val = substr.runconf{j}.(CSF_5)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(18).name = 'acomp_CSF6';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(18).val = substr.runconf{j}.(CSF_6)(1:end);                
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
                
                %% setup lifetime linear main effect. Note that "as long as all of the contrasts are derived from the same GLM model, then you can have as many as you want in a single SPM.mat" ---Suzanne Witt
                %setup linear contrast for lifetime
                %conditions
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'all vs none';
                %use spmmat.SPM.xX.name header to find the
                %right columns
                [~,all_trials]=find(contains(spmmat.SPM.xX.name(1,:),'all_trials*bf(1)'));
      
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix

                convec(1,all_trials)=1/length(all_trials);
                
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                                
                %% 1st lvl results (thresholded)
                matlabbatch{4}.spm.stats.results.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{4}.spm.stats.results.export{2}.tspm.basename = 'all vs none fwe';%for details about threshold and correction, see xxx_template_job.m
                %first contrast
                matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'all vs none fwe';
                matlabbatch{4}.spm.stats.results.conspec(1).contrasts = 1;      
            
            %run the contrast and thresholding jobs
            spm_jobman('run',matlabbatch(3:4));
           
    
end
        



