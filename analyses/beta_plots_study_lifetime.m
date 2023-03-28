%% function to plot results for the study phase lifetime familiarity effect
% 2023-03-16 now saving standard deviation of the sample for bar plots
% since the se is missleading @Russ Poldrack
function beta_plots_study_lifetime(first_lvl_dir,sublist,mask_dir,ROI_mask,output_dir,analysis)
%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%read in ROI nifti
ROI=niftiread(strcat(mask_dir,'/',ROI_mask));

switch analysis
    case 'alltrials'
        for i=1:length(SSID)
            %load spm.mat
            spmmat=load(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/','SPM.mat'));
            [~,life1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
            [~,life2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
            [~,life3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
            [~,life4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
            [~,life5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));
            %loop through runs that contains conditions
            if ~isempty(life1_main_col)
                for j=1:length(life1_main_col)
                    life1_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/beta_',num2str(life1_main_col(j),'%04.f'),'.nii'));
                    life1_ROI_beta(j)=nanmean(life1_beta{j}(find(ROI)));%average beta within the ROI
                end
                sub_life1_ROI_beta{i,1}=nanmean(life1_ROI_beta);
                sub_life1_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life2_main_col)
                for j=1:length(life2_main_col)
                    life2_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/beta_',num2str(life2_main_col(j),'%04.f'),'.nii'));
                    life2_ROI_beta(j)=nanmean(life2_beta{j}(find(ROI)));
                end
                sub_life2_ROI_beta{i,1}=nanmean(life2_ROI_beta);
                sub_life2_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life3_main_col)
                for j=1:length(life3_main_col)
                    life3_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/beta_',num2str(life3_main_col(j),'%04.f'),'.nii'));
                    life3_ROI_beta(j)=nanmean(life3_beta{j}(find(ROI)));
                end
                sub_life3_ROI_beta{i,1}=nanmean(life3_ROI_beta);
                sub_life3_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life4_main_col)
                for j=1:length(life4_main_col)
                    life4_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/beta_',num2str(life4_main_col(j),'%04.f'),'.nii'));
                    life4_ROI_beta(j)=nanmean(life4_beta{j}(find(ROI)));
                end
                sub_life4_ROI_beta{i,1}=nanmean(life4_ROI_beta);
                sub_life4_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life5_main_col)
                for j=1:length(life5_main_col)
                    life5_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/beta_',num2str(life5_main_col(j),'%04.f'),'.nii'));
                    life5_ROI_beta(j)=nanmean(life5_beta{j}(find(ROI)));
                end
                sub_life5_ROI_beta{i,1}=nanmean(life5_ROI_beta);
                sub_life5_ROI_beta{i,2}=SSID{i};
            end
            
        end
        
        %% for plot, if statement checks for missing conditions
        if exist('sub_life1_ROI_beta','var') == 1
            sub_life1_ROI_beta_noemp=sub_life1_ROI_beta(~cellfun(@isempty, sub_life1_ROI_beta(:,1)));
            life1_avg=mean(cell2mat(sub_life1_ROI_beta_noemp),'omitnan');
            life1_se=std(cell2mat(sub_life1_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life1_ROI_beta_noemp));
            life1_sd=std(cell2mat(sub_life1_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life1.mat'),'life1_avg','life1_se','life1_sd','sub_life1_ROI_beta');
        end
        if exist('sub_life2_ROI_beta','var') == 1
            sub_life2_ROI_beta_noemp=sub_life2_ROI_beta(~cellfun(@isempty, sub_life2_ROI_beta(:,1)));
            life2_avg=mean(cell2mat(sub_life2_ROI_beta_noemp),'omitnan');
            life2_se=std(cell2mat(sub_life2_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life2_ROI_beta_noemp));
            life2_sd=std(cell2mat(sub_life2_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life2.mat'),'life2_avg','life2_se','life2_sd','sub_life2_ROI_beta');
        end
        if exist('sub_life3_ROI_beta','var') == 1
            sub_life3_ROI_beta_noemp=sub_life3_ROI_beta(~cellfun(@isempty, sub_life3_ROI_beta(:,1)));
            life3_avg=mean(cell2mat(sub_life3_ROI_beta_noemp),'omitnan');
            life3_se=std(cell2mat(sub_life3_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life3_ROI_beta_noemp));
            life3_sd=std(cell2mat(sub_life3_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life3.mat'),'life3_avg','life3_se','life3_sd','sub_life3_ROI_beta');
        end
        if exist('sub_life4_ROI_beta','var') == 1
            sub_life4_ROI_beta_noemp=sub_life4_ROI_beta(~cellfun(@isempty, sub_life4_ROI_beta(:,1)));
            life4_avg=mean(cell2mat(sub_life4_ROI_beta_noemp),'omitnan');
            life4_se=std(cell2mat(sub_life4_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life4_ROI_beta_noemp));
            life4_sd=std(cell2mat(sub_life4_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life4.mat'),'life4_avg','life4_se','life4_sd','sub_life4_ROI_beta');
        end
        if exist('sub_life5_ROI_beta','var') == 1
            sub_life5_ROI_beta_noemp=sub_life5_ROI_beta(~cellfun(@isempty, sub_life5_ROI_beta(:,1)));
            life5_avg=mean(cell2mat(sub_life5_ROI_beta_noemp),'omitnan');
            life5_se=std(cell2mat(sub_life5_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life5_ROI_beta_noemp));
            life5_sd=std(cell2mat(sub_life5_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life5.mat'),'life5_avg','life5_se','life5_sd','sub_life5_ROI_beta');
        end
        
    case 'pres1'
        %hard-coded variable to load event files
        TR=2.5;
        expstart_vol=5;
        project_derivative='/scratch/hyang336/working_dir/PPC_MD/';
        fmriprep_foldername='fmriprep_1.5.4_AROMA';
        %% load event files and recode high vs. low freq and lifetime
        for i=1:length(SSID)            
            runkey=fullfile(strcat(project_derivative,'/',fmriprep_foldername,'/fmriprep/sub-',SSID{i},'/func/'),'*study*_space-MNI152*smoothAROMAnonaggr*.nii.gz');
            runfile=dir(runkey);
            substr=struct();
            substr.run=extractfield(runfile,'name');
            [~,~,raw]=xlsread(strcat(project_derivative,'/behavioral/sub-',SSID{i},'/',SSID{i},'_task-pscan_data.xlsx'));
            substr.postscan=raw;
            runevent=cell(0);
            for j=1:5 %loop through 5 runs
                task=regexp(substr.run{j},'task-\w*_','match');%this will return something like "task-localizer...._"
                run=regexp(substr.run{j},'run-\d\d_','match');
                substr.runevent{j}=load_event_test(project_derivative,strcat('sub-',SSID{i}),task,run,expstart_vol,TR);
                substr.runevent{j}(:,14)={j};%run number
                for s=1:size(substr.runevent{j},1)
                    if ~ismember(SSID{i},{'020','022'})%use normative data for these 2, otherwise use postscan ratings
                        postscan_rating=substr.postscan{strcmp(substr.postscan(:,6),substr.runevent{j}{s,10}),11};
                    else
                        %our stimuli (180 in total) has a
                        %normative rating ranging from 1.75 to
                        %8.95, the cutoffs were defined by
                        %evenly dividing that range into 5
                        %intervals
                        if substr.runevent{j}{s,3}<=3.19
                            postscan_rating='1';
                        elseif substr.runevent{j}{s,3}>3.19&&substr.runevent{j}{s,3}<=4.63
                            postscan_rating='2';
                        elseif substr.runevent{j}{s,3}>4.63&&substr.runevent{j}{s,3}<=6.07
                            postscan_rating='3';
                        elseif substr.runevent{j}{s,3}>6.07&&substr.runevent{j}{s,3}<=7.51
                            postscan_rating='4';
                        elseif substr.runevent{j}{s,3}>7.51
                            postscan_rating='5';
                        end
                    end
                    substr.runevent{j}{s,13}=postscan_rating;%replace with postscan ratings
                    substr.runevent{j}{s,15}=s;%trial number
                end
                %concatenate across runs
                runevent=[runevent;substr.runevent{j}];
            end
            
            pres_1=find(cellfun(@(x) mod(x,10),runevent(:,2))==1);
            pres_1_event=runevent(pres_1,:);
            
            %disregard trials without response, since we cannot be sure that
            %participants perceived the stimulus
            respnan=cellfun(@(x) isnan(x),pres_1_event(:,6),'UniformOutput',0);%more complicated than test phase because now the resp has more than one characters in each cell
            noresp_trials=cellfun(@(x) any(x), respnan);
            pres_1_event_resp=pres_1_event(~noresp_trials,:);
            
            %find different levels of lifetime
            life1=find(strcmp(pres_1_event_resp(:,13),'1'));
            life2=find(strcmp(pres_1_event_resp(:,13),'2'));
            life3=find(strcmp(pres_1_event_resp(:,13),'3'));
            life4=find(strcmp(pres_1_event_resp(:,13),'4'));
            life5=find(strcmp(pres_1_event_resp(:,13),'5'));
            
            %load the corresponding betas in the ROI
            if ~isempty(life1)
                for j=1:length(life1)
                    life1_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/task-study_run_',num2str(pres_1_event_resp{life1(j),14}),'/trial_',num2str(pres_1_event_resp{life1(j),15}),'/beta_0001.nii'));
                    life1_ROI_beta(j)=nanmean(life1_beta{j}(find(ROI)));%average beta within the ROI
                end
                sub_life1_ROI_beta{i,1}=nanmean(life1_ROI_beta);
                sub_life1_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life2)
                for j=1:length(life2)
                    life2_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/task-study_run_',num2str(pres_1_event_resp{life2(j),14}),'/trial_',num2str(pres_1_event_resp{life2(j),15}),'/beta_0001.nii'));
                    life2_ROI_beta(j)=nanmean(life2_beta{j}(find(ROI)));
                end
                sub_life2_ROI_beta{i,1}=nanmean(life2_ROI_beta);
                sub_life2_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life3)
                for j=1:length(life3)
                    life3_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/task-study_run_',num2str(pres_1_event_resp{life3(j),14}),'/trial_',num2str(pres_1_event_resp{life3(j),15}),'/beta_0001.nii'));
                    life3_ROI_beta(j)=nanmean(life3_beta{j}(find(ROI)));
                end
                sub_life3_ROI_beta{i,1}=nanmean(life3_ROI_beta);
                sub_life3_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life4)
                for j=1:length(life4)
                    life4_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/task-study_run_',num2str(pres_1_event_resp{life4(j),14}),'/trial_',num2str(pres_1_event_resp{life4(j),15}),'/beta_0001.nii'));
                    life4_ROI_beta(j)=nanmean(life4_beta{j}(find(ROI)));
                end
                sub_life4_ROI_beta{i,1}=nanmean(life4_ROI_beta);
                sub_life4_ROI_beta{i,2}=SSID{i};
            end
            
            if ~isempty(life5)
                for j=1:length(life5)
                    life5_beta{j}=niftiread(strcat(first_lvl_dir,'/sub-',SSID{i},'/temp/task-study_run_',num2str(pres_1_event_resp{life5(j),14}),'/trial_',num2str(pres_1_event_resp{life5(j),15}),'/beta_0001.nii'));
                    life5_ROI_beta(j)=nanmean(life5_beta{j}(find(ROI)));
                end
                sub_life5_ROI_beta{i,1}=nanmean(life5_ROI_beta);
                sub_life5_ROI_beta{i,2}=SSID{i};
            end
        end
        
        %% for plot, if statement checks for missing conditions
        if exist('sub_life1_ROI_beta','var') == 1
            sub_life1_ROI_beta_noemp=sub_life1_ROI_beta(~cellfun(@isempty, sub_life1_ROI_beta(:,1)));
            life1_avg=mean(cell2mat(sub_life1_ROI_beta_noemp),'omitnan');
            life1_se=std(cell2mat(sub_life1_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life1_ROI_beta_noemp));
            life1_sd=std(cell2mat(sub_life1_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life1_pres1.mat'),'life1_avg','life1_se','life1_sd','sub_life1_ROI_beta');
        end
        if exist('sub_life2_ROI_beta','var') == 1
            sub_life2_ROI_beta_noemp=sub_life2_ROI_beta(~cellfun(@isempty, sub_life2_ROI_beta(:,1)));
            life2_avg=mean(cell2mat(sub_life2_ROI_beta_noemp),'omitnan');
            life2_se=std(cell2mat(sub_life2_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life2_ROI_beta_noemp));
            life2_sd=std(cell2mat(sub_life2_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life2_pres1.mat'),'life2_avg','life2_se','life2_sd','sub_life2_ROI_beta');
        end
        if exist('sub_life3_ROI_beta','var') == 1
            sub_life3_ROI_beta_noemp=sub_life3_ROI_beta(~cellfun(@isempty, sub_life3_ROI_beta(:,1)));
            life3_avg=mean(cell2mat(sub_life3_ROI_beta_noemp),'omitnan');
            life3_se=std(cell2mat(sub_life3_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life3_ROI_beta_noemp));
            life3_sd=std(cell2mat(sub_life3_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life3_pres1.mat'),'life3_avg','life3_se','life3_sd','sub_life3_ROI_beta');
        end
        if exist('sub_life4_ROI_beta','var') == 1
            sub_life4_ROI_beta_noemp=sub_life4_ROI_beta(~cellfun(@isempty, sub_life4_ROI_beta(:,1)));
            life4_avg=mean(cell2mat(sub_life4_ROI_beta_noemp),'omitnan');
            life4_se=std(cell2mat(sub_life4_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life4_ROI_beta_noemp));
            life4_sd=std(cell2mat(sub_life4_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life4_pres1.mat'),'life4_avg','life4_se','life4_sd','sub_life4_ROI_beta');
        end
        if exist('sub_life5_ROI_beta','var') == 1
            sub_life5_ROI_beta_noemp=sub_life5_ROI_beta(~cellfun(@isempty, sub_life5_ROI_beta(:,1)));
            life5_avg=mean(cell2mat(sub_life5_ROI_beta_noemp),'omitnan');
            life5_se=std(cell2mat(sub_life5_ROI_beta_noemp),'omitnan')/sqrt(length(sub_life5_ROI_beta_noemp));
            life5_sd=std(cell2mat(sub_life5_ROI_beta_noemp),1,'omitnan');
            save(strcat(output_dir,'/',ROI_mask,'_life5_pres1.mat'),'life5_avg','life5_se','life5_sd','sub_life5_ROI_beta');
        end
end
end