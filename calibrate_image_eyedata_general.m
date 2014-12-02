clear all;
clc;

%CMPRES2CMCTX=11.04/14;  %a constant ratio value to transfer between cortex and presentation units.
[calibFile,calibPath] = uigetfile('*.mat','pick the MATLAB file of the calibration');
load([calibPath,calibFile]);    %load the variables from the file you selected
[infoFile,infoPath]=uigetfile('*.mat','pick the MATLAB file that has the decoded trial information (.mat) ');   %have the user pick the appropriate spike file with the eye data

[eyeFile,eyePath] = uigetfile('*.smr','pick the spike file that has the eyedata for the images (.smr) ');   %have the user pick the appropriate spike file with the eye data
[eyeX,eyeY,time] = downsampleeyes([eyePath,eyeFile]);   %downsample the eyes, a program written by Chris and Robert to input the eye data from Spike
eyeData = [eyeX;eyeY];  %put the eye data in a variable with a different name for convenience
xy = cal.rotmat*[(eyeData(1,:)-cal.intersect(1));(eyeData(2,:)-cal.intersect(2))];  %calibrate the horizontal and vertical eye position, the next 3 lines are taken from Robert and Chris's code.  they use the calibration parameters from the calibraiton matlab file that was loaded
eyeX = xy(1,:)*cal.param(2,1)+cal.param(1,1);
eyeY = xy(2,:)*cal.param(2,2)+cal.param(1,2);
load([infoPath,infoFile]);
%PRES2ANG=PIX2ANG*CMPRES2CMCTX;   %figure out the converstion from presentation pixels to degreees of visual angle
%   PIXELS * (DVAcortex/PIXELS) = DVAcortex;     DVAcortex * (CMpres/CMcortex) = DVApres

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

for i=1:length(trialinfo); %scroll through the movie trials
    if strcmp(trialinfo(i).trialtype,'good') || strcmp(trialinfo(i).trialtype,'imgfail');
        imon=round(trialinfo(i).imgon);
        imoff=round(trialinfo(i).imgoff);
        trialinfo(i).eyexImOn=eyeX(imon:imoff);  %cut teh eye data from one frame to the next and record it in the movietrial structure
        trialinfo(i).eyeyImOn=eyeY(imon:imoff);  %cut teh eye data from one frame to the next and record it in the movietrial structure
    end
end
save([infoPath,infoFile(1:end-4),'_calibrated_image_eye.mat']);


