%% generating constrast of repetition suppression in the study phase using 1st and 2nd presentations

%% F-contrast are non-directional (i.e. they only test the difference between two conditions, not which one has higher activation)
%% We can construct a directional OR test with conjunction analyses on multiple t-contrasts using the "global null" option in conjunction analysis
%% And we can construct a directional AND test with conjunction analyses with the "conjunction null" option
%% See Friston et al. (2005) "Conjunction revisited"

function repetition_suppression_1stlvl_softAROMA(project_derivative,output,sub,expstart_vol,fmriprep_foldername,TR,maskfile)
    
%(i.e. if there are 4 dummy scans, the experiment starts at the 5th
%TR/trigger/volume). In this version every participant in every run has to have the same number of
%dummy scans. 

%sub needs to be in the format of 'sub-xxx'
sub_dir=strcat(output,'/repetition_suppression_softAROMA/',sub);

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
        runbycond=cell(length(substr.run),25);%maximam 25 condtions (5 bins with presentation number 1, 3, 5, 7, 9) that may differ between runs.
            
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

                %% 20210306 the obj_freq column is numeric
                %conditions are difined on the number of
                %presentation of a trial, regardless of
                %total number of presentations
                pres_1=substr.runevent{j}(cellfun(@(x) x==11,substr.runevent{j}(:,2))|cellfun(@(x) x==31,substr.runevent{j}(:,2))|cellfun(@(x) x==51,substr.runevent{j}(:,2))|cellfun(@(x) x==71,substr.runevent{j}(:,2))|cellfun(@(x) x==91,substr.runevent{j}(:,2)),:);
                pres_2=substr.runevent{j}(cellfun(@(x) x==32,substr.runevent{j}(:,2))|cellfun(@(x) x==52,substr.runevent{j}(:,2))|cellfun(@(x) x==72,substr.runevent{j}(:,2))|cellfun(@(x) x==92,substr.runevent{j}(:,2)),:);
                pres_3=substr.runevent{j}(cellfun(@(x) x==33,substr.runevent{j}(:,2))|cellfun(@(x) x==53,substr.runevent{j}(:,2))|cellfun(@(x) x==73,substr.runevent{j}(:,2))|cellfun(@(x) x==93,substr.runevent{j}(:,2)),:);
                pres_4=substr.runevent{j}(cellfun(@(x) x==54,substr.runevent{j}(:,2))|cellfun(@(x) x==74,substr.runevent{j}(:,2))|cellfun(@(x) x==94,substr.runevent{j}(:,2)),:);
                pres_5=substr.runevent{j}(cellfun(@(x) x==55,substr.runevent{j}(:,2))|cellfun(@(x) x==75,substr.runevent{j}(:,2))|cellfun(@(x) x==95,substr.runevent{j}(:,2)),:);
                pres_6=substr.runevent{j}(cellfun(@(x) x==76,substr.runevent{j}(:,2))|cellfun(@(x) x==96,substr.runevent{j}(:,2)),:);
                pres_7=substr.runevent{j}(cellfun(@(x) x==77,substr.runevent{j}(:,2))|cellfun(@(x) x==97,substr.runevent{j}(:,2)),:);
                pres_8=substr.runevent{j}(cellfun(@(x) x==98,substr.runevent{j}(:,2)),:);
                pres_9=substr.runevent{j}(cellfun(@(x) x==99,substr.runevent{j}(:,2)),:);
