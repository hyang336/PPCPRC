function key_prac(version)
%present 1-5 to familiarize the subjects with key
%mapping. Keep presenting until get 45 (a full run) correct in a row, order
%randomly sampled using datasampe(data,n). If participants make a wrong
%response, they will be shown a picture of the correct key for 2
%secondes(may need to adjust codes for screens with different resolutions).
%% surpress the screen sync error on Windows, will like result in wildly inaccurate timing of stimulus onsets
Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);

%create a cell structure for all the options
stim={'1','2','3','4','5'};%,'animate','inanimate'};
KbName('UnifyKeyNames');
endofprac='practice ends';

%load images
img_folder='C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC\button_box\';
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
          r5=KbName('8*');
          r4=KbName('7&');
          r3=KbName('6^');
          r2=KbName('1!');
          r1=KbName('2@');
%           animate=KbName('3#');
%           inanimate=KbName('4$');
          try
           %% initialize instructions
            screens=Screen('Screens');
            screenNumber=max(screens);

            % Open window with default settings:
            [w,rect]=Screen('OpenWindow', screenNumber);
            [xCenter, yCenter] = RectCenter(rect);
            
            %make image matrices into OpenGL textures, not drawing them
            %yet!
            left_ring_tex = Screen('MakeTexture', w, left_ring);
            left_mid_tex= Screen('MakeTexture', w, left_mid);
            left_index_tex= Screen('MakeTexture', w, left_index);
            right_index_tex= Screen('MakeTexture', w, right_index);
            right_mid_tex= Screen('MakeTexture', w, right_mid);
            v1tex=Screen('MakeTexture',w,handv1);
%             %get inter-rrame interval
%             ifi = Screen('GetFlipInterval', w);
%             %Interstimulus interval time in seconds and frames
%             isiTimeSecs = 1;
%             isiTimeFrames = round(isiTimeSecs / ifi);
            % Select specific text font, style and size:
            Screen('TextFont',w, 'Courier New');
            Screen('TextSize',w, 64);
            Screen('TextStyle', w, 1+2);
            
            % Read instruction file:
            fd = fopen('key_prac_ins.m');
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
            while lcount < 17%ending line
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
            
            Screen('DrawTexture', w, v1tex);
            Screen('Flip',w);
            KbStrokeWait;

            %% practice procedure
                %threshold for consecutive correct responses
                success=0;
            while success < 45
               respond=true;
               curWord=datasample(stim,1);%randomly sample from the 7 options
               curWord=curWord{1};
                %draw fixation
                DrawFormattedText(w, '+', 'center', 'center');
                
                Screen('Flip',w);
                WaitSecs(2);
               %% get response
               while respond==true
               
                DrawFormattedText(w,curWord, 'center', 'center' );
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
                    Screen('Flip',w);
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
                    Screen('DrawTexture', w, right_mid_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'2')
                    Screen('DrawTexture', w, right_index_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'3')
                    Screen('DrawTexture', w, left_index_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0; 
                elseif strcmp(curWord,'4')
                    Screen('DrawTexture', w, left_mid_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;  
                elseif strcmp(curWord,'5')
                    Screen('DrawTexture', w, left_ring_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;                    
                end
                          
            end
            DrawFormattedText(w,endofprac, 'center', 'center' );
            Screen('Flip',w);
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
            screens=Screen('Screens');
            screenNumber=max(screens);

            % Open window with default settings:
            [w,rect]=Screen('OpenWindow', screenNumber);
            [xCenter, yCenter] = RectCenter(rect);
            
            %make image matrices into OpenGL textures, not drawing them
            %yet!            
            left_mid_tex= Screen('MakeTexture', w, left_mid);
            left_index_tex= Screen('MakeTexture', w, left_index);
            right_index_tex= Screen('MakeTexture', w, right_index);
            right_mid_tex= Screen('MakeTexture', w, right_mid);
            right_ring_tex= Screen('MakeTexture', w, right_ring);
            v2tex=Screen('MakeTexture', w, handv2);
%             %get inter-rrame interval
%             ifi = Screen('GetFlipInterval', w);
%             % Interstimulus interval time in seconds and frames
%             isiTimeSecs = 1;
%             isiTimeFrames = round(isiTimeSecs / ifi);
            % Select specific text font, style and size:
            Screen('TextFont',w, 'Courier New');
            Screen('TextSize',w, 64);
            Screen('TextStyle', w, 1+2);
           
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
            [nx, ny, bbox] = DrawFormattedText(w, mytext,'center','center');

            Screen('Flip',w);
            KbStrokeWait;
            
            Screen('DrawTexture', w, v2tex);
            Screen('Flip',w);
            KbStrokeWait;

            %% practice procedure
                %threshold for consecutive correct responses
                success=0;
            while success < 45
               respond=true;
               curWord=datasample(stim,1);%randomly sample from the 7 options
               curWord=curWord{1};
                %draw fixation
                DrawFormattedText(w, '+', 'center', 'center');
                
                Screen('Flip',w);
                WaitSecs(2);
               %% get response
               while respond==true
               
                DrawFormattedText(w,curWord, 'center', 'center' );
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
                    Screen('Flip',w);
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
                    Screen('DrawTexture', w, left_mid_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'2')
                    Screen('DrawTexture', w, left_index_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'3')
                    Screen('DrawTexture', w, right_index_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'4')
                    Screen('DrawTexture', w, right_mid_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                elseif strcmp(curWord,'5')
                    Screen('DrawTexture', w, right_ring_tex);
                    Screen('Flip',w);
                    WaitSecs(2);
                    success=0;
                end
                         
            end
            DrawFormattedText(w,endofprac, 'center', 'center' );
            Screen('Flip',w);
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