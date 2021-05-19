%% Average contrast value within ROIs defined by marsbar and run stats, for whatever reason marsbar's ROI analysis 
%% pipeline is broken and the forum is pretty much dead.

%requires either functionally defined (e.g. marsbar) or
%structurally defined ROIs

%also requires 1st-lvl contrast files

%returns inferential stats, since it is ROI these are not
%corrected for multiple comparisons across space

%% for '/test_1stlvl_all3_softAROMA_bin/' contrast images are:
% 0001: lifetime high>low main effect
% 0002: recent low>high main effect
% 0003: recent high>low inc main effect
% 0004: lifetime low>high main effect
% 0005: dec-irr lifetime high>low main effect
% 0006: dec-irr lifetime low>high main effect

%% for '/repetition_suppression_softAROMA/' contrast images are
%contrast 0001 pres_1>pres_2
%contrast 0002 pres_1>baseline
%contrast 0003 pres_2>baseline
%contrast 0004 pres_1>pres_789

function ROI_2ndlvl(contrast_dir,sublist,contrast,ROI_mask)
    
%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%load ROIs
ROI=niftiread(ROI_mask);

%load .con images and calculate the average
for i=1:length(SSID)
    filecell=strcat(contrast_dir,'/sub-',SSID(i),'/temp/',contrast,'.nii');
    conimg=niftiread(filecell{1});
    ROI_activation=conimg(find(ROI));%assuming there is only one ROI since this will just find all non-zero entries
    results(i)=nanmean(ROI_activation);
end
%t or F test
[h,p,ci,stats] = ttest(results);
end
