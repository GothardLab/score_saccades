clear all;
clc;

movietrial2=[];
moremovs='y';
while strcmp(moremovs,'y');
    [movfile,movpath] = uigetfile('*.mat','pick the matlab file that contains the movie trial data');
    load([movpath,movfile]);
    movietrial2=[movietrial2,movietrial];
    moremovs=input('are there more matlab movie files? ','s');
end
movietrial=movietrial2;
clear movietrial2;

save([movpath,movfile(1:end-12),'_combined.mat']);