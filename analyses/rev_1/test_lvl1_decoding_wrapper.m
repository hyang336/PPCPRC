%% wrapper function around test_1stlvl_decoding_highlow.m to iterate through classification type, bin type, and feature-selection type
function test_lvl1_decoding_wrapper(project_derivative,GLM_dir,ASHS_dir,sub)
c_types={'rec','life','task'};
bin_types={'high3','low3'};
fs_types={'xgy','xsy','anova'};

for i=1:length(fs_types)
    for j=1:length(c_types)
        if ~strcmp(c_types{j},'task')
            for k=1:length(bin_types)
                test_1stlvl_decoding_highlow(project_derivative,GLM_dir,ASHS_dir,sub,c_types{j},bin_types{k},fs_types{i});
            end
        else
            %if task decoding, bin type doesnt matter
            test_1stlvl_decoding_highlow(project_derivative,GLM_dir,ASHS_dir,sub,c_types{j},bin_types{1},fs_types{i});
        end
    end
end
end

         