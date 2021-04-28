%% does not include all contrasts
%2nd level analyses, make sure all subjects contrast images are registered and resampled to the the MNI space before
%running this


function test_resp_2ndlvl(con_dir,output_dir,sublist,contrast)

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

%% contrast image are:
% ###sub-020 only has contrast 0001,0002,0008(numbered as 0003),and 0009(numbered as 0004)###

% 0001: lifetime linear inc main effect
% 0002: recent linear dec main effect
% 0003: lifetime linear inc para_moded
% 0004: recent linear dec para_moded
% 0005: feat_over main effect in lifetime trials
% 0006: feat_over main effect in recent trials
% 0007: feat_over main effect in all trials
% 0008: recent linear inc main effect
% 0009: lifetime linear dec main effect

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


switch contrast
    
    case 'lifetime_main'
        %load job template
        test_resp_2ndlvl_job_indi_singleT;
        
        if ~exist(strcat(output_dir,'/lifetime_main'),'dir')
            mkdir (output_dir,'lifetime_main');
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0001.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_main')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_main/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_main/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_main';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_main/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'lifetime_main';
    case 'recent_main'
        %load job template
        test_resp_2ndlvl_job_indi_singleT;

        if ~exist(strcat(output_dir,'/recent_main'),'dir')
            mkdir (output_dir,'recent_main');
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0002.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_main')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_main/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_main/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'recent_main';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_main/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'recent_main';
    case 'lifetime_pmod'
        %load job template
        test_resp_2ndlvl_job_indi_pairedT;
        
        if ~exist(strcat(output_dir,'/lifetime_pmod'),'dir')
            mkdir (output_dir,'lifetime_pmod');
        end
        file_cell=cell(0,2);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0003.nii');
            file_cell{i,2}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0001.nii');
            matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(i).scans=file_cell(i,:)';
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_pmod')};%specify
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_pmod/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_pmod/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_pmod';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1,-1];
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_pmod/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'lifetime_pmod';
    case 'recent_pmod'
        %load job template
        test_resp_2ndlvl_job_indi_pairedT;
        
        if ~exist(strcat(output_dir,'/recent_pmod'),'dir')
            mkdir (output_dir,'recent_pmod');
        end
        file_cell=cell(0,2);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0004.nii');
            file_cell{i,2}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/spmT_0002.nii');
            matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(i).scans=file_cell(i,:)';
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_pmod')};%specify
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_pmod/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_pmod/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'recent_pmod';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1,-1];
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_pmod/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'recent_pmod';
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


%skip the results part since it will get stuck. Will need to
%find another way to threshold
spm_jobman('run',matlabbatch);
%spm_jobman('run',matlabbatch(1:3));
%spm_jobman('run',matlabbatch(5:7));
%spm_jobman('run',matlabbatch(9:11));
%spm_jobman('run',matlabbatch(13:15));
end