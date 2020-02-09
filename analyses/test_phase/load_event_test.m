%ExpStartTime is the last dummy trigger plus a couple ms to run through that for-loop

function eventout=load_event_test(project_derivative,sub,task,run)
lifetime_events=fullfile(strcat(project_derivative,'/behavioral/',sub,'/',sub,'_',task,run,'data','.xlsx'));
[~,~,raw]=xlsread(lifetime_events{1});%should have only 1 file, hopefully
event=cell(size(raw,1),7);
event(1,1:7)={'onset','obj_freq','norm_fam','task','duration','resp','RT'};
%find columns of interest based on headers
[~,startcol]=find(cellfun(@(x)strcmp(x,'ExpStartTime'),raw(1,1:end)));
[~,obj_freq_col]=find(cellfun(@(x)strcmp(x,'objective_freq'),raw(1,1:end)));
[~,norm_fam_col]=find(cellfun(@(x)strcmp(x,'norm_fam'),raw(1,1:end)));
[~,task_col]=find(cellfun(@(x)strcmp(x,'task'),raw(1,1:end)));
[~,onsetcol]=find(cellfun(@(x)strcmp(x,'StimOnsetTime'),raw(1,1:end)));
[~,respcol]=find(cellfun(@(x)strcmp(x,'Response'),raw(1,1:end)));
[~,RTcol]=find(cellfun(@(x)strcmp(x,'RespTime'),raw(1,1:end)));
event(2:end,1)=num2cell(cellfun(@(x,y)x-y,raw(2:end,onsetcol),raw(2:end,startcol)));%onset corrected for exp start time
event(2:end,2)=raw(2:end,obj_freq_col);
event(2:end,3)=raw(2:end,norm_fam_col);
event(2:end,4)=raw(2:end,task_col);
event(2:end,5)={2.5};
event(2:end,6)=raw(2:end,respcol);
event(2:end,7)=raw(2:end,RTcol);
eventout=event(2:end,:);%no headers
end