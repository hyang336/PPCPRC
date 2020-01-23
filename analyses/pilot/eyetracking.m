%script to transform eye-tracking data into an fMRI
%compatible format
data=Edf2Mat('C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC_data\pilot\eye_tracking\001\001_eyeD.edf');

trial_onsets=find(strcmp(data.Events.Messages.info,'SYNCTIME'));
trial_offsets=find(strcmp(data.Events.Messages.info,'TRIAL_RESULT 0'));

trial_time=zeros(2,length(trial_onsets)); %onset on row 1 and offset on row 2, column marks trials
for i=1:length(trial_onsets)
trial_time(:,i)=data.Events.Messages.time(trial_onsets(i):trial_offsets(i));
end

trial_onset_samples=find(data.Samples.time==trial_time(1,:));
trial_offset_samples=find(data.Samples.time==trial_time(2,:));

