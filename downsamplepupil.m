function [pupil,time] = downsamplepupil(fpath,pupchan)
%test stuff
% clear all;close all;pack;clc;

% [File,Path] = uigetfile;    %get a raw itm file
fid=fopen(fpath);
[ch10,ch10_info]=SONGetADCChannel(fid,pupchan);%Y direction eye info
ch10=single(SONADCToDouble(ch10,ch10_info));
% pack;
%go back to 120Hz...about..was 500Hz=2ms or ch8_info.sampleinterval
realpup=[ch10_info.start:ch10_info.sampleinterval:ch10_info.stop];
desiredpup=[ch10_info.start:(1/120):ch10_info.stop];
ch10a=interp1(realpup,ch10,desiredpup);
clear realpup  ch10

ch10=ch10a; clear ch9a ch8a;
timePup(1:length(ch10))=desiredpup(1:length(ch10));
pupil=ch10;
timePup(1)=0;
time=round(timePup*1000);
clear ch8 timeY timeX ch8_info ch9 desiredx desiredy ch8a DATA File Path fid Allheader ChanList ch9_info ch9_info i info name number scr scr_info