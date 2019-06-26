%handles study phase stimulus presentation and data collection, has built-in error
%handling. Note that depending on where the error happens, the trial when the error occurs
%may or may not be presented to the participants, for now this detail is not treated
%differently.

%% the block number listed in the loaded stimuli does not match total number of runs 
%% since we reduced 10 runs to 5 runs (double the trial count in each run), but the block number was not changed
%% since the main function of it was to counter balance the order of presentation between subjects
%% the output from this function should list the correct run number
function [resp_sofar,errors,terminated] = study(pathdata,SSID,addtrig,PTBwindow,y_center,stimuli,jitter,hand,run,trial)%run is in the range of [1,5], trial is in [1,90]
    output=cell(450,10);%initialize data output; headers are handled in the main procedure script (all but participant_ID and version [3 12])
    %some of the columns in the output will be empty (e.g.
    %norm_fam, frequency, run-number which is dependent on how many different exp_start afterwards,etc.), that's because this
    %function only takes the words and the jitters as input.
    output(:,7)={'animacy'};% fill the "task" column
    
    %for instruction reading
    scan_trig=KbName('5%');
    ins_done=KbName('2@');
    experimenter_pass=KbName('e');
    pausekey=KbName('p');
    termkey=KbName('t');
    
    %define key list to only accept response keys (1 & 6)
    %and pause key in the KbQueue
    klist=zeros(1,256);
    klist([pausekey, hand.animate, hand.inanimate])=1;
    
    %flow control
    errors='none';%for debugging, return errors in this function
    terminated='none';%for situations where a scanning run has to be terminated and restarted (i.e. change of exp_start and wait for trigger).
