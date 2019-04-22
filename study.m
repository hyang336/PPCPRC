%handles study phase stimulus presentation and data collection, has built-in error
%handling. Note that depending on where the error happens, the trial when the error occurs
%may or may not be presented to the participants, for now this detail is not treated
%differently.
function [resp_sofar,lastrun,lasttrial] = study(PTBwindow,stimuli,run, trial)
    data=cell(450,7);%initialize data output; headers are handled in the main procedure script
    a=0;
    try
    for i=run:10
        if i==run % for the first run, continue from the next trial
            for j=trial:45 
            a=a+1;   
            end            
        else
            for j=1:45 %for all followin runs, start from the first trial
            a=a+1

            
            end
        end
        %wait for experimenter input to continue if no error has occured
        
    end       
        lastrun=i;
        lasttrial=j;
        %need to delete empty rows to make it easy to concatenate in case of error
        resp_sofar=data;
    catch
        %need to copy it here as well otherwise if error occurred in loops these variables
        %won't get returned
        lastrun=i;
        lasttrial=j;
        %need to delete empty rows to make it easy to concatenate in case of error
        resp_sofar=data;
        
        Screen('CloseAll');
        disp('Study phase error, check lastrun and lasttrial');
    end
end