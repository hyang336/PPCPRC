%job template for running single sample t-tests on the main
%effect of recent and lifetime. And paired t-tests for
%modulated contrast vs. main effect contrast

%% SPM.mat for each specification need to be in separate folders

%% specify lifetime main contrast
matlabbatch{1}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = '<UNDEFINED>';

matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
%estimate
matlabbatch{2}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;
%generate results
matlabbatch{3}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{3}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{3}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{3}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{3}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{3}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{3}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{3}.spm.stats.results.conspec(1).mask.none = 1;

%% specify recent main contrast
matlabbatch{4}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{4}.spm.stats.factorial_design.des.t1.scans = '<UNDEFINED>';

matlabbatch{4}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{4}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{4}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{4}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{4}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{4}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{4}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{4}.spm.stats.factorial_design.globalm.glonorm = 1;
%estimate
matlabbatch{5}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
matlabbatch{5}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{5}.spm.stats.fmri_est.method.Classical = 1;
%generate results
matlabbatch{6}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{6}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{6}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{6}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{6}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{6}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{6}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{6}.spm.stats.results.conspec(1).mask.none = 1;

%% paired t-test between modulated and unmodulated contrasts, lifetime
matlabbatch{7}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{7}.spm.stats.factorial_design.des.pt.pair(1).scans = '<UNDEFINED>';%pairs need to be 2x1 cell-array with file names in each cell
matlabbatch{7}.spm.stats.factorial_design.des.pt.pair(2).scans = '<UNDEFINED>';%first cell in the pair should be modulated, if we later use [1 -1] as contrast
matlabbatch{7}.spm.stats.factorial_design.des.pt.pair(3).scans = '<UNDEFINED>';
matlabbatch{7}.spm.stats.factorial_design.des.pt.gmsca = 0;
matlabbatch{7}.spm.stats.factorial_design.des.pt.ancova = 0;
matlabbatch{7}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{7}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{7}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{7}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{7}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{7}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{7}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{7}.spm.stats.factorial_design.globalm.glonorm = 1;

%estimate
matlabbatch{8}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
matlabbatch{8}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{8}.spm.stats.fmri_est.method.Classical = 1;
%generate results
matlabbatch{9}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{9}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{9}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{9}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{9}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{9}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{9}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{9}.spm.stats.results.conspec(1).mask.none = 1;

%% paired t-test between modulated and unmodulated contrasts, recent
matlabbatch{10}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{10}.spm.stats.factorial_design.des.pt.pair(1).scans = '<UNDEFINED>';%pairs need to be 2x1 cell-array with file names in each cell
matlabbatch{10}.spm.stats.factorial_design.des.pt.pair(2).scans = '<UNDEFINED>';%first cell in the pair should be modulated, if we later use [1 -1] as contrast
matlabbatch{10}.spm.stats.factorial_design.des.pt.pair(3).scans = '<UNDEFINED>';
matlabbatch{10}.spm.stats.factorial_design.des.pt.gmsca = 0;
matlabbatch{10}.spm.stats.factorial_design.des.pt.ancova = 0;
matlabbatch{10}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{10}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{10}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{10}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{10}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{10}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{10}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{10}.spm.stats.factorial_design.globalm.glonorm = 1;

%estimate
matlabbatch{11}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
matlabbatch{11}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{11}.spm.stats.fmri_est.method.Classical = 1;
%generate results
matlabbatch{12}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{12}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{12}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{12}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{12}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{12}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{12}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{12}.spm.stats.results.conspec(1).mask.none = 1;