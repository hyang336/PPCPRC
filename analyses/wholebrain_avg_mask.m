%% generate avg wholebrain mask in funtional space (MNI)

fmriprep_dir='~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected';
fid = fopen('~/scratch/working_dir/PPC_MD/sub_list_test_2mmMotionCor.txt');
sublist = textscan(fid,'%s');
fclose(fid);
sublist=sublist{1,1};
output_dir='~/scratch/working_dir/PPC_MD/masks';

imcalc_template_job

sum_str='';
for a=1:length(sublist)
    s=sublist{a};
    %unzip the anatomical brain mask in MNI space
    gunzip(strcat(fmriprep_dir,'/fmriprep/sub-',s,'/anat/sub-',s,'_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz'),output_dir);
    matlabbatch{1}.spm.util.imcalc.input(a)={strcat(output_dir,'/sub-',s,'_space-MNI152NLin2009cAsym_desc-brain_mask.nii')};
    if a < length(sublist)
        sum_str=strcat(sum_str,'i',num2str(a),'+');
    else
        sum_str=strcat(sum_str,'i',num2str(a));
    end
end

%average
matlabbatch{1}.spm.util.imcalc.expression = strcat('(',sum_str,')/',num2str(length(sublist)));



