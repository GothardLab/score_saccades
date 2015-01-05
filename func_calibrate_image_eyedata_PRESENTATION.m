function cal_path = func_calibrate_image_eyedata_PRESENTATION(trlFile, trlPath, eyeFile2, eyePath2)
PRESWIDTH=1024; %the width of the monitor used during calibration (800x600 typically);
PRESHEIGHT=768; %the height of the monitor used during calibration (800x600 typically);
VOLTAGESCALE=4.0; %the number of volts (out of 5) to distribute across the monitor (determned in presentation timing file);
PRESCAL2PIX_X=(PRESWIDTH/2)/VOLTAGESCALE;
PRESCAL2PIX_Y=(PRESHEIGHT/2)/VOLTAGESCALE;

fprintf('Calibrating based off a %d by %d monitor with a voltage scale of %d', PRESWIDTH, PRESHEIGHT, VOLTAGESCALE);

%MONITORWIDTH_CM = 37.8; %width of the monitor in cm
%MONITORHEIGHT_CM = 30; %height of the monitor in cm
MONITORWIDTH_CM = 37.8*1024/1024; %width of the monitor in cm
MONITORHEIGHT_CM = 30*768/768; %height of the monitor in cm
MONKDIST = 57; %distance of monkey's eye from screen
ANGWIDTH_X = 2*(atand((MONITORWIDTH_CM/2)/MONKDIST)); %WIDTH OF FIXSPOT IN DVA
ANGWIDTH_Y = 2*(atand((MONITORHEIGHT_CM/2)/MONKDIST)); %WIDTH OF FIXSPOT IN DVA
PIX2ANG_X = ANGWIDTH_X/PRESWIDTH; %conversion factor for taking pixels to DVA
PIX2ANG_Y = ANGWIDTH_Y/PRESHEIGHT; %conversion factor for taking pixels to DVA

%[itmFile,itmPath] = uigetfile('*.mat','pick the mat file that has the movie names (e.g. monkey_movies.txt) '); %have the user pick the appropriate movie itm file
%[eyeFile2,eyePath2] = uigetfile('*.smr','pick the spike file that has the eyedata for the movies (.smr) ');   %have the user pick the appropriate spike file with the eye data
%[eyeX,eyeY,time] = downsampleeyes([eyePath2,eyeFile2]);   %downsample the eyes, a program written by Chris and Robert to input the eye data from Spike
[eyeX,eyeY] = geteyes([eyePath2,eyeFile2]);
eyeX = eyeX*PRESCAL2PIX_X*PIX2ANG_X;
eyeY = eyeY*PRESCAL2PIX_Y*PIX2ANG_Y;

fprintf('.');


%upsample eye data to 1000Hz
% desiredx=[time(1):1:time(end)]; %get the start and end times of the eye data
% eyeX1=zeros(1,length(desiredx));    %make a vector that is the length of the datafile, sampled at 1000Hz
% eyeY1=zeros(1,length(desiredx));    %make a vector that is the length of the datafile, sampled at 1000Hz
% eyeX1=interp1(time,eyeX,desiredx);  %interpolate the eye data sampled at 250Hz (or whatever it was) so that it is now sampled at 1000Hz
% eyeY1=interp1(time,eyeY,desiredx);  %interpolate the eye data sampled at 250Hz (or whatever it was) so that it is now sampled at 1000Hz
% eyeX = eyeX1; eyeY = eyeY1;         %reassign the 1000Hz sampled data to the old variable names
% clear eyeX1 eyeY1;      %clear the temporary variables we made
% ends=[];    %assign NaNs to the extra values at the beginning and end of the interpolation (next 4 lines)
% ends(end+1) = time(end);
% eyeY(end+1:max(ends))=NaN;
% eyeY=eyeY;
% eyeX=eyeX;
% eyeX(end+1:max(ends))=NaN;
load([trlPath,trlFile]);
for i=1:length(trialinfo); %scroll through the movie trials
    if strcmp(trialinfo(i).trialtype,'good');
        trialinfo(i).eyexImOn=eyeX(trialinfo(i).imgon:trialinfo(i).imgon+4000);
        trialinfo(i).eyeyImOn=eyeY(trialinfo(i).imgon:trialinfo(i).imgon+4000);
    end
end
fprintf('.');

if ~isdir([eyePath2,'matfiles\']);
    mkdir([eyePath2,'matfiles\']);
end
%save([eyePath,'matfiles\',eyeFile(1:end-4),'_calibrated_movie_eye_','.mat']);

cal_path = [eyePath2,'matfiles\',eyeFile2(1:end-4),'_calibrated_eye.mat'];

save(cal_path);

fprintf('.\n');


