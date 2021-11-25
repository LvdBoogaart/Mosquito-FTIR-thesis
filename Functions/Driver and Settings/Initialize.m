%create a settings struct and clean up workspace, cannot run seperately

%% Settings for background subtraction
settings.filtertype = 'medfilt2'; %allowed filters: medfilt2, gaussfilt
settings.filtertwice = filtertwice; %2nd pass image filter, recommended to reduce salt and pepper noise
settings.grainsize = grainsize; %pixel cluster size for filtering salt and pepper noise
settings.noisethreshold = threshold; %highpass threshold filtering remaining background noise

%% Settings for image tracking
settings.segmentationalgorithm = segmentationalgorithm;
settings.minboundingboxarea = minboundingboxarea;
settings.Centersearchrange = Centersearchrange;
settings.Centerminpts = Centerminpts;
settings.Makespline = Makespline;
settings.smoothingrange = smoothingrange;

run classifierweights.m
settings.weights = weights;
%settings.additionalsettings
%settings.noiselevel
% settings.Pixsearchrange
% settings.Pixminpts

%% Settings for analysis
switch camera
    case 'PCO'
        settings.resolution = [2000,2000];
    case 'Photron1'
        settings.resolution = [1024,1024];
    case 'Photron2'
        settings.resolution = [1024,1024];
end

%% clean workspace
clear filtertype filtertwice grainsize threshold segmentationalgorithm ...
    minboundingboxarea Centersearchrange Centerminpts Makespline weights

