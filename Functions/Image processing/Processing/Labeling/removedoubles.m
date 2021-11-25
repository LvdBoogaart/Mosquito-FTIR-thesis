function [imdat,stat] = removedoubles(imdat,stat)
%FILTERDOUBLES locates and removes points that fall within the big boxes.
%The algorithm creates a large matrix containing all the possible x and y 
%locations, and regions of interest, and then flags all intersections for
%x and y. In the event both flags are triggered, a point is within a ROI
%and its index is flagged and removed.

Centers = imdat.processing.tracking.centroids.all;
rangestrct = imdat.processing.tracking.boxrangestrct.LBox;
Labels = imdat.processing.tracking.centroids.alllabels;

%initialize
%% large bounding box localization
sz = size(Centers);
if isempty(fieldnames(rangestrct)) == 0
    %% Extract ROI
    xrange = rangestrct.xrange;
    yrange = rangestrct.yrange;
    %% Prepare matrixes
    %prepare megamatrix
    Points_x = Centers(:,1);
    Points_y = Centers(:,2);
    %make tall matrices
    Xstack = repmat(Points_x,[size(xrange,1),1]);
    Ystack = repmat(Points_y,[size(yrange,1),1]);
    %repeat elements
    Xcheckstack = repelem(xrange,sz(1),1);
    Ycheckstack = repelem(yrange,sz(1),1);
    %make index and label vector
    idx = [1:1:size(Xstack,1)]';
    label = ceil(idx/size(Points_x,1));
    %% Flag points in ROI
    %Find intersect flags
    Flag1 = idx(Xcheckstack(:,1) < Xstack & Xstack < Xcheckstack(:,2));
    Flag2 = idx(Ycheckstack(:,1) < Ystack & Ystack < Ycheckstack(:,2));
    
    %Find union of intersect flags
    doublepointn = Flag1(ismember(Flag1,Flag2));
    
    %Retrieve group and index
    doublepointlabel = label(doublepointn);
    doublepointidx = doublepointn-(doublepointlabel-1)*size(Centers,1);
    %% Remove double points from set
    clear idx
    idx = 1:1:size(Centers,1);
    filtmembers = ismember(idx,doublepointidx);
    imdat.processing.tracking.centroids.filtered = Centers(filtmembers == 0,:);
    imdat.processing.tracking.centroids.filteredlabels = Labels(filtmembers == 0);
    
    stat.removedoubles = true;
else %pass empty data in case big boxes were found
    imdat.processing.tracking.centroids.filtered = Centers;
    imdat.processing.tracking.centroid.filteredlabels = Labels;
    
    stat.removedoubles = false;
end
end

