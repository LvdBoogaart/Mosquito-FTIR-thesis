function [xy] = IDtoXY(ID,resolution)
%IDTOXY is used to transform the pixel ID (index) to an x-y location
%provided that the indexing has been done in a scanning fashion.
%E.g. for an image taken with a 4MPx camera (having a [2000,2000] pixel
%resolution), the pixel index would be:
%
%[   1 2001 4001... 
%[   2 2002 4002... 
%[   3 2003 ...  etc.
%
%Corresponding to an (x,y) of:
%[(1,1) (2,1) (3,1) ... 
%[(1,2) (2,2) (3,2) ...
%[(1,3) (2,3) ... etc.
%
%The conversion algorithm for (x,y) to ID is:
%ID = y + Yresolution*(x-1);
%
%Supply ID as scalar: e.g 332735
%Supply resolution as 1 by 2: e.g [2000,2000]

if ID<=resolution(1)*resolution(2)
    if mod(ID/resolution(1),1) > 0
        y = round(resolution(1)*mod(ID/resolution(1),1));
        x = fix(ID/resolution(1))+1;
    else 
        y = 2000;
        x = ID/resolution(1);
    end
    
elseif isempty(ID) == true 
    warning('ID value was empty')
    x = [];
    y = [];
else
    error('ID exceeds the max ID within supplied resolution')
end
xy = [x,y];
end

