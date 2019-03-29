% List of open inputs
% Contrast Manager: Select SPM.mat - cfg_files
% Contrast Manager: Name - cfg_entry
% Contrast Manager: Weights vector - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC\analyses\pilot\multisession_test_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(3, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Contrast Manager: Select SPM.mat - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Contrast Manager: Name - cfg_entry
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % Contrast Manager: Weights vector - cfg_entry
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
