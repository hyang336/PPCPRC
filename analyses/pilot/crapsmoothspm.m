function smoothed_4d=crapsmoothspm(filepath,filenames,kernal_size)
%filenames are absolute file paths in cells for each run
%kernal size is of [x,y,z] in mm.
%returns the file names for smoothed data
smooth_template_job;
matlabbatch{1}.spm.spatial.smooth.fwhm=kernal_size;
for i=1:length(filenames)
    expand_nii{i}=spm_select('expand',cellstr(strcat(filepath,filenames{i})));
    matlabbatch{1}.spm.spatial.smooth.data=expand_nii{i};
    spm_jobman('run',matlabbatch);
    smoothed_4d{i}=strcat(filepath,matlabbatch{1}.spm.spatial.smooth.prefix,filenames{i});
end

end