%% correlate across participants the fMRI effect and the behavioral data
function [r,p]=corr_behav_2ndlvl(project_derivative,sublist,effect)

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

switch effect
    case 'priming_freq'
        %extract contrast
        lvl1_folder=strcat(project_derivative,'/GLM_avgMask_4mmSmooth/repetition_suppression_softAROMA/');
        %prc mask
        maskfile=strcat(project_derivative,'/masks/abovethreshold_PrC_masks/studyphase_pres1vs789_dec/lPrC75_SVC_abovethreshold_mask.nii');
        mask=niftiread(maskfile);
        %calculate behavioral variable
        behav_folder=strcat(project_derivative,'/behavioral/');
        prime_res=cell(0,3);
        for i=1:length(SSID)
            conimg=niftiread(strcat(lvl1_folder,'/sub-',SSID{i},'/temp/con_0004.nii'));%con_0004 is the pres1vs789 contrast
            prc_con_val=nanmean(conimg(find(mask)));
            %behavioral part
            %[~,~,pscan]=xlsread(strcat(project_derivative,'/behavioral/sub-',SSID{i},'/',SSID{i},'_task-pscan_data.xlsx'));
            
            event=cell(0);
            for j=1:5 %loop through 4 runs
                %some hard-coded fields to load events
                task='task-study_';
                run=strcat('run-0',num2str(j),'_');
                expstart_vol=5;
                TR=2.5;
                
                runevent=load_event_test(project_derivative,strcat('sub-',SSID{i}),{task},{run},expstart_vol,TR);
                runevent(:,14)={j};%run number
                for s=1:size(runevent,1)
                    runevent{s,15}=s;%trial number
                end
                %concatenate across runs
                event=[event;runevent];
            end
            
            %remove noresp trials, the prc con img should have that
            %taken care of in SPM
            event=event(~cellfun(@(x) isnan(x),event(:,7)),:);
            
            %regress RT on presentation number and extract slope
            b1=mod(cell2mat(event(:,2)),10)\cell2mat(event(:,7));
            
            %compile results
            prime_res(i,1)=SSID(i);
            prime_res(i,2)={prc_con_val};
            prime_res(i,3)={b1};
        end
        
        %correlate across participants
        [r,p]=corrcoef(cell2mat(prime_res(:,2)),cell2mat(prime_res(:,3)));
        %output results
        sprintf('\nThe correlation coefficient is %0.3f, the p-value is %0.3f', r, p);
        
    case 'priming_fam'
        %extract contrast
        lvl1_folder=strcat(project_derivative,'/GLM_avgMask_pscan020022exclude/postscan_lifetime_softAROMA_const-epoch/');
        %prc mask
        maskfile=strcat(project_derivative,'/masks/abovethreshold_PrC_masks/studyphase_lifetime_alltrial/lPrC75_SVC_abovethreshold_mask.nii');
        mask=niftiread(maskfile);
        %calculate behavioral variable
        behav_folder=strcat(project_derivative,'/behavioral/');
        prime_res=cell(0,3);
        for i=1:length(SSID)
            conimg=niftiread(strcat(lvl1_folder,'/sub-',SSID{i},'/temp/con_0001.nii'));%con_0001 is the lifetime_dec contrast
            prc_con_val=nanmean(conimg(find(mask)));
            %behavioral part
            [~,~,pscan]=xlsread(strcat(behav_folder,'sub-',SSID{i},'/',SSID{i},'_task-pscan_data.xlsx'));
            
            event=cell(0);
            for j=1:5 %loop through 4 runs
                %some hard-coded fields to load events
                task='task-study_';
                run=strcat('run-0',num2str(j),'_');
                expstart_vol=5;
                TR=2.5;
                
                runevent=load_event_test(project_derivative,strcat('sub-',SSID{i}),{task},{run},expstart_vol,TR);
                runevent(:,14)={j};%run number
                for s=1:size(runevent,1)
                    runevent{s,15}=s;%trial number
                end
                [o,l]=ismember(runevent(:,10),pscan(:,6));%find stimuli
                runevent(:,13)=pscan(l,11);%fill in post-scan ratings
                %concatenate across runs
                event=[event;runevent];
            end
            
            %remove noresp trials, the prc con img should have that
            %taken care of in SPM
            event=event(~cellfun(@(x) isnan(x),event(:,7)),:);
            
            %find trials with no pscan ratings and replace it with
            %normative rating
            emp_trial=cellfun(@(x) isempty(x),event(:,13));
            %logical index of norm ratings
            norm1=cellfun(@(x)x<=3.19,event(:,3));
            norm2=cellfun(@(x)x>3.19&&x<=4.63,event(:,3));
            norm3=cellfun(@(x)x>4.63&&x<=6.07,event(:,3));
            norm4=cellfun(@(x)x>6.07&&x<=7.51,event(:,3));
            norm5=cellfun(@(x)x>7.51,event(:,3));
            
            %loop over trial and replace with norm (rescaled) ratings
            for trial=1:size(event,1)
                if emp_trial(trial)&norm1(trial)
                    event(trial,13)={'1'};
                elseif emp_trial(trial)&norm2(trial)
                    event(trial,13)={'2'};
                elseif emp_trial(trial)&norm3(trial)
                    event(trial,13)={'3'};
                elseif emp_trial(trial)&norm4(trial)
                    event(trial,13)={'4'};
                elseif emp_trial(trial)&norm5(trial)
                    event(trial,13)={'5'};
                end
            end

            %regress RT on lifetime and extract slope, for the two outliers
            %need to use normative data
            if ~ismember(SSID{i},{'020','022'})
                b1=str2num(cell2mat(event(:,13)))\cell2mat(event(:,7));
            else
                b1=cell2mat(event(:,3))\cell2mat(event(:,7));
            end
            
            
            %compile results
            prime_res(i,1)=SSID(i);
            prime_res(i,2)={prc_con_val};
            prime_res(i,3)={b1};
        end
        
        %correlate across participants
        [r,p]=corrcoef(cell2mat(prime_res(:,2)),cell2mat(prime_res(:,3)));
        %output results
        sprintf('\nThe correlation coefficient is %0.3f, the p-value is %0.3f', r, p);
        
    case 'mirror'
        %extract contrast
        lvl1_folder=strcat(project_derivative,'/GLM_avgMask_pscan020022exclude/test_1stlvl_postscan_softAROMA_const-epoch/');
        %prc mask
        maskfile=strcat(project_derivative,'/masks/abovethreshold_PrC_masks/testphase_life-irr_conjunction_both_dec/lPrC75_SVC_global_null_abovethreshold_mask.nii');
        mask=niftiread(maskfile);
        %calculate behavioral variable
        behav_folder=strcat(project_derivative,'/behavioral/');
        prime_res=cell(0,3);
        for i=1:length(SSID)
            conimg=niftiread(strcat(lvl1_folder,'/sub-',SSID{i},'/temp/con_0001.nii'));%con_0001 is the lifetime_dec contrast
            prc_con_val=nanmean(conimg(find(mask)));
            %behavioral part
            [~,~,pscan]=xlsread(strcat(behav_folder,'sub-',SSID{i},'/',SSID{i},'_task-pscan_data.xlsx'));
            
            event=cell(0);
            for j=1:4 %loop through 4 runs
                %some hard-coded fields to load events
                task='task-test_';
                run=strcat('run-0',num2str(j),'_');
                expstart_vol=5;
                TR=2.5;
                
                runevent=load_event_test(project_derivative,strcat('sub-',SSID{i}),{task},{run},expstart_vol,TR);
                runevent(:,14)={j};%run number
                for s=1:size(runevent,1)
                    runevent{s,15}=s;%trial number
                end
                [o,l]=ismember(runevent(:,10),pscan(:,6));%find stimuli
                runevent(:,13)=pscan(l,11);%fill in post-scan ratings
                %concatenate across runs
                event=[event;runevent];
            end
            
            %remove noresp trials, the prc con img should have that
            %taken care of in SPM
            event=event(~cellfun(@(x) isnan(x),event(:,7)),:);
            
            %find trials with no pscan ratings and replace it with
            %normative rating
            emp_trial=cellfun(@(x) isempty(x),event(:,13));
            %logical index of norm ratings
            norm1=cellfun(@(x)x<=3.19,event(:,3));
            norm2=cellfun(@(x)x>3.19&&x<=4.63,event(:,3));
            norm3=cellfun(@(x)x>4.63&&x<=6.07,event(:,3));
            norm4=cellfun(@(x)x>6.07&&x<=7.51,event(:,3));
            norm5=cellfun(@(x)x>7.51,event(:,3));
            
            %loop over trial and replace with norm (rescaled) ratings
            for trial=1:size(event,1)
                if emp_trial(trial)&norm1(trial)
                    event(trial,13)={'1'};
                elseif emp_trial(trial)&norm2(trial)
                    event(trial,13)={'2'};
                elseif emp_trial(trial)&norm3(trial)
                    event(trial,13)={'3'};
                elseif emp_trial(trial)&norm4(trial)
                    event(trial,13)={'4'};
                elseif emp_trial(trial)&norm5(trial)
                    event(trial,13)={'5'};
                end
            end
            
            %regress freq_error on lifetime and extract slope, for the two outliers
            %need to use normative data
            freq_error=str2num(cell2mat(event(:,6)))-rescale(cell2mat(event(:,2)),1,5);
            if ~ismember(SSID{i},{'020','022'})
                b1=str2num(cell2mat(event(:,13)))\freq_error;
            else
                b1=cell2mat(event(:,3))\freq_error;
            end
            
            %compile results
            prime_res(i,1)=SSID(i);
            prime_res(i,2)={prc_con_val};
            prime_res(i,3)={b1};
        end
        
        %correlate across participants
        [r,p]=corrcoef(cell2mat(prime_res(:,2)),cell2mat(prime_res(:,3)));
        %output results
        sprintf('\nThe correlation coefficient is %0.3f, the p-value is %0.3f', r, p);
end
end