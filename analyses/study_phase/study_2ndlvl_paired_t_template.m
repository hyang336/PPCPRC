matlabbatch{1}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(1).scans = '<UNDEFINED>';%pairs need to be 2x1 cell-array with file names in each cell
matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(2).scans = '<UNDEFINED>';%first cell in the pair should be modulated, if we later use [1 -1] as contrast
matlabbatch{1}.spm.stats.factorial_design.des.pt.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.pt.ancova = 0;
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
%contrast
matlabbatch{3}.spm.stats.con.spmmat = '<UNDEFINED>';
matlabbatch{3}.spm.stats.con.consess = {};
matlabbatch{3}.spm.stats.con.delete = 0;
%generate results
matlabbatch{4}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{4}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{4}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{4}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{4}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{4}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{4}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{4}.spm.stats.results.conspec(1).mask.none = 1;