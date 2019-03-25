%% not using this, call spm_jobman directly in main script and give input to matlabbatch explicitly
function batch_template(nrun,jobfile,cellofinput)
% job = repmat(jobfile, 1, nrun);
inputs = cell(length(cellofinput), nrun);
for crun = 1:nrun%fill each run
    for i=1:length(cellofinput)%for each run fill all inputs
        inputs{i,crun}=cellofinput{i};
    end
end

%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

spm_jobman('run', jobfile, inputs{:});
end