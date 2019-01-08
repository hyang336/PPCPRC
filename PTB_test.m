% Screen('Preference','SkipSyncTests',1);
% Screen('Preference','VisualDebugLevel',0);
% window=Screen(2,'OpenWindow');
% study_scale='animate         inanimate';
% DrawFormattedText(window,study_scale, 'center', 'center' );
% Screen('Flip',window);%gotta have this line to draw anything on screen
% WaitSecs(6);
% Screen('CloseAll');


%%
% r5=KbName('1!');
% success=0;
% while success < 45
%                respond=true;
%                curWord='5';
%                 %draw fixation
% %                 Screen('DrawDots', w, [xCenter; yCenter], 20, [1 0 0 1],[],1,1);
% %                 
% %                 vbl=Screen('Flip',w,vbl+2);
% %                 
%                while respond==true
% 
%                 % Check the keyboard.
%                 [keyIsDown,secs, keyCode] = KbCheck(-1);
%                 
%                 if keyCode(r5)
%                        resp='5';
%                        respond=false;
% %                     vbl=Screen('Flip',w);
%                 end
%                end
%                 if strcmp(curWord,'animate')&&strcmp(resp,'3')
%                     success=success+1;
%                 elseif strcmp(curWord,'inanimate')&&strcmp(resp,'2')
%                     success=success+1;
%                 elseif strcmp(curWord,'1')&&strcmp(resp,'1')
%                     success=success+1;
%                 elseif strcmp(curWord,'2')&&strcmp(resp,'2')
%                     success=success+1;
%                 elseif strcmp(curWord,'3')&&strcmp(resp,'3')
%                     success=success+1;
%                 elseif strcmp(curWord,'4')&&strcmp(resp,'4')
%                     success=success+1;
%                 elseif strcmp(curWord,'5')&&strcmp(resp,'5')
%                     success=success+1;
%                 else
%                     success=0;
%                 end
%                 
%                success
% 
%               
% end

%%
% Screen('Preference','SkipSyncTests',1);
% Screen('Preference','VisualDebugLevel',0);
% 
% screens=Screen('Screens');
%             screenNumber=max(screens);
% 
%             % Open window with default settings:
%             [w,rect]=Screen('OpenWindow', screenNumber);
%             [xCenter, yCenter] = RectCenter(rect);
% left_ring_tex = Screen('MakeTexture', w, left_ring);
% Screen('DrawTexture', w, left_ring_tex);
% Screen('Flip',w);
% WaitSecs(3);
% Screen('CloseAll');

%%
% function data=PTB_test(SSID,version_inp,run)
% data=cell(46,9);%45 trials per run plus headers
% data(1,:)={'ParticipantNum' 'Version' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'StimOnsetTime' 'Response' 'RespTime'};
% SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
% data(2:end,1)={SSID};
% data(2:end,2)={version_inp};
% data(2:end,3)={run};
% end

%% trigger test
KbName('UnifyKeyNames');
dummy=2;
scan_trig='t';
keynum=KbName(scan_trig);
        dummy_t=cell(dummy,1);
        keyCodes(1:256)=0;
    for i=1:dummy
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
           
           fprintf('dummy %d\n',i)
           dummy_t{i}=dummy_start;%resolution shows in second, but are actually finer (hint:take the difference)

    end
    exp_start=dummy_t{end};
    