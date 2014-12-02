clear all;
clc;

fid = fopen('C:\results1a.txt');
tline = fgetl(fid);
fid2 = fopen('D:\movinput5.txt','wt');
    tline = fgetl(fid);
while ischar(tline);

    
    movind=strfind(tline, '|*|');
    
    movcnd=str2num(tline(1:movind-1));
    
    for t=1:300;
        clear stime etime;
        sid=[' ',num2str(t),'Xa '];
        stime=strfind(tline, sid)+length(sid);
        if ~isempty(stime);
        etime=strfind(tline(stime:end), ' ');
        etime=etime(1)+stime-2;
        
        xposA(t)=str2num(tline(stime:etime));
        else
            xposA(t)=0;
        end
        
        clear stime etime;
        sid=[' ',num2str(t),'Ya '];
        stime=strfind(tline, sid)+length(sid);
        if ~isempty(stime);
        etime=strfind(tline(stime:end), ' ');
        etime=etime(1)+stime-2;
        
        yposA(t)=str2num(tline(stime:etime));
        else
            yposA(t)=0;
        end
        
         clear stime etime;
        sid=[' ',num2str(t),'Xb '];
        stime=strfind(tline, sid)+length(sid);
        if ~isempty(stime);
        etime=strfind(tline(stime:end), ' ');
        etime=etime(1)+stime-2;
        
        xposB(t)=str2num(tline(stime:etime));
        else
            xposB(t)=0;
        end
        
         clear stime etime;
        sid=[' ',num2str(t),'Yb '];
        stime=strfind(tline, sid)+length(sid);
        if ~isempty(stime);
        etime=strfind(tline(stime:end), ' ');
        etime=etime(1)+stime-2;
        
        yposB(t)=str2num(tline(stime:etime));
        else
            yposB(t)=0;
        end
        
    end
    
    
    frameposX=-xposB;
    frameposY=-yposB;
    
    fprintf(fid2,[num2str(movcnd),'|*|']);
    for t=1:300;
        fprintf(fid2,[' ',num2str(t),'X ',num2str(frameposX(t))]);
        fprintf(fid2,[' ',num2str(t),'Y ',num2str(frameposY(t))]);
    end
    fprintf(fid2,[' \n']);
      tline = fgetl(fid);
end

fclose(fid2);

