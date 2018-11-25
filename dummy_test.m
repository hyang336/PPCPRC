scan_trig=KbName('t');
        dummy=5;
        dummy_t=cell(dummy,1);
%     for i=1:dummy
%            keyCodes(scan_trig)=0;
%            while ~keyCodes(scan_trig)
%             [keyIsDown, dummy_start, keyCodes] = KbCheck(-1);
%            end
%            fprintf('dummy %d\n',i)
%            dummy_t{i}=dummy_start;%resolution shows in second, but are actually finer (hint:take the difference)
%                    
%            %KbCheck will return 1 whenever a key is pressed, the following
%            %loop seems to hault the for loop until the key is released.
%            %helpful in preventing one key pressing being registered as
%            %multiple press
%            while KbCheck(-1)
%            end
%         end


%this also works, KbReleaseWait quaries the keyboard every 5ms, not sure if
%this is more frequent than while KbCheck loop or not
    for i=1:dummy
           waitfortrig=1;
           while waitfortrig
            [keyIsDown, dummy_start, keyCodes] = KbCheck(-1);
            if keyCodes(scan_trig)
                fprintf('dummy %d\n',i)
                dummy_t{i}=dummy_start;
                %reset if condition
                keyCodes(scan_trig)=0;
                %reset while condition
                waitfortrig=0;
            end
           end
           KbReleaseWait;

    end
        
        