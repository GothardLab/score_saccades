clear all;
clc;

direct='C:\REMOTE32\webphoto\eyes\'
fid=dir(direct);
fid(1)=[]; fid(1)=[];
if ~isdir([direct(1:end-5),'eyereg\']);
    mkdir([direct(1:end-5),'eyereg\']);
end
for i=1:length(fid);
    clear imo eyecent eyeregion;
    imo=imread([direct(1:end-5),fid(i).name]);
    imshow(imo);
    [x,y]=ginput(1);
    eyecent=[round(x),round(y)];
    
    imo=imread([direct,fid(i).name]);
    imo(find(imo>1))=255;
    imshow(imo);
    hold on;
    plot(eyecent(1),eyecent(2),'ok','MarkerFaceColor','r');
    pause;
    eyeregion=imo(:,:,1);
    save([direct(1:end-5),'eyereg\',fid(i).name(1:end-4),'.mat'],'eyecent','imo','eyeregion');
end