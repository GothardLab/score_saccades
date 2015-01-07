clear all
close all;
clc;

% function func_new_check_saccade_times_images(trial_path, eye_path)

trial_path = 'C:\Users\putnampt\Dev\score_saccades\matfiles\juritest_trialinfo_1-70_circ_e_n1_itm.mat';
eye_path = 'C:\Users\putnampt\Dev\score_saccades\matfiles\juritest_calibrated_eye.mat';


load(trial_path);
load(eye_path);
[save_dir, save_name, blurgh] =  fileparts(eye_path);
save_path = fullfile(save_dir, [save_name, '_SCORING_SACCADES.mat'])


%[neweyeFile7,neweyePath7] = uigetfile('*.mat','pick the matlab file that has the scanpath data (.mat) ');
%load([neweyePath7,neweyeFile7]);
slidenum=1;
imonlength=500; 

for i=1:length(trialinfo);
    clear start_time;
    start_time =round(trialinfo(i).imgon);
    stop_time =round(trialinfo(i).imgoff); 
    imagetrial(i).allX=eyeX(start_time:stop_time);
    imagetrial(i).allY=eyeY(start_time:stop_time);
    imagetrial(i).image_on_time = trialinfo(i).imgon;
    imagetrial(i).start_time = start_time;
    imagetrial(i).stop_time = stop_time;
end

% for i=1:length(imagetrial);
%     clear distime;
%     distime=round(1000*imagetrial(i).image_on_time(1));
%     imagetrial(i).allX=eyeX(distime:distime+10000);
%     imagetrial(i).allY=eyeY(distime:distime+10000);
% end

if ~isfield(imagetrial,'sacstart');
    %save_path=[neweyePath7,neweyeFile7(1:end-4),'_SCORING_SACCADES.mat'];
    caca=0;
    
    
    accellthresh=0.002;
    for i=1:length(imagetrial);
        clear slash imontime smoothx smoothy diffx diffy speed smoothspeed accel;
        
        imontime=imagetrial(i).image_on_time(1);
        
        smoothx=smooth(imagetrial(i).allX,20);
        smoothy=smooth(imagetrial(i).allY,20);
        diffx=diff(smoothx);
        diffy=diff(smoothy);
        speed=sqrt(diffx.^2 + diffy.^2);
        smoothspeed=smooth(speed,20);
        accel=diff(smoothspeed);
        imagetrial(i).accel=smooth(accel,20);
        imagetrial(i).speed=smoothspeed;
        
        clear accel accelbef accelmid accelaf peaks peaks2;
        accel=imagetrial(i).accel;
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
        
        imagetrial(i).sacstart=peaks;
        imagetrial(i).sacend=dips;
    end
    save(save_path);
end


i=slidenum;
if exist('slidenum2');
    i=slidenum2;
end
figure;

savemode='yes';
shift=14;
xie=1;
xax=[0 4000];
while i<=length(imagetrial);
    cla;
    while xie<=size(xax,1);
    clear imo sacstart sacend eyeox eyeoy;
    eyeox=imagetrial(i).allX(1:imonlength);
    eyeoy=imagetrial(i).allY(1:imonlength);
    sacstart=imagetrial(i).sacstart;
    sacend=imagetrial(i).sacend;
   

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
 title([num2str(i), ' of ', num2str(length(imagetrial))]);
    hold on;
    
    if ~isempty(sacstart);
        plot(sacstart,eyeox(sacstart),'or','MarkerFaceColor','r','LineWidth',2);
        plot(sacstart,eyeoy(sacstart)+shift,'or','MarkerFaceColor','r','LineWidth',2);
    end
    if ~isempty(sacend);
        plot(sacend,eyeox(sacend),'ob','MarkerFaceColor','b','LineWidth',2);
        plot(sacend,eyeoy(sacend)+shift,'ob','MarkerFaceColor','b','LineWidth',2);
    end
    axis([xax(xie,1) xax(xie,2) -15 15+shift]);
    
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
        imagetrial(i).sacstart=sacstart;
    elseif strcmp(a,'e');
        [x,y]=ginput(1);
        if x<1;
            x=1;
        elseif x>length(eyeox);
            x=length(eyeox);
        end
        sacend=[sacend;round(x)];
        sacend=sort(sacend);
        imagetrial(i).sacend=sacend;
    elseif strcmp(a,'x');
        [x,y]=ginput(2);
        sacstart(find(sacstart>x(1) & sacstart<x(2)))=[];
        sacend(find(sacend>x(1) & sacend<x(2)))=[];
        imagetrial(i).sacstart=sacstart;
        imagetrial(i).sacend=sacend;
    elseif strcmp(a,'n') && strcmp(savemode,'yes');
        if xie<size(xax,1);
            xie=xie+1;
        else
            if ~isempty(sacstart) && ~isempty(sacend);
                if length(sacend)==length(sacstart);
                    if isempty(find((sacend-sacstart)<0));
                        slidenum2=slidenum;
                        save(save_path);
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
                        
                        slidenum2=slidenum;
                        i=i+1;
                        xie=1;
                    end
                end
            end
        end
    elseif strcmp(a,'v');
        slidenum2=slidenum;
        save(save_path);
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
  save(save_path);