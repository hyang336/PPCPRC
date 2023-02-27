%ExpStartTime is the last dummy trigger plus a couple ms to run through that for-loop
% 20200110 added script to also return feature overlap value pulled from a
% reference spreadsheet, one column with feature-overlap
% calculated with 541 items in the database, the other
% column with binary (high/low) feature overlap
function eventout=load_event_test(project_derivative,sub,task,run,expstart_vol,TR)
lifetime_events=fullfile(strcat(project_derivative,'/behavioral/',sub,'/',sub,'_',task,run,'data','.xlsx'));
% run and task would be in a cell created by the outer
% script, otherwise the next line won't work. Check help
% fullfile
if iscell(lifetime_events)
    [~,~,raw]=xlsread(lifetime_events{1});%should have only 1 file, hopefully 
elseif ischar(lifetime_events)
    [~,~,raw]=xlsread(lifetime_events);
end
[~,~,fo_sheet]=xlsread('stimulus_select_5.2.xlsm',1);%spreadsheet containing feat_overlap
[~,~,t_sheet]=xlsread('lifetime_episem_regress_29ss.xlsx',1);%spreadsheet containing epi_t and sem_t
feat_over=fo_sheet(2:91,1:2);%pull out all stimuli and their feat_over for later search
feat_over(91:180,1:2)=fo_sheet(2:91,13:14);

event=cell(size(raw,1),12);
event(1,1:12)={'onset','obj_freq','norm_fam','task','duration','resp','RT','feat_over','feat_di','stimuli','epi_t','sem_t'};

%find columns of interest based on headers
[~,startcol]=find(cellfun(@(x)strcmp(x,'ExpStartTime'),raw(1,1:end)));
[~,obj_freq_col]=find(cellfun(@(x)strcmp(x,'objective_freq'),raw(1,1:end)));
[~,norm_fam_col]=find(cellfun(@(x)strcmp(x,'norm_fam'),raw(1,1:end)));
[~,task_col]=find(cellfun(@(x)strcmp(x,'task'),raw(1,1:end)));
[~,onsetcol]=find(cellfun(@(x)strcmp(x,'StimOnsetTime'),raw(1,1:end)));
[~,respcol]=find(cellfun(@(x)strcmp(x,'Response'),raw(1,1:end)));
[~,RTcol]=find(cellfun(@(x)strcmp(x,'RespTime'),raw(1,1:end)));
[~,stimcol]=find(cellfun(@(x)strcmp(x,'Stimuli'),raw(1,1:end)));

onset_temp=num2cell(cellfun(@(x,y)x-y,raw(2:end,onsetcol),raw(2:end,startcol)));%onset corrected for exp start time
event(2:end,1)=num2cell(cellfun(@(x) x+(expstart_vol-1)*TR, onset_temp));%corrected for dummy TRs
event(2:end,2)=raw(2:end,obj_freq_col);
event(2:end,3)=raw(2:end,norm_fam_col);
event(2:end,4)=raw(2:end,task_col);
event(2:end,5)={2.5};
event(2:end,6)=raw(2:end,respcol);
event(2:end,7)=raw(2:end,RTcol);
event(2:end,10)=raw(2:end,stimcol);

for i=2:size(event,1)
    [word_id,~]=find(strcmp(event{i,10},feat_over(1:end,1)));%find the word
    [word_id_regress,~]=find(strcmp(event{i,10},t_sheet(2:end,9)));%find word for epi_t and sem_t
    event{i,11}=t_sheet{word_id_regress+1,5};%has header
    event{i,12}=t_sheet{word_id_regress+1,8};
    event{i,8}=feat_over{word_id,2};%fill in the feat_over value
    if event{i,8}>0.04%binarize, note that for a given run there may be different # of high and low feat_over trials, so they still needs to be demeaned(orthogonalized) in SPM as parametric modulator
        event{i,9}=1;
    else
        event{i,9}=-1;
    end
end
eventout=event(2:end,:);%no headers
end