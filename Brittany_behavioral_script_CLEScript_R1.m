clearvars;

%load stimuli
[num,txt,raw] = xlsread('ConceptsCombined_Numbered_Randomized','Randomized 1');
wordList_1=raw(2:end,:);
[num,txt,raw] = xlsread('ConceptsCombined_Numbered_Randomized','Randomized 2');
wordList_2=raw(2:end,:);
[num,txt,raw] = xlsread('ConceptsCombined_Numbered_Randomized','Randomized 3');
wordList_3=raw(2:end,:);

prompt='please type in your participant number';
SSID = inputdlg(prompt);
Screen('Preference', 'SkipSyncTests', 1);
close all;
sca;  
 
% Setup PTB with some default values
PsychDefaultSetup(2);
 
% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));
 
% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define black, white and grey
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

%% edited by HY
Screen('Preference', 'SkipSyncTests', 1)

% Open the screen
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey, [], 32, 2);
 
% Flip to clear
Screen('Flip', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);
 
% Set the text size
Screen('TextSize', window, 60);
 
% Query the maximum priority level
topPriorityLevel = MaxPriority(window);
 
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);
 
% Set the blend funciton for the screen
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
 
 
%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------
 
% Interstimulus interval time in seconds and frames
isiTimeSecs = 1;
isiTimeFrames = round(isiTimeSecs / ifi);
 
% Numer of frames to wait before re-drawing
waitframes = 1;
 
 
%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------
 
% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
downKey = KbName('DownArrow');
 
 

%----------------------------------------------------------------------
%                       Experimental loop
%----------------------------------------------------------------------
 
% Animation loop: we loop for the total number of trials

wordList_size = size(wordList_1);
blockNum = 3;  %sets the number of blocks
respMat = nan(3, wordList_size(1),blockNum);


for curBlock = 1:blockNum
    
   if curBlock == 1
      %Load different wordlist for each block here 
       curInstructions = 'Part One: Concept Familiarity\n\n Please rate how much experience you have\n with each concept on a scale of 1 to 9.\n\n  1 = Very little experience\n 9 = A lot of experience.\n\n  Press the space bar to begin.';
       stimuli=wordList_1;
   elseif curBlock == 2
        %Load different wordlist for each block here 
       curInstructions = 'Part Two: Semantic Knowledge\n\n Please rate how much information\n(i.e., knowledge)\nyou have for each concept\n on a scale of 1 to 9.\n\n 1 = Very little knowledge\n 9 = A lot of knowledge\n\n Press the space bar to begin.';
       stimuli=wordList_2;
   elseif curBlock == 3
        %Load different wordlist for each block here 
       curInstructions = 'Part Three: Episodic Ease\n\n Please rate how easily you can bring to mind\n a specific past episode (i.e.,memory) involving\n each of the concepts on a scale of 1 to 9.\n\n 1 = Very difficult to think of a past episode\n 9 = Easily able to think of a past episode\n\n Press space bar to begin.';
       stimuli=wordList_3; 
   end 
    
for trial = 1:wordList_size(1)
 
    curWordNum = stimuli{trial,1};
    curWord = stimuli{trial,2};
    
    % Word and color number
    %wordNum = condMatrixShuffled(1, trial);
    % colorNum = condMatrixShuffled(2, trial);
 
    % The color word and the color it is drawn in
    %theWord = wordList(wordNum);
    % theColor = rgbColors(colorNum, :);
 
    % Cue to determine whether a response has been made
 
respToBeMade=true;
    
    if trial == 1
        
            while respToBeMade == true
  
        % Draw the word
   %     DrawFormattedText(window, char(theWord), 'center', 'center', theColor);
 DrawFormattedText(window,curInstructions, 'center', 'center' );
        % Check the keyboard. The person should press the
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(44 )
            
            respToBeMade = false;
        end
   vbl = Screen('Flip', window);
        % Flip to the screen
            end
    end
    
    
    respToBeMade = true;
        
        
        
    
    
 
    % Flip again to sync us to the vertical retrace at the same time as
    % drawing our fixation point
    Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
    vbl = Screen('Flip', window);
 
    % Now we present the isi interval with fixation point minus one frame
    % because we presented the fixation point once already when getting a
    % time stamp
    for frame = 1:isiTimeFrames - 1
 
        % Draw the fixation point
        Screen('DrawDots', window, [xCenter; yCenter], 10, black, [], 2);
 
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
 
    % Now present the word in continuous loops until the person presses a
    % key to respond. We take a time stamp before and after to calculate
    % our reaction time. We could do this directly with the vbl time stamps,
    % but for the purposes of this introductory demo we will use GetSecs.
    %
    % The person should be asked to respond to either the written word or
    % the color the word is written in. They make thier response with the
    % three arrow key. They should press "Left" for "Red", "Down" for
    % "Green" and "Right" for "Blue".
    tStart = GetSecs;
    while respToBeMade == true
  
        % Draw the word
   %     DrawFormattedText(window, char(theWord), 'center', 'center', theColor);
 DrawFormattedText(window,curWord, 'center', 'center' );
        % Check the keyboard. The person should press the
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            ShowCursor;
            sca;
            return
        elseif keyCode(30)
            response = 1;
            respToBeMade = false;
        elseif keyCode(31)
            response = 2;
            respToBeMade = false;
        elseif keyCode(32)
            response = 3;
            respToBeMade = false;
                    elseif keyCode(33)
            response = 4;
            respToBeMade = false;
                    elseif keyCode(34)
            response = 5;
            respToBeMade = false;
                    elseif keyCode(35)
            response = 6;
            respToBeMade = false;
                    elseif keyCode(36)
            response = 7;
            respToBeMade = false;
                    elseif keyCode(37)
            response = 8;
            respToBeMade = false;
                    elseif keyCode(38)
            response = 9;
            respToBeMade = false;
        end
 
        % Flip to the screen
        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);
    end
    tEnd = GetSecs;
    rt = tEnd - tStart;
 
    % Record the trial data into out data matrix
    respMat(1, trial,curBlock) = curWordNum;
    %respMat(2, trial) = colorNum;
    respMat(2, trial,curBlock) = response;
    respMat(3, trial,curBlock) = rt;
 
end
end 
 
% End of experiment screen. We clear the screen once they have made their
% response
DrawFormattedText(window, 'Experiment finished! \n\n Thank you!! \n\n Press any key to exit',...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
sca;
resp_folder='/Users/brittanyhaynes/Desktop/CLE Data/';
respfile=strcat(resp_folder,SSID{1},'_responseMat_SemFirst.mat');
save(respfile, 'respMat');