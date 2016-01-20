clear all;
clc;
PRESWIDTH=800 %the width of the monitor used during calibration (800x600 typically);
PRESHEIGHT=600 %the height of the monitor used during calibration (800x600 typically);
VOLTAGESCALE=4.0 %the number of volts (out of 5) to distribute across the monitor (determned in presentation timing file);
PRESCAL2PIX_X=(PRESWIDTH/2)/VOLTAGESCALE
PRESCAL2PIX_Y=(PRESHEIGHT/2)/VOLTAGESCALE
%MONITORWIDTH_CM = 37.8; %width of the monitor in cm
%MONITORHEIGHT_CM = 30; %height of the monitor in cm
MONITORWIDTH_CM = 37.8*800/800; %width of the monitor in cm
MONITORHEIGHT_CM = 30*600/600; %height of the monitor in cm
MONKDIST = 57; %distance of monkey's eye from screen
ANGWIDTH_X = 2*(atand((MONITORWIDTH_CM/2)/MONKDIST)); %WIDTH OF FIXSPOT IN DVA
ANGWIDTH_Y = 2*(atand((MONITORHEIGHT_CM/2)/MONKDIST)); %WIDTH OF FIXSPOT IN DVA
PIX2ANG_X = ANGWIDTH_X/PRESWIDTH; %conversion factor for taking pixels to DVA
PIX2ANG_Y = ANGWIDTH_Y/PRESHEIGHT; %conversion factor for taking pixels to DVA

[itmFile,itmPath] = uigetfile('*.txt','pick the text file that has the movie names (e.g. monkey_movies.txt) '); %have the user pick the appropriate movie itm file
[eyeFile,eyePath] = uigetfile('*.smr','pick the spike file that has the eyedata for the movies (.smr) ');   %have the user pick the appropriate spike file with the eye data
moviesStart=input('When did you start showing the movies (in seconds)?  '); %ask the user to type in the start time of this part of the file
moviesEnd=input('When did you stop showing the movies (in seconds)?  ');    %ask the user to type in the end time of this part of the file
moviedir=itmPath; %the directory of where to look for the movies.  Make sure that each movie that you want to

[movietrial]=decode_pres_movie_encode_immov2([eyePath,eyeFile], [itmPath,itmFile],moviesStart, moviesEnd);    %run a sepearate function to decode the channel 32.  to read about this function, open it in a seperate script-editing window
[eyeX,eyeY,time] = downsampleeyes([eyePath,eyeFile]);   %downsample the eyes, a program written by Chris and Robert to input the eye data from Spike
eyeX = eyeX*PRESCAL2PIX_X*PIX2ANG_X;
eyeY = eyeY*PRESCAL2PIX_Y*PIX2ANG_Y;


%upsample eye data to 1000Hz
desiredx=[time(1):1:time(end)]; %get the start and end times of the eye data
eyeX1=zeros(1,length(desiredx));    %make a vector that is the length of the datafile, sampled at 1000Hz
eyeY1=zeros(1,length(desiredx));    %make a vector that is the length of the datafile, sampled at 1000Hz
eyeX1=interp1(time,eyeX,desiredx);  %interpolate the eye data sampled at 250Hz (or whatever it was) so that it is now sampled at 1000Hz
eyeY1=interp1(time,eyeY,desiredx);  %interpolate the eye data sampled at 250Hz (or whatever it was) so that it is now sampled at 1000Hz
eyeX = eyeX1; eyeY = eyeY1;         %reassign the 1000Hz sampled data to the old variable names
clear eyeX1 eyeY1;      %clear the temporary variables we made
ends=[];    %assign NaNs to the extra values at the beginning and end of the interpolation (next 4 lines)
ends(end+1) = time(end);
eyeY(end+1:max(ends))=NaN;
eyeY=eyeY;
eyeX=eyeX;
eyeX(end+1:max(ends))=NaN;

