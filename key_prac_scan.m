function [resp_sofar,errors,terminated]=key_prac_scan(project_dir,pathdata,SSID,addtrig,PTBwindow,hand,trial)
%present 1-5 to familiarize the subjects with key
%mapping. Keep presenting until get 45 (a full run) correct in a row, order
%randomly sampled using datasampe(data,n). If participants make a wrong
%response, they will be shown a picture of the correct key for 2
%secondes(may need to adjust codes for screens with different resolutions).

output=cell(500,10);%maximum record 500 trials
output(:,7)={'key_prac'};% fill the "task" column

%create a cell structure for all the options
stim={'1','2','3','4','5'};%,'animate','inanimate'};
KbName('UnifyKeyNames');
endofprac='practice ends';

%setting up control keys
scan_trig=KbName('5%');
ins_done=KbName('2@');
experimenter_pass=KbName('e');
pausekey=KbName('p');
termkey=KbName('t');
    
%load images
img_folder=strcat(project_dir,'/button_box/');
left_ring=imread(strcat(img_folder,'left_ring.JPG'));
left_mid=imread(strcat(img_folder,'left_middle.JPG'));
left_index=imread(strcat(img_folder,'left_index.JPG'));
right_index=imread(strcat(img_folder,'right_index.JPG'));
right_mid=imread(strcat(img_folder,'right_middle.JPG'));
right_ring=imread(strcat(img_folder,'right_ring.JPG'));

handv1=imread(strcat(img_folder,'left_5.JPG'));
handv2=imread(strcat(img_folder,'right_5.JPG'));
switch version
    
