
function [pair, nEvents, nTS] = Encode2HiLo(path,sTime,eTime)
ranges = [0:50, 1000:1100];
threshold = 0.006;
%path = 'C:\Users\bamboo\Documents\MATLAB\spk\zin\2013\neurophys\020613\z020613_calib_images_trec.smr';
%path = 'C:\Users\bamboo\Documents\MATLAB\sfm\smr\081010\081010movies_eeg.smr';
fid=fopen(path);


[Allheader]=SONFileHeader(fid);
[ChanList]=SONChanList(fid);

for i=1:length(ChanList) %excludes blank keyboard channel 31%
    number=ChanList(1,i).number;   %get the number of the current channel
    name=[ChanList(1,i).title];    %get the name of the current channel
    if number==32;  %if the channel number is 32
        info=[ChanList(1,i).title,'_info'];    %get information (e.g. sample rate) for chan 32
        [Chan32.data,Chan32.info]=SONGetMarkerChannel(fid, number); %get the times of the chan 32 markers
        Chan32.data.markers(:,2:4)=[];  %only take the first column of markers (the rest are just superfluos zeros)
    end
end


events=Chan32.data.markers;
ts=Chan32.data.timings;

if sTime ~= 0 && eTime ~= 0 
    
events(find(ts<sTime | ts>eTime))=[];
ts(find(ts<sTime | ts>eTime))=[];

end

for tsDEX = 1:size(ts,1) %fill byte structure
    byte(tsDEX).paired = 0;
    byte(tsDEX).code = events(tsDEX);
    byte(tsDEX).time = ts(tsDEX);
end

if ~mod(size(events,1),2)
    [pair, sucess] =  simplePair(ts, events, ranges, threshold);
    
    if ~sucess
        clear pair
        [pair, sucess] =  nearPair(ts, events, ranges, threshold);
    end
else
    [pair, sucess] =  nearPair(ts, events, ranges, threshold);
end

 nEvents = nan(size(pair,2),1);
 nTS = nan(size(pair,2),1);
for i = 1:size(pair,2)
    nEvents(i)=pair(i).coBYTE;
    nTS(i)=pair(i).loTS;
    %fprintf('Index:%4d\tHi:%3d\tLo:%3d\tCo:%4d\n',pair(i).coDEX, pair(i).hiBYTE, pair(i).loBYTE, pair(i).coBYTE);
end

end


function [pair, sucess] =  simplePair(ts, events, ranges, threshold)

pairCOUNT = 0;
sucess = 1;

for pairDEX = 1:2:size(ts,1)
    
    pairCOUNT = pairCOUNT +1;
    
    pair(pairCOUNT).hiDEX = pairDEX+1;
    pair(pairCOUNT).loDEX = pairDEX;
    pair(pairCOUNT).hiBYTE = events(pairDEX+1);
    pair(pairCOUNT).loBYTE = events(pairDEX);
    pair(pairCOUNT).hiTS = ts(pairDEX+1);
    pair(pairCOUNT).loTS = ts(pairDEX);
    
    pair(pairCOUNT).coBYTE  = (double(pair(pairCOUNT).loBYTE)) + (double(pair(pairCOUNT).hiBYTE)*256);
    pair(pairCOUNT).coTS = pair(pairCOUNT).loTS;
    pair(pairCOUNT).coDEX = pairCOUNT;
    
    if ~ismember(pair(pairCOUNT).coBYTE, ranges)
        %fprintf('ERROR:\tSimple pairing failed (Calculated encode %d out of range)\n',pair(pairCOUNT).coBYTE);
        sucess = 0;
        pair(1).fail = 1;
        break
    elseif pair(pairCOUNT).hiBYTE >  pair(pairCOUNT).loBYTE
        %fprintf('WARNING:\t High byte (%d) is greater than the low bye (%d)\n', pair(pairCOUNT).hiBYTE, pair(pairCOUNT).loBYTE);
    elseif abs(pair(pairCOUNT).hiTS-pair(pairCOUNT).loTS) >= threshold
        %fprintf('ERROR:\tSimple pairing failed (Gap of %f between codes at %d and %d)\n', abs(pair(pairCOUNT).hiTS-pair(pairCOUNT).loTS), pairDEX, (pairDEX+1));
        sucess = 0;
        pair(1).fail = 1;
        break
    end
