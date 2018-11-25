
function err = PS_PRC_1back_HY_test

err= [];
%addpath('C:\Usgybers\Bobby\Dropbox\Matlab\fMRI\AB_Memory\')
% addpath('/Users/bobbysrrrybbrbbyyybbbyybybybybyytojanoski/Dropbox/Matlab/fMRI/AB_Memory/')
%abort the experiment by pressing Esc
%if experiment crashes for whatever reason press ctrl+c to get keyboard function back

KbName('UnifyKeyNames');

% Reseed the random-number generator for each expt.
rand('state',sum(100*clock));

% if nargin < 1
% %     path = 'D:\Dropbox\Experiments\fMRI\AB_Memory\Images\';
%     path = '/Users/kaylaferko/Desktop/PS_PRC_testing/nback/';
%     
% end
% if nargin < 2
%     counterbalanceResponseMode = -1;
% end

% pathStim = 'D:\Dropbox\Experiments\fMRI\AB_Memory\Images\';
pathStim = 'C:/Users/haozi/Desktop/PhD/fMRI_PrC-PPC/stmuli/';
cd(pathStim)

%KEYS 
animate = KbName('y'); %animate concept
inanimate = KbName('g'); %inanimate concept

pulsekey =  KbName('t'); %scanner starting trigger @HY
escapekey = KbName('ESCAPE');
enterkey = KbName('SPACE');


% %VARIABLES
datafilename =  input('please enter the participant number: ', 's');
stimBlock = input('please enter the block number: ', 's');
currBlock = str2num(stimBlock);
% currBlock = currBlock_og +currBlock_og-1;


%CREATE DATAFILE
datafile = fopen([num2str(datafilename) '.txt'], 'a');
% fprintf(datafile, 'ParticipantNum\t Block\t Trial\t ExpStartTime\t Image\t ImageOnestTime\t Response1\t Response2\t ResponseJ\t RespTime1\t RespTime2\t RespTimeJ\n');
fprintf(datafile, 'ParticipantNum\t Block\t Trial\t ExpStartTime\t Image\t ImageOnsetTime\t Response1\t ResponseJ\t RespTime1\t RespTimeJ\n');

%Exp parameters
resp = [];
rt_window=3;
%Load images according to set list; counterbalance ver5_1 | ver5_2 | ver5_3
[Jit, ImName] = xlsread(sprintf('%sstimuli_jitter_PSPRC_ver5_2.xls',pathStim));
%Correct Jitter times per Block
Jit = 1; %Jit(:,1:2:13); 
% JitInt = Jit(:,currBlock); 
% JitInt = JitInt/1000; 
JitInt = Jit;

%Select Images per Block
ImName = ImName(:,1:2:size(ImName,2));

TotDataSet = ImName(:,currBlock);

stimDur1 = 1.2;
% stiDur2 = .6;
%The total set of images.
numimages = length(TotDataSet); %total number of trials since all dataset
%numimages = length(3); %total number of trials since all dataset

%Screen paremeters
%winsize = [0 0 1280 800];
%make winsize 1 pixel less than resolution of VgA display 
winsize = [0 0 799 599];
bckgcolour = [128 128 128];
% no_trials= 48;
% no_pics=12;
% picture_order=1:no_pics;cclose all

%pics_shuffled=Shuffle(picture_order); %randomize order in which pictures are presented

ListenChar(2);   %prevents writing into the command window during the experiment

%OPEN EXPERIMENTAL SCREEN
try %embedded in try-catch in case something goes wrong
    screenNumber = 0;
    [window,screenRect] = Screen(screenNumber,'OpenWindow',bckgcolour,winsize);
    
    %COLOURS
    white = WhiteIndex(window); % pixel value for white
    black = BlackIndex(window); % pixel value for black
    
    %open offscreen window
    [offwindow1,oRect] = Screen(screenNumber,'OpenOffscreenWindow');
    [offwindow2,oRect] = Screen(screenNumber,'OpenOffscreenWindow');
    Screen(offwindow1,'FillRect',bckgcolour);
    Screen(offwindow2,'FillRect',bckgcolour);
    
    Screen(window,'FillRect', bckgcolour);
    HideCursor;
    WaitSecs(1);
    
    %INFO
%     instString = 'Welcome and thank you for participating!';
%     DrawFormattedText(window ,instString,400,100,black);
%     instString = 'You will see a series of images';
%     DrawFormattedText(window  ,instString, 400 ,300,black);
%     instString = 'Your task is simple:  Pay attention to each image!';
%     DrawFormattedText(window ,instString,400,350,black);
%     instString = 'Do you have any questions? If not, Click the mouse to continue';
%     DrawFormattedText(window ,instString,400,600,black);
%     Screen(window, 'Flip');
%     GetClicks;
    
    %     info = 'The experiment is going to start after the countdown';
    %     DrawFormattedText(window, info, 'center', 'center', black);
    %     Screen(window, 'Flip');
    %     WaitSecs(2);
    %
%         %COUNTDOWN
%         for countdown=5:-1:1
%             count_text=sprintf('%d', countdown);
%             DrawFormattedText(window, count_text, 'center', 'center', black);
%             Screen(window, 'Flip');
%             WaitSecs(1.0);
%         end;
    %
    %     DrawFormattedText(window, '+', 'center', 'center', black);
    %     Screen(window, 'Flip');
    %     WaitSecs(1);
        %INFO
    info = 'The experiment is going to start in a few seconds';
    DrawFormattedText(window, info, 'center', 'center', black);
    Screen(window, 'Flip');
    WaitSecs(2);
    
    DrawFormattedText(window, '+', 'center', 'center', black);
    Screen(window, 'Flip');
    WaitSecs(1);
    tic
    DummyStart = toc;     %WAIT FOR DUMMY SCANS
    dummies = 5;
    dummy_list=(dummies:-1:1); %number of dummies
    for i=1:dummies
        dummy=dummy_list(i);
        while 1
            [keyIsDown,curTime,keyCode] = KbCheck(-1);
            if keyCode(pulsekey), dummy_time=curTime;
                number=num2str(dummy);
                if i==1
                    dummy_start=curTime;
                end
                fprintf('dummy %d\n',dummy)
                break;
            end
        end
        alldummies(i)=dummy_time;
        
        while KbCheck
        end
    end
    
    exp_start=toc; %This corresponds to onset of first images
    save(sprintf('%s_dummies',datafilename),'alldummies','DummyStart','exp_start', 'dummy_start');


    for imIdx = 1:size(TotDataSet,1) % 1:numibmages %this is the total list of objects to be presented
        
        DrawFormattedText(window, '+', 'center', 'center', black);
        Screen(window,'TextSize',30);
        Screen(window, 'Flip');
%         WaitSecs(.75);
        
        %load borderless image
        ImageOnsetTime = toc;
%         RespWindow = bdlessOnsetTime+stimDur1+stimDur1+JitInt(imIdx);
        
        while toc<ImageOnsetTime+stimDur1
%             Image1=[TotDataSet{(imIdx)}]
            showImage1 = imread([TotDataSet{(imIdx)}]);
            %place stimuli on offscreen window
            Screen(offwindow1,'PutImage',showImage1);
            %present pictures - copy offscreen windows to window
            Screen('CopyWindow',offwindow1,window);
            Screen(window, 'Flip');
%             
            [keyIsDown, endrt, keyCode] = KbCheck(-1);
            if isempty(find(keyCode))
                resp1 = 'np';
                resptime1= 999;
            elseif keyCode(pulsekey)
                scannerTrig = 999;
            elseif keyCode(inanimate)
                resp1 = KbName(keyCode)
                resptime1 = toc
                WaitSecs(ImageOnsetTime+stimDur1-resptime1)
%                 break
            elseif keyCode(animate)
                resp1 = KbName(keyCode)
                resptime1 = toc
                WaitSecs(ImageOnsetTime+stimDur1-resptime1)
%                 break
            end;
            
            while KbCheck;
            end
        end
       
        
%         borderOnsettime = toc; %Note: resptime-borderOnsettime should be positive; if negative it means they responded before the red border appeared        
%         while toc<borderOnsettime+stiDur2
%             %load bordered image
%             showImage2 = imread(sprintf('2%s',TotDataSet{(imIdx)}));
%             %place stimuli on offscreen window
%             Screen(offwindow2,'PutImage',showImage2);
%             %present pictures - copy offscreen windows to window
%             Screen('CopyWindow',offwindow2,window);
%             Screen(window, 'Flip');
% %             
%             [keyIsDown, endrt, keyCode] = KbCheck(-2);
%             if isempty(find(keyCode))
%                 resp2 = 'np'
%                 resptime2= 999;
%             elseif keyCode(pulsekey)
%                 scannerTrig = 999;
%             elseif keyCode(rightkey)
%                 resp2 = KbName(keyCode)
%                 resptime2 = toc
%                 WaitSecs(borderOnsettime+stiDur2-resptime2)
% %                 break
%             elseif keyCode(leftkey)
%                 resp2 = KbName(keyCode)
%                 resptime2 = toc
%                 WaitSecs(borderOnsettime+stiDur2-resptime2)
% %                 break
%             end;
%             
%             while KbCheck;
%             end
%             
%         end
        JitStart = toc;
        while toc<JitStart+JitInt%(imIdx)
            %ITT with random Jitter
            DrawFormattedText(window, '+', 'center', 'center', black);
            Screen(window,'TextSize',30);
            Screen(window, 'Flip');
             
            [keyIsDown, endrt, keyCode] = KbCheck(-2);
            if isempty(find(keyCode))
                respJ = 'np'
                resptimeJ= 999;
            elseif keyCode(pulsekey)
                scannerTrig = 999;                
            elseif keyCode(inanimate)
                respJ = KbName(keyCode)
                resptimeJ = toc
                WaitSecs(JitStart+JitInt-resptimeJ)
%                 break
            elseif keyCode(animate)
                respJ = KbName(keyCode)
                resptimeJ = toc
                WaitSecs(JitStart+JitInt-resptimeJ)
%                 break
            end;
            
            while KbCheck;
            end
        end
        
        %WRITE DATA TO FILE
        datafile = fopen([num2str(datafilename) '.txt'], 'a');
        fprintf(datafile, '%s\t %d\t %d\t %f\t %s\t %f\t %s\t %s\t %f\t %f\t \n', datafilename, currBlock, imIdx, exp_start, [TotDataSet{(imIdx)}], ImageOnsetTime, ...
         resp1,respJ, resptime1,resptimeJ);
        fclose(datafile); %File is saved in the stim folder
        %         save(sprintf('Data/%s_beh_study.mat',pname),'dataOut');
        
    end %for imIdx
    
    
    %DONE INFO
    done = 'You are done. Thank you!';
    DrawFormattedText(window, done, 'center', 'center', black);
    Screen(window, 'Flip');
    WaitSecs(2);
    %KbWait; 
    %while KbCheck; end;
    
    %CLOSE EXPERIMENTAL SCREEN
    Screen('CloseAll');
    ShowCursor
    %         end
    
    %%
catch ME
    % This "catch" section executes in case of an error in the "try" section
    % above.  Importantly, it closes the onscreen window if it's open.
    Screen('CloseAll');
    %             psychrethrow(psychlasterror);
    ShowCursor
    ListenChar(0);
    err = ME;
end %end of try-catch

ListenChar(0);


