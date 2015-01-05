clear all
close all;
clc;


[neweyeFile7,neweyePath7] = uigetfile('*.mat','pick the matlab file that has the scanpath data (.mat) ');
load([neweyePath7,neweyeFile7]);
slidenum=1;
PIX2ANG=PIX2ANG_X;
if ~exist('goodtrial');
    newfname=[neweyePath7,neweyeFile7(1:end-4),'_SCORING_SACCADES.mat'];
    caca=0;
    for i=1:length(trialinfo);
        if strcmp(trialinfo(i).trialtype,'good');
            caca=caca+1;
            goodtrial(caca)=trialinfo(i);
        end
    end
    clear trialinfo;
   
    accellthresh=0.002;
    for i=1:length(goodtrial);
        clear slash imontime smoothx smoothy diffx diffy speed smoothspeed accel;
        imonlength=4000;
        imontime=goodtrial(i).imgon/1000;
        
        smoothx=smooth(goodtrial(i).eyexImOn,20);
        smoothy=smooth(goodtrial(i).eyeyImOn,20);
        diffx=diff(smoothx);
        diffy=diff(smoothy);
        speed=sqrt(diffx.^2 + diffy.^2);
        smoothspeed=smooth(speed,20);
        accel=diff(smoothspeed);
        goodtrial(i).accel=smooth(accel,20);
        goodtrial(i).speed=smoothspeed;
        
        clear accel accelbef accelmid accelaf peaks peaks2;
        accel=goodtrial(i).accel;
        accelbef=accel; accelaf=accel; accelmid=accel;
        accelbef(1:2)=[];
        accelmid(1)=[]; accelmid(end)=[];
        accelaf(end-1:end)=[];
        peaks=[];
        peaks=find((accelbef-accelmid)<0 & (accelaf-accelmid)<0 & accelmid>accellthresh)+1;
        dips=[];
        dips=find((accelbef-accelmid)>0 & (accelaf-accelmid)>0 & accelmid<-accellthresh)+1;
        
        peaks(find(peaks<10))=[];
        peaks(find(peaks>length(accel-10)))=[];
        dips(find(dips<10))=[];
        dips(find(dips>length(accel-10)))=[];
        
        goodtrial(i).sacstart=peaks;
        goodtrial(i).sacend=dips;
    end
    save(newfname);
end


i=slidenum;
if exist('slidenum2');
    i=slidenum2;
end
figure;

