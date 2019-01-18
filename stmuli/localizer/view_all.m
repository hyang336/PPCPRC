% for i=1:400
%     figure()
%     imshow(Images{i})
%     saveas(gcf,strcat('C:\Users\haozi\Desktop\PhD\fMRI_PrC-PPC\stmuli\localizer\figs_2\figure-',num2str(i),'.png'));
%     close all
% end

%1 and 1B has the same stimuli, 2 and 2B has the same stimuli, according to visual
%inspection

%check if any images are duplicate across sets (1B vs 2B)
stim_1b=load('FPO_ImageMatFile_1B.mat');
stim_2b=load('FPO_ImageMatFile_2B.mat');

%400 by 400 logical output, rows are 1b, columns are 2b
logic_1b2b=cell(400);
for i=1:400
   for j=1:400
      logic_1b2b{i,j}=isequal(stim_1b.Images{i},stim_2b.Images{j});
   end
end

matrix=cell2mat(logic_1b2b);
imshow(matrix);
