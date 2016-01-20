function func_check_saccade_times_movieimageVaribleTimes()%(neweyeFile7,neweyePath7)

[neweyeFile7,neweyePath7] = uigetfile('*.mat','pick the matlab file that has the scanpath data (.mat) ');
load([neweyePath7,neweyeFile7]);
slidenum=1;
imonlength=10000;

for i=1:length(movietrial);
    clear distime;
    distime=round(1000*movietrial(i).frametime(1));
    movietrial(i).allX=eyeX(distime:distime+imonlength);
    movietrial(i).allY=eyeY(distime:distime+imonlength);
end

if ~isfield(movietrial,'sacstart');
    newfname=[neweyePath7,neweyeFile7(1:end-4),'_SCORING_SACCADES.mat'];
    caca=0;
    
    
    accellthresh=0.002;
    for i=1:length(movietrial);
        clear slash imontime smoothx smoothy diffx diffy speed smoothspeed accel;
        
        imontime=movietrial(i).frametime(1);
        
        smoothx=smooth(movietrial(i).allX,20);
        smoothy=smooth(movietrial(i).allY,20);
        diffx=diff(smoothx);
        diffy=diff(smoothy);
        speed=sqrt(diffx.^2 + diffy.^2);
        smoothspeed=smooth(speed,20);
        accel=diff(smoothspeed);
        movietrial(i).accel=smooth(accel,20);
        movietrial(i).speed=smoothspeed;
        
        clear accel accelbef accelmid accelaf peaks peaks2;
        accel=movietrial(i).accel;
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
        
        movietrial(i).sacstart=peaks;
        movietrial(i).sacend=dips;
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
xie=1;
xax=[0 imonlength];
while i<=length(movietrial);
    cla;
    while xie<=size(xax,1);
    clear imo sacstart sacend eyeox eyeoy;
    eyeox=movietrial(i).allX(1:imonlength);
    eyeoy=movietrial(i).allY(1:imonlength);
    sacstart=movietrial(i).sacstart;
    sacend=movietrial(i).sacend;
   

    cla;
    plot(eyeox,'k','LineWidth',2);
    hold on;
    plot(eyeoy+shift,'k','LineWidth',2);
    xlabel('time from image on (ms)');
    ylabel({['eyeX                   eyeY'],['(dva)']});

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
        end
    end
 title([num2str(i), ' of ', num2str(length(movietrial))]);
    hold on;
    
    if ~isempty(sacstart);
        plot(sacstart,eyeox(sacstart),'or','MarkerFaceColor','r','LineWidth',2);
        plot(sacstart,eyeoy(sacstart)+shift,'or','MarkerFaceColor','r','LineWidth',2);
    end
    if ~isempty(sacend);
        plot(sacend,eyeox(sacend),'ob','MarkerFaceColor','b','LineWidth',2);
        plot(sacend,eyeoy(sacend)+shift,'ob','MarkerFaceColor','b','LineWidth',2);
    end
    axis([xax(xie,1) xax(xie,2) -25 25+shift]);
    
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
        movietrial(i).sacstart=sacstart;
    elseif strcmp(a,'e');
        [x,y]=ginput(1);
        if x<1;
            x=1;
        elseif x>length(eyeox);
            x=length(eyeox);
        end
        sacend=[sacend;round(x)];
        sacend=sort(sacend);
        movietrial(i).sacend=sacend;
    elseif strcmp(a,'x');
        [x,y]=ginput(2);
        sacstart(find(sacstart>x(1) & sacstart<x(2)))=[];
        sacend(find(sacend>x(1) & sacend<x(2)))=[];
        movietrial(i).sacstart=sacstart;
        movietrial(i).sacend=sacend;
    elseif strcmp(a,'n') && strcmp(savemode,'yes');
        if xie<size(xax,1);
            xie=xie+1;
        else
            if ~isempty(sacstart) && ~isempty(sacend);
                if length(sacend)==length(sacstart);
                    if isempty(find((sacend-sacstart)<0));
                        slidenum2=i;
                        save(newfname);
                        i=i+1;
                        xie=1;
                    end
                end
            end
        end
    elseif strcmp(a,'n') && strcmp(savemode,'no');
        if xie<size(xax,1);
            xie=xie+1;
        else
            if ~isempty(sacstart) && ~isempty(sacend);
                if length(sacend)==length(sacstart);
                    if isempty(find((sacend-sacstart)<0));
                        
                        slidenum2=i;
                        i=i+1;
                        xie=1;
                    end
                end
            end
        end
    elseif strcmp(a,'v');
        slidenum2=i;
        save(newfname);
    elseif strcmp(a,'saveoff');
        savemode='no';
   elseif strcmp(a,'saveon');
        savemode='yes';
    elseif strcmp(a,'p');
        if xie>1;
          xie=xie-1;
        elseif i>1 && xie==1;
            i=i-1;
            xie=size(xax,1);
        end
    end
    end
end
  save(newfname);