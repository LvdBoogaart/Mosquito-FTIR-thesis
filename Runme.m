%% Main file for data analysis Mosquito Thesis project
% Author: Luc van den Boogaart

%Use this file to set the algorithm settings and the operation mode.

%% Operation modes:
%'standard': Run the full algorithm
%   recommended use: use default settings
%
%'segmentation': Only runs the segmentation part of the code. 
%   recommended use: to find initial segmentation thresholds. To quickly
%   visualize segmentation result use: showframe(framenumber)
%
%'plotting': Only runs the figure plotting algorithm
%   recommended use: set clearall to false
%
%'load_data': Only loads the image data and creates a datastore
%   recommended use: using datastore for other purposes

%NOTE: Custom operating modes can be added in the runtype.m script under
%\functions\Driver and Settings

%% Do you want to clear the workspace?
clearall = true;
if clearall == true
clc
clear all
close all
end

%% Select runtype
Operatingmode = 'standard';

%% add function folders
%Add Functions subfolder to path
currentfolder = pwd;
subfolder = [currentfolder,'\Functions'];
addpath(genpath(subfolder));

%% Data set selection

%For WINDOWS machines: Set drive selection to automatic or manual.
%   automatic: will try to locate the events.xlsx file. This will work only
%   when the file is located in the top folder of a drive, either internal or
%   external.
%   manual: specify the measurement day, run number, drive, and camera.
%   sampledata: use the sample dataset

selection = 'manual';

%For IOS/Linux systems drive selection must be adjusted by manually and by
%hand. For details see the read_data_v05.m function

switch selection
    case 'manual'
        %Select day: 'mm_dd', run: #, drive: e.g. ('D:'/'E:'/'F:'/'G:'),
        %camera: 'PCO'/'Photron1'/'Photron2';
        
        %You can change the values of these parameters
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        day = '03_31';
        runno = 6;
        drive = 'D:';
        camera = 'PCO';
        frames = [586, 736];
        %%%%%%%%%%%%%%%%%%%%%%%%%%
        %Note that specifying an altfolder will overwrite the folder
        %selection algorithm, but the above parameters still need to be
        %filled out for the data loading algorithm to work.
        
        usesampledata = 0;
        altfolder = []; %manually override the folder path (currently only way to select data on IOS and Linux systems)
    
    case 'automatic'
        %Select set number (setno), as indicated in the events.xlsx file
        setno = 19;
        run auto_selector_string.m 
        usesampledata = false;
        
    case 'sampledata'
        day = '03_31';
        runno = 6;
        drive = 'D:';
        camera = 'PCO';
        frames = [2, 25];
        usesampledata = true;
        
        altfolder = [];
end

%% Toggles
filtertype = 'medfilt2';    %possible filters: medfilt2, gaussfilt
filtertwice = true;         %apply 2nd pass filter on image (reduces salt & pepper noise)

%% Settings
%image and background removal
grainsize = 3;              %Sets the pixel cluster size for filtering
threshold = 10;             %Sets the noise level threshold after background removal

%Segmentation and tracking
segmentationalgorithm = 'otsuthresh';   
minboundingboxarea = 750;  %Minimum size (#pixels^2) of bounding box (e.g. a 10 * 75 pixel box)

%Boxtracking;
%DBscan:
Centersearchrange = 50;
Centerminpts = 8;

%Spline fitting
Makespline = true;

%Threshold smoothing range
smoothingrange = 25;

%% Run Driver.m
run Driver.m


