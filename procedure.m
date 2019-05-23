%% need to update this!!! 2019-04-20
function [output,errors]=procedure(SSID,version_inp,project_dir,pathdata,varargin)
%16 versions (hand (2) * set_selection (2) * block_order (4)).
%study phase one run, test phase one run, both triggered by scanner.
%pseudorandomization done for each Ss individually.
%study phase has spacing constraint for repetitions
%test phase presentation is simple shuffling, since there is no repetition.

%% input parser

%study phase has 5 runs of 90 trials, key_practice has one
%run of however many trials (max 10 mins will be scanned),
%test phase has 4 runs of 45 trials, post_scan has one run
%of 180 trials.
p = inputParser;

%default start from the beginning of the study phase and run
%through all phases
defaultPhase = 'study';
validPhase={'study','key_prac','test','post_scan'};
checkPhase=@(x) any(validatestring(x,validPhase));
defaultRun = 1;
checkRun=@(x) isinteger(int8(x))&&(x>0)&&(x<6);
defaultTrial=1;
checkTrial=@(x) isinteger(int8(x))&&(x>0)&&(x<91);

addRequired(p,'SSID');
addRequired(p,'version_inp');
addRequired(p,'project_dir');
addRequired(p,'pathdata');
addParameter(p,'phase',defaultPhase,checkPhase);
addParameter(p,'run',defaultRun,checkRun);
addParameter(p,'trial',defaultTrial,checkTrial);

%parse
parse(p,SSID,version_inp,project_dir,pathdata,varargin{:});

%% surpress the screen sync error on Windows, will like result in wildly inaccurate timing of stimulus onsets
Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);

%% add project path, may be changed for different PC
addpath(genpath(project_dir));

%% initialize constants
KbName('UnifyKeyNames');
scan_trig=KbName('5%');
experimenter_pass=KbName('e');
%create data cell, later use xlswrite to export
data=cell(811,12);%630 trials in scanner, and 180 trials post-scan, plus headers
data(1,:)={'ParticipantNum' 'Version' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'objective_freq' 'norm_fam' 'task' 'StimOnsetTime' 'Response' 'RespTime'};
SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
data(2:end,1)={SSID};
data(2:end,2)={version_inp};
mkdir(pathdata,SSID);

screens=Screen('Screens');
scanner_screen=max(screens);%before running the script, use Screen('Screens') to determine the scanner screen number

addtrig=5;%exp start at the 5th trigger


%% specify hand mapping, load stimuli and block order according to version number
[study_stim,test_stim,hand]=version_select(version_inp);
    study_txt=study_stim(:,1);%stimuli
    study_num=study_stim(:,2);%jitter
    test_txt=test_stim(:,1);%stimuli
    test_num=test_stim(:,2);%jitter

%% set up screen 
try
    [w,rect]=Screen('OpenWindow', scanner_screen);
    y_mid=(rect(2)+rect(4))/2;%get the y mid point of the screen for presentation use
    
% %     %code for instruction screen testing below
% %     [nx, ny, bbox] = DrawFormattedText(w, page1,'center','center');
% %     Screen('Flip',w);
% %     waittrig=1;
% %     while waittrig
% %     [keyIsDown, instime, keyCodes] = KbCheck;
% %     if keyCodes(flippage)==1
% %         waittrig=0;
% %     end
% %     end
% %     %page2
% %     [nx, ny, bbox] = DrawFormattedText(w, page2,'center','center');
% %     Screen('Flip',w);
% %     %cant use KbStrokeWait since scanner trigger will be treated as
% %     %a key press
% %     waittrig=1;
% %     while waittrig
% %     [keyIsDown, instime, keyCodes] = KbCheck;
% %     if keyCodes(ins_done)==1
% %         waittrig=0;
% %     end
% %     end
% %     WaitSecs(3);
% %     Screen('CloseAll');



% call sub-procedures and pass in PTB window, stimuli, and hand mapping, return responses.
% need to have an indicator for the operator to start the scan. Also return the trial
% number of the last-run trial. If anything returns an error, we can pass in those to
% continue. Also wait for experimenter inputs between phases.

if strcmp(p.Results.phase,'study')
%stage 1: call function handling study phase presentation, loop over runs with break in between
    [resp_sofar,study_error] = study(pathdata,SSID,addtrig,w,y_mid,study_txt,study_num,hand,p.Results.run,p.Results.trial);
    %find none empty trials
    [trial_row,~]=find(~cellfun('isempty',resp_sofar(1:end,8)));%search the onset column (8)
    data(trial_row+1,3:12)=resp_sofar(trial_row,1:10);%test line
    %if an error occured in the study phase, terminate the
    %function and return the error, study_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(study_error,'none')
        errors=study_error;
        return
    else
        errors='none';
    end
    
    %wait for experimenter input (continue or terminate)
    
    
%stage 2: call function handling practice, one long run (~15 min). If subject cannot complete the task within that time, the rest is not scanned.

%stage 3: call function handling test phase presentation, loop over runs with break in between

%stage 4: post-process scanning data, use ExpStartTime to assign runs. The "run" field was used to select stimuli to present so it had to fall within a certain range, but now it needs to reflect the actual run number, which can be outside of that range if error occured and a run was broken into multiple runs. However, any run would have the same ExpStartTime.
    scandata=data;%copy the unprocessed data just in case
    
%stage 5: call function handling post-scan test, instruct participants to get out of scanner (lock keys during that), remap keys


elseif strcmp(p.Results.phase,'key_prac')
%stage 2:

%stage 3:

%stage 4:

%stage 5:

elseif strcmp(p.Results.phase,'test')
%stage 3:

%stage 4:

%stage 5:

elseif strcmp(p.Results.phase,'post_scan')
%stage 5:

end

xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_alldata.xlsx'),data);
Screen('CloseAll');
output=data;

catch ME
        Screen('CloseAll');
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_alldata.xlsx'),data);
        output=data;
        errors=ME;
end
end