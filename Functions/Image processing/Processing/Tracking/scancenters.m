function [imdat,stat] = scancenters(imdat,ImTrackSettings,stat)
searchrange = ImTrackSettings.Centersearchrange;
minpts = ImTrackSettings.Centerminpts;

Centers = imdat.processing.tracking.centroids.all;

%Compute euclidean distances between pixelclusters
imdat.processing.tracking.Euclidmat = sqrt((Centers(:,1)-Centers(:,1)').^2+(Centers(:,2)-Centers(:,2)').^2);

%Use DBSCAN alghoritm to group pixelclusters based on distance to other
%pixelclusters
imdat.processing.tracking.centroids.alllabels = dbscan(Centers,searchrange,minpts);

stat.scancenters = true;
end