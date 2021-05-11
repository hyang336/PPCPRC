%% using the pres_1>pres_2 contrast generated on lvl 1 to specify a simple t-contrast on lvl 2
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
%contrast
matlabbatch{3}.spm.stats.con.spmmat = '<UNDEFINED>';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = '<UNDEFINED>';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = '<UNDEFINED>';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
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

%% using the simple contrasts of pres_1 and pres_2 to specify a differential contrast pres_1>pres_2 on lvl 2
matlabbatch{5}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{5}.spm.stats.factorial_design.des.pt.pair(1).scans = '<UNDEFINED>';%pairs need to be 2x1 cell-array with file names in each cell
matlabbatch{5}.spm.stats.factorial_design.des.pt.pair(2).scans = '<UNDEFINED>';%first cell in the pair should be modulated, if we later use [1 -1] as contrast
matlabbatch{5}.spm.stats.factorial_design.des.pt.gmsca = 0;
matlabbatch{5}.spm.stats.factorial_design.des.pt.ancova = 0;
matlabbatch{5}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{5}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{5}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{5}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{5}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{5}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{5}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{5}.spm.stats.factorial_design.globalm.glonorm = 1;

%estimate
matlabbatch{6}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
matlabbatch{6}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{6}.spm.stats.fmri_est.method.Classical = 1;
%contrast
matlabbatch{7}.spm.stats.con.spmmat = '<UNDEFINED>';
matlabbatch{7}.spm.stats.con.consess = {};
matlabbatch{7}.spm.stats.con.delete = 0;
%generate results
matlabbatch{8}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{8}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{8}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{8}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{8}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{8}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{8}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{8}.spm.stats.results.conspec(1).mask.none = 1;

%% using the pres_1>pres_789 contrast generated on lvl 1 to specify a simple t-contrast on lvl 2
matlabbatch{9}.spm.stats.factorial_design.dir = '<UNDEFINED>';
matlabbatch{9}.spm.stats.factorial_design.des.t1.scans = '<UNDEFINED>';

matlabbatch{9}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{9}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{9}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{9}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{9}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{9}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{9}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{9}.spm.stats.factorial_design.globalm.glonorm = 1;
%estimate
matlabbatch{10}.spm.stats.fmri_est.spmmat = '<UNDEFINED>';
matlabbatch{10}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{10}.spm.stats.fmri_est.method.Classical = 1;
%contrast
matlabbatch{11}.spm.stats.con.spmmat = '<UNDEFINED>';
matlabbatch{11}.spm.stats.con.consess{1}.tcon.name = '<UNDEFINED>';
matlabbatch{11}.spm.stats.con.consess{1}.tcon.weights = '<UNDEFINED>';
matlabbatch{11}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{11}.spm.stats.con.delete = 0;
%generate results
matlabbatch{12}.spm.stats.results.spmmat = '<UNDEFINED>';
matlabbatch{12}.spm.stats.results.conspec(1).titlestr = '';
matlabbatch{12}.spm.stats.results.conspec(1).contrasts = 1;
matlabbatch{12}.spm.stats.results.conspec(1).threshdesc = 'FWE';
matlabbatch{12}.spm.stats.results.conspec(1).thresh = 0.05;
matlabbatch{12}.spm.stats.results.conspec(1).extent = 0;
matlabbatch{12}.spm.stats.results.conspec(1).conjunction = 1;
matlabbatch{12}.spm.stats.results.conspec(1).mask.none = 1;
