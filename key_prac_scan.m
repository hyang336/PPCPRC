function [resp_sofar,errors,terminated]=key_prac_scan(project_dir,pathdata,SSID,addtrig,PTBwindow,hand,trial,StimSize)
%present 1-5 to familiarize the subjects with key
%mapping. Keep presenting until get 45 (a full run) correct in a row, order
%randomly sampled using datasampe(data,n). If participants make a wrong
%response, they will be shown a picture of the correct key for 2
%secondes(may need to adjust codes for screens with different resolutions).

output=cell(500,10);%maximum record 500 trials
output(:,7)={'key_prac'};% fill the "task" column
output(:,1)={1};%fill in "run" column, there is only one key_prac run

%create a cell structure for all the options
stim={'1','2','3','4','5'};%,'animate','inanimate'};
KbName('UnifyKeyNames');
endofprac='practice ends';

[id,name] = GetKeyboardIndices;%get the device indices to be used in KbQueue
bboxid=id(find(~cellfun(@isempty,strfind(name,'Current Designs'))));

%setting up control keys
scan_trig=KbName('5%');
ins_done=KbName('2@');
experimenter_pass=KbName('e');
pausekey=KbName('p');
termkey=KbName('t');

%define key list to only accept response keys (in hand struct)
%and pause key in the KbQueue
klist=zeros(1,256);
p_klist=klist;
klist([hand.r1, hand.r2, hand.r3, hand.r4, hand.r5])=1;
p_klist(pausekey)=1;

%load images
img_folder=strcat(project_dir,'/button_box/');

if strcmp(hand.ver,'L5animate')
handv=imread(strcat(img_folder,'left_5.jpg'));
h5=imread(strcat(img_folder,'left_ring.jpg'));
h4=imread(strcat(img_folder,'left_middle.jpg'));
h3=imread(strcat(img_folder,'left_index.jpg'));
h2=imread(strcat(img_folder,'right_index.jpg'));
h1=imread(strcat(img_folder,'right_middle.jpg'));
else
handv=imread(strcat(img_folder,'right_5.jpg'));
h1=imread(strcat(img_folder,'left_middle.jpg'));
h2=imread(strcat(img_folder,'left_index.jpg'));
h3=imread(strcat(img_folder,'right_index.jpg'));
h4=imread(strcat(img_folder,'right_middle.jpg'));
h5=imread(strcat(img_folder,'right_ring.jpg'));
end
%flow control
errors='none';%for debugging, return errors in this function
terminated='none';%for situations where a scanning run has to be terminated and restarted (i.e. change of exp_start and wait for trigger).


[Xp, Yp] = Screen('WindowSize', PTBwindow);
screenrec=[0 0 Xp Yp];

          try
           %% initialize instructions

            %make image matrices into OpenGL textures, not drawing them
            %yet!
            h1_tex = Screen('MakeTexture', PTBwindow, h1);
            h2_tex= Screen('MakeTexture', PTBwindow, h2);
            h3_tex= Screen('MakeTexture', PTBwindow, h3);
            h4_tex= Screen('MakeTexture', PTBwindow, h4);
            h5_tex= Screen('MakeTexture', PTBwindow, h5);
            vtex=Screen('MakeTexture',PTBwindow,handv);
            
            %load instruction
            ins=load_instruction('key_prac',1,hand.ver);
            Screen('TextSize',PTBwindow, 35);            
            
            %display instruction
            [nx, ny, bbox] = DrawFormattedText(PTBwindow, ins{1},'center','center');
            Screen(PTBwindow,'Flip');
            waittrig=1;
            while waittrig
            [keyIsDown, instime, keyCodes] = KbCheck;
            if keyCodes(ins_done)==1
                waittrig=0;
            end
            end
            %display hand figure for 5 sec
            Screen('DrawTexture', PTBwindow, vtex,[],screenrec);
            Screen(PTBwindow,'Flip');
            WaitSecs(5);
            
            info = 'The experiment is going to start in a few seconds';
            DrawFormattedText(PTBwindow, info, 'center', 'center');
            Screen(PTBwindow, 'Flip');

            %wait for dummy scan
            dummy_t=cell(addtrig,1);
            keyCodes(1:256)=0;        
            for trig=1:addtrig
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
                   dummy_t{trig}=dummy_start;%resolution shows in second, but are actually finer (hint:take the difference)
            end

            %the last dummy trigger received marks the beginning
            %of the experiment for the current run
            exp_start=dummy_t{end};

            Screen('TextSize',PTBwindow,StimSize);%use font size 80 for stimuli

            %draw first focuing cross for 3 seconds
            DrawFormattedText(PTBwindow, '+', 'center', 'center');
            Screen(PTBwindow, 'Flip');
            WaitSecs(3);
            

            %% practice procedure loop
            %threshold for consecutive correct responses=45                
            success=0;
                            
            %initialize counter for interrupted prac run, if
            %it is the first time running this session i
            %should be 1
            i=trial;
            KbQueueCreate(bboxid,klist);%queue for button boxes only accept the 5 resp keys 
            KbQueueCreate([],p_klist);%queue for keyboards only accept pause key
            KbQueueStart(bboxid);
            KbQueueStart([]);
            while success < 45               
               
                % Sending a 'TRIALID' message to mark the start of a trial in Data
                % Viewer.  This is different than the start of recording message
                % START that is logged when the trial recording begins. The viewer
                % will not parse any messages, events, or samples, that exist in
                % the data file prior to this message.
                Eyelink('Message', 'TRIALID %d', i);
                
