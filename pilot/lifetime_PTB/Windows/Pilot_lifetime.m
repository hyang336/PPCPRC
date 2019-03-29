function data=Pilot_lifetime(version,SSID,run,behav,trial)
% trial=1 if start from the beginning of a run, otherwise trial=stim+1
% behav=1 if purely bahavioral (script not complete), otherwise behav=0
 Screen('Preference','SkipSyncTests',1);
 Screen('Preference','VisualDebugLevel',0);
screens=Screen('Screens');
% screenNumber=max(screens);
scanner_screen=max(screens); %before running the script, use Screen('Screens') to determine the scanner screen number
    
%% initial setup
    KbName('UnifyKeyNames');
    %This part is specific for the 3T scanner, the key mapping is NOT
    %configurable
    scan_trig=KbName('5%');
    ins_done=KbName('1!');
    switch version
        case 2
        r5=KbName('3#');
        r4=KbName('2@');
        r3=KbName('1!');
        r2=KbName('6^');
        r1=KbName('7&');
        case 1
        r5=KbName('8*');
        r4=KbName('7&');
        r3=KbName('6^');
        r2=KbName('1!');
        r1=KbName('2@');   
    end
    SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
    pathStim = 'D:\pilot\lifetime_PTB\Windows\stimuli\';
    pathdata='D:\pilot\lifetime_PTB\Windows\datapilot\';
    mkdir(pathdata,SSID);
    
    addtrig=5;%according to Trevor the scanner automatically discard the first 4 volumes, and send the first trigger at the beginning of the 5th.
    %in that case we only need to discard one more volume to have a
    %total of 5 dummy scans. But we will receive 6 triggers before stimulus
    %presentation since the trigger was sent at the begining of each run
    
    %load in all 180 stimuli for lifetime pilot, only need one version
    %since both version used all 180 stimuli
    [lifetime_num,lifetime_txt,~]=xlsread(strcat(pathStim,'pilot_lifetime'),'Sheet1','A2:J181');%cant read in headers cuz they are also text
        
%% run specific setup for stimuli, jitter, and instructions
    if run<=4&&run>=1
      run_stim=lifetime_txt((run-1)*45+1:run*45);%get the stimuli for the selected run in study phase
      run_jit=lifetime_num((run-1)*45+1:run*45,9);%get jittering time
    else
        error('run number out of range [1,4]')
    end

%% data output
    %data output
    if behav==1
        data=cell(181,8);
        data(1,:)={'ParticipantNum' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'StimOnsetTime' 'Response' 'RespTime'};
        data(2:end,1)={SSID};
        data(2:end,2)={0};%for behavioral pilot the run is always 0
        data(2:end,3)={1:180};
        data(2:end,5)=lifetime_txt;
    else
        data=cell(46,8);%45 trials per run plus headers
        data(1,:)={'ParticipantNum' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'StimOnsetTime' 'Response' 'RespTime'};
        data(2:end,1)={SSID};
        data(2:end,2)={run};
        run_trial=[(run-1)*45+1:1:run*45];
        data(2:end,3)=num2cell(run_trial);
        data(2:end,5)=run_stim;
    end
%% lifetime exposure judgement task procedure
    try
        
        %screens=Screen('Screens');%check connected screens, 0 is ALL screens on Windows
        %use the scanner moniter 
        % Open window with default settings:
        [w,rect]=Screen('OpenWindow', scanner_screen);
        [xCenter, yCenter] = RectCenter(rect);
        %set font size, may need to tweak it on the scanner
        Screen('TextSize',w,40);
        HideCursor;
      %depending on the run, show different instructions
      if run==1
            switch version
                case 2
                    fd = fopen('pilot_lifetime_ins_v2.m');
                case 1
                    fd = fopen('pilot_lifetime_ins_v1.m');
            end
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
            while lcount < 23%ending line
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
            %cant use KbStrokeWait since scanner trigger will be treated as
            %a key press
            waittrig=1;
            while waittrig
            [keyIsDown, instime, keyCodes] = KbCheck;
            if keyCodes(ins_done)==1
                waittrig=0;
            end
           end
      else
            [nx, ny, bbox] = DrawFormattedText(w, strcat('Run', num2str(run),'\n Press with your right index finger to begin'),'center','center');%for all runs except the first one, only display a brief msg
            Screen('Flip',w);
            %cant use KbStrokeWait since scanner trigger will be treated as
            %a key press
            waittrig=1;
            while waittrig
            [keyIsDown, instime, keyCodes] = KbCheck;
            if keyCodes(ins_done)==1
                waittrig=0;
            end
           end
      end
      
        %draw info
        info = 'The experiment is going to start in a few seconds';
        DrawFormattedText(w, info, 'center', 'center');
        Screen(w, 'Flip');

%         %draw first focuing cross
%         DrawFormattedText(w, '+', 'center', 'center');
%         Screen(w, 'Flip');
%         
 
        %% wait for the first n=1 volumes as dummy scans
        dummy_t=cell(addtrig,1);
        keyCodes(1:256)=0;        
    for i=1:addtrig
            waittrig=1;
           while waittrig
            [keyIsDown, dummy_start, keyCodes] = KbCheck;
            if keyCodes(scan_trig)==1
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
    exp_start=dummy_t(end);
    data(2:end,4)=exp_start;

%% loop through stimuli for the current run
    for stim=trial:size(run_stim,1)
        word=run_stim{stim};
        %draw first focuing cross
        DrawFormattedText(w, '+', 'center', 'center');
        Screen(w, 'Flip');
        WaitSecs(run_jit(stim));
        DrawFormattedText(w,strcat(word,'\n\n1  2  3  4  5'), 'center', 'center' );%present stimuli
        onset=Screen(w,'Flip');%put presentation outside of KbCheck while-loop to keep presenting after a key is pressed, also use the returned value for RT
        respond=true;
        while respond %this is important for only registering the first key press
            
            % Check the keyboard.
                [keyIsDown,secs, keyCode] = KbCheck;

                if keyCode(r5)
                       resp='5';
                       respond=false;
                elseif keyCode(r4)
                       resp='4';
                       respond=false;
                elseif keyCode(r3)
                       resp='3';
                       respond=false;
                elseif keyCode(r2)
                       resp='2';
                       respond=false;
                elseif keyCode(r1)
                       resp='1';
                       respond=false;
                else
                    resp=[];
                end
                if secs-onset>2.5%response window
                    respond=false;
                    resp=[];
                end
        end
        offset=GetSecs;%time after a response is made,used for RT calculation
        WaitSecs('UntilTime',onset+2.5);%VERY IMPORTANT, wait until 2.5 seconds has passed since the onset of the image, this number has to agree with the response window, to keep stimulus on the screen after a key is pressed
        data{stim+1,7}=resp; %record responses, data has headers
        data{stim+1,6}=onset;%onset time, currently put before drawformattedtext call
        data{stim+1,8}=offset-onset;%RT, the offset line has to occur before the WaitSecs line
        
    end
    temprun=sprintf('%02d',run);
    %save data to subject-specific folder
    xlswrite(strcat(pathdata,SSID,'/task-lifetime_run-',temprun,'.xlsx'),data);
    
    %debriefing
    if run~=4
       debrief = 'You have finished one run, please relax and stay ready for the next run';
    else
       debrief = 'You have finished the lifetime experience task'; 
    end
    DrawFormattedText(w, debrief, 'center', 'center');
    Screen(w, 'Flip'); 
    WaitSecs(3);
    Screen('CloseAll');
    
    catch
        Screen('CloseAll');
        
        disp(['scan stopped at run ' num2str(run) ' trial ' num2str(stim)]);
    end
    

end