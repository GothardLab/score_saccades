%cal=calibrateEye(eye daya file path, calibration item file path, pplot)
%scaling factor/conversion between cortex units and visual angle
function cal = calibrateEye(fpath,fpathitm,lowlimit,uplimit,pplot,CTX2ANG) %visual angle per cortex unit
%--------------------------------------------------

[cal.x,cal.y,time] = downsampleeyes(fpath);

sr = (1/mean(diff(time)))*1000; %sampling rate for eye data

timestart = time(1);

%% Read in channel 32 markers/times
fid = fopen(fpath);
ch32 = SONGetMarkerChannel(fid, 32);
mkrs = ch32.markers(:,1);
tims = ch32.timings;

mkrs=mkrs(find(tims>lowlimit & tims<uplimit));
tims=tims(find(tims>lowlimit & tims<uplimit));

a8 = findvec([8 0 19 0 20 0 3 0],mkrs);

numtrial = length(a8);

for i=1:numtrial
    cond(i) = GetCndNum(mkrs([a8(i)-2:a8(i)-1]));
end

itm = readitmfile(fpathitm,3:4);
maxcond = max(cond);
condx = [itm{2:maxcond+1,2}]; condy = [itm{2:maxcond+1,3}];

for i = 1:numtrial
    condxord(i) = condx(cond(i));
    condyord(i) = condy(cond(i));
end

ctimebeg = tims(a8);
ctimeend = tims(a8)+0.5; %to end_pause
cbinbeg = round((ctimebeg+0.20)*sr);
cbinend = round((ctimeend)*sr);

%%
for i = 1:numtrial %calculate calibration averages
%     if cbinbeg(i)>0
        calavgx(i) = mean(cal.x(cbinbeg(i):cbinend(i)));
        calavgy(i) = mean(cal.y(cbinbeg(i):cbinend(i)));
%     end
end

%get the trial index for each of the conditions on the horizontal axis
xtrialindex=find(condyord==0);
ytrialindex=find(condxord==0);

allpointsxX=calavgx(xtrialindex);
allpointsxY=calavgy(xtrialindex);
allpointsyX=calavgx(ytrialindex);
allpointsyY=calavgy(ytrialindex);

%calibration conversion factor
cuex = unique(condxord); cuey = unique(condyord); %(spike2 unit)/(cortex unit)

tempx = polyfit(allpointsxX,allpointsxY,1); %fit line to cal points on x-axis
tempy = polyfit(allpointsyX,allpointsyY,1); %fit line to cal points on y-axis

intersect(1) = (tempy(2) - tempx(2))/(tempx(1) - tempy(1));
intersect(2) = tempx(1)*intersect(1) + tempx(2);

ex = [allpointsxX-intersect(1);allpointsxY-intersect(2)];
ey = [allpointsyX-intersect(1);allpointsyY-intersect(2)];

rotang = atand(tempx(1)); %angle that data should be rotated

if tempx(1)>0
    rotmat = [cosd(rotang) -sind(rotang); sind(rotang) cosd(rotang)];
else
    rotmat = [cosd(rotang) sind(rotang); -sind(rotang) cosd(rotang)];
end

ex = rotmat*ex; %rotate eye data for cal poitns
ey = rotmat*ey; %rotate eye data for cal points

cuex = condxord(xtrialindex)*CTX2ANG; cuey = condyord(ytrialindex)*CTX2ANG;
p1 = polyfit(ex(1,:),cuex,1); p2 = polyfit(ey(2,:),cuey,1);

scale = [p1(1),p2(1)];
bias = [p1(2) p2(2)];

cal.param = [bias;scale];
cal.rotmat = rotmat;
cal.intersect = intersect;

calpts = [calavgx;calavgy];

xy = cal.rotmat*[(calpts(1,:)-cal.intersect(1));(calpts(2,:)-cal.intersect(2))];
x = xy(1,:)*cal.param(2,1)+cal.param(1,1);
y = xy(2,:)*cal.param(2,2)+cal.param(1,2);


if pplot
    clf;
    plot(x,y,'.');
    hold on;
    title(['calparam: ',num2str(cal.param(1,:)),'     ',num2str(cal.param(2,:))]);
    plot(cuex,zeros(1,length(cuex)),'ro');
    plot(zeros(1,length(cuey)),cuey,'ro');
    axis equal;
end