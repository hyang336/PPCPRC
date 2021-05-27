%% test phase conjunction analysis similar to (Duke et al., 2017)
% using the procedure described at https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind04&L=SPM&P=R187333
%% for '/test_1stlvl_all3_softAROMA_bin/' contrast images are:
% 0001: lifetime high>low main effect
% 0002: recent low>high main effect
% 0003: recent high>low inc main effect
% 0004: lifetime low>high main effect
% 0005: dec-irr lifetime high>low main effect
% 0006: dec-irr lifetime low>high main effect

%% for '/test_1stlvl_softAROMA/' contrast images are:
% 0001: lifetime linear increase
% 0002: recent linear decrease
% 0003: recent linear increase
% 0004: lifetime linear decrease

%% for '/test_1stlvl_postscan_softAROMA/' contrast images are:
% 0001: lifetime linear increase
% 0002: lifetime linear decrease
% 0003: dec-irr lifetime linear increase
% 0004: dec-irr lifetime linear decrease

function test_2ndlvl_conjunction(con_dir,output_dir,sublist,contrast_list,maskfile)

if ~exist(output_dir,'dir')
    mkdir (output_dir);
end

%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%read in contrast list
fid=fopen(contrast_list,'r');
tline=fgetl(fid);
contrasts=cell(0,1);
while ischar(tline)
    contrasts{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%initil setup for SPM
spm('defaults', 'FMRI');
spm_jobman('initcfg');

%initialize job structure
test_2ndlvl_conjunctive_job;
for i=1:length(SSID)%loop over subjects
    for j=1:length(contrasts) %loop over contrasts
        confile=strcat(con_dir,'/sub-',SSID{i},'/temp/',contrasts{j},'.nii,1');
        matlabbatch{1}.spm.stats.factorial_design.des.anova.icell(j).scans{i}=confile;
    end
end
matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir};
matlabbatch{1}.spm.stats.factorial_design.masking.em = {maskfile};
matlabbatch{2}.spm.stats.fmri_est.spmmat = {strcat(output_dir,'/SPM.mat')};
matlabbatch{3}.spm.stats.con.spmmat = {strcat(output_dir,'/SPM.mat')};

%the contrast vector should be rows of an n-by-n identity
%matrix, with n being the number of contrasts to conjunct
conmat=eye(length(contrasts));
for k=1:length(contrasts)
    matlabbatch{3}.spm.stats.con.consess{k}.tcon.name = contrasts{k};
    matlabbatch{3}.spm.stats.con.consess{k}.tcon.weights = conmat(k,:);
end
matlabbatch{4}.spm.stats.results.spmmat = {strcat(output_dir,'/SPM.mat')};

matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'conjunction_global';
matlabbatch{4}.spm.stats.results.conspec(1).contrasts = [1:length(contrasts)];
matlabbatch{4}.spm.stats.results.conspec(1).conjunction = length(contrasts);%Global null

spm_jobman('run',matlabbatch);
end