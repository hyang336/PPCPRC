%% does not include all contrasts
%2nd level analyses, make sure all subjects contrast images are registered and resampled to the the MNI space before
%running this


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


if ~exist(strcat(output_dir,'/lifetime_main_mean_centered_di'),'dir')
    mkdir (output_dir,'lifetime_main');
end
if ~exist(strcat(output_dir,'/recent_main_mean_centered_di'),'dir')
    mkdir (output_dir,'recent_main');
end
if ~exist(strcat(output_dir,'/lifetime_pmod_mean_centered_di'),'dir')
    mkdir (output_dir,'lifetime_pmod');
end
if ~exist(strcat(output_dir,'/recent_pmod_mean_centered_di'),'dir')
    mkdir (output_dir,'recent_pmod');
end
% if ~exist(strcat(output_dir,'/featmain_lifetime'),'dir')
%     mkdir (output_dir,'featmain_lifetime');
% end
% if ~exist(strcat(output_dir,'/featmain_recent'),'dir')
%     mkdir (output_dir,'featmain_recent');
% end
% if ~exist(strcat(output_dir,'/featmain_overall'),'dir')
%     mkdir (output_dir,'featmain_overall');
% end


%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%% contrast image are:
% 0001: lifetime main effect
% 0002: recent main effect
% 0003: lifetime para_moded
% 0004: recent para_moded
% 0005: feat_over main effect in lifetime trials
% 0006: feat_over main effect in recent trials
% 0007: feat_over main effect in all trials

% To test whether parametric modulation effect (interaction)
% is significant, we need to use the tmaps to compare
% whether the model fit in the first-level is better for the
% modulated design columns

% 2020-05-06 Currently we run 4 tests, main effet of lifetime and
% recent exposure with a contrast vector of [1 0] run on contrast 0001 and 0002;
% interaction with feature-overlap within each task, with
% contrast vector [1 -1] on t-maps for 0003 and 0001, and
% 0004 and 0002, respectively for lifetime and recent
% exposure.

%%   
%load job template, should be able to use the same job
%template since the number of contrasts and the type are the
%same on the 2nd level
test_resp_2ndlvl_job;

% main effect of lifetime and recent exposure, one-sample t-tests 
file_cell=cell(0,1);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0001.nii');
end
matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_main_mean_centered_di')};%specify
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_main_mean_centered_di/SPM.mat')};%estimate
matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_main_mean_centered_di/SPM.mat')};%contrast
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_main_mean_centered_di';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_main_mean_centered_di/SPM.mat')};%threshold
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'lifetime_main_mean_centered_di';

file_cell=cell(0,1);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0002.nii');
end
matlabbatch{5}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_main_mean_centered_di')};%specify
matlabbatch{5}.spm.stats.factorial_design.des.t1.scans = file_cell;
matlabbatch{6}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_main_mean_centered_di/SPM.mat')};%estimate
matlabbatch{7}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_main_mean_centered_di/SPM.mat')};%contrast
matlabbatch{7}.spm.stats.con.consess{1}.tcon.name = 'recent_main_mean_centered_di';
matlabbatch{7}.spm.stats.con.consess{1}.tcon.weights = 1;
matlabbatch{8}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_main_mean_centered_di/SPM.mat')};%threshold
matlabbatch{8}.spm.stats.results.conspec(1).titlestr = 'recent_main_mean_centered_di';

%paired t-test between modulated and unmodulated contrasts
file_cell=cell(0,2);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0003.nii');
    file_cell{i,2}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0001.nii');
    matlabbatch{9}.spm.stats.factorial_design.des.pt.pair(i).scans=file_cell(i,:)';
end
matlabbatch{9}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_pmod_mean_centered_di')};%specify
matlabbatch{10}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_pmod_mean_centered_di/SPM.mat')};%estimate
matlabbatch{11}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_pmod_mean_centered_di/SPM.mat')};%contrast
matlabbatch{11}.spm.stats.con.consess{1}.tcon.name = 'lifetime_pmod_mean_centered_di';
matlabbatch{11}.spm.stats.con.consess{1}.tcon.weights = [1,-1];
matlabbatch{12}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_pmod_mean_centered_di/SPM.mat')};%threshold
matlabbatch{12}.spm.stats.results.conspec(1).titlestr = 'lifetime_pmod_mean_centered_di';

file_cell=cell(0,2);
for i=1:length(SSID)
    file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0004.nii');
    file_cell{i,2}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0002.nii');
    matlabbatch{13}.spm.stats.factorial_design.des.pt.pair(i).scans=file_cell(i,:)';
end
matlabbatch{13}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_pmod_mean_centered_di')};%specify
matlabbatch{14}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_pmod_mean_centered_di/SPM.mat')};%estimate
matlabbatch{15}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_pmod_mean_centered_di/SPM.mat')};%contrast
matlabbatch{15}.spm.stats.con.consess{1}.tcon.name = 'recent_pmod_mean_centered_di';
matlabbatch{15}.spm.stats.con.consess{1}.tcon.weights = [1,-1];
matlabbatch{16}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_pmod_mean_centered_di/SPM.mat')};%threshold
matlabbatch{16}.spm.stats.results.conspec(1).titlestr = 'recent_pmod_mean_centered_di';

%skip the results part since it will get stuck. Will need to
%find another way to threshold
spm_jobman('run',matlabbatch);
%spm_jobman('run',matlabbatch(1:3));
%spm_jobman('run',matlabbatch(5:7));
%spm_jobman('run',matlabbatch(9:11));
%spm_jobman('run',matlabbatch(13:15));
end