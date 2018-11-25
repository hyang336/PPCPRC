function procedure(SSID,version_inp,run)
%16 versions (hand (2) * set_selection (2) * block_order (4)).
%study phase one run, test phase one run, both triggered by scanner.
%pseudorandomization done for each Ss individually.
%study phase has spacing constraint for repetitions
%test phase presentation is simple shuffling, since there is no repetition.

%% surpress the screen sync error on Windows, will like result in wildly inaccurate timing of stimulus onsets
Screen('Preference','SkipSyncTests',1);
Screen('Preference','VisualDebugLevel',0);

%% initialize constants
KbName('UnifyKeyNames');
scan_trig=KbName('t');
pathStim = 'C:/Users/haozi/Desktop/PhD/fMRI_PrC-PPC/stmuli/';
cd(pathStim)
%create data cell, later use xlswrite to export
data=cell(46,9);%45 trials per run plus headers
data(1,:)={'ParticipantNum' 'Version' 'Run' 'Trial' 'ExpStartTime' 'Stimuli' 'StimOnsetTime' 'Response' 'RespTime'};
SSID=num2str(SSID,'%03.f');%pad SSID with zeros and convert to string
data(2:end,1)={SSID};
data(2:end,2)={version_inp};
data(2:end,3)={run};
% datafile = fopen([num2str(SSID) '.txt'], 'a');
% fprintf(datafile, 'ParticipantNum\t Version\t Run\t Trial\t ExpStartTime\t Stimuli\t StimOnsetTime\t Response\t RespTime\t');
winsize = [0 0 799 599];
bckgcolour = [128 128 128];
scanner_screen=2; %before running the script, use Screen('Screens') to determine the scanner screen number
dummy=1;%according to Trevor the scanner automatically discard the first 4 volumes, and send the first trigger at the beginning of the 5th.
%in that case we only need to discard one more volume to have a
%total of 5 dummy scans

