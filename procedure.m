%% need to update this!!! 2019-04-20
function [output,errors]=procedure(SSID,version_inp,project_dir,pathdata,varargin)
%The script has built in error handling. At each trial of
%any phases, the experimenter can press the pause key (P) to
%pause the experiment after the current trial. Participants’
%responses will still be recorded for the paused trial, and
%saved in the disk as a .mat file with all responses so far
%for the current phase (study, key_prac, test). The
%experimenter can choose to continue the paused experiment
%by pressing the experimenter pass key (E), which will lead
%to the presentation of a fixation cross for 2 seconds, then
%continue to the next trial, with all the appropriate
%instructions and prompt for the participants. The
%experimenter can also choose to terminate the paused
%experiment by pressing the terminate key (T). This is to
%handle the situation when something happened to the
%scanner and a separate run has to be started. For the study
%and the test phase, the script will automatically relunch
%after pressing the terminate key from the next trial. For
%the key-prac phase, the script will proceed into the next
%phase (i.e. test phase) since the stimuli in the key_prac
%phase is not of set order but are continuously and randomly
%sampled. This also allow the experimenter to manully
%terminate the key_prac phase if it runs too long.

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
defaultPilot='';
validPilot={'','pilot'};
checkPilot=@(x) any(validatestring(x,validPilot));

addRequired(p,'SSID');
addRequired(p,'version_inp');
addRequired(p,'project_dir');
addRequired(p,'pathdata');
addParameter(p,'phase',defaultPhase,checkPhase);
addParameter(p,'run',defaultRun,checkRun);
addParameter(p,'trial',defaultTrial,checkTrial);
addParameter(p,'pilot',defaultPilot,checkPilot);

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
    
    temppp=cell(1);
for i=1:36%36 small blocks in the test phase
    nexttask=test_stim{(i-1)*5+1,4};
    temppp{i,1}=nexttask;