for i=1:length(movietrial); %scroll through the movie trials
    for j=1:length(movietrial(i).frametime)-1;  %for each movie frame (except the last)...
        clear frame1 frame2;   %clear these temporary variables so we don't get confused
        frame1=round(movietrial(i).frametime(j)*1000);  %get the time that one frame was shown
        frame2=round(movietrial(i).frametime(j+1)*1000);    %get the tim that the next fram was shown
        movietrial(i).eyex{j}=eyeX(frame1:frame2);  %cut teh eye data from one frame to the next and record it in the movietrial structure
        movietrial(i).eyey{j}=eyeY(frame1:frame2);  %cut teh eye data from one frame to the next and record it in the movietrial structure
    end
    
    endframe=round(movietrial(i).frametime(length(movietrial(i).frametime))*1000);  %the last frame will be equal to the length of the frames shown for this movie
    
    bc=sort([movietrial(i).frametime(1):-(1/30):movietrial(i).frametime(1)-1]);
    ad=sort([endframe/1000+0.033:(1/30):endframe/1000+0.033+1]);
    movietrial(i).preframetime=bc;
    movietrial(i).postframetime=ad;
    
    for j=1:length(movietrial(i).preframetime)-1;  %for each movie frame (except the last)...
        clear frame1 frame2;   %clear these temporary variables so we don't get confused
        frame1=round(movietrial(i).preframetime(j)*1000);  %get the time that one frame was shown
        frame2=round(movietrial(i).preframetime(j+1)*1000);    %get the tim that the next fram was shown
        movietrial(i).preeyex{j}=eyeX(frame1:frame2);  %cut teh eye data from one frame to the next and record it in the movietrial structure
        movietrial(i).preeyey{j}=eyeY(frame1:frame2);  %cut teh eye data from one frame to the next and record it in the movietrial structure
    end
    endpreframe=round(movietrial(i).preframetime(length(movietrial(i).preframetime))*1000);  %the last frame will be equal to the length of the frames shown for this movie
    movietrial(i).preeyex{length(movietrial(i).preframetime)}=eyeX(endpreframe:endpreframe+33); %since the movie is shown at 30 Hz, the last frame turned off 33ms later, record the eye data durign this time period
    movietrial(i).preeyey{length(movietrial(i).preframetime)}=eyeY(endpreframe:endpreframe+33); %since the movie is shown at 30 Hz, the last frame turned off 33ms later, record the eye data durign this time period
    
    for j=1:length(movietrial(i).postframetime)-1;  %for each movie frame (except the last)...
        clear frame1 frame2;   %clear these temporary variables so we don't get confused
        frame1=round(movietrial(i).postframetime(j)*1000);  %get the time that one frame was shown
        frame2=round(movietrial(i).postframetime(j+1)*1000);    %get the tim that the next fram was shown
        movietrial(i).posteyex{j}=eyeX(frame1:frame2);  %cut teh eye data from one frame to the next and record it in the movietrial structure
        movietrial(i).posteyey{j}=eyeY(frame1:frame2);  %cut teh eye data from one frame to the next and record it in the movietrial structure
    end
    endpostframe=round(movietrial(i).postframetime(length(movietrial(i).postframetime))*1000);  %the last frame will be equal to the length of the frames shown for this movie
    movietrial(i).posteyex{length(movietrial(i).postframetime)}=eyeX(endpostframe:endpostframe+33); %since the movie is shown at 30 Hz, the last frame turned off 33ms later, record the eye data durign this time period
    movietrial(i).posteyey{length(movietrial(i).postframetime)}=eyeY(endpostframe:endpostframe+33); %since the movie is shown at 30 Hz, the last frame turned off 33ms later, record the eye data durign this time period
    
    movietrial(i).eyex{length(movietrial(i).frametime)}=eyeX(endframe:endframe+33); %since the movie is shown at 30 Hz, the last frame turned off 33ms later, record the eye data durign this time period
    movietrial(i).eyey{length(movietrial(i).frametime)}=eyeY(endframe:endframe+33); %since the movie is shown at 30 Hz, the last frame turned off 33ms later, record the eye data durign this time period
    movietrial(i).movieregions=20*ones(length(movietrial(i).frametime),1); %make a vector that will record the movie region that the monkey is looking at during each frame
end

movienum=1; %set the initial movie number to 1
frame_num=1;    %set the initial frame number to 1
if ~isdir([eyePath,'matfiles\']);
    mkdir([eyePath,'matfiles\']);
end
%save([eyePath,'matfiles\',eyeFile(1:end-4),'_calibrated_movie_eye_','.mat']);

save([eyePath,'matfiles\',eyeFile(1:end-4),'_calibrated_movie_eye_',num2str(moviesStart),'-',num2str(moviesEnd),'.mat']);
disp(length(movietrial));