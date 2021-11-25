function [imdat] = backgroundsubtractv3(settings,varargin)
%BACKGROUNDSUBSTRACT Substracts backgroundimage from image of interest. A
%threshold must be set, including and below which value, after background
%removal, will be considered noise.
%
%NEEDS UPDATE
%
%Use:
%Supply settings, target-image and background image. The following inputs
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
%background: imdat struct, 'uint8', 'uint16', 'matlab.ui.Figure',
%'matlab.graphics.axis.Axes'
%
%Examples:
%   imdat = backgroundsubstractv2(settings,imdat)
%
%   backgroundsubstracted = backgroundsubstractv2(settings,gcf(),uint8_background_image)
%
%   Author: Luc van den Boogaart
%   Email: lucvdboogaart@gmail.com

%% check input type
%initialize
nargs = nargin;
vargs = size(varargin,2);
obj = varargin{1};
process = 0;
c2s = @convertCharsToStrings;

%Unpack the image files, set to workable format
while process == 0
    argclass = class(obj);
    switch argclass
        case 'cell'
            if isa(obj{1},'struct') == true
                nobj = 1;
                imdat = obj; %imdat struct confirmed
                for n = 1:size(imdat,1)
                    image{n,1} = imdat{n}.Imagedat.raw;             %create cell array with images
                end
                background = imdat{1}.Imagedat.background;          %same for all figures in imdat
                algorithm = 'series';
                process = 1;
            else
                %some sort of cell input, check what to do with this
            end
        case 'matlab.ui.Figure'
            obj = uint8(getimage(obj));
            process = 0;
        case 'matlab.graphics.axis.Axes'
            obj = uint8(getimage(obj));
            process = 0;
        case 'uint8'
            nobj = 2;
            obj2 = varargin{2};
            if class(obj) ~= class(obj2)
                arg2class = class(obj2);
                switch arg2class
                    case 'uint16'
                        %raw from some cameras
                        obj2 = uint8(image);
                    case 'matlab.ui.Figure'
                        %gcf()
                        obj2 = uint8(getimage(image));
                    case 'matlab.graphics.axis.Axes'
                        %gca()
                        obj2 = uint8(getimage(image));
                    otherwise
                        error('unexpected background format supplied')
                end
            end
            image = obj;                                %image input
            background = obj2;                           %background input
            algorithm = 'singleframe';
            process = 1;
    end
end

%% Check if extra options are set
if vargs>nobj
    a = nobj+1;
    while a<vargs
        setting = varargin{a};
        switch setting
            case 'output'
                outputflag = 1;
                output_value = varargin{a+1};
                switch output_value
                    case 'uint8'
                        if isa(image,'cell') == true
                            for n = 1:size(image,1)
                                image{n} = uint8(image{n});
                            end
                        else
                            image = uint8(image);
                        end
                        background = uint8(background);
                        imclass = 'uint';
                    case 'int8'
                        if isa(image,'cell') == true
                            for n = 1:size(image,1)
                                image{n} = int8(image{n});
                            end
                        else
                            image = int8(image);
                        end
                        background = int8(background);
                        imclass = 'int';
                    case 'uint16'
                        if isa(image,'cell') == true
                            for n = 1:size(image,1)
                                image{n} = uint16(image{n});
                            end
                        else
                            image = uint16(image);
                        end
                        background = uint16(background);
                        imclass = 'uint';
                    case 'int16'
                        if isa(image,'cell') == true
                            for n = 1:size(image,1)
                                image{n} = int16(image{n});
                            end
                        else
                            image = int16(image);
                        end
                        background = int16(background);
                        imclass = 'int';
                end
                a = a+2;
            case 'imagesc'
                imagescflag = 1;
                a = a+1;
            case 'filtersetting'
                filter_algorithm = varargin{a+1};
                switch filter_algorithm
                    case 'single'
                        passtwice = false;
                        a = a+2;
                    case 'double'
                        passtwice = true;
                        a = a+2;
                    otherwise
                        error('Unexpected filtertype, only single or double accepted')
                end
            case 'fieldname'
                fieldname_value = varargin{a+1};
                a = a+2;
            case 'filtertype'
                   filtertype = varargin{a+1};
                   filterparameters = varargin{a+2};
                   a = a+3;
            case 'gausspass'
                gausspass = true;
                if a+1<=vargs && isscalar(varargin{a+1}) == true
                    std = varargin{a+1};
                    a = a+2;
                else
                    std = 2;
                    a = a+1;
                end
            case 'noisethreshold'
                noisethreshold = true;
                if a+1<=vargs && isscalar(varargin{a+1}) == true
                    threshold = varargin{a+1};
                    a = a+2;
                elseif exist('outputflag','var')
                    switch imclass
                        case 'int'
                            threshold = 5;
                        case 'uint'
                            threshold = 10;
                    end
                    a = a+1;
                else
                    threshold = 5;
                    a = a+1;
                end
            otherwise
                error('unexpected namepair supplied')
        end
    end
end

%% Settings for backround prefiltering
% filter twice?
if exist('filter_algorithm','var') == 1
    filtertwice = passtwice;
else
    filtertwice = false;
end

% filter type?
if exist('filtertype','var') == 0
    filtertype = settings.filtertype;
    filterparameters = settings.grainsize;
end

switch filtertype
    case 'medfilt2'
        if isscalar(filterparameters) == true
            sigma = [filterparameters,filterparameters];
        else
            sigma = filterparameters;
        end
        background = medfilt2(background,sigma);
    case 'gaussfilt'
        sigma = filterparameters;
        background = imgaussfilt(background,sigma);
    otherwise
        warning('unexpected filter type is provided, default filter: "medfilt2" with a grainsize of 3 is used')
        background = medfilt2(background,[3,3]);
end

%% Output field name
%set fieldname, default: filteredbackground (accepted by applythreshold.m)
if exist('fieldname_value','var')== 1
    fieldname = fieldname_value;
elseif exist('outputflag','var') == 1
    fieldname = ['filteredbackground',output_value];
else
    fieldname = 'filteredbackground';
end

%% backgroundsubtract algorithm
switch algorithm
    case 'series'
        S = size(image,1);
        for n = 1:S
            tic
            backsub = image{n}-background; %substract background
            if filtertwice == true
                backsub = medfilt2(backsub,sigma);
            end
            
            if exist('gausspass','var')
                backsub = imgaussfilt(backsub,std);
            end
            if exist('noisethreshold','var')
                backsub(backsub<threshold) = 0;
            end
            
            imdat{n}.Imagedat.(fieldname) = backsub;
            %% Display process
            clc
            disp('backgroundsubstract.m')
            disp(['n = ',num2str(n),' of ',num2str(S)])
            toc
        end
    case 'singleframe'
        backsub = image-background;
        if filtertwice == true
            backsub = medfilt2(backsub,sigma);
        end
        
        if exist('gausspass','var')
            backsub = imgaussfilt(backsub,std);
        end
        
        if exist('noisethreshold','var')
            backsub(backsub<threshold) = 0;
        end
        
        imdat = backsub;
end

%% Display image?
if exist('imagescflag','var') == 1
    imagesc(backsub)
end

end
