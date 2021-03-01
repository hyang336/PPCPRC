SVM_dir='I:\scratch\working_dir\PPC_MD\MVPA\PrC_test_phase_SVM';
sub_list={'sub-001','sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-011','sub-013','sub-014','sub-016','sub-020','sub-021','sub-022','sub-026','sub-095'};

%mean_di
for i=1:length(sub_list)
   load(strcat(SVM_dir,'/',sub_list{i},'/output/lifetime_mean_di_SVM.mat'));
   lifetime_mean_di_error(i)=lifetime_ce;
   load(strcat(SVM_dir,'/',sub_list{i},'/output/recent_mean_di_SVM.mat'));
   recent_mean_di_error(i)=recent_ce;
end

%3_di
for i=1:length(sub_list)
   load(strcat(SVM_dir,'/',sub_list{i},'/output/lifetime_3_di_SVM.mat'));
   lifetime_3_di_error(i)=lifetime_ce;
   load(strcat(SVM_dir,'/',sub_list{i},'/output/recent_3_di_SVM.mat'));
   recent_3_di_error(i)=recent_ce;
end

%% plot
bar(categorical(sub_list),lifetime_error)
ylabel('classification error');

bar(categorical(sub_list),recent_error)
ylabel('classification error');

%% stats
[hl,pl,cil,statsl] = ttest(lifetime_error-0.5)
[hr,pr,cir,statsr] = ttest(recent_error-0.5)

[h,p,ci,stats] = ttest(recent_3_di_error-0.5,recent_mean_di_error-0.5)
[h,p,ci,stats] = ttest(lifetime_3_di_error-0.5,lifetime_mean_di_error-0.5)