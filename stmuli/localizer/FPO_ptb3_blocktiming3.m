function h=FPO_ptb3_blocktiming2(CurSub,OrderNo)

if nargin < 1
    disp('Usage:')
    disp('h=FPO_ptb3_blocktiming2(CurSub,OrderNo)')
    return
end

f = sprintf('FPO_ImageMatFile_%dB.mat',OrderNo);

load(f);

KbCheck(-1);

h=[];
try
%     HideCursor
    
    % Display settings
    screenNumbers=Screen('Screens');
    [w,screenRect] = Screen('OpenWindow',max(screenNumbers)); % get the screen size
    % create textures
    tex(1) = Screen('MakeTexture',w,uint8(255*ones(size(Images{1}))));
    for ii=2:(length(Images)+1)
        tex(ii) = Screen('MakeTexture',w,Images{ii-1});
    end
    
    Priority(MaxPriority(w));
    
    [normBoundsRect, offsetBoundsRect]= Screen('TextBounds', w, 'Getting Screen Refresh Rate', screenRect(3)/2,screenRect(4)/2);
    [newX,newY]=Screen('DrawText', w, 'Getting Screen Refresh Rate', screenRect(3)/2 - normBoundsRect(3)/2,screenRect(4)/2);
    Screen('Flip',w);
    [monitorFlipInterval,nrValidSamples,stddev ]=Screen('GetFlipInterval', w, 25);
    hz = 1/monitorFlipInterval;
    TrialsPerBlock=16;
    BlockLength = 16; %in seconds
    NumOfBlocks=25;
    InitialBaseline = 20;
    EndBaseline = 30;
    
    
    framesImageBlankDuration = floor(hz);
    framesImageDuration = round(0.75*framesImageBlankDuration);
    
    trigKC = KbName('t'); %5%
    quitKC = KbName('q');
    
    
    % put up fixation cross
    fix = [mean([screenRect(1),screenRect(3)]) mean([screenRect(2),screenRect(4)])];
    Screen('DrawTexture', w, tex(1));
    Screen('DrawDots', w, fix, 10 ,[255 128 128],[],1);
    Screen('Flip', w);
    
    
    % Initiate Timing stuff
    h.BlockStarts = 0:BlockLength:(NumOfBlocks*BlockLength);
    h.BlockTiming(:,1) = (0:framesImageBlankDuration/hz:framesImageBlankDuration/hz*(TrialsPerBlock-1)) + InitialBaseline;
    h.BlockTiming(:,2) = h.BlockTiming(:,1) + framesImageDuration/hz ;
    
    h.VBLTimestamp=zeros(length(Images)-1,2);
    h.StimulusOnsetTime=zeros(length(Images)-1,2);
    h.FlipTimestamp=zeros(length(Images)-1,2);
    h.Missed_Beampos=zeros(length(Images)-1,2);
    h.KbCheck=zeros(length(Images)-1,2);
    
    
    
    % check for key press
    [keyIsDown, secs, keyCode] = KbCheck(-1);
    while ~keyIsDown
        [keyIsDown, h.Start, keyCode] = KbCheck(-1);
    end
    
    %create all the offscreen windows and put in the appropriate images
    idx=1;
    for bl = 1:NumOfBlocks
        [keyIsDown, h.KbCheck(idx,1), keyCode, deltaSecs] = KbCheck(-1);
        while ~keyCode(quitKC) && ~keyCode(trigKC) && (GetSecs - h.Start) < (h.BlockStarts(bl) - 1/(2*hz))
            [keyIsDown, h.KbCheck(idx,2), keyCode, deltaSecs] = KbCheck(-1);
            if keyCode(quitKC)
                sca;
                return;
            end
            %WaitSecs(0.004)
        end
        for im = 1:TrialsPerBlock
            
            Screen('DrawTexture', w, tex(idx+1));% [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
            Screen('DrawDots', w, fix, 10 ,[255 128 128],[],1);
            [h.VBLTimestamp(idx,1), h.StimulusOnsetTime(idx,1), h.FlipTimestamp(idx,1), h.Missed_Beampos(idx,1)] = Screen('Flip', w, [h.BlockStarts(bl) + h.BlockTiming(im,1) + h.Start - 1/(2*hz)]);
            Screen('DrawTexture', w, tex(1));% [,sourceRect] [,destinationRect] [,rotationAngle] [, filterMode] [, globalAlpha] [, modulateColor] [, textureShader] [, specialFlags] [, auxParameters]);
            Screen('DrawDots', w, fix, 10 ,[255 128 128],[],1);
            [h.VBLTimestamp(idx,2), h.StimulusOnsetTime(idx,2), h.FlipTimestamp(idx,2), h.Missed_Beampos(idx,2)] = Screen('Flip', w, [h.BlockStarts(bl) + h.BlockTiming(im,2) + h.Start - 1/(2*hz)]);
            % check for quit
            [keyIsDown, h.KbCheck(idx,2), keyCode, deltaSecs] = KbCheck(-1);
            if keyCode(quitKC)
                sca;
                return;
            end
            
            idx=idx+1;
            
        end
        
    end
    WaitSecs(EndBaseline);
    
    h.t =  [h.VBLTimestamp(:,1) h.FlipTimestamp(:,1) h.VBLTimestamp(:,2) h.FlipTimestamp(:,2) h.KbCheck(:,1) h.KbCheck(:,2)] -h.Start;
    sca
    clear Images
    clear t
    save([CurSub '-' num2str(OrderNo)])
    disp([h.BlockStarts(1:end-1)' h.t(1:BlockLength:BlockLength*NumOfBlocks)'])
%     ShowCursor
    return
    
catch
    h=lasterror;
    sca
    clear Images
    clear t
    save([CurSub '-' num2str(OrderNo)])
%     ShowCursor
    return
    
end