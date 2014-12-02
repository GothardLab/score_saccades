%calibrate the eye data
clear all; close all; clc; %pack

%% Constants
PRESWIDTH=800 %the width of the monitor used during calibration (800x600 typically);
PRESHEIGHT=600 %the height of the monitor used during calibration (800x600 typically);
VOLTAGESCALE=4.0 %the number of volts (out of 5) to distribute across the monitor (determned in presentation timing file);
PRESCAL2PIX_X=(PRESWIDTH/2)/VOLTAGESCALE
PRESCAL2PIX_Y=(PRESHEIGHT/2)/VOLTAGESCALE
MONITORWIDTH_CM = 37.8; %width of the monitor in cm
MONITORHEIGHT_CM = 30; %height of the monitor in cm
MONKDIST = 57; %distance of monkey's eye from screen
ANGWIDTH_X = 2*(atand((MONITORWIDTH_CM/2)/MONKDIST)); %WIDTH OF FIXSPOT IN DVA
ANGWIDTH_Y = 2*(atand((MONITORHEIGHT_CM/2)/MONKDIST)); %WIDTH OF FIXSPOT IN DVA

PIX2ANG_X = ANGWIDTH_X/PRESWIDTH; %conversion factor for taking pixels to DVA
PIX2ANG_Y = ANGWIDTH_Y/PRESHEIGHT; %conversion factor for taking pixels to DVA

[itmFile,itmPath] = uigetfile('*.txt','pick the text file that has the positions of the calibration fixspots (for example, prescal.txt) ');
[calibFile,calibPath] = uigetfile('*.smr','pick the spike file that contains calibration (.smr) ');


lowlimit=input('At what time did you start calibration (sec)? ');
uplimit=input('At what time did you end calibration (sec)? ');

[cal.x,cal.y,time] = downsampleeyes([calibPath,calibFile]);
desiredx=[time(1):1:time(end)]; %get the start and end times of the eye data
eyeX1=zeros(1,length(desiredx));    %make a vector that is the length of the datafile, sampled at 1000Hz
eyeY1=zeros(1,length(desiredx));    %make a vector that is the length of the datafile, sampled at 1000Hz
eyeX1=interp1(time,cal.x,desiredx);  %interpolate the eye data sampled at 250Hz (or whatever it was) so that it is now sampled at 1000Hz
eyeY1=interp1(time,cal.y,desiredx);  %interpolate the eye data sampled at 250Hz (or whatever it was) so that it is now sampled at 1000Hz
eyeX = eyeX1; eyeY = eyeY1;         %reassign the 1000Hz sampled data to the old variable names
clear eyeX1 eyeY1;      %clear the temporary variables we made
ends=[];    %assign NaNs to the extra values at the beginning and end of the interpolation (next 4 lines)
ends(end+1) = time(end);
eyeY(end+1:max(ends))=NaN;
eyeY=eyeY;
eyeX=eyeX;
eyeX(end+1:max(ends))=NaN;


sr = (1/mean(diff(time)))*1000; %sampling rate for eye data
timestart = time(1);

fid=fopen([calibPath,calibFile]);    %open the file with chan 32
[Allheader]=SONFileHeader(fid); %get the headers of the channels in this spike file
[ChanList2]=SONChanList(fid);   %get a list of the channel numbers

%scroll through the channel list to find channel 32
for i=1:length(ChanList2) %excludes blank keyboard channel 31%
    number=ChanList2(1,i).number;   %get the number of the current channel
    name=[ChanList2(1,i).title];    %get the name of the current channel
    if number==32;  %if the channel number is 32
        info=[ChanList2(1,i).title,'_info'];    %get information (e.g. sample rate) for chan 32
        [Chan32.data,Chan32.info]=SONGetMarkerChannel(fid, number); %get the times of the chan 32 markers
        Chan32.data.markers(:,2:4)=[];  %only take the first column of markers (the rest are just superfluos zeros)
    end
end

allmarks=Chan32.data.markers;  %assign the encode maker numbers to a new variable
alltimes=Chan32.data.timings;   %assign the encode marker times to a new variable
allmarks(find(alltimes<lowlimit | alltimes>uplimit))=[];   %delete any markers that didn't occur during the movie presentation period
alltimes(find(alltimes<lowlimit | alltimes>uplimit))=[];   %delete any marker times that didn't occur during the movie presentation period
if allmarks(1)==0;
    allmarks(1)=[];
    alltimes(1)=[];
