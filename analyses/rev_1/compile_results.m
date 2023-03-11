%% compile decoding results to generate .csv files to be used in R
sub_list={'sub-001','sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-011','sub-012','sub-013','sub-014','sub-015','sub-016','sub-017','sub-018','sub-019','sub-020','sub-021','sub-022','sub-023','sub-024','sub-095','sub-026','sub-027','sub-028','sub-029','sub-030','sub-031','sub-032'};

ouput_dir='C:\Users\haozi\OneDrive\Desktop\PhD\fMRI_PrC-PPC_data\Rev_1_test-decoding';

table_sz=[length(sub_list),10];
vartype=["string","double","double","double","double","double","double","double","double","double"];
varname=["SSID","rec_xgy","rec_xsy","rec_anova","life_xgy","life_xsy","life_anova","task_xgy","task_xsy","task_anova"];
sub_results=table('Size',table_sz,'VariableTypes',vartype,'VariableNames',varname);

for i=1:length(sub_list)
    results_dir=strcat(ouput_dir,'/',sub_list{i});
    %recent decoding select high > low
    temp=load(strcat(results_dir,'/rec_high3_xgy.mat'));
    res_rec_h3_xgy=temp.results.total_perf;
    temp=load(strcat(results_dir,'/rec_low3_xgy.mat'));
    res_rec_l3_xgy=temp.results.total_perf;
    rec_xgy=mean([res_rec_h3_xgy,res_rec_l3_xgy]);

    %recent decoding select high < low
    temp=load(strcat(results_dir,'/rec_high3_xsy.mat'));
    res_rec_h3_xsy=temp.results.total_perf;
    temp=load(strcat(results_dir,'/rec_low3_xsy.mat'));
    res_rec_l3_xsy=temp.results.total_perf;
    rec_xsy=mean([res_rec_h3_xsy,res_rec_l3_xsy]);

    %recent decoding select high != low
    temp=load(strcat(results_dir,'/rec_high3_anova.mat'));
    res_rec_h3_anova=temp.results.total_perf;
    temp=load(strcat(results_dir,'/rec_low3_anova.mat'));
    res_rec_l3_anova=temp.results.total_perf;
    rec_anova=mean([res_rec_h3_anova,res_rec_l3_anova]);

    %lifetime decoding select high > low
    temp=load(strcat(results_dir,'/life_high3_xgy.mat'));
    res_life_h3_xgy=temp.results.total_perf;
    temp=load(strcat(results_dir,'/life_low3_xgy.mat'));
    res_life_l3_xgy=temp.results.total_perf;
    life_xgy=mean([res_life_h3_xgy,res_life_l3_xgy]);

    %lifetime decoding select high < low
    temp=load(strcat(results_dir,'/life_high3_xsy.mat'));
    res_life_h3_xsy=temp.results.total_perf;
    temp=load(strcat(results_dir,'/life_low3_xsy.mat'));
    res_life_l3_xsy=temp.results.total_perf;
    life_xsy=mean([res_life_h3_xsy,res_life_l3_xsy]);

    %lifetime decoding select high != low
    temp=load(strcat(results_dir,'/life_high3_anova.mat'));
    res_life_h3_anova=temp.results.total_perf;
    temp=load(strcat(results_dir,'/life_low3_anova.mat'));
    res_life_l3_anova=temp.results.total_perf;
    life_anova=mean([res_life_h3_anova,res_life_l3_anova]);

    %task decoding select recent > lifetime
    temp=load(strcat(results_dir,'/task_na_xgy.mat'));
    task_xgy=temp.results.total_perf;

    %task decoding select recent < lifetime
    temp=load(strcat(results_dir,'/task_na_xsy.mat'));
    task_xsy=temp.results.total_perf;

    %task decoding select recent != lifetime
    temp=load(strcat(results_dir,'/task_na_anova.mat'));
    task_anova=temp.results.total_perf;

    sub_results(i,:)={sub_list{i},rec_xgy,rec_xsy,rec_anova,life_xgy,life_xsy,life_anova,task_xgy,task_xsy,task_anova};
end

%convert to cellstr
sub_results.SSID=cell2mat(cellstr(sub_results.SSID));
%trash MATLAB function so damn hard to output csv file, had to use xlsx
writetable(sub_results,strcat(ouput_dir,"/compiled_results.xlsx"));

%sanity check one-sample t-tests
for j=2:10
[~,p]=ttest(table2array(sub_results(:,j)),0.5,'Tail','right')
end
%other than task recent > life selection, everything is above chance. 

%% extract voxels that are selected for >, < or != for each subject, aggregate across cross-validation folds and generate nifti files
