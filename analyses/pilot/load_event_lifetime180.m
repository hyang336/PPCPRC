%ExpStartTime is the last dummy trigger plus a couple ms to run through that for-loop

function eventout=load_event_lifetime180(project_derivative,sub,task,run)
lifetime_events=fullfile(strcat(project_derivative,'/behavioral/pilot/',sub,'/',task,run,'.xlsx'));
[~,~,raw]=xlsread(lifetime_events{1});%should have only 1 file, hopefully
event=cell(size(raw,1),3);
event(1,1:3)={'onset','duration','type'};
%find columns of interest based on headers
[~,startcol]=find(cellfun(@(x)strcmp(x,'ExpStartTime'),raw(1,1:end)));
[~,onsetcol]=find(cellfun(@(x)strcmp(x,'StimOnsetTime'),raw(1,1:end)));
[~,respcol]=find(cellfun(@(x)strcmp(x,'Response'),raw(1,1:end)));
event(2:end,1)=num2cell(cellfun(@(x,y)x-y,raw(2:end,onsetcol),raw(2:end,startcol)));%onset corrected for exp start time
event(2:end,2)={2.5};
event(2:end,3)=raw(2:end,respcol);
eventout=event(2:end,:);%no headers
end