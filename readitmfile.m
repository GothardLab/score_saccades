%function y = readitmfile(x) 
%function y = readitmfile(x,columns)--> if want additional columns read
% modified from original syntax y = readitmfile(x) by Haiyin
% input columns specify the additional columns to be read
function y = readitmfile(x,varargin)
warning('off','MATLAB:deblank:NonStringInput')
if nargin > 1, columns = varargin{1};
    morecol = length(columns);
else morecol = 0; end
% Takes a text file written in columns and transforms it into a cell array from which columns of interest might be extracted.
% 
% if nargin ~= 1 | ~isstr(x)
%      error(' You need to write syntax: \n y = readtxtcolumns(<filename>) \n Note the filename must be in column format and between single quotes ');
%      return
% end

y = {};
nrows = 0;
fid = fopen(x,'r');

if isempty(fid) | fid == -1
    fprintf('\n The file is empty or could not open the file. \n You may want to check your path. \n');
    return
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read next line until the end of the file
while 1
   thisline = deblank(fgetl(fid));
   if isempty(thisline) |  isnumeric(thisline) %sometimes after the last line thisline = -1
       break
   end    

   % update row and column counters, initialize the column cell array
   nrows = nrows +1;
   ncols = 0;
   colugnas = {};
  
  % read the row to a cell array with "ncols" entries, one for each column 
  while ~isempty(thisline)    
       ncols = ncols + 1;      
       [colugnas{ncols},thisline] = strtok(thisline);       
  end
 
  % check that the header line is correct and record the tag names
  if nrows ==1  
          if ~strcmp(colugnas{1},'ITEM')
              error('First field in itm-file must be "ITEM"');
              break
          end
          y{1,1}=colugnas{1};
          if strcmp(colugnas{ncols},'------FILENAME------')              
              y{1,2+morecol}=colugnas{ncols};
          end  
  end       
  
  % look for the first item in the experiment
  if nrows >1 
      c1=str2num(colugnas{1});
      if c1 ==1
          nrows = 2;
      end
      if c1>0
          y{nrows,1}=c1;
%           if find(colugnas{end}=='\') ~=0
%               colugnas{end}=colugnas{end}( find(colugnas{end}=='\')+1 : end );
%           elseif find(colugnas{end}=='/') ~=0
%               colugnas{end}=colugnas{end}( find(colugnas{end}=='/')+1 : end );
%           end          
          for jj = 1:morecol
              y{nrows,1+jj} = str2num(colugnas{columns(jj)});
          end
          y{nrows,2+morecol}=colugnas{end};
      end 
  end     
  
  % get (item_number,file_name) pairs
     
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fclose('all');
