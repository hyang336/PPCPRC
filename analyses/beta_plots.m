%% plot beta values within ROIs across conditions
% 2023-03-16 now saving standard deviation of the sample for bar plots
% since the se is missleading @Russ Poldrack
function beta_plots(first_lvl_folder,sublist,mask_dir,ROI_mask,output_dir)
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

for i=1:length(SSID)
    %load spm.mat
    spmmat=load(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/','SPM.mat'));
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
        sub_life_irr_1_ROI_beta{i,1}=nanmean(life_irr_1_ROI_beta);
        sub_life_irr_1_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life_irr_2_main_col)
        for j=1:length(life_irr_2_main_col)
            life_irr_2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_2_main_col(j),'%04.f'),'.nii'));
            life_irr_2_ROI_beta(j)=nanmean(life_irr_2_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_life_irr_2_ROI_beta{i,1}=nanmean(life_irr_2_ROI_beta);
        sub_life_irr_2_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life_irr_3_main_col)
        for j=1:length(life_irr_3_main_col)
            life_irr_3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_3_main_col(j),'%04.f'),'.nii'));
            life_irr_3_ROI_beta(j)=nanmean(life_irr_3_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_life_irr_3_ROI_beta{i,1}=nanmean(life_irr_3_ROI_beta);
        sub_life_irr_3_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life_irr_4_main_col)
        for j=1:length(life_irr_4_main_col)
            life_irr_4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_4_main_col(j),'%04.f'),'.nii'));
            life_irr_4_ROI_beta(j)=nanmean(life_irr_4_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_life_irr_4_ROI_beta{i,1}=nanmean(life_irr_4_ROI_beta);
        sub_life_irr_4_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life_irr_5_main_col)
        for j=1:length(life_irr_5_main_col)
            life_irr_5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life_irr_5_main_col(j),'%04.f'),'.nii'));
            life_irr_5_ROI_beta(j)=nanmean(life_irr_5_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_life_irr_5_ROI_beta{i,1}=nanmean(life_irr_5_ROI_beta);
        sub_life_irr_5_ROI_beta{i,2}=SSID{i};
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [~,life1_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_1*bf(1)'));
    [~,life2_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_2*bf(1)'));
    [~,life3_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_3*bf(1)'));
    [~,life4_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_4*bf(1)'));
    [~,life5_main_col]=find(contains(spmmat.SPM.xX.name(1,:),'lifetime_5*bf(1)'));
    %these long if-statement make sure we are useing the dec-rele GLM
    if ~isempty(life1_main_col)&&all([isempty(life_irr_1_main_col),isempty(life_irr_2_main_col),isempty(life_irr_3_main_col),isempty(life_irr_4_main_col),isempty(life_irr_5_main_col)])
        for j=1:length(life1_main_col)
            life1_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life1_main_col(j),'%04.f'),'.nii'));
            life1_ROI_beta(j)=nanmean(life1_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_life1_ROI_beta{i,1}=nanmean(life1_ROI_beta);
        sub_life1_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life2_main_col)&&all([isempty(life_irr_1_main_col),isempty(life_irr_2_main_col),isempty(life_irr_3_main_col),isempty(life_irr_4_main_col),isempty(life_irr_5_main_col)])
        for j=1:length(life2_main_col)
            life2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life2_main_col(j),'%04.f'),'.nii'));
            life2_ROI_beta(j)=nanmean(life2_beta{j}(find(ROI)));
        end
        sub_life2_ROI_beta{i,1}=nanmean(life2_ROI_beta);
        sub_life2_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life3_main_col)&&all([isempty(life_irr_1_main_col),isempty(life_irr_2_main_col),isempty(life_irr_3_main_col),isempty(life_irr_4_main_col),isempty(life_irr_5_main_col)])
        for j=1:length(life3_main_col)
            life3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life3_main_col(j),'%04.f'),'.nii'));
            life3_ROI_beta(j)=nanmean(life3_beta{j}(find(ROI)));
        end
        sub_life3_ROI_beta{i,1}=nanmean(life3_ROI_beta);
        sub_life3_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life4_main_col)&&all([isempty(life_irr_1_main_col),isempty(life_irr_2_main_col),isempty(life_irr_3_main_col),isempty(life_irr_4_main_col),isempty(life_irr_5_main_col)])
        for j=1:length(life4_main_col)
            life4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life4_main_col(j),'%04.f'),'.nii'));
            life4_ROI_beta(j)=nanmean(life4_beta{j}(find(ROI)));
        end
        sub_life4_ROI_beta{i,1}=nanmean(life4_ROI_beta);
        sub_life4_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(life5_main_col)&&all([isempty(life_irr_1_main_col),isempty(life_irr_2_main_col),isempty(life_irr_3_main_col),isempty(life_irr_4_main_col),isempty(life_irr_5_main_col)])
        for j=1:length(life5_main_col)
            life5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(life5_main_col(j),'%04.f'),'.nii'));
            life5_ROI_beta(j)=nanmean(life5_beta{j}(find(ROI)));
        end
        sub_life5_ROI_beta{i,1}=nanmean(life5_ROI_beta);
        sub_life5_ROI_beta{i,2}=SSID{i};
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
        sub_recent1_ROI_beta{i,1}=nanmean(recent1_ROI_beta);
        sub_recent1_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(recent2_main_col)
        for j=1:length(recent2_main_col)
            recent2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent2_main_col(j),'%04.f'),'.nii'));
            recent2_ROI_beta(j)=nanmean(recent2_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_recent2_ROI_beta{i,1}=nanmean(recent2_ROI_beta);
        sub_recent2_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(recent3_main_col)
        for j=1:length(recent3_main_col)
            recent3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent3_main_col(j),'%04.f'),'.nii'));
            recent3_ROI_beta(j)=nanmean(recent3_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_recent3_ROI_beta{i,1}=nanmean(recent3_ROI_beta);
        sub_recent3_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(recent4_main_col)
        for j=1:length(recent4_main_col)
            recent4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent4_main_col(j),'%04.f'),'.nii'));
            recent4_ROI_beta(j)=nanmean(recent4_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_recent4_ROI_beta{i,1}=nanmean(recent4_ROI_beta);
        sub_recent4_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(recent5_main_col)
        for j=1:length(recent5_main_col)
            recent5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(recent5_main_col(j),'%04.f'),'.nii'));
            recent5_ROI_beta(j)=nanmean(recent5_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_recent5_ROI_beta{i,1}=nanmean(recent5_ROI_beta);
        sub_recent5_ROI_beta{i,2}=SSID{i};
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [~,pres1_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_1*bf(1)'));
    [~,pres2_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_2*bf(1)'));
    [~,pres3_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_3*bf(1)'));
    [~,pres4_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_4*bf(1)'));
    [~,pres5_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_5*bf(1)'));
    [~,pres6_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_6*bf(1)'));
    [~,pres7_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_7*bf(1)'));
    [~,pres8_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_8*bf(1)'));
    [~,pres9_col]=find(contains(spmmat.SPM.xX.name(1,:),'pres_9*bf(1)'));
    if ~isempty(pres1_col)
        for j=1:length(pres1_col)
            pres1_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres1_col(j),'%04.f'),'.nii'));
            pres1_ROI_beta(j)=nanmean(pres1_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres1_ROI_beta{i,1}=nanmean(pres1_ROI_beta);
        sub_pres1_ROI_beta{i,2}=SSID{i};
    end

    if ~isempty(pres2_col)
        for j=1:length(pres2_col)
            pres2_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres2_col(j),'%04.f'),'.nii'));
            pres2_ROI_beta(j)=nanmean(pres2_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres2_ROI_beta{i,1}=nanmean(pres2_ROI_beta);
        sub_pres2_ROI_beta{i,2}=SSID{i};
    end

    if ~isempty(pres3_col)
        for j=1:length(pres3_col)
            pres3_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres3_col(j),'%04.f'),'.nii'));
            pres3_ROI_beta(j)=nanmean(pres3_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres3_ROI_beta{i,1}=nanmean(pres3_ROI_beta);
        sub_pres3_ROI_beta{i,2}=SSID{i};
    end

    if ~isempty(pres4_col)
        for j=1:length(pres4_col)
            pres4_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres4_col(j),'%04.f'),'.nii'));
            pres4_ROI_beta(j)=nanmean(pres4_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres4_ROI_beta{i,1}=nanmean(pres4_ROI_beta);
        sub_pres4_ROI_beta{i,2}=SSID{i};
    end

    if ~isempty(pres5_col)
        for j=1:length(pres5_col)
            pres5_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres5_col(j),'%04.f'),'.nii'));
            pres5_ROI_beta(j)=nanmean(pres5_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres5_ROI_beta{i,1}=nanmean(pres5_ROI_beta);
        sub_pres5_ROI_beta{i,2}=SSID{i};
    end

    if ~isempty(pres6_col)
        for j=1:length(pres6_col)
            pres6_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres6_col(j),'%04.f'),'.nii'));
            pres6_ROI_beta(j)=nanmean(pres6_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres6_ROI_beta{i,1}=nanmean(pres6_ROI_beta);
        sub_pres6_ROI_beta{i,2}=SSID{i};
    end

    if ~isempty(pres7_col)
        for j=1:length(pres7_col)
            pres7_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres7_col(j),'%04.f'),'.nii'));
            pres7_ROI_beta(j)=nanmean(pres7_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres7_ROI_beta{i,1}=nanmean(pres7_ROI_beta);
        sub_pres7_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(pres8_col)
        for j=1:length(pres8_col)
            pres8_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres8_col(j),'%04.f'),'.nii'));
            pres8_ROI_beta(j)=nanmean(pres8_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres8_ROI_beta{i,1}=nanmean(pres8_ROI_beta);
        sub_pres8_ROI_beta{i,2}=SSID{i};
    end


    if ~isempty(pres9_col)
        for j=1:length(pres9_col)
            pres9_beta{j}=niftiread(strcat(first_lvl_folder,'/sub-',SSID{i},'/temp/beta_',num2str(pres9_col(j),'%04.f'),'.nii'));
            pres9_ROI_beta(j)=nanmean(pres9_beta{j}(find(ROI)));%average beta within the ROI
        end
        sub_pres9_ROI_beta{i,1}=nanmean(pres9_ROI_beta);
        sub_pres9_ROI_beta{i,2}=SSID{i};
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end
%% for plot
if exist('sub_life1_ROI_beta','var') == 1
    life1_avg=mean(cell2mat(sub_life1_ROI_beta(:,1)));
    life1_se=std(cell2mat(sub_life1_ROI_beta(:,1)))/sqrt(length(sub_life1_ROI_beta(:,1)));
    life1_sd=std(cell2mat(sub_life1_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_life1.mat'),'life1_avg','life1_se','life1_sd','sub_life1_ROI_beta');
end
if exist('sub_life2_ROI_beta','var') == 1
    life2_avg=mean(cell2mat(sub_life2_ROI_beta(:,1)));
    life2_se=std(cell2mat(sub_life2_ROI_beta(:,1)))/sqrt(length(sub_life2_ROI_beta(:,1)));
    life2_sd=std(cell2mat(sub_life2_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_life2.mat'),'life2_avg','life2_se','life2_sd','sub_life2_ROI_beta');
end
if exist('sub_life3_ROI_beta','var') == 1
    life3_avg=mean(cell2mat(sub_life3_ROI_beta(:,1)));
    life3_se=std(cell2mat(sub_life3_ROI_beta(:,1)))/sqrt(length(sub_life3_ROI_beta(:,1)));
    life3_sd=std(cell2mat(sub_life3_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_life3.mat'),'life3_avg','life3_se','life3_sd','sub_life3_ROI_beta');
end
if exist('sub_life4_ROI_beta','var') == 1
    life4_avg=mean(cell2mat(sub_life4_ROI_beta(:,1)));
    life4_se=std(cell2mat(sub_life4_ROI_beta(:,1)))/sqrt(length(sub_life4_ROI_beta(:,1)));
    life4_sd=std(cell2mat(sub_life4_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_life4.mat'),'life4_avg','life4_se','life4_sd','sub_life4_ROI_beta');
end
if exist('sub_life5_ROI_beta','var') == 1
    life5_avg=mean(cell2mat(sub_life5_ROI_beta(:,1)));
    life5_se=std(cell2mat(sub_life5_ROI_beta(:,1)))/sqrt(length(sub_life5_ROI_beta(:,1)));
    life5_sd=std(cell2mat(sub_life5_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_life5.mat'),'life5_avg','life5_se','life5_sd','sub_life5_ROI_beta');
end


% errorbar((1:5),[life1_avg,life2_avg,life3_avg,life4_avg,life5_avg],[life1_se,life2_se,life3_se,life4_se,life5_se]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('sub_recent1_ROI_beta','var') == 1
    recent1_avg=mean(cell2mat(sub_recent1_ROI_beta(:,1)));
    recent1_se=std(cell2mat(sub_recent1_ROI_beta(:,1)))/sqrt(length(sub_recent1_ROI_beta(:,1)));
    recent1_sd=std(cell2mat(sub_recent1_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_recent1.mat'),'recent1_avg','recent1_se','recent1_sd','sub_recent1_ROI_beta');
end

if exist('sub_recent2_ROI_beta','var') == 1
    recent2_avg=mean(cell2mat(sub_recent2_ROI_beta(:,1)));
    recent2_se=std(cell2mat(sub_recent2_ROI_beta(:,1)))/sqrt(length(sub_recent2_ROI_beta(:,1)));
    recent2_sd=std(cell2mat(sub_recent2_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_recent2.mat'),'recent2_avg','recent2_se','recent2_sd','sub_recent2_ROI_beta');
end

if exist('sub_recent3_ROI_beta','var') == 1
    recent3_avg=mean(cell2mat(sub_recent3_ROI_beta(:,1)));
    recent3_se=std(cell2mat(sub_recent3_ROI_beta(:,1)))/sqrt(length(sub_recent3_ROI_beta(:,1)));
    recent3_sd=std(cell2mat(sub_recent3_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_recent3.mat'),'recent3_avg','recent3_se','recent3_sd','sub_recent3_ROI_beta');
end

if exist('sub_recent4_ROI_beta','var') == 1
    recent4_avg=mean(cell2mat(sub_recent4_ROI_beta(:,1)));
    recent4_se=std(cell2mat(sub_recent4_ROI_beta(:,1)))/sqrt(length(sub_recent4_ROI_beta(:,1)));
    recent4_sd=std(cell2mat(sub_recent4_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_recent4.mat'),'recent4_avg','recent4_se','recent4_sd','sub_recent4_ROI_beta');
end

if exist('sub_recent5_ROI_beta','var') == 1
    recent5_avg=mean(cell2mat(sub_recent5_ROI_beta(:,1)));
    recent5_se=std(cell2mat(sub_recent5_ROI_beta(:,1)))/sqrt(length(sub_recent5_ROI_beta(:,1)));
    recent5_sd=std(cell2mat(sub_recent5_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_recent5.mat'),'recent5_avg','recent5_se','recent5_sd','sub_recent5_ROI_beta');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('sub_life_irr_1_ROI_beta','var') == 1

    sub_life_irr_1_ROI_beta_noemp=sub_life_irr_1_ROI_beta(~cellfun(@isempty, sub_life_irr_1_ROI_beta(:,1)));
    life_irr_1_avg=mean(cell2mat(sub_life_irr_1_ROI_beta_noemp));
    life_irr_1_se=std(cell2mat(sub_life_irr_1_ROI_beta_noemp))/sqrt(length(sub_life_irr_1_ROI_beta_noemp));
    life_irr_1_sd=std(cell2mat(sub_life_irr_1_ROI_beta_noemp),1);
    save(strcat(output_dir,'/',ROI_mask,'_life_irr_1.mat'),'life_irr_1_avg','life_irr_1_se','life_irr_1_sd','sub_life_irr_1_ROI_beta');
end

if exist('sub_life_irr_2_ROI_beta','var') == 1
    sub_life_irr_2_ROI_beta_noemp=sub_life_irr_2_ROI_beta(~cellfun(@isempty,sub_life_irr_2_ROI_beta(:,1)));
    life_irr_2_avg=mean(cell2mat(sub_life_irr_2_ROI_beta_noemp));
    life_irr_2_se=std(cell2mat(sub_life_irr_2_ROI_beta_noemp))/sqrt(length(sub_life_irr_2_ROI_beta_noemp));
    life_irr_2_sd=std(cell2mat(sub_life_irr_2_ROI_beta_noemp),1);
    save(strcat(output_dir,'/',ROI_mask,'_life_irr_2.mat'),'life_irr_2_avg','life_irr_2_se','life_irr_2_sd','sub_life_irr_2_ROI_beta');
end

if exist('sub_life_irr_3_ROI_beta','var') == 1
    sub_life_irr_3_ROI_beta_noemp=sub_life_irr_3_ROI_beta(~cellfun(@isempty,sub_life_irr_3_ROI_beta(:,1)));
    life_irr_3_avg=mean(cell2mat(sub_life_irr_3_ROI_beta_noemp));
    life_irr_3_se=std(cell2mat(sub_life_irr_3_ROI_beta_noemp))/sqrt(length(sub_life_irr_3_ROI_beta_noemp));
    life_irr_3_sd=std(cell2mat(sub_life_irr_3_ROI_beta_noemp),1);
    save(strcat(output_dir,'/',ROI_mask,'_life_irr_3.mat'),'life_irr_3_avg','life_irr_3_se','life_irr_3_sd','sub_life_irr_3_ROI_beta');
end

if exist('sub_life_irr_4_ROI_beta','var') == 1
    sub_life_irr_4_ROI_beta_noemp=sub_life_irr_4_ROI_beta(~cellfun(@isempty,sub_life_irr_4_ROI_beta(:,1)));
    life_irr_4_avg=mean(cell2mat(sub_life_irr_4_ROI_beta_noemp));
    life_irr_4_se=std(cell2mat(sub_life_irr_4_ROI_beta_noemp))/sqrt(length(sub_life_irr_4_ROI_beta_noemp));
    life_irr_4_sd=std(cell2mat(sub_life_irr_4_ROI_beta_noemp),1);
    save(strcat(output_dir,'/',ROI_mask,'_life_irr_4.mat'),'life_irr_4_avg','life_irr_4_se','life_irr_4_sd','sub_life_irr_4_ROI_beta');
end

if exist('sub_life_irr_5_ROI_beta','var') == 1
    sub_life_irr_5_ROI_beta_noemp=sub_life_irr_5_ROI_beta(~cellfun(@isempty,sub_life_irr_5_ROI_beta(:,1)));
    life_irr_5_avg=mean(cell2mat(sub_life_irr_5_ROI_beta_noemp));
    life_irr_5_se=std(cell2mat(sub_life_irr_5_ROI_beta_noemp))/sqrt(length(sub_life_irr_5_ROI_beta_noemp));
    life_irr_5_sd=std(cell2mat(sub_life_irr_5_ROI_beta_noemp),1);
    save(strcat(output_dir,'/',ROI_mask,'_life_irr_5.mat'),'life_irr_5_avg','life_irr_5_se','life_irr_5_sd','sub_life_irr_5_ROI_beta');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('sub_pres1_ROI_beta','var') == 1
    pres1_avg=mean(cell2mat(sub_pres1_ROI_beta(:,1)));
    pres1_se=std(cell2mat(sub_pres1_ROI_beta(:,1)))/sqrt(length(sub_pres1_ROI_beta(:,1)));
    pres1_sd=std(cell2mat(sub_pres1_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres1.mat'),'pres1_avg','pres1_se','pres1_sd','sub_pres1_ROI_beta');
end

if exist('sub_pres2_ROI_beta','var') == 1
    pres2_avg=mean(cell2mat(sub_pres2_ROI_beta(:,1)));
    pres2_se=std(cell2mat(sub_pres2_ROI_beta(:,1)))/sqrt(length(sub_pres2_ROI_beta(:,1)));
    pres2_sd=std(cell2mat(sub_pres2_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres2.mat'),'pres2_avg','pres2_se',"pres2_sd",'sub_pres2_ROI_beta');
end

if exist('sub_pres3_ROI_beta','var') == 1
    pres3_avg=mean(cell2mat(sub_pres3_ROI_beta(:,1)));
    pres3_se=std(cell2mat(sub_pres3_ROI_beta(:,1)))/sqrt(length(sub_pres3_ROI_beta(:,1)));
    pres3_sd=std(cell2mat(sub_pres3_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres3.mat'),'pres3_avg','pres3_se','pres3_sd','sub_pres3_ROI_beta');
end

if exist('sub_pres4_ROI_beta','var') == 1
    pres4_avg=mean(cell2mat(sub_pres4_ROI_beta(:,1)));
    pres4_se=std(cell2mat(sub_pres4_ROI_beta(:,1)))/sqrt(length(sub_pres4_ROI_beta(:,1)));
    pres4_sd=std(cell2mat(sub_pres4_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres4.mat'),'pres4_avg','pres4_se','pres4_sd','sub_pres4_ROI_beta');
end

if exist('sub_pres5_ROI_beta','var') == 1
    pres5_avg=mean(cell2mat(sub_pres5_ROI_beta(:,1)));
    pres5_se=std(cell2mat(sub_pres5_ROI_beta(:,1)))/sqrt(length(sub_pres5_ROI_beta(:,1)));
    pres5_sd=std(cell2mat(sub_pres5_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres5.mat'),'pres5_avg','pres5_se','pres5_sd','sub_pres5_ROI_beta');
end

if exist('sub_pres6_ROI_beta','var') == 1
    pres6_avg=mean(cell2mat(sub_pres6_ROI_beta(:,1)));
    pres6_se=std(cell2mat(sub_pres6_ROI_beta(:,1)))/sqrt(length(sub_pres6_ROI_beta(:,1)));
    pres6_sd=std(cell2mat(sub_pres6_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres6.mat'),'pres6_avg','pres6_se','pres6_sd','sub_pres6_ROI_beta');
end

if exist('sub_pres7_ROI_beta','var') == 1
    pres7_avg=mean(cell2mat(sub_pres7_ROI_beta(:,1)));
    pres7_se=std(cell2mat(sub_pres7_ROI_beta(:,1)))/sqrt(length(sub_pres7_ROI_beta(:,1)));
    pres7_sd=std(cell2mat(sub_pres7_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres7.mat'),'pres7_avg','pres7_se','pres7_sd','sub_pres7_ROI_beta');
end

if exist('sub_pres8_ROI_beta','var') == 1
    pres8_avg=mean(cell2mat(sub_pres8_ROI_beta(:,1)));
    pres8_se=std(cell2mat(sub_pres8_ROI_beta(:,1)))/sqrt(length(sub_pres8_ROI_beta(:,1)));
    pres8_sd=std(cell2mat(sub_pres8_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres8.mat'),'pres8_avg','pres8_se','pres8_sd','sub_pres8_ROI_beta');
end

if exist('sub_pres9_ROI_beta','var') == 1
    pres9_avg=mean(cell2mat(sub_pres9_ROI_beta(:,1)));
    pres9_se=std(cell2mat(sub_pres9_ROI_beta(:,1)))/sqrt(length(sub_pres9_ROI_beta(:,1)));
    pres9_sd=std(cell2mat(sub_pres9_ROI_beta(:,1)),1);
    save(strcat(output_dir,'/',ROI_mask,'_pres9.mat'),'pres9_avg','pres9_se','pres9_sd','sub_pres9_ROI_beta');
end

end