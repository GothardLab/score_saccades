clear all;
clc;

load('F:\scanpath_neurons\scanpathfileChart.mat');
[File4,Path4] = uigetfile('*.mat','pick the file with the trial info and calibrated eye data (.mat) ');
[File5,Path5] = uigetfile('*.mat','pick the file with the cell info (.mat) ');
slashes=strfind(Path5,'\');
elecstuff=Path5(slashes(end-1)+1:slashes(end)-1);
elecnum=elecstuff(2);
marknum=elecstuff(5);
date=Path5(slashes(end-2)+1:slashes(end-1)-1);
newcell={date,elecnum,marknum,[Path5,File5],[Path4,File4]};
porky=0;
for j=2:size(scanChart,1);
    if strfind(scanChart{j,4},[Path5,File5]);
        porky=1;
    end
end
if porky ==0;
scanChart=[scanChart;newcell];
end
save('F:\scanpath_neurons\scanpathfileChart.mat','scanChart');

load([Path4,File4],'CTX2ANG','trialinfo','PIX2ANG');
load([Path5,File5]);

imonlength=1500;
if ~isdir (['F:\scanpath_neurons',Path5(17:end)]);
    mkdir (['F:\scanpath_neurons',Path5(17:end)]);
end
caca=0;
for i=1:length(trialinfo);
    if strcmp(trialinfo(i).trialtype,'good');
        caca=caca+1;
        if trialinfo(i).imgon>sTime*1000 && trialinfo(i).imgon+imonlength<eTime*1000;
            goodtrial(caca)=trialinfo(i);
        end
    end
end
clear trialinfo;

for i=1:length(goodtrial);
    slash=max(strfind(goodtrial(i).imgfname{1},'\'));
    load(['C:\REMOTE32\',goodtrial(i).imgfname{1}(1:slash),'eyereg\',goodtrial(i).imgfname{1}(slash+1:end-4),'.mat']);
    goodtrial(i).eyereg=eyeregion/255;
    goodtrial(i).eyecent=eyecent;
    if strfind(goodtrial(i).imgfname{1},'me');
        goodtrial(i).direct=1;
    else
        goodtrial(i).direct=0;
    end
end

spikes2=round(spikes*1000);
spikebin=zeros(1,round(eTime*1000)+10000);
spikebin(spikes2)=1;
gauSize=51;
w=gausswin(gauSize);
gaussbin=conv(spikebin,w);
gaussbin(1:floor(gauSize/2))=[];
gaussbin(end-floor(gauSize/2)+1:end)=[];
allgausslist=[];

gauSize2=21;
w2=gausswin(gauSize2);
gaussbin2=conv(spikebin,w2);
gaussbin2(1:floor(gauSize2/2))=[];
gaussbin2(end-floor(gauSize2/2)+1:end)=[];

gauSize3=11;
w3=gausswin(gauSize3);
gaussbin3=conv(spikebin,w3);
gaussbin3(1:floor(gauSize3/2))=[];
gaussbin3(end-floor(gauSize3/2)+1:end)=[];

sacthres=0.05;
for i=1:length(goodtrial);
    imon=round(goodtrial(i).imgon);
    
    goodtrial(i).spikecut=spikes2(find(spikes2>imon & spikes2<(imon+imonlength)))-imon;
    goodtrial(i).gausscut=gaussbin(imon:imon+imonlength);
    goodtrial(i).bincut=spikebin(imon:imon+imonlength);
    goodtrial(i).gausscut2=gaussbin2(imon:imon+imonlength);
    goodtrial(i).gausscut3=gaussbin3(imon:imon+imonlength);
    allgauss(i,:)=gaussbin(imon:imon+imonlength);
    allgauss2(i,:)=gaussbin2(imon:imon+imonlength);
    allgauss3(i,:)=gaussbin3(imon:imon+imonlength);
    allgausslist=[allgausslist,gaussbin(imon:imon+imonlength)];
    
    smoothx=smooth(goodtrial(i).eyexImOn,20);
    smoothy=smooth(goodtrial(i).eyeyImOn,20);
    diffx=diff(smoothx);
    diffy=diff(smoothy);
    speed=sqrt(diffx.^2 + diffy.^2);
    smoothspeed=smooth(speed,20);
    accel=diff(smoothspeed);
    goodtrial(i).accel=smooth(accel,20);
    goodtrial(i).speed=smoothspeed;
end

speedthresh=0.05;
alltypes=[];
for i=1:length(goodtrial);
    clear scantype eyeFixStart eyeFixEnd othFixStart othFixEnd regions regions2 regions3;
    eyexis=round(goodtrial(i).eyexImOn/PIX2ANG+150);
    eyeyis=round(-goodtrial(i).eyeyImOn/PIX2ANG+150);
    eyexis(find(eyexis<1))=1;eyeyis(find(eyeyis<1))=1;
    eyexis(find(eyexis>255))=255;eyeyis(find(eyeyis>255))=255;
    regions=goodtrial(i).eyereg(eyeyis,eyexis);
    regions2=diag(regions);
    regions3=regions2; regions3(end)=[];
    
    scantype=zeros(1,imonlength);
    scantype(find(goodtrial(i).speed>=speedthresh))=-1;
    scantype(find(goodtrial(i).speed<speedthresh & regions3==1))=1;
    scantype(find(goodtrial(i).speed<speedthresh & regions3==0))=2;
    
    goodtrial(i).scantype=scantype;
    
    eyeFixStart=strfind(scantype,[-1,ones(1,50)])+1;
    for k=1:length(eyeFixStart);
        if ~isempty(find(scantype(eyeFixStart(k):end)~=1))
            eyeFixEnd(k)=min(find(scantype(eyeFixStart(k):end)~=1))+eyeFixStart(k)-1;
        else;
            eyeFixEnd(k)=1500;
        end
    end
    
    othFixStart=strfind(scantype,[-1,2*ones(1,50)])+1;
    for k=1:length(othFixStart);
        if ~isempty(find(scantype(othFixStart(k):end)~=2))
            othFixEnd(k)=min(find(scantype(othFixStart(k):end)~=2))+othFixStart(k)-1;
        else;
            othFixEnd(k)=1500;
        end
    end
    if ~isempty(eyeFixStart);
        goodtrial(i).eyefixes=[eyeFixStart',eyeFixEnd'];
    end
    if ~isempty(othFixStart);
        goodtrial(i).othfixes=[othFixStart',othFixEnd'];
    end
end



x_ax=[0:0.01:max(allgausslist)+0.01]
n_elements = histc(allgausslist,x_ax)/length(allgausslist);
c_elements = cumsum(n_elements);
cocoboon=c_elements(1);
c_elements= (c_elements-c_elements(1))/(1-c_elements(1));
colspace=linspace(0,1,64);
cocospace=zeros(1,length(c_elements));
for i=1:64;
    cocospace(find(c_elements>=colspace(i)))=i;
end

accellthresh=0.002;
caca=0;
clear sacSpike;allto=[]; clear sacSpikeTips; clear firstGauss allAccel; gaussSac=[];
for i=1:length(goodtrial);
    accel=goodtrial(i).accel;
    accelbef=accel; accelaf=accel; accelmid=accel;
    accelbef(1:2)=[];
    accelmid(1)=[]; accelmid(end)=[];
    accelaf(end-1:end)=[];
    peaks=find((accelbef-accelmid)<0 & (accelaf-accelmid)<0 & accelmid>accellthresh)+1;
    goodtrial(i).sacstart=peaks;
    firstSaccade(i)=NaN;
    if ~isempty(peaks);
    firstSaccade(i)=min(peaks(find(peaks>50)));
    end
    goodtrial(i).firstSaccade=firstSaccade(i);
    firstEye(i)=NaN;
    if ~isempty(goodtrial(i).eyefixes);
        if ~isempty(find(goodtrial(i).eyefixes(1,:)>50));
            firstEye(i)=min(goodtrial(i).eyefixes(1,find(goodtrial(i).eyefixes(1,:)>50)));
        end
    end
    
    firstOther(i)=NaN;
    if ~isempty(goodtrial(i).othfixes);
        if  ~isempty(find(goodtrial(i).othfixes(1,:)>50));
            firstOther(i)=min(goodtrial(i).othfixes(1,find(goodtrial(i).othfixes(1,:)>50)));
        end
    end
end

t=10.5;
scaletime=(300)*PIX2ANG/imonlength;
speedscale=0.4; speedsub=9;
colorscale=autumn;
colorscale=colorscale(64:-1:1,:);
colorscale(1,:)=[173,173,173]/255;
whitechunk=255*ones(100,300,3);
scrsz = get(0,'ScreenSize')

for i=1:length(goodtrial);
    cnd(i)=goodtrial(i).cndnum;
end
[n,ix]=sort(cnd);
close all;
figure;
set(gcf,'Position',[1 1 scrsz(3) scrsz(4)]);
for j=0:(ceil(length(goodtrial)/8)-1);
    
    for i=1:8;
        
        index=ix(i+j*8);
        if index<=length(goodtrial);
            gaussraw=(goodtrial(index).gausscut(1:imonlength));
            gaussround=ceil(gaussraw*100)+1;
            gausscol=cocospace(gaussround);
            
            scantype=goodtrial(index).scantype;
            
            subplot(2,4,i);
            imo=[imread(['C:\REMOTE32\',goodtrial(index).imgfname{1}]);whitechunk];
            imshow(imo,'XData',[-(size(imo,2)/2)*PIX2ANG,(size(imo,2)/2)*PIX2ANG],'YData',[-(size(imo,1)/2-50)*PIX2ANG,(size(imo,1)/2+50)*PIX2ANG]);
            hold on;
            %set(gca,'xtick',[],'ytick',[]);
            eyeox=goodtrial(index).eyexImOn(1:imonlength);
            eyeoy=-goodtrial(index).eyeyImOn(1:imonlength);
            plot(eyeox,eyeoy,'k','LineWidth',1);
            eyeox(find(scantype<0))=NaN;
            eyeoy(find(scantype<0))=NaN;
            scatter(eyeox,eyeoy,10,colorscale(gausscol,:),'filled');
            if ~isempty(find(scantype==1));
                plot((find(scantype==1)-imonlength/2)*scaletime,11.5,'sr','MarkerEdgeColor',[0 178 238]/255,'MarkerFaceColor',[0 178 238]/255);
            end
            if ~isempty(find(scantype==2));
                plot((find(scantype==2)-imonlength/2)*scaletime,11.5,'sg','MarkerEdgeColor',[107 66 38]/255,'MarkerFaceColor',[107 66 38]/255);
            end
            if ~isempty(goodtrial(index).spikecut);
                h=errorbar((goodtrial(index).spikecut-750)*scaletime,t*ones(length(goodtrial(index).spikecut),1,'single'),0.4*ones(length(goodtrial(index).spikecut),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
                errorbar_tick(h,0);
                hold on;
            end
            plot(([1:imonlength]-imonlength/2)*scaletime,-goodtrial(index).eyexImOn(1:imonlength)*speedscale+speedsub,'-b','LineWidth',2);
            plot(([1:imonlength]-imonlength/2)*scaletime,-goodtrial(index).eyeyImOn(1:imonlength)*speedscale+speedsub,'-g','LineWidth',2);
            plot((goodtrial(index).sacstart-imonlength/2)*scaletime,-goodtrial(index).eyexImOn(goodtrial(index).sacstart)*speedscale+speedsub,'om','MarkerFaceColor','m');
            plot((goodtrial(index).sacstart-imonlength/2)*scaletime,-goodtrial(index).eyeyImOn(goodtrial(index).sacstart)*speedscale+speedsub,'om','MarkerFaceColor','m');
            
            if i==1;
                title({File5;[num2str(goodtrial(index).cndnum),':  ',goodtrial(index).imgfname{1},', t= ',num2str(round(goodtrial(index).imgon/100)/10),'s']});
            else;
                title([num2str(goodtrial(index).cndnum),':  ',goodtrial(index).imgfname{1},', t= ',num2str(round(goodtrial(index).imgon/100)/10),'s']);
            end
        end
    end
    pause(5);
    
    
    saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SCANPATHS_',num2str(j+1),'.jpg'];
    screenCapture(saveName2);
    clf;
end



%let's see if firing rate depends on where the location of the initial
%fixation is.

phase1=80; phase2=300;
cacaEye=0; cacaOther=0;
for i=1:length(goodtrial);
    type=goodtrial(i).scantype;
    minnex=min(find(type>0));
    
    eyeloc=(goodtrial(i).eyecent-[150,150])*PIX2ANG;
    dist(i)=sqrt((goodtrial(i).eyexImOn(minnex)-eyeloc(1))^2+(-goodtrial(i).eyeyImOn(minnex)-eyeloc(2))^2);
    distph(i)=sum(goodtrial(i).bincut(phase1:phase2))/((phase2-phase1)/1000);
    if type(minnex)==1;
        cacaEye=cacaEye+1;
        phaseEye(cacaEye)=sum(goodtrial(i).bincut(phase1:phase2))/((phase2-phase1)/1000);
        gaussEye(cacaEye,:)=goodtrial(i).gausscut;
        cutEye{cacaEye}=goodtrial(i).spikecut;
    elseif type(minnex)==2;
        cacaOther=cacaOther+1;
        phaseOther(cacaOther)=sum(goodtrial(i).bincut(phase1:phase2))/((phase2-phase1)/1000);
        gaussOther(cacaOther,:)=goodtrial(i).gausscut;
        cutOther{cacaOther}=goodtrial(i).spikecut;
    end
end

subplot(3,2,[1 3]);
for i=1:length(cutEye);
    if ~isempty(cutEye{i});
        h=errorbar((cutEye{i}),i*ones(length(cutEye{i}),1,'single'),0.4*ones(length(cutEye{i}),1,'single'),'LineStyle','none','Color',[0 154 205]/255,'LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
for i=1:length(cutOther);
    if ~isempty(cutOther{i});
        h=errorbar((cutOther{i}),(i+length(cutEye))*ones(length(cutOther{i}),1,'single'),0.4*ones(length(cutOther{i}),1,'single'),'LineStyle','none','Color',[107 66 38]/255,'LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([0 imonlength 0 length(goodtrial)]);
title('File5');
subplot(3,2,5);
plot([0:imonlength],mean(gaussEye)/(gauSize/1000),'Color',[0 154 205]/255,'LineWidth',2);
hold on;
plot([0:imonlength],mean(gaussOther)/(gauSize/1000),'Color',[107 66 38]/255,'LineWidth',2);
legend({'eye start',  'other start'});
[p,h,stats]=ranksum(phaseEye,phaseOther);

sig1=[]; sig2=[];
for i=1:imonlength;
    [p2,h2,stats2]=ranksum(gaussEye(:,i),gaussOther(:,i));
    pStartPlace(i)=p2;
    if p2<0.01;
        sig2=[sig2,i];
    elseif p2>=0.01 && p2<0.05;
        sig1=[sig1,i];
    end
end
if ~isempty(sig1);
    plot(sig1,-0.01,'*k');
end
if ~isempty(sig2);
    plot(sig2,-0.01,'*r');
end
xlabel('time from image on (ms)');
ylabel('firing rate (Hz)');
title(['phasic pval (ranksum): ' num2str(p)]);

subplot(3,2,[2 4]);
plot(dist,distph,'ok','MarkerFaceColor','k');
xlabel('distance of initial fix from eyes (dva)');
ylabel('phasic firing rate (80-300ms window) (Hz)');
statslin = regstats(distph',dist');
hold on;
plot([0:0.1:max(dist)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[0:0.1:max(dist)],'-k');
title(['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']);
pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_INITIALFIXATION_FRATE.jpg'];
screenCapture(saveName2);

clf;


for i=1:length(goodtrial);
    scanlength(i)=sum(goodtrial(i).speed);
    tonrate(i)=length(goodtrial(i).spikecut)/(imonlength/1000);
    if length(goodtrial(i).spikecut)>2;
        isi=diff(goodtrial(i).spikecut)/1000;
        CV(i)=std(isi)/mean(isi);
    else
        CV(i)=NaN;
    end
    eyeloc=(goodtrial(i).eyecent-[150,150])*PIX2ANG;
    tempdist=sqrt((goodtrial(i).eyexImOn(find(goodtrial(i).scantype>0))-eyeloc(1)).^2+(-goodtrial(i).eyeyImOn(find(goodtrial(i).scantype>0))-eyeloc(2)).^2);
    totaldisteye(i)=median(tempdist);
    toteyelooking(i)=length(find(goodtrial(i).scantype==1));
end
subplot(3,2,[1 3]);
plot(scanlength,tonrate,'ok','MarkerFaceColor','k');
xlabel('scanpath length (dva)');
ylabel('mean tonic firing rate (Hz)');
statslin = regstats(tonrate',scanlength');
hold on;
plot([min(scanlength):0.1:max(scanlength)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(scanlength):0.1:max(scanlength)],'-k');
title({File5,['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']});

subplot(3,2,[2 4]);
plot(scanlength,CV,'ok','MarkerFaceColor','k');
xlabel('scanpath length (dva)');
ylabel('Coefficient of variation');
statslin = regstats(CV',scanlength');
hold on;
plot([min(scanlength):0.1:max(scanlength)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(scanlength):0.1:max(scanlength)],'-k');
title(['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SCANPATHLENGTH_FRATE.jpg'];
pause(5);
screenCapture(saveName2);
clf;


subplot(3,2,[1 3]);
plot(totaldisteye,tonrate,'ok','MarkerFaceColor','k');
xlabel('median distance from eyes (dva)');
ylabel('mean tonic firing rate (Hz)');
statslin = regstats(tonrate',totaldisteye');
hold on;
plot([min(totaldisteye):0.1:max(totaldisteye)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(totaldisteye):0.1:max(totaldisteye)],'-k');
title({File5,['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']});

subplot(3,2,[2 4]);
plot(totaldisteye,CV,'ok','MarkerFaceColor','k');
xlabel('median distance from eyes (dva)');
ylabel('Coefficient of variation');
statslin = regstats(CV',totaldisteye');
hold on;
plot([min(totaldisteye):0.1:max(totaldisteye)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(totaldisteye):0.1:max(totaldisteye)],'-k');
title(['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_MEDIAN_DIST_EYES_FRATE.jpg'];
pause(5);
screenCapture(saveName2);
clf;


subplot(3,2,[1 3]);
plot(toteyelooking,tonrate,'ok','MarkerFaceColor','k');
xlabel('scanpath length (dva)');
ylabel('mean tonic firing rate (Hz)');
statslin = regstats(tonrate',toteyelooking');
hold on;
plot([min(toteyelooking):0.1:max(toteyelooking)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(toteyelooking):0.1:max(toteyelooking)],'-k');
title({File5,['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']});

subplot(3,2,[2 4]);
plot(toteyelooking,CV,'ok','MarkerFaceColor','k');
xlabel('scanpath length (dva)');
ylabel('Coefficient of variation');
statslin = regstats(CV',toteyelooking');
hold on;
plot([min(toteyelooking):0.1:max(toteyelooking)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(toteyelooking):0.1:max(toteyelooking)],'-k');
title(['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_TOTEYELOOKING_FRATE.jpg'];
pause(5);
screenCapture(saveName2);
clf;



for i=1:length(goodtrial);
    phasicscanlength(i)=sum(goodtrial(i).speed(1:500));
    if length(find(goodtrial(i).spikecut<500))>2;
        isitemp=diff(goodtrial(i).spikecut(find(goodtrial(i).spikecut<500)))/1000;
        CVphase(i)=std(isitemp)/mean(isitemp);
    elseif length(find(goodtrial(i).spikecut<500))==1;
        CVphase(i)=-1;
    else
        CVphase(i)=-2;
    end
    eyeloc=(goodtrial(i).eyecent-[150,150])*PIX2ANG;
    tempdist=sqrt((goodtrial(i).eyexImOn(find(goodtrial(i).scantype(1:500)>0))-eyeloc(1)).^2+(-goodtrial(i).eyeyImOn(find(goodtrial(i).scantype(1:500)>0))-eyeloc(2)).^2);
    totaldisteyePhase(i)=sum(tempdist);
    toteyelookingPhase(i)=length(find(goodtrial(i).scantype(1:500)==1))/length(find(goodtrial(i).scantype(1:500)>0));
    didioo(i)=goodtrial(i).direct;       
end
[tiedrank,r] = tiedrank(CVphase);
subplot(3,2,[1 3]);
plot(toteyelookingPhase(find(didioo==1)),tiedrank(find(didioo==1)),'or','MarkerFaceColor','r');
hold on;
plot(toteyelookingPhase(find(didioo==0)),tiedrank(find(didioo==0)),'ok','MarkerFaceColor','k');
xlabel('percent eye-looking during phasic period');
ylabel('phasic CV rank');
legend({'direct','averted'});
statslin = regstats(tiedrank',toteyelookingPhase');
hold on;
plot([0:0.1:1],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[0:0.1:1],'-k');
title({File5,['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']});


subplot(3,2,[2 4]);
plot(totaldisteyePhase(find(didioo==1)),tiedrank(find(didioo==1)),'or','MarkerFaceColor','r');
hold on;
plot(totaldisteyePhase(find(didioo==0)),tiedrank(find(didioo==0)),'ok','MarkerFaceColor','k');
xlabel('scanpath length during phasic period (dva)');
ylabel('phasic CV rank');
legend({'direct','averted'});
statslin = regstats(tiedrank',totaldisteyePhase');
hold on;
plot([min(totaldisteyePhase):0.1:max(totaldisteyePhase)],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(totaldisteyePhase):0.1:max(totaldisteyePhase)],'-k');
title({File5,['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']});
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_PHASIC_CVs.jpg'];
pause(5);
screenCapture(saveName2);
clf;

subplot(3,3,[1 4]);
[n,ix]=sort(firstSaccade);
for i=1:length(goodtrial);
    if ~isempty(goodtrial(ix(i)).spikecut);
        h=errorbar((goodtrial(ix(i)).spikecut),i*ones(length(goodtrial(ix(i)).spikecut),1,'single'),0.4*ones(length(goodtrial(ix(i)).spikecut),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
        plot(firstSaccade(ix(i)),(i),'*r');
    end
end
axis([0 1500 0 length(goodtrial)+1]);
div3=floor(length(goodtrial)/3);
fastsac=ix(1:div3);
medsac=ix(div3+1:div3*2);
slowsac=ix(2*div3+1:end);
hline([div3,div3*2+1],'-r');
subplot(3,3,7);
plot([0:imonlength],mean(allgauss(fastsac,:))/(gauSize/1000),'-k','Color',[205 127 50]/255,'LineWidth',2);
hold on;
plot([0:imonlength],mean(allgauss(medsac,:))/(gauSize/1000),'-k','Color',[127 0 255]/255,'LineWidth',2);
plot([0:imonlength],mean(allgauss(slowsac,:))/(gauSize/1000),'-k','Color',[0 205 0]/255,'LineWidth',2);
legend({'quick first saccade',  'medium first saccade','slow first saccades'});

sig1=[]; sig2=[];
for i=1:imonlength;
    [p2,h2,stats2]=ranksum(allgauss(fastsac,i),allgauss(slowsac,i));
    pStartPlace(i)=p2;
    if p2<0.01;
        sig2=[sig2,i];
    elseif p2>=0.01 && p2<0.05
        sig1=[sig1,i];
    end
end
if ~isempty(sig1);
    plot(sig1,-0.01,'*k');
end
if ~isempty(sig2);
    plot(sig2,-0.01,'*r');
end

subplot(3,3,[2 5]);
[n,ix]=sort(firstEye);
for i=1:length(goodtrial);
    if ~isempty(goodtrial(ix(i)).spikecut) && ~isnan(firstEye(ix(i)));
        h=errorbar((goodtrial(ix(i)).spikecut),i*ones(length(goodtrial(ix(i)).spikecut),1,'single'),0.4*ones(length(goodtrial(ix(i)).spikecut),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
        plot(firstEye(ix(i)),(i),'*r');
    end
end
axis([0 1500 0 sum(~isnan(firstEye))+1]);
div3=floor(sum(~isnan(firstEye))/3);
fastsac=ix(1:div3);
medsac=ix(div3+1:div3*2);
slowsac=ix(2*div3+1:end);
hline([div3,div3*2+1],'-r');
subplot(3,3,8);
plot([0:imonlength],mean(allgauss(fastsac,:))/(gauSize/1000),'-k','Color',[205 127 50]/255,'LineWidth',2);
hold on;
plot([0:imonlength],mean(allgauss(medsac,:))/(gauSize/1000),'-k','Color',[127 0 255]/255,'LineWidth',2);
plot([0:imonlength],mean(allgauss(slowsac,:))/(gauSize/1000),'-k','Color',[0 205 0]/255,'LineWidth',2);
legend({'quick eye',  'medium eye','slow eye'});

sig1=[]; sig2=[];
for i=1:imonlength;
    [p2,h2,stats2]=ranksum(allgauss(fastsac,i),allgauss(slowsac,i));
    pStartPlace(i)=p2;
    if p2<0.01;
        sig2=[sig2,i];
    elseif p2>=0.01 && p2<0.05
        sig1=[sig1,i];
    end
end
if ~isempty(sig1);
    plot(sig1,-0.01,'*k');
end
if ~isempty(sig2);
    plot(sig2,-0.01,'*r');
end



subplot(3,3,[3 6]);
[n,ix]=sort(firstOther);
for i=1:length(goodtrial);
    if ~isempty(goodtrial(ix(i)).spikecut) && ~isnan(firstOther(ix(i)));
        h=errorbar((goodtrial(ix(i)).spikecut),i*ones(length(goodtrial(ix(i)).spikecut),1,'single'),0.4*ones(length(goodtrial(ix(i)).spikecut),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
        plot(firstOther(ix(i)),(i),'*r');
    end
end
axis([0 1500 0 sum(~isnan(firstOther))+1]);
div3=floor(sum(~isnan(firstOther))/3);
fastsac=ix(1:div3);
medsac=ix(div3+1:div3*2);
slowsac=ix(2*div3+1:end);
hline([div3,div3*2+1],'-r');
subplot(3,3,9);
plot([0:imonlength],mean(allgauss(fastsac,:))/(gauSize/1000),'-k','Color',[205 127 50]/255,'LineWidth',2);
hold on;
plot([0:imonlength],mean(allgauss(medsac,:))/(gauSize/1000),'-k','Color',[127 0 255]/255,'LineWidth',2);
plot([0:imonlength],mean(allgauss(slowsac,:))/(gauSize/1000),'-k','Color',[0 205 0]/255,'LineWidth',2);
legend({'quick other',  'medium other','slow other'});


sig1=[]; sig2=[];
for i=1:imonlength;
    [p2,h2,stats2]=ranksum(allgauss(fastsac,i),allgauss(slowsac,i));
    pStartPlace(i)=p2;
    if p2<0.01;
        sig2=[sig2,i];
    elseif p2>=0.01 && p2<0.05
        sig1=[sig1,i];
    end
end
if ~isempty(sig1);
    plot(sig1,-0.01,'*k');
end
if ~isempty(sig2);
    plot(sig2,-0.01,'*r');
end
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_RESORTED_SPIKETRAINS.jpg'];
pause(5);
screenCapture(saveName2);
clf;

caca=0;
allregEye=[]; allregOth=[];
clear gazeDir frate; t=0;
for i=1:length(goodtrial);
    di=goodtrial(i).direct;
    reggie=goodtrial(i).scantype;
    eyeoreg=zeros(1,1500);
    eyeoreg(find(reggie==1))=1;
    othoreg=zeros(1,1500);
    othoreg(find(reggie==2))=1;
    allregEye=[allregEye;eyeoreg];
    allregOth=[allregOth;othoreg];
    alldi(i)=di;
    if ~isempty(goodtrial(i).eyefixes);
        eyefixes=goodtrial(i).eyefixes;
        for k=1:size(eyefixes,1);
            caca=caca+1;
            gazeDir(caca)=di;
            regLook(caca)=1;
            tempdist=sqrt((goodtrial(i).eyexImOn(eyefixes(k,1)+25)-eyeloc(1)).^2+(-goodtrial(i).eyeyImOn(eyefixes(k,1)+25)-eyeloc(2)).^2);
            distEye(caca)=tempdist;
            durFix(caca)=eyefixes(k,2)-eyefixes(k,1);
            if eyefixes(k,1)<500;
                phasTon(caca)=1;
                fireRate(caca)=sum(goodtrial(i).bincut(eyefixes(k,1):eyefixes(k,2)))/((eyefixes(k,2)-eyefixes(k,1))/1000);
                
                if length(find(goodtrial(i).spikecut>eyefixes(k,1) & goodtrial(i).spikecut<eyefixes(k,2)))>2;
                    tempdiff=diff(goodtrial(i).spikecut(find(goodtrial(i).spikecut>eyefixes(k,1) & goodtrial(i).spikecut<eyefixes(k,2))))/1000;
                    fireRate2(caca)=1/mean(tempdiff);
                elseif length(find(goodtrial(i).spikecut>eyefixes(k,1) & goodtrial(i).spikecut<eyefixes(k,2)))==1;
                    fireRate2(caca)=0;
                else
                    fireRate2(caca)=-1;
                end
            elseif eyefixes(k,1)>=500;
                phasTon(caca)=2;
                fireRate(caca)=sum(goodtrial(i).bincut(eyefixes(k,1):eyefixes(k,2)))/((eyefixes(k,2)-eyefixes(k,1))/1000);
                
                if length(find(goodtrial(i).spikecut>eyefixes(k,1) & goodtrial(i).spikecut<eyefixes(k,2)))>2;
                    tempdiff=diff(goodtrial(i).spikecut(find(goodtrial(i).spikecut>eyefixes(k,1) & goodtrial(i).spikecut<eyefixes(k,2))))/1000;
                    fireRate2(caca)=1/mean(tempdiff);
                elseif length(find(goodtrial(i).spikecut>eyefixes(k,1) & goodtrial(i).spikecut<eyefixes(k,2)))==1;
                    fireRate2(caca)=0;
                else
                    fireRate2(caca)=-1;
                end
            end
        end
    end
    if ~isempty(goodtrial(i).othfixes);
        othfixes=goodtrial(i).othfixes;
        for k=1:size(othfixes,1);
            caca=caca+1;
            gazeDir(caca)=di;
            regLook(caca)=2;
            tempdist=sqrt((goodtrial(i).eyexImOn(othfixes(k,1)+25)-eyeloc(1)).^2+(-goodtrial(i).eyeyImOn(othfixes(k,1)+25)-eyeloc(2)).^2);
            distEye(caca)=tempdist;
            durFix(caca)=othfixes(k,2)-othfixes(k,1);
            if othfixes(k,1)<500;
                phasTon(caca)=1;
                fireRate(caca)=sum(goodtrial(i).bincut(othfixes(k,1):othfixes(k,2)))/((othfixes(k,2)-othfixes(k,1))/1000);
                
                if length(find(goodtrial(i).spikecut>othfixes(k,1) & goodtrial(i).spikecut<othfixes(k,2)))>2;
                    tempdiff=diff(goodtrial(i).spikecut(find(goodtrial(i).spikecut>othfixes(k,1) & goodtrial(i).spikecut<othfixes(k,2))))/1000;
                    fireRate2(caca)=1/mean(tempdiff);
                elseif length(find(goodtrial(i).spikecut>othfixes(k,1) & goodtrial(i).spikecut<othfixes(k,2)))==1;
                    fireRate2(caca)=0;
                else
                    fireRate2(caca)=-1;
                end
            elseif othfixes(k,1)>=500;
                phasTon(caca)=2;
                fireRate(caca)=sum(goodtrial(i).bincut(othfixes(k,1):othfixes(k,2)))/((othfixes(k,2)-othfixes(k,1))/1000);
                
                if length(find(goodtrial(i).spikecut>othfixes(k,1) & goodtrial(i).spikecut<othfixes(k,2)))>2;
                    tempdiff=diff(goodtrial(i).spikecut(find(goodtrial(i).spikecut>othfixes(k,1) & goodtrial(i).spikecut<othfixes(k,2))))/1000;
                    fireRate2(caca)=1/mean(tempdiff);
                elseif length(find(goodtrial(i).spikecut>othfixes(k,1) & goodtrial(i).spikecut<othfixes(k,2)))==1;
                    fireRate2(caca)=0;
                else
                    fireRate2(caca)=-1;
                end
            end
        end
    end
    
end

pae=find(phasTon==1 & gazeDir==0 & regLook==1);
pde=find(phasTon==1 & gazeDir==1 & regLook==1);
pao=find(phasTon==1 & gazeDir==0 & regLook==2);
pdo=find(phasTon==1 & gazeDir==1 & regLook==2);

tae=find(phasTon==2 & gazeDir==0 & regLook==1);
tde=find(phasTon==2 & gazeDir==1 & regLook==1);
tao=find(phasTon==2 & gazeDir==0 & regLook==2);
tdo=find(phasTon==2 & gazeDir==1 & regLook==2);

subplot(2,4,[1 2 5 6]);
plot(mean(allregEye(find(alldi==1),:)),'r','Color',[0 154 208]/255,'LineWidth',2);
hold on;
plot(mean(allregOth(find(alldi==1),:)),'b','Color',[244 144 96]/255,'LineWidth',2);
plot(mean(allregEye(find(alldi==0),:)),'r','Color',[16 78 139]/255,'LineWidth',2);
plot(mean(allregOth(find(alldi==0),:)),'b','Color',[92 51 23]/255,'LineWidth',2);
plot(mean(allgauss)/max(mean(allgauss))-1,'k','LineWidth',2);
axis([1 1500 -1 1]);
legend('prob looking at EYES DIRECT','prob looking at OTHER DIRECT','prob looking at EYES AVERTED','prob looking at OTHER AVERTED','PSTH');
title(File5);

subplot(2,4,3);
plot(distEye([pde pdo]),fireRate([pde pdo]) ,'or','MarkerFaceColor','r');
hold on;
plot(distEye([pae pao]),fireRate([pae pao]) ,'ok','MarkerFaceColor','k');
xlabel('distance from eyes');
ylabel('phasic firing rate during fixation');
legend({'direct','averted'});
statslin = regstats(fireRate([pde pdo pae pao])',distEye([pde pdo pae pao])');
hold on;
plot([min(distEye([pde pdo pae pao])):0.1:max(distEye([pde pdo pae pao]))],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(distEye([pde pdo pae pao])):0.1:max(distEye([pde pdo pae pao]))],'-k');
title(['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']);

subplot(2,4,4);
plot(distEye([tde tdo]),fireRate([tde tdo]) ,'or','MarkerFaceColor','r');
hold on;
plot(distEye([tae tao]),fireRate([tae tao]) ,'ok','MarkerFaceColor','k');
xlabel('distance from eyes');
ylabel('tonic firing rate during fixation');
legend({'direct','averted'});
statslin = regstats(fireRate([tde tdo tae tao])',distEye([tde tdo tae tao])');
hold on;
plot([min(distEye([tde tdo tae tao])):0.1:max(distEye([tde tdo tae tao]))],statslin.tstat.beta(1)+statslin.tstat.beta(2)*[min(distEye([tde tdo tae tao])):0.1:max(distEye([tde tdo tae tao]))],'-k');
title(['R-square: ',num2str(statslin.rsquare),', Beta2: ', num2str(statslin.tstat.beta(2)),' (',num2str(statslin.tstat.pval(2)),')']);

subplot(2,4,[7 8]);
[pFRpeo,hFRpeo,statsFRpeo]=ranksum(fireRate([pae pde]),fireRate([pao,pdo]));
[pFR2peo,hFR2peo,statsFR2peo]=ranksum(fireRate2([pae pde]),fireRate2([pao,pdo]));
[pFRpade,hFRpade,statsFRpade]=ranksum(fireRate([pae]),fireRate([pde]));
[pFR2pade,hFR2pade,statsFR2pade]=ranksum(fireRate2([pae]),fireRate2([pde]));
[pFRpado,hFRpado,statsFRpado]=ranksum(fireRate([pao]),fireRate([pdo]));
[pFR2pado,hFR2pado,statsFR2pado]=ranksum(fireRate2([pao]),fireRate2([pdo]));

[pFRteo,hFRteo,statsFRteo]=ranksum(fireRate([tae tde]),fireRate([tao,tdo]));
[pFR2teo,hFR2teo,statsFR2teo]=ranksum(fireRate2([tae tde]),fireRate2([tao,tdo]));
[pFRtade,hFRtade,statsFRtade]=ranksum(fireRate([tae]),fireRate([tde]));
[pFR2tade,hFR2tade,statsFR2tade]=ranksum(fireRate2([tae]),fireRate2([tde]));
[pFRtado,hFRtado,statsFRtado]=ranksum(fireRate([tao]),fireRate([tdo]));
[pFR2tado,hFR2tado,statsFR2tado]=ranksum(fireRate2([tao]),fireRate2([tdo]));

if ~isfield(statsFRpeo,'zval');
    statsFRpeo.zval=0;
end
if ~isfield(statsFR2peo,'zval');
    statsFR2peo.zval=0;
end
if ~isfield(statsFRpade,'zval');
    statsFRpade.zval=0;
end
if ~isfield(statsFR2pade,'zval');
    statsFR2pade.zval=0;
end
if ~isfield(statsFRpado,'zval');
    statsFRpado.zval=0;
end
if ~isfield(statsFR2pado,'zval');
    statsFR2pado.zval=0;
end
if ~isfield(statsFRteo,'zval');
    statsFRteo.zval=0;
end
if ~isfield(statsFR2teo,'zval');
    statsFR2teo.zval=0;
end
if ~isfield(statsFRtade,'zval');
    statsFRtade.zval=0;
end
if ~isfield(statsFR2tade,'zval');
    statsFR2tade.zval=0;
end
if ~isfield(statsFRtado,'zval');
    statsFRtado.zval=0;
end
if ~isfield(statsFR2tado,'zval');
    statsFR2tado.zval=0;
end

text(0.05,0.5,{['phasic firing profiles'],...
    ['rate EYE vs. OTHER: ',num2str(pFRpeo),' [',num2str(statsFRpeo.zval),']','   (',num2str(median(fireRate([pae pde]))),' , ',num2str(median(fireRate([pao pdo]))),')']...
    ['rate2 EYE vs. OTHER: ',num2str(pFR2peo),' [',num2str(statsFR2peo.zval),']','   (',num2str(median(fireRate2([pae pde]))),' , ',num2str(median(fireRate2([pao pdo]))),')']...
    ['rate DIRECT EYE vs. AVERTED EYE: ',num2str(pFRpade),' [',num2str(statsFRpade.zval),']','   (',num2str(median(fireRate([pde]))),' , ',num2str(median(fireRate([pae]))),')']...
    ['rate2 DIRECT EYE vs. AVERTED EYE: ',num2str(pFR2pade),' [',num2str(statsFR2pade.zval),']','   (',num2str(median(fireRate2([pde]))),' , ',num2str(median(fireRate2([pae]))),')']...
    ['rate DIRECT OTHER vs. AVERTED OTHER: ',num2str(pFRpado),' [',num2str(statsFRpado.zval),']','   (',num2str(median(fireRate([pdo]))),' , ',num2str(median(fireRate([pao]))),')']...
    ['rate2 DIRECT OTHER vs. AVERTED OTHER: ',num2str(pFR2pado),' [',num2str(statsFR2pado.zval),']','   (',num2str(median(fireRate2([pdo]))),' , ',num2str(median(fireRate2([pao]))),')']...
    ['variance in firing rate 1: DIRECT EYE (',num2str(var(fireRate(pde))),'); DIRECT OTHER (',num2str(var(fireRate(pdo))),'); AVERTED EYE (',num2str(var(fireRate(pae))),'); AVERTED OTHER (',num2str(var(fireRate(pao))),')']...
    [''],...
    ['tonic firing profiles'],...
    ['rate EYE vs. OTHER: ',num2str(pFRteo),' [',num2str(statsFRpeo.zval),']','   (',num2str(median(fireRate([tae tde]))),' , ',num2str(median(fireRate([tao tdo]))),')']...
    ['rate2 EYE vs. OTHER: ',num2str(pFR2teo),' [',num2str(statsFR2teo.zval),']','   (',num2str(median(fireRate2([tae tde]))),' , ',num2str(median(fireRate2([tao tdo]))),')']...
    ['rate DIRECT EYE vs. AVERTED EYE: ',num2str(pFRtade),' [',num2str(statsFRtade.zval),']','   (',num2str(median(fireRate([tde]))),' , ',num2str(median(fireRate([tae]))),')']...
    ['rate2 DIRECT EYE vs. AVERTED EYE: ',num2str(pFR2tade),' [',num2str(statsFR2tade.zval),']','   (',num2str(median(fireRate2([tde]))),' , ',num2str(median(fireRate2([tae]))),')']...
    ['rate DIRECT OTHER vs. AVERTED OTHER: ',num2str(pFRtado),' [',num2str(statsFRtado.zval),']','   (',num2str(median(fireRate([tdo]))),' , ',num2str(median(fireRate([tao]))),')']...
    ['rate2 DIRECT OTHER vs. AVERTED OTHER: ',num2str(pFR2tado),' [',num2str(statsFR2tado.zval),']','   (',num2str(median(fireRate2([tdo]))),' , ',num2str(median(fireRate2([tao]))),')']...
    ['variance in firing rate 1: DIRECT EYE (',num2str(var(fireRate(tde))),'); DIRECT OTHER (',num2str(var(fireRate(tdo))),'); AVERTED EYE (',num2str(var(fireRate(tae))),'); AVERTED OTHER (',num2str(var(fireRate(tao))),')']});
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_DIRECTAVERTED_STATS.jpg'];
pause(5);
screenCapture(saveName2);
clf;


%%phasic
[n,xout]=hist(fireRate(pde),[0:0.01:max(fireRate)]);
[n2,xout2]=hist(fireRate(pae),[0:0.01:max(fireRate)]);
directEye=cumsum(n);
avertedEye=cumsum(n2);
subplot(2,2,1);
plot(xout,directEye/max(directEye),'r');
hold on;
plot(xout2,avertedEye/max(avertedEye),'b');
xlabel('phasic mean firing rate during fixation period (Hz)');
ylabel('cumuluative probability of occurrence');
legend({['DIRECT EYE (n=',num2str(length(pde)),')'],['AVERTED EYE (n=',num2str(length(pae)),')']},'Location','SouthEast');
title({File5,['ranksum p-val: ',num2str(pFRpade)]});

[n,xout]=hist(fireRate(tde),[0:0.01:max(fireRate)]);
[n2,xout2]=hist(fireRate(tae),[0:0.01:max(fireRate)]);
directEye=cumsum(n);
avertedEye=cumsum(n2);
subplot(2,2,2);
plot(xout,directEye/max(directEye),'r');
hold on;
plot(xout2,avertedEye/max(avertedEye),'b');
xlabel('tonic mean firing rate during fixation period (Hz)');
ylabel('cumuluative probability of occurrence');
legend({['DIRECT EYE (n=',num2str(length(tde)),')'],['AVERTED EYE (n=',num2str(length(tae)),')']},'Location','SouthEast');
title({['ranksum p-val: ',num2str(pFRtade)]});

[n,xout]=hist(fireRate([pde pae]),[0:0.01:max(fireRate)]);
[n2,xout2]=hist(fireRate([pdo pao]),[0:0.01:max(fireRate)]);
directEye=cumsum(n);
avertedEye=cumsum(n2);
subplot(2,2,3);
plot(xout,directEye/max(directEye),'r');
hold on;
plot(xout2,avertedEye/max(avertedEye),'b');
xlabel('phasic mean firing rate during fixation period (Hz)');
ylabel('cumuluative probability of occurrence');
legend({['EYES (n=',num2str(length([pde pae])),')'],['OTHER (n=',num2str(length([pdo pao])),')']},'Location','SouthEast');
title({['ranksum p-val: ',num2str(pFRpeo)]});

[n,xout]=hist(fireRate([tde tae]),[0:0.01:max(fireRate)]);
[n2,xout2]=hist(fireRate([tdo tao]),[0:0.01:max(fireRate)]);
directEye=cumsum(n);
avertedEye=cumsum(n2);
subplot(2,2,4);
plot(xout,directEye/max(directEye),'r');
hold on;
plot(xout2,avertedEye/max(avertedEye),'b');
xlabel('tonic mean firing rate during fixation period (Hz)');
ylabel('cumuluative probability of occurrence');
legend({['EYES (n=',num2str(length([tde tae])),')'],['OTHER (n=',num2str(length([tdo tao])),')']},'Location','SouthEast');
title({['ranksum p-val: ',num2str(pFRteo)]});

saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_CUMSUMS.jpg'];
pause(5);
screenCapture(saveName2);
clf;




caca=0;
for i=1:length(goodtrial);
    sacstart=goodtrial(i).firstSaccade;
    if ~isnan(sacstart) && sacstart>100;
        caca=caca+1;
        starties(caca)=sacstart;
        saccut{caca}=find(goodtrial(i).bincut(sacstart-100:sacstart+100))-100;
        sacgauss(caca,:)=goodtrial(i).gausscut(sacstart-100:sacstart+100);
        sacgauss2(caca,:)=goodtrial(i).gausscut2(sacstart-100:sacstart+100);
        sacgauss3(caca,:)=goodtrial(i).gausscut3(sacstart-100:sacstart+100);
        validtrials(caca)=i;
    end
end
clear newgauss;
newgauss=allgauss(validtrials,:);
newgauss2=allgauss2(validtrials,:);
newgauss3=allgauss3(validtrials,:);

for i=1:1000;
    clear gausstemp;
    randshuff=randperm(length(validtrials));
    suffsacs=starties(randshuff);
    for j=1:length(suffsacs);
        guasstemp(j,:)=newgauss(j,suffsacs(j)-100:suffsacs(j)+100);
        guasstemp2(j,:)=newgauss2(j,suffsacs(j)-100:suffsacs(j)+100);
        guasstemp3(j,:)=newgauss3(j,suffsacs(j)-100:suffsacs(j)+100);
    end
    shuffmeanGauss(i,:)=mean(guasstemp);
    shuffmeanGauss2(i,:)=mean(guasstemp2);
    shuffmeanGauss3(i,:)=mean(guasstemp3);
end

subplot(3,2,[1 3]);
for i=1:length(saccut);
    if ~isempty(saccut{i});
        h=errorbar((saccut{i}),(i)*ones(length(saccut{i}),1,'single'),0.4*ones(length(saccut{i}),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([-100 100 0 length(saccut)+1]);
xlabel('time from first saccade (ms)');
title([File5,'  50 ms gauss, first saccade']);

subplot(3,2,5);
bar([-100:100],mean(sacgauss)/(gauSize/1000),'k');
axis([-100 100 0 max([(mean(sacgauss)),mean(shuffmeanGauss)]/(gauSize/1000))+0.01]);
xlabel('time from first saccade (ms)');
ylabel('mean firing rate (Hz)');

subplot(3,2,2);
[n2,xout2]=hist(starties,[0:500]);
bar(xout2,n2,'k');
axis([0 500 0 max(n2)+1]);
xlabel('latency of first saccades from image on (ms)');
ylabel('count');

meansac=mean(sacgauss);
subplot(3,2,4);
for i=1:length(mean(sacgauss));
    perc(i)=length(find(shuffmeanGauss(:,i)<=meansac(i)))/1000;
end
rectangle('Position',[-100 0 201 1],'FaceColor','g');
hold on;
k=bar([-100:100],perc,'m');
set(k,'EdgeColor','m');
axis([-100 100 0 1]);
hline([0.05 0.95],'k');
xlabel('time from first saccade (ms)');
ylabel('portion of cases with lower firing rate than experimental data');

subplot(3,2,6);
bar([-100:100],mean(shuffmeanGauss)/(gauSize/1000),'k');
axis([-100 100 0 max([(mean(sacgauss)),mean(shuffmeanGauss)]/(gauSize/1000))+0.01]);
xlabel('time from first saccade (ms)');
ylabel('mean firing rate suffled data (Hz)');

pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SACCADE_CUTS_FIRST50_',num2str(j+1),'.jpg'];
screenCapture(saveName2);
clf;


subplot(3,2,[1 3]);
for i=1:length(saccut);
    if ~isempty(saccut{i});
        h=errorbar((saccut{i}),(i)*ones(length(saccut{i}),1,'single'),0.4*ones(length(saccut{i}),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([-100 100 0 length(saccut)+1]);
xlabel('time from first saccade (ms)');
title([File5,'  20 ms gauss, first saccade']);

subplot(3,2,5);
bar([-100:100],mean(sacgauss2)/(gauSize2/1000),'k');
axis([-100 100 0 max([(mean(sacgauss2)),mean(shuffmeanGauss2)]/(gauSize2/1000))+0.01]);
xlabel('time from first saccade (ms)');
ylabel('mean firing rate (Hz)');

subplot(3,2,2);
[n2,xout2]=hist(starties,[0:500]);
bar(xout2,n2,'k');
axis([0 500 0 max(n2)+1]);
xlabel('latency of first saccades from image on (ms)');
ylabel('count');

meansac2=mean(sacgauss3);
subplot(3,2,4);
for i=1:length(mean(sacgauss3));
    perc(i)=length(find(shuffmeanGauss2(:,i)<=meansac2(i)))/1000;
end
rectangle('Position',[-100 0 201 1],'FaceColor','g');
hold on;
k=bar([-100:100],perc,'m');
set(k,'EdgeColor','m');
axis([-100 100 0 1]);
hline([0.05 0.95],'k');
xlabel('time from first saccade (ms)');
ylabel('portion of cases with lower firing rate than experimental data');

subplot(3,2,6);
bar([-100:100],mean(shuffmeanGauss2)/(gauSize2/1000),'k');
axis([-100 100 0 max([(mean(sacgauss2)),mean(shuffmeanGauss2)]/(gauSize2/1000))+0.01]);
xlabel('time from first saccade (ms)');
ylabel('mean firing rate suffled data (Hz)');

pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SACCADE_CUTS_FIRST20_',num2str(j+1),'.jpg'];
screenCapture(saveName2);
clf;





caca=0; caca2=0;
for i=1:length(goodtrial);
    sacstart=goodtrial(i).sacstart;
    if ~isempty(sacstart);
        for t=1:length(sacstart);
            if sacstart(t)>500 && sacstart(t)<1400;
                caca=caca+1;
                starties(caca)=sacstart(t);
                saccut{caca}=find(goodtrial(i).bincut(sacstart(t)-100:sacstart(t)+100))-100;
                sacgauss(caca,:)=goodtrial(i).gausscut(sacstart(t)-100:sacstart(t)+100);
                sacgauss2(caca,:)=goodtrial(i).gausscut2(sacstart(t)-100:sacstart(t)+100);
                sacgauss3(caca,:)=goodtrial(i).gausscut3(sacstart(t)-100:sacstart(t)+100);
                validtrials(caca)=i;
            end
            if sacstart(t)>100 && sacstart(t)<1400;
                caca2=caca2+1;
                ALLstarties(caca2)=sacstart(t);
                ALLsaccut{caca2}=find(goodtrial(i).bincut(sacstart(t)-100:sacstart(t)+100))-100;
                ALLsacgauss(caca2,:)=goodtrial(i).gausscut(sacstart(t)-100:sacstart(t)+100);
                ALLsacgauss2(caca2,:)=goodtrial(i).gausscut2(sacstart(t)-100:sacstart(t)+100);
                ALLsacgauss3(caca2,:)=goodtrial(i).gausscut3(sacstart(t)-100:sacstart(t)+100);
                ALLvalidtrials(caca2)=i;
            end
        end
    end
end
clear newgauss;
newgauss=allgauss(validtrials,:);
newgauss2=allgauss2(validtrials,:);
newgauss3=allgauss3(validtrials,:);
ALLnewgauss=allgauss(ALLvalidtrials,:);
ALLnewgauss2=allgauss2(ALLvalidtrials,:);
ALLnewgauss3=allgauss3(ALLvalidtrials,:);

for i=1:1000;
    clear gausstemp;
    randshuff=randperm(length(validtrials));
    suffsacs=starties(randshuff);
    for j=1:length(suffsacs);
        guasstemp(j,:)=newgauss(j,suffsacs(j)-100:suffsacs(j)+100);
        guasstemp2(j,:)=newgauss2(j,suffsacs(j)-100:suffsacs(j)+100);
        guasstemp3(j,:)=newgauss3(j,suffsacs(j)-100:suffsacs(j)+100);
    end
    shuffmeanGauss(i,:)=mean(guasstemp);
    shuffmeanGauss2(i,:)=mean(guasstemp2);
    shuffmeanGauss3(i,:)=mean(guasstemp3);
    
     ALLrandshuff=randperm(length(ALLvalidtrials));
    ALLsuffsacs=ALLstarties(ALLrandshuff);
    for j=1:length(ALLsuffsacs);
        ALLguasstemp(j,:)=ALLnewgauss(j,ALLsuffsacs(j)-100:ALLsuffsacs(j)+100);
        ALLguasstemp2(j,:)=ALLnewgauss2(j,ALLsuffsacs(j)-100:ALLsuffsacs(j)+100);
        ALLguasstemp3(j,:)=ALLnewgauss3(j,ALLsuffsacs(j)-100:ALLsuffsacs(j)+100);
    end
    ALLshuffmeanGauss(i,:)=mean(ALLguasstemp);
    ALLshuffmeanGauss2(i,:)=mean(ALLguasstemp2);
    ALLshuffmeanGauss3(i,:)=mean(ALLguasstemp3);
    
    
end


subplot(3,2,[1 3]);
for i=1:length(saccut);
    if ~isempty(saccut{i});
        h=errorbar((saccut{i}),(i)*ones(length(saccut{i}),1,'single'),0.4*ones(length(saccut{i}),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([-100 100 0 length(saccut)+1]);
xlabel('time from tonic saccades (ms)');
title([File5,'  50 ms gauss, tonic saccades']);

subplot(3,2,5);
bar([-100:100],mean(sacgauss)/(gauSize/1000),'k');
axis([-100 100 0 max([(mean(sacgauss)),mean(shuffmeanGauss)]/(gauSize/1000))+0.01]);
xlabel('time from tonic saccades (ms)');
ylabel('mean firing rate (Hz)');

subplot(3,2,2);
[n2,xout2]=hist(starties,[0:1500]);
bar(xout2,n2,'k');
axis([0 1500 0 max(n2)+1]);
xlabel('latency of saccades from image on (ms)');
ylabel('count');

meansac=mean(sacgauss);
subplot(3,2,4);
for i=1:length(mean(sacgauss));
    perc(i)=length(find(shuffmeanGauss(:,i)<=meansac(i)))/1000;
end
rectangle('Position',[-100 0 201 1],'FaceColor','g');
hold on;
k=bar([-100:100],perc,'m');
set(k,'EdgeColor','m');
axis([-100 100 0 1]);
hline([0.05 0.95],'k');
xlabel('time from tonic saccades (ms)');
ylabel('portion of cases with lower firing rate than experimental data');

subplot(3,2,6);
bar([-100:100],mean(shuffmeanGauss)/(gauSize/1000),'k');
axis([-100 100 0 max([(mean(sacgauss)),mean(shuffmeanGauss)]/(gauSize/1000))+0.01]);
xlabel('time from tonic saccades (ms)');
ylabel('mean firing rate suffled data (Hz)');

pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SACCADE_CUTS-TONIC50_',num2str(j+1),'.jpg'];
screenCapture(saveName2);
clf;


subplot(3,2,[1 3]);
for i=1:length(saccut);
    if ~isempty(saccut{i});
        h=errorbar((saccut{i}),(i)*ones(length(saccut{i}),1,'single'),0.4*ones(length(saccut{i}),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([-100 100 0 length(saccut)+1]);
xlabel('time from tonic saccades (ms)');
title([File5,'  20 ms gauss, tonic saccades']);

subplot(3,2,5);
bar([-100:100],mean(sacgauss2)/(gauSize2/1000),'k');
axis([-100 100 0 max([(mean(sacgauss2)),mean(shuffmeanGauss2)]/(gauSize2/1000))+0.01]);
xlabel('time from tonic saccades (ms)');
ylabel('mean firing rate (Hz)');

subplot(3,2,2);
[n2,xout2]=hist(starties,[0:1500]);
bar(xout2,n2,'k');
axis([0 1500 0 max(n2)+1]);
xlabel('latency of saccades from image on (ms)');
ylabel('count');

meansac2=mean(sacgauss2);
subplot(3,2,4);
for i=1:length(mean(sacgauss2));
    perc(i)=length(find(shuffmeanGauss2(:,i)<=meansac2(i)))/1000;
end
rectangle('Position',[-100 0 201 1],'FaceColor','g');
hold on;
k=bar([-100:100],perc,'m');
set(k,'EdgeColor','m');
axis([-100 100 0 1]);
hline([0.05 0.95],'k');
xlabel('time from tonic saccades (ms)');
ylabel('portion of cases with lower firing rate than experimental data');

subplot(3,2,6);
bar([-100:100],mean(shuffmeanGauss2)/(gauSize2/1000),'k');
axis([-100 100 0 max([(mean(sacgauss2)),mean(shuffmeanGauss2)]/(gauSize2/1000))+0.01]);
xlabel('time from tonic saccades (ms)');
ylabel('mean firing rate suffled data (Hz)');

pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SACCADE_CUTS_TONIC20_',num2str(j+1),'.jpg'];
screenCapture(saveName2);
clf;

subplot(3,2,[1 3]);
for i=1:length(ALLsaccut);
    if ~isempty(ALLsaccut{i});
        h=errorbar((ALLsaccut{i}),(i)*ones(length(ALLsaccut{i}),1,'single'),0.4*ones(length(ALLsaccut{i}),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([-100 100 0 length(ALLsaccut)+1]);
xlabel('time from ALL saccades (ms)');
title([File5,'  50 ms gauss, ALL saccades']);

subplot(3,2,5);
bar([-100:100],mean(ALLsacgauss)/(gauSize/1000),'k');
axis([-100 100 0 max([(mean(ALLsacgauss)),mean(ALLshuffmeanGauss)]/(gauSize/1000))+0.01]);
xlabel('time from all saccades(ms)');
ylabel('mean firing rate (Hz)');

subplot(3,2,2);
[n2,xout2]=hist(ALLstarties,[0:1500]);
bar(xout2,n2,'k');
axis([0 1500 0 max(n2)+1]);
xlabel('latency of saccades from image on (ms)');
ylabel('count');

ALLmeansac=mean(ALLsacgauss);
subplot(3,2,4);
for i=1:length(ALLmeansac);
    perc(i)=length(find(ALLshuffmeanGauss(:,i)<=ALLmeansac(i)))/1000;
end
rectangle('Position',[-100 0 201 1],'FaceColor','g');
hold on;
k=bar([-100:100],perc,'m');
set(k,'EdgeColor','m');
axis([-100 100 0 1]);
hline([0.05 0.95],'k');
xlabel('time from all saccades (ms)');
ylabel('portion of cases with lower firing rate than experimental data');

subplot(3,2,6);
bar([-100:100],mean(shuffmeanGauss)/(gauSize/1000),'k');
axis([-100 100 0 max([(mean(sacgauss)),mean(shuffmeanGauss)]/(gauSize/1000))+0.01]);
xlabel('time from all saccades (ms)');
ylabel('mean firing rate suffled data (Hz)');

pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SACCADE_CUTS_ALL50_',num2str(j+1),'.jpg'];
screenCapture(saveName2);
clf;



subplot(3,2,[1 3]);
for i=1:length(ALLsaccut);
    if ~isempty(ALLsaccut{i});
        h=errorbar((ALLsaccut{i}),(i)*ones(length(ALLsaccut{i}),1,'single'),0.4*ones(length(ALLsaccut{i}),1,'single'),'LineStyle','none','Color','k','LineWidth',2);
        errorbar_tick(h,0);
        hold on;
    end
end
axis([-100 100 0 length(ALLsaccut)+1]);
xlabel('time from ALL saccades (ms)');
title([File5,'  20 ms gauss, ALL saccades']);

subplot(3,2,5);
bar([-100:100],mean(ALLsacgauss2)/(gauSize2/1000),'k');
axis([-100 100 0 max([(mean(ALLsacgauss2)),mean(ALLshuffmeanGauss2)]/(gauSize2/1000))+0.01]);
xlabel('time from all saccades (ms)');
ylabel('mean firing rate (Hz)');

subplot(3,2,2);
[n2,xout2]=hist(ALLstarties,[0:1500]);
bar(xout2,n2,'k');
axis([0 1500 0 max(n2)+1]);
xlabel('latency of saccades from image on (ms)');
ylabel('count');

ALLmeansac2=mean(ALLsacgauss2);
subplot(3,2,4);
for i=1:length(ALLmeansac2);
    perc(i)=length(find(ALLshuffmeanGauss2(:,i)<=ALLmeansac2(i)))/1000;
end
rectangle('Position',[-100 0 201 1],'FaceColor','g');
hold on;
k=bar([-100:100],perc,'m');
set(k,'EdgeColor','m');
axis([-100 100 0 1]);
hline([0.05 0.95],'k');
xlabel('time from all saccades (ms)');
ylabel('portion of cases with lower firing rate than experimental data');

subplot(3,2,6);
bar([-100:100],mean(shuffmeanGauss2)/(gauSize2/1000),'k');
axis([-100 100 0 max([(mean(sacgauss2)),mean(shuffmeanGauss2)]/(gauSize2/1000))+0.01]);
xlabel('time from all saccades (ms)');
ylabel('mean firing rate suffled data (Hz)');

pause(5);
saveName2=['F:\scanpath_neurons',Path5(17:end),File5(1:end-4),'_SACCADE_CUTS_ALL20_',num2str(j+1),'.jpg'];
screenCapture(saveName2);
clf;