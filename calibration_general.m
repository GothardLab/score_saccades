%calibrate the eye data
clear all; close all; clc; %pack

%% Constants
CMWIDTH = 14; %image width in centimeters
CTXWIDTH = 8.8; %image width in cortex units
PIXWIDTH = 300; %image width in pixels
MONKDIST = 57; %distance of monkey's eye from screen
ANGWIDTH = 2*(atand((CMWIDTH/2)/MONKDIST)); %in degrees of visual angle
FIXSPOT = atand(0.2/MONKDIST); %fixinfotion spot in visual angle
FIXWIND = atand(2.05/MONKDIST); %allowed window for fixation in visang
PIX2ANG = ANGWIDTH/PIXWIDTH; 
CTX2ANG = ANGWIDTH/CTXWIDTH; %visual angle per cortex unit
PIX2CTX = CTXWIDTH/PIXWIDTH;
IMGANGWIDTH = 12*CTX2ANG + 300*PIX2ANG;
IMGANGHEIGHT = ANGWIDTH;
ISCANSR = 120;

pplot=1;
stepthru=1;
pfix=0;

[itmFile,itmPath] = uigetfile('*.itm','pick the calibration item file that was used (for example, qtcal.itm) ');
[calibFile,calibPath] = uigetfile('*.smr','pick the spike file that contains calibration (.smr) ');
lowlimit=input('At what time did you start calibration (sec)? ');
uplimit=input('At what time did you end calibration (sec)? ');

cal=calibrateEye([calibPath,calibFile],[itmPath,itmFile],lowlimit,uplimit,1,CTX2ANG);
if ~isdir([calibPath,'matfiles']);
    mkdir([calibPath,'matfiles']);
end
save([calibPath,'\matfiles\',calibFile(1:end-4),'_CALIBRATION_',num2str(lowlimit),'.mat']);