%lifetime fam for freq. items. 
%load in the full test stimuli
%uses "S" "D" "F" "J" "K" "L" as the response keys
function [resp_sofar,errors,terminated] = post_scan_beh(pathdata,SSID,PTBwindow,y_center,test_stimuli,hand,trial)
output=cell(90,10);%initialize data output; headers are handled in the main procedure script (all but participant_ID and version [3 12])
    %some of the columns in the output will be empty (e.g.
    %norm_fam, frequency, run-number which is dependent on how many different exp_start afterwards,etc.), that's because this
    %function only takes the words, the jitters, and the task as input.
    
output(:,3)={-1};%fill the ExpStartTime column with -1, necessary for data parsing (BIDS_event)   

%for instruction reading
%     scan_trig=KbName('5%');
%     flippage=KbName('1!');
    ins_done=KbName('k');
    experimenter_pass=KbName('e');
    pausekey=KbName('p');
    termkey=KbName('t');
    
    %define key list to only accept response keys 
    %and pause key in the KbQueue
    klist=zeros(1,256);
    switch hand.ver
        case 'L5animate'
            r5=KbName('s');
            r4=KbName('d');
            r3=KbName('f');
            r2=KbName('j');
            r1=KbName('k');            
        case 'R5animate'
            r5=KbName('l');
            r4=KbName('k');
            r3=KbName('j');
            r2=KbName('f');
            r1=KbName('d');    
    end
    klist([pausekey, r1, r2, r3, r4, r5])=1;
    
    %flow control
    errors='none';%for debugging, return errors in this function
    terminated='none';%for situations where a scanning run has to be terminated and restarted (i.e. change of exp_start and wait for trigger).
%% loop through runs and trials, special treatment on first run    
    try
        
        %%get the stimuli from test phase frequency stimuli, and randomize the order
        [freq_row,~]=find(strcmp(test_stimuli(:,4),'recent'));
        stim=test_stimuli(freq_row,:);
        order=randperm(size(stim,1));
        stim=stim(order,:);
        jitter=truncexp_jitter_sample(2.5,10,1.5,90);%generate jittering time
        stim(:,2)=num2cell(jitter);
        stim(:,4)={'post_scan'};
        
        %load instruction
        ins=load_instruction('post_scan',1,hand.ver);
        Screen('TextSize',PTBwindow,60);%use font size 60 for instruction
        
        %display instruction P1
        [nx, ny, bbox] = DrawFormattedText(PTBwindow, ins{1},'center','center');
        Screen('Flip',PTBwindow);
        waittrig=1;
        while waittrig
        [keyIsDown, instime, keyCodes] = KbCheck;
        if keyCodes(ins_done)==1
            waittrig=0;
        end
        end  
        
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

            for j=trial:90                
                    word=stim{j,1};       

                    DrawFormattedText(PTBwindow,strcat(word,strcat('\n\n\n',hand.test_scale)), 'center', y_center );%present stimuli

                    onset=Screen(PTBwindow,'Flip');%put presentation outside of KbCheck while-loop to keep presenting after a key is pressed, also use the returned value for RT
                    KbQueueFlush;%flush keyboard buffer to start response collection for the current trial after stimuulus onset
                    WaitSecs('UntilTime',onset+2.5);%VERY IMPORTANT, wait until 2.5 seconds has passed since the onset of the image
                    %draw focuing cross during jitter
                    DrawFormattedText(PTBwindow, '+', 'center', y_center);
                    Screen(PTBwindow, 'Flip');
                    WaitSecs(stim{j,2});
                    
                    output{j,7}='post_scan';%task
                    output{j,8}=onset;%onset time
                    output{j,4}=word;%the stimulus of this trial
                    output{j,2}=j;% the trial count of the current run
                    
                    %check response after presentation
                    [pressed, firstPress]=KbQueueCheck;
                    
                if pressed %if key was pressed do the following
                     firstPress(find(firstPress==0))=NaN; %little trick to get rid of 0s
                     [endtime Index]=sort(firstPress); % sort the RT of the first key-presses and their ID (the index are with respect to the firstPress)                 
                            
                     %if the first key press is "animate" or if the first key press is experimenter pause and the second key press is "animate"
                            if Index(1)==r5
                                   resp='5';
                                   output{j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==r5
                                   resp='5';
                                   output{j,10}=endtime(2)-onset;%RT
                            elseif Index(1)==r4
                                   resp='4';
                                   output{j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==r4
                                   resp='4';
                                   output{j,10}=endtime(2)-onset;%RT
                            elseif Index(1)==r3
                                   resp='3';
                                   output{j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==r3
                                   resp='3';
                                   output{j,10}=endtime(2)-onset;%RT
                            elseif Index(1)==r2
                                   resp='2';
                                   output{j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==r2
                                   resp='2';
                                   output{j,10}=endtime(2)-onset;%RT
                            elseif Index(1)==r1
                                   resp='1';
                                   output{j,10}=endtime(1)-onset;%RT
                            elseif Index(1)==pausekey&&Index(2)==r1
                                   resp='1';
                                   output{j,10}=endtime(2)-onset;%RT
                            else
                                resp=[];%pressing any key other than pause key before valid response keys results in noresp
                                output{j,10}=NaN;%pressing any other key also results in no RT
                            end
                     output{j,9}=resp; %record responses before pause
                     
                    %put the pause and termination check
                    %after we record the response of the
                    %current trial
                    if ~isnan(firstPress(pausekey))
                        waitcont=1;
                        DrawFormattedText(PTBwindow,'experiment paused, please wait', 'center', 'center' );
                        Screen(PTBwindow, 'Flip');
                        %save partial data
                       save(strcat(pathdata,'/',SSID,'/',SSID,'_postscan_','trial-',num2str(j),'data.mat'),'output');
                        while waitcont%check if the pause key has been pressed
                            [~, ~, keyCodes] = KbCheck;
                            if keyCodes(experimenter_pass)%if continue key has been pressed
                                waitcont=0;
                                DrawFormattedText(PTBwindow, '+', 'center', 'center');                
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
                    output{j,10}=NaN;
                    output{j,9}=resp; %record responses as empty if no response    
                end      
                                   
            end
        
        
        %run-level debrief
        Screen('TextSize',PTBwindow,60);%use font size 60 for debriefing
        debrief = 'You have finished the experiment'; 
        DrawFormattedText(PTBwindow, debrief, 'center', 'center');
        Screen(PTBwindow, 'Flip');
            
    
%% gather the output for all the runs so far
        resp_sofar=output;
    catch ME
        %need to copy it here as well otherwise if error occurred in loops these variables
        %won't get returned
        resp_sofar=output;
        Screen('CloseAll');
        errors=ME;
        terminated='none';
    end








end