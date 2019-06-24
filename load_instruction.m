function ins=load_instruction(phase,block,handmapping)
ins=cell(2);%maximum 2 pages
%% study phase, one page
if strcmp(phase,'study')==1  
    if block==1
        switch handmapping
            case 'L5animate'
                fd_p1 = fopen('study_ins_L5animates.m');
            case 'R5animate'
                fd_p1 = fopen('study_ins_R5animates.m');
        end
        if fd_p1==-1
            error('Could not open instruction files.');
        end

        page1 = '';
% % % % %         page2 = '';
        while ~feof(fd_p1)%read from the first line till the last line
            tline = fgets(fd_p1);
            page1=[page1 tline];
        end
% % % % %         %skip the first line
% % % % %          for k=1:1
% % % % %             fgets(fd); 
% % % % %          end
% % % % %         lcount = 2;%starting line
% % % % %         tl=fgets(fd);
% % % % %         while lcount <= 13%ending line
% % % % %             page1 = [page1 tl]; %#ok<*AGROW>
% % % % %             tl = fgets(fd);
% % % % %             lcount = lcount + 1;
% % % % %         end

% % % % %         lcount2 = 14;%page2 start
% % % % %         tl2=fgets(fd);
% % % % %         while lcount2 <= 26%ending line
% % % % %             page2 = [page2 tl2]; %#ok<*AGROW>
% % % % %             tl2 = fgets(fd);
% % % % %             lcount2 = lcount2 + 1;
% % % % %         end

        fclose(fd_p1);
        page1 = [page1 newline];
% % % % %         page2 = [page2 newline];

        % Get rid of '% ' symbols at the start of each line:
        page1 = strrep(page1, '% ', '');
        page1 = strrep(page1, '%', '');
% % % % %         page2 = strrep(page2, '% ', '');
% % % % %         page2 = strrep(page2, '%', '');
        
        ins{1}=page1;
% % % % %         ins{2}=page2;
      else
        ins{1}=strcat('Run', num2str(block),'\n Press with your right middle finger to begin');  
    end

    %% test phase, two pages
elseif strcmp(phase,'test')==1
    if block==1
        switch handmapping
            case 'L5animate'
                fd_p1 = fopen('test_ins_L5animates_p1.m');
                fd_p2 = fopen('test_ins_L5animates_p2.m');
            case 'R5animate'
                fd_p1 = fopen('test_ins_R5animates_p1.m');
                fd_p2 = fopen('test_ins_R5animates_p2.m');
        end        
        if fd_p1==-1||fd_p2==-1
            error('Could not open instruction files.');
        end

        page1 = '';
        page2 = '';
        
        %read page 1
        while ~feof(fd_p1)%last line
            tline = fgets(fd_p1);
            page1 = [page1 tline]; 
            
        end
        fclose(fd_p1);
        
        %read page 2
        while ~feof(fd_p2)%last line
            tline = fgets(fd_p2);
            page2 = [page2 tline]; 
            
        end
        fclose(fd_p2);
        
        page1 = [page1 newline];
        page2 = [page2 newline];

        % Get rid of '% ' symbols at the start of each line:
        page1 = strrep(page1, '% ', '');
        page1 = strrep(page1, '%', '');
        page2 = strrep(page2, '% ', '');
        page2 = strrep(page2, '%', '');
        
        ins{1}=page1;
        ins{2}=page2;        
    else
        ins{1}=strcat('Run', num2str(block),'\n Press with your right middle finger to begin');  
    end
    
%% key practice, 1 page and only 1 run, so "block" can equal any value
elseif strcmp(phase,'key_prac')==1
        switch handmapping
            case 'L5animate'
                fd_p1 = fopen('keyprac_ins_L5animates.m');
            case 'R5animate'
                fd_p1 = fopen('keyprac_ins_R5animates.m');
        end
        if fd_p1==-1
            error('Could not open instruction files.');
        end

        page1 = '';

        while ~feof(fd_p1)%read from the first line till the last line
            tline = fgets(fd_p1);
            page1=[page1 tline];
        end

        fclose(fd_p1);
        page1 = [page1 newline];

        % Get rid of '% ' symbols at the start of each line:
        page1 = strrep(page1, '% ', '');
        page1 = strrep(page1, '%', '');

        ins{1}=page1;
        
%% post-scan lifetime
elseif strcmp(phase,'post_scan')==1
        switch handmapping
            case 'L5animate'
                fd_p1 = fopen('postscan_ins_L5animates.m');
            case 'R5animate'
                fd_p1 = fopen('postscan_ins_R5animates.m');
        end
        if fd_p1==-1
            error('Could not open instruction files.');
        end

        page1 = '';

        while ~feof(fd_p1)%read from the first line till the last line
            tline = fgets(fd_p1);
            page1=[page1 tline];
        end

        fclose(fd_p1);
        page1 = [page1 newline];

        % Get rid of '% ' symbols at the start of each line:
        page1 = strrep(page1, '% ', '');
        page1 = strrep(page1, '%', '');

        ins{1}=page1;
end 
