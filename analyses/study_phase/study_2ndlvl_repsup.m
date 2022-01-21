%% 2nd level contrast (for now just run it on Graham interactively)
% 2021-06-23 now also runs F contrasts
% 2021-07-08 now let you specify which contrast to bring to
% the 2nd level

%contrast 0001 pres_1>pres_2
%contrast 0002 pres_1>baseline
%contrast 0003 pres_2>baseline
%contrast 0004 pres_1>avg(pres_789)
%contrast 0005 pres_1 throught pres_9 decrease
%contrast 0006 lifetime_inc pmod pres_1
%contrast 0007 lifetime_dec pmod pres_1
%contrast 0008 feat-over_inc pmod pres_1
%contrast 0009 feat-over_dec pmod pres_1
%contrast 0010 lifetime_inc pmod pres_all
%contrast 0011 lifetime_dec pmod pres_all
%contrast 0012 feat-over_inc pmod pres_all
%contrast 0013 feat-over_dec pmod pres_all
function study_2ndlvl_repsup(con_dir,output_dir,sublist,maskfile,contrast_type,varargin)

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

switch contrast_type
    
    case 't'        
        %make sure only one contrast is given
        assert(length(varargin)==1);
        contrast=varargin{1};
        
        %initil setup for SPM
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');
        
        %load matlabbatch template
        study_2ndlvl_t_template;
        
        %make output directory
        if ~exist(strcat(output_dir,'/',contrast,'_t'),'dir')
            mkdir (output_dir,strcat(contrast,'_t'));
        end
       
        % one sample t-test
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/',contrast,'.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/',contrast,'_t')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/',contrast,'_t/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/',contrast,'_t/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = contrast;
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/',contrast,'_t/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = contrast;
        
        spm_jobman('run',matlabbatch);
        
    case 'paired_t'
        %make sure only two contrast is given
        assert(length(varargin)==2);
        contrast_1=varargin{1};
        contrast_2=varargin{2};
        
        %initil setup for SPM
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');
        
        %load matlabbatch template
        study_2ndlvl_paired_t_template;
        
        %make output directory
        if ~exist(strcat(output_dir,'/',contrast_1,'-',contrast_2,'_paired-t'),'dir')
            mkdir (output_dir,strcat(contrast_1,'-',contrast_2,'_paired-t'));
        end
        
        % paired t-test
        file_cell=cell(0,2);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/',contrast_1,'.nii');
            file_cell{i,2}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/',contrast_2,'.nii');
            matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(i).scans=file_cell(i,:)';
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/',contrast_1,'-',contrast_2,'_paired-t')};%specify
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/',contrast_1,'-',contrast_2,'_paired-t/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/',contrast_1,'-',contrast_2,'_paired-t/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = strcat(contrast_1,'-',contrast_2);
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = [1,-1];
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/',contrast_1,'-',contrast_2,'_paired-t/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = strcat(contrast_1,'-',contrast_2);
        
        spm_jobman('run',matlabbatch);
    case 'F'
        %make sure only one contrast is given
        assert(length(varargin)==1);
        contrast=varargin{1};
        
        %initil setup for SPM
        spm('defaults', 'FMRI');
        spm_jobman('initcfg');
        
        %load matlabbatch template
        study_2ndlvl_F_template;
        
        %make output directory
        if ~exist(strcat(output_dir,'/',contrast,'_F'),'dir')
            mkdir (output_dir,strcat(contrast,'_F'));
        end
        
        % F-test
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/',contrast,'.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/',contrast,'_F')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/',contrast,'_F/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/',contrast,'_F/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.name = contrast;
        matlabbatch{3}.spm.stats.con.consess{1}.fcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/',contrast,'_F/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = contrast;
        
        spm_jobman('run',matlabbatch);
end

end