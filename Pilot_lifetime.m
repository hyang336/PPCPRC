function Pilot_lifetime(SSID,run,behav)

Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);
scanner_screen=2; %before running the script, use Screen('Screens') to determine the scanner screen number
    
%% initial setup
    KbName('UnifyKeyNames');
    scan_trig=KbName('t');
    pathStim = 'C:/Users/haozi/Desktop/PhD/fMRI_PrC-PPC/stmuli/';
    cd(pathStim)
    addtrig=2;%according to Trevor the scanner automatically discard the first 4 volumes, and send the first trigger at the beginning of the 5th.
    %in that case we only need to discard one more volume to have a
    %total of 5 dummy scans. But we will receive 6 triggers before stimulus
    %presentation since the trigger was sent at the begining of each run
    
    %load in all 180 stimuli for lifetime pilot, only need one version
    %since both version used all 180 stimuli
    [lifetime_num,lifetime_txt,~]=xlsread(strcat(pathStim,'pilot_lifetime'),'Sheet1','A2:J181');%cant read in headers cuz they are also text
        
    %data output
    if behav==1
        data=cell(181,8);
        data(1,:)={'ParticipantNum' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'StimOnsetTime' 'Response' 'RespTime'};
        SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
        data(2:end,1)={SSID};
        data(2:end,3)={0};%for behavioral pilot the run is always 0
    else
        data=cell(45,9);%45 trials per run plus headers
        data(1,:)={'ParticipantNum' 'Version' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'StimOnsetTime' 'Response' 'RespTime'};
        SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
        data(2:end,1)={SSID};
        data(2:end,3)={run};
    end

%% run specific setup for stimuli, jitter, and instructions
    if run<=4&&run>=1
      run_stim=lifetime_txt((run-1)*45+1:run*45);%get the stimuli for the selected run in study phase
      run_jit=lifetime_num((run-1)*45+1:run*45,9);%get jittering time
    else
        error('run number out of range [1,4]')
    end

%% lifetime exposure judgement task procedure
    try
        
        %screens=Screen('Screens');%check connected screens, 0 is ALL screens on Windows
        %use the scanner moniter 
        % Open window with default settings:
        [w,rect]=Screen('OpenWindow', scanner_screen);
        [xCenter, yCenter] = RectCenter(rect);
            
        %COLOURS
        white = WhiteIndex(window); % pixel value for white
        black = BlackIndex(window); % pixel value for black

        Screen(window,'FillRect', bckgcolour);
        HideCursor;
        WaitSecs(1);
        
        %draw info
        info = 'The experiment is going to start in a few seconds';
        DrawFormattedText(window, info, 'center', 'center', black);
        Screen(window, 'Flip');
        WaitSecs(3);
        
        %draw first focuing cross
        DrawFormattedText(window, '+', 'center', 'center', black);
        Screen(window, 'Flip');
        WaitSecs(2.5);
        
        %% wait for the first n=1 volumes as dummy scans
        dummy_t=cell(addtrig,1);
        keyCodes(1:256)=0;
        keynum=KbName(scan_trig);
    for i=1:addtrig
            waittrig=1;
           while waittrig
            [keyIsDown, dummy_start, keyCodes] = KbCheck;
            if keyCodes(keynum)==1
                waittrig=0;
            end
           end
           
           %need to have these two lines to wait for the key release
           while KbCheck
           end
           
           fprintf('trigger %d\n',i)
           dummy_t{i}=dummy_start;%resolution shows in second, but are actually finer (hint:take the difference)

    end
    
    %the last dummy trigger received marks the beginning of the experiment
    exp_start=dummy_t{end};
    
     
%% loop through stimuli for the current run
   %depending on the run, show different instructions
      if run==1
            fd = fopen('pilot_lifetime_ins.m');
            if fd==-1
                error('Could not open instructions.m file.');
            end

            mytext = '';
            %skip the first line
             for k=1:1
                fgets(fd); 
             end
            lcount = 2;%starting line
            tl=fgets(fd);
            while lcount < 11%ending line
                mytext = [mytext tl]; %#ok<*AGROW>
                tl = fgets(fd);
                lcount = lcount + 1;
            end
            fclose(fd);
            mytext = [mytext newline];

            % Get rid of '% ' symbols at the start of each line:
            mytext = strrep(mytext, '% ', '');
            mytext = strrep(mytext, '%', '');

            % Now vertically centered:
            [nx, ny, bbox] = DrawFormattedText(w, mytext,'center','center');

            Screen('Flip',w);
            KbStrokeWait;
      else
            [nx, ny, bbox] = DrawFormattedText(w, 'Run 2\n Press a key to begin','center','center');%for all runs except the first one, only display a brief msg
            Screen('Flip',w);
            KbStrokeWait;
      end
      
    %loop through stimuli
    for stim=1:size(run_stim,1)
        
        hand(hand_v).r5
    
    end
        
    catch
        Screen('CloseAll');
        disp(['scan stopped at run ' num2str(run) ' stim ' num2str(stim)])%need to receive a stop trigger from scanner (if possible) earlier in presentation loop
    end



end