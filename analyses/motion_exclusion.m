output_dir='~/scratch/working_dir/PPC_MD/';
fmriprep_dir='~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_AROMA';

fid = fopen('~/scratch/working_dir/PPC_MD/sub_list.txt');
sublist = textscan(fid,'%s');
fclose(fid);
sublist=sublist{1,1};

runlist={'keyprac_run-01','study_run-01','study_run-02','study_run-03','study_run-04','study_run-05','test_run-01','test_run-02','test_run-03','test_run-04'};

for a=1:length(sublist)
    s=sublist{a};

    for b=1:length(runlist)
        filename = strcat('sub-',s,'_task-',runlist{b},'_desc-confounds_regressors.tsv');
        file=tdfread(strcat(fmriprep_dir,'/fmriprep/sub-',s,'/func/',filename));
        FD=file.framewise_displacement;
        for c=1:length(FD)
            FD_array(c,1)=str2double(FD(c,:));
        end
        FD_over=FD_array>2;%2 mm is the voxel size
        if sum(FD_over,1)>0
            Bad_run(a,b)=cellstr(strcat('sub-',s,'_task-',runlist{b}));
            %now also save the frames that have diplacement
            %over threshold
            Bad_run_movement{a,b}=FD_array(FD_over);
        end
        
    end
end
save(output_dir,'Bad_run');