savemode='yes';
shift=14;
while i<=length(goodtrial);
    clear imo sacstart sacend eyeox eyeoy;
    imo=[imread(['C:\REMOTE32\CIRC8B\',goodtrial(i).imgfname{1}(9:end)])];
    imonlength=4000;
    subplot(3,4,1);
    cla;
    imshow(imo,'XData',[-(size(imo,2)/2)*PIX2ANG,(size(imo,2)/2)*PIX2ANG],'YData',[-(size(imo,1)/2)*PIX2ANG,(size(imo,1)/2)*PIX2ANG]);
    hold on;
    %set(gca,'xtick',[],'ytick',[]);
    eyeox=goodtrial(i).eyexImOn(1:imonlength);
    eyeoy=goodtrial(i).eyeyImOn(1:imonlength);
    plot(eyeox,-eyeoy,'k','LineWidth',1);
    sacstart=goodtrial(i).sacstart;
    sacend=goodtrial(i).sacend;
    title([num2str(i), ' of ', num2str(length(goodtrial))]);
    subplot(3,4,[2 3 4 6 7 8 10 11 12]);
    cla;
    plot(eyeox,'k','LineWidth',2);
    hold on;
    plot(eyeoy+shift,'k','LineWidth',2);
    xlabel('time from image on (ms)');
    ylabel({['eyeX                   eyeY'],['(dva)']});
    set(gca,'yticklabel',[-5 0 5 -5 0 5]);
    if ~isempty(sacstart) && ~isempty(sacend);
        fixsacs=nan(1,imonlength);
        if length(sacend)==length(sacstart);
            if isempty(find((sacend-sacstart)<0));
                for k=1:length(sacstart);
                    fixsacs(sacstart(k):sacend(k))=1;
                end
                for k=1:length(sacstart)-1;
                    fixsacs(sacend(k)+1:sacstart(k+1)-1)=2;
                end
                if sacstart(1)>=2;
                    fixsacs(1:sacstart(1)-1)=2;
                end
                if sacend(end)<length(eyeox);
                    fixsacs(sacend(end):length(eyeox))=2;
                end
            end
            plot(find(fixsacs==2),eyeox(find(fixsacs==2)),'og','MarkerFaceColor','g','LineWidth',2);
            plot(find(fixsacs==2),eyeoy(find(fixsacs==2))+shift,'og','MarkerFaceColor','g','LineWidth',2);
            clear dist;
            dist=sqrt((eyeox(sacend)-eyeox(sacstart)).^2 + (eyeoy(sacend)-eyeoy(sacstart)).^2);
            for s=1:length(dist);
                text(sacstart(s),7.5,num2str(round(dist(s)*10)/10),'FontSize',14);
            end
            subplot(3,4,1);
            hold on;
            plot(eyeox(find(fixsacs==2)),-eyeoy(find(fixsacs==2)),'og','MarkerFaceColor','g','LineWidth',2);
            
        end
    end
    subplot(3,4,[2 3 4 6 7 8 10 11 12]);
    hold on;
    
    if ~isempty(sacstart);
        plot(sacstart,eyeox(sacstart),'or','MarkerFaceColor','r','LineWidth',2);
        plot(sacstart,eyeoy(sacstart)+shift,'or','MarkerFaceColor','r','LineWidth',2);
    end
    if ~isempty(sacend);
        plot(sacend,eyeox(sacend),'ob','MarkerFaceColor','b','LineWidth',2);
        plot(sacend,eyeoy(sacend)+shift,'ob','MarkerFaceColor','b','LineWidth',2);
    end
    axis([0 length(eyeox) -12 12+shift]);
    
    clear x y;
    a=input('what do you want to do?  ','s');
    if strcmp(a,'s');
        [x,y]=ginput(1);
        if x<1;
            x=1;
        elseif x>length(eyeox);
            x=length(eyeox);
        end
        sacstart=[sacstart;round(x)];
        sacstart=sort(sacstart);
        goodtrial(i).sacstart=sacstart;
    elseif strcmp(a,'e');
        [x,y]=ginput(1);
        if x<1;
            x=1;
        elseif x>length(eyeox);
            x=length(eyeox);
        end
        sacend=[sacend;round(x)];
        sacend=sort(sacend);
        goodtrial(i).sacend=sacend;
    elseif strcmp(a,'x');
        [x,y]=ginput(2);
        sacstart(find(sacstart>x(1) & sacstart<x(2)))=[];
        sacend(find(sacend>x(1) & sacend<x(2)))=[];
        goodtrial(i).sacstart=sacstart;
        goodtrial(i).sacend=sacend;
    elseif strcmp(a,'n') && strcmp(savemode,'yes');
        if ~isempty(sacstart) && ~isempty(sacend);
            if length(sacend)==length(sacstart);
                if isempty(find((sacend-sacstart)<0));
                    slidenum2=slidenum;
                    save(newfname);
                    i=i+1;
                end
            end
        end
    elseif strcmp(a,'n') && strcmp(savemode,'no');
        if ~isempty(sacstart) && ~isempty(sacend);
            if length(sacend)==length(sacstart);
                if isempty(find((sacend-sacstart)<0));
                    i=i+1;
                end
            end
        end
    elseif strcmp(a,'v');
        slidenum2=slidenum;
        save(newfname);
    elseif strcmp(a,'saveoff');
        savemode='no';
   elseif strcmp(a,'saveon');
        savemode='yes';
    elseif strcmp(a,'p');
        if i>1;
            i=i-1;
        end
    end
end
  save(newfname);