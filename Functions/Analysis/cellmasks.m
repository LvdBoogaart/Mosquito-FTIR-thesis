function [imdat] = cellmasks(settings,imdat,framedat,samplepoints)
%INTENSITY_PROFILE Summary of this function goes here
%   Detailed explanation goes here

resolution = settings.resolution; %resolution of the camera (needed for pixel indices)
smoothingrange = settings.smoothingrange; %scalar for square cell, or provide (width,height) [pixels]

nLegs = imdat.sampling.nLegs;
for n = 1:nLegs
    disp(['Leg ',num2str(n)])

    %initialize
    querypoints = samplepoints.cb{n}; %take every pixel as possible parent (this could be updated to any other unit)    
    querypointsUNIQ = unique(querypoints,'rows','stable');
    
    %cull querypoints that lie outside of the image
    X = querypointsUNIQ(:,1); X(X<1) = 1; X(X>2000) = 2000;
    Y = querypointsUNIQ(:,2); Y(Y<1) = 1; Y(Y>2000) = 2000;
    querypointsUNIQ = [X,Y];
    
    targetpoints = framedat.INstack{n}; %all the points to be evaluated
    

    
    %process
    [qcells{n},groups{n}] = DivideIntoCells2(smoothingrange,querypointsUNIQ,targetpoints,resolution);
    
    %Output
    imdat.analysis.legobj{n}.qcells = qcells{n};
    imdat.analysis.legobj{n}.groups = groups{n};
end
end
    
function [qcells,groups] = DivideIntoCells2(celldim,cell_origins,targetpoints,resolution)

n = 1;
[ncells,i] = max(size(cell_origins)); %both (2,n) or (n,2) matrices allowed.
if i == 2
    transpose(cell_origins); %make the matrix tall if provided wide
end

if isscalar(celldim) == true
    width = celldim;
    height = celldim;
else
    width = celldim(1);
    height = celldim(2);
end
radius = ceil(width/2);

groupstack = [];
while n<=ncells
    origin = cell_origins(n,:);
    
    xmin = ceil(origin(1)-width/2);       qcells{n}.xmin = xmin;
    xmax = floor(origin(1)+width/2);       qcells{n}.xmax = xmax;
    ymin = ceil(origin(2)-height/2);      qcells{n}.ymin = ymin;
    ymax = floor(origin(2)+height/2);      qcells{n}.ymax = ymax;
    
    stack(n,1) = xmin; %do I need this for anything? don't seem so
    stack(n,2) = xmax;
    stack(n,3) = ymin;
    stack(n,4) = ymax;
    
    
    %find all points in the new cell
    ptin = targetpoints(xmin <= targetpoints(:,1)...
        & xmax >= targetpoints(:,1)...
        & ymin <= targetpoints(:,2)...
        & ymax >= targetpoints(:,2) , : );
    
    
    qcells{n}.ptin = ptin;
    ptinID = XYtoID(ptin,resolution);
    reverse = IDtoXY(ptinID,resolution);
    qcells{n}.ptinID = ptinID;
    
    %while we are already in the cell
    
    circlemask = false(width,height);    
    [x,y] = meshgrid(1:height,1:width);
    circlemask((x - radius+1).^2 + (y - radius+1).^2 <= (radius-1).^2) = true; 
    [r,c] = find(circlemask == 1);
    R = r+xmin;
    C = c+ymin;
    RCID = XYtoID([R,C],resolution);
    
    children = intersect(RCID,ptinID);
    groupstack = vertcat(groupstack,children);
    
    %and make it go around

    groups.parent{n} = origin;
    groups.children{n}  = children;
    groups.stack = groupstack;
    
    n = n+1;
end
end