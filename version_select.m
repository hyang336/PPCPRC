%match a single version number to a set of parameters for counterbalancing 
function [study_stim,test_stim,hand]=version_select(version)
%% load look-up table
 version_str=load('version.mat');%this should be able to find the file as long as it is added to Matlab path
 version_str=version_str.version;%get rid of the useless top layer

%% specify hand mapping, block order, and stimulu set variable
 % test phase only has two block orders, which are nested with study block order
 stimulus_set=version_str(version).set_cb;
 block_order=version_str(version).run_cb;
 hand_map=version_str(version).hand_cb;
%% build and return experiment settings based on variable values
 switch stimulus_set
     case 1
         tab='v1';
     case 2
         tab='v2';
 end
 
 switch block_order
     case 'inc'
        [~,~,study_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'study_jitter'), 'A2:C451');
        [~,~,test_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'test_jitter'), 'A2:D181');
     case 'dec'
        [~,~,study_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'study_jitter'), 'E2:G451');
        [~,~,test_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'test_jitter'), 'E2:H181');         
     case 'odd_first'
        [~,~,study_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'study_jitter'), 'I2:K451');
        [~,~,test_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'test_jitter'), 'A2:D181');          
     case 'even_first'
        [~,~,study_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'study_jitter'), 'M2:O451');
        [~,~,test_stim]=xlsread('genetic_180_rand_jitter_run45.xlsx',strcat(tab,'test_jitter'), 'E2:H181');          
 end
 
 switch hand_map
     case 'L5animate'
           hand.r5=KbName('8*');
           hand.r4=KbName('7&');
           hand.r3=KbName('6^');
           hand.r2=KbName('1!');
           hand.r1=KbName('2@');
           hand.animate=KbName('6^');
           hand.inanimate=KbName('1!');
           hand.study_scale='animate         inanimate';
           hand.test_scale='5   4   3   2   1';
     case 'R5animate'
           hand.r5=KbName('3#');
           hand.r4=KbName('2@');
           hand.r3=KbName('1!');
           hand.r2=KbName('6^');
           hand.r1=KbName('7&');
           hand.animate=KbName('1!');
           hand.inanimate=KbName('6^');
           hand.study_scale='inanimate         animate';
           hand.test_scale='1   2   3   4   5';
 end

end