%% assuming left to right keys are 1 2 3 4 5, with 3 keys mapped on the left hand for first version and on the right hand for the second version
%The buttonbox has two setup (see black notebook), always 1 to 5 from left
%to right. In v1 123 are mapped onto the left box, 45 on the right. In v2
%12 are mapped onto the left box, 345 on the right
%define the two versions of key mapping and scale on screen as struct
   hand(1).r5=KbName('1!');
   hand(1).r4=KbName('2@');
   hand(1).r3=KbName('3#');
   hand(1).r2=KbName('4$');
   hand(1).r1=KbName('5%');
   hand(1).animate=KbName('3#');
   hand(1).inanimate=KbName('4$');
   hand(1).study_scale='animate         inanimate';
   hand(1).test_scale='5   4   3   2   1';
   
   hand(2).r5=KbName('5%');
   hand(2).r4=KbName('4$');
   hand(2).r3=KbName('3#');
   hand(2).r2=KbName('2@');
   hand(2).r1=KbName('1!');
   hand(2).animate=KbName('3#');
   hand(2).inanimate=KbName('2@');
   hand(2).study_scale='inanimate         animate';
   hand(2).test_scale='1   2   3   4   5';
    %% setup stimuli and key mapping for different versions, see version.mat in stimuli folder for reference
    switch version_inp    

        case 1
    %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','A2:B451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','A2:B181');
     
     %key mapping 
        hand_v=1;
     %test phase block order
     test_first='recent';

        case 2
    %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','A2:B451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','A2:B181');      

     %key mapping 
        hand_v=2;
     %test phase block order
     test_first='recent';       
        
        case 3
     %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','E2:F451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','A2:B181');      

      %key mapping 
        hand_v=1;
     %test phase block order
     test_first='recent';

        case 4
     %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','E2:F451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','A2:B181');      

     %key mapping 
        hand_v=2;
     %test phase block order
     test_first='recent';
     
        case 5
     %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','I2:J451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','E2:F181');      

      %key mapping 
        hand_v=1;
     %test phase block order
     test_first='lifetime';

        case 6
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','I2:J451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','E2:F181');      

      %key mapping 
        hand_v=2;
     %test phase block order
     test_first='lifetime';
     
        case 7
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','M2:N451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','E2:F181');      

      %key mapping 
         hand_v=1;
     %test phase block order
     test_first='lifetime';

        case 8
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1study_jitter','M2:N451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v1test_jitter','E2:F181');      

     %key mapping 
        hand_v=2;
     %test phase block order
     test_first='lifetime';
     
        case 9
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','A2:B451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','A2:B181');      

      %key mapping 
        hand_v=1;
     %test phase block order
     test_first='recent';

        case 10
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','A2:B451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','A2:B181');      

     %key mapping 
        hand_v=2;
     %test phase block order
     test_first='recent';
     
        case 11
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','E2:F451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','A2:B181');      

      %key mapping 
        hand_v=1;
     %test phase block order
     test_first='recent';

        case 12
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','E2:F451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','A2:B181');      

     %key mapping 
        hand_v=2;
     %test phase block order
     test_first='recent';
     
        case 13
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','I2:J451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','E2:F181');      

      %key mapping 
        hand_v=1;
     %test phase block order
     test_first='lifetime';

        case 14
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','I2:J451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','E2:F181');      

      %key mapping 
        hand_v=2;
     %test phase block order
     test_first='lifetime';
     
        case 15
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','M2:M451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','E2:F181');      

      %key mapping 
         hand_v=1;
     %test phase block order
     test_first='lifetime';

        case 16
            %load in stimulus set
     [study_num,study_txt,~] = xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2study_jitter','M2:N451');
     [test_num,test_txt,~]=xlsread(strcat(pathStim,'genetic_180_rand_jitter_run45'),'v2test_jitter','E2:F181');      
     
     %key mapping 
        hand_v=2;
     %test phase block order
     test_first='lifetime';
     
        otherwise
            error('version out of range [1, 16]')
    end
    
    %% run specific setup for stimuli, jitter, and instructions
    %totel 14 runs, the first 10 runs are study, and the last 4 are
    %test,each run has 45 stimuli
    if run<=10&&run>=1
          run_stim=study_txt((run-1)*45+2:run*45+1);%get the stimuli for the selected run in study phase
          run_jit=study_num((run-1)*45+2:run*45+1);%get jittering time
          %depending on the hand mapping version, show different
          %instructions for study phase
          if mod(hand_v,2)==1
            
          else
              
          end
    else
        if run>=11&&run<=14
          run_stim=test_txt((run-11)*45+2:(run-10)*45+1); %get the stimuli for the selected run in test phase
          run_jit=test_num((run-11)*45+2:(run-10)*45+1);%get jittering time
          
          %make stimuli blocks according to test_first
          switch test_first
              case 'recent'
              
              case 'lifetime'
                  
              otherwise
                  error('test phase block order error')
          end
          %depending on the hand mapping version, show different
          %instructions for test phase
          if mod(hand_v,2)==1
            
          else
              
          end
        else
          error('run number out of range [1,14]')
        end
    end
    
    
    %% presenting using a screen, enclosed in a try-catch block so it doesn't freeze on error
    try
        
        %screens=Screen('Screens');%check connected screens, 0 is ALL screens on Windows
        %use the scanner moniter 
        window = Screen(scanner_screen,'OpenWindow',bckgcolour,winsize); %timing will be inevitably off on Windows after 8, mainly due to the highly varying and above-threshold std from the test calls of screen('Flip').

        %COLOURS
        white = WhiteIndex(window); % pixel value for white
        black = BlackIndex(window); % pixel value for black

        %not sure what is offscreenwindow and why we need it, by HY
        %open offscreen window
%         offwindow1= Screen('OpenOffscreenWindow',scanner_screen);
%         offwindow2 = Screen('OpenOffscreenWindow',scanner_screen);
%         Screen(offwindow1,'FillRect',bckgcolour);
%         Screen(offwindow2,'FillRect',bckgcolour);

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
        
        %% wait for the first n volumes as dummy scans
        dummy_t=cell(dummy,1);
        keyCodes(1:256)=0;
    for i=1:dummy
           keyCodes(scan_trig)=0;%gotta reset the scan_trigger since im using it as the condition for while-loop
           while ~keyCodes(scan_trig)
            [keyIsDown, dummy_start, keyCodes] = KbCheck(-1);
           end
           fprintf('dummy %d\n',i)
           dummy_t{i}=dummy_start;%resolution shows in second, but are actually finer (hint:take the difference)
                   
           %KbCheck will return 1 whenever a key is pressed, the following
           %loop seems to hault the for loop until the key is released.
           %helpful in preventing one key pressing being registered as
           %multiple press
           while KbCheck(-1)
           end
    end
    
    %wait for the trigger of dummy+1 volume. E.g. if we have 5 dummy scan,
    %the 6th is the first volume of the real scan, but the trigger is sent
    %at the beginning of each volume, so after the above for-loop we still
    %need to wait one more trigger to start presenting stimuli
    keyCodes(1:256)=0;
    while ~keyCodes(scan_trig)
            [~, exp_start, keyCodes] = KbCheck(-1);%exp_start correspond to the beggining of the first real volume
    end
    
     
    %% loop through stimuli for the current run
    for stim=1:size(run_stim,1)
        
        hand(hand_v).r5
    
    end
        
    catch
        Screen('CloseAll');
        
    end