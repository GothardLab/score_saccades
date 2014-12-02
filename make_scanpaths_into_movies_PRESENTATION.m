clear all;
clc;
close all;


[anFile,anPath] = uigetfile('*.mat','pick the MATLAB file with the movie scanpath data ');
load([anPath,anFile]);

PRESWIDTH_MOVIE=1024 %the width of the monitor used during calibration (800x600 typically);
PRESHEIGHT_MOVIE=768 %the height of the monitor used during calibration (800x600 typically);
moviedir='H:\presentation_stimuli\movie_physio\';

blackround=zeros(PRESHEIGHT_MOVIE,PRESWIDTH_MOVIE,3);

fixcolor=[255 0 0]/255;
% if ~isdir(['C:\data\MOVIE_LOOKING_PAPER\vg091510\movies_with_scanpaths\',eyeFile(1:end-4),'\']);
%     mkdir(['C:\data\MOVIE_LOOKING_PAPER\vg091510\movies_with_scanpaths\',eyeFile(1:end-4),'\']);
% end
movspeed=input('What speed would you like the movies to be made at (half speed=0.5)? ');
PIX2ANG_X_MOVIE = PIX2ANG_X; %conversion factor for taking pixels to DVA
PIX2ANG_Y_MOVIE = PIX2ANG_Y; %conversion factor for taking pixels to DVA

%PIX2ANG_X_MOVIE = ANGWIDTH_X/PRESWIDTH_MOVIE; %conversion factor for taking pixels to DVA
%PIX2ANG_Y_MOVIE = ANGWIDTH_Y/PRESHEIGHT_MOVIE; %conversion factor for taking pixels to DVA
% [movFile,movPath] = uigetfile('*.avi','pick the avi file that has the recorded movie of the viewer monkey (.avi) ');   %have the user pick the appropriate spike file with the eye data
% mov=[movPath,movFile];
% movieData = mmreader(mov);

if ~isdir([eyePath,'scanpath_movies\']);
    mkdir([eyePath,'scanpath_movies\']);
end
figure;
set(gcf,'Position',[80         124        1120         840],'Color','k');

webcamInt= 0.01496173;
webcamSlope=0.00115174;


for i=1 :10;%length(movietrial);
    clear videoFWriter;
    vidname=['D:\MOVIE IMAGE DATA\movies of stuff\',movietrial(i).filename(1:end-4),'_',num2str(i),'.avi'];
    videoFWriter =vision.VideoFileWriter(vidname,'FrameRate',round(30*movspeed),'VideoCompressor','DV Video Encoder');



    if strfind(movietrial(i).filename(1),'''');
        movietrial(i).filename(1)=[];
        movietrial(i).filename(end)=[];
    end
    for j=1:length(movietrial(i).framenum)-1;
       % if movietrial(i).endframe~=1;
        frame_num=movietrial(i).framenum(j);
        frameload=imread([moviedir,movietrial(i).filename(1:end-4),'\',num2str(frame_num),'.bmp']); %load the frame for frame1,movie1
       % elseif movietrial(i).endframe==1;
       % frame_num=j;
       % frameload=imread(['H:\presentation_stimuli\movie_physio\00 single movie frames\',movietrial(i).filename(1:end-4),'.bmp']); %load the frame for frame1,movie1
       % end
        cla;
        imagesc([-(size(blackround,2)/2)*PIX2ANG_X_MOVIE,(size(blackround,2)/2)*PIX2ANG_X_MOVIE],[-(size(blackround,1)/2)*PIX2ANG_Y_MOVIE,(size(blackround,1)/2)*PIX2ANG_Y_MOVIE],blackround);
        hold on;    %hold the background on while we also show the image (otherwise the black baground will just dissappear)
        %display the image.  Center it on the center of the screen and
        %convert itto dva
        imagesc([-(size(frameload,2)/2)*PIX2ANG_X_MOVIE (size(frameload,2)/2)*PIX2ANG_X_MOVIE],[-(size(frameload,1)/2)*PIX2ANG_Y_MOVIE (size(frameload,1)/2)*PIX2ANG_Y_MOVIE],frameload);
        hold on;    %hold on the background and image while we plot the eye data
        %plot the eye data in dva, be sure to flip the y-axis (multiply eyey by -1) since matlab plots images in inverse y-cartesian coordinates
        plot(movietrial(i).eyex{j},-movietrial(i).eyey{j},'Color',fixcolor,'LineWidth',5);
          text(-16,-12,['\bf',num2str(i), '   ',movietrial(i).filename(1:end-4), ': frame ', num2str(j),', ' num2str(movietrial(i).frametime(j)),' s'],'Color','w','FontSize',14);

%              webframe=round(30*(movietrial(i).frametime(f)+(movietrial(i).frametime(f)*webcamSlope + webcamInt)))+1;
%             webload=read(movieData,webframe);
%             image([10.6 18.7]-1,[0 5.4]-13,webload);
%             set(gca,'xtick',[],'ytick',[]);
                     gg = getframe(gcf);
        step(videoFWriter,gg.cdata);

    end
     for s=1:5;
         cla;
        imagesc([-(size(blackround,2)/2)*PIX2ANG_X_MOVIE,(size(blackround,2)/2)*PIX2ANG_X_MOVIE],[-(size(blackround,1)/2)*PIX2ANG_Y_MOVIE,(size(blackround,1)/2)*PIX2ANG_Y_MOVIE],blackround);
         gg = getframe(gcf);
        step(videoFWriter,gg.cdata);
     end
   release(videoFWriter);
   % movie2avi(M,['G:\movie_scanpaths\',anPath(12:17),'\MOVIE_',num2str(i),'_',movietrial(i).filename(1:end-4)],'fps',30);
%    mmwrite([eyePath,'scanpath_movies\',movietrial(i).filename(1:end-4),'_',num2str(round(movietrial(i).frametime(1))),'.wmv'],v); 
    disp([num2str(i), ' of ', num2str(length(movietrial))]);
end
