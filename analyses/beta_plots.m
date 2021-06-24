%% plot beta values within ROIs across conditions

function beta_plots(first_lvl_folder,sublist,ROI_mask)
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
    ROI=niftiread(ROI_mask);
    
    for i=1:length(SSID)
        %load spm.mat
        spmmat=load(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/','SPM.mat'));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        [~,life1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
        [~,life2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
        [~,life3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
        [~,life4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
        [~,life5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));
        if ~isempty(life1_main_col)
            for j=1:length(life1_main_col)
                life1_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life1_main_col(j),'%04.f'),'.nii'));
                life1_ROI_beta(j)=nanmean(life1_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_life1_ROI_beta{i}=nanmean(life1_ROI_beta);
        end
        
        
        if ~isempty(life2_main_col)
            for j=1:length(life2_main_col)
                life2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life2_main_col(j),'%04.f'),'.nii'));
                life2_ROI_beta(j)=nanmean(life2_beta{j}(find(ROI)));
            end
            sub_life2_ROI_beta{i}=nanmean(life2_ROI_beta);
        end
        
        
        if ~isempty(life3_main_col)
            for j=1:length(life3_main_col)
                life3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life3_main_col(j),'%04.f'),'.nii'));
                life3_ROI_beta(j)=nanmean(life3_beta{j}(find(ROI)));
            end
            sub_life3_ROI_beta{i}=nanmean(life3_ROI_beta);
        end
        
        
        if ~isempty(life4_main_col)
            for j=1:length(life4_main_col)
                life4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life4_main_col(j),'%04.f'),'.nii'));
                life4_ROI_beta(j)=nanmean(life4_beta{j}(find(ROI)));
            end
            sub_life4_ROI_beta{i}=nanmean(life4_ROI_beta);
        end
        
        
        if ~isempty(life5_main_col)
            for j=1:length(life5_main_col)
                life5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life5_main_col(j),'%04.f'),'.nii'));
                life5_ROI_beta(j)=nanmean(life5_beta{j}(find(ROI)));
            end
            sub_life5_ROI_beta{i}=nanmean(life5_ROI_beta);
        end
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        [~,recent1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_1*bf(1)'));
        [~,recent2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_2*bf(1)'));
        [~,recent3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_3*bf(1)'));
        [~,recent4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_4*bf(1)'));
        [~,recent5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'recent_5*bf(1)'));
        if ~isempty(recent1_main_col)
            for j=1:length(recent1_main_col)
                recent1_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent1_main_col(j),'%04.f'),'.nii'));
                recent1_ROI_beta(j)=nanmean(recent1_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_recent1_ROI_beta{i}=nanmean(recent1_ROI_beta);
        end
        
        
        if ~isempty(recent2_main_col)
            for j=1:length(recent2_main_col)
                recent2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent2_main_col(j),'%04.f'),'.nii'));
                recent2_ROI_beta(j)=nanmean(recent2_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_recent2_ROI_beta{i}=nanmean(recent2_ROI_beta);
        end
        
        
        if ~isempty(recent3_main_col)
            for j=1:length(recent3_main_col)
                recent3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent3_main_col(j),'%04.f'),'.nii'));
                recent3_ROI_beta(j)=nanmean(recent3_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_recent3_ROI_beta{i}=nanmean(recent3_ROI_beta);
        end
        
        
        if ~isempty(recent4_main_col)
            for j=1:length(recent4_main_col)
                recent4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent4_main_col(j),'%04.f'),'.nii'));
                recent4_ROI_beta(j)=nanmean(recent4_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_recent4_ROI_beta{i}=nanmean(recent4_ROI_beta);
        end
        
        
        if ~isempty(recent5_main_col)
            for j=1:length(recent5_main_col)
                recent5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent5_main_col(j),'%04.f'),'.nii'));
                recent5_ROI_beta(j)=nanmean(recent5_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_recent5_ROI_beta{i}=nanmean(recent5_ROI_beta);
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        [~,life_irr_1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_1*bf(1)'));
        [~,life_irr_2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_2*bf(1)'));
        [~,life_irr_3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_3*bf(1)'));
        [~,life_irr_4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_4*bf(1)'));
        [~,life_irr_5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_irr_5*bf(1)'));
        if ~isempty(life_irr_1_main_col)
            for j=1:length(life_irr_1_main_col)
                life_irr_1_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_1_main_col(j),'%04.f'),'.nii'));
                life_irr_1_ROI_beta(j)=nanmean(life_irr_1_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_life_irr_1_ROI_beta{i}=nanmean(life_irr_1_ROI_beta);
        end
        
        
        if ~isempty(life_irr_2_main_col)
            for j=1:length(life_irr_2_main_col)
                life_irr_2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_2_main_col(j),'%04.f'),'.nii'));
                life_irr_2_ROI_beta(j)=nanmean(life_irr_2_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_life_irr_2_ROI_beta{i}=nanmean(life_irr_2_ROI_beta);
        end
        
        
        if ~isempty(life_irr_3_main_col)
            for j=1:length(life_irr_3_main_col)
                life_irr_3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_3_main_col(j),'%04.f'),'.nii'));
                life_irr_3_ROI_beta(j)=nanmean(life_irr_3_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_life_irr_3_ROI_beta{i}=nanmean(life_irr_3_ROI_beta);
        end
        
        
        if ~isempty(life_irr_4_main_col)
            for j=1:length(life_irr_4_main_col)
                life_irr_4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_4_main_col(j),'%04.f'),'.nii'));
                life_irr_4_ROI_beta(j)=nanmean(life_irr_4_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_life_irr_4_ROI_beta{i}=nanmean(life_irr_4_ROI_beta);
        end
        
        
        if ~isempty(life_irr_5_main_col)
            for j=1:length(life_irr_5_main_col)
                life_irr_5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_5_main_col(j),'%04.f'),'.nii'));
                life_irr_5_ROI_beta(j)=nanmean(life_irr_5_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_life_irr_5_ROI_beta{i}=nanmean(life_irr_5_ROI_beta);
        end
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        [~,pres1_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_1*bf(1)'));
        [~,pres7_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_7*bf(1)'));
        [~,pres8_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_8*bf(1)'));
        [~,pres9_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_9*bf(1)'));
        if ~isempty(pres1_col)
            for j=1:length(pres1_col)
                pres1_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres1_col(j),'%04.f'),'.nii'));
                pres1_ROI_beta(j)=nanmean(pres1_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_pres1_ROI_beta{i}=nanmean(pres1_ROI_beta);
        end
        
        
        if ~isempty(pres7_col)
            for j=1:length(pres7_col)
                pres7_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres7_col(j),'%04.f'),'.nii'));
                pres7_ROI_beta(j)=nanmean(pres7_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_pres7_ROI_beta{i}=nanmean(pres7_ROI_beta);
        end
        
        
        if ~isempty(pres8_col)
            for j=1:length(pres8_col)
                pres8_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres8_col(j),'%04.f'),'.nii'));
                pres8_ROI_beta(j)=nanmean(pres8_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_pres8_ROI_beta{i}=nanmean(pres8_ROI_beta);
        end
        
        
        if ~isempty(pres9_col)
            for j=1:length(pres9_col)
                pres9_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres9_col(j),'%04.f'),'.nii'));
                pres9_ROI_beta(j)=nanmean(pres9_beta{j}(find(ROI)));%average beta within the ROI
            end
            sub_pres9_ROI_beta{i}=nanmean(pres9_ROI_beta);
        end
        
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        

    end
%% plot

end