%% use the PrC mask generated with ASHS to find voxel with the highest contrast value and t-value
function maxPrC_lifetime=test_max_in_PrC(contrast_folder,sublist,maskfolder)
    %read in subject IDs
    fid=fopen(sublist,'r');
    tline=fgetl(fid);
    SSID=cell(0,1);
    while ischar(tline)
        SSID{end+1,1}=tline;
        tline=fgetl(fid);
    end
    fclose(fid);
    
    maxPrC_lifetime=cell(length(SSID),3)
    for i=1:length(SSID)
        %find contrast file
        lifetime_main_con=niftiread(strcat(contrast_folder,'/test_1stlvl_softAROMA/sub-',SSID{i},'/temp/con_0001.nii'));
        %find t-file
        lifetime_main_t=niftiread(strcat(contrast_folder,'/test_1stlvl_softAROMA/sub-',SSID{i},'/temp/spmT_0001.nii'));
        %find PrC mask in MNINLin6
        PrC_mask=niftiread(strcat(maskfolder,'/sub-',SSID{i},'/final/sub-',SSID{i},'_PRC_MNINLin6_resampled.nii'));
        %extract PrC contrast and t-map
        PrC_lifetime_main_con=lifetime_main_con(find(PrC_mask));
        PrC_lifetime_main_t=lifetime_main_t(find(PrC_mask));
        %find max
        maxPrC_lifetime{i,1}=SSID{i};
        maxPrC_lifetime{i,2}=max(PrC_lifetime_main_con);
        maxPrC_lifetime{i,2}=max(PrC_lifetime_main_t);
    end
end