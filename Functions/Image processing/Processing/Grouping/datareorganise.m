function [imdat, stat] = datareorganise(imdat, stat)
%DATAREORGANISE Make some copies of data for easier access
%   Also done so the struct more resembles the folder structure

if stat.LBox == 1
%import
centroids = imdat.processing.tracking.centroids;

%make a struct folder containing all labeling data
labeling.LBoxlabels = centroids.LBoxlabels;
labeling.alllabels = centroids.alllabels;
labeling.filteredlabels = centroids.filteredlabels;
labeling.Largeboxdat = imdat.processing.tracking.Largeboxdat;
labeling.uniquelabels = imdat.processing.tracking.centroids.uniquelabels;

%export
imdat.processing.labeling = labeling;
end
end

