function[] = TestPlay(sub,runNo)

addpath(genpath('/home/kohlerlab/Documents/Sudesna'))
PsychPortAudio('Close');

%% Declare Constants
C.versionNum = 2;
C.ORDERING = {'Pieman_soundcheck','Pieman_Intact','Pieman_Scrambled','Parachute_Intact'};
C.FILE_DIR = '/home/kohlerlab/Documents/Sudesna/Clips/';
C.PRE_WAIT_TIME = 5;
C.POST_WAIT_TIME = 15;
C.CLIP_TIME = 5; % CLIP_TIME is contained within POST_WAIT_TIME

%% Store Data for Output
output.runNo = runNo;
output.thisFile = C.ORDERING(runNo);
if ~exist(strcat('/home/kohlerlab/Documents/Sudesna/Data/', sprintf('%02d',sub)),'dir')
    mkdir(strcat('/home/kohlerlab/Documents/Sudesna/Data/', sprintf('%02d',sub)));
end
output.matName = strcat('/home/kohlerlab/Documents/Sudesna/Data/', sprintf('%02d',sub), '/Correlation_', sprintf('%02d',sub), '_', output.thisFile{1}, '_R', mat2str(runNo), '.mat');
if exist(output.matName, 'file')
    error('File with these input parameters already exists!');
end

%% Load and Initialize Audio Files for Feedback   
audioFile.thisFile = dir(fullfile(C.FILE_DIR, [output.thisFile{1} '.wav']));  %create a structure containing all associated files        
[audioFile.wavedata, audioFile.freq] = audioread(fullfile(C.FILE_DIR, audioFile.thisFile.name)); % load sound file
audioFile.duration = length(audioFile.wavedata) ./ audioFile.freq;
audioFile.channels = size(audioFile.wavedata,2);
audioFile.pahandle = PsychPortAudio('Open', [], [], 2, audioFile.freq, audioFile.channels, 0); % opens sound buffer at a different frequency
PsychPortAudio('FillBuffer', audioFile.pahandle, audioFile.wavedata'); % loads data into buffer
InitializePsychSound(1); %initializes sound driver...the 1 pushes for low latency   
save(output.matName);

%% Begin Run
disp(['Read Blurb to Participant: ' output.thisFile{1}]);
disp('Start the fMRI Scan Now, making sure the scan matches the Audio File');
disp('Waiting for Trigger to Start Experiment');

output.runStart = GetSecs; 
keyCodes(1:256) = 0; 
while keyCodes(29)==0 %Trigger set to 't'
     [keyIsDown, secs, keyCodes, deltaSecs] = KbCheck;
end
    
%% Play Audio Clip and wait for BOLD response to come back down
disp('Experiment Starting!');
WaitSecs(C.PRE_WAIT_TIME);
output.startSoundTime = GetSecs - output.runStart;
PsychPortAudio('Start', audioFile.pahandle, 1,0); % starts sound immediately
WaitSecs(audioFile.duration); % waits for the whole duration of sound for it to play,if this wait is too short then sounds will be cutoff
output.endSoundTime = GetSecs - output.runStart;
output.actualSoundDuration = output.endSoundTime - output.startSoundTime;
WaitSecs(C.CLIP_TIME);
output.stopSoundTime = GetSecs - output.runStart;
PsychPortAudio('Stop', audioFile.pahandle); % Stop sound playback
WaitSecs(C.POST_WAIT_TIME-C.CLIP_TIME);
output.runDuration = GetSecs - output.runStart;
disp('Done!');
clear runNo sub ans audioFile;
save(output.matName);

%% Clean Up
PsychPortAudio('Close');
clear all;
               
