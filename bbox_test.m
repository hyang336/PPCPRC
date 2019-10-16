%% ask Subject to press with their left pinky, left ring finger, middle finger, etc. all the way to the right pinky, once per finger
clear all
addpath(genpath(pwd));
KbName('UnifyKeyNames');
ver=input('version number:');
[study_stim,test_stim,hand]=version_select(ver);
[id,name] = GetKeyboardIndices;%get the device indices to be used in KbQueue
bboxid=id(find(~cellfun(@isempty,strfind(name,'Current Designs'))));

scan_trig=KbName('5%');
ins_done=KbName('2@');
experimenter_pass=KbName('e');
pausekey=KbName('p');
termkey=KbName('t');

%define key list to only accept response keys (in hand struct)
%and pause key in the KbQueue
klist=zeros(1,256);
p_klist=klist;
klist([hand.r1, hand.r2, hand.r3, hand.r4, hand.r5])=1;
p_klist(pausekey)=1;
  KbQueueCreate(bboxid,klist);%Queue for button boxes and only accept the 5 resp keys and p as input keys in the queue
  KbQueueCreate([],p_klist); %Queue for the key board/expeirmenter control         
  KbQueueStart(bboxid);
  KbQueueStart([]);
            KbQueueFlush(bboxid);
            KbQueueFlush([]);
            count=0;
            ListenChar(2);
            while 1            
            [pressed, firstPress]=KbQueueCheck(bboxid);
               %% get response
                if pressed%if key was pressed do the following
                     firstPress(find(firstPress==0))=NaN; %little trick to get rid of 0s
                     [endtime Index]=sort(firstPress);
                     result(count+1)=Index(1);
                     count=count+1;
                end
                [paused,~]=KbQueueCheck([]);
                if paused
                    disp('pause key pressed');
                end
                if count==5
                    ListenChar();
                    break
                end
            end
