%% use SnPM to correct for multiple comparison (nonparametrically)
%% pass in the whole-brain mask for whole brain analysis, PrC mask for SVC
function SnPM_singleT(lvl1_dir,contrast,sublist,output_dir,mask)
    if ~exist(output_dir,'dir')
    mkdir (output_dir);
end

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%initialize job template
SnPM_multisub_singleT_job

%loop over subjects to load contrast images (one per subject)
for i=1:length(SSID)%loop over subjects
        confile=strcat(lvl1_dir,'/sub-',SSID{i},'/temp/',contrast,'.nii,1');
        matlabbatch{1}.spm.tools.snpm.des.OneSampT.P{i,1}=confile;
end
matlabbatch{1}.spm.tools.snpm.des.OneSampT.vFWHM=[4,4,4];%variance smoothing equals the smoothing extent of the data
matlabbatch{1}.spm.tools.snpm.des.OneSampT.masking.em = {mask};
matlabbatch{1}.spm.tools.snpm.des.OneSampT.dir = {output_dir};
%compute
matlabbatch{2}.spm.tools.snpm.cp.snpmcfg = {strcat(output_dir,'/SnPMcfg.mat')};

%infer
matlabbatch{3}.spm.tools.snpm.inference.SnPMmat = {strcat(output_dir,'/SnPM.mat')};

spm_jobman('run',matlabbatch);

end