%                 % Do a drift correction at the beginning of each trial
%                 % Performing drift correction (checking) is optional for
%                 % EyeLink 1000 eye trackers.
%                 EyelinkDoDriftCorrection(el);% start recording eye position (preceded by a short pause so that 
%                 
                % the tracker can finish the mode transition)
                % The paramerters for the 'StartRecording' call controls the
                % file_samples, file_events, link_samples, link_events availability
                Eyelink('Command', 'set_idle_mode');
                WaitSecs(0.05);
                %         Eyelink('StartRecording', 1, 1, 1, 1);
                Eyelink('StartRecording');
                % record a few samples before we actually start displaying
                % otherwise you may lose a few msec of data
                WaitSecs(0.1);
                
               curWord=datasample(stim,1);%randomly sample from the 7 options
               curWord=curWord{1};
               DrawFormattedText(PTBwindow,curWord, 'center', 'center' );
               onset=Screen(PTBwindow,'Flip');
               KbQueueFlush(bboxid);
               KbQueueFlush([]);
               % write out a message to indicate the time of the picture onset
               % this message can be used to create an interest period in EyeLink
               % Data Viewer.               
               Eyelink('Message', 'SYNCTIME');
               
               WaitSecs('UntilTime',onset+1.5);%present the number for 1.5 seconds
               jitter=truncexp_jitter_sample(1,4,0.5,1);%randomly sample the truncated exponential distribution for ISI, mean~1.5s
                %draw fixation
                DrawFormattedText(PTBwindow, '+', 'center', 'center');
                
                Screen(PTBwindow,'Flip');
                WaitSecs(jitter);
                              
                % Sending a 'TRIAL_RESULT' message to mark the end of a trial in
                % Data Viewer. This is different than the end of recording message
                % END that is logged when the trial recording ends. The viewer will
                % not parse any messages, events, or samples that exist in the data
                % file after this message.
                Eyelink('Message', 'TRIAL_RESULT 0')
                % stop the recording of eye-movements for the current trial
                Eyelink('StopRecording');
                
                %record resp
                output{i,8}=onset;
                output{i,2}=i;
                output{i,4}=curWord;%record the stimulus
                output{i,3}=exp_start;%record ExpStartTime for each trial since we dont know when the run is going to restart
               
                %check response after presentation
                [pressed, firstRESP]=KbQueueCheck(bboxid);%check response
                [paused,~]=KbQueueCheck([]);%check experimenter pause
               %% get response
                if pressed%if key was pressed do the following
                     firstRESP(find(firstRESP==0))=NaN; %little trick to get rid of 0s
                     [endtime Index]=sort(firstRESP); % sort the RT of the first key-presses and their ID (the index are with respect to the firstRESP)                 
                            
                     %use the first pressed key as response
                            if Index(1)==hand.r5
                                   resp='5';
                                   output{i,10}=endtime(1)-onset;%RT
%                             elseif Index(1)==pausekey&&Index(2)==hand.r5
%                                    resp='5';
%                                    output{i,10}=endtime(2)-onset;%RT
                            elseif Index(1)==hand.r4
                                   resp='4';
                                   output{i,10}=endtime(1)-onset;%RT
%                             elseif Index(1)==pausekey&&Index(2)==hand.r4
%                                    resp='4';
%                                    output{i,10}=endtime(2)-onset;%RT
                            elseif Index(1)==hand.r3
                                   resp='3';
                                   output{i,10}=endtime(1)-onset;%RT
%                             elseif Index(1)==pausekey&&Index(2)==hand.r3
%                                    resp='3';
%                                    output{i,10}=endtime(2)-onset;%RT
                            elseif Index(1)==hand.r2
                                   resp='2';
                                   output{i,10}=endtime(1)-onset;%RT
%                             elseif Index(1)==pausekey&&Index(2)==hand.r2
%                                    resp='2';
%                                    output{i,10}=endtime(2)-onset;%RT
                            elseif Index(1)==hand.r1
                                   resp='1';
                                   output{i,10}=endtime(1)-onset;%RT
