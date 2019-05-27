% List of open inputs
% Smooth: Images to smooth - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC\analyses\pilot\smooth_template_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(1, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Smooth: Images to smooth - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
