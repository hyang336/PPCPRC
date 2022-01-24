%% correlate across participants the fMRI effect and the behavioral data
function corr_behav_2ndlvl(project_derivative,sublist,effect,output_dir)

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
        maskfile=strcat(prject_derivative,'/masks/abovethreshold_PrC_masks/studyphase_pres1vs789_dec/lPrC75_SVC_abovethreshold_mask.nii');
        mask=niftiread(maskfile);
        %calculate behavioral variable
        behav_folder=strcat(project_derivative,'/behavioral/');
        
        for i=1:length(SSID)
            conimg=niftiread(strcat(lvl1_folder,'/sub-',SSID{i},'/temp/con_0004.nii'))%con_0004 is the pres1vs789 contrast
            prc_con_val=nanmean(conimg(find(mask)));
            %behavioral part
            %[~,~,pscan]=xlsread(strcat(project_derivative,'/behavioral/sub-',SSID{i},'/',SSID{i},'_task-pscan_data.xlsx'));
            
            event=cell(0);
            for j=1:4 %loop through 4 runs
                %some hard-coded fields to load events
                task='task-study_';
                run=strcat('run-0',num2str(i),'_');
                expstart_vol=5;
                TR=2.5;
                
                runevent{j}=load_event_test(behav_folder,strcat('sub-',SSID{i}),{task},{run},expstart_vol,TR);
                runevent{j}(:,14)={j};%run number
                for s=1:size(runevent{j},1)
                    runevent{j}{s,15}=s;%trial number
                end
                %concatenate across runs
                event=[event;substr.runevent{j}];
            end
            %pull out presentation number
            pres1=cellfun(@(x) mod(x,10)==1,event(:,2));
            pres7=cellfun(@(x) mod(x,10)==7,event(:,2));
            pres8=cellfun(@(x) mod(x,10)==8,event(:,2));
            pres9=cellfun(@(x) mod(x,10)==8,event(:,2));
            
            %compute mean RT
            
        end
        
        %correlate across participants
        
        %output results
        
        
    case 'priming_fam'
        %extract contrast
        lvl1_folder=strcat(project_derivative,'/GLM_avgMask_pscan020022exclude/postscan_lifetime_softAROMA_const-epoch/');
        %prc mask
        maskfile=strcat(prject_derivative,'/masks/abovethreshold_PrC_masks/studyphase_lifetime_alltrial/lPrC75_SVC_abovethreshold_mask.nii');
        %calculate behavioral variable
        behav_folder=strcat(project_derivative,'/behavioral/');
        
        
    case 'mirror'
        %extract contrast
        lvl1_folder=strcat(project_derivative,'/GLM_avgMask_pscan020022exclude/test_1stlvl_postscan_softAROMA_const-epoch/');
        %prc mask
        maskfile=strcat(prject_derivative,'/masks/abovethreshold_PrC_masks/testphase_life-irr_conjunction_both_dec/lPrC75_SVC_global_null_abovethreshold_mask.nii');
        %calculate behavioral variable
        behav_folder=strcat(project_derivative,'/behavioral/');
        
end

end