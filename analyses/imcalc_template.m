% List of open inputs
% Image Calculator: Input Images - cfg_files
% Image Calculator: Expression - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC\analyses\imcalc_template_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(2, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Image Calculator: Input Images - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Image Calculator: Expression - cfg_entry
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
