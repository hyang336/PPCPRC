%discarded, noresp trials are modeled as a regressor of non-interest now
function medianresp=lifetime_mean(project_derivative,sub)
lifetime_events=fullfile(strcat(project_derivative,'/behavioral/pilot/',sub,'/'),'*lifetime*.xlsx');
lifetime_file=dir(lifetime_events);
for i=1:length(lifetime_file)
[~,~,raw{i}]=xlsread(strcat(project_derivative,'/behavioral/pilot/',sub,'/',lifetime_file(i).name));

resp((i-1)*length(raw{i}(2:end,7))+1:i*length(raw{i}(2:end,7)),1)=cell2mat(raw{i}(2:end,7));
end
medianresp=nanmedian(resp);

end