%handles study phase stimulus presentation and data collection, has built-in error
%handling. Note that depending on where the error happens, the trial when the error occurs
%may or may not be presented to the participants, for now this detail is not treated
%differently.
function [resp_sofar,lastrun,lasttrial] = study(PTBwindow,stimuli,hand,run, trial)
    output=cell(450,7);%initialize data output; headers are handled in the main procedure script
    a=0;
    try
    for i=run:10
        if i==1 %different instruction for the first run
            
        else
            
        end
        if i==run % for the starting run, continue from the specified trial 
            for j=trial:45 
            
                
            end            
        else
            for j=1:45 %for all followin runs, start from the first trial
            

            
            end
        end
        %wait for experimenter input to continue if no error has occured
        
    end       
        lastrun=i;
        lasttrial=j;
        %need to delete empty rows to make it easy to concatenate in case of error
        resp_sofar=output;
    catch
        %need to copy it here as well otherwise if error occurred in loops these variables
        %won't get returned
        lastrun=i;
        lasttrial=j;
        %need to delete empty rows to make it easy to concatenate in case of error
        resp_sofar=output;
        
        Screen('CloseAll');
        disp('Study phase error, check lastrun and lasttrial');
    end
end