%                             elseif Index(1)==pausekey&&Index(2)==hand.r1
%                                    resp='1';
%                                    output{i,10}=endtime(2)-onset;%RT
                            else
                                resp=[];%pressing any key other than pause key before valid response keys results in noresp
                                output{i,10}=NaN;%pressing any other key also results in no RT
                            end
                                output{i,9}=resp; %record responses before pause
                     
                           %if the resp match the stimulus,proceed to next trial
                %directly
                if strcmp(curWord,'1')&&strcmp(resp,'1')
                    success=success+1;
                elseif strcmp(curWord,'2')&&strcmp(resp,'2')
                    success=success+1;
                elseif strcmp(curWord,'3')&&strcmp(resp,'3')
                    success=success+1;
                elseif strcmp(curWord,'4')&&strcmp(resp,'4')
                    success=success+1;
                elseif strcmp(curWord,'5')&&strcmp(resp,'5')
                    success=success+1;
                %if the resp doesn't match the stimulus, display the
                %correct key, then proceed to next trial
                elseif strcmp(curWord,'1')
                    Screen('DrawTexture', PTBwindow, h1_tex,[],screenrec);
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);
                    success=0;
                    DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);                        
                elseif strcmp(curWord,'2')
                    Screen('DrawTexture', PTBwindow, h2_tex,[],screenrec);
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);
                    success=0;
                    DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);                        
                elseif strcmp(curWord,'3')
                    Screen('DrawTexture', PTBwindow, h3_tex,[],screenrec);
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);
                    success=0;
                    DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);                        
                elseif strcmp(curWord,'4')
                    Screen('DrawTexture', PTBwindow, h4_tex,[],screenrec);
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);
                    success=0;
                    DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);                        
                elseif strcmp(curWord,'5')
                    Screen('DrawTexture', PTBwindow, h5_tex,[],screenrec);
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);
                    success=0;
                    DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                    Screen(PTBwindow,'Flip');
                    WaitSecs(2);                        
                end
                
                    %put the pause and termination check
                    %after we record the response of the
                    %current trial
                    %% 20191004
                    if paused
                        waitcont=1;
                        DrawFormattedText(PTBwindow,'experiment paused, please wait', 'center', 'center' );
                        Screen(PTBwindow, 'Flip');
                        %save partial data
                       save(strcat(pathdata,'/',SSID,'/',SSID,'_keyPrac_trial-',num2str(i),'_data.mat'),'output');
                        while waitcont%check if the pause key has been pressed
                            [~, ~, keyCodes] = KbCheck;
                            if keyCodes(experimenter_pass)%if continue key has been pressed
                                waitcont=0;
                                DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                                Screen(PTBwindow,'Flip');
                                WaitSecs(2);
                            elseif keyCodes(termkey)
                                terminated='yes';
                                resp_sofar=output;
                                return
                            end
                        end                       
                           %need to have these two lines to wait for the key release
                       while KbCheck
                       end 
                    end  
                    
                else
                    resp=[];%not pressing any key results in noresp
                    output{i,10}=NaN;
                    output{i,9}=resp; %record responses as empty if no response
                    if strcmp(curWord,'1')
                        Screen('DrawTexture', PTBwindow, h1_tex,[],screenrec);
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);
                        success=0;
                        DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);                        
                    elseif strcmp(curWord,'2')
                        Screen('DrawTexture', PTBwindow, h2_tex,[],screenrec);
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);
                        success=0;
                        DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);                        
                    elseif strcmp(curWord,'3')
                        Screen('DrawTexture', PTBwindow, h3_tex,[],screenrec);
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);
                        success=0;
                        DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);                        
                    elseif strcmp(curWord,'4')
                        Screen('DrawTexture', PTBwindow, h4_tex,[],screenrec);
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);
                        success=0;
                        DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);                        
                    elseif strcmp(curWord,'5')
                        Screen('DrawTexture', PTBwindow, h5_tex,[],screenrec);
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);
                        success=0;
                        DrawFormattedText(PTBwindow, '+', 'center', 'center');                
                        Screen(PTBwindow,'Flip');
                        WaitSecs(2);                        
                    end
                end
                    
                i=i+1;
            end
            
            resp_sofar=output;
            DrawFormattedText(PTBwindow,endofprac, 'center', 'center' );
            Screen(PTBwindow,'Flip');
            WaitSecs(3);
            
        catch ME
        %need to copy it here as well otherwise if error occurred in loops these variables
        %won't get returned
%         lastrun=i;
%         lasttrial=j;
        resp_sofar=output;
        Screen('CloseAll');
        errors=ME;
        terminated='none';
        end
        
          
          
          


end