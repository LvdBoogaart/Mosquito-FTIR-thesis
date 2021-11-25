function [imdat,stat] = boxtrack(imdat,ImTrackSettings,stat)
print_to_console=false;

L = imdat.segmentation.BWlabels;
n = imdat.segmentation.numBWlabels;

boxtrackdat = regionprops(L,'BoundingBox','Centroid');
lowerbound = ImTrackSettings.noiselevel;
upperbound = ImTrackSettings.minboundingboxarea;

imdat.processing.tracking.LBox = struct([]);
imdat.processing.tracking.allBox = struct([]);

k = 1;
l = 1;
for i = 1:n
    boxsize = boxtrackdat(i).BoundingBox(3)*boxtrackdat(i).BoundingBox(4);
    if boxsize>upperbound %Filter every box below threshold
        imdat.processing.tracking.LBox(k).BoundingBox = boxtrackdat(i).BoundingBox;
        imdat.processing.tracking.LBox(k).idx = i;
        imdat.processing.tracking.LBox(k).size = boxsize;
        imdat.processing.tracking.LBox(k).FnBoxidx = l;
        k = k+1;
    end
    if boxsize>lowerbound %don't track salt and pepper noise
        imdat.processing.tracking.allBox(l).BoundingBox = boxtrackdat(i).BoundingBox;
        imdat.processing.tracking.allBox(l).Centroid = boxtrackdat(i).Centroid;
        imdat.processing.tracking.allBox(l).idx = i;
        imdat.processing.tracking.allBox(l).size = boxsize;
        l = l+1;
    end
end
imdat.processing.tracking.nLB = k-1;
imdat.processing.tracking.nallB = l-1;
if print_to_console == true
    disp(['Image filtered bounding boxes: ',num2str(k)]);
end
if imdat.processing.tracking.nLB > 0
    stat.LBox = true;
else
    stat.LBox = false;
end
end