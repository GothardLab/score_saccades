%find vector (where it starts)
function start=findvec(a,b)
%b=the big vector
%a= the small vector to be found
count=0;
start=[];
if size(b,1)>1
    b = b';
end
if size(a,1)>1
    a = a';
end
for i=1:length(b)-(length(a)-1)
    temp=length(find(double(b(i:i+length(a)-1))-double(a)==0));
    if temp==length(a)
        count=count+1;
        start(count)=i;
    end
    clear temp
end