%% does not include all contrasts
%2nd level analyses, make sure all subjects contrast images are registered and resampled to the the MNI space before
%running this


function test_2ndlvl_all3_bin(con_dir,output_dir,sublist,contrast,maskfile)

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%% contrast image are:
% 0001: lifetime high>low main effect
% 0002: recent low>high main effect
% 0003: recent high>low inc main effect
% 0004: lifetime low>high main effect
% 0005: dec-irr lifetime high>low main effect
% 0006: dec-irr lifetime low>high main effect

%%  
switch contrast
    
    case 'lifetime_h-l'
        %load job template
        test_resp_2ndlvl_job_indi_singleT;
        
        if ~exist(strcat(output_dir,'/lifetime_h-l'),'dir')
            mkdir (output_dir,'lifetime_h-l');
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0001.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_h-l')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_h-l/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_h-l/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_h-l';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_h-l/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'lifetime_h-l';
    case 'recent_l-h'
        %load job template
        test_resp_2ndlvl_job_indi_singleT;

        if ~exist(strcat(output_dir,'/recent_l-h'),'dir')
            mkdir (output_dir,'recent_l-h');
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0002.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_l-h')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_l-h/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_l-h/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'recent_l-h';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_l-h/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'recent_l-h';
    case 'lifetime_irr_h-l'
        %load job template
        %load job template
        test_resp_2ndlvl_job_indi_singleT;
        
        if ~exist(strcat(output_dir,'/lifetime_irr_h-l'),'dir')
            mkdir (output_dir,'lifetime_irr_h-l');
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0005.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/lifetime_irr_h-l')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/lifetime_irr_h-l/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/lifetime_irr_h-l/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'lifetime_irr_h-l';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/lifetime_irr_h-l/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'lifetime_irr_h-l';

        case 'recent_h-l'
        %load job template
        test_resp_2ndlvl_job_indi_singleT;

        if ~exist(strcat(output_dir,'/recent_h-l'),'dir')
            mkdir (output_dir,'recent_h-l');
        end
        file_cell=cell(0,1);
        for i=1:length(SSID)
            file_cell{i,1}=strcat(con_dir,'/sub-',SSID{i,1},'/temp/con_0003.nii');
        end
        matlabbatch{1}.spm.stats.factorial_design.dir = {strcat(output_dir,'/recent_h-l')};%specify
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = file_cell;
        matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
        matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/recent_h-l/SPM.mat')};%estimate
        matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/recent_h-l/SPM.mat')};%contrast
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'recent_h-l';
        matlabbatch{3}.spm.stats.con.consess{1}.tcon.weights = 1;
        matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/recent_h-l/SPM.mat')};%threshold
        matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'recent_h-l';
end

spm_jobman('run',matlabbatch);

end