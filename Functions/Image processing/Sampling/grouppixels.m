function [framedat] = grouppixels(curves)
%GROUPPIXELS Summary of this function goes here
%   Detailed explanation goes here

targetdim = [2000,2000];
celldim = [20,20];

[cells,cellstack] = DivideIntoCells(targetdim,celldim);

sz = size(curves.cb,2);
list = {};

for n = 1:sz %loop over all legs
    %cb1 is top/left, x-ascending
    %cb2 is bottom/right, x-ascending
    %cp1 is left, from cb1 to cb2
    %cp2 is right, from cb1 to cb2
    cb1 = curves.cb1{n};
    cb2 = curves.cb2{n};
    
    cp1x = curves.cbp{n}.x(:,1); cp1x = cp1x(~isnan(cp1x));
    cp1y = curves.cbp{n}.y(:,1); cp1y = cp1y(~isnan(cp1y));
    cp2x = curves.cbp{n}.x(:,end); cp2x = cp2x(~isnan(cp2x));
    cp2y = curves.cbp{n}.y(:,end); cp2y = cp2y(~isnan(cp2y));
    
    cp1 = [cp1x,cp1y];
    cp2 = [cp2x,cp2y];
    
    outline = vertcat(cb1,cp2,flipud(cb2),flipud(cp1));
    
    %now cull the outline because we cant have it project beyond the image
    outline(outline<1) = 1; outline(outline>2000) = 2000;
    
    %outline is the outline of the polygon. Now we need to create a group
    %of all the pixels that fall within this polygon.
    
    %ping pong algorithm
    
    [cells,list{n}] = pingpongcelldiv(outline,cells,cellstack);
    
    disp(['Scan pixels Leg ',num2str(n)])
    instack = [];
    instackID = [];
    for m = 1:size(list{n},2)
        i = list{n}(m);
        xq = repmat(transpose(cells{i}.xmin:1:cells{i}.xmax),cells{i}.ymax-cells{i}.ymin+1,1);
        yq = repelem(transpose(cells{i}.ymin:1:cells{i}.ymax),cells{i}.xmax-cells{i}.xmin+1);
        
        IN = inpolygon(xq,yq,outline(:,1),outline(:,2));
        
        cells{i}.IN = IN;
        cells{i}.ptsIN = cells{i}.pti(IN == 1,:);
        cells{i}.ptsINID = cells{i}.ptiID(IN == 1);
        instack = vertcat(instack,cells{i}.ptsIN);
        instackID = vertcat(instackID,cells{i}.ptsINID);
    end
    INstack{n} = instack;
    INstackID{n} = instackID;
end
    framedat.cells = cells;
    framedat.cellstack = cellstack;
    framedat.INstack = INstack;
    framedat.INstackID = INstackID;
    framedat.list = list;
end

function [cells,stack] = DivideIntoCells(targetdim,celldim)
x = 1;
y = 1;
n = 1;
while x<targetdim(1) || y<targetdim(2)
    if x>targetdim(1)
        x = x-targetdim(1);
    end
    cells{n}.xmin = x;
    cells{n}.xmax = x+celldim(1)-1;
    cells{n}.ymin = y;
    cells{n}.ymax = y+celldim(2)-1;
    
    stack(n,1) = cells{n}.xmin;
    stack(n,2) = cells{n}.xmax;
    stack(n,3) = cells{n}.ymin;
    stack(n,4) = cells{n}.ymax;
    
    
    cells{n}.pti = [repmat(transpose((x:1:x+celldim(1)-1)),celldim(1),1),repelem(transpose((y:1:y+celldim(2)-1)),celldim(2))];
    cells{n}.ptiID = cells{n}.pti(:,1)+targetdim(1)*(cells{n}.pti(:,2)-1);
    
    n = n+1;
    x = x+celldim(1);
    if x>targetdim(1)
        y = y+celldim(2);
    end

end
end

function [cells,list] = pingpongcelldiv(points,cells,stack)
%take a random point
n = 1;
cellindex = transpose(1:size(stack,1));
ptsindex = transpose(1:size(points,1));

checkvec = ptsindex;
iter = 0;
while isempty(checkvec)==false
    iter = iter+1;
    n = checkvec(1);
    pt = points(n,:);
    cell_i = cellindex(pt(1)>=stack(:,1)...
        & pt(1)<=stack(:,2)...
        & pt(2)>=stack(:,3)...
        & pt(2)<=stack(:,4));
    
    bounds = stack(cell_i,:);
    points_i = ptsindex(bounds(1)<=points(:,1)...
        & bounds(2)>=points(:,1)...
        & bounds(3)<=points(:,2)...
        & bounds(4)>=points(:,2));
    
    cells{cell_i}.borderpts_i = points_i;
    cells{cell_i}.borderpts = points(points_i,:);
    
    checkvec = setdiff(checkvec,points_i);
    list(iter) = cell_i;
end
end