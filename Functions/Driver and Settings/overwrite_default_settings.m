function ImTrackSettings = overwrite_default_settings(settings)
%% Default settings
%Segmenting
segmentationalgorithm = 'otsuthresh';
additionalsettings = [];

%boxtracking
minboundingboxarea = 750;
noiselevel = 4;

%DBscan
Centersearchrange = 50;
Centerminpts = 8;

%Pixeltracking
Pixsearchrange = 4;
Pixminpts = 20;

%Splinegraft
Makespline = true;

%Camera information
resolution = [2000,2000];

%% Overwrite if specified
nsets = size(fieldnames(settings));
args = fieldnames(settings);
for n = 1:nsets
    argn = args{n};
    switch argn
        case 'segmentationalgorithm'
            segmentationalgorithm = getfield(settings,argn);
        case 'minboundingboxarea'
            minboundingboxarea = getfield(settings,argn);
        case 'Centersearchrange'
            Centersearchrange = getfield(settings,argn);
        case 'Centerminpts'
            Centerminpts = getfield(settings,argn);
        case 'additionalsettings'
            additionalsettings = getfield(settings,argn);
        case 'noiselevel'
            noiselevel = getfield(settings,argn);
        case 'Pixsearchrange'
            Pixsearchrange = getfield(settings,argn);
        case 'Pixminpts'
            Pixminpts = getfield(settings,argn);
        case 'Makespline'
            Makespline = getfield(settings,argn);
        case 'resolution'
            resolution = getfield(settings,argn);
    end
end

%% Output
%Specify outputs in ImTrackSettings
ImTrackSettings.segmentationalgorithm = segmentationalgorithm;
ImTrackSettings.minboundingboxarea = minboundingboxarea;
ImTrackSettings.Centersearchrange = Centersearchrange;
ImTrackSettings.Centerminpts = Centerminpts;
ImTrackSettings.additionalsettings = additionalsettings;
ImTrackSettings.noiselevel = noiselevel;
ImTrackSettings.Pixsearchrange = Pixsearchrange;
ImTrackSettings.Pixminpts = Pixminpts;
ImTrackSettings.Makespline = Makespline;
ImTrackSettings.resolution = resolution;


end