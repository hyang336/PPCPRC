%% 2nd level contrast (for now just run it on Graham interactively)

%contrast 0001 pres_1>pres_2
%contrast 0002 pres_1>baseline
%contrast 0003 pres_2>baseline
function study_2ndlvl_repsup(con_dir,output_dir,sublist,maskfile)

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);


if ~exist(strcat(output_dir,'/pres1v2_simple'),'dir')
    mkdir (output_dir,'pres1v2_simple');
end
if ~exist(strcat(output_dir,'/pres1v2_diff'),'dir')
    mkdir (output_dir,'pres1v2_diff');
end


%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%%   
%load job template, should be able to use the same job
%template since the number of contrasts and the type are the
%same on the 2nd level
study_2ndlvl_repsup_job;

% main effect pres_1>pres_2 as a one sample t-test
file_cell=cell(0,1);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0001.nii');
end
matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/pres1v2_simple')};%specify
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/pres1v2_simple/SPM.mat')};%estimate
matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/pres1v2_simple/SPM.mat')};%contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'pres_1>pres_2_simple';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/pres1v2_simple/SPM.mat')};%threshold
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'pres_1>pres_2_simple';

% main effect pres_1>pres_2 as a paired t-test 
file_cell=cell(0,2);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0002.nii');
    file_cell{i,2}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0003.nii');
    matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(i).scans=file_cell(i,:)';
end
matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/pres1v2_diff')};%specify
matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/pres1v2_diff/SPM.mat')};%estimate
matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/pres1v2_diff/SPM.mat')};%contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'pres_1>pres_2_diff';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1,-1];
matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/pres1v2_diff/SPM.mat')};%threshold
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'pres_1>pres_2_diff';

spm_jobman('run',matlabbatch);

end