%                 trail_11=substr.runevent{j}(cellfun(@(x) x==11,substr.runevent{j}(:,2)),:);
%                 trail_31=substr.runevent{j}(cellfun(@(x) x==31,substr.runevent{j}(:,2)),:);
%                 trail_51=substr.runevent{j}(cellfun(@(x) x==51,substr.runevent{j}(:,2)),:);
%                 trail_71=substr.runevent{j}(cellfun(@(x) x==71,substr.runevent{j}(:,2)),:);
%                 trail_91=substr.runevent{j}(cellfun(@(x) x==91,substr.runevent{j}(:,2)),:);
%                 trail_32=substr.runevent{j}(cellfun(@(x) x==32,substr.runevent{j}(:,2)),:);
%                 trail_52=substr.runevent{j}(cellfun(@(x) x==52,substr.runevent{j}(:,2)),:);
%                 trail_72=substr.runevent{j}(cellfun(@(x) x==72,substr.runevent{j}(:,2)),:);
%                 trail_92=substr.runevent{j}(cellfun(@(x) x==92,substr.runevent{j}(:,2)),:);
%                 trail_33=substr.runevent{j}(cellfun(@(x) x==33,substr.runevent{j}(:,2)),:);
%                 trail_53=substr.runevent{j}(cellfun(@(x) x==53,substr.runevent{j}(:,2)),:);
%                 trail_73=substr.runevent{j}(cellfun(@(x) x==73,substr.runevent{j}(:,2)),:);
%                 trail_93=substr.runevent{j}(cellfun(@(x) x==93,substr.runevent{j}(:,2)),:);
%                 trail_54=substr.runevent{j}(cellfun(@(x) x==54,substr.runevent{j}(:,2)),:);
%                 trail_74=substr.runevent{j}(cellfun(@(x) x==74,substr.runevent{j}(:,2)),:);
%                 trail_94=substr.runevent{j}(cellfun(@(x) x==94,substr.runevent{j}(:,2)),:);
%                 trail_55=substr.runevent{j}(cellfun(@(x) x==55,substr.runevent{j}(:,2)),:);
%                 trail_75=substr.runevent{j}(cellfun(@(x) x==75,substr.runevent{j}(:,2)),:);
%                 trail_95=substr.runevent{j}(cellfun(@(x) x==95,substr.runevent{j}(:,2)),:);
%                 trail_76=substr.runevent{j}(cellfun(@(x) x==76,substr.runevent{j}(:,2)),:);
%                 trail_96=substr.runevent{j}(cellfun(@(x) x==96,substr.runevent{j}(:,2)),:);
%                 trail_77=substr.runevent{j}(cellfun(@(x) x==77,substr.runevent{j}(:,2)),:);
%                 trail_97=substr.runevent{j}(cellfun(@(x) x==97,substr.runevent{j}(:,2)),:);
%                 trail_98=substr.runevent{j}(cellfun(@(x) x==98,substr.runevent{j}(:,2)),:);
%                 trail_99=substr.runevent{j}(cellfun(@(x) x==99,substr.runevent{j}(:,2)),:);
          
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
                cond={'pres_1','pres_2','pres_3','pres_4','pres_5','pres_6','pres_7','pres_8','pres_9';pres_1,pres_2,pres_3,pres_4,pres_5,pres_6,pres_7,pres_8,pres_9};
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
                    matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).duration = 1.5; %the duration in load_event_test is hard-coded to 2.5, which is only correct for test-phase
                    % ignore feat_over for now
%                     matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).tmod = 0;
%                     matlabbatch{1}.spm.stats.fmri_spec.sess(j).cond(k).pmod = struct('name', 'feat_over', 'param', cell2mat(cond{2,have_cond(k)}(:,8)), 'poly', 1);%the 8th column of a cond cell array is the feat_over para_modulator, using dichotomized value then to result in some conditions having all same feat_over value in a given run, which means the design matrix becomes rank deficient and requiring the contrast vector involving that column to add up to 1.
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
                
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(7).name = 'acomp_CSF1';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(7).val = substr.runconf{j}.(CSF_1)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(8).name = 'acomp_CSF2';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(8).val = substr.runconf{j}.(CSF_2)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(9).name = 'acomp_CSF3';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(9).val = substr.runconf{j}.(CSF_3)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(10).name = 'acomp_CSF4';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(10).val = substr.runconf{j}.(CSF_4)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(11).name = 'acomp_CSF5';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(11).val = substr.runconf{j}.(CSF_5)(1:end);
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(12).name = 'acomp_CSF6';
                matlabbatch{1}.spm.stats.fmri_spec.sess(j).regress(12).val = substr.runconf{j}.(CSF_6)(1:end);                
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
              
                %% setup pres_1 vs. pres_2 t-contrast
                %setup linear contrast for lifetime
                %conditions
                matlabbatch{3}.spm.stats.con.spmmat = {strcat(temp_dir,'SPM.mat')};
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'pres_1 > pres_2';
                %use spmmat.SPM.xX.name header to find the
                %right columns
                [~,pres1_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_1*bf(1)'));
                [~,pres2_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_2*bf(1)'));
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,pres1_col)=1/length(pres1_col);
                convec(1,pres2_col)=-1/length(pres2_col);
                
                matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = convec;
                
                %% pres_1 simple t-contrast
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'pres_1';
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,pres1_col)=1/length(pres1_col);
                
                matlabbatch{3}.spm.stats.con.consess{2}.tcon.weights = convec;
                
                %% pres_2 simple t_contrast
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.name = 'pres_2';
                
                convec=zeros(1,length(spmmat.SPM.xX.name(1,:)));%contrast vector should be of the same dimension as the number of columns in the design matrix
                convec(1,pres2_col)=1/length(pres2_col);
                
                matlabbatch{3}.spm.stats.con.consess{3}.tcon.weights = convec;
                
                            
            
            
            %run the contrast and thresholding jobs
            spm_jobman('run',matlabbatch(3));
           

end