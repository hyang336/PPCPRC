%% compile SVM results and run t-tests

function study_2ndlvl_SVM_bin(lvl1_dir,sublist,output)
   
%read in subject IDs
fid=fopen(sublist,'r');
tline=fgetl(fid);
SSID=cell(0,1);
while ischar(tline)
    SSID{end+1,1}=tline;
    tline=fgetl(fid);
end
fclose(fid);

%compile results
for i=1:length(SSID)
   result=load(strcat(lvl1_dir,'/sub-',SSID{i},'/SVM_results.mat')); 
   freq_voxels{i}=result.freq_voxels;
   life_voxels{i}=result.life_voxels;
   freq_accuracy{i}=result.freq_accuracy;
   life_accuracy{i}=result.life_accuracy;
end

%average across sample and cross-validation fold
freq_mean_acc=cellfun(@(x) mean(x,'all'),freq_accuracy);
life_mean_acc=cellfun(@(x) mean(x,'all'),life_accuracy);

%test against chance
[~,freq_p,freq_ci,freq_tval]=ttest(freq_mean_acc,0.5,'Tail','right');%alternative hypothesis is that accuracy higher than 0.5
[~,life_p,life_ci,life_tval]=ttest(life_mean_acc,0.5,'Tail','right');%alternative hypothesis is that accuracy higher than 0.5

if ~exist(output,'dir')
    mkdir (output);
end

save(strcat(output,'/bin_SVM_result.m'),'freq_p','freq_ci','freq_tval','life_p','life_ci','life_tval');
end