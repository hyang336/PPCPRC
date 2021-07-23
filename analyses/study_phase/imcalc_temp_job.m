%-----------------------------------------------------------------------
% Job saved on 22-Jul-2021 02:05:15 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
matlabbatch{1}.spm.util.imcalc.input = {
                                        'C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC_data\studyphase_1stlvl\LSSN_test\sub-005\temp\task-study_run_1\trial_1\beta_0001.nii,1'
                                        'C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC_data\studyphase_1stlvl\LSSN_test\sub-005\temp\task-study_run_1\trial_11\beta_0001.nii,1'
                                        };
matlabbatch{1}.spm.util.imcalc.output = 'life1_beta.nii';
matlabbatch{1}.spm.util.imcalc.outdir = {'C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC_data\studyphase_1stlvl\study_lifetime_con_pres-1\sub-005\temp'};
matlabbatch{1}.spm.util.imcalc.expression = '(i1+i2)/2';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
