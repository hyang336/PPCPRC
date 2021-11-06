%% build the .csv file for HDDM. Note that the some column names in HDDM are reserved
%% As of 2021-11-03, we try to use above FWE threshold clusters from the 1st level t-test of 
%% increasing frequency judgement effect to define whole-brain ROIs, and ASHS mask for PrC

%% The feature/voxel selection procedure was carried out in each ROI separately based on t value (decrease in PrC) and increase in frontoparietal
%% using the same GLM that extracted the ROI, then we use the selected voxel as refined masks to extract trial-by-trial betas from each region
%% Then averaging beta across voxels and z-score within each region to control for different SNR across regions
%% Then regress the z-score to extract residuals

function preprocess(project_derivative,LSSN_foldername,output_dir,sublist,ROImask,region_name)

%some preset parameters
TR=2.5;
expstart_vol=5;
project_derivative='/scratch/hyang336/working_dir/PPC_MD';
freq_con_dir=strcat(project_derivative,'/GLM_avgMask_4mmSmooth/test_lifetime_recent_conjunction_both_inc/');
fmriprep_foldername='fmriprep_1.5.4_AROMA';
ROI=niftiread(ROImask);

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%prealloc result table
freq_result=cell2table(cell(0,5),'VariableNames',{'subj_idx','stim','rt','response',strcat(region_name,'_beta'),strcat(region_name,'_z')});

%loop through subjects
for i=1:length(SSID)
    %load in t-map corresponding to freq_inc contrast for frontoparietal or
    %freq_dec for PrC. With a single t-map, we can simple look for the max
    %positive value in a lifetime_inc t-map to find voxels with most
    %increase, and max negative value to find voxels with most decrease
    %since the contrast was generated as a weighted sum: [-2, -1, 0 ,1, 2]
    %for increasing activity with increasing level of frequency judgement
    %[1, 2, 3, 4, 5]
    freq_t=niftiread(strcat(freq_con_dir,'/spmT_0002.nii'));
    ROI_t=freq_t(find(ROI));
    %select the top 10% voxels according to t-value
    [~,topvoxels]=maxk(ROI_t,ceil(length(ROI_t)*0.05));%top 5% voxels, need to change maxk to mink when using regions with decreasing signal (e.g. PrC)
    
    %load in event file 

    %extract relevant behavioral data for frequency trials,
    %condition dividing, accuracy coding, etc.
    
    %load beta weights for each trial, and extract average
    %beta in the ROI 
    
end   
    
end