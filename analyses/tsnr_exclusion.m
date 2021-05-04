%% this need to be run *AFTER* motion_exclusion.m
output_dir='~/scratch/working_dir/PPC_MD';
fmriprep_dir='~/scratch/working_dir/PPC_MD/fmriprep_1.5.4_AROMA';
ASHS_dir='~/scratch/working_dir/PPC_MD/ASHS_raw2';

fid = fopen('~/scratch/working_dir/PPC_MD/sub_list_libmotion.txt');
sublist = textscan(fid,'%s');
fclose(fid);
sublist=sublist{1,1};

runlist={'keyprac_run-01','study_run-01','study_run-02','study_run-03','study_run-04','study_run-05','test_run-01','test_run-02','test_run-03','test_run-04'};

tSNR_res=cell(length(sublist)+1,length(runlist)+1);
tSNR_res(1,2:end)=runlist;

for a=1:length(sublist)
    s=sublist{a};
    tSNR_res{a+1,1}=s;
    for b=1:length(runlist)
        filename = strcat('sub-',s,'_task-',runlist{b},'_space-T1w_desc-preproc_bold.nii.gz');
        runfile=niftiread(strcat(fmriprep_dir,'/fmriprep/sub-',s,'/func/',filename));
        prcfile=strcat('sub-',s,'_PRC_resampled.nii');
        PrC=niftiread(strcat(ASHS_dir,'/sub-',s,'/final/',prcfile));
        %find non-zero entries which are the voxels in the
        %ROI
        [p,r,c]=ind2sub(size(PrC),find(PrC));
        
        for i=1:length(p)
            timeseries=runfile(p(i),r(i),c(i),:);
            tSNR(i)=abs(mean(timeseries)/std(timeseries));
        end
        PrC_tSNR=mean(tSNR);
        if PrC_tSNR<10
            tSNR_Bad(a,b)=cellstr(strcat('sub-',s,'_task-',runlist{b}));
        end
        tSNR_res{a+1,b+1}=PrC_tSNR;
    end
end
save(strcat(output_dir,'/tSNR_after_motionEX.mat'),'tSNR_res');