%% version 1
    
    case 1 %5 on left
          try
           %% initialize instructions

            %make image matrices into OpenGL textures, not drawing them
            %yet!
            left_ring_tex = Screen('MakeTexture', PTBwindow, left_ring);
            left_mid_tex= Screen('MakeTexture', PTBwindow, left_mid);
            left_index_tex= Screen('MakeTexture', PTBwindow, left_index);
            right_index_tex= Screen('MakeTexture', PTBwindow, right_index);
            right_mid_tex= Screen('MakeTexture', PTBwindow, right_mid);
            v1tex=Screen('MakeTexture',PTBwindow,handv1);
            
            %load instruction
            ins=load_instruction('key_prac',1,hand.ver);
            Screen('TextSize',PTBwindow, 60);            
            
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
            %display hand figure for 5 sec
            Screen('DrawTexture', PTBwindow, v1tex);
            Screen('Flip',PTBwindow);
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
            exp_start=dummy_t(end);

            Screen('TextSize',PTBwindow,80);%use font size 80 for stimuli

            %draw first focuing cross for 3 seconds
            DrawFormattedText(PTBwindow, '+', 'center', y_center);
            Screen(PTBwindow, 'Flip');
            WaitSecs(3);
            

            %% practice procedure loop
            %threshold for consecutive correct responses=45                
                success=0;
                            
            %initialize counter for interrupted prac run, if
            %it is the first time running this session i
            %should be 1
            i=trial;
            
            while success < 45
               respond=true;
               curWord=datasample(stim,1);%randomly sample from the 7 options
               curWord=curWord{1};
               jitter=truncexp_jitter_sample(2.5,10,1.5,1);%randomly sample the truncated exponential distribution for ISI
                %draw fixation
                DrawFormattedText(PTBwindow, '+', 'center', 'center');
                
                Screen('Flip',PTBwindow);
                WaitSecs(jitter);
               %% get response
               while respond==true
               
                DrawFormattedText(PTBwindow,curWord, 'center', 'center' );
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
                end
                    Screen('Flip',PTBwindow);
                end
               %% if correct
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
                    Screen('DrawTexture', PTBwindow, right_mid_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'2')
                    Screen('DrawTexture', PTBwindow, right_index_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'3')
                    Screen('DrawTexture', PTBwindow, left_index_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0; 
                elseif strcmp(curWord,'4')
                    Screen('DrawTexture', PTBwindow, left_mid_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;  
                elseif strcmp(curWord,'5')
                    Screen('DrawTexture', PTBwindow, left_ring_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;                    
                end
                %record resp
                output{i,3}=exp_start;%record ExpStartTime for each trial since we dont know when the run is going to restart
                i=i+1;
            end
            DrawFormattedText(w,endofprac, 'center', 'center' );
            Screen('Flip',PTBwindow);
            WaitSecs(3)
            Screen('CloseAll')
        catch %#ok<*CTCH>
            % This "catch" section executes in case of an error in the "try"
            % section []
            % above.  Importantly, it closes the onscreen window if it's open.
            sca;
            fclose('all');
            psychrethrow(psychlasterror);
          end
        
          
          
          
%% version 2

    case 2 % 5 on right
           r5=KbName('3#');
           r4=KbName('2@');
           r3=KbName('1!');
           r2=KbName('6^');
           r1=KbName('7&');
%            animate=KbName('3');
%            inanimate=KbName('2');
          try
              %% initialize instructions

            %make image matrices into OpenGL textures, not drawing them
            %yet!            
            left_mid_tex= Screen('MakeTexture', PTBwindow, left_mid);
            left_index_tex= Screen('MakeTexture', PTBwindow, left_index);
            right_index_tex= Screen('MakeTexture', PTBwindow, right_index);
            right_mid_tex= Screen('MakeTexture', PTBwindow, right_mid);
            right_ring_tex= Screen('MakeTexture', PTBwindow, right_ring);
            v2tex=Screen('MakeTexture', PTBwindow, handv2);
%             %get inter-rrame interval
%             ifi = Screen('GetFlipInterval', w);
%             % Interstimulus interval time in seconds and frames
%             isiTimeSecs = 1;
%             isiTimeFrames = round(isiTimeSecs / ifi);
            % Select specific text font, style and size:
            Screen('TextFont',PTBwindow, 'Courier New');
            Screen('TextSize',PTBwindow, 64);
            Screen('TextStyle', PTBwindow, 1+2);
           
            % Read instruction file:
            fd = fopen('key_prac_ins.m');
            if fd==-1
                error('Could not open instructions.m file.');
            end

            mytext = '';
             %skip the first 20 lines
             for k=1:17
                fgets(fd); 
             end
            lcount = 18;
            tl=fgets(fd);
            while lcount < 33
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
            [nx, ny, bbox] = DrawFormattedText(PTBwindow, mytext,'center','center');

            Screen('Flip',PTBwindow);
            KbStrokeWait;
            
            Screen('DrawTexture', PTBwindow, v2tex);
            Screen('Flip',PTBwindow);
            KbStrokeWait;

            %% practice procedure
                %threshold for consecutive correct responses
                success=0;
            while success < 45
               respond=true;
               curWord=datasample(stim,1);%randomly sample from the 7 options
               curWord=curWord{1};
                %draw fixation
                DrawFormattedText(PTBwindow, '+', 'center', 'center');
                
                Screen('Flip',PTBwindow);
                WaitSecs(2);
               %% get response
               while respond==true
               
                DrawFormattedText(PTBwindow,curWord, 'center', 'center' );
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
%                 elseif strcmp(curWord,'animate')&&keyCode(animate)
%                        success=success+1;
%                        respond=false;
%                 elseif strcmp(curWord,'inanimate')&&keyCode(inanimate)
%                        success=success+1;
%                        respond=false;
%                 else
%                        success=0;
%                        respond=false;
                end
                    Screen('Flip',PTBwindow);
                end
               %% if correct
%                 if strcmp(curWord,'animate')&&strcmp(resp,'3')
%                     success=success+1;
%                 elseif strcmp(curWord,'inanimate')&&strcmp(resp,'2')
%                     success=success+1;


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
                    Screen('DrawTexture', PTBwindow, left_mid_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'2')
                    Screen('DrawTexture', PTBwindow, left_index_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'3')
                    Screen('DrawTexture', PTBwindow, right_index_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'4')
                    Screen('DrawTexture', PTBwindow, right_mid_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'5')
                    Screen('DrawTexture', PTBwindow, right_ring_tex);
                    Screen('Flip',PTBwindow);
                    WaitSecs(2);
                    success=0;
                end
                         
            end
            DrawFormattedText(PTBwindow,endofprac, 'center', 'center' );
            Screen('Flip',PTBwindow);
            WaitSecs(3)
            Screen('CloseAll')
        catch %#ok<*CTCH>
            % This "catch" section executes in case of an error in the "try"
            % section []
            % above.  Importantly, it closes the onscreen window if it's open.
            sca;
            fclose('all');
            psychrethrow(psychlasterror);
        end

    otherwise
        error('there are only two versions for hand mapping')
end

end