%     temppp{1+6*(i-1),4}= strcat('switch_to_',nexttask);
%     temppp{1+6*(i-1),1}=strcat(nexttask,' judgement task begins');%switch task prompt
%     temppp{1+6*(i-1),2}=3;%always have a 3s ISI for the switching trial
%     temppp(2+6*(i-1):6+6*(i-1),:)=test_stim((i-1)*5+1:(i-1)*5+5,:);%fill in the rest
end

    test_txt=test_stim(:,1);%stimuli
    test_num=test_stim(:,2);%jitter
    test_task=temppp;%task

    %if is pilot testing the script, change key mappings
    if strcmp(p.Results.pilot,'pilot')
        switch hand.ver
            case 'L5animate'
                hand.r5=KbName('s');
                hand.r4=KbName('d');
                hand.r3=KbName('f');
                hand.r2=KbName('j');
                hand.r1=KbName('k');
            case 'R5animate'
                hand.r5=KbName('l');
                hand.r4=KbName('k');
                hand.r3=KbName('j');
                hand.r2=KbName('f');
                hand.r1=KbName('d');
        end
    end
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
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the study phase function from the next trial to have a new run
    while strcmp(terminated,'yes')
        if floor(max(trial_row)/90)==5%if terminated at the last trial of the last run (i.e. trial 450)
            terminated='none';%skip the while loop
            continue
        elseif floor(max(trial_row)/90)~=5&&mod(max(trial_row),90)==0%if terminated at the last trial the first n-1 runs
            lastrun=floor(max(trial_row)/90);%find the maximum run number
            [resp_sofar,study_error,terminated] = study(pathdata,SSID,addtrig,w,y_mid,study_txt,study_num,hand,lastrun+1,1);%start from the 1st trial of the next run
            [trial_row,~]=find(~cellfun('isempty',resp_sofar(1:end,8)));%search the onset column (8)
            data(trial_row+1,3:12)=resp_sofar(trial_row,1:10);%fill in the data
        else
            lastrun=floor(max(trial_row)/90);%find the maximum run number
            lasttrial=mod(max(trial_row),90);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_sofar,study_error,terminated] = study(pathdata,SSID,addtrig,w,y_mid,study_txt,study_num,hand,lastrun,lasttrial+1);%start from the next trial of the current run
            [trial_row,~]=find(~cellfun('isempty',resp_sofar(1:end,8)));%search the onset column (8)
            data(trial_row+1,3:12)=resp_sofar(trial_row,1:10);%fill in the data
        end
        if ~strcmp(study_error,'none')
            errors=study_error;
            BIDS_event(pathdata,SSID,data)%call data parser
            ShowCursor;
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
       keypracdata=data(1,:);%get headers
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
   [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,1,1);
   %find none empty trials
    [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
    data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data from row 451
    
    %if an error occured in the test phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(test_error,'none')
        errors=test_error;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        BIDS_event(pathdata,SSID,data)%call data parser
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(test_terminated,'yes')
        if floor(max(trial_row)/45)==4%if terminated at the last trial of the last run (i.e. trial 1800)
            test_terminated='none';%skip the while loop
            continue
        elseif floor(max(trial_row)/45)~=4&&mod(max(trial_row),45)==0%if terminated at the last trial the first n-1 runs
            lastrun=floor(max(trial_row)/45);%find the maximum run number
            [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,lastrun+1,1);%start from the 1st trial of the next run
            [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
            data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data
        else
            lastrun=floor(max(trial_row)/45);%find the maximum run number
            lasttrial=mod(max(trial_row),45);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,lastrun,lasttrial+1);%start from the next trial of the current run
            [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
            data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data
        end
        if ~strcmp(test_error,'none')
            errors=test_error;
            BIDS_event(pathdata,SSID,data)%call data parser
            ShowCursor;
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


%stage 4: call function handling post-scan test, remap keys
    %data gotta be filled from trial_row+631, to not
    %overwrite study and test phase data
    
    %instruct participant to come out of the scanner
    ins='The next phase will be outside of the scanner.';
    DrawFormattedText(w,ins, 'center', 'center' );
    Screen(w, 'Flip');
    
    %call sub routines and get data
    [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,1);
    [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
    data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data from row 631
    
    %if an error occured in the post-scan phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(ps_errors,'none')
        errors=ps_errors;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(ps_terminated,'yes')
        if floor(max(trial_row)/90)==1%if terminated at the last trial of the last run (i.e. trial 90)
            ps_terminated='none';%skip the while loop
            continue
        else
            lasttrial=mod(max(trial_row),90);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,lasttrial+1);
            [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
            data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data
        end
        if ~strcmp(ps_errors,'none')
            errors=ps_errors;
            ShowCursor;
            return
        else
            errors='none';
        end
    end
%% start from key practice phase
elseif strcmp(p.Results.phase,'key_prac')
%stage 2: call function handling practice, one long run (~15 min). If subject cannot complete the task within that time, the rest is not scanned.
       [resp_keyprac,keyprac_errors,keyprac_terminated]=key_prac_scan(project_dir,pathdata,SSID,addtrig,w,hand,p.Results.trial);
       [trial_row,~]=find(~cellfun('isempty',resp_keyprac(1:end,8)));
       keypracdata=data(1,:);%get headers
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
   [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,1,1);
   %find none empty trials
    [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
    data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data from row 451
    
    %if an error occured in the test phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(test_error,'none')
        errors=test_error;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        BIDS_event(pathdata,SSID,data)%call data parser
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(test_terminated,'yes')
        if floor(max(trial_row)/45)==4%if terminated at the last trial of the last run (i.e. trial 180)
            test_terminated='none';%skip the while loop
            continue
        elseif floor(max(trial_row)/45)~=4&&mod(max(trial_row),45)==0%if terminated at the last trial the first n-1 runs
            lastrun=floor(max(trial_row)/45);%find the maximum run number
            [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,lastrun+1,1);%start from the 1st trial of the next run
            [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
            data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data
        else
            lastrun=floor(max(trial_row)/45);%find the maximum run number
            lasttrial=mod(max(trial_row),45);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,lastrun,lasttrial+1);%start from the next trial of the current run
            [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
            data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data
        end
        if ~strcmp(test_error,'none')
            errors=test_error;
            BIDS_event(pathdata,SSID,data)%call data parser
            ShowCursor;
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


%stage 4: call function handling post-scan test, remap keys
    %data gotta be filled from trial_row+631, to not
    %overwrite study and test phase data
    
    %instruct participant to come out of the scanner
    ins='The next phase will be outside of the scanner.';
    DrawFormattedText(w,ins, 'center', 'center' );
    Screen(w, 'Flip');
    
    %call sub routines and get data
    [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,1);
    [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
    data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data from row 631
    
    %if an error occured in the post-scan phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(ps_errors,'none')
        errors=ps_errors;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(ps_terminated,'yes')
        if floor(max(trial_row)/90)==1%if terminated at the last trial of the last run (i.e. trial 90)
            ps_terminated='none';%skip the while loop
            continue
        else
            lasttrial=mod(max(trial_row),90);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,lasttrial+1);
            [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
            data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data
        end
        if ~strcmp(ps_errors,'none')
            errors=ps_errors;
            ShowCursor;
            return
        else
            errors='none';
        end
    end

%% start from test phase
elseif strcmp(p.Results.phase,'test')
%stage 3: call function handling test phase presentation, loop over runs with break in between
   [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,p.Results.run,p.Results.trial);
   %find none empty trials
    [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
    data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data from row 451
    
    %if an error occured in the test phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(test_error,'none')
        errors=test_error;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        BIDS_event(pathdata,SSID,data)%call data parser
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(test_terminated,'yes')
        if floor(max(trial_row)/45)==4%if terminated at the last trial of the last run (i.e. trial 180)
            test_terminated='none';%skip the while loop
            continue
        elseif floor(max(trial_row)/45)~=4&&mod(max(trial_row),45)==0%if terminated at the last trial the first n-1 runs
            lastrun=floor(max(trial_row)/45);%find the maximum run number
            [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,lastrun+1,1);%start from the 1st trial of the next run
            [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
            data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data
        else
            lastrun=floor(max(trial_row)/45);%find the maximum run number
            lasttrial=mod(max(trial_row),45);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_test,test_error,test_terminated] = test(pathdata,SSID,addtrig,w,y_mid,test_txt,test_num,test_task,hand,lastrun,lasttrial+1);%start from the next trial of the current run
            [trial_row,~]=find(~cellfun('isempty',resp_test(1:end,8)));%search the onset column (8)
            data(trial_row+451,3:12)=resp_test(trial_row,1:10);%fill in the data
        end
        if ~strcmp(test_error,'none')
            errors=test_error;
            BIDS_event(pathdata,SSID,data)%call data parser
            ShowCursor;
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


%stage 4: call function handling post-scan test, remap keys
    %data gotta be filled from trial_row+631, to not
    %overwrite study and test phase data
    
    %instruct participant to come out of the scanner
    ins='The next phase will be outside of the scanner.';
    DrawFormattedText(w,ins, 'center', 'center' );
    Screen(w, 'Flip');
    
    %call sub routines and get data
    [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,1);
    [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
    data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data from row 631
    
    %if an error occured in the post-scan phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(ps_errors,'none')
        errors=ps_errors;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(ps_terminated,'yes')
        if floor(max(trial_row)/90)==1%if terminated at the last trial of the last run (i.e. trial 90)
            ps_terminated='none';%skip the while loop
            continue
        else
            lasttrial=mod(max(trial_row),90);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,lasttrial+1);
            [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
            data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data
        end
        if ~strcmp(ps_errors,'none')
            errors=ps_errors;
            ShowCursor;
            return
        else
            errors='none';
        end
    end

%% start from post-scan phase
elseif strcmp(p.Results.phase,'post_scan')
%stage 4: call function handling post-scan test, remap keys
    %data gotta be filled from trial_row+631, to not
    %overwrite study and test phase data
    
    %instruct participant to come out of the scanner
    ins='The next phase will be outside of the scanner.';
    DrawFormattedText(w,ins, 'center', 'center' );
    Screen(w, 'Flip');
    
    %call sub routines and get data
    [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,p.Results.trial);
    [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
    data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data from row 631
    
    %if an error occured in the post-scan phase, terminate the
    %function and return the error, test_error won't be
    %catched on this level, so I have to manually return the
    %function
    if ~strcmp(ps_errors,'none')
        errors=ps_errors;
        output=data;
        xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
        ShowCursor;
        return
    else
        errors='none';
    end
    
    %if the study phase was terminated by the experimenter halfway,
    %re-engage the test phase function from the next trial to have a new run
    while strcmp(ps_terminated,'yes')
        if floor(max(trial_row)/90)==1%if terminated at the last trial of the last run (i.e. trial 90)
            ps_terminated='none';%skip the while loop
            continue
        else
            lasttrial=mod(max(trial_row),90);%find the maximum trial number, if terminated at the last trial, this will cause the presentation to start from the first trial since mod(A*90,90)=0,that's why we nned the if statment above
            [resp_pscan,ps_errors,ps_terminated] = post_scan_beh(pathdata,SSID,w,y_mid,test_stim,hand,lasttrial+1);
            [trial_row,~]=find(~cellfun('isempty',resp_pscan(1:end,8)));%search the onset column (8)
            data(trial_row+631,3:12)=resp_pscan(trial_row,1:10);%fill in the data
        end
        if ~strcmp(ps_errors,'none')
            errors=ps_errors;
            ShowCursor;
            return
        else
            errors='none';
        end
    end

end

%% save the combined behavioral data and parse the scanning beh data into BIDS format
%overall data from the current execution of this function
xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_startphase-',p.Results.phase,'_startrun-',num2str(p.Results.run),'_starttrial-',num2str(p.Results.trial),'_data.xlsx'),data);
BIDS_event(pathdata,SSID,data)%call data parser
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