end
c=0;    %set a counter variable "c" to a value zero
%scroll through all the markers and take every other one to get the lobytes
for i=1:2:length(allmarks);
    c=c+1;  %incremetn the counter "c"
    lob(c)=allmarks(i); %a vector with the lobyte values
    marktimes(c)=alltimes(i);   %set the event times to the times that the lobytes were sent, since these are sent first
end

c=0;    %reset the counter variable "c" to a value zero
%scroll through all the markers and take every other one to get the hibytes
for i=2:2:length(allmarks);
    c=c+1;  %incremetn the counter "c"
    hib(c)=allmarks(i); %a vector with the hibyte values
end

%scroll through all the lobyte values and combine them with the hibyte
%values to get the entire decimal value
for i=1:length(lob);
    hiblob(i)=double(lob(i))+(double(hib(i))*256);
end
marktimes(find(hiblob==0))=[];
hiblob(find(hiblob==0))=[];

goodfixes=findvec([36 3],hiblob);

for j=1:length(goodfixes);
    allgood(j).cndnum=hiblob(goodfixes(j)-2)-1000;
    allgood(j).fixachieve=round(1000*marktimes(goodfixes(j)-1));
end


fid=fopen([itmPath,itmFile],'r'); %get an index so MATLAB knows where to find the itmfile
aline = fgetl(fid); %get the firstline of the itmfile
xind=strfind(aline, 'fixX|');  %find the position of the moviename titlebar, since the movienames are aligned beneath it, this will allow us to find the movie names
yind=strfind(aline, 'fixY|');  %find the position of the moviename titlebar, since the movienames are aligned beneath it, this will allow us to find the movie names

c=0;     %set a counter variable "c" to a value zero
while ~feof(fid)    %as long as there are no lines left to read in from the itm file...
    c=c+1;  %increment the counter variable "c"
    aline = fgetl(fid); %read in the next line from the itm file
    fixspot(str2num(aline(1:2))).xposPIX=str2num(aline(xind:xind+3));
    fixspot(str2num(aline(1:2))).yposPIX=str2num(aline(yind:yind+3));
    fixspot(str2num(aline(1:2))).xposDVA=fixspot(str2num(aline(1:2))).xposPIX*PIX2ANG_X;
    fixspot(str2num(aline(1:2))).yposDVA= fixspot(str2num(aline(1:2))).yposPIX*PIX2ANG_Y;
end

for i=1:length(allgood);
    allgood(i).fixXposPIX= fixspot(allgood(i).cndnum).xposPIX;
    allgood(i).fixYposPIX= fixspot(allgood(i).cndnum).yposPIX;
      allgood(i).fixXposDVA= fixspot(allgood(i).cndnum).xposDVA;
    allgood(i).fixYposDVA= fixspot(allgood(i).cndnum).yposDVA;
    
    allgood(i).eyeX_volt=eyeX(allgood(i).fixachieve+50:allgood(i).fixachieve+100);
    allgood(i).eyeY_volt=eyeY(allgood(i).fixachieve+50:allgood(i).fixachieve+100);
      allgood(i).eyeX_PIX= allgood(i).eyeX_volt*PRESCAL2PIX_X;
    allgood(i).eyeY_PIX= allgood(i).eyeY_volt*PRESCAL2PIX_Y;
      allgood(i).eyeX_DVA= allgood(i).eyeX_PIX*PIX2ANG_X;
    allgood(i).eyeY_DVA= allgood(i).eyeY_PIX*PIX2ANG_Y;
end


% 
% ox=[]; oy=[];
% for i=1:length(allgood);
%     if allgood(i).cndnum==1;
%         ox=[ox,allgood(i).eyeX];
%         oy=[oy,allgood(i).eyeY];
%     end
% end
for i=1:length(allgood);
    % if allgood(i).cndnum==1;
    plot(( allgood(i).eyeX_DVA),( allgood(i).eyeY_DVA),'*k');
        hold on;
    plot(allgood(i).fixXposDVA,allgood(i).fixYposDVA,'ob');
%  vline([-150 -100 100 150 0],'-r');
%  hline([-150 -100 100 150 0],'-r');
    %pause;
    axis([(-PRESWIDTH/2)*PIX2ANG_X (PRESWIDTH/2)*PIX2ANG_X -(PRESHEIGHT/2)*PIX2ANG_Y (PRESHEIGHT/2)*PIX2ANG_Y]);
   % end
end





cal=calibrateEye([calibPath,calibFile],[itmPath,itmFile],lowlimit,uplimit,1,CTX2ANG);
if ~isdir([calibPath,'matfiles']);
    mkdir([calibPath,'matfiles']);
end
save([calibPath,'\matfiles\',calibFile(1:end-4),'_CALIBRATION_',num2str(lowlimit),'.mat']);