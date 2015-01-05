function [eyeX,eyeY] = geteyes(fpath)

fid=fopen(fpath);
[ch8,ch8_info]=SONGetADCChannel(fid,8);%X direction eye info  
[ch8]=single(SONADCToDouble(ch8,ch8_info));
[ch9,ch9_info]=SONGetADCChannel(fid,9);%Y direction eye info
ch9=single(SONADCToDouble(ch9,ch9_info));

%note to future phil, it seems that chris wrote this to resample to the
%orginal eye tracker fs and then later on clayton resamples to the orginal
%1000hz, idk what to do about this but it's a job for another day, perhaps
%return the orginal channge if it matches 1000hz sampling?

if (1/ch8_info.sampleinterval) == 1000 && (1/ch9_info.sampleinterval) == 1000
    eyeX = ch8;
    eyeY = ch9;
else

% pack;
%go back to 120Hz...about..was 500Hz=2ms or ch8_info.sampleinterval
realx=[ch8_info.start:ch8_info.sampleinterval:ch8_info.stop];
desiredx=[ch8_info.start:(1/120):ch8_info.stop];
ch8a=interp1(realx,ch8,desiredx);
clear realx 
realy=[ch9_info.start:ch9_info.sampleinterval:ch9_info.stop];
desiredy=[ch9_info.start:(1/120):ch9_info.stop];
ch9a=interp1(realy,ch9,desiredy);
clear realy  ch9
ch8=ch8a;ch9=ch9a; clear ch9a ch8a;
% pack;
if length(ch9)>length(ch8);ch9(end)=[];end
if length(ch8)>length(ch9);ch8(end)=[];end
timeX(1:length(ch8))=desiredx(1:length(ch8));
timeY(1:length(ch9))=desiredy(1:length(ch8));
eyeX=ch8;
eyeY=ch9;
timeX(1)=0;
time=round(timeX*1000);
clear ch8 timeY timeX ch8_info ch9 desiredx desiredy ch8a DATA File Path fid Allheader ChanList ch9_info ch9_info i info name number scr scr_info

end