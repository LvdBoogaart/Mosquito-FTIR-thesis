function [ID] = XYtoID(xy,resolution)
%XYTOID is used to transform the x-y location to a pixel ID, doing the
%indexing in a scanning fashion.
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
%ID = y + Yresolution*(y-1);
%
%Supply xy as 2 by 1: e.g. [x,y] or as a 2 by n: e.g.
%[x1 y1]
%[x2 y2]
%[.  .]
%[xn yn]
%Supply resolution as 1 by 2: e.g. [2000,2000]

[M,I] = max(size(xy));
if I == 2 && M>2
    xy = transpose(xy); %make tall if supplied wide
end

if sum(xy(:,1)> resolution(1))==0 && sum(xy(:,2)> resolution(2)) == 0
    ID = xy(:,2) + resolution(2)*(xy(:,1)-1);  
else
    error('xy exceeds possible locations within supplied resolution')
end

