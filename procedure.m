%% need to update this!!! 2019-04-20
function [output,errors]=procedure(SSID,version_inp,project_dir,pathdata,varargin)
%16 versions (hand (2) * set_selection (2) * block_order (4)).
%study phase one run, test phase one run, both triggered by scanner.
%pseudorandomization done for each Ss individually.
%study phase has spacing constraint for repetitions
%test phase presentation is simple shuffling, since there is no repetition.

%the script is cumulative:
%only the corresponding input phase can start from different run
%and trials, all subsequent phases always start from run 1
%and trial 1.
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
% scan_trig=KbName('5%');
experimenter_pass=KbName('e');
termkey=KbName('t');

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
    HideCursor;
    y_mid=(rect(2)+rect(4))/2;%get the y mid point of the screen for presentation use

% call sub-procedures and pass in PTB window, stimuli, and hand mapping, return responses.
%% start from study phase
if strcmp(p.Results.phase,'study')
%stage 1: call function handling study phase presentation, loop over runs with break in between
    [resp_sofar,study_error,terminated] = study(pathdata,SSID,addtrig,w,y_mid,study_txt,study_num,hand,p.Results.run,p.Results.trial);
    %find none empty trials
    [trial_row,~]=find(~cellfun('isempty',resp_sofar(1:end,8)));%search the onset column (8)
    data(trial_row+1,3:12)=resp_sofar(trial_row,1:10);%fill in the data
    
    %if an error occured in the study phase, terminate the
    %function and return the error, study_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(study_error,'none')
        errors=study_error;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        BIDS_event(pathdata,SSID,data)%call data parser
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter half run,
    %re-engage the study phase function from the next trial to have a new run
    while strcmp(terminated,'yes')
        if mod(max(trial_row),90)==0%if terminated at the last trial of a run,since trial_row can only go from 1 to 450
            terminated='none';%skip the while loop
            continue
        end
        lastrun=round(max(trial_row)/90);%find the maximum run number
        lasttrial=mod(max(trial_row),90);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0, A is an integer
        [resp_sofar,study_error,terminated] = study(pathdata,SSID,addtrig,w,y_mid,study_txt,study_num,hand,lastrun,lasttrial+1);
        [trial_row,~]=find(~cellfun('isempty',resp_sofar(1:end,8)));%search the onset column (8)
        data(trial_row+1,3:12)=resp_sofar(trial_row,1:10);%fill in the data
        if ~strcmp(study_error,'none')
            errors=study_error;
            return
        else
            errors='none';
        end
    end
    
    %wait for experimenter input (continue to next phase or terminate and save all the data so far)
       waittrig=1;
           while waittrig
            [keyIsDown, dummy_start, keyCodes] = KbCheck;
            if keyCodes(experimenter_pass)==1%if continue
                waittrig=0;
            elseif keyCodes(termkey)==1%if terminate and save
                xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
                BIDS_event(pathdata,SSID,data)%call data parser
                Screen('CloseAll');
                ShowCursor;
                output=data;
                return
            end
           end
       %need to have these two lines to wait for the key release
       while KbCheck
       end
    
%stage 2: call function handling practice, one long run (~15 min). If subject cannot complete the task within that time, the rest is not scanned.
       [resp_keyprac,keyprac_errors,keyprac_terminated]=key_prac_scan(project_dir,pathdata,SSID,addtrig,w,hand,1);
       [trial_row,~]=find(~cellfun('isempty',resp_keyprac(1:end,8)));
       keypracdata=data(1,:);
       keypracdata(trial_row+1,3:12)=resp_keyprac(trial_row,1:10);%fill in the dataresp_sofar(trial_row,1:10);%fill in the data
       xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_task-keyprac_data.xlsx'),keypracdata);
       
       %if errors occurred in practice phase, return study
       %data so far and error msg, then terminate the function
       if ~strcmp(keyprac_errors,'none')
        errors=keyprac_errors;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        BIDS_event(pathdata,SSID,data)%call data parser
        output=data;
        ShowCursor;
        return
        else
            errors='none';
       end
        
       %if it was terminated by the experimenter, just
       %proceed.
       waittrig=1;
       DrawFormattedText(w, 'please stay ready for the next phase', 'center', 'center');
       Screen(w, 'Flip');
           while waittrig
            [keyIsDown, dummy_start, keyCodes] = KbCheck;
            if keyCodes(experimenter_pass)==1%if continue
                waittrig=0;
            elseif keyCodes(termkey)==1%if terminate and save
                xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
                BIDS_event(pathdata,SSID,data)%call data parser (for study phase data at this stage
                Screen('CloseAll');
                ShowCursor;
                output=data;
                return
            end
           end
       %need to have these two lines to wait for the key release
       while KbCheck
       end
       
%stage 3: call function handling test phase presentation, loop over runs with break in between
    %data gotta be filled from trial_row+451, to not
    %overwrite study phase data

%stage 4: call function handling post-scan test, instruct participants to get out of scanner (lock keys during that), remap keys
    %data gotta be filled from trial_row+631, to not
    %overwrite study and test phase data
%% start from key practice phase
elseif strcmp(p.Results.phase,'key_prac')
%stage 2:
       [resp_keyprac,keyprac_errors,keyprac_terminated]=key_prac_scan(project_dir,pathdata,SSID,addtrig,w,hand,1);
       [trial_row,~]=find(~cellfun('isempty',resp_keyprac(1:end,8)));
       keypracdata=data(1,:);
       keypracdata(trial_row+1,3:12)=resp_keyprac(trial_row,1:10);%fill in the dataresp_sofar(trial_row,1:10);%fill in the data
       xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_task-keyprac_data.xlsx'),keypracdata);      
       
       %if errors occurred in practice phase, return study
       %data so far and error msg, then terminate the function
       if ~strcmp(keyprac_errors,'none')
        errors=keyprac_errors;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        BIDS_event(pathdata,SSID,data)%call data parser
        output=data;
        ShowCursor;
        return
        else
            errors='none';
       end
        
       %if it was terminated by the experimenter, just
       %proceed.
       waittrig=1;
       DrawFormattedText(w, 'please stay ready for the next phase', 'center', 'center');
       Screen(w, 'Flip');
           while waittrig
            [keyIsDown, dummy_start, keyCodes] = KbCheck;
            if keyCodes(experimenter_pass)==1%if continue
                waittrig=0;
            elseif keyCodes(termkey)==1%if terminate and save
                xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
                BIDS_event(pathdata,SSID,data)%call data parser (for study phase data at this stage
                Screen('CloseAll');
                ShowCursor;
                output=data;
                return
            end
           end
       %need to have these two lines to wait for the key release
       while KbCheck
       end
       
%stage 3:

%stage 4:

%% start from test phase
elseif strcmp(p.Results.phase,'test')
%stage 3:

%stage 4:

%% start from post-scan phase
elseif strcmp(p.Results.phase,'post_scan')
%stage 4:

end

%% save the combined behavioral data
%overall data from the current execution of this function
xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
Screen('CloseAll');
ShowCursor;
output=data;

catch ME
        Screen('CloseAll');
        ShowCursor;
        %overall data from the current execution of this function
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        output=data;
        errors=ME;
end
end