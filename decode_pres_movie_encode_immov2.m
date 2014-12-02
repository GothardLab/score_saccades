%this function decodes the encodes that presentation sends during
%presentation of movies

function [movietrial]=decode_pres_movie_encode_immov2(smrfile, itmfile, moviesStart, moviesEnd);
%the output is a structure that contains the trial information for each
%movie presentation.  The first 2 inputs are the spike smr file and the movie itm
%file.  The last 2 inputs are the start and end times of the movie section
%of the file

fid=fopen(smrfile);    %open the file with chan 32
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
allmarks(find(alltimes<moviesStart | alltimes>moviesEnd))=[];   %delete any markers that didn't occur during the movie presentation period
alltimes(find(alltimes<moviesStart | alltimes>moviesEnd))=[];   %delete any marker times that didn't occur during the movie presentation period
if allmarks(1)==0;
    allmarks(1)=[];
    alltimes(1)=[];
end

badones=find(diff(alltimes)<0.002)+1;
alltimes(badones)=[];
allmarks(badones)=[];

%c=0;    %set a counter variable "c" to a value zero
%scroll through all the markers and take every other one to get the lobytes
% for i=1:2:length(allmarks);
%     c=c+1;  %incremetn the counter "c"
%     lob(c)=allmarks(i); %a vector with the lobyte values
%     marktimes(c)=alltimes(i);   %set the event times to the times that the lobytes were sent, since these are sent first
% end
% 
% c=0;    %reset the counter variable "c" to a value zero
% %scroll through all the markers and take every other one to get the hibytes
% for i=2:2:length(allmarks);
%     c=c+1;  %incremetn the counter "c"
%     hib(c)=allmarks(i); %a vector with the hibyte values
% end

clear hib lob hiblob;
c=0;
diffmarks=[diff(alltimes)];
for i=1:length(allmarks)-1;
    if (diffmarks(i)>0.002 & diffmarks(i)<=0.0064) & allmarks(i)~=0 & allmarks(i+1)~=232;
        c=c+1;
        lob(c)=allmarks(i);
        hib(c)=allmarks(i+1);
        marktimes(c)=alltimes(i);
    end
end
    
    
%scroll through all the lobyte values and combine them with the hibyte
%values to get the entire decimal value
for i=1:length(lob);
    hiblob(i)=double(lob(i))+(double(hib(i))*256);
end
marktimes(find(hiblob==0))=[];
hiblob(find(hiblob==0))=[];
marktimes(find(hiblob==59395))=[];
hiblob(find(hiblob==59395))=[];
marktimes(find(hiblob==3587))=[];
hiblob(find(hiblob==3587))=[];

cueon=find(hiblob(1:end-5)==35 & hiblob(2:end-4)==1000 & hiblob(3:end-3)==1000 & hiblob(4:end-2)==14 & hiblob(5:end-1)==36 & hiblob(6:end)>255);
cueon=unique([cueon,find(hiblob(1:end-4)==35 & hiblob(2:end-3)==1000 & hiblob(3:end-2)==14 & hiblob(4:end-1)==36 & hiblob(5:end)>255)]);

for i=1:length(cueon);  %scroll through all the cue on times

    movietrial(i).cueon=marktimes(cueon(i));    %for each movie trial, record the cueon time in a structure
    if hiblob(cueon(i)+4)==36;  %if the next marker is 36 (cue off) then...
        movietrial(i).cueoff=marktimes(cueon(i)+1);%...record the cue off time in the structure
    end
    if hiblob(cueon(i)+5)>256*255;  %if the next value after cue off is greater than FF*256 then this is the movie number
        movietrial(i).moviecnd=hiblob(cueon(i)+5)-256*255;  %calculate the movie cnd number and record it in the structure
        movietrial(i).movieon=marktimes(cueon(i)+6);    %record the time that the move cam on in the structure
    end
    endmov=find(hiblob(cueon(i)+6:end)==35,1,'first')+cueon(i)+6-1;
    if ~isempty(endmov);
    movietrial(i).framenum=hiblob(cueon(i)+6:endmov)-1000;  %then all the remaining markers are frame numbers; record them
    movietrial(i).frametime=marktimes(cueon(i)+6:endmov);   %record the time that each frame was presented.
    else
    movietrial(i).framenum=hiblob(cueon(i)+6:end)-1000;  %then all the remaining markers are frame numbers; record them
    movietrial(i).frametime=marktimes(cueon(i)+6:end);   %record the time that each frame was presented.
  
    end
    
end

fid=fopen(itmfile,'r'); %get an index so MATLAB knows where to find the itmfile
aline = fgetl(fid); %get the firstline of the itmfile
mind=strfind(aline, '|moviename');  %find the position of the moviename titlebar, since the movienames are aligned beneath it, this will allow us to find the movie names
c=0;     %set a counter variable "c" to a value zero
while ~feof(fid)    %as long as there are no lines left to read in from the itm file...
    c=c+1;  %increment the counter variable "c"
    aline = fgetl(fid); %read in the next line from the itm file
    aviind=strfind(aline,'.avi');   %find the last character in the name of the movie by looking for the string ".avi"
      lastframeind=strfind(aline,'|');
      lastframeind2=lastframeind(end);
    movie(c).cnd=c; %the condtion number equals the line number, record it in a movie variable
    movie(c).filename=aline(mind+1:aviind+3);   %record the movie filenames in a movie variable
    movie(c).endframe=str2num(aline(lastframeind2+1:lastframeind2+3));
end
% 
for i=1:length(movietrial); %scroll through each movie trial in the structure
    for k=1:length(movie);  %scroll through each movie name and cnd number in the other structure
        if movietrial(i).moviecnd==movie(k).cnd;    %if the cnd number for this movie trial matches the cnd of the movie structure
            movietrial(i).filename=movie(k).filename;   %then this must be the name of the movie, record it.
               movietrial(i).endframe=movie(k).endframe;   %then this must be the name of the movie, record it.
        end
    end
end

