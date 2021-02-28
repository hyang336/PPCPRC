%single-trial GLM for the 1st level. The indi_ss_sharcnet git repo online has
%been changed by Jordan, use the local version instead.

function test_resp_1stlvl_LSS(project_derivative,fmriprep_foldername,output,sub,expstart_vol)
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
sub_dir=strcat(output,'/singletrial_GLM/',sub);

%% step 1 generate alltrial regressor and noise regressor
        %assume BIDS folder structure
        %temp_dir now under sub_dir
        mkdir (sub_dir,'output');
        mkdir (sub_dir,'temp');
        output_dir=strcat(sub_dir,'/output/');
        temp_dir=strcat(sub_dir,'/temp/');
       
        %get #runs from each derivatives/fmriprep_1.0.7/fmriprep/subject/func/ folder
        runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/'),'*test*_space-T1w_desc-preproc_bold.nii.gz');
        runfile=dir(runkey);
        substr=struct();
        substr.run=extractfield(runfile,'name');
        substr.id=sub;
        task=regexp(substr.run{1},'task-\w*_','match');%this will return something like "task-blablabla_"
        %unzip the nii.gz files into the temp directory
        gunzip(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run),temp_dir);
        
        %load the nii files, primarily to get the number of time points
        substr.runexp=spm_vol(strcat(temp_dir,erase(substr.run,'.gz')));

        %initil setup for SPM
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');

        %loop through runs for each participants, store output in the
        %structure named "substr"
        for j=1:length(substr.run)
%% **moved into the run for-loop on 9/17/2018 14:41, did not change behavior**
            load('template_AvsB.mat');
            
            %get TR from nifti header
            ninfo=niftiinfo(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/',sub,'/func/',substr.run{j}));
            TR=ninfo.PixelDimensions(4);
            matlabbatch{1}.spm.stats.fmri_spec.timing.RT=TR;
                            
            %task names
            task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
            
            %make run-specific dir
            mkdir(temp_dir,strcat(task{1},'run_', num2str(j)));
            run_temp=strcat(temp_dir,strcat(task{1},'run_', num2str(j)));
            
            %get design onset, duration, conditions, and confound regressors
            run=regexp(substr.run{j},'run-\d\d_','match');%find corresponding run number to load the events.tsv
            substr.runevent{j}=load_event_test(project_derivative,sub,task,run,expstart_vol,TR);%store the loaded event files in sub.runevent; sub-xxx, task-xxx_, run-xx
            %the event output has no headers, they are in order of {'onset','obj_freq','norm_fam','task','duration','resp','RT','feat_over','feat_over_di','stimuli'};
            
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
            
            %load nii files into job    
            matlabbatch{1}.spm.stats.fmri_spec.sess.scans=[];
            matlabbatch{1}.spm.stats.fmri_spec.sess.scans=sliceinfo;
            
         %always have 6 motion regressors
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).name = 'x_move';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(1).val = substr.runconf{j}.trans_x(1:end);%2020-07-15 dummy scans now corrected in trial onsets
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).name = 'y_move';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(2).val = substr.runconf{j}.trans_y(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).name = 'z_move';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(3).val = substr.runconf{j}.trans_z(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).name = 'x_rot';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(4).val = substr.runconf{j}.rot_x(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).name = 'y_rot';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(5).val = substr.runconf{j}.rot_y(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).name = 'z_rot';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(6).val = substr.runconf{j}.rot_z(1:end);

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
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(7).name = 'acomp_WM1';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(7).val = substr.runconf{j}.(WM_1)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(8).name = 'acomp_WM2';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(8).val = substr.runconf{j}.(WM_2)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(9).name = 'acomp_WM3';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(9).val = substr.runconf{j}.(WM_3)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(10).name = 'acomp_WM4';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(10).val = substr.runconf{j}.(WM_4)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(11).name = 'acomp_WM5';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(11).val = substr.runconf{j}.(WM_5)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(12).name = 'acomp_WM6';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(12).val = substr.runconf{j}.(WM_6)(1:end);

            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(13).name = 'acomp_CSF1';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(13).val = substr.runconf{j}.(CSF_1)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(14).name = 'acomp_CSF2';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(14).val = substr.runconf{j}.(CSF_2)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(15).name = 'acomp_CSF3';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(15).val = substr.runconf{j}.(CSF_3)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(16).name = 'acomp_CSF4';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(16).val = substr.runconf{j}.(CSF_4)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(17).name = 'acomp_CSF5';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(17).val = substr.runconf{j}.(CSF_5)(1:end);
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(18).name = 'acomp_CSF6';
            matlabbatch{1}.spm.stats.fmri_spec.sess.regress(18).val = substr.runconf{j}.(CSF_6)(1:end);


            %loop through trials
            for trial = 1:length(substr.runevent{1,j})
                
                %output dir
                mkdir(run_temp,strcat('trial_', num2str(trial)));
                trial_temp=strcat(run_temp,'/',strcat('trial_', num2str(trial)));
                matlabbatch{1}.spm.stats.fmri_spec.dir = {trial_temp};
                
                % this part redefine the conditions in the
                % design for each trial, cond(1) is the
                % trial of interest and cond(2) is all other trials
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).name='trial_interest';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).onset = substr.runevent{1,j}{trial,1};
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(1).duration = substr.runevent{1,j}{trial,5};
                               
                %use logical index to get all other trials
                othertrial_ind=~eq(cell2mat(substr.runevent{1,j}(:,1)),substr.runevent{1,j}{trial,1});
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).name='other_trials';
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).onset = cell2mat(substr.runevent{1,j}(othertrial_ind,1));%1st column is onset time with respect to first TR trigger
                matlabbatch{1}.spm.stats.fmri_spec.sess.cond(2).duration = cell2mat(substr.runevent{1,j}(othertrial_ind,5));%5th column is duration of event
                                
                %estimate the specified lvl-1 model
                matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(trial_temp,'/SPM.mat')};
                                
                %run here to generate SPM.mat
                spm_jobman('run',matlabbatch);
            end
            
            %clear job structure and reload at the beginning
            %of the for-loop
            clear matlabbatch

        end
end 