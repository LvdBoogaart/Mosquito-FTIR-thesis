function [imdat,stat] = pixeltrackerv2(imdat,ImTrackSettings,stat)
%PIXELTRACKER Pixeltracker tracks the pixels inside the bigger boxes. To do
%so the pixeltracker uses a dbscan algorithm.
%
%Currently there is a maximum box size set for local labeling, to avoid CPU overload.
%
%Improvements considered (but not implemented in this version)
%   - Do parallel tracking on the GPU through the parallel computing
%   toolbox.
%   - Partitioning the problem by dividing in cells.
%
%   This functionality is skipped for now because the information inside
%   the body box is not that interesting for the current application.

print_to_console = false;
if stat.LBox == 1
    %Initialize
    searchrange = ImTrackSettings.Pixsearchrange;
    minpts = ImTrackSettings.Pixminpts;
    resolution = ImTrackSettings.resolution;
    
    %find index of segmented image pixels
    segm_im = imdat.segmentation.segm_im;
    segm_ids = find(segm_im == 1);
    
    %% Pixellocation
    %Find xy locations of the pixels inside the red boxes
    rangestrct = imdat.processing.tracking.boxrangestrct.LBox;
    xrange = rangestrct.xrange;
    yrange = rangestrct.yrange;
    sz = size(xrange,1);
    flag = zeros(sz,1);
    for i = 1:sz
        xmin = xrange(i,1); xmax = xrange(i,2);
        ymin = yrange(i,1); ymax = yrange(i,2);
        centroid = [(xmax+xmin)/2,(ymax+ymin)/2];
                
        %Create a mask of the pixels inside the large boxes
        xpt = transpose(xmin:1:xmax);
        ypt = transpose(ymin:1:ymax);
        maskx = repmat(xpt,ymax-ymin+1,1);
        masky = repelem(ypt,xmax-xmin+1);
        
        %convert the x,y inside the mask to IDs (global)
        maskxy = [maskx,masky]; 
        maskID = XYtoID(maskxy,resolution);
        
        ptsinboxID = intersect(segm_ids,maskID);
        ptsinboxXY = IDtoXY(ptsinboxID,resolution);
    
        %don't label any boxes over a size threshold (would be the body)
        boxsize = (xmax-xmin+1)*(ymax-ymin+1);
        if boxsize<50000           
            pixlabel = dbscan(ptsinboxXY,searchrange,minpts);
            flag(i) = 1;
        else
            pixlabel = zeros(size(ptsinboxID));
            flag(i) = 0;
        end
        imdat.processing.tracking.Largeboxdat{i}.globalxy = ptsinboxXY;
        imdat.processing.tracking.Largeboxdat{i}.globalID = ptsinboxID;
        imdat.processing.tracking.Largeboxdat{i}.locallabel = pixlabel;
        imdat.processing.tracking.Largeboxdat{i}.size = boxsize;
        imdat.processing.tracking.Largeboxdat{i}.fill = length(ptsinboxID)/boxsize;
        imdat.processing.tracking.Largeboxdat{i}.xmin = xmin;
        imdat.processing.tracking.Largeboxdat{i}.xmax = xmax;
        imdat.processing.tracking.Largeboxdat{i}.ymin = ymin;
        imdat.processing.tracking.Largeboxdat{i}.ymax = ymax;
        imdat.processing.tracking.Largeboxdat{i}.centroidxy = centroid;
        
        if print_to_console == true
            disp(['n = ',num2str(i),' of ',num2str(sz)])
        end
        
    end
    imdat.processing.tracking.Largeboxflag = flag';
    stat.pixeltracker = true;
else %pass empty data onwards
    stat.pixeltracker = false;
    imdat = imdat;
end

end