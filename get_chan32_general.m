%get the channel 32 information and determine what images were shown to teh
%monkey and whether they were correctly seen

clear all;  %clear all the current variables in matlab
clc;    %clear the computer monitor

[File3,Path] = uigetfile('*.smr','pick a file with chan 32 (.smr) '); %get the location of the Spike file containing the channel 32
fid=fopen([Path,File3]);    %open the file with chan 32
[Allheader]=SONFileHeader(fid); %get the headers of the channels in this spike file
[ChanList2]=SONChanList(fid);   %get a list of the channel numbers 

%scroll through the channel list to find channel 32
for i=1:length(ChanList2) %excludes blank keyboard channel 31%
    number=ChanList2(1,i).number;   %get the number of the current channel
    name=[ChanList2(1,i).title];    %get the name of the current channel
    if number==32;  %if teh channel number is 32
        info=[ChanList2(1,i).title,'_info'];    %get information (e.g. sample rate) for chan 32
        [Chan32.data,Chan32.info]=SONGetMarkerChannel(fid, number); %get the times of the chan 32 markers
        Chan32.data.markers(:,2:4)=[];  %only take the first column of markers (the rest are just superfluos zeros)
    end
end

[File4,Path4] = uigetfile('*.itm','pick the itm file shown (.itm) '); %get the filepath of the item file
[File5,Path5] = uigetfile('*.cnd','pick the cnd file used (.cnd) ');  %get the filepath of the cnd file
sTimeITM=input('What time did you start showing this itm file (in seconds)?  ');   %get the start time at which the itm file began                                                                               %(important when multiple itm files -- including calibration-- were shown
eTimeITM=input('What time did you end itm file (in seconds)?  ');    %get the time at which we stopped showing the item file
mark32=Chan32.data.markers(find(Chan32.data.timings>sTimeITM & Chan32.data.timings<eTimeITM));
time32=Chan32.data.timings(find(Chan32.data.timings>sTimeITM & Chan32.data.timings<eTimeITM));
itm = readitmfile_general([Path4, File4]);  %read the item file into matlab
imgfname = {itm{2:end,2}};  %get the filenames of each item in the list
imgXpos = {itm{2:end,3}};  %get the filenames of each item in the list
imgYpos = {itm{2:end,4}};  %get the filenames of each item in the list
[trialinfo] = InterpCodes_allMkr_general(mark32,time32,[Path5,File5],imgfname,imgXpos,imgYpos,0); %get information about each trial
dir(Path);
if ~isdir([Path,'matfiles']);
    mkdir([Path,'matfiles']);
end
save([Path,'matfiles\',File3(1:end-4),'_trial_info_for_',File4(1:end-4),'_',num2str(sTimeITM),'s'],'trialinfo','imgfname','sTimeITM','eTimeITM');  %save the information about the trials to the same directory as the chan 32 file
