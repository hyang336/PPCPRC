%% 2nd level all trial vs. baseline contrast


function test_resp_2ndlvl_mean_centered_di(con_dir,output_dir,sublist)

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);


if ~exist(strcat(output_dir,'/alltrials'),'dir')
    mkdir (output_dir,'alltrials');
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
test_resp_2ndlvl_allvsnone_job;

% main effect all trials
file_cell=cell(0,1);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0001.nii');
end
matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/alltrials')};%specify
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/alltrials/SPM.mat')};%estimate
matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/alltrials/SPM.mat')};%contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'alltrials';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/alltrials/SPM.mat')};%threshold
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'alltrials';

%skip the results part since it will get stuck. Will need to
%find another way to threshold
spm_jobman('run',matlabbatch);

end