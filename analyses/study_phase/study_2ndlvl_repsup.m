%% 2nd level contrast 
function study_2ndlvl_repsup(con_dir,output_dir,sublist)

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);


if ~exist(strcat(output_dir,'/pres1v2'),'dir')
    mkdir (output_dir,'pres1v2');
end
if ~exist(strcat(output_dir,'/pres2v3'),'dir')
    mkdir (output_dir,'pres2v3');
end


%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%% contrast image are:
% 0001: all trial main effect

%%   
%load job template, should be able to use the same job
%template since the number of contrasts and the type are the
%same on the 2nd level
study_2ndlvl_repsup_job;

% main effect pres_1>pres_2
file_cell=cell(0,1);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0001.nii');
end
matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/pres1v2')};%specify
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/pres1v2/SPM.mat')};%estimate
matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/pres1v2/SPM.mat')};%contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'pres_1>pres_2';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/pres1v2/SPM.mat')};%threshold
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'pres_1>pres_2';

% main effect pres_2>pres_3
file_cell=cell(0,1);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0002.nii');
end
matlabbatch{5}.spm.stats.factorial_design.dir = {strcat(output_dir,'/pres2v3')};%specify
matlabbatch{5}.spm.stats.factorial_design.des.t1.scans = file_cell;
matlabbatch{6}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/pres2v3/SPM.mat')};%estimate
matlabbatch{7}.spm.stats.con.spmmat = {strcat(output_dir,'/pres2v3/SPM.mat')};%contrast
matlabbatch{7}.spm.stats.con.consess{1}.tcon.name = 'pres_2>pres_3';
matlabbatch{7}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{8}.spm.stats.results.spmmat = {strcat(output_dir,'/pres2v3/SPM.mat')};%threshold
matlabbatch{8}.spm.stats.results.conspec(1).titlestr = 'pres_2>pres_3';


spm_jobman('run',matlabbatch);

end