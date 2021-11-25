function animate_series(imdat,series,contactarea,varargin)
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
                case 't_pause'
                    t_pause = varargin{a+1}; %take the value
                    a = a+2; %advance the amount of varargins used under case + 1
                case 'scaled'
                    imscaled = true;
                    a = a+1;
                    
                case {'set'}
                    set = varargin{a+1};
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
defaultset = 'raw';
defaulttpause = 0.05;
defaultimscaled = false;
%etc

%% overwrite function settings
if exist('t_pause','var') == 0% check if the option value is present
t_pause = defaulttpause;
end

if exist('set','var') == 1
    setfield = set;
else
    setfield = defaultset;
end

if exist('imscaled','var') == 1
    useimagesc = imscaled;
else
    useimagesc = defaultimscaled;
end

%% Algorithm
%Create a containing structure
if length(series) == 2
SER = series(1):series(2);

elseif length(series)>2
    SER = series;
else
    error('no series provided')
end

figure()
for n = SER
    im = imdat{n}.Imagedat.(setfield);
    subplot(2,1,1)
    if useimagesc == 1
        imagesc(im)
    elseif useimagesc == 0     
        imshow(im)
    end
    pbaspect([1 1 1])
    hold on
    colorbar
    
    subplot(2,1,2)
    plot(1:n,contactarea(1:n))
    drawnow
    pause(t_pause)
end