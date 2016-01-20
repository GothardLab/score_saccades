clear all
clc

newFileStr = 'New file';
reopenStr = 'Reopen a file';

button = questdlg('Do you want to start a new file or reopen a file.','Choose your destiny',newFileStr,reopenStr,newFileStr);

if strcmp(button, newFileStr)



[itmFile,itmPath] = uigetfile('*.txt','pick the text item file (e.g. monkey_movies.txt) '); %have the user pick the appropriate movie itm file
[eyeFile,eyePath] = uigetfile('*.smr','pick the spike file that has the eyedata for the movies (.smr) ');   %have the user pick the appropriate spike file with the eye data

moviesStartS=input('What time did you start showing this itm file (in seconds)?  ');   %get the start time at which the itm file began                                                                               %(important when multiple itm files -- including calibration-- were shown
moviesEndS=input('What time did you end itm file (in seconds)?  ');    %get the time at which we stopped showing the item file






[movietrial]=decode_pres_movie_encode_immov2(fullfile(eyePath, eyeFile), fullfile(itmPath, itmFile), moviesStartS, moviesEndS);





% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% [save_path] = func_decode_pres_images_encode(itmFile,itmPath, eyeFile,eyePath, sTimeITM, eTimeITM);
% 
% [trlPath, trlName, trlExt] = fileparts(save_path);
% 
% trlPath = [trlPath, '\'];
% trlFile = [trlName, trlExt];
% 
% cal_path = func_check_saccade_times_movieimage(trlFile, trlPath, eyeFile, eyePath);
% 
% [scnPath, scnName, scnExt] = fileparts(cal_path);
% 
% scnPath = [scnPath, '\'];
% scnFile = [scnName, scnExt];
% 
% %imgPath = 'E:\dat\img\REMOTE32\';
% %func_check_saccade_times(scnFile,scnPath, imgPath)
% func_new_check_saccade_times_images(save_path, cal_path);
% 
% 
elseif strcmp(button, reopenStr)
%     [sacFile,sacDir] = uigetfile('*SCORING_SACCADES.mat','pick the mat file from your last saccade scoring session'); %have the user pick the appropriate movie itm file
%     sacPath = fullfile(sacDir, sacFile);
%     func_old_check_saccade_times_images(sacPath);
 else
%     
%     helpdlg('How did this get here I am not good with computer','YOU CHOOSE WRONG!')
 end