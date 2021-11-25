function [imdat] = applythreshold(settings,varargin)
%APPLYTHRESHOLD Summary of this function goes here 
%A threshold must be set, including and below which value, after background
%removal, will be considered noise.

%Use:
%Supply settings & target image. The following inputs
%are accepted:
%
%Settings: a struct, organised as follows:
%   filtertype = settings.filtertype;
%   filtertwice = settings.filtertwice;
%   grainsize = settings.grainsize;
%   noisethreshold = settings.noisethreshold;
%
%image: imdat struct, 'uint8', 'uint16', 'matlab.ui.Figure',
%'matlab.graphics.axis.Axes'
%
%
%Examples:
%   imdat = backgroundsubstractv2(settings,imdat)
%
%   threshold_applied = backgroundsubstractv2(settings,gcf())
%
%   Author: Luc van den Boogaart
%   Email: lucvdboogaart@gmail.com

%% check input type
if nargin == 2 && isa(varargin{1},'cell') == 1 && isa(varargin{1}{1},'struct') == 1
    imdat = varargin{1}; %imdat struct confirmed
    for n = 1:size(imdat,1)
        image{n,1} = imdat{n}.Imagedat.filteredbackground;             %create cell array with images
    end
    imClass = class(imdat{1}.Imagedat.raw);             %image class variable (must be uint8)
    flag = 'cell';
else
    image = varargin{1};                                %image input
    imClass = class(image);                             %image class (does not have to be uint8)
    flag = 'single';
end

%% set image class to uint8 for background and target image.
switch imClass
    case 'uint8'
        %No operation needed
    case 'uint16'
        %raw from some cameras
        image = uint8(image);
    case 'matlab.ui.Figure'
        %gcf()
        image = uint8(getimage(image));
    case 'matlab.graphics.axis.Axes'
        %gca()
        image = uint8(getimage(image));
end

%% Settings
noisethreshold = settings.noisethreshold;
filtertwice = settings.filtertwice;
grainsize = settings.grainsize;
sigma = [grainsize,grainsize];

%% noisethreshold algorithm 
switch flag
    case 'cell'
        S = size(image,1);
        for n = 1:S
            tic
            backsub = image{n};
            backsub(backsub<noisethreshold) = 0; %remove noise
            prefilt = backsub;  %prepare for 2nd filterpass if needed
            if filtertwice == true
                imdat{n}.Imagedat.backgroundremoved = medfilt2(prefilt,sigma);
            else
                imdat{n}.Imagedat.backgroundremoved = prefilt;
            end
            clc
            disp('applythreshold.m')
            disp(['n = ',num2str(n),' of ',num2str(S)])
            toc
        end
    case 'single'
        backsub = image;
        backsub(backsub<noisethreshold) = 0;
        prefilt = backsub;
        if filtertwice == true
            imdat = medfilt2(prefilt,sigma);
        else
            imdat = prefilt;
        end
end
end