end
end












function [pair, sucess] =  nearPair(ts, events, ranges, threshold)

    sucess = 1;
    paircount = 0;

    h = waitbar(0,'Please wait...');

    for tsDEX = 1:size(ts,1)
        waitbar(tsDEX / size(ts,1),h,sprintf('Finding nearest match for event:%d',tsDEX));
        tsTEMP = ts;
        tsTEMP(tsDEX) = NaN;%999999999999;

        nearestDEX = knnsearch(tsTEMP,ts(tsDEX));

        %fprintf('Point index %d @ time %f was paired with point index %d @ time %f\n', tsDEX, ts(tsDEX), nearestDEX, ts(nearestDEX));

        near(tsDEX).nearest = nearestDEX;
        near(tsDEX).diff = abs(ts(tsDEX)-ts(nearestDEX));
        near(tsDEX).matched = 0;
    end
    close(h);

    for tsDEX = 1:size(near,2)
        %fprintf('\n');
         loBYTE =0;
        loDEX  =0;
        loTS  =0;
        hiBYTE  =0;
        hiDEX  =0;
        hiTS  =0;
        coBYTE =0;
        
         %fprintf('At index:%4d time:%f code: %3d:\n',tsDEX, ts(tsDEX), events(tsDEX)); 

        if tsDEX ~= 1 &&  tsDEX ~= size(near,2)
            back =  near(tsDEX-1);
            back.index = tsDEX-1;

            current = near(tsDEX);
            current.index = tsDEX;

            forward = near(tsDEX+1);
            forward.index = tsDEX+1;

            match =  near(near(tsDEX).nearest);
            match.index = near(tsDEX).nearest;
        elseif tsDEX == 1
            back.nearest = 0;
            back.diff = 9999999999;
            back.index = 9999999999;
            back.matched = 1;


            current = near(tsDEX);
            current.index = tsDEX;

            forward = near(tsDEX+1);
            forward.index = tsDEX+1;
            forward.index = tsDEX+1;

            match = near(near(tsDEX).nearest);
            match.index = near(tsDEX).nearest;
        elseif tsDEX == size(near,2)
            back =  near(tsDEX-1);
            back.index = tsDEX-1;

            current = near(tsDEX);
            current.index = tsDEX;

            match = near(near(tsDEX).nearest);
            match.index = near(tsDEX).nearest;

            forward.nearest = 0;
            forward.diff = 9999999999;
            forward.index = 9999999999;
            forward.matched = 1;
        end

      if ~current.matched
          if forward.index == match.index && match.nearest == current.index && back.matched == 1 && inRange(events(current.index),  events(match.index), ranges)
              %fprintf('\tClean match to next and the one behind is unmatched\n');
              %Clean match to next and the one behind is unmatched
              hiBYTE = events(match.index);
              loBYTE = events(current.index);
              hiTS = ts(match.index);
              loTS = ts(current.index);
              hiDEX = match.index;
              loDEX = current.index;
              coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);
              
              near(hiDEX).matched = 1;
              near(loDEX).matched = 1;

              
          elseif back.index == match.index && match.nearest == current.index && forward.nearest ~= current.index && inRange(events(match.index), events(current.index), ranges)
              %fprintf('\tClean match to previous and the next one behind is not a match\n');
              %Clean match to previous and the next one behind isn't a match
              loBYTE = events(match.index);
              hiBYTE = events(current.index);
              loTS = ts(match.index);
              hiTS = ts(current.index);
              loDEX = match.index;
              hiDEX = current.index;
              coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);
              
              near(hiDEX).matched = 1;
              near(loDEX).matched = 1;


          elseif forward.index == match.index && match.nearest ~= current.index
              %Match to the forward code, however it's match isn't to us
              %fprintf('\tMatch to the forward code, however its match is not to us\n')
              if match.nearest == match.index + 1 && near(match.index + 1).nearest == match.index
                  %Our match also has another match down the line
                  %fprintf('\tOur match also has another match down the line\n');

                   if near(match.index + 2).nearest == match.index + 1 && back.matched == 1 && inRange(events(current.index),  events(match.index), ranges)
                       %Our match's matching match has a second match
                       %fprintf('\tOur matchs matching match has a second match\n');
                        hiBYTE = events(match.index);
                          loBYTE = events(current.index);
                          hiTS = ts(match.index);
                          loTS = ts(current.index);
                          hiDEX = match.index;
                          loDEX = current.index;
                          coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);

                          near(hiDEX).matched = 1;
                          near(loDEX).matched = 1;



                   else
                       %Spurious code
                       %fprintf('\tissue\n');
                   end
              elseif match.nearest == match.index + 1 && near(match.index + 1).nearest ~= match.index  && back.matched == 1 && inRange(events(current.index),  events(match.index), ranges)
                 %fprintf('\tOur matchs match does not match to it\n'); 
                 
                 hiBYTE = events(match.index);
                          loBYTE = events(current.index);
                          hiTS = ts(match.index);
                          loTS = ts(current.index);
                          hiDEX = match.index;
                          loDEX = current.index;
                          coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);

                          near(hiDEX).matched = 1;
                          near(loDEX).matched = 1;
              end
          elseif forward.nearest == current.index  && near(forward.index+1).nearest ~= forward.index && back.matched == 1 && inRange(events(current.index),  events(match.index), ranges)
              %fprintf('\tUnclean match to one ahead.\n');
              
              hiBYTE = events(forward.index);
              loBYTE = events(current.index);
              hiTS = ts(forward.index);
              loTS = ts(current.index);
              hiDEX = forward.index;
              loDEX = current.index;
              coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);
              
              near(hiDEX).matched = 1;
              near(loDEX).matched = 1;
          elseif back.index == match.index && match.nearest ~= current.index && forward.nearest == current.index && back.matched == 1 && inRange(events(current.index),  events(forward.index), ranges)
             %fprintf('\tMatch to one behind, but it is already matched and next matches to us.\n');
              
               hiBYTE = events(forward.index);
              loBYTE = events(current.index);
              hiTS = ts(forward.index);
              loTS = ts(current.index);
              hiDEX = forward.index;
              loDEX = current.index;
              coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);
              
              near(hiDEX).matched = 1;
              near(loDEX).matched = 1;
             
          elseif match.index == back.index && back.matched == 1 && forward.nearest == current.index  && inRange(events(current.index),  events(forward.index), ranges)
              
               hiBYTE = events(forward.index);
              loBYTE = events(current.index);
              hiTS = ts(forward.index);
              loTS = ts(current.index);
              hiDEX = forward.index;
              loDEX = current.index;
              coBYTE = (double(loBYTE)) + (double(hiBYTE)*256);
              
              near(hiDEX).matched = 1;
              near(loDEX).matched = 1;
          else
              %fprintf('\tNo match\n'); 
          end

          %Pair them
          if loDEX ~= 0 
              %fprintf('\tPairing c:3%d i:4%d t:%f to c:%3d i:%4d t:%f\t->\t%4d\n',loBYTE,loDEX,loTS,hiBYTE,hiDEX,hiTS,coBYTE);
              paircount=paircount+1;
              
              pair(paircount).hiBYTE=hiBYTE;
              pair(paircount).loBYTE=loBYTE;
              pair(paircount).hiTS=hiTS;
              pair(paircount).loTS=loTS;
              pair(paircount).hiDEX=hiDEX;
              pair(paircount).loDEX=loDEX;
              pair(paircount).coBYTE=coBYTE;
              pair(paircount).coTS=loTS;
              pair(paircount).coDEX=paircount;
              
              
              
              pause(.1);
          end

      else
          %fprintf('\tAlready matched\n'); 
      end

      clear loBYTE loDEX loTS hiBYTE hiDEX hiTS coBYTE back current foward match
    end


    for tsDEX = 1:size(near,2)
        
        if  near(tsDEX).matched ==0
            %fprintf('ERROR:\tNearest pairing failed (Encode %d (Index:%d) is left unpaired)\n',events(tsDEX), tsDEX);
            sucess = 0;
        end
        
    end
end

function [bool] =  inRange(lo, hi, ranges)
    co  = (double(lo) + (double(hi)*256));
    bool = ismember(co, ranges);
    
    if ~bool
        %fprintf('\tPotential pairing creates out of range %d & %d -> %d\n', lo, hi, co);
        %fprintf('');
    end
end
 