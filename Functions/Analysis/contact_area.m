function [imdat] = contact_area(imdat,varargin)
%Contact_area
%   Take the temporal dynamics from a series of contact images.
%   example call: output =
%   Template_function(input,'option1',option1value,'option 2',option2value)
%
%   Author:
%   date:

nvargs = size(varargin,2);
c2s = @convertCharsToStrings;

%% Expand function input
%loop over all varargin inputs.
a = 1;
while a<=nvargs
    object = varargin{a};
    objectclass = class(object);
    switch objectclass
        case 'char'     %namepair options
            charobj = object;
            switch charobj
                case 'threshold'
                    threshold = varargin{a+1}; %take the value
                    a = a+2; %advance the amount of varargins used under case + 1
                case 'padding'
                    padding = varargin{a+1};
                    a = a+2;
                    
                case {'leg_no','leg'}
                    leg_label = varargin{a+1};
                    a = a+2;
                case 'image'
                    image = varargin{a+1};
                    a = a+2;
                    
                otherwise
                    error('unexpected namepair supplied')
            end
        case 'double'   %scalars, vectors, matrices
        case 'cell'     %cell arrays
        case 'struct'   %structs
        otherwise
            
            error(['function not defined for input of type ',objectclass'])
    end
end
%etc

%% defaults settings
defaultthreshold = 8.8;
defaultpadding = 1;
defaultlegs = "all";
%etc

%% overwrite function settings
if exist('threshold','var') == 1% check if the option value is present
    thresholdvalue = threshold;
else
    thresholdvalue = defaultthreshold;
end

if exist('padding','var') == 1
    paddingvalue = padding;
else
    paddingvalue = defaultpadding;
end

if exist('leg_indices','var') == 1
    LEGS = leg_indices;
else
    if defaultlegs == "all"
        LEGS = 1:size(imdat.sampling.nLegs);
    end
end

if exist('image','var') == 1
    I = image;
else
    I = imdat.Imagedat.filtered;
end

%% Algorithm
%Create a containing structure
n = 0;
if isfield(imdat.processing.classification,'legobj') == true
legs = imdat.processing.classification.legobj;



for i = size(legs)
    if c2s(legs{i}.label) == c2s(leg_label)
        n = i;
    end
end
end

if n ~= 0
    points = imdat.fitting.legobj{n}.legpts;
    
    %Make a stack off all points in the leg group.
    for m = 1:size(points,2)
        allpts = vertcat(points{m});
    end
    
    %Find outer values:
    xmin = min(allpts(:,1))-paddingvalue;    ymin = min(allpts(:,2))-paddingvalue;
    xmax = max(allpts(:,1))+paddingvalue;    ymax = max(allpts(:,2))+paddingvalue;
    
    %cull if needed
    xmin(xmin<1) = 1; ymin(ymin<1) = 1; xmax(xmax>2000) = 2000; ymax(ymax>2000) = 2000;
    
    %ROI
    ROI{n} = [xmin xmax xmax xmin xmin;
        ymin ymin ymax ymax ymin]';
    
    window = I(ymin:ymax,xmin:xmax);
    
    %wie uit parents vallen in de window. (filter de body uit de meting)
    
    
    parents = imdat.analysis.filtered.qpt{n};
    ymean = cell2mat(imdat.analysis.filtered.mean_ypt{n});
    
    %Evil code maar:
    in = inpolygon(parents(:,1),parents(:,2),ROI{n}(:,1),ROI{n}(:,2));
    
    subsetx = parents(in == 1);
    subsety = ymean(in == 1);
    
    
    domain = subsety>thresholdvalue;
    X = subsetx(domain == 1);
    Y = subsety(domain == 1);
    
    %for now a factor?
    npts = numel(Y);
    
    %estimate contact area
    factor = 250; %µm^2 per pt
    contactarea = factor*npts;
    
    %show contact area
    %
else
    contactarea = 0;
end
    


%% Plotting %%
%     figure()
%
%     a = subplot(1,2,1)
%     imagesc(window), axis off
%     title('filtered image')
%     hold on
%     b = subplot(1,2,2),
%     imagesc(window(window>thresholdvalue)), axis off
%     title('contact')
%
%     contactarea = numel(window)>thresholdvalue
%

%% Output
%Create the outputs.
imdat.analysis.contactarea.(leg_label) = contactarea;
