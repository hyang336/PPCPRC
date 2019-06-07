function BIDS_event(pathdata,SSID,data)
    scandata=data;%copy the unprocessed data just in case
    %find the onset columns
    [headerow,expcol]=find(strcmp(scandata,'ExpStartTime'));
    %find the task columns
    [~,taskcol]=find(strcmp(scandata,'task'));
    %find the run columns
    [~,runcol]=find(strcmp(scandata,'Run'));
    
    %*********assuming there is not empty cells in the
    %ExpStartTime column************
    taskcell=scandata(headerow+1:end,taskcol);
    [p,IP,~]=unique(taskcell(~cellfun(@isempty,taskcell)));%unique task
    
    scand=cell(1);
    trow=cell(1);
    rrow=cell(1);
    scand_break=cell(1,1);
    for i=1:length(p)%cut the data according to task
       [trow{i},~]=find(strcmp(scandata(:,taskcol),p{i}));
       scand{i}=scandata(trow{i},:);
       %get unique runs in each task
       expcell=cell2mat(scand{i}(:,expcol));
       [C,IA,IC]=unique(expcell);
       %cut the data according to runs in each task
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