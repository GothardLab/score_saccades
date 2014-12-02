clear all;
clc;

[itmFile,itmPath] = uigetfile('*.txt','pick the text file that has the movie names (e.g. monkey_movies.txt) '); %have the user pick the appropriate movie itm file
[eyeFile,eyePath] = uigetfile('*.smr','pick the spike file that has the eyedata for the movies (.smr) ');   %have the user pick the appropriate spike file with the eye data

% fid=fopen([eyePath,eyeFile]);
% [Allheader]=SONFileHeader(fid);
% [ChanList]=SONChanList(fid);
% 
sTimeITM=input('What time did you start showing this itm file (in seconds)?  ');   %get the start time at which the itm file began                                                                               %(important when multiple itm files -- including calibration-- were shown
eTimeITM=input('What time did you end itm file (in seconds)?  ');    %get the time at which we stopped showing the item file

[pair, hiblob, marktimes] = Encode2HiLo([eyePath,eyeFile],sTimeITM,eTimeITM);

events=find(hiblob(1:end-3)==17 & hiblob(3:end-1)==18 & hiblob(4:end)==3);


fid=fopen([itmPath,itmFile],'r'); %get an index so MATLAB knows where to find the itmfile
aline = fgetl(fid); %get the firstline of the itmfile
mind=strfind(aline, '|filename');  %find the position of the moviename titlebar, since the movienames are aligned beneath it, this will allow us to find the movie names
c=0;     %set a counter variable "c" to a value zero
while ~feof(fid)    %as long as there are no lines left to read in from the itm file...

    aline = fgetl(fid); %read in the next line from the itm file
    aviind=strfind(aline,'.bmp');   %find the last character in the name of the movie by looking for the string ".avi"
    temp_filename = aline(mind+1:aviind+3);

    if  size(temp_filename,2)
        c=c+1;  %increment the counter variable "c"
        bmp(c).cnd=c; %the condtion number equals the line number, record it in a movie variable
        bmp(c).filename=['cmmonks\',aline(mind+1:aviind+3)];   %record the movie filenames in a movie variable
 
    end
    
    
end

for j=1:length(events);
    trialinfo(j).imgon=round(1000*marktimes(events(j)));
    trialinfo(j).imgoff=round(1000*marktimes(events(j)+2));
    trialinfo(j).cndnum=hiblob(events(j)+1)-1000;
    trialinfo(j).imgfname{1}=bmp(trialinfo(j).cndnum).filename;
    trialinfo(j).trialtype='good';
end

if ~isdir([eyePath,'matfiles\'])
    mkdir([eyePath,'matfiles\']);
end
save([eyePath,'matfiles\',eyeFile(1:end-4),'_trialinfo_',num2str(sTimeITM),'-',num2str(eTimeITM),'_',itmFile(1:end-4),'.mat'],'sTimeITM','eTimeITM','trialinfo');
