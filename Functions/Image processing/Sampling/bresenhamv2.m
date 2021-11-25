function [cb] = bresenhamv2(varargin)
%Bresenhamv2 applies the bresenham algorithm to project a continuous spline
%on a grid. Bresenham can do 2 types of bresenham line projection:
%serial ('serial'): taking one spline and projecting over its length
%parallel ('parallel'): taking 2 splines, projecting between its points

%Format:
%The algorithm is set to take the splinedat struct from the get_bounds
%algorithm for serial projection (in which the spline number needs to be
%specified)


%[x y] = bresenhamv2(struct,'type',target)

%examples
%[x y] = bresenhamv2(splinedat,'serial','0')
%[x y] = bresenhamv2(c1,c2,'parallel')

c2s = @convertCharsToStrings; %function handle to check char strings

if isstruct(varargin{1}) == true && isfield(varargin{1},'c0')
    %splinedat struct supplied
    object = varargin{1};
    type = varargin{2};
    target = varargin{3};
    sz = size(object.c0,2);
elseif nargin == 3 && c2s(varargin{3}) == "parallel"
    object = varargin{1};
    object2 = varargin{2};
    type = varargin{3};
    sz = size(object,2);
else
    error('Input not allowed, try help bresenhamv2 for more information')
end

for n = 1:sz
    switch type
        case 'serial'
            c = object.(['c',target]){n};
            [x y] = bresenham(c);
            cb{n} = [x y];
        case 'parallel'
            c1 = object{n};
            c2 = object2{n};
            [x y] = bresenham(c1,c2);
            cb{n}.x = x;
            cb{n}.y = y;
    end
    plot(x,y) %,'o'
    drawnow
    clear x y
end
end

function [xb yb]=bresenham(varargin)
%Matlab optmized version of Bresenham line algorithm. No loops.
%Format:
%               [x y]=bham(x1,y1,x2,y2)
%
%Input:
%               (x1,y1): Start position
%               (x2,y2): End position
%
%Output:
%               x y: the line coordinates from (x1,y1) to (x2,y2)
%
%Usage example:
%               [x y]=bham(1,1, 10,-5);
%               plot(x,y,'or');
nargin = size(varargin,2);

if nargin == 1
    c1 = varargin{1};
    X1=c1(1:end-1,1); Y1=c1(1:end-1,2); X2=c1(2:end,1); Y2=c1(2:end,2);
elseif nargin == 2
    c1 = varargin{1};
    c2 = varargin{2};
    X1 = c1(:,1); Y1 = c1(:,2); X2 = c2(:,1); Y2 = c2(:,2);
    
else
    error('Too many function inputs supplied')
end


xb = [];
yb = [];
if size(X1,1) == size(X2,1)
    sz = size(X1,1);
else
    sz = min([size(X1,1),size(X2,1)]);
end
for n = 1:sz
    x1 = X1(n); x2 = X2(n); y1 = Y1(n); y2 = Y2(n);
    x1=round(x1); x2=round(x2);
    y1=round(y1); y2=round(y2);
    dx=abs(x2-x1);
    dy=abs(y2-y1);
    steep=abs(dy)>abs(dx);
    if steep t=dx;dx=dy;dy=t; end
    %The main algorithm goes here.
    if dy==0
        q=zeros(dx+1,1);
    else
        q=[0;diff(mod([floor(dx/2):-dy:-dy*dx+floor(dx/2)]',dx))>=0];
    end
    %and ends here.
    if steep
        if y1<=y2 y=[y1:y2]'; else y=[y1:-1:y2]'; end
        if x1<=x2 x=x1+cumsum(q);else x=x1-cumsum(q); end
    else
        if x1<=x2 x=[x1:x2]'; else x=[x1:-1:x2]'; end
        if y1<=y2 y=y1+cumsum(q);else y=y1-cumsum(q); end
    end
    if nargin == 1
        xb = vertcat(xb,x);
        yb = vertcat(yb,y);
    elseif nargin == 2
        %here we struggle with different length vectors.
        %first we check which one is larger, the new one, or the existing
        %one
        if isempty(xb) == true %initialization case, need to do nothing
            xb = horzcat(xb,x);
            yb = horzcat(yb,y);
        elseif size(xb,1)>size(x,1)
            %pad the new vector
            szx = size(x,1);
            szxb = size(xb,1);

            X = nan(szxb,1); Y = nan(szxb,1);
            X(1:szx) = x;
            Y(1:szx) = y;
            
            xb = horzcat(xb,X);
            yb = horzcat(yb,Y);
            
        elseif size(xb,1)<size(x,1)
            %pad the matrix
            szx = size(x,1);
            szxb = size(xb);
            
            Xb = nan(szx,szxb(2)); Yb = nan(szx,szxb(2));
            Xb(1:szxb(1),1:szxb(2)) = xb;
            Yb(1:szxb(1),1:szxb(2)) = yb;
            
            xb = horzcat(Xb,x);
            yb = horzcat(Yb,y);
            
        else %size is equal, just concatenate
            xb = horzcat(xb,x);
            yb = horzcat(yb,y);
        end
    end
end
end
