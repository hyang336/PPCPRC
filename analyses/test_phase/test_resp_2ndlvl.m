%% does not include all contrasts
%2nd level analyses, make sure all subjects contrast images are registered and resampled to the the MNI space before
%running this


function test_resp_2ndlvl(con_dir,output_dir,sublist,maskfile,varargin)

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

%% for '/test_1stlvl_all3_softAROMA_bin/' contrast images are:
% 0001: lifetime high>low main effect
% 0002: recent low>high main effect
% 0003: recent high>low inc main effect
% 0004: lifetime low>high main effect
% 0005: dec-irr lifetime high>low main effect
% 0006: dec-irr lifetime low>high main effect

%% for '/test_1stlvl_softAROMA/' contrast images are:
% 0001: lifetime linear increase
% 0002: recent linear decrease
% 0003: recent linear increase
% 0004: lifetime linear decrease

%% for '/test_1stlvl_postscan_softAROMA/' contrast images are:
% 0001: lifetime linear increase
% 0002: lifetime linear decrease
% 0003: dec-irr lifetime linear increase
% 0004: dec-irr lifetime linear decrease

%% for '/test_1stlvl_lifetime-pmod_epi(or sem)_softAROMA_var-epoch/' contrast images are:  
% note that the linear effect tested in this case is more
% strict since it is a parametric model

% 0001: lifetime linear increase
% 0002: recent linear decrease
% 0003: recent linear increase
% 0004: lifetime linear decrease
% 0005: epi_t or sem_t linear increase in lifetime trials

if length(varargin)==1 %if only one contrast name is specified, use single-sample t-test
    
        %load job template
        test_resp_2ndlvl_job_indi_singleT;
        
        if ~exist(output_dir,'dir')
            mkdir (output_dir);
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/',contrast,'.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_main')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_main/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_main/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_main';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_main/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'lifetime_main';
        
elseif length(varargin)==2 %if two contrast names are specified, use paired t-test
        %load job template
        test_resp_2ndlvl_job_indi_pairedT;

        if ~exist(output_dir,'dir')
            mkdir (output_dir);
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0002.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_main')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_main/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_main/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'recent_main';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_main/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'recent_main';
    
end

%skip the results part since it will get stuck. Will need to
%find another way to threshold
spm_jobman('run',matlabbatch);

end