%% incomplete
%2nd level analyses, all subjects contrast images needs to
%be registered and resampled to the the MNI space before
%running this

function test_resp_2ndlvl(con_dir,output_dir,sub-list,test)

if ~exist(strcat(output_dir,'/lifetime_main'),'dir')
    mkdir (output_dir,'lifetime_main');
end
if ~exist(strcat(output_dir,'/rec_main'),'dir')
    mkdir (output_dir,'rec_main');
end
if ~exist(strcat(output_dir,'/lifetime_pmod'),'dir')
    mkdir (output_dir,'lifetime_pmod');
end
if ~exist(strcat(output_dir,'/recent_pmod'),'dir')
    mkdir (output_dir,'recent_pmod');
end

%load job template
test_resp_2ndlvl_job;

%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%contrast image are:
% 0001: lifetime linear inc main effect
% 0002: recent linear dec main effect
% 0003: lifetime linear inc para_moded
% 0004: recent linear dec para_moded
% 0005: feat_over main effect in lifetime trials
% 0006: feat_over main effect in recent trials
% 0007: feat_over main effect in all trials

switch test
    case 'single_t'%contrast 0001 and 0002       
        matlabbatch{1}.spm.stats.factorial_design.dir = strcat(output_dir,'/lifetime_main/SPM.mat');
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = '<UNDEFINED>';
        matlabbatch{2}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
        matlabbatch{3}.spm.stats.results.spmmat = '<UNDEFINED>';
        matlabbatch{4}.spm.stats.factorial_design.dir = '<UNDEFINED>';
        matlabbatch{4}.spm.stats.factorial_design.des.t1.scans = '<UNDEFINED>';
        matlabbatch{5}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
        matlabbatch{6}.spm.stats.results.spmmat = '<UNDEFINED>';
        
        spm_jobman('run',matlabbatch(1:6));
    case 'pair_t'%contrast 0003>0001, contrast 0004>0002


end