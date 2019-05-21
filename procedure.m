%% need to update this!!! 2019-04-20
function [data,errors]=procedure(SSID,version_inp,project_dir)
%16 versions (hand (2) * set_selection (2) * block_order (4)).
%study phase one run, test phase one run, both triggered by scanner.
%pseudorandomization done for each Ss individually.
%study phase has spacing constraint for repetitions
%test phase presentation is simple shuffling, since there is no repetition.

%% surpress the screen sync error on Windows, will like result in wildly inaccurate timing of stimulus onsets
Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);

%% add project path, may be changed for different PC
addpath(genpath(project_dir));

%% initialize constants
KbName('UnifyKeyNames');
scan_trig=KbName('5%');
%create data cell, later use xlswrite to export
data=cell(811,12);%630 trials in scanner, and 180 trials post-scan, plus headers
data(1,:)={'ParticipantNum' 'Version' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'objective_freq' 'norm_fam' 'task' 'StimOnsetTime' 'Response' 'RespTime'};
SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
data(2:end,1)={SSID};
data(2:end,2)={version_inp};

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
%% stage 1: call function handling study phase presentation, loop over runs with break in between
[resp_sofar,lastrun,lasttrial] = study(addtrig,w,study_txt,study_num,hand,1,2);
data=resp_sofar;%test line
disp(['last study run:' lastrun]);
disp(['last study trial:' lasttrial]);
%% stage 2: call function handling practice, one long run (~15 min). If subject cannot complete the task within that time, the rest is not scanned.

%% stage 3: call function handling test phase presentation, loop over runs with break in between

%% post-process scanning data, use ExpStartTime to assign runs. The "run" field was used to select stimuli to present so it had to fall within a certain range, but now it needs to reflect the actual run number, which can be outside of that range if error occured and a run was broken into multiple runs. However, any run would have the same ExpStartTime.
    ppdata=data;%copy the unprocessed data just in case
    
%% stage 4: call function handling post-scan test, instruct participants to get out of scanner (lock keys during that), remap keys






%% obsolete code for salvage below
% %% run specific setup for stimuli, jitter, and instructions
%     %totel 14 runs, the first 10 runs are study, and the last 4 are
%     %test,each run has 45 stimuli
%     if run<=10&&run>=1
%           run_stim=study_txt((run-1)*45+1:run*45);%get the stimuli for the selected run in study phase
%           run_jit=study_num((run-1)*45+1:run*45);%get jittering time
%           %depending on the hand mapping version, show different
%           %instructions for study phase
%           if mod(hand_v,2)==1
%             
%           else
%               
%           end
%     else
%         if run>=11&&run<=14
%           run_stim=test_txt((run-11)*45+1:(run-10)*45); %get the stimuli for the selected run in test phase
%           run_jit=test_num((run-11)*45+1:(run-10)*45);%get jittering time
%           
%           %make stimuli blocks according to test_first
%           switch test_first
%               case 'recent'
%               
%               case 'lifetime'
%                   
%               otherwise
%                   error('test phase block order error')
%           end
%           %depending on the hand mapping version, show different
%           %instructions for test phase
%           if mod(hand_v,2)==1
%             
%           else
%               
%           end
%         else
%           error('run number out of range [1,14]')
%         end
%     end
%     
%     
%     %% presenting using a screen, enclosed in a try-catch block so it doesn't freeze on error
%     try
%         
%         %screens=Screen('Screens');%check connected screens, 0 is ALL screens on Windows
%         %use the scanner moniter 
%         window = Screen(scanner_screen,'OpenWindow',bckgcolour,winsize); %timing will be inevitably off on Windows after 8, mainly due to the highly varying and above-threshold std from the test calls of screen('Flip').
% 
%         %COLOURS
%         white = WhiteIndex(window); % pixel value for white
%         black = BlackIndex(window); % pixel value for black
% 
%         %not sure what is offscreenwindow and why we need it, by HY
%         %open offscreen window
% %         offwindow1= Screen('OpenOffscreenWindow',scanner_screen);
% %         offwindow2 = Screen('OpenOffscreenWindow',scanner_screen);
% %         Screen(offwindow1,'FillRect',bckgcolour);
% %         Screen(offwindow2,'FillRect',bckgcolour);
% 
%         Screen(window,'FillRect', bckgcolour);
%         HideCursor;
%         WaitSecs(1);
%         
%         %draw info
%         info = 'The experiment is going to start in a few seconds';
%         DrawFormattedText(window, info, 'center', 'center', black);
%         Screen(window, 'Flip');
%         WaitSecs(3);
%         
%         %draw first focuing cross
%         DrawFormattedText(window, '+', 'center', 'center', black);
%         Screen(window, 'Flip');
%         WaitSecs(2.5);
%         
%         %% wait for the first n volumes as dummy scans
%         dummy_t=cell(addtrig,1);
%         keyCodes(1:256)=0;
%     for i=1:addtrig
%            keyCodes(scan_trig)=0;%gotta reset the scan_trigger since im using it as the condition for while-loop
%            while ~keyCodes(scan_trig)
%             [keyIsDown, dummy_start, keyCodes] = KbCheck(-1);
%            end
%            fprintf('trigger %d\n',i)
%            dummy_t{i}=dummy_start;%resolution shows in second, but are actually finer (hint:take the difference)
%                    
%            %KbCheck will return 1 whenever a key is pressed, the following
%            %loop seems to hault the for loop until the key is released.
%            %helpful in preventing one key pressing being registered as
%            %multiple press
%            while KbCheck(-1)
%            end
%     end
%     
%     exp_start=dummy_t{end};%last trigger from the above loop signals the beginning of the exp run
%     
%      
%     %% loop through stimuli for the current run
%     for stim=1:size(run_stim,1)
%         
%         hand(hand_v).r5
%     
%     end
%         
    catch
        Screen('CloseAll');
        data=resp_sofar;%test line
%         disp(['scan stopped at run ' num2str(run) ' stim ' num2str(stim)])%need to receive a stop trigger from scanner (if possible) earlier in presentation loop
end
end