%% loop through runs and trials, special treatment on first run    
    try
    for i=run:5 % 5 runs of 90 trials
        
        %parse run stimuli
        run_stim=stimuli((i-1)*90+1:i*90);%get the stimuli for the selected run in study phase
        run_jit=jitter((i-1)*90+1:i*90);%get jittering time
                
        %load instruction
        ins=load_instruction('study',i,hand.ver);
        Screen('TextSize',PTBwindow,60);%use font size 60 for instruction
        
        %display instruction
        [nx, ny, bbox] = DrawFormattedText(PTBwindow, ins{1},'center','center');
        Screen('Flip',PTBwindow);
        waittrig=1;
        while waittrig
        [keyIsDown, instime, keyCodes] = KbCheck;
        if keyCodes(ins_done)==1
            waittrig=0;
        end
        end  
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
        exp_start=dummy_t(end);
        
        Screen('TextSize',PTBwindow,80);%use font size 80 for stimuli
        
        %draw first focuing cross for 3 seconds
        DrawFormattedText(PTBwindow, '+', 'center', y_center);
        Screen(PTBwindow, 'Flip');
        WaitSecs(3);

    %% present stimuli and collect resp
        %create and start KbQueue, flush each run (in
        %the for-loop)
        KbQueueCreate([],klist);%use default keyboard and only accept 1, 6, and p as input keys in the queue
        KbQueueStart;
        if i==run % for the starting run, continue from the specified trial 
            output((i-1)*90+trial:i*90,3)=exp_start;%fill in the exp_start for each run
            for j=trial:90 
                    word=run_stim{j};       

                    DrawFormattedText(PTBwindow,strcat(word,strcat('\n\n\n',hand.study_scale)), 'center', y_center );%present stimuli

                    onset=Screen(PTBwindow,'Flip');%put presentation outside of KbCheck while-loop to keep presenting after a key is pressed, also use the returned value for RT
                    KbQueueFlush;%flush keyboard buffer to start response collection for the current trial after stimuulus onset
                    WaitSecs('UntilTime',onset+1.5);%VERY IMPORTANT, wait until 1.5 seconds has passed since the onset of the image
                    %draw focuing cross during jitter
                    DrawFormattedText(PTBwindow, '+', 'center', y_center);
                    Screen(PTBwindow, 'Flip');
                    WaitSecs(run_jit{j});
                    
                    output{(i-1)*90+j,8}=onset;%onset time
                    output{(i-1)*90+j,4}=word;%the stimulus of this trial
                    output{(i-1)*90+j,2}=j;% the trial count of the current run
                    
                    %check response after presentation
                    [pressed, firstPress]=KbQueueCheck;
                    
                if pressed %if key was pressed do the following
                     firstPress(find(firstPress==0))=NaN; %little trick to get rid of 0s
                     [endtime Index]=sort(firstPress); % sort the RT of the first key-presses and their ID (the index are with respect to the firstPress)                 
                            
                     %if the first key press is "animate" or if the first key press is experimenter pause and the second key press is "animate"
                            if Index(1)==hand.animate
                                   resp='animate';
                                   output{(i-1)*90+j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==hand.animate
                                   resp='animate';
                                   output{(i-1)*90+j,10}=endtime(2)-onset;%RT
                            elseif Index(1)==hand.inanimate
                                   resp='inanimate';
                                   output{(i-1)*90+j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==hand.inanimate
                                   resp='inanimate';
                                   output{(i-1)*90+j,10}=endtime(2)-onset;%RT
                            else
                                resp=[];%pressing any key other than pause key before valid response keys results in noresp
                                output{(i-1)*90+j,10}=NaN;%pressing any other key also results in no RT
                            end
                     output{(i-1)*90+j,9}=resp; %record responses before pause
                     
                    %put the pause and termination check
                    %after we record the response of the
                    %current trial
                    if ~isnan(firstPress(pausekey))
                        waitcont=1;
                        DrawFormattedText(PTBwindow,'experiment paused, please wait', 'center', 'center' );
                        Screen(PTBwindow, 'Flip');
                        %save partial data
                       save(strcat(pathdata,'/',SSID,'/',SSID,'_study_run-',num2str(i),'_trial-',num2str(j),'data.mat'),'output');
                        while waitcont%check if the pause key has been pressed
                            [~, ~, keyCodes] = KbCheck;
                            if keyCodes(experimenter_pass)%if continue key has been pressed
                                waitcont=0;
                                DrawFormattedText(PTBwindow, '+', 'center', 'center');%present a 2s fixation then continue to next trial                
                                Screen('Flip',PTBwindow);
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
                    output{(i-1)*90+j,10}=NaN;
                    output{(i-1)*90+j,9}=resp; %record responses as empty if no response    
                end      
                                   
            end
        else
            output((i-1)*90+1:i*90,3)=exp_start;%fill in the exp_start for each run
            for j=1:90 %for all followin runs, start from the first trial
                    word=run_stim{j};
        
                    DrawFormattedText(PTBwindow,strcat(word,strcat('\n\n\n',hand.study_scale)), 'center', y_center );%present stimuli

                    onset=Screen(PTBwindow,'Flip');%put presentation outside of KbCheck while-loop to keep presenting after a key is pressed, also use the returned value for RT
                    KbQueueFlush;%flush keyboard buffer to start response collection for the current trial after stimuulus onset
                    WaitSecs('UntilTime',onset+1.5);%VERY IMPORTANT, wait until 1.5 seconds has passed since the onset of the image
                    %draw focuing cross during jitter
                    DrawFormattedText(PTBwindow, '+', 'center', y_center);
                    Screen(PTBwindow, 'Flip');
                    WaitSecs(run_jit{j});                    
                    
                    output{(i-1)*90+j,8}=onset;%onset time
                    output{(i-1)*90+j,4}=word;%the stimulus of this trial
                    output{(i-1)*90+j,2}=j;% the trial count of the current run
                    
                    %check response after presentation
                    [pressed, firstPress]=KbQueueCheck;
                    
                if pressed %if key was pressed do the following
                     firstPress(find(firstPress==0))=NaN; %little trick to get rid of 0s
                     [endtime Index]=sort(firstPress); % sort the RT of the first key-presses and their ID (the index are with respect to the firstPress)                 
                            
                     %if the first key press is "animate" or if the first key press is experimenter pause and the second key press is "animate"
                            if Index(1)==hand.animate
                                   resp='animate';
                                   output{(i-1)*90+j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==hand.animate
                                   resp='animate';
                                   output{(i-1)*90+j,10}=endtime(2)-onset;%RT
                            elseif Index(1)==hand.inanimate
                                   resp='inanimate';
                                   output{(i-1)*90+j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==hand.inanimate
                                   resp='inanimate';
                                   output{(i-1)*90+j,10}=endtime(2)-onset;%RT
                            else
                                resp=[];%pressing any key other than pause key before valid response keys results in noresp
                                output{(i-1)*90+j,10}=NaN;%pressing any other key also results in no RT
                            end
                     output{(i-1)*90+j,9}=resp; %record responses before pause
                     
                    %put the pause and termination check
                    %after we record the response of the
                    %current trial
                    if ~isnan(firstPress(pausekey))
                        waitcont=1;
                        DrawFormattedText(PTBwindow,'experiment paused, please wait', 'center', 'center' );
                        Screen(PTBwindow, 'Flip');
                        %save partial data
                       save(strcat(pathdata,'/',SSID,'/',SSID,'_study_run-',num2str(i),'_trial-',num2str(j),'data.mat'),'output');
                        while waitcont%check if the pause key has been pressed
                            [~, ~, keyCodes] = KbCheck;
                            if keyCodes(experimenter_pass)%if continue key has been pressed
                                waitcont=0;
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
                    output{(i-1)*90+j,10}=NaN;
                    output{(i-1)*90+j,9}=resp; %record responses as empty if no response    
                end       
      
             end
        end
        
        %run-level debrief
        Screen('TextSize',PTBwindow,60);%use font size 60 for debriefing
            if i~=5
               debrief = 'Please relax and stay ready for the next run';
            else
               debrief = 'You have finished the first phase of the experiment'; 
            end
            DrawFormattedText(PTBwindow, debrief, 'center', 'center');
            Screen(PTBwindow, 'Flip');
            
        %wait for experimenter input to continue if no error
        %has occured, unless it is the last run
           if i<5
                waittrig=1;
                   while waittrig
                    [keyIsDown, dummy_start, keyCodes] = KbCheck;
                    if keyCodes(experimenter_pass)==1
                        waittrig=0;
                    end
                   end
               %need to have these two lines to wait for the key release
               while KbCheck
               end
           end
    end
    
%% gather the output for all the runs so far
%         lastrun=i;
%         lasttrial=j;
        resp_sofar=output;
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