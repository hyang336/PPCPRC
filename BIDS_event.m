function BIDS_event(pathdata,SSID,data)
    scandata=data;%copy the unprocessed data just in case
    scandata{1,size(scandata,2)+1}='phase';%add a phase column so that test phase doesnt produce duplicated files
    %find the onset columns
    [headerow,expcol]=find(strcmp(scandata,'ExpStartTime'));
    %find the task columns
    [~,taskcol]=find(strcmp(scandata,'task'));
    %fill in the phase column according to tasks
    [studyrow,~]=find(strcmp(scandata(:,taskcol),'animacy'));
    [testrow,~]=find(strcmp(scandata(:,taskcol),'lifetime')|strcmp(scandata(:,taskcol),'recent'));
    scandata(studyrow,end)={'study'};
    scandata(testrow,end)={'test'};
    %find the run columns
    [~,runcol]=find(strcmp(scandata,'Run'));
    
    %*********assuming there is not empty cells in the
    %ExpStartTime column************
    phasecell=scandata(headerow+1:end,end);
    [p,IP,~]=unique(phasecell(~cellfun(@isempty,phasecell)));%unique task
    
    scand=cell(1);
    trow=cell(1);
    rrow=cell(1);
    scand_break=cell(1,1);
    for i=1:length(p)%cut the data according to phase
       [trow{i},~]=find(strcmp(scandata(:,end),p{i}));
       scand{i}=scandata(trow{i},:);
       %get unique runs in each phase
       expcell=cell2mat(scand{i}(:,expcol));
       [C,IA,IC]=unique(expcell);
       %cut the data according to runs in each phase
       for j=1:length(C)
            tempcell=cellfun(@(x) isequal(x,C(j)),scandata(:,expcol));%isequal() gives logic rather than cell array
            [rrow{j},~]=find(tempcell);
            scand_break{j,i}=scandata(rrow{j},:);
            scand_break{j,i}(:,runcol)={j};
            %write to separate spreadsheets
            xlswrite(strcat(pathdata,'/',SSID,'/',SSID,'_task-',p{i},'_run-',num2str(j),'_data.xlsx'),vertcat(scandata(headerow,:),scand_break{j,i}));
       end
    end
end