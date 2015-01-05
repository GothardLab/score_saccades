clear all;
clc;

fid=dir('D:\GAZE CELLS\gaze matfiles\saccade scores\QT\cmmonk\');
fid(1)=[]; fid(1)=[];

for zz=1:length(fid);
    
    clearvars -except fid zz;
    load(['D:\GAZE CELLS\gaze matfiles\saccade scores\QT\cmmonk\',fid(zz).name]);
    imonlength=1500;
    
    
    for i=1:length(goodtrial);
        slash=max(strfind(goodtrial(i).imgfname{1},'\'));
        load(['D:\GAZE CELLS\images & eye regions\cmmonk images\eyereg\',goodtrial(i).imgfname{1}(slash+1:end-4),'.mat']);
        goodtrial(i).eyereg=eyeregion/255;
        goodtrial(i).eyecent=eyecent;
        if strfind(goodtrial(i).imgfname{1},'me');
            goodtrial(i).direct=1;
        else
            goodtrial(i).direct=0;
        end
    end
    
    for i=1:length(goodtrial);
        if min(goodtrial(i).sacstart)>2;
            goodtrial(i).sacstart=[1; goodtrial(i).sacstart];
            goodtrial(i).sacend=[2;goodtrial(i).sacend];
        end
    end
    for i=1:length(goodtrial);
        clear scantype eyeFixStart eyeFixEnd othFixStart othFixEnd regions regions2 regions3;
        eyexis=round(goodtrial(i).eyexImOn/PIX2ANG+150);
        eyeyis=round(-goodtrial(i).eyeyImOn/PIX2ANG+150);
        eyexis(find(eyexis<1))=1;eyeyis(find(eyeyis<1))=1;
        eyexis(find(eyexis>255))=255;eyeyis(find(eyeyis>255))=255;
        regions=goodtrial(i).eyereg(eyeyis,eyexis);
        regions2=diag(regions);
        regions3=regions2; regions3(end)=[];
        
        sactipo=[];
        for j=1:length(goodtrial(i).sacend)-1;
            tipo=median(regions3(goodtrial(i).sacend(j):goodtrial(i).sacend(j+1)));
            sactipo=[sactipo,tipo];
        end
        if goodtrial(i).sacend(end)<imonlength;
            sactipo=[sactipo,median(regions3(goodtrial(i).sacend(end):imonlength))];
        else
            sactipo=[sactipo,nan];
        end
        
        goodtrial(i).sactipo=sactipo;
    end
    
    save(['D:\GAZE CELLS\gaze matfiles\saccade types\',fid(zz).name(1:end-4),'_saccadetypes.mat']);
    disp(zz);
end