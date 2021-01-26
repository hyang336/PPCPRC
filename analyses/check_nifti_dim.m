fmriprep_dir='~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_corrected';
fid = fopen('~/scratch/working_dir/PPC_MD/sub_list_test_2mmMotionCor.txt');
sublist = textscan(fid,'%s');
fclose(fid);
sublist=sublist{1,1};
runlist={'keyprac_run-01','study_run-01','study_run-02','study_run-03','study_run-04','study_run-05','test_run-01','test_run-02','test_run-03','test_run-04'};

for a=1:length(sublist)
    s=sublist{a};
    for b=1:length(runlist)
        filename = strcat('sub-',s,'_task-',runlist{b},'_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz');
        header(a,b)=niftiinfo(strcat(fmriprep_dir,'/fmriprep/sub-',s,'/func/',filename));
        
    end
end
