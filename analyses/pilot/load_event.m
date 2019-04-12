function eventout=load_event(project_derivative,subject_id,task,run)
%% Import data from E-prime file.
% Script for importing data from the E-prime spreadsheet


%% Initialize variables.
%E-prime event file name
filename = strcat(project_derivative,'/behavioral/pilot/',subject_id,'/',task,'_',subject_id,'_',num2str(run),'.xlsx');
[~,~,raw]=xlsread(filename);

[~,block_col]=find(cellfun(@(x)strcmp(x,'Procedure[Trial]'),raw));
[~,onset_col]=find(cellfun(@(x)strcmp(x,'Stimuli.OnsetTime'),raw));
[~,s_col]=find(cellfun(@(x)strcmp(x,'Scarmbled'),raw));%someone misspelled the name...
[s_row,~]=find(cellfun(@(x)~isnan(x),raw(2:end,s_col)));
s_row=s_row+1;%had to count from the 2nd row in raw, add 1 after find() to get back to the row index in raw
[~,f_col]=find(cellfun(@(x)strcmp(x,'F'),raw));
[f_row,~]=find(cellfun(@(x)~isnan(x),raw(2:end,f_col)));
f_row=f_row+1;
[~,o_col]=find(cellfun(@(x)strcmp(x,'O'),raw));
[o_row,~]=find(cellfun(@(x)~isnan(x),raw(2:end,o_col)));
o_row=o_row+1;
[~,p_col]=find(cellfun(@(x)strcmp(x,'P'),raw));
[p_row,~]=find(cellfun(@(x)~isnan(x),raw(2:end,p_col)));
p_row=p_row+1;

s_trial=cell(length(s_row),2);
s_trial(:,1)=num2cell(s_row);
s_trial(:,2)={'s'};
f_trial=cell(length(f_row),2);
f_trial(:,1)=num2cell(f_row);
f_trial(:,2)={'f'};
o_trial=cell(length(o_row),2);
o_trial(:,1)=num2cell(o_row);
o_trial(:,2)={'o'};
p_trial=cell(length(p_row),2);
p_trial(:,1)=num2cell(p_row);
p_trial(:,2)={'p'};

trials=[s_trial;f_trial;o_trial;p_trial];
trials=sortrows(trials,1);
block_type=trials(1:32:end,2);

[trial_row,~]=find(cellfun(@(x)strcmp(x,'TrialProc'),raw(:,block_col)));
trial_onsets=raw(trial_row,onset_col);
block_onset=trial_onsets(1:32:end);
block_offset=trial_onsets(32:32:end);
block_duration=(cell2mat(block_offset)-cell2mat(block_onset)+400)./1000;%the times are onsets, need to add a duration of another trial for each block
block_onset_realign=(cell2mat(block_onset)-block_onset{1})./1000;%and convert to second

headers={'onset','duration','type'};
event=[num2cell(block_onset_realign),num2cell(block_duration),block_type];
eventh=[headers;event];
%for now put the event.tsv inside the derivatives/behavoral/pilot/ folder since I don't have
%write access to the bids folder, and using xlswrite since it's a fucking pain in the ass
%to use dlmwrite or fprintf to output cell
run=sprintf('%02d',run);
filetosave=strcat(subject_id,'_task-',task,'_run-',run,'_bold_events.xlsx');
%xlswrite(strcat(project_derivative,'/behavioral/pilot/',filetosave),eventh);

